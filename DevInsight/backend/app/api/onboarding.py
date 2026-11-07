import logging
import re
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, ConfigDict, Field, StrictBool, field_validator
from starlette.concurrency import run_in_threadpool

from app.api.dependencies import AuthenticatedUser, get_current_user
from app.api.me import get_next_step
from app.services.onboarding_service import (
    DuplicateUsernameError,
    OnboardingIncompleteError,
    OnboardingServiceError,
    onboarding_service,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/onboarding")

SUPPORTED_INTERESTS = frozenset(
    {
        "Code Quality & Issues",
        "Project Risk Prediction",
        "Root Cause Analysis",
        "Issue Prioritization",
        "Team Productivity",
        "AI Recommendations",
        "Project Performance Insights",
    }
)
SUPPORTED_NOTIFICATION_TOPICS = frozenset(
    {
        "Critical Risk Alerts",
        "Project Updates",
        "Issue Assignments",
        "AI Recommendations",
        "Project Activity",
    }
)


class RequestModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class ProfileSetupRequest(RequestModel):
    full_name: str = Field(min_length=1, max_length=120)
    username: str = Field(min_length=3, max_length=30)
    organization: str | None = Field(default=None, max_length=120)
    job_title: str | None = Field(default=None, max_length=120)
    role: Literal["developer", "project_manager"]

    @field_validator(
        "full_name",
        "username",
        "organization",
        "job_title",
        mode="before",
    )
    @classmethod
    def strip_text(cls, value: object) -> object:
        return value.strip() if isinstance(value, str) else value

    @field_validator("username")
    @classmethod
    def normalize_username(cls, value: str) -> str:
        if not re.fullmatch(r"[A-Za-z0-9_.-]{3,30}", value):
            raise ValueError(
                "Username may contain only letters, numbers, dots, underscores, and hyphens."
            )
        return value.lower()


class PreferencesRequest(RequestModel):
    interests: list[str]

    @field_validator("interests")
    @classmethod
    def validate_interests(cls, values: list[str]) -> list[str]:
        unsupported = set(values) - SUPPORTED_INTERESTS
        if unsupported:
            raise ValueError("One or more interests are not supported.")
        return list(dict.fromkeys(values))


class NotificationsRequest(RequestModel):
    email_enabled: StrictBool
    push_enabled: StrictBool
    topics: list[str]

    @field_validator("topics")
    @classmethod
    def validate_topics(cls, values: list[str]) -> list[str]:
        unsupported = set(values) - SUPPORTED_NOTIFICATION_TOPICS
        if unsupported:
            raise ValueError("One or more notification categories are not supported.")
        return list(dict.fromkeys(values))


class StepSavedResponse(BaseModel):
    status: Literal["saved"] = "saved"
    onboarding_step: int


class OnboardingCompleteResponse(BaseModel):
    onboarding_completed: bool
    role: Literal["developer", "project_manager"]
    next_step: Literal["developer_home", "manager_home"]


class OnboardingProfileResponse(BaseModel):
    id: str
    full_name: str | None = None
    username: str | None = None
    organization: str | None = None
    job_title: str | None = None
    role: Literal["developer", "project_manager"] | None = None
    onboarding_step: int = 1
    onboarding_completed: bool = False


class OnboardingPreferencesResponse(BaseModel):
    interests: list[str]


class OnboardingNotificationsResponse(BaseModel):
    email_enabled: bool
    push_enabled: bool
    topics: list[str]


class OnboardingStateResponse(BaseModel):
    profile: OnboardingProfileResponse
    preferences: OnboardingPreferencesResponse | None = None
    notifications: OnboardingNotificationsResponse | None = None
    next_step: str


def _raise_service_error(error: OnboardingServiceError) -> None:
    if isinstance(error, DuplicateUsernameError):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Username is already in use.",
        ) from error
    if isinstance(error, OnboardingIncompleteError):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=str(error),
        ) from error
    logger.warning("Onboarding operation failed (%s).", type(error).__name__)
    raise HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail="Onboarding service is unavailable.",
    ) from error


@router.get("/state", response_model=OnboardingStateResponse)
async def get_onboarding_state(
    user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> OnboardingStateResponse:
    try:
        state = await run_in_threadpool(
            onboarding_service.get_onboarding_state,
            user.id,
        )
    except OnboardingServiceError as error:
        _raise_service_error(error)

    profile = state["profile"]
    preferences = state["preferences"]
    notifications = state["notifications"]
    return OnboardingStateResponse(
        profile=profile,
        preferences=preferences,
        notifications=notifications,
        next_step=get_next_step(
            profile,
            preferences is not None,
            notifications is not None,
        ),
    )


@router.put("/profile", response_model=StepSavedResponse)
async def save_profile(
    request: ProfileSetupRequest,
    user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> StepSavedResponse:
    try:
        profile = await run_in_threadpool(
            onboarding_service.save_profile,
            user.id,
            request.model_dump(exclude_unset=True),
        )
    except OnboardingServiceError as error:
        _raise_service_error(error)
    return StepSavedResponse(onboarding_step=int(profile["onboarding_step"]))


@router.put("/preferences", response_model=StepSavedResponse)
async def save_preferences(
    request: PreferencesRequest,
    user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> StepSavedResponse:
    try:
        await run_in_threadpool(
            onboarding_service.save_preferences,
            user.id,
            request.interests,
        )
    except OnboardingServiceError as error:
        _raise_service_error(error)
    return StepSavedResponse(onboarding_step=3)


@router.put("/notifications", response_model=StepSavedResponse)
async def save_notifications(
    request: NotificationsRequest,
    user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> StepSavedResponse:
    try:
        await run_in_threadpool(
            onboarding_service.save_notifications,
            user.id,
            request.email_enabled,
            request.push_enabled,
            request.topics,
        )
    except OnboardingServiceError as error:
        _raise_service_error(error)
    return StepSavedResponse(onboarding_step=3)


@router.post("/complete", response_model=OnboardingCompleteResponse)
async def complete_onboarding(
    user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> OnboardingCompleteResponse:
    try:
        profile = await run_in_threadpool(
            onboarding_service.complete_onboarding,
            user.id,
        )
    except OnboardingServiceError as error:
        _raise_service_error(error)

    role = profile["role"]
    return OnboardingCompleteResponse(
        onboarding_completed=bool(profile["onboarding_completed"]),
        role=role,
        next_step="developer_home" if role == "developer" else "manager_home",
    )
