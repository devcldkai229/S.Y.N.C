"""Libs.Shared.Enums — Roadmap service."""

from enum import IntEnum


class RoadmapStatus(IntEnum):
    Active = 0
    Paused = 1
    Completed = 2
    Abandoned = 3
