"""Deterministic document understanding, used when no AI key is configured.

These are deliberately conservative: they find candidates (requirements, dates,
metadata) for the user to review, never final answers.
"""

from __future__ import annotations

import re
from datetime import date

KINDS = ("proposal", "instruction", "journal", "supervision", "draft", "other")

_KIND_RULES: list[tuple[str, tuple[str, ...]]] = [
    ("supervision", ("bimbingan", "catatan bimbingan", "supervision", "konsultasi")),
    ("instruction", ("panduan", "pedoman", "ketentuan", "instruksi", "rubrik", "guideline", "syarat", "template")),
    ("proposal", ("proposal", "usulan penelitian", "rumusan masalah", "research proposal")),
    ("journal", ("abstract", "doi", "journal", "jurnal", "vol.", "volume", "issn", "keywords", "kata kunci")),
    ("draft", ("bab i", "bab 1", "pendahuluan", "chapter 1", "introduction", "draf", "draft", "skripsi")),
]

_DOI = re.compile(r"\b10\.\d{4,9}/[-._;()/:A-Za-z0-9]+[A-Za-z0-9]")
_YEAR = re.compile(r"\b(19[89]\d|20[0-4]\d)\b")

_REQUIREMENT_WORDS = re.compile(
    r"\b(minimal|minimum|maksimal|maksimum|wajib|harus|paling sedikit|paling lambat|sekurang-kurangnya|"
    r"format|sitasi|ieee|apa style|halaman|referensi|must|at least|required|at most|no later than)\b",
    re.IGNORECASE,
)

MONTHS = {
    "januari": 1, "january": 1, "jan": 1,
    "februari": 2, "february": 2, "feb": 2, "pebruari": 2,
    "maret": 3, "march": 3, "mar": 3,
    "april": 4, "apr": 4,
    "mei": 5, "may": 5,
    "juni": 6, "june": 6, "jun": 6,
    "juli": 7, "july": 7, "jul": 7,
    "agustus": 8, "august": 8, "agu": 8, "aug": 8,
    "september": 9, "sep": 9, "sept": 9,
    "oktober": 10, "october": 10, "okt": 10, "oct": 10,
    "november": 11, "nov": 11, "nopember": 11,
    "desember": 12, "december": 12, "des": 12, "dec": 12,
}
_DATE_WORDS = re.compile(r"\b(\d{1,2})\s+([A-Za-z]{3,9})\.?\s+(\d{4})\b")
_DATE_ISO = re.compile(r"\b(\d{4})-(\d{2})-(\d{2})\b")
_DATE_SLASH = re.compile(r"\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})\b")


_HEAD_ORDER = ("instruction", "proposal", "journal", "supervision", "draft")


def classify(filename: str, text: str) -> str:
    """Kind of document. The title and opening lines decide first ("Panduan Skripsi"
    stays a guideline even when its body mentions bimbingan); then the whole text."""
    rules = dict(_KIND_RULES)
    head = f"{filename}\n{text[:400]}".lower()
    for kind in _HEAD_ORDER:
        if any(word in head for word in rules[kind]):
            return kind
    haystack = f"{filename}\n{text[:6000]}".lower()
    for kind, words in _KIND_RULES:
        if any(word in haystack for word in words):
            return kind
    return "other"


def metadata(text: str) -> dict:
    head = text[:8000]
    result: dict = {}
    if m := _DOI.search(head):
        result["doi"] = m.group(0).rstrip(".")
        # Numbers inside a DOI are not publication years.
        head = head.replace(m.group(0), " ")
    if m := _YEAR.search(head):
        result["year"] = int(m.group(1))
    return result


def guess_title(filename: str, text: str) -> str:
    for line in text.splitlines():
        line = line.strip().lstrip("#").strip()
        if 8 <= len(line) <= 200 and any(c.isalpha() for c in line):
            return line
    stem = filename.rsplit(".", 1)[0]
    return re.sub(r"[_-]+", " ", stem).strip() or filename


def sentences(text: str) -> list[str]:
    flat = re.sub(r"\s+", " ", text)
    return [s.strip() for s in re.split(r"(?<=[.!?;])\s+|\s+[-•]\s+|\s\d+[.)]\s", flat) if s.strip()]


def _words(text: str) -> set[str]:
    return set(re.findall(r"\w+", text.lower()))


def same_requirement(a: str, b: str) -> bool:
    """True when two requirement texts state the same rule.

    Extraction can cut a sentence differently ("Ketentuan Umum Skripsi wajib ..." versus
    "Skripsi wajib ..."), so most of the shorter text's words appearing in the other counts.
    """
    wa, wb = _words(a), _words(b)
    if not wa or not wb:
        return False
    small, large = (wa, wb) if len(wa) <= len(wb) else (wb, wa)
    return len(small & large) / len(small) >= 0.75


