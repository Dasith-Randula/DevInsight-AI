from datetime import datetime, timedelta, timezone
from typing import Any

import httpx
from postgrest.exceptions import APIError
from supabase import SupabaseException

from app.config import get_settings
from app.services.github_service import (
    GitHubPrivateRepository,
    GitHubRateLimitExceeded,
    GitHubRepositoryNotFound,
    GitHubService,
    GitHubUnavailable,
    github_service,
)
from app.services.supabase_service import (
    SupabaseConfigurationError,
    supabase_service,
)

DATABASE_ERRORS = (
    APIError,
    httpx.HTTPError,
    OSError,
    SupabaseConfigurationError,
    SupabaseException,
    ValueError,
)


class RepositoryDatabaseError(RuntimeError):
    """A repository connection could not be read or saved."""


class RepositoryService:
    def __init__(self, github: GitHubService | None = None) -> None:
        self._github = github or github_service

    def list_connections(self, user_id: str) -> list[dict[str, Any]]:
        try:
            response = (
                supabase_service.get_client()
                .table("connected_repositories")
                .select("*")
                .eq("user_id", user_id)
                .order("connected_at", desc=True)
                .execute()
            )
            return response.data
        except DATABASE_ERRORS as error:
            raise RepositoryDatabaseError from error

    def get_connection(
        self,
        user_id: str,
        connection_id: str,
    ) -> dict[str, Any] | None:
        try:
            response = (
                supabase_service.get_client()
                .table("connected_repositories")
                .select("*")
                .eq("user_id", user_id)
                .eq("id", connection_id)
                .limit(1)
                .execute()
            )
            return response.data[0] if response.data else None
        except DATABASE_ERRORS as error:
            raise RepositoryDatabaseError from error

    def disconnect(self, user_id: str, connection_id: str) -> bool:
        try:
            response = (
                supabase_service.get_client()
                .table("connected_repositories")
                .delete()
                .select("id")
                .eq("user_id", user_id)
                .eq("id", connection_id)
                .execute()
            )
            return bool(response.data)
        except DATABASE_ERRORS as error:
            raise RepositoryDatabaseError from error

    def connect(self, user_id: str, repository_url: str) -> dict[str, Any]:
        from app.services.github_service import parse_repository_url

        owner, repository = parse_repository_url(repository_url)
        try:
            existing = self._find_by_name(user_id, owner, repository)
            if existing is not None and not self.is_stale(existing):
                return existing

            try:
                repository_data = self._github.get_repository(owner, repository)
                if repository_data.get("private") is True:
                    raise GitHubPrivateRepository
                summary = self._github.get_summary(
                    owner,
                    repository,
                    repository_data,
                )
            except (GitHubRateLimitExceeded, GitHubUnavailable):
                if existing is not None:
                    return existing
                raise
            row = {
                "user_id": user_id,
                "github_repository_id": repository_data["id"],
                "repository_full_name": repository_data["full_name"],
                "repository_url": repository_data["html_url"],
                "repository_owner": repository_data["owner"]["login"],
                "repository_name": repository_data["name"],
                "description": repository_data.get("description"),
                "default_branch": repository_data.get("default_branch"),
                "primary_language": repository_data.get("language"),
                "is_private": False,
                "stargazers_count": repository_data.get("stargazers_count", 0),
                "forks_count": repository_data.get("forks_count", 0),
                "github_created_at": repository_data.get("created_at"),
                "github_updated_at": repository_data.get("updated_at"),
                "github_pushed_at": repository_data.get("pushed_at"),
                "last_synced_at": summary["synced_at"],
                "cached_summary": summary,
                "updated_at": summary["synced_at"],
            }
            response = (
                supabase_service.get_client()
                .table("connected_repositories")
                .upsert(
                    row,
                    on_conflict="user_id,github_repository_id",
                )
                .select("*")
                .execute()
            )
            if not response.data:
                raise RepositoryDatabaseError
            return response.data[0]
        except (GitHubPrivateRepository, GitHubRepositoryNotFound):
            raise
        except RepositoryDatabaseError:
            raise
        except DATABASE_ERRORS as error:
            raise RepositoryDatabaseError from error

    def overview(self, user_id: str, connection_id: str) -> dict[str, Any] | None:
        connection = self.get_connection(user_id, connection_id)
        if connection is None:
            return None
        return {
            "connection": connection,
            "summary": connection.get("cached_summary") or {},
            "is_stale": self.is_stale(connection),
        }

    def refresh(
        self,
        user_id: str,
        connection_id: str,
    ) -> tuple[dict[str, Any], bool] | None:
        connection = self.get_connection(user_id, connection_id)
        if connection is None:
            return None
        if not self._can_refresh(connection):
            return connection, True

        owner = str(connection["repository_owner"])
        repository = str(connection["repository_name"])
        repository_data = self._github.get_repository(owner, repository)
        if repository_data.get("private") is True:
            raise GitHubPrivateRepository
        summary = self._github.get_summary(owner, repository, repository_data)
        updated_at = summary["synced_at"]
        row = {
            "repository_full_name": repository_data["full_name"],
            "repository_url": repository_data["html_url"],
            "repository_owner": repository_data["owner"]["login"],
            "repository_name": repository_data["name"],
            "description": repository_data.get("description"),
            "default_branch": repository_data.get("default_branch"),
            "primary_language": repository_data.get("language"),
            "is_private": False,
            "stargazers_count": repository_data.get("stargazers_count", 0),
            "forks_count": repository_data.get("forks_count", 0),
            "github_created_at": repository_data.get("created_at"),
            "github_updated_at": repository_data.get("updated_at"),
            "github_pushed_at": repository_data.get("pushed_at"),
            "last_synced_at": updated_at,
            "cached_summary": summary,
            "updated_at": updated_at,
        }
        try:
            response = (
                supabase_service.get_client()
                .table("connected_repositories")
                .update(row)
                .eq("user_id", user_id)
                .eq("id", connection_id)
                .select("*")
                .execute()
            )
            if not response.data:
                return None
            return response.data[0], False
        except DATABASE_ERRORS as error:
            raise RepositoryDatabaseError from error

    @staticmethod
    def is_stale(connection: dict[str, Any]) -> bool:
        last_sync = connection.get("last_synced_at")
        try:
            synced_at = datetime.fromisoformat(str(last_sync).replace("Z", "+00:00"))
        except (TypeError, ValueError):
            return True
        if synced_at.tzinfo is None:
            synced_at = synced_at.replace(tzinfo=timezone.utc)
        return datetime.now(timezone.utc) - synced_at > timedelta(
            minutes=get_settings().github_cache_minutes
        )

    @staticmethod
    def _can_refresh(connection: dict[str, Any]) -> bool:
        last_sync = connection.get("last_synced_at")
        try:
            synced_at = datetime.fromisoformat(str(last_sync).replace("Z", "+00:00"))
        except (TypeError, ValueError):
            return True
        if synced_at.tzinfo is None:
            synced_at = synced_at.replace(tzinfo=timezone.utc)
        return datetime.now(timezone.utc) - synced_at >= timedelta(seconds=60)

    def _find_by_name(
        self,
        user_id: str,
        owner: str,
        repository: str,
    ) -> dict[str, Any] | None:
        response = (
            supabase_service.get_client()
            .table("connected_repositories")
            .select("*")
            .eq("user_id", user_id)
            .ilike("repository_full_name", f"{owner}/{repository}")
            .limit(1)
            .execute()
        )
        return response.data[0] if response.data else None


repository_service = RepositoryService()
