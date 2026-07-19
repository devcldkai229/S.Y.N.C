"""Xác thực JWT phát hành bởi IAM (.NET) + trích xuất AuthContext.

JWT của IAM ký bằng khoá đối xứng (HS256) chia sẻ qua secret. Verify issuer,
audience, exp, signature. Trích `sub` (userId), `tier` (SubscriptionTier),
`role`, `persona` nếu có claim.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from fastapi import Header, HTTPException

from app.config import get_settings


@dataclass(frozen=True)
class AuthContext:
    user_id: str
    tier: str = "Free"          # Free | Premium | Ultra
    role: str = "User"          # User | Partner | SystemAdmin
    persona: str = "FriendlyBuddy"
    motivation_style: str = "Supportive"
    locale: str = "vi"


def _decode(token: str) -> dict[str, Any]:
    settings = get_settings()
    is_prod = settings.environment == "production"
    try:
        import jwt  # PyJWT

        return jwt.decode(
            token,
            settings.jwt_signing_key,
            algorithms=["HS256"],
            audience=settings.jwt_audience,
            issuer=settings.jwt_issuer,
            options={"require": ["exp", "sub"]},
        )
    except ModuleNotFoundError:
        if is_prod:
            raise HTTPException(
                status_code=500,
                detail="JWT verification unavailable in production",
            ) from None
        import base64
        import json

        parts = token.split(".")
        if len(parts) != 3:
            raise HTTPException(status_code=401, detail="Malformed token")
        pad = parts[1] + "=" * (-len(parts[1]) % 4)
        return json.loads(base64.urlsafe_b64decode(pad))
    except Exception as exc:
        raise HTTPException(status_code=401, detail=f"Invalid token: {exc}") from exc


def auth_from_header(authorization: str | None) -> AuthContext:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    claims = _decode(authorization.split(" ", 1)[1])
    user_id = claims.get("sub") or claims.get("userId")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token thiếu subject")
    role = (
        claims.get("role")
        or claims.get("Role")
        or claims.get("http://schemas.microsoft.com/ws/2008/06/identity/claims/role")
        or "User"
    )
    return AuthContext(
        user_id=str(user_id),
        tier=str(claims.get("tier") or claims.get("SubscriptionTier") or "Free"),
        role=str(role),
        persona=str(claims.get("persona") or "FriendlyBuddy"),
        motivation_style=str(claims.get("motivationStyle") or "Supportive"),
        locale=str(claims.get("locale") or "vi"),
    )


def require_auth(authorization: str | None = Header(default=None)) -> AuthContext:
    return auth_from_header(authorization)
