"""Mode presets (master plan §5): YAML files in ``modes/`` at the repository root.

A mode is configuration, not code: templates, UI terms, AI persona and features. Every
user-facing text is stored as ``{"id": ..., "en": ...}``.
"""

from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

import yaml

from app.core.config import get_settings
from app.modules.planning import topological_order

SUPPORTED_LOCALES = ("id", "en")


def localized(value: dict | str | None, locale: str) -> str:
    """Pick the text for ``locale``; fall back to Indonesian, then to any value."""
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    return value.get(locale) or value.get("id") or next(iter(value.values()), "")


def localized_list(value: dict | list | None, locale: str) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(v) for v in value]
    return list(value.get(locale) or value.get("id") or [])


@dataclass(frozen=True)
class TemplateTask:
    key: str
    hours: float
    title: dict
    after: tuple[str, ...] = ()
    optional: bool = False
    done: dict | None = None


@dataclass(frozen=True)
class TemplateMilestone:
    key: str
    title: dict
    tasks: tuple[TemplateTask, ...]


@dataclass(frozen=True)
class Template:
    id: str
    name: dict
    description: dict
    deliverables: dict
    open_questions: dict
    milestones: tuple[TemplateMilestone, ...]

    def all_tasks(self) -> list[TemplateTask]:
        return [task for milestone in self.milestones for task in milestone.tasks]


@dataclass(frozen=True)
class Mode:
    id: str
    version: int
    name: dict
    persona: dict
    terms: dict
    features: tuple[str, ...]
    templates: tuple[Template, ...]

    def template(self, template_id: str) -> Template | None:
        return next((t for t in self.templates if t.id == template_id), None)


class PresetError(ValueError):
    pass


def _parse_mode(data: dict, source: Path) -> Mode:
    templates = []
    for raw in data.get("templates", []):
        milestones = []
        for m in raw.get("milestones", []):
            tasks = tuple(
                TemplateTask(
                    key=t["key"],
                    hours=float(t["hours"]),
                    title=t["title"],
                    after=tuple(t.get("after", ())),
                    optional=bool(t.get("optional", False)),
                    done=t.get("done"),
                )
                for t in m.get("tasks", [])
            )
            milestones.append(TemplateMilestone(key=m["key"], title=m["title"], tasks=tasks))
        template = Template(
            id=raw["id"],
            name=raw["name"],
            description=raw.get("description", {}),
            deliverables=raw.get("deliverables", {}),
            open_questions=raw.get("open_questions", {}),
            milestones=tuple(milestones),
        )
        _validate_template(template, source)
        templates.append(template)
    return Mode(
        id=data["id"],
        version=int(data.get("version", 1)),
        name=data["name"],
        persona=data.get("persona", {}),
        terms=data.get("terms", {}),
        features=tuple(data.get("features", ())),
        templates=tuple(templates),
    )


def _validate_template(template: Template, source: Path) -> None:
    tasks = template.all_tasks()
    keys = [t.key for t in tasks]
    milestone_keys = [m.key for m in template.milestones]
    if len(set(milestone_keys)) != len(milestone_keys):
        raise PresetError(f"{source.name}/{template.id}: duplicate milestone key")
    for task in tasks:
        if not 0.5 <= task.hours <= 40:
            raise PresetError(f"{source.name}/{template.id}/{task.key}: estimate outside 0.5-40 hours")
        for locale in SUPPORTED_LOCALES:
            if not localized(task.title, locale):
                raise PresetError(f"{source.name}/{template.id}/{task.key}: missing {locale} title")
    try:
        topological_order(keys, {t.key: t.after for t in tasks})
    except ValueError as exc:
        raise PresetError(f"{source.name}/{template.id}: {exc}") from exc


@lru_cache
def load_modes(directory: str | None = None) -> dict[str, Mode]:
    folder = Path(directory) if directory else get_settings().modes_dir
    modes: dict[str, Mode] = {}
    for path in sorted(folder.glob("*.yaml")):
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
        mode = _parse_mode(data, path)
        modes[mode.id] = mode
    if not modes:
        raise PresetError(f"no mode presets found in {folder}")
    return modes


def get_mode(mode_id: str) -> Mode | None:
    return load_modes().get(mode_id)
