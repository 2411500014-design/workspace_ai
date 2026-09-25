"""Progress and health score (master plan §8).

Progress is weighted by estimated hours, so a 10-hour task counts more than a 1-hour one.

    SPI = hours of finished tasks / hours of tasks scheduled to be finished by today

| Status    | Condition                                                              |
|-----------|------------------------------------------------------------------------|
| On Track  | SPI >= 0.90 and no critical task late                                  |
| At Risk   | SPI 0.75 up to below 0.90, or a critical task 1-3 days late            |
| Off Track | SPI < 0.75, a critical task more than 3 days late, or plan infeasible  |

While less than 5% of the work was due, SPI is not yet stable and only the late-task
rules apply.
"""

from __future__ import annotations

from collections.abc import Iterable
from dataclasses import dataclass
from datetime import date
from statistics import median

from .types import EPS, HealthStatus

SPI_ON_TRACK = 0.90
SPI_AT_RISK = 0.75
SPI_STABLE_FROM = 0.05
LATE_AT_RISK_MAX_DAYS = 3


@dataclass(frozen=True)
class TaskProgress:
    key: str
    estimate_hours: float
    done: bool
    scheduled_end: date | None
    is_critical: bool = False


@dataclass(frozen=True)
class HealthResult:
    status: HealthStatus
    spi: float | None
    planned_pct: float
    actual_pct: float
    spi_stable: bool
    critical_late_days: int
    # Machine-readable reasons; the app turns them into sentences in both languages.
    reasons: tuple[str, ...]


def compute_health(tasks: Iterable[TaskProgress], today: date, feasible: bool = True) -> HealthResult:
    items = list(tasks)
    total = sum(t.estimate_hours for t in items)
    planned = sum(t.estimate_hours for t in items if t.scheduled_end is not None and t.scheduled_end < today)
    actual = sum(t.estimate_hours for t in items if t.done)

    planned_pct = planned / total if total > EPS else 0.0
    actual_pct = actual / total if total > EPS else 0.0
    spi_stable = planned_pct >= SPI_STABLE_FROM
    spi = actual / planned if planned > EPS else None

    critical_late_days = max(
        (
            (today - t.scheduled_end).days
            for t in items
            if t.is_critical and not t.done and t.scheduled_end is not None and t.scheduled_end < today
        ),
        default=0,
    )

    reasons: list[str] = []
    if not feasible:
        reasons.append("infeasible")
    if critical_late_days > LATE_AT_RISK_MAX_DAYS:
        reasons.append("critical_late_major")
    elif critical_late_days >= 1:
        reasons.append("critical_late_minor")
    if spi_stable and spi is not None:
        if spi < SPI_AT_RISK:
            reasons.append("spi_low")
        elif spi < SPI_ON_TRACK:
            reasons.append("spi_moderate")

    if {"infeasible", "critical_late_major", "spi_low"} & set(reasons):
        status: HealthStatus = "off_track"
    elif {"critical_late_minor", "spi_moderate"} & set(reasons):
        status = "at_risk"
    else:
        status = "on_track"

    return HealthResult(
        status=status,
        spi=round(spi, 4) if spi is not None else None,
        planned_pct=round(planned_pct, 4),
        actual_pct=round(actual_pct, 4),
        spi_stable=spi_stable,
        critical_late_days=critical_late_days,
        reasons=tuple(reasons),
    )


def calibration_factor(pairs: Iterable[tuple[float, float]]) -> float:
    """Personal speed factor (V1): median of actual hours divided by estimated hours.

    New estimates are multiplied by this factor. With no usable data the factor is 1.
    """
    ratios = [actual / estimate for estimate, actual in pairs if estimate > EPS and actual > EPS]
    if not ratios:
        return 1.0
    return round(median(ratios), 4)
