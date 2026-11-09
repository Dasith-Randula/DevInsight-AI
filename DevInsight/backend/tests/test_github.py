import unittest
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from unittest.mock import Mock, patch

import httpx
from fastapi.testclient import TestClient

from app.api.dependencies import AuthenticatedUser, get_current_user
from app.main import app
from app.services.github_service import (
    GitHubPrivateRepository,
    GitHubRateLimitExceeded,
    GitHubRepositoryNotFound,
    GitHubService,
    GitHubUnavailable,
    parse_repository_url,
)
from app.services.repository_service import RepositoryService, repository_service
from app.services.supabase_service import supabase_service


class InMemoryQuery:
    def __init__(self, database: "InMemoryDatabase", name: str) -> None:
        self.database = database
        self.name = name
        self.filters: list[tuple[str, str, str]] = []
        self.operation = "select"
        self.payload: dict[str, object] = {}
        self.conflicts: list[str] = []
        self.limit_value: int | None = None

    def select(self, _: str) -> "InMemoryQuery":
        return self

    def eq(self, field: str, value: str) -> "InMemoryQuery":
        self.filters.append(("eq", field, value))
        return self

    def ilike(self, field: str, value: str) -> "InMemoryQuery":
        self.filters.append(("ilike", field, value))
        return self

    def limit(self, value: int) -> "InMemoryQuery":
        self.limit_value = value
        return self

    def order(self, *_: object, **__: object) -> "InMemoryQuery":
        return self

    def upsert(
        self,
        payload: dict[str, object],
        *,
        on_conflict: str,
    ) -> "InMemoryQuery":
        self.operation = "upsert"
        self.payload = payload
        self.conflicts = on_conflict.split(",")
        return self

    def update(self, payload: dict[str, object]) -> "InMemoryQuery":
        self.operation = "update"
        self.payload = payload
        return self

    def delete(self) -> "InMemoryQuery":
        self.operation = "delete"
        return self

    def execute(self) -> SimpleNamespace:
        rows = self.database.tables.setdefault(self.name, [])
        deleted_rows: list[dict[str, object]] = []
        upserted_row: dict[str, object] | None = None
        if self.operation == "upsert":
            row = next(
                (
                    candidate
                    for candidate in rows
                    if all(
                        candidate.get(field) == self.payload.get(field)
                        for field in self.conflicts
                    )
                ),
                None,
            )
            if row is None:
                row = {
                    "id": f"connection-{len(rows) + 1}",
                    "connected_at": datetime.now(timezone.utc).isoformat(),
                    "created_at": datetime.now(timezone.utc).isoformat(),
                    **self.payload,
                }
                rows.append(row)
            else:
                row.update(self.payload)
            upserted_row = row
        elif self.operation == "delete":
            deleted_rows = [row for row in rows if self._matches(row)]
            rows[:] = [row for row in rows if not self._matches(row)]
        else:
            for row in rows:
                if self._matches(row) and self.operation == "update":
                    row.update(self.payload)

        results = (
            [dict(row) for row in deleted_rows]
            if self.operation == "delete"
            else [dict(upserted_row)]
            if upserted_row is not None
            else [dict(row) for row in rows if self._matches(row)]
        )
        if self.limit_value is not None:
            results = results[: self.limit_value]
        return SimpleNamespace(data=results)

    def _matches(self, row: dict[str, object]) -> bool:
        for operation, field, value in self.filters:
            candidate = str(row.get(field, ""))
            if operation == "eq" and candidate != value:
                return False
            if operation == "ilike" and candidate.casefold() != value.casefold():
                return False
        return True


class InMemoryDatabase:
    def __init__(self) -> None:
        self.tables: dict[str, list[dict[str, object]]] = {
            "connected_repositories": []
        }

    def table(self, name: str) -> InMemoryQuery:
        return InMemoryQuery(self, name)


class FakeGitHubService:
    def __init__(self) -> None:
        self.repository_calls = 0
        self.summary_calls = 0

    def get_repository(self, owner: str, name: str) -> dict[str, object]:
        self.repository_calls += 1
        return {
            "id": 123 if name == "app" else 124,
            "full_name": f"{owner}/{name}",
            "html_url": f"https://github.com/{owner}/{name}",
            "owner": {"login": owner},
            "name": name,
            "description": "A test repository",
            "default_branch": "main",
            "language": "Python",
            "private": False,
            "stargazers_count": 2,
            "forks_count": 1,
        }

    def get_summary(
        self,
        owner: str,
        name: str,
        repository_data: dict[str, object],
    ) -> dict[str, object]:
        self.summary_calls += 1
        return {
            "open_pull_requests": 1,
            "resolved_issues_30d": 2,
            "languages": [{"name": "Python", "bytes": 100, "percentage": 100.0}],
            "recent_commits": [],
            "recent_activity": [],
            "synced_at": datetime.now(timezone.utc).isoformat(),
        }


