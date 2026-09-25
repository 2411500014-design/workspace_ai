from datetime import date, timedelta

import pytest

from app.modules.planning import (
    Capacity,
    PlanTask,
    ScheduleRequest,
    TaskProgress,
    calibration_factor,
    compute_health,
    replan_options,
)

TODAY = date(2026, 11, 2)


def progress(key, hours, done, days_until_due, critical=False):
    return TaskProgress(key, hours, done, TODAY + timedelta(days=days_until_due), critical)


# --- health ------------------------------------------------------------------------------


def test_plan_example_40_percent_planned_30_percent_done_is_at_risk():
    # Master plan §8: 40% of hours due, 30% actually done -> SPI 0.75 -> At Risk.
    tasks = [
        progress("A", 30, True, -5),
        progress("B", 10, False, -1),
        progress("C", 60, False, 10),
    ]
    health = compute_health(tasks, TODAY)
    assert health.planned_pct == 0.4
    assert health.actual_pct == 0.3
    assert health.spi == 0.75
    assert health.status == "at_risk"
    assert health.reasons == ("spi_moderate",)


def test_on_track_when_everything_due_is_done():
    tasks = [progress("A", 10, True, -2), progress("B", 10, False, 5)]
    health = compute_health(tasks, TODAY)
    assert health.spi == 1.0
    assert health.status == "on_track"


def test_low_spi_is_off_track():
    tasks = [progress("A", 10, False, -2), progress("B", 10, True, -1), progress("C", 10, False, 5)]
    assert compute_health(tasks, TODAY).status == "off_track"  # SPI 0.5


def test_spi_is_ignored_until_five_percent_of_work_was_due():
    # 2 of 100 hours due and not done: SPI would be 0, but it is not yet stable.
    tasks = [progress("A", 2, False, -1), progress("B", 98, False, 30)]
    health = compute_health(tasks, TODAY)
    assert not health.spi_stable
    assert health.status == "on_track"


@pytest.mark.parametrize(("days_late", "status"), [(1, "at_risk"), (3, "at_risk"), (4, "off_track")])
def test_late_critical_task_rules(days_late, status):
    tasks = [progress("K", 1, False, -days_late, critical=True), progress("Z", 100, True, 20)]
    health = compute_health(tasks, TODAY)
    assert health.critical_late_days == days_late
    assert health.status == status


def test_infeasible_plan_is_off_track():
    assert compute_health([progress("A", 5, False, 10)], TODAY, feasible=False).status == "off_track"


def test_calibration_factor_is_the_median_ratio():
    assert calibration_factor([(2, 3), (4, 4), (10, 5)]) == 1.0
    assert calibration_factor([(2, 3), (2, 3), (4, 4)]) == 1.5
    assert calibration_factor([]) == 1.0


# --- re-plan -----------------------------------------------------------------------------


MON = date(2026, 9, 28)


def test_feasible_plan_only_offers_a_reschedule():
    req = ScheduleRequest((PlanTask("A", 4),), MON, MON + timedelta(days=30), Capacity((2, 2, 2, 2, 2, 0, 0)))
    options = replan_options(req)
    assert [o.kind for o in options] == ["reschedule"]


def test_infeasible_plan_gets_recovery_options():
    tasks = (
        PlanTask("core", 20),
        PlanTask("extra", 8, ("core",), optional=True),
    )
    # Two working weeks at 2h/day = 20h, far short of 28h.
    req = ScheduleRequest(tasks, MON, MON + timedelta(days=13), Capacity((2, 2, 2, 2, 2, 0, 0)))
    options = {o.kind: o for o in replan_options(req)}
    assert options["reschedule"].result.feasibility == "infeasible"

    boost = options["add_capacity"]
    assert boost.result.feasibility == "feasible"
    assert boost.params["hours_per_week"] >= 1

    reduced = options["reduce_scope"]
    assert reduced.params["deferred"] == ["extra"]
    assert "extra" not in reduced.result.tasks

    extended = options["extend_deadline"]
    assert extended.result.feasibility == "feasible"
    assert date.fromisoformat(extended.params["new_deadline"]) > req.deadline

    ordered = replan_options(req)
    assert ordered[0].result.feasibility == "feasible"
