"""Planning Engine: deterministic scheduling, priority, health and re-plan simulation.

Pure Python with no I/O; everything here must stay unit-testable in isolation.
"""

from .graph import CycleError, DuplicateKeyError, GraphError, UnknownDependencyError, topological_order
from .health import HealthResult, TaskProgress, calibration_factor, compute_health
from .priority import priority_score
from .replan import ReplanOption, replan_options
from .scheduler import schedule
from .types import Capacity, DayAllocation, PlanTask, ScheduleRequest, ScheduleResult, TaskPlan

__all__ = [
    "Capacity",
    "CycleError",
    "DayAllocation",
    "DuplicateKeyError",
    "GraphError",
    "HealthResult",
    "PlanTask",
    "ReplanOption",
    "ScheduleRequest",
    "ScheduleResult",
    "TaskPlan",
    "TaskProgress",
    "UnknownDependencyError",
    "calibration_factor",
    "compute_health",
    "priority_score",
    "replan_options",
    "schedule",
    "topological_order",
]
