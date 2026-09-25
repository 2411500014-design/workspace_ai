"""Document Engine service: upload, background processing, search (master plan §9).

Upload -> store (status processing) -> extract text per page -> classify -> chunk with
context headers -> index -> summary and metadata -> proposed brief update (status ready).
Every step is idempotent: a retry deletes the previous chunks and starts over.
"""

from __future__ import annotations

import hashlib
import logging
import uuid
from pathlib import Path

from sqlalchemy import delete, func, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.db import session_factory
from app.core.errors import AppError, NotFound
from app.modules.accounts.models import Profile
from app.modules.ai.gateway import Gateway
from app.modules.ai.suggestions import create_suggestion
from app.modules.ai.workflows import AIContext, Passage, document_insight
from app.modules.modes.loader import get_mode
from app.modules.projects.models import Project, Requirement

from . import heuristics
from .chunking import chunk_pages
from .extract import count_pages, detect_mime, extract_pages
from .models import Document, DocumentChunk
from .search import SearchDoc, bm25_search, is_relevant

log = logging.getLogger(__name__)

EXTENSION_FOR = {
    "application/pdf": ".pdf",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document": ".docx",
    "text/plain": ".txt",
    "text/markdown": ".md",
}


def list_documents(db: Session, project_id: str) -> list[Document]:
    return list(db.scalars(select(Document).where(Document.project_id == project_id).order_by(Document.created_at.desc())))


def chunk_counts(db: Session, project_id: str) -> dict[str, int]:
    rows = db.execute(
        select(DocumentChunk.document_id, func.count()).where(DocumentChunk.project_id == project_id).group_by(DocumentChunk.document_id)
    )
    return dict(rows.all())


def get_document(db: Session, document_id: str, allowed_projects: set[str]) -> Document:
    document = db.get(Document, document_id)
    if document is None or document.project_id not in allowed_projects:
        raise NotFound("document")
    return document


def upload(db: Session, project: Project, filename: str, declared_mime: str | None, data: bytes) -> Document:
    settings = get_settings()
    if not data:
        raise AppError("empty_file", 422)
    if len(data) > settings.max_upload_mb * 1024 * 1024:
        raise AppError("file_too_large", 413, {"max_mb": settings.max_upload_mb})
    mime = detect_mime(filename, declared_mime)
    pages = count_pages(data, mime)
    if pages > settings.max_pages:
        raise AppError("too_many_pages", 413, {"max_pages": settings.max_pages})
    checksum = hashlib.sha256(data).hexdigest()
    duplicate = db.scalars(select(Document).where(Document.project_id == project.id, Document.checksum == checksum)).first()
    if duplicate is not None:
        raise AppError("duplicate_document", 409, {"document_id": duplicate.id})

    # Random file names, never the uploaded name (master plan §13).
    folder = Path(settings.storage_dir) / project.id
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / f"{uuid.uuid4().hex}{EXTENSION_FOR[mime]}"
    path.write_bytes(data)
    document = Document(
        project_id=project.id,
        title=Path(filename).stem[:300] or filename,
        filename=Path(filename).name[:300],
        storage_path=str(path),
        mime=mime,
        size_bytes=len(data),
        pages=pages,
        checksum=checksum,
        status="processing",
    )
    db.add(document)
    db.flush()
    return document


def process_document(document_id: str, user_id: str, gateway: Gateway) -> None:
    """Background job. Opens its own session; never raises."""
    db = session_factory()()
    try:
        document = db.get(Document, document_id)
        user = db.get(Profile, user_id)
        if document is None or user is None:
            return
        project = db.get(Project, document.project_id)
        try:
            _process(db, document, user, project, gateway)
            document.status = "ready"
            document.error_code = None
        except AppError as exc:
            db.rollback()
            document = db.get(Document, document_id)
            document.status = "failed"
            document.error_code = exc.code
        except Exception:  # pragma: no cover - unexpected parser failures
            log.exception("document processing failed")
            db.rollback()
            document = db.get(Document, document_id)
            document.status = "failed"
            document.error_code = "processing_failed"
        db.commit()
    finally:
        db.close()


def process_now(db: Session, document: Document, user: Profile, project: Project, gateway: Gateway) -> None:
    """Process a document inside the caller's session (used for the sample project)."""
    _process(db, document, user, project, gateway)
    document.status = "ready"
    document.error_code = None
    db.flush()


