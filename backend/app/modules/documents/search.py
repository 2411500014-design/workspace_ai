"""Keyword retrieval with BM25.

In production, retrieval is hybrid: pgvector similarity plus PostgreSQL full-text
search, merged with Reciprocal Rank Fusion (master plan §9). Local development has no
embedding model (it costs money), so this module provides the keyword half; the
``reciprocal_rank_fusion`` helper is ready for when vector results exist.

Every search is scoped to one project by the caller, so documents from other projects
can never leak into an answer.
"""

from __future__ import annotations

import math
import re
from collections import Counter
from collections.abc import Sequence
from dataclasses import dataclass

_TOKEN = re.compile(r"[0-9a-zà-öø-ÿ]+", re.IGNORECASE)

STOPWORDS = frozenset(
    ["yang", "dan", "di", "ke", "dari", "untuk", "dengan", "pada", "adalah", "ini", "itu", "atau", "dalam", "oleh", "akan", "juga", "tidak", "ada", "karena", "sebagai", "bisa", "dapat", "telah", "sudah", "lebih", "agar", "serta", "saat", "maka", "jika", "bahwa", "para", "apa", "bagaimana", "mengapa", "kapan", "siapa", "mana", "saya", "kamu", "kami", "kita", "mereka", "dia", "ia", "nya", "pun", "lah", "the", "a", "an", "of", "to", "in", "and", "or", "is", "are", "was", "were", "be", "been", "for", "on", "with", "as", "by", "at", "from", "this", "that", "these", "those", "it", "its", "into", "than", "then", "what", "which", "who", "how", "why", "when", "where", "do", "does", "did", "not", "no", "can", "could", "should", "would", "will", "may", "might", "about", "over", "under", "also", "any", "all", "some", "such",
     # Words that only frame a question ("berapa banyak yang perlu saya ...", "how many do I need ...").
     # Left in, they outscore the words that carry the meaning.
     "berapa", "banyak", "perlu", "apakah", "aku", "gue", "tolong", "mohon", "bisakah", "sih", "dong",
     "i", "me", "my", "you", "your", "we", "our", "many", "much", "need", "needs", "have", "has", "there", "please", "tell"]
)


def tokenize(text: str) -> list[str]:
    return [t for t in (m.group(0).lower() for m in _TOKEN.finditer(text)) if len(t) > 1 and t not in STOPWORDS]


# References mix Indonesian and English. Without multilingual embeddings, keyword search
# cannot match "hasil" to "results", so common academic terms are expanded both ways.
_BILINGUAL = [
    ("hasil", "result results"), ("metode", "method methods"), ("metodologi", "methodology"),
    ("kesimpulan", "conclusion conclusions"), ("tujuan", "aim aims objective objectives"),
    ("penelitian", "research study"), ("jurnal", "journal"), ("pengujian", "testing evaluation"),
    ("evaluasi", "evaluation"), ("akurasi", "accuracy"), ("persen", "percent"), ("data", "data"),
    ("kemenangan", "win won wins"), ("menang", "win won"), ("kalah", "lose lost"),
    ("keterbatasan", "limitation limitations"), ("masalah", "problem"), ("latar", "background"),
    ("pembahasan", "discussion"), ("perbandingan", "comparison compare"), ("algoritma", "algorithm"),
    ("model", "model"), ("sistem", "system"), ("pengguna", "user users"), ("waktu", "time"),
    ("kecepatan", "speed fast"), ("tercepat", "fastest"), ("terbaik", "best"), ("sampel", "sample"),
    ("responden", "respondents participants"), ("eksperimen", "experiment experiments"),
    ("rumusan", "formulation"), ("saran", "recommendation future"), ("kontribusi", "contribution"),
]
_EXPANSION: dict[str, set[str]] = {}
for _id, _en in _BILINGUAL:
    for _word in _en.split():
        _EXPANSION.setdefault(_id, set()).add(_word)
        _EXPANSION.setdefault(_word, set()).add(_id)


