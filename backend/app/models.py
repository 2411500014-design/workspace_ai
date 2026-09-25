"""Imports every ORM model so ``Base.metadata`` (and Alembic) sees all 21 tables."""

from app.modules.accounts.models import Profile, Workspace, WorkspaceMember
from app.modules.ai.models import AiMessage, AiSuggestion, AiThread, UsageLedger
from app.modules.documents.models import Document, DocumentChunk
from app.modules.insight.models import ActivityEvent, Notification, ProgressSnapshot
from app.modules.projects.models import Note, Project, ProjectBrief, ProjectMemory, Requirement
from app.modules.tasks.models import Milestone, Task, TaskDependency, TaskRequirement

__all__ = [
    "ActivityEvent",
    "AiMessage",
    "AiSuggestion",
    "AiThread",
    "Document",
    "DocumentChunk",
    "Milestone",
    "Note",
    "Notification",
    "Profile",
    "ProgressSnapshot",
    "Project",
    "ProjectBrief",
    "ProjectMemory",
    "Requirement",
    "Task",
    "TaskDependency",
    "TaskRequirement",
    "UsageLedger",
    "Workspace",
    "WorkspaceMember",
]
