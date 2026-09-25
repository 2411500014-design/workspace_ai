"""Re-plan options (master plan §8, "Re-plan").

The scheduler simulates several recovery options; the LLM only explains them and the
user picks one. Every option here is a complete, re-scheduled plan, so the app can show
exactly what would change before anything is applied.

| Option                    | Example                                                  |
|---------------------------|----------------------------------------------------------|
| Add capacity              | 3 more hours a week for 4 weeks                          |
| Reschedule non-critical   | Move tasks with plenty of slack later                     |
| Reduce scope              | Defer optional tasks (e.g. an extra experiment)          |
| Move the internal target  | Push the target back, only if campus rules allow it      |
"""

from __future__ import annotations

from dataclasses import dataclass, field, replace
from datetime import date, timedelta
from typing import Literal

from .scheduler import schedule
from .timeline import Timeline
from .types import ScheduleRequest, ScheduleResult

OptionKind = Literal["reschedule", "add_capacity", "reduce_scope", "extend_deadline"]

MAX_EXTRA_HOURS_PER_WEEK = 20
DEFAULT_BOOST_WEEKS = 4


@dataclass(frozen=True)
class ReplanOption:
    kind: OptionKind
    result: ScheduleResult
    params: dict = field(default_factory=dict)


def boost_extra(req: ScheduleRequest, hours_per_week: float, weeks: int) -> dict[date, float]:
    """Extra hours per day: ``hours_per_week`` spread over the days that already have capacity."""
    extra: dict[date, float] = {}
    for week in range(weeks):
        week_start = req.start + timedelta(days=7 * week)
        days = [week_start + timedelta(days=i) for i in range(7)]
        working = [d for d in days if d <= req.deadline and req.capacity.hours_on(d) > 0]
        if not working:
            continue
        per_day = hours_per_week / len(working)
        for d in working:
            extra[d] = extra.get(d, 0.0) + per_day
    return extra


def _boost(req: ScheduleRequest, hours_per_week: float, weeks: int) -> ScheduleRequest:
    return replace(req, capacity=req.capacity.with_extra(boost_extra(req, hours_per_week, weeks)))


def replan_options(req: ScheduleRequest) -> list[ReplanOption]:
    base = schedule(req)
    options = [ReplanOption("reschedule", base)]
    if base.feasibility == "feasible":
        return options

    weeks_left = max(1, (req.deadline - req.start).days // 7 + 1)
    for weeks in sorted({min(DEFAULT_BOOST_WEEKS, weeks_left), weeks_left}):
        found = None
        for extra in range(1, MAX_EXTRA_HOURS_PER_WEEK + 1):
            candidate = schedule(_boost(req, extra, weeks))
            if candidate.feasibility == "feasible":
                found = ReplanOption("add_capacity", candidate, {"hours_per_week": extra, "weeks": weeks})
                break
        if found:
            options.append(found)
            break

    optional_keys = [t.key for t in req.tasks if t.optional and t.schedulable]
    if optional_keys:
        reduced = replace(
            req,
            tasks=tuple(replace(t, deferred=True) if t.key in optional_keys else t for t in req.tasks),
        )
        options.append(ReplanOption("reduce_scope", schedule(reduced), {"deferred": optional_keys}))

    if base.total_hours > 0:
        # The earliest deadline that gives this plan its full buffer again: the day by
        # which capacity reaches total / (1 - buffer).
        needed = Timeline(req.start, req.capacity).day_reaching(base.total_hours / (1.0 - req.buffer_pct))
        if needed is not None and needed > req.deadline:
            candidate = schedule(replace(req, deadline=needed))
            if candidate.feasibility == "feasible":
                options.append(
                    ReplanOption(
                        "extend_deadline",
                        candidate,
                        {"new_deadline": needed.isoformat(), "days": (needed - req.deadline).days},
                    )
                )

    # Options that actually fix the plan first, then by projected finish.
    def sort_key(option: ReplanOption):
        order = {"feasible": 0, "tight": 1, "infeasible": 2}[option.result.feasibility]
        finish = option.result.projected_finish or date.max
        return (order, finish, option.kind)

    return sorted(options, key=sort_key)
