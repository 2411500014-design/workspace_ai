"""The current date, in the user's own timezone (WIB, WITA or WIT).

Day boundaries for schedules follow the user's timezone (master plan §11). Tests replace
the clock through FastAPI dependency overrides.
"""

from __future__ import annotations

from datetime import date, datetime
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


class Clock:
    def today(self, timezone: str) -> date:
        try:
            zone = ZoneInfo(timezone)
        except ZoneInfoNotFoundError:
            zone = ZoneInfo("Asia/Jakarta")
        return datetime.now(zone).date()


class FixedClock(Clock):
    def __init__(self, day: date) -> None:
        self.day = day

    def today(self, timezone: str) -> date:  # noqa: ARG002 - same signature as Clock
        return self.day


_clock = Clock()


def get_clock() -> Clock:
    return _clock