def ready_documents(db: Session, project_id: str) -> list[dict]:
    """Title, kind and full text of every processed document, in upload order."""
    result = []
    for doc in db.scalars(
        select(Document).where(Document.project_id == project_id, Document.status == "ready").order_by(Document.created_at)
    ):
        text = "\n".join(
            db.scalars(select(DocumentChunk.text).where(DocumentChunk.document_id == doc.id).order_by(DocumentChunk.position))
        )
        result.append({"title": doc.title, "kind": doc.kind, "text": text})
    return result


def _process(db: Session, document: Document, user: Profile, project: Project, gateway: Gateway) -> None:
    data = Path(document.storage_path).read_bytes()
    pages = extract_pages(data, document.mime)
    full_text = "\n".join(p.text for p in pages)
    if not full_text.strip():
        # A scanned PDF: reading page images needs Claude's PDF support (V1, costs more).
        raise AppError("no_text_found", 422)
    chunks = chunk_pages(pages)
    db.execute(delete(DocumentChunk).where(DocumentChunk.document_id == document.id))
    for chunk in chunks:
        db.add(
            DocumentChunk(
                document_id=document.id,
                project_id=document.project_id,
                position=chunk.position,
                text=chunk.text,
                page_start=chunk.page_start,
                page_end=chunk.page_end,
                heading_path=chunk.heading_path[:500],
                token_count=chunk.token_count,
            )
        )
    mode = get_mode(project.mode) if project else None
    ctx = AIContext(db=db, user=user, gateway=gateway, mode=mode, locale=user.locale, project_id=document.project_id)
    insight = document_insight(ctx, document.filename, full_text, [c.text for c in chunks])
    document.kind = insight.value["kind"]
    guessed = insight.value.get("title") or ""
    if guessed and (insight.ai_used or document.title == Path(document.filename).stem):
        document.title = guessed[:300]
    document.summary = insight.value.get("summary", "")
    document.summary_ai = insight.ai_used
    document.doc_metadata = insight.value.get("metadata", {})
    db.flush()
    if project is not None and document.kind in ("instruction", "proposal"):
        _propose_brief_update(db, project, document, full_text)


def _propose_brief_update(db: Session, project: Project, document: Document, text: str) -> None:
    known = [r.text for r in db.scalars(select(Requirement).where(Requirement.project_id == project.id))]
    fresh = [c for c in heuristics.requirement_candidates(text) if not any(heuristics.same_requirement(c, k) for k in known)]
    if not fresh:
        return
    ops = [{"op": "add", "entity": "requirement", "fields": {"text": c, "source_document_id": document.id}} for c in fresh]
    create_suggestion(
        db,
        project,
        "brief_update",
        ops,
        meta={"document_id": document.id, "document_title": document.title},
    )


def mark_for_retry(db: Session, document: Document) -> Document:
    document.status = "processing"
    document.error_code = None
    db.flush()
    return document


def delete_document(db: Session, document: Document) -> None:
    path = Path(document.storage_path)
    db.delete(document)
    db.flush()
    try:
        path.unlink(missing_ok=True)
    except OSError:  # pragma: no cover - file locked on Windows
        log.warning("could not delete %s", path)


def search_passages(db: Session, project_id: str, query: str, top_k: int = 8) -> list[Passage]:
    """Keyword retrieval, always filtered by project (master plan §9)."""
    rows = db.execute(
        select(DocumentChunk, Document.title)
        .join(Document, Document.id == DocumentChunk.document_id)
        .where(DocumentChunk.project_id == project_id, Document.status == "ready")
    ).all()
    if not rows:
        return []
    by_id = {chunk.id: (chunk, title) for chunk, title in rows}
    # Index the context header (title and heading path) together with the text.
    docs = [SearchDoc(chunk.id, f"{title}\n{chunk.heading_path}\n{chunk.text}") for chunk, title in rows]
    passages = []
    for hit in bm25_search(query, docs, top_k=top_k):
        chunk, title = by_id[hit.id]
        passages.append(
            Passage(
                chunk_id=chunk.id,
                document_id=chunk.document_id,
                document_title=title,
                page_start=chunk.page_start,
                page_end=chunk.page_end,
                heading_path=chunk.heading_path,
                text=chunk.text,
                relevant=is_relevant(hit),
            )
        )
    return passages
