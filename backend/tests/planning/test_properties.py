"""Property-based tests for the scheduler (master plan §14).

Hypothesis generates thousands of random projects and checks that these rules always hold:
- a task never starts before its dependencies have finished;
- no day gets more hours than its capacity;
- a feasible plan always finishes before the deadline.
"""

from collections import defaultdict
from datetime import date, timedelta

from hypothesis import HealthCheck, example, given, settings
from hypothesis import strategies as st

from app.modules.planning import Capacity, PlanTask, ScheduleRequest, compute_health, schedule
from app.modules.planning.health import TaskProgress

START = date(2026, 9, 28)


@st.composite
def projects(draw):
    n = draw(st.integers(min_value=1, max_value=14))
    keys = [f"T{i}" for i in range(n)]
    tasks = []
    for i, key in enumerate(keys):
        # Only depend on earlier keys, so the graph is always acyclic.
        parents = draw(st.lists(st.sampled_from(keys[:i]), unique=True, max_size=3)) if i else []
        tasks.append(
            PlanTask(
                key=key,
                estimate_hours=draw(st.floats(min_value=0.5, max_value=40, allow_nan=False)),
                depends_on=tuple(parents),
                done=draw(st.booleans()) if draw(st.integers(0, 4)) == 0 else False,
                optional=draw(st.booleans()),
                importance=draw(st.sampled_from([0.0, 0.5, 1.0])),
            )
        )
    hours = tuple(draw(st.sampled_from([0, 0, 1, 2, 3, 4, 8])) for _ in range(7))
    if sum(hours) == 0:
        hours = (2, 2, 2, 2, 2, 0, 0)
    blocked = frozenset(
        START + timedelta(days=d) for d in draw(st.lists(st.integers(0, 120), max_size=10, unique=True))
    )
    deadline = START + timedelta(days=draw(st.integers(0, 400)))
    buffer = draw(st.sampled_from([0.0, 0.1, 0.15, 0.3]))
    return ScheduleRequest(tuple(tasks), START, deadline, Capacity(hours, blocked), buffer)


RUNS = settings(max_examples=1500, deadline=None, suppress_health_check=[HealthCheck.too_slow])


@RUNS
@given(projects())
def test_dependencies_finish_before_dependents_start(req):
    result = schedule(req)
    by_key = {t.key: t for t in req.tasks}
    last_hour_day = {}
    first_day = {}
    for alloc in result.allocations:
        first_day.setdefault(alloc.key, alloc.day)
        last_hour_day[alloc.key] = alloc.day
    position = {k: i for i, k in enumerate(result.order)}
    for key, plan in result.tasks.items():
        for parent in by_key[key].depends_on:
            if parent not in result.tasks:
                continue  # finished or deferred prerequisites do not block
            assert position[parent] < position[key]
            if plan.start is not None and result.tasks[parent].end is not None:
                assert result.tasks[parent].end <= plan.start


@RUNS
@given(projects())
def test_daily_hours_never_exceed_capacity(req):
    result = schedule(req)
    per_day = defaultdict(float)
    for alloc in result.allocations:
        assert alloc.hours > 0
        per_day[alloc.day] += alloc.hours
    for day, hours in per_day.items():
        assert hours <= req.capacity.hours_on(day) + 1e-6


@RUNS
@given(projects())
def test_every_scheduled_hour_is_accounted_for(req):
    result = schedule(req)
    placed = defaultdict(float)
    for alloc in result.allocations:
        placed[alloc.key] += alloc.hours
    for key, plan in result.tasks.items():
        estimate = next(t.estimate_hours for t in req.tasks if t.key == key)
        if plan.end is not None:
            assert abs(placed[key] - estimate) < 1e-3


@RUNS
@given(projects())
# Found by Hypothesis: a few seconds over capacity used to report a shortfall of 0.
@example(
    ScheduleRequest(
        (PlanTask(key="T0", estimate_hours=2.00001),),
        START,
        START,
        Capacity((2, 2, 2, 2, 2, 0, 0), frozenset()),
        0.0,
    )
)
def test_feasible_plans_finish_before_the_deadline(req):
    result = schedule(req)
    if result.feasibility == "feasible" and result.total_hours > 0:
        assert result.projected_finish is not None
        assert result.projected_finish <= result.buffer_deadline <= req.deadline
    if result.feasibility in ("feasible", "tight") and result.total_hours > 0:
        assert result.projected_finish <= req.deadline
    if result.feasibility == "infeasible":
        assert result.shortfall_hours > 0


@RUNS
@given(projects())
def test_priorities_are_normalised(req):
    result = schedule(req)
    for plan in result.tasks.values():
        assert 0.0 <= plan.priority <= 1.0
    for key in result.critical_path:
        assert result.tasks[key].is_critical


@RUNS
@given(projects(), st.integers(0, 200))
def test_health_is_always_a_valid_status(req, day_offset):
    result = schedule(req)
    today = START + timedelta(days=day_offset)
    progress = [
        TaskProgress(t.key, t.estimate_hours, t.done, result.tasks[t.key].end if t.key in result.tasks else None,
                     result.tasks[t.key].is_critical if t.key in result.tasks else False)
        for t in req.tasks
    ]
    health = compute_health(progress, today, feasible=result.feasible)
    assert health.status in ("on_track", "at_risk", "off_track")
    assert 0 <= health.planned_pct <= 1 and 0 <= health.actual_pct <= 1
    if not result.feasible:
        assert health.status == "off_track"
