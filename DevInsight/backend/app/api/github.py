import logging
from typing import Annotated, Any

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, ConfigDict, Field
from starlette.concurrency import run_in_threadpool

from app.api.dependencies import AuthenticatedUser, get_current_user
from app.services.github_service import (
    GitHubPrivateRepository,
    GitHubRateLimitExceeded,
    GitHubRepositoryNotFound,
    GitHubUnavailable,
)
from app.services.repository_service import (
    RepositoryDatabaseError,
    repository_service,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/github", tags=["github"])


class RequestModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class RepositoryConnectRequest(RequestModel):
    repository_url: str = Field(min_length=1, max_length=500)


class RepositoryConnectionResponse(BaseModel):
    id: str
    github_repository_id: int
    repository_full_name: str
    repository_url: str
    repository_owner: str
    repository_name: str
    description: str | None = None
    default_branch: str | None = None
    primary_language: str | None = None
    is_private: bool
    stargazers_count: int = 0
    forks_count: int = 0
    github_created_at: str | None = None
    github_updated_at: str | None = None
    github_pushed_at: str | None = None
    connected_at: str
    last_synced_at: str | None = None
    cached_summary: dict[str, Any] = Field(default_factory=dict)


class RepositoryOverviewResponse(BaseModel):
    connection: RepositoryConnectionResponse
    summary: dict[str, Any]
    is_stale: bool


class RepositoryRefreshResponse(RepositoryOverviewResponse):
    throttled: bool = False


def _raise_service_error(error: Exception) -> None:
    if isinstance(error, ValueError):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(error),
        ) from error
    if isinstance(error, GitHubRepositoryNotFound):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="This public GitHub repository could not be found.",
        ) from error
    if isinstance(error, GitHubPrivateRepository):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Private GitHub repositories are not supported.",
        ) from error
    if isinstance(error, GitHubRateLimitExceeded):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="GitHub is rate limiting requests. Please try again later.",
            headers={"Retry-After": "60"},
        ) from error
    if isinstance(error, GitHubUnavailable):
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="GitHub is temporarily unavailable. Please try again.",
        ) from error
    logger.warning("Repository operation failed (%s).", type(error).__name__)
    raise HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail="Repository storage is unavailable. Please try again.",
    ) from error


@router.post(
    "/connections",
    response_model=RepositoryConnectionResponse,
    status_code=status.HTTP_200_OK,
)
async def connect_repository(
    request: RepositoryConnectRequest,
    user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> RepositoryConnectionResponse:
    try:
        connection = await run_in_threadpool(
            repository_service.connect,
            user.id,
            request.repository_url,
        )
    except (
        ValueError,
        GitHubPrivateRepository,
        GitHubRepositoryNotFound,
        GitHubRateLimitExceeded,
        GitHubUnavailable,
        RepositoryDatabaseError,
    ) as error:
        _raise_service_error(error)
    return RepositoryConnectionResponse.model_validate(connection)


@router.get(
    "/connections",
    response_model=list[RepositoryConnectionResponse],
)
async def list_connections(
    user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> list[RepositoryConnectionResponse]:
    try:
        connections = await run_in_threadpool(
            repository_service.list_connections,
            user.id,
        )
    except RepositoryDatabaseError as error:
        _raise_service_error(error)
    return [
        RepositoryConnectionResponse.model_validate(connection)
        for connection in connections
    ]


@router.get(
    "/connections/{connection_id}/overview",
    response_model=RepositoryOverviewResponse,
)
async def get_overview(
    connection_id: str,
    user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> RepositoryOverviewResponse:
    try:
        overview = await run_in_threadpool(
            repository_service.overview,
            user.id,
            connection_id,
        )
    except RepositoryDatabaseError as error:
        _raise_service_error(error)
    if overview is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Repository connection was not found.",
        )
    return RepositoryOverviewResponse.model_validate(overview)


@router.delete(
    "/connections/{connection_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def disconnect_repository(
    connection_id: str,
    user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> None:
    try:
        disconnected = await run_in_threadpool(
            repository_service.disconnect,
            user.id,
            connection_id,
        )
    except RepositoryDatabaseError as error:
        _raise_service_error(error)
    if not disconnected:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Repository connection was not found.",
        )


@router.post(
    "/connections/{connection_id}/refresh",
    response_model=RepositoryRefreshResponse,
)
async def refresh_connection(
    connection_id: str,
    user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> RepositoryRefreshResponse:
    try:
        result = await run_in_threadpool(
            repository_service.refresh,
            user.id,
            connection_id,
        )
    except (
        GitHubPrivateRepository,
        GitHubRepositoryNotFound,
        GitHubRateLimitExceeded,
        GitHubUnavailable,
        RepositoryDatabaseError,
    ) as error:
        _raise_service_error(error)
    if result is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Repository connection was not found.",
        )
    connection, throttled = result
    return RepositoryRefreshResponse(
        connection=RepositoryConnectionResponse.model_validate(connection),
        summary=connection.get("cached_summary") or {},
        is_stale=repository_service.is_stale(connection),
        throttled=throttled,
    )
