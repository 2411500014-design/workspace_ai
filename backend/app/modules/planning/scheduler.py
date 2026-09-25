"""The MVP scheduler (master plan §8, "Algoritma scheduler").

1. Validate the dependency graph with Kahn's algorithm; a cycle is rejected.
2. Critical path: the dependency chain with the largest total estimate.
3. Backward pass: the latest finish of every task, counted back from the deadline
   minus the buffer (default 15%).
4. Capacity-based forward pass: fill working days from today in topological order,
   the task with the least slack first.
5. Feasibility: when the work exceeds the capacity before the deadline, report the
   shortfall in hours.

One person does the work, so tasks run one after another and share each day's
capacity. Finish-to-start dependencies only.
"""

from __future__ import annotations

import heapq
import math
from datetime import date

from .graph import downstream_counts, topological_order
from .priority import normalise, priority_score
from .timeline import MAX_HORIZON_DAYS, Timeline
from .types import EPS, DayAllocation, ScheduleRequest, ScheduleResult, TaskPlan


def _round(hours: float) -> float:
    return round(hours + 0.0, 4)


def schedule(req: ScheduleRequest) -> ScheduleResult:
    by_key = {task.key: task for task in req.tasks}
    keys = [task.key for task in req.tasks]
    deps = {task.key: task.depends_on for task in req.tasks}
    # Validates the whole graph, including finished and deferred tasks.
    full_order = topological_order(keys, deps)

    active = [k for k in full_order if by_key[k].schedulable]
    active_set = set(active)
    for k in active:
        if by_key[k].estimate_hours <= 0:
            raise ValueError(f"task {k!r} needs a positive estimate")
    # Finished or deferred prerequisites no longer block anything.
    adeps = {k: tuple(d for d in by_key[k].depends_on if d in active_set) for k in active}
    est = {k: float(by_key[k].estimate_hours) for k in active}
    succ: dict[str, list[str]] = {k: [] for k in active}
    for k in active:
        for d in adeps[k]:
            succ[d].append(k)
    position = {k: i for i, k in enumerate(keys)}

    timeline = Timeline(req.start, req.capacity)
    available = timeline.hours_through(req.deadline) if req.deadline >= req.start else 0.0
    latest_total = available * (1.0 - req.buffer_pct)
    # latest_total never exceeds the capacity up to the deadline, so this day is on or
    # before the deadline. Without any capacity the deadline itself is the limit.
    buffer_deadline = (timeline.day_reaching(latest_total) if latest_total > EPS else None) or req.deadline

    # --- Step 2: critical path on estimates alone (classic CPM) ----------------------
    es: dict[str, float] = {}
    ef: dict[str, float] = {}
    for k in active:
        es[k] = max((ef[d] for d in adeps[k]), default=0.0)
        ef[k] = es[k] + est[k]
    length = max(ef.values(), default=0.0)
    ls: dict[str, float] = {}
    for k in reversed(active):
        lf = min((ls[c] for c in succ[k]), default=length)
        ls[k] = lf - est[k]
    critical = {k for k in active if ls[k] - es[k] <= EPS}
    critical_path = _critical_chain(active, adeps, succ, es, ef, critical)

    # --- Step 3: backward pass in capacity space --------------------------------------
    lf_cap: dict[str, float] = {}
    ls_cap: dict[str, float] = {}
    for k in reversed(active):
        lf_cap[k] = min((ls_cap[c] for c in succ[k]), default=latest_total)
        ls_cap[k] = lf_cap[k] - est[k]

    # --- Step 4: serial forward pass, least slack first --------------------------------
    indegree = {k: len(adeps[k]) for k in active}
    importance = {k: by_key[k].importance for k in active}
    ready = [(lf_cap[k], -importance[k], position[k], k) for k in active if indegree[k] == 0]
    heapq.heapify(ready)
    sequence: list[str] = []
    ef_cap: dict[str, float] = {}
    cursor = 0.0
    while ready:
        _, _, _, k = heapq.heappop(ready)
        sequence.append(k)
        cursor += est[k]
        ef_cap[k] = cursor
        for c in succ[k]:
            indegree[c] -= 1
            if indegree[c] == 0:
                heapq.heappush(ready, (lf_cap[c], -importance[c], position[c], c))
    total = cursor

    allocations, spans = _allocate(sequence, est, timeline, req.start)

    # --- Step 5: feasibility -----------------------------------------------------------
    if total > available + EPS:
        feasibility = "infeasible"
    elif total > latest_total + EPS:
        feasibility = "tight"
    else:
        feasibility = "feasible"
    shortfall = max(0.0, total - available)
    projected_finish = spans[sequence[-1]][1] if sequence and sequence[-1] in spans else None

    # --- Priority ----------------------------------------------------------------------
    slack = {k: lf_cap[k] - ef_cap[k] for k in active}
    max_slack = max((max(s, 0.0) for s in slack.values()), default=0.0)
    downstream = downstream_counts(active, adeps) if active else {}
    max_down = max(downstream.values(), default=0)

    plans: dict[str, TaskPlan] = {}
    for k in active:
        start_day, end_day = spans.get(k, (None, None))
        latest_day = timeline.day_reaching(lf_cap[k]) if lf_cap[k] > EPS else req.start
        plans[k] = TaskPlan(
            key=k,
            start=start_day,
            end=end_day,
            latest_finish=latest_day,
            slack_hours=_round(slack[k]),
            is_critical=k in critical,
            priority=priority_score(
                critical=k in critical,
                slack_norm=normalise(max(slack[k], 0.0), max_slack),
                dependents_norm=normalise(downstream.get(k, 0), max_down),
                importance=min(max(importance[k], 0.0), 1.0),
            ),
        )

    return ScheduleResult(
        tasks=plans,
        allocations=tuple(allocations),
        order=tuple(sequence),
        critical_path=critical_path,
        total_hours=_round(total),
        available_hours=_round(available),
        buffer_deadline=buffer_deadline,
        projected_finish=projected_finish,
        feasibility=feasibility,
        # Rounded up, so an infeasible plan never reports a shortfall of zero.
        shortfall_hours=math.ceil(shortfall * 10_000 - EPS) / 10_000 if shortfall > EPS else 0.0,
    )


