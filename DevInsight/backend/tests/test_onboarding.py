import unittest
from unittest.mock import patch

from fastapi.testclient import TestClient

from app.api.dependencies import AuthenticatedUser, get_current_user
from app.main import app
from app.services.supabase_service import supabase_service


class InMemoryQuery:
    def __init__(self, client: "InMemorySupabase", table_name: str) -> None:
        self.client = client
        self.table_name = table_name
        self.filters: list[tuple[str, str, str]] = []
        self.operation = "select"
        self.payload: dict[str, object] = {}
        self.conflict_field = ""
        self.ignore_duplicates = False

    def select(self, _: str) -> "InMemoryQuery":
        return self

    def eq(self, field: str, value: str) -> "InMemoryQuery":
        self.filters.append(("eq", field, value))
        return self

    def ilike(self, field: str, value: str) -> "InMemoryQuery":
        self.filters.append(("ilike", field, value))
        return self

    def limit(self, _: int) -> "InMemoryQuery":
        return self

    def upsert(
        self,
        payload: dict[str, object],
        *,
        on_conflict: str,
        ignore_duplicates: bool = False,
    ) -> "InMemoryQuery":
        self.operation = "upsert"
        self.payload = payload
        self.conflict_field = on_conflict
        self.ignore_duplicates = ignore_duplicates
        return self

    def update(self, payload: dict[str, object]) -> "InMemoryQuery":
        self.operation = "update"
        self.payload = payload
        return self

    def execute(self) -> object:
        rows = self.client.tables.setdefault(self.table_name, [])
        matched = [row for row in rows if self._matches(row)]
        if self.operation == "upsert":
            existing = next(
                (
                    row
                    for row in rows
                    if row.get(self.conflict_field)
                    == self.payload.get(self.conflict_field)
                ),
                None,
            )
            if existing is None:
                rows.append(dict(self.payload))
            elif not self.ignore_duplicates:
                existing.update(self.payload)
            matched = [
                row
                for row in rows
                if row.get(self.conflict_field)
                == self.payload.get(self.conflict_field)
            ]
        elif self.operation == "update":
            for row in matched:
                row.update(self.payload)
        return type("Response", (), {"data": [dict(row) for row in matched]})()

    def _matches(self, row: dict[str, object]) -> bool:
        for operation, field, value in self.filters:
            row_value = str(row.get(field, ""))
            if operation == "eq" and row_value != value:
                return False
            if operation == "ilike" and row_value.casefold() != value.casefold():
                return False
        return True


class InMemorySupabase:
    def __init__(self, profiles: list[dict[str, object]] | None = None) -> None:
        self.tables: dict[str, list[dict[str, object]]] = {
            "profiles": [dict(row) for row in (profiles or [])],
            "user_preferences": [],
            "notification_settings": [],
        }

    def table(self, table_name: str) -> InMemoryQuery:
        return InMemoryQuery(self, table_name)


