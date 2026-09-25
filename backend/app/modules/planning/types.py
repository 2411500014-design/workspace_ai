"""Plain data types for the Planning Engine.

The planning module is pure Python: no database, no network, no clock. Every input
arrives as one of these values and every output is one of these values, so the whole
engine can be tested exhaustively (master plan §8, §10).
"""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass, field
from datetime import date
from typing import Literal

Feasibility = Literal["feasible", "tight", "infeasible"]
HealthStatus = Literal["on_track", "at_risk", "off_track"]

# Tolerance for float comparisons on hours.
EPS = 1e-6


@dataclass(frozen=True)
class Capacity:
    """How many hours the person can work on each day.

    ``hours_by_weekday`` is indexed like ``date.weekday()``: Monday is 0, Sunday is 6.
    ``blocked_dates`` are days with no capacity at all (exams, holidays).
    ``extra_hours`` adds hours on specific days; re-plan options use it to simulate
    "add three hours a week for four weeks".
    """

    hours_by_weekday: tuple[float, float, float, float, float, float, float]
    blocked_dates: frozenset[date] = frozenset()
    extra_hours: Mapping[date, float] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if len(self.hours_by_weekday) != 7:
            raise ValueError("hours_by_weekday must have exactly 7 values")
        if any(h < 0 for h in self.hours_by_weekday):
            raise ValueError("capacity cannot be negative")
        if any(h < 0 for h in self.extra_hours.values()):
            raise ValueError("extra hours cannot be negative")

    def hours_on(self, day: date) -> float:
        if day in self.blocked_dates:
            return 0.0
        return self.hours_by_weekday[day.weekday()] + self.extra_hours.get(day, 0.0)

    @property
    def weekly_hours(self) -> float:
        return float(sum(self.hours_by_weekday))

    def with_extra(self, extra: Mapping[date, float]) -> Capacity:
        merged = dict(self.extra_hours)
        for day, hours in extra.items():
            merged[day] = merged.get(day, 0.0) + hours
        return Capacity(self.hours_by_weekday, self.blocked_dates, merged)


@dataclass(frozen=True)
class PlanTask:
    """One unit of work as the scheduler sees it."""

    key: str
    estimate_hours: float
    depends_on: tuple[str, ...] = ()
    done: bool = False
    optional: bool = False
    # U in the priority formula: the user's own importance rating, 0, 0.5 or 1.
    importance: float = 0.0
    # Deferred tasks are out of scope for now ("kurangi scope"); they are not scheduled
    # and do not block the tasks that depend on them.
    deferred: bool = False

    @property
    def schedulable(self) -> bool:
        return not self.done and not self.deferred


@dataclass(frozen=True)
class ScheduleRequest:
    tasks: tuple[PlanTask, ...]
    start: date
    deadline: date
    capacity: Capacity
    buffer_pct: float = 0.15

    def __post_init__(self) -> None:
        if not 0 <= self.buffer_pct < 1:
            raise ValueError("buffer_pct must be in [0, 1)")


@dataclass(frozen=True)
class DayAllocation:
    day: date
    key: str
    hours: float


@dataclass(frozen=True)
class TaskPlan:
    key: str
    start: date | None
    end: date | None
    latest_finish: date | None
    # Hours of capacity between the scheduled finish and the latest allowed finish.
    # Negative means the task is scheduled to finish too late.
    slack_hours: float
    is_critical: bool
    priority: float

    @property
    def late(self) -> bool:
        return self.slack_hours < -EPS


@dataclass(frozen=True)
class ScheduleResult:
    tasks: Mapping[str, TaskPlan]
    allocations: tuple[DayAllocation, ...]
    order: tuple[str, ...]
    critical_path: tuple[str, ...]
    total_hours: float
    available_hours: float
    buffer_deadline: date
    projected_finish: date | None
    feasibility: Feasibility
    shortfall_hours: float

    @property
    def feasible(self) -> bool:
        return self.feasibility != "infeasible"
