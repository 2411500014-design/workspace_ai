"""Priority score (master plan §8).

    P = 0.4 K + 0.3 (1 - S_n) + 0.2 D_n + 0.1 U

K is 1 for tasks on the critical path, S_n is slack normalised to 0..1, D_n is the
number of tasks waiting on this one (normalised) and U is the user's own importance
rating (0, 0.5 or 1). The weights are starting values, to be re-tuned after beta.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class PriorityWeights:
    critical: float = 0.4
    slack: float = 0.3
    dependents: float = 0.2
    importance: float = 0.1


DEFAULT_WEIGHTS = PriorityWeights()


def normalise(value: float, maximum: float) -> float:
    if maximum <= 0:
        return 0.0
    return min(max(value / maximum, 0.0), 1.0)


def priority_score(
    *,
    critical: bool,
    slack_norm: float,
    dependents_norm: float,
    importance: float,
    weights: PriorityWeights = DEFAULT_WEIGHTS,
) -> float:
    for name, value in (("slack_norm", slack_norm), ("dependents_norm", dependents_norm), ("importance", importance)):
        if not 0.0 <= value <= 1.0:
            raise ValueError(f"{name} must be within 0..1, got {value}")
    score = (
        weights.critical * (1.0 if critical else 0.0)
        + weights.slack * (1.0 - slack_norm)
        + weights.dependents * dependents_norm
        + weights.importance * importance
    )
    return round(score, 4)