class GitHubUrlTests(unittest.TestCase):
    def test_supported_url_forms_are_canonicalized(self) -> None:
        for url in (
            "https://github.com/Owner/repository",
            "https://github.com/Owner/repository/",
            "https://github.com/Owner/repository.git",
        ):
            with self.subTest(url=url):
                self.assertEqual(parse_repository_url(url), ("Owner", "repository"))

    def test_unsupported_urls_are_rejected(self) -> None:
        for url in (
            "http://github.com/Owner/repository",
            "https://github.com.evil.example/Owner/repository",
            "https://github.com/Owner/repository/issues",
            "https://github.com/Owner/repository?tab=readme",
            "https://github.com:bad/Owner/repository",
            "https://user@github.com/Owner/repository",
        ):
            with self.subTest(url=url), self.assertRaises(ValueError):
                parse_repository_url(url)


class GitHubApiServiceTests(unittest.TestCase):
    def test_summary_separates_issues_from_pull_requests(self) -> None:
        responses = {
            "/repos/acme/app/languages": {"Python": 75, "Dart": 25},
            "/repos/acme/app/commits": [
                {
                    "sha": "abc",
                    "html_url": "https://github.com/acme/app/commit/abc",
                    "commit": {
                        "message": "Fix issue",
                        "author": {
                            "name": "Developer",
                            "date": "2026-11-08T12:00:00Z",
                        },
                    },
                }
            ],
            "/repos/acme/app/issues": [
                {
                    "number": 7,
                    "title": "A real issue",
                    "state": "closed",
                    "html_url": "https://github.com/acme/app/issues/7",
                    "updated_at": "2026-11-08T12:00:00Z",
                    "created_at": "2026-11-01T12:00:00Z",
                    "closed_at": "2026-11-08T12:00:00Z",
                    "user": {"login": "dev"},
                    "labels": [{"name": "bug"}],
                },
                {
                    "number": 8,
                    "title": "This is a PR in the issues endpoint",
                    "pull_request": {},
                },
            ],
            "/repos/acme/app/pulls": [
                {
                    "number": 9,
                    "title": "Merged work",
                    "state": "closed",
                    "merged_at": "2026-11-08T12:00:00Z",
                    "html_url": "https://github.com/acme/app/pull/9",
                    "updated_at": "2026-11-08T12:00:00Z",
                    "user": {"login": "dev"},
                }
            ],
        }

        def responder(request: httpx.Request) -> httpx.Response:
            path = request.url.path
            if request.url.path == "/search/issues":
                query = request.url.params["q"]
                count = 4 if "is:pr" in query else 3
                return httpx.Response(
                    200,
                    json={"total_count": count, "incomplete_results": False},
                )
            if path in responses:
                return httpx.Response(200, json=responses[path])
            return httpx.Response(404)

        with httpx.Client(transport=httpx.MockTransport(responder)) as client:
            service = GitHubService(client=client)
            repository = {
                "updated_at": "2026-11-08T12:00:00Z",
            }
            summary = service.get_summary("acme", "app", repository)

        self.assertEqual(summary["open_pull_requests"], 4)
        self.assertEqual(summary["resolved_issues_30d"], 3)
        self.assertEqual(
            {item["name"]: item["percentage"] for item in summary["languages"]},
            {"Python": 75.0, "Dart": 25.0},
        )
        self.assertEqual(len(summary["recent_activity"]), 3)
        issue = next(item for item in summary["recent_activity"] if item["type"] == "issue")
        self.assertEqual(issue["labels"], ["bug"])
        pull = next(
            item
            for item in summary["recent_activity"]
            if item["type"] == "pull_request"
        )
        self.assertEqual(pull["state"], "merged")

    def test_not_found_and_rate_limit_errors_are_distinguished(self) -> None:
        for response, error in (
            (httpx.Response(404), GitHubRepositoryNotFound),
            (
                httpx.Response(
                    403,
                    headers={"X-RateLimit-Remaining": "0"},
                ),
                GitHubRateLimitExceeded,
            ),
        ):
            with self.subTest(error=error.__name__):
                client = httpx.Client(
                    transport=httpx.MockTransport(lambda _: response),
                )
                service = GitHubService(client=client)
                with self.assertRaises(error):
                    service.get_repository("acme", "missing")
                client.close()

    def test_incomplete_search_results_do_not_become_a_count(self) -> None:
        client = httpx.Client(
            transport=httpx.MockTransport(
                lambda _: httpx.Response(
                    200,
                    json={"total_count": 50, "incomplete_results": True},
                )
            )
        )
        service = GitHubService(client=client)
        self.assertIsNone(service._search_count("repo:acme/app is:pr is:open"))
        client.close()

    def test_weekly_activity_requires_all_eight_weeks(self) -> None:
        today = datetime.now(timezone.utc).date()
        current_sunday = today - timedelta(days=(today.weekday() + 1) % 7)
        first_sunday = current_sunday - timedelta(weeks=7)
        weeks = [
            {
                "week": int(
                    datetime.combine(
                        first_sunday + timedelta(weeks=index),
                        datetime.min.time(),
                        timezone.utc,
                    ).timestamp()
                ),
                "total": index + 1,
            }
            for index in range(8)
        ]
        client = httpx.Client(
            transport=httpx.MockTransport(
                lambda _: httpx.Response(200, json={"all": weeks})
            )
        )
        service = GitHubService(client=client)

        result = service._weekly_activity("acme/app", "main", "2020-01-01T00:00:00Z")

        self.assertEqual(result["availability"], "available")
        self.assertTrue(result["is_complete"])
        self.assertEqual(result["total_commits"], 36)
        self.assertEqual(len(result["weeks"]), 8)
        client.close()

        incomplete_weeks = weeks[:-1]
        client = httpx.Client(
            transport=httpx.MockTransport(
                lambda _: httpx.Response(200, json={"all": incomplete_weeks})
            )
        )
        result = GitHubService(client=client)._weekly_activity(
            "acme/app",
            "main",
            "2020-01-01T00:00:00Z",
        )
        self.assertEqual(result["availability"], "incomplete")
        self.assertIsNone(result["total_commits"])
        self.assertIsNone(result["weeks"][-1]["commits"])
        client.close()

    def test_weekly_activity_preserves_processing_state(self) -> None:
        client = httpx.Client(
            transport=httpx.MockTransport(lambda _: httpx.Response(202))
        )
        result = GitHubService(client=client)._weekly_activity(
            "acme/app",
            "main",
            "2020-01-01T00:00:00Z",
        )
        self.assertEqual(result["availability"], "processing")
        self.assertFalse(result["is_complete"])
        self.assertIsNone(result["total_commits"])
        client.close()

    def test_ci_states_and_test_file_detection_are_explicit(self) -> None:
        def responder(request: httpx.Request) -> httpx.Response:
            if request.url.path.endswith("/check-runs"):
                return httpx.Response(
                    200,
                    json={
                        "total_count": 1,
                        "check_runs": [
                            {
                                "status": "completed",
                                "conclusion": "failure",
                                "completed_at": "2026-11-08T12:00:00Z",
                                "html_url": "https://github.com/acme/app/actions",
                            }
                        ],
                    },
                )
            if request.url.path.endswith("/status"):
                return httpx.Response(200, json={"statuses": []})
            if "/git/trees/" in request.url.path:
                return httpx.Response(
                    200,
                    json={
                        "truncated": False,
                        "tree": [{"type": "blob", "path": "tests/test_app.py"}],
                    },
                )
            return httpx.Response(404)

        client = httpx.Client(transport=httpx.MockTransport(responder))
        service = GitHubService(client=client)

        ci = service._ci_signals("acme/app", "abc123")
        tests_detected = service._tests_detected("acme/app", "main")

        self.assertEqual(ci["state"], "failure")
        self.assertEqual(ci["failed"], 1)
        self.assertEqual(ci["passed"], 0)
        self.assertEqual(ci["availability"], "available")
        self.assertTrue(tests_detected)
        client.close()