def _has_date(text: str) -> bool:
    return any(_date_matches(text))


def requirement_candidates(text: str, limit: int = 12) -> list[str]:
    """Sentences that read like rules ("wajib", "minimal", "must").

    Sentences that carry a date are deadlines; they become important dates instead.
    """
    found: list[str] = []
    seen: set[str] = set()
    for sentence in sentences(text):
        if 12 <= len(sentence) <= 260 and _REQUIREMENT_WORDS.search(sentence) and not _has_date(sentence):
            key = sentence.lower()
            if key not in seen:
                seen.add(key)
                found.append(sentence.rstrip(";"))
        if len(found) >= limit:
            break
    return found


def _safe_date(y: int, m: int, d: int) -> date | None:
    try:
        return date(y, m, d)
    except ValueError:
        return None


def _date_matches(line: str) -> list[tuple[int, int, date]]:
    """(start, end, date) for every date written in ``line``, in reading order."""
    found: list[tuple[int, int, date | None]] = []
    for m in _DATE_WORDS.finditer(line):
        month = MONTHS.get(m.group(2).lower().rstrip("."))
        if month:
            found.append((m.start(), m.end(), _safe_date(int(m.group(3)), month, int(m.group(1)))))
    for m in _DATE_ISO.finditer(line):
        found.append((m.start(), m.end(), _safe_date(int(m.group(1)), int(m.group(2)), int(m.group(3)))))
    for m in _DATE_SLASH.finditer(line):
        found.append((m.start(), m.end(), _safe_date(int(m.group(3)), int(m.group(2)), int(m.group(1)))))
    return sorted((start, end, day) for start, end, day in found if day is not None)


# Words that only join a label to its date: "dilaksanakan pada 20 November", "due on 3 May".
_LABEL_TAIL = re.compile(r"(?:\s+|^)(?:pada|tanggal|tgl\.?|hari|on|at|by|is|adalah|yaitu)\s*$", re.IGNORECASE)
_LABEL_MAX = 60


def _label_before(segment: str) -> str:
    """The words just before a date: the last sentence of ``segment``, trimmed."""
    segment = re.sub(r"\s+", " ", segment)
    segment = re.split(r"(?<=[.!?;])\s+|\s\d+[.)]\s", segment)[-1]
    label = segment.strip(" :,.-–—()")
    while (trimmed := _LABEL_TAIL.sub("", label).strip(" :,-–—")) != label:
        label = trimmed
    if len(label) > _LABEL_MAX:
        label = label[-_LABEL_MAX:].split(" ", 1)[-1]
    return label


def date_candidates(text: str, limit: int = 10) -> list[dict]:
    """Dates, each labelled with the words that introduce it.

    A line often holds several dates once a PDF loses its line breaks, e.g.
    "Batas proposal: 30 Oktober 2026 Seminar dilaksanakan pada 20 November 2026", so each
    date takes the text between the previous date and itself as its label.
    """
    results: list[dict] = []
    seen: set[str] = set()
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        previous_end = 0
        for start, end, day in _date_matches(line):
            label = _label_before(line[previous_end:start])
            if not label:  # "30 Oktober 2026: batas proposal"
                label = _label_before(re.split(r"(?<=[.!?;])\s", line[end:].strip(" :,-–—"))[0])
            previous_end = end
            if day.isoformat() in seen:
                continue
            seen.add(day.isoformat())
            results.append({"label": label or re.sub(r"\s+", " ", line)[:90], "date": day.isoformat()})
            if len(results) >= limit:
                return results
    return results


_SUMMARY_KEYWORDS = re.compile(
    r"\b(tujuan|bertujuan|metode|hasil|kesimpulan|menunjukkan|aim|aims|method|results?|conclusion|propose|we)\b",
    re.IGNORECASE,
)


def extractive_summary(texts: list[str], max_words: int = 300) -> str:
    """Up to ``max_words``: the opening sentences plus sentences about aims, methods and results."""
    picked: list[str] = []
    words = 0
    candidates = sentences("\n".join(texts[:12]))
    lead = candidates[:3]
    keyed = [s for s in candidates[3:] if _SUMMARY_KEYWORDS.search(s)]
    for sentence in lead + keyed:
        if not 30 <= len(sentence) <= 400 or sentence in picked:
            continue
        count = len(sentence.split())
        if words + count > max_words:
            break
        picked.append(sentence)
        words += count
    return " ".join(picked)
