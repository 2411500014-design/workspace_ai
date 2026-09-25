"""Structure-aware chunking (master plan §9, "Chunking dan embedding").

Split along section headings first, then paragraphs; aim for 300-800 tokens with about
10% overlap. Every chunk keeps its first and last page and its heading path (for example
"2.3 Metode > MCTS") so answers can cite the exact pages.
"""

from __future__ import annotations

import re
from dataclasses import dataclass

from .extract import Page

TARGET_MIN_TOKENS = 300
TARGET_MAX_TOKENS = 800
OVERLAP_RATIO = 0.10

_NUMBERED = re.compile(r"^(\d+(?:\.\d+){0,3})\.?\s+(\S.{0,120})$")
_CHAPTER = re.compile(r"^(BAB|CHAPTER)\s+([IVXLC]+|\d+)\b\.?\s*(.{0,120})$", re.IGNORECASE)
_MARKDOWN = re.compile(r"^(#{1,6})\s+(.+)$")
_SENTENCE_END = re.compile(r"(?<=[.!?])\s+")


@dataclass(frozen=True)
class Chunk:
    position: int
    text: str
    page_start: int
    page_end: int
    heading_path: str
    token_count: int


def estimate_tokens(text: str) -> int:
    """Rough token estimate: about 4/3 tokens per word for Indonesian and English."""
    words = len(text.split())
    return max(1, round(words * 4 / 3)) if words else 0


def heading_level(line: str) -> tuple[int, str] | None:
    line = line.strip()
    if not line or len(line) > 140:
        return None
    if m := _MARKDOWN.match(line):
        return len(m.group(1)), m.group(2).strip()
    if m := _CHAPTER.match(line):
        return 1, line
    if (m := _NUMBERED.match(line)) and not line.endswith((".", ",", ";")):
        depth = m.group(1).count(".") + 1
        # "2019 was a good year" is not a heading; require a short title-like remainder.
        if len(m.group(2).split()) <= 12 and m.group(2)[:1].isupper():
            return min(depth + 1, 6), line
    letters = [c for c in line if c.isalpha()]
    if len(letters) >= 4 and all(c.isupper() for c in letters) and len(line.split()) <= 10:
        return 1, line
    return None


def _flush(paragraph: list[str], page_no: int, stack: list[tuple[int, str]], units: list[tuple[str, int, str]]) -> None:
    if paragraph:
        text = " ".join(paragraph).strip()
        if text:
            units.append((text, page_no, " > ".join(h for _, h in stack)))
        paragraph.clear()


def _units(pages: list[Page]) -> list[tuple[str, int, str]]:
    """Paragraph-sized units with their page number and heading path."""
    units: list[tuple[str, int, str]] = []
    stack: list[tuple[int, str]] = []
    for page in pages:
        paragraph: list[str] = []
        for raw in page.text.splitlines():
            line = raw.strip()
            if not line:
                _flush(paragraph, page.number, stack, units)
                continue
            heading = heading_level(line)
            if heading:
                _flush(paragraph, page.number, stack, units)
                level, title = heading
                while stack and stack[-1][0] >= level:
                    stack.pop()
                stack.append((level, title))
                continue
            paragraph.append(line)
            # PDFs rarely keep blank lines; end a paragraph at a sentence end once it is long.
            if line.endswith((".", "?", "!", ":")) and sum(len(p) for p in paragraph) > 600:
                _flush(paragraph, page.number, stack, units)
        _flush(paragraph, page.number, stack, units)
    return units


def _split_long(text: str, max_tokens: int) -> list[str]:
    if estimate_tokens(text) <= max_tokens:
        return [text]
    pieces: list[str] = []
    current: list[str] = []
    for sentence in _SENTENCE_END.split(text):
        candidate = " ".join([*current, sentence])
        if current and estimate_tokens(candidate) > max_tokens:
            pieces.append(" ".join(current))
            current = [sentence]
        else:
            current.append(sentence)
    if current:
        pieces.append(" ".join(current))
    # A single enormous "sentence" (tables, lists) is cut by words.
    result: list[str] = []
    for piece in pieces:
        words = piece.split()
        limit = int(max_tokens * 3 / 4)
        for i in range(0, len(words), limit):
            result.append(" ".join(words[i : i + limit]))
    return result


def chunk_pages(
    pages: list[Page],
    min_tokens: int = TARGET_MIN_TOKENS,
    max_tokens: int = TARGET_MAX_TOKENS,
    overlap_ratio: float = OVERLAP_RATIO,
) -> list[Chunk]:
    units: list[tuple[str, int, str]] = []
    for text, page, heading in _units(pages):
        units.extend((piece, page, heading) for piece in _split_long(text, max_tokens))

    chunks: list[Chunk] = []
    current: list[tuple[str, int, str]] = []

    def tokens(items: list[tuple[str, int, str]]) -> int:
        return sum(estimate_tokens(t) for t, _, _ in items)

    def emit() -> None:
        if not current:
            return
        text = "\n\n".join(t for t, _, _ in current)
        chunks.append(
            Chunk(
                position=len(chunks),
                text=text,
                page_start=min(p for _, p, _ in current),
                page_end=max(p for _, p, _ in current),
                heading_path=current[-1][2],
                token_count=estimate_tokens(text),
            )
        )

    for unit in units:
        heading_changed = bool(current) and unit[2] != current[-1][2]
        too_big = bool(current) and tokens(current) + estimate_tokens(unit[0]) > max_tokens
        if (too_big and tokens(current) >= min_tokens // 2) or (heading_changed and tokens(current) >= min_tokens):
            emit()
            # Carry the tail of the previous chunk over as overlap, within the same section.
            overlap: list[tuple[str, int, str]] = []
            budget = int(max_tokens * overlap_ratio)
            for item in reversed(current):
                if item[2] != unit[2] or tokens(overlap) + estimate_tokens(item[0]) > budget:
                    break
                overlap.insert(0, item)
            current = overlap
        current.append(unit)
    emit()
    return chunks
