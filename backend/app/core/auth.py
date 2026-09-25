"""Authentication and workspace access.

Local mode serves a single local user with no login, so the app runs without any
external service. Supabase mode verifies the Supabase JWT on every request (master plan
§13): with a JWKS URL for asymmetric keys, or the legacy shared HS256 secret.
"""

from __future__ import annotations

from functools import lru_cache

import jwt
from fastapi import Depends, Request
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.accounts.models import Profile, Workspace, WorkspaceMember

from .config import Settings, get_settings
from .db import get_db
from .errors import AppError

LOCAL_USER_ID = "00000000-0000-4000-8000-000000000001"


def ensure_workspace(db: Session, user: Profile) -> Workspace:
    member = db.scalars(select(WorkspaceMember).where(WorkspaceMember.user_id == user.id)).first()
    if member is not None:
        workspace = db.get(Workspace, member.workspace_id)
        assert workspace is not None
        return workspace
    workspace = Workspace(name=user.name or "Workspace", owner_id=user.id)
    db.add(workspace)
    db.flush()
    db.add(WorkspaceMember(workspace_id=workspace.id, user_id=user.id, role="owner"))
    db.flush()
    return workspace


def _local_user(db: Session) -> Profile:
    user = db.get(Profile, LOCAL_USER_ID)
    if user is None:
        user = Profile(id=LOCAL_USER_ID, email=None, name="", locale="id", timezone="Asia/Jakarta")
        db.add(user)
        db.flush()
    ensure_workspace(db, user)
    return user


@lru_cache
def _jwks_client(url: str) -> jwt.PyJWKClient:
    return jwt.PyJWKClient(url, cache_keys=True)


def verify_supabase_token(token: str, settings: Settings) -> dict:
    try:
        if settings.supabase_jwks_url:
            key = _jwks_client(settings.supabase_jwks_url).get_signing_key_from_jwt(token).key
            return jwt.decode(token, key, algorithms=["RS256", "ES256"], audience=settings.supabase_jwt_audience)
        if settings.supabase_jwt_secret:
            return jwt.decode(
                token, settings.supabase_jwt_secret, algorithms=["HS256"], audience=settings.supabase_jwt_audience
            )
    except jwt.PyJWTError as exc:
        raise AppError("unauthenticated", 401) from exc
    raise AppError("auth_not_configured", 500)


def get_current_user(request: Request, db: Session = Depends(get_db)) -> Profile:
    settings = get_settings()
    if settings.auth_mode == "local":
        return _local_user(db)

    header = request.headers.get("authorization", "")
    scheme, _, token = header.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise AppError("unauthenticated", 401)
    claims = verify_supabase_token(token, settings)
    user_id = claims.get("sub")
    if not user_id:
        raise AppError("unauthenticated", 401)
    user = db.get(Profile, user_id)
    if user is None:
        meta = claims.get("user_metadata") or {}
        user = Profile(id=user_id, email=claims.get("email"), name=meta.get("full_name") or meta.get("name") or "")
        db.add(user)
        db.flush()
    ensure_workspace(db, user)
    return user


def workspace_ids(db: Session, user: Profile) -> list[str]:
    return list(db.scalars(select(WorkspaceMember.workspace_id).where(WorkspaceMember.user_id == user.id)))