def expand_terms(terms: list[str]) -> list[str]:
    expanded = list(terms)
    for term in terms:
        for other in sorted(_EXPANSION.get(term, ())):
            if other not in expanded and other not in STOPWORDS:
                expanded.append(other)
    return expanded


@dataclass(frozen=True)
class SearchDoc:
    id: str
    text: str


@dataclass(frozen=True)
class Hit:
    id: str
    score: float
    # Share of the distinct query terms found in this document, 0..1.
    coverage: float


def bm25_search(query: str, docs: Sequence[SearchDoc], top_k: int = 8, k1: float = 1.5, b: float = 0.75) -> list[Hit]:
    original = list(dict.fromkeys(tokenize(query)))
    if not original or not docs:
        return []
    # A query term counts as matched when it or its other-language form appears.
    groups = {t: {t} | (_EXPANSION.get(t, set()) - STOPWORDS) for t in original}
    terms = expand_terms(original)
    tokenized = [tokenize(d.text) for d in docs]
    lengths = [len(t) for t in tokenized]
    avg_len = (sum(lengths) / len(lengths)) or 1.0
    n = len(docs)
    df = Counter()
    for tokens in tokenized:
        for term in set(tokens) & set(terms):
            df[term] += 1

    hits: list[Hit] = []
    for doc, tokens, length in zip(docs, tokenized, lengths, strict=True):
        counts = Counter(tokens)
        score = 0.0
        for term in terms:
            tf = counts.get(term, 0)
            if not tf:
                continue
            idf = math.log(1 + (n - df[term] + 0.5) / (df[term] + 0.5))
            score += idf * tf * (k1 + 1) / (tf + k1 * (1 - b + b * length / avg_len))
        matched = sum(1 for t in original if any(counts.get(form) for form in groups[t]))
        if score > 0:
            hits.append(Hit(doc.id, round(score, 4), round(matched / len(original), 4)))
    hits.sort(key=lambda h: (-h.score, h.id))
    return hits[:top_k]


_SENTENCES = re.compile(r"(?<=[.!?])\s+|\n+")


def best_snippet(text: str, query: str, max_chars: int = 600) -> str:
    """The sentences of ``text`` that match ``query`` best, with their neighbours."""
    sentences = [s.strip() for s in _SENTENCES.split(text) if s.strip()]
    if not sentences:
        return text[:max_chars]
    terms = set(expand_terms(list(dict.fromkeys(tokenize(query)))))
    scores = [len(terms & set(tokenize(s))) for s in sentences]
    best = max(range(len(sentences)), key=lambda i: (scores[i], -i))
    start = end = best
    length = len(sentences[best])
    # Grow the window around the best sentence while it fits.
    while True:
        grew = False
        for candidate in (end + 1, start - 1):
            if 0 <= candidate < len(sentences) and not start <= candidate <= end:
                extra = len(sentences[candidate]) + 1
                if length + extra <= max_chars:
                    start, end = min(start, candidate), max(end, candidate)
                    length += extra
                    grew = True
        if not grew:
            break
    snippet = " ".join(sentences[start : end + 1])
    return snippet if len(snippet) <= max_chars else snippet[: max_chars - 1] + "…"


# Below this, retrieval did not really find the question in the documents and the AI must
# say so instead of guessing (master plan §7, "Grounding dan sitasi").
MIN_COVERAGE = 0.34


def is_relevant(hit: Hit) -> bool:
    return hit.coverage >= MIN_COVERAGE


def reciprocal_rank_fusion(rankings: Sequence[Sequence[str]], k: int = 60) -> list[tuple[str, float]]:
    """RRF(d) = sum over rankings r of 1 / (k + rank_r(d)), ranks starting at 1."""
    scores: dict[str, float] = {}
    for ranking in rankings:
        for rank, doc_id in enumerate(ranking, start=1):
            scores[doc_id] = scores.get(doc_id, 0.0) + 1.0 / (k + rank)
    return sorted(scores.items(), key=lambda item: (-item[1], item[0]))