class RepositoryConnectionTests(unittest.TestCase):
    user_id = "verified-user-id"

    def setUp(self) -> None:
        self.database = InMemoryDatabase()
        self.github = FakeGitHubService()
        self.service = RepositoryService(github=self.github)
        self.database_patch = patch.object(
            supabase_service,
            "get_client",
            return_value=self.database,
        )
        self.database_patch.start()
        self.addCleanup(self.database_patch.stop)

    def test_connection_persists_idempotently_and_is_user_scoped(self) -> None:
        url = "https://github.com/acme/app"
        first = self.service.connect(self.user_id, url)
        second = self.service.connect(self.user_id, url)

        self.assertEqual(first["id"], second["id"])
        self.assertEqual(len(self.database.tables["connected_repositories"]), 1)
        self.assertEqual(self.github.repository_calls, 1)
        self.assertEqual(self.github.summary_calls, 1)
        self.assertIsNone(self.service.get_connection("another-user", first["id"]))
        overview = self.service.overview(self.user_id, first["id"])
        self.assertFalse(overview["is_stale"])
        self.assertEqual(overview["summary"]["open_pull_requests"], 1)

    def test_multiple_connections_can_be_disconnected_individually(self) -> None:
        first = self.service.connect(
            self.user_id,
            "https://github.com/acme/app",
        )
        second = self.service.connect(
            self.user_id,
            "https://github.com/acme/other",
        )

        self.assertEqual(len(self.service.list_connections(self.user_id)), 2)
        self.assertTrue(self.service.disconnect(self.user_id, first["id"]))
        self.assertFalse(self.service.disconnect("another-user", second["id"]))
        remaining = self.service.list_connections(self.user_id)
        self.assertEqual([row["id"] for row in remaining], [second["id"]])

    def test_recent_refresh_is_throttled_and_stale_cache_survives_outage(self) -> None:
        connection = self.service.connect(
            self.user_id,
            "https://github.com/acme/app",
        )
        before = (self.github.repository_calls, self.github.summary_calls)
        refreshed = self.service.refresh(self.user_id, connection["id"])
        self.assertTrue(refreshed[1])
        self.assertEqual(
            (self.github.repository_calls, self.github.summary_calls),
            before,
        )

        old_sync = datetime(2020, 1, 1, tzinfo=timezone.utc).isoformat()
        self.database.tables["connected_repositories"][0]["last_synced_at"] = old_sync
        self.github.get_repository = Mock(side_effect=GitHubUnavailable)
        cached = self.service.connect(
            self.user_id,
            "https://github.com/acme/app",
        )
        self.assertEqual(cached["last_synced_at"], old_sync)
        self.assertTrue(self.service.is_stale(cached))

    def test_private_repository_is_rejected(self) -> None:
        self.github.get_repository = Mock(
            return_value={
                "private": True,
            }
        )
        with self.assertRaises(GitHubPrivateRepository):
            self.service.connect(
                self.user_id,
                "https://github.com/acme/private",
            )

    def test_authenticated_endpoint_uses_verified_user_id(self) -> None:
        app.dependency_overrides[get_current_user] = lambda: AuthenticatedUser(
            id=self.user_id
        )
        self.addCleanup(app.dependency_overrides.clear)
        record = {
            "id": "connection-1",
            "github_repository_id": 123,
            "repository_full_name": "acme/app",
            "repository_url": "https://github.com/acme/app",
            "repository_owner": "acme",
            "repository_name": "app",
            "is_private": False,
            "connected_at": datetime.now(timezone.utc).isoformat(),
            "last_synced_at": datetime.now(timezone.utc).isoformat(),
            "cached_summary": {},
        }
        with patch.object(repository_service, "connect", return_value=record) as connect:
            response = TestClient(app).post(
                "/api/v1/github/connections",
                json={"repository_url": "https://github.com/acme/app"},
            )

        self.assertEqual(response.status_code, 200)
        connect.assert_called_once_with(self.user_id, "https://github.com/acme/app")
        self.assertNotIn("user_id", response.json())

    def test_disconnect_endpoint_uses_verified_user_id(self) -> None:
        app.dependency_overrides[get_current_user] = lambda: AuthenticatedUser(
            id=self.user_id
        )
        self.addCleanup(app.dependency_overrides.clear)
        with patch.object(
            repository_service,
            "disconnect",
            return_value=True,
        ) as disconnect:
            response = TestClient(app).delete(
                "/api/v1/github/connections/connection-1"
            )

        self.assertEqual(response.status_code, 204)
        disconnect.assert_called_once_with(self.user_id, "connection-1")

    def test_missing_token_is_rejected(self) -> None:
        app.dependency_overrides.pop(get_current_user, None)
        response = TestClient(app).get("/api/v1/github/connections")
        self.assertEqual(response.status_code, 401)


if __name__ == "__main__":
    unittest.main()
