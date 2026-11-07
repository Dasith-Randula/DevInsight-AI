import logging
from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from starlette.concurrency import run_in_threadpool

from app.api.dependencies import AuthenticatedUser, get_current_user
from app.services.profile_service import ProfileServiceError, profile_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1")


class CurrentUserProfile(BaseModel):
    id: str
    full_name: str | None = None
    username: str | None = None
    organization: str | None = None
    job_title: str | None = None
    role: str | None = None
    onboarding_step: int = 1
    onboarding_completed: bool = False
    created_at: datetime | None = None
    updated_at: datetime | None = None
    next_step: str


def get_next_step(
    profile: dict[str, object],
    preferences_saved: bool = False,
    notifications_saved: bool = False,
) -> str:
    if profile.get("onboarding_completed"):
        return {
            "developer": "developer_home",
            "project_manager": "manager_home",
        }.get(str(profile.get("role")), "profile")
    if (
        int(profile.get("onboarding_step") or 1) < 2
        or profile.get("role") not in {"developer", "project_manager"}
    ):
        return "profile"
    if not preferences_saved:
        return "preferences"
    if not notifications_saved:
        return "notifications"
    return "complete"


@router.get("/me", response_model=CurrentUserProfile)
async def get_me(
    user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> CurrentUserProfile:
    try:
        profile, preferences_saved, notifications_saved = await run_in_threadpool(
            profile_service.get_onboarding_state,
            user.id,
        )
    except ProfileServiceError as error:
        logger.warning("Profile retrieval failed (%s).", type(error).__name__)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Profile service is unavailable.",
        ) from error

    return CurrentUserProfile(
        **profile,
        next_step=get_next_step(profile, preferences_saved, notifications_saved),
    )
