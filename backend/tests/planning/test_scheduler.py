from datetime import date, timedelta

import pytest

from app.modules.planning import (
    Capacity,
    CycleError,
    DuplicateKeyError,
    PlanTask,
    ScheduleRequest,
    UnknownDependencyError,
    schedule,
    topological_order,
)

MON = date(2026, 9, 28)  # a Monday
WEEKDAYS_2H = Capacity((2, 2, 2, 2, 2, 0, 0))  # 10 hours a week, weekends off


def req(tasks, deadline=MON + timedelta(days=60), capacity=WEEKDAYS_2H, start=MON, buffer=0.15):
    return ScheduleRequest(tuple(tasks), start, deadline, capacity, buffer)


# --- graph ---------------------------------------------------------------------------


def test_topological_order_respects_dependencies_and_input_order():
    keys = ["A", "B", "C", "D"]
    deps = {"C": ["A"], "D": ["B", "C"]}
    assert topological_order(keys, deps) == ["A", "B", "C", "D"]


def test_cycle_is_rejected_with_the_keys_involved():
    with pytest.raises(CycleError) as err:
        topological_order(["A", "B", "C"], {"A": ["C"], "B": ["A"], "C": ["B"]})
    assert err.value.keys == ("A", "B", "C")


def test_unknown_dependency_and_duplicate_keys_are_rejected():
    with pytest.raises(UnknownDependencyError):
        topological_order(["A"], {"A": ["Z"]})
    with pytest.raises(DuplicateKeyError):
        topological_order(["A", "A"], {})


# --- forward pass ----------------------------------------------------------------------


def test_chain_is_scheduled_in_order_within_daily_capacity():
    result = schedule(req([PlanTask("A", 3), PlanTask("B", 3, ("A",))]))
    a, b = result.tasks["A"], result.tasks["B"]
    # 2h Monday + 1h Tuesday for A, then 1h Tuesday + 2h Wednesday for B.
    assert (a.start, a.end) == (MON, MON + timedelta(days=1))
    assert (b.start, b.end) == (MON + timedelta(days=1), MON + timedelta(days=2))
    assert result.order == ("A", "B")
    per_day = {}
    for alloc in result.allocations:
        per_day[alloc.day] = per_day.get(alloc.day, 0) + alloc.hours
    assert all(hours <= 2 + 1e-9 for hours in per_day.values())


def test_weekends_and_blocked_dates_get_no_work():
    blocked = frozenset({MON + timedelta(days=1)})  # Tuesday: exam
    capacity = Capacity((2, 2, 2, 2, 2, 0, 0), blocked_dates=blocked)
    result = schedule(req([PlanTask("A", 12)], capacity=capacity))
    days = {a.day for a in result.allocations}
    assert MON + timedelta(days=1) not in days
    assert all(d.weekday() < 5 for d in days)
    # 12h at 2h/day without Tuesday: Mon, Wed, Thu, Fri, next Mon, next Tue.
    assert result.tasks["A"].end == MON + timedelta(days=8)


def test_least_slack_task_goes_first():
    # B has a long chain behind it, so it has less slack than A and must come first.
    tasks = [
        PlanTask("A", 2),
        PlanTask("B", 2),
        PlanTask("C", 10, ("B",)),
        PlanTask("D", 10, ("C",)),
    ]
    result = schedule(req(tasks, deadline=MON + timedelta(days=20)))
    assert result.order.index("B") < result.order.index("A")


def test_done_and_deferred_tasks_are_not_scheduled_and_do_not_block():
    tasks = [
        PlanTask("A", 5, done=True),
        PlanTask("X", 5, optional=True, deferred=True),
        PlanTask("B", 2, ("A", "X")),
    ]
    result = schedule(req(tasks))
    assert set(result.tasks) == {"B"}
    assert result.tasks["B"].start == MON
    assert result.total_hours == 2


# --- critical path and backward pass --------------------------------------------------


def test_critical_path_is_the_longest_chain():
    tasks = [
        PlanTask("M1", 6),
        PlanTask("M2", 4, ("M1",)),
        PlanTask("M3", 20, ("M2",)),
        PlanTask("M4", 8, ("M1", "M2")),
        PlanTask("S", 2, ("M4",)),
        PlanTask("M5", 10, ("S", "M3")),
    ]
    result = schedule(req(tasks, deadline=MON + timedelta(days=120)))
    assert result.critical_path == ("M1", "M2", "M3", "M5")
    assert result.tasks["M3"].is_critical
    assert not result.tasks["M4"].is_critical


def test_latest_finish_respects_the_buffer_before_the_deadline():
    deadline = MON + timedelta(days=13)  # two working weeks: 20h of capacity
    result = schedule(req([PlanTask("A", 4)], deadline=deadline))
    assert result.available_hours == 20
    # 15% buffer: latest finish is after 17h of capacity. Cumulative capacity is 16h at
    # the end of Wednesday (day 9) and 18h at the end of Thursday (day 10).
    assert result.buffer_deadline == MON + timedelta(days=10)
    assert result.tasks["A"].latest_finish == result.buffer_deadline
    assert result.tasks["A"].slack_hours == pytest.approx(13)


# --- feasibility -----------------------------------------------------------------------


def test_feasibility_levels_and_shortfall():
    deadline = MON + timedelta(days=13)  # 20h available, 17h before the buffer
    assert schedule(req([PlanTask("A", 16)], deadline=deadline)).feasibility == "feasible"
    assert schedule(req([PlanTask("A", 19)], deadline=deadline)).feasibility == "tight"
    late = schedule(req([PlanTask("A", 25)], deadline=deadline))
    assert late.feasibility == "infeasible"
    assert late.shortfall_hours == 5
    assert late.projected_finish == MON + timedelta(days=16)
    assert late.tasks["A"].late


def test_zero_capacity_never_finishes():
    result = schedule(req([PlanTask("A", 3)], capacity=Capacity((0,) * 7)))
    assert result.feasibility == "infeasible"
    assert result.projected_finish is None
    assert result.tasks["A"].start is None and result.tasks["A"].end is None


def test_empty_plan_is_trivially_feasible():
    result = schedule(req([]))
    assert result.feasibility == "feasible"
    assert result.total_hours == 0
    assert result.projected_finish is None


def test_estimate_must_be_positive():
    with pytest.raises(ValueError):
        schedule(req([PlanTask("A", 0)]))


# --- priority --------------------------------------------------------------------------


def test_priority_is_between_zero_and_one_and_favours_critical_blockers():
    tasks = [
        PlanTask("A", 4),
        PlanTask("B", 4, ("A",)),
        PlanTask("C", 4, ("B",)),
        PlanTask("side", 1),
    ]
    result = schedule(req(tasks, deadline=MON + timedelta(days=40)))
    scores = {k: t.priority for k, t in result.tasks.items()}
    assert all(0 <= s <= 1 for s in scores.values())
    assert scores["A"] > scores["side"]
    assert scores["A"] >= scores["C"]


def test_importance_breaks_ties():
    tasks = [PlanTask("plain", 2), PlanTask("important", 2, importance=1.0)]
    result = schedule(req(tasks))
    assert result.order[0] == "important"
    assert result.tasks["important"].priority > result.tasks["plain"].priority