def _allocate(
    sequence: list[str], est: dict[str, float], timeline: Timeline, start: date
) -> tuple[list[DayAllocation], dict[str, tuple[date, date]]]:
    """Fill working days in order.

    A task that cannot be finished within the horizon (for example because there is no
    capacity at all) gets no span, so callers see it without start or end dates.
    """
    allocations: list[DayAllocation] = []
    spans: dict[str, tuple[date, date]] = {}
    day_index = 0
    used_today = 0.0
    origin = start.toordinal()
    for k in sequence:
        remaining = est[k]
        first: date | None = None
        last: date | None = None
        while remaining > EPS and day_index < MAX_HORIZON_DAYS:
            day = date.fromordinal(origin + day_index)
            free = timeline.hours_on(day) - used_today
            if free <= EPS:
                day_index += 1
                used_today = 0.0
                continue
            take = min(remaining, free)
            # Not rounded: rounding each piece separately can push a day's total past
            # its capacity. Round only when displaying.
            allocations.append(DayAllocation(day=day, key=k, hours=take))
            first = first or day
            last = day
            remaining -= take
            used_today += take
        if remaining <= EPS and first is not None and last is not None:
            spans[k] = (first, last)
    return allocations, spans


def _critical_chain(active, adeps, succ, es, ef, critical) -> tuple[str, ...]:
    """One deterministic longest chain through the critical tasks."""
    if not critical:
        return ()
    current = next((k for k in active if k in critical and not adeps[k]), None)
    chain: list[str] = []
    while current is not None:
        chain.append(current)
        nxt = None
        for c in succ[current]:
            if c in critical and abs(es[c] - ef[current]) <= EPS:
                nxt = c
                break
        current = nxt
    return tuple(chain)
