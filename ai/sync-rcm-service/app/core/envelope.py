"""ApiResponse<T> envelope — identical shape to the .NET services so the Flutter
client (`ApiEnvelope` / `_parsePagedList`) can unwrap responses uniformly.
"""
from typing import Any

from pydantic import BaseModel


class ApiResponse(BaseModel):
    success: bool
    message: str = ""
    data: Any = None
    errors: Any = None


def ok(data: Any, message: str = "Success") -> ApiResponse:
    return ApiResponse(success=True, message=message, data=data)


def fail(message: str, errors: Any = None) -> ApiResponse:
    return ApiResponse(success=False, message=message, data=None, errors=errors)
