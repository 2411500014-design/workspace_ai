from __future__ import annotations

from datetime import datetime

from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.db import Base, new_id, utcnow


class Document(Base):
    __tablename__ = "documents"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    project_id: Mapped[str] = mapped_column(ForeignKey("projects.id", ondelete="CASCADE"), index=True)
    # proposal | instruction | journal | supervision | draft | other
    kind: Mapped[str] = mapped_column(String(12), default="other")
    title: Mapped[str] = mapped_column(String(300))
    filename: Mapped[str] = mapped_column(String(300))
    storage_path: Mapped[str] = mapped_column(String(500))
    mime: Mapped[str] = mapped_column(String(100))
    size_bytes: Mapped[int] = mapped_column(Integer)
    pages: Mapped[int | None] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(12), default="processing")  # processing | ready | failed
    error_code: Mapped[str | None] = mapped_column(String(40))
    summary: Mapped[str] = mapped_column(Text, default="")
    summary_ai: Mapped[bool] = mapped_column(default=False)
    doc_metadata: Mapped[dict] = mapped_column("metadata", default=dict)  # authors, year, doi
    checksum: Mapped[str] = mapped_column(String(64))
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class DocumentChunk(Base):
    """A searchable piece of a document with its page range and heading path.

    PostgreSQL adds an ``embedding`` (pgvector) and a ``tsv`` column in production;
    local SQLite development uses keyword search only (ADR-0002).
    """

    __tablename__ = "document_chunks"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    document_id: Mapped[str] = mapped_column(ForeignKey("documents.id", ondelete="CASCADE"), index=True)
    project_id: Mapped[str] = mapped_column(ForeignKey("projects.id", ondelete="CASCADE"), index=True)
    position: Mapped[int] = mapped_column(Integer)
    text: Mapped[str] = mapped_column(Text)
    page_start: Mapped[int] = mapped_column(Integer)
    page_end: Mapped[int] = mapped_column(Integer)
    heading_path: Mapped[str] = mapped_column(String(500), default="")
    token_count: Mapped[int] = mapped_column(Integer, default=0)
