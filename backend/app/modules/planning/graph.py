"""Dependency graph checks: Kahn's topological sort and cycle detection."""

from __future__ import annotations

import heapq
from collections.abc import Mapping, Sequence


class GraphError(ValueError):
    """Base class for dependency graph problems."""


class CycleError(GraphError):
    """The dependencies contain a cycle, so no valid order exists."""

    def __init__(self, keys: Sequence[str]) -> None:
        self.keys = tuple(sorted(keys))
        super().__init__(f"dependency cycle among: {', '.join(self.keys)}")


class UnknownDependencyError(GraphError):
    def __init__(self, key: str, missing: str) -> None:
        self.key = key
        self.missing = missing
        super().__init__(f"task {key!r} depends on unknown task {missing!r}")


class DuplicateKeyError(GraphError):
    def __init__(self, key: str) -> None:
        self.key = key
        super().__init__(f"duplicate task key {key!r}")


def validate_keys(keys: Sequence[str], deps: Mapping[str, Sequence[str]]) -> None:
    seen: set[str] = set()
    for key in keys:
        if key in seen:
            raise DuplicateKeyError(key)
        seen.add(key)
    for key, parents in deps.items():
        for parent in parents:
            if parent not in seen:
                raise UnknownDependencyError(key, parent)


def topological_order(keys: Sequence[str], deps: Mapping[str, Sequence[str]]) -> list[str]:
    """Return ``keys`` in an order where every task comes after its dependencies.

    Uses Kahn's algorithm. Ties are broken by the original position in ``keys`` so the
    result is deterministic. Raises :class:`CycleError` if the graph has a cycle.
    """
    validate_keys(keys, deps)
    position = {key: i for i, key in enumerate(keys)}
    indegree = {key: 0 for key in keys}
    children: dict[str, list[str]] = {key: [] for key in keys}
    for key in keys:
        for parent in set(deps.get(key, ())):
            indegree[key] += 1
            children[parent].append(key)

    # A heap keyed by original position keeps the order deterministic.
    ready = [(position[k], k) for k in keys if indegree[k] == 0]
    heapq.heapify(ready)
    order: list[str] = []
    while ready:
        _, key = heapq.heappop(ready)
        order.append(key)
        for child in children[key]:
            indegree[child] -= 1
            if indegree[child] == 0:
                heapq.heappush(ready, (position[child], child))

    if len(order) != len(keys):
        raise CycleError([k for k in keys if indegree[k] > 0])
    return order


def downstream_counts(keys: Sequence[str], deps: Mapping[str, Sequence[str]]) -> dict[str, int]:
    """For every task, how many tasks (directly or indirectly) wait on it."""
    children: dict[str, set[str]] = {key: set() for key in keys}
    for key in keys:
        for parent in deps.get(key, ()):
            if parent in children:
                children[parent].add(key)

    memo: dict[str, frozenset[str]] = {}

    def reach(key: str) -> frozenset[str]:
        if key in memo:
            return memo[key]
        found: set[str] = set()
        for child in children[key]:
            found.add(child)
            found |= reach(child)
        memo[key] = frozenset(found)
        return memo[key]

    # Visit in reverse topological order so recursion depth stays small.
    for key in reversed(topological_order(keys, deps)):
        reach(key)
    return {key: len(memo[key]) for key in keys}
