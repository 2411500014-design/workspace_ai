"""Mapping between calendar days and cumulative working hours.

The scheduler reasons in *capacity hours*: hour 0 is the start of the first day, and
hour ``h`` is reached on the first day whose cumulative capacity is at least ``h``.
Working in this space makes deadlines, buffers and slack exact regardless of weekends,
blocked dates or uneven daily capacity.
"""

from __future__ import annotations

from bisect import bisect_left
from datetime import date, timedelta

from .types import EPS, Capacity

# Never look further ahead than this; with zero capacity the work simply never fits.
MAX_HORIZON_DAYS = 366 * 5


class Timeline:
    def __init__(self, start: date, capacity: Capacity) -> None:
        self.start = start
        self.capacity = capacity
        self._days: list[date] = []
        self._cum: list[float] = []  # cumulative hours through the end of each day

    def _extend(self, count: int) -> bool:
        """Make sure at least ``count`` days are materialised. False if past the horizon."""
        count = min(count, MAX_HORIZON_DAYS)
        while len(self._days) < count:
            day = self.start + timedelta(days=len(self._days))
            previous = self._cum[-1] if self._cum else 0.0
            self._days.append(day)
            self._cum.append(previous + self.capacity.hours_on(day))
        return len(self._days) >= count

    def hours_on(self, day: date) -> float:
        return self.capacity.hours_on(day)

    def hours_through(self, day: date) -> float:
        """Capacity from the start up to and including ``day``."""
        if day < self.start:
            return 0.0
        index = (day - self.start).days
        if not self._extend(index + 1):
            return self._cum[-1]
        return self._cum[index]

    def day_reaching(self, hours: float) -> date | None:
        """First day by whose end ``hours`` of capacity have accumulated.

        Returns ``None`` if that never happens within the horizon.
        """
        if hours <= EPS:
            return self.start
        chunk = 64
        while True:
            if self._cum and self._cum[-1] >= hours - EPS:
                index = bisect_left(self._cum, hours - EPS)
                return self._days[index]
            if len(self._days) >= MAX_HORIZON_DAYS:
                return None
            self._extend(len(self._days) + chunk)
            chunk = min(chunk * 2, 1024)
