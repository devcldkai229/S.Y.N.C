"""JWT authentication — validates tokens minted by the IAM service (HS256, same
secret/issuer/audience). Reads the .NET namespaced role claim.
"""
import jwt
from fastapi import Depends, Header, HTTPException
from pydantic import BaseModel

from app.config import settings

ROLE_CLAIM = "http://schemas.microsoft.com/ws/2008/06/identity/claims/role"
NAME_CLAIM = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"


class CurrentUser(BaseModel):
    id: str
    email: str = ""
    full_name: str = ""
    role: str = "User"


def _decode(token: str) -> dict:
    try:
        return jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
            audience=settings.jwt_audience,
            issuer=settings.jwt_issuer,
        )
    except jwt.PyJWTError as exc:  # pragma: no cover - thin wrapper
        raise HTTPException(status_code=401, detail="Invalid or expired token") from exc


async def get_current_user(authorization: str = Header(...)) -> CurrentUser:
    if not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing Bearer token")
    token = authorization[7:]
    payload = _decode(token)
    return CurrentUser(
        id=str(payload.get("sub") or payload.get("nameid") or ""),
        email=payload.get("email", ""),
        full_name=payload.get(NAME_CLAIM, ""),
        role=payload.get(ROLE_CLAIM, "User"),
    )


async def get_raw_token(authorization: str = Header(...)) -> str:
    """Raw JWT to forward to downstream services."""
    if not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing Bearer token")
    return authorization[7:]


async def require_admin(user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
    # Canonical admin role in this platform is "SystemAdmin".
    if user.role != "SystemAdmin":
        raise HTTPException(status_code=403, detail="SystemAdmin role required")
    return user
