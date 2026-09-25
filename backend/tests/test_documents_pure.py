from app.modules.documents.chunking import chunk_pages, estimate_tokens, heading_level
from app.modules.documents.extract import Page, detect_mime, extract_pages
from app.modules.documents.heuristics import (
    classify,
    date_candidates,
    extractive_summary,
    metadata,
    requirement_candidates,
    same_requirement,
)
from app.modules.documents.search import SearchDoc, bm25_search, is_relevant, reciprocal_rank_fusion
from tests.fixtures import INSTRUCTION_TEXT, JOURNAL_PAGES, make_docx, make_pdf

PDF = "application/pdf"
DOCX = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"


def test_pdf_text_is_extracted_per_page():
    pages = extract_pages(make_pdf(JOURNAL_PAGES), PDF)
    assert [p.number for p in pages] == [1, 2, 3]
    assert "Monte Carlo Tree Search" in pages[0].text
    assert "68 percent" in pages[2].text


def test_docx_headings_are_marked_for_the_chunker():
    data = make_docx([("Bab 1 Pendahuluan", "Heading 1"), ("Latar belakang penelitian ini.", None)])
    pages = extract_pages(data, DOCX)
    assert pages[0].text.splitlines()[0] == "# Bab 1 Pendahuluan"


def test_mime_is_detected_from_the_extension():
    assert detect_mime("Proposal.PDF", None) == PDF
    assert detect_mime("notes.md", "application/octet-stream") == "text/markdown"


def test_headings_are_recognised():
    assert heading_level("2.3 Metode Penelitian")[0] == 3
    assert heading_level("BAB II TINJAUAN PUSTAKA")[0] == 1
    assert heading_level("# Pendahuluan") == (1, "Pendahuluan")
    assert heading_level("2019 adalah tahun yang baik.") is None


def test_chunks_keep_pages_and_heading_path():
    pages = extract_pages(make_pdf(JOURNAL_PAGES), PDF)
    chunks = chunk_pages(pages, min_tokens=10, max_tokens=60)
    assert chunks, "expected at least one chunk"
    method = next(c for c in chunks if "50 ms budget" in c.text)
    assert "2. Method" in method.heading_path
    assert method.page_start == method.page_end == 2
    assert all(c.token_count <= 60 + 20 for c in chunks)


def test_long_sections_are_split_with_overlap():
    body = " ".join(f"Kalimat nomor {i} menjelaskan metode penelitian secara rinci." for i in range(200))
    chunks = chunk_pages([Page(1, "1. Metode\n" + body)], min_tokens=300, max_tokens=800)
    assert len(chunks) >= 2
    assert all(estimate_tokens(c.text) <= 800 + 100 for c in chunks)


def test_bm25_finds_the_relevant_passage_and_flags_unrelated_questions():
    docs = [SearchDoc(str(i), text) for i, text in enumerate(JOURNAL_PAGES)]
    hits = bm25_search("What percent of matches did MCTS win against Utility AI?", docs)
    assert hits[0].id == "2"
    assert is_relevant(hits[0])
    # An Indonesian question finds the English passage through the bilingual term list.
    hits = bm25_search("Berapa persen kemenangan MCTS melawan Utility AI?", docs)
    assert hits[0].id == "2"
    unrelated = bm25_search("resep rendang padang", docs)
    assert not unrelated or not is_relevant(unrelated[0])


def test_rrf_merges_rankings():
    fused = reciprocal_rank_fusion([["a", "b", "c"], ["b", "a", "d"]])
    assert [doc for doc, _ in fused][:2] in (["a", "b"], ["b", "a"])
    assert dict(fused)["d"] < dict(fused)["a"]


def test_heuristics_find_requirements_dates_and_kind():
    assert classify("panduan_skripsi.pdf", INSTRUCTION_TEXT) == "instruction"
    assert classify("paper.pdf", JOURNAL_PAGES[0]) == "journal"
    reqs = requirement_candidates(INSTRUCTION_TEXT)
    assert any("20 referensi" in r for r in reqs)
    assert any("IEEE" in r for r in reqs)
    dates = {d["date"] for d in date_candidates(INSTRUCTION_TEXT)}
    assert {"2026-10-30", "2026-11-20", "2027-03-15"} <= dates
    assert not any("2026" in r for r in reqs), "deadlines are dates, not requirements"


def test_each_date_is_labelled_by_the_words_before_it():
    # PDFs often lose their line breaks, putting several dates on one line.
    flat = (
        "2. Jadwal Penting Batas pengumpulan proposal: 30 Oktober 2026 Seminar proposal dilaksanakan "
        "pada 20 November 2026 Sidang akhir paling lambat 15 Maret 2027"
    )
    assert date_candidates(flat) == [
        {"label": "Jadwal Penting Batas pengumpulan proposal", "date": "2026-10-30"},
        {"label": "Seminar proposal dilaksanakan", "date": "2026-11-20"},
        {"label": "Sidang akhir paling lambat", "date": "2027-03-15"},
    ]
    assert date_candidates("30/10/2026: batas unggah proposal.") == [{"label": "batas unggah proposal", "date": "2026-10-30"}]
    assert date_candidates("The final report is due on 2027-01-15.")[0]["label"] == "The final report is due"
    assert metadata(JOURNAL_PAGES[0]) == {"doi": "10.1234/rts.2024.001"}


def test_extractive_summary_stays_within_the_word_limit():
    summary = extractive_summary(JOURNAL_PAGES, max_words=40)
    assert summary
    assert len(summary.split()) <= 40


def test_the_same_rule_cut_differently_is_recognised():
    assert same_requirement(
        "Ketentuan Umum Skripsi wajib menggunakan minimal 20 referensi dari 5 tahun terakhir.",
        "Program Studi Informatika Skripsi wajib menggunakan minimal 20 referensi dari 5 tahun terakhir.",
    )
    assert not same_requirement("Format sitasi harus mengikuti gaya IEEE.", "Naskah paling sedikit 40 halaman.")
    assert not same_requirement("", "Naskah paling sedikit 40 halaman.")