class OnboardingEndpointTests(unittest.TestCase):
    user_id = "verified-user-id"

    def setUp(self) -> None:
        app.dependency_overrides[get_current_user] = lambda: AuthenticatedUser(
            id=self.user_id
        )
        self.client = TestClient(app)
        self.database = InMemorySupabase()
        self.client_patch = patch.object(
            supabase_service,
            "get_client",
            return_value=self.database,
        )
        self.client_patch.start()
        self.addCleanup(self.client_patch.stop)
        self.addCleanup(app.dependency_overrides.clear)

    def _profile(self, **overrides: object) -> dict[str, object]:
        return {
            "id": self.user_id,
            "full_name": "Test User",
            "username": "testuser",
            "organization": None,
            "job_title": None,
            "role": "developer",
            "onboarding_step": 2,
            "onboarding_completed": False,
            **overrides,
        }

    @staticmethod
    def _profile_payload(**overrides: object) -> dict[str, object]:
        return {
            "full_name": "New User",
            "username": "NewUser",
            "organization": "Example Org",
            "job_title": "Engineer",
            "role": "developer",
            **overrides,
        }

    def test_onboarding_route_rejects_missing_access_token(self) -> None:
        app.dependency_overrides.clear()
        response = self.client.put(
            "/api/v1/onboarding/profile",
            json=self._profile_payload(),
        )
        self.assertEqual(response.status_code, 401)

    def test_local_flutter_web_preflight_is_allowed(self) -> None:
        response = self.client.options(
            "/api/v1/me",
            headers={
                "Origin": "http://localhost:5173",
                "Access-Control-Request-Method": "GET",
                "Access-Control-Request-Headers": "authorization",
            },
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.headers["access-control-allow-origin"],
            "http://localhost:5173",
        )

    def test_profile_creation_uses_authenticated_id_and_normalizes_username(self) -> None:
        response = self.client.put(
            "/api/v1/onboarding/profile",
            json=self._profile_payload(),
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["onboarding_step"], 2)
        profile = self.database.tables["profiles"][0]
        self.assertEqual(profile["id"], self.user_id)
        self.assertEqual(profile["username"], "newuser")
        self.assertFalse(profile["onboarding_completed"])

    def test_profile_update_preserves_later_progress_and_completion(self) -> None:
        self.database.tables["profiles"].append(
            self._profile(onboarding_step=3, onboarding_completed=True)
        )

        response = self.client.put(
            "/api/v1/onboarding/profile",
            json=self._profile_payload(role="project_manager"),
        )
        repeated = self.client.put(
            "/api/v1/onboarding/profile",
            json=self._profile_payload(role="project_manager"),
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(repeated.status_code, 200)
        profile = self.database.tables["profiles"][0]
        self.assertEqual(len(self.database.tables["profiles"]), 1)
        self.assertEqual(profile["onboarding_step"], 3)
        self.assertTrue(profile["onboarding_completed"])
        self.assertEqual(profile["role"], "project_manager")

    def test_profile_rejects_duplicate_username_and_client_user_id(self) -> None:
        self.database.tables["profiles"].append(
            self._profile(id="another-user", username="claimed")
        )
        duplicate = self.client.put(
            "/api/v1/onboarding/profile",
            json=self._profile_payload(username="CLAIMED"),
        )
        with_user_id = self.client.put(
            "/api/v1/onboarding/profile",
            json=self._profile_payload(user_id="another-user"),
        )
        with_progress = self.client.put(
            "/api/v1/onboarding/profile",
            json=self._profile_payload(onboarding_completed=True),
        )

        self.assertEqual(duplicate.status_code, 409)
        self.assertEqual(with_user_id.status_code, 422)
        self.assertEqual(with_progress.status_code, 422)
        self.assertEqual(len(self.database.tables["profiles"]), 1)

    def test_profile_validation_rejects_invalid_role_and_blank_name(self) -> None:
        invalid_role = self.client.put(
            "/api/v1/onboarding/profile",
            json=self._profile_payload(role="admin"),
        )
        blank_name = self.client.put(
            "/api/v1/onboarding/profile",
            json=self._profile_payload(full_name="   "),
        )

        self.assertEqual(invalid_role.status_code, 422)
        self.assertEqual(blank_name.status_code, 422)

    def test_preferences_require_profile_and_dedupe_supported_interests(self) -> None:
        blocked = self.client.put(
            "/api/v1/onboarding/preferences",
            json={"interests": ["Code Quality & Issues"]},
        )
        self.assertEqual(blocked.status_code, 409)

        self.database.tables["profiles"].append(self._profile())
        response = self.client.put(
            "/api/v1/onboarding/preferences",
            json={
                "interests": [
                    "Code Quality & Issues",
                    "AI Recommendations",
                    "Code Quality & Issues",
                ]
            },
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            self.database.tables["user_preferences"][0],
            {
                "user_id": self.user_id,
                "interests": ["Code Quality & Issues", "AI Recommendations"],
                "updated_at": self.database.tables["user_preferences"][0][
                    "updated_at"
                ],
            },
        )
        self.assertEqual(self.database.tables["profiles"][0]["onboarding_step"], 3)

    def test_preferences_reject_unsupported_values_and_foreign_user_id(self) -> None:
        self.database.tables["profiles"].append(self._profile())
        invalid_value = self.client.put(
            "/api/v1/onboarding/preferences",
            json={"interests": ["unknown"]},
        )
        foreign_user = self.client.put(
            "/api/v1/onboarding/preferences",
            json={"interests": [], "user_id": "another-user"},
        )

        self.assertEqual(invalid_value.status_code, 422)
        self.assertEqual(foreign_user.status_code, 422)
        self.assertEqual(self.database.tables["user_preferences"], [])

    def test_notifications_require_preferences_and_save_idempotently(self) -> None:
        self.database.tables["profiles"].append(self._profile(onboarding_step=3))
        payload = {
            "email_enabled": True,
            "push_enabled": False,
            "topics": ["Project Updates", "Project Updates"],
        }
        blocked = self.client.put(
            "/api/v1/onboarding/notifications",
            json=payload,
        )
        self.assertEqual(blocked.status_code, 409)

        self.database.tables["user_preferences"].append(
            {"user_id": self.user_id, "interests": []}
        )
        first = self.client.put("/api/v1/onboarding/notifications", json=payload)
        second = self.client.put("/api/v1/onboarding/notifications", json=payload)

        self.assertEqual(first.status_code, 200)
        self.assertEqual(second.status_code, 200)
        self.assertEqual(len(self.database.tables["notification_settings"]), 1)
        saved = self.database.tables["notification_settings"][0]
        self.assertTrue(saved["email_enabled"])
        self.assertFalse(saved["push_enabled"])
        self.assertEqual(saved["topics"], ["Project Updates"])

    def test_notifications_validate_strict_booleans_and_categories(self) -> None:
        invalid_boolean = self.client.put(
            "/api/v1/onboarding/notifications",
            json={
                "email_enabled": "yes",
                "push_enabled": False,
                "topics": [],
            },
        )
        invalid_topic = self.client.put(
            "/api/v1/onboarding/notifications",
            json={
                "email_enabled": True,
                "push_enabled": False,
                "topics": ["Other"],
            },
        )

        self.assertEqual(invalid_boolean.status_code, 422)
        self.assertEqual(invalid_topic.status_code, 422)

    def test_completion_requires_all_steps_then_is_idempotent(self) -> None:
        self.database.tables["profiles"].append(self._profile())
        incomplete = self.client.post("/api/v1/onboarding/complete")
        self.assertEqual(incomplete.status_code, 409)

        self.database.tables["user_preferences"].append(
            {"user_id": self.user_id, "interests": []}
        )
        still_incomplete = self.client.post("/api/v1/onboarding/complete")
        self.assertEqual(still_incomplete.status_code, 409)

        self.database.tables["notification_settings"].append(
            {"user_id": self.user_id, "email_enabled": False}
        )
        completed = self.client.post("/api/v1/onboarding/complete")
        repeated = self.client.post("/api/v1/onboarding/complete")

        expected = {
            "onboarding_completed": True,
            "role": "developer",
            "next_step": "developer_home",
        }
        self.assertEqual(completed.status_code, 200)
        self.assertEqual(completed.json(), expected)
        self.assertEqual(repeated.json(), expected)
        self.assertEqual(len(self.database.tables["profiles"]), 1)

    def test_project_manager_completion_and_me_routing(self) -> None:
        self.database.tables["profiles"].append(
            self._profile(role="project_manager", onboarding_step=3)
        )
        self.database.tables["user_preferences"].append(
            {"user_id": self.user_id, "interests": []}
        )
        self.database.tables["notification_settings"].append(
            {"user_id": self.user_id, "email_enabled": True}
        )

        completed = self.client.post("/api/v1/onboarding/complete")
        current_user = self.client.get("/api/v1/me")

        self.assertEqual(completed.json()["next_step"], "manager_home")
        self.assertEqual(current_user.json()["next_step"], "manager_home")

    def test_me_routes_by_saved_incomplete_progress(self) -> None:
        self.database.tables["profiles"].append(self._profile())
        self.assertEqual(self.client.get("/api/v1/me").json()["next_step"], "preferences")
        self.database.tables["user_preferences"].append(
            {"user_id": self.user_id, "interests": []}
        )
        self.assertEqual(self.client.get("/api/v1/me").json()["next_step"], "notifications")
        self.database.tables["notification_settings"].append(
            {"user_id": self.user_id, "email_enabled": False}
        )
        self.assertEqual(self.client.get("/api/v1/me").json()["next_step"], "complete")


if __name__ == "__main__":
    unittest.main()
