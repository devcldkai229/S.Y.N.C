from enum import IntEnum
from typing import Any, TypeVar

E = TypeVar("E", bound=IntEnum)


def coerce_int_enum(enum_cls: type[E], value: Any) -> E:
    """Accept C# enum as int or PascalCase name (JSON from .NET APIs)."""
    if isinstance(value, enum_cls):
        return value
    if isinstance(value, str):
        stripped = value.strip()
        if stripped.isdigit():
            return enum_cls(int(stripped))
        return enum_cls[stripped]
    if isinstance(value, int):
        return enum_cls(value)
    raise ValueError(f"Cannot coerce {value!r} to {enum_cls.__name__}")
