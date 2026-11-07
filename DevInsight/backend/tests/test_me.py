import unittest
from types import SimpleNamespace
from unittest.mock import Mock, patch

from fastapi.testclient import TestClient
from supabase_auth.errors import AuthApiError

from app.api.me import get_next_step
from app.main import app
from app.services.profile_service import ProfileService, ProfileServiceError
from app.services.supabase_service import supabase_service


class CurrentUserEndpointTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)
        self.profile = {
            "id": "verified-user-id",
            "full_name": "Test User",
            "username": "testuser",
            "organization": None,
            "job_title": None,
            "role": None,
            "onboarding_step": 1,
            "onboarding_completed": False,
        }

    def _mock_auth(self, user_id: str = "verified-user-id") -> Mock:
        auth_client = Mock()
        auth_client.auth.get_user.return_value = SimpleNamespace(
            user=SimpleNamespace(id=user_id)
        )
        return patch.object(
            supabase_service,
            "get_auth_client",
            return_value=auth_client,
        )

    def test_missing_token_is_rejected(self) -> None:
        with patch.object(supabase_service, "get_auth_client") as get_auth:
            response = self.client.get("/api/v1/me")
        self.assertEqual(response.status_code, 401)
        get_auth.assert_not_called()

    def test_invalid_token_is_rejected(self) -> None:
        auth_client = Mock()
        auth_client.auth.get_user.side_effect = AuthApiError(
            "invalid token",
            401,
            None,
        )
        with patch.object(
            supabase_service,
            "get_auth_client",
            return_value=auth_client,
        ):
            response = self.client.get(
                "/api/v1/me",
                headers={"Authorization": "Bearer invalid"},
            )
        self.assertEqual(response.status_code, 401)

    def test_expired_token_is_rejected(self) -> None:
        auth_client = Mock()
        auth_client.auth.get_user.side_effect = AuthApiError(
            "token expired",
            401,
            None,
        )
        with patch.object(
            supabase_service,
            "get_auth_client",
            return_value=auth_client,
        ):
            response = self.client.get(
                "/api/v1/me",
                headers={"Authorization": "Bearer expired"},
            )
        self.assertEqual(response.status_code, 401)

    def test_profile_lookup_uses_verified_user_id(self) -> None:
        with self._mock_auth(), patch(
            "app.api.me.profile_service.get_onboarding_state",
            return_value=(self.profile, False, False),
        ) as get_profile:
            response = self.client.get(
                "/api/v1/me",
                headers={"Authorization": "Bearer valid"},
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["id"], "verified-user-id")
        self.assertEqual(response.json()["next_step"], "profile")
        get_profile.assert_called_once_with("verified-user-id")

    def test_completed_roles_are_returned_with_their_home_route(self) -> None:
        for role, next_step in (
            ("developer", "developer_home"),
            ("project_manager", "manager_home"),
        ):
            profile = {
                **self.profile,
                "role": role,
                "onboarding_step": 3,
                "onboarding_completed": True,
            }
            with self.subTest(role=role), self._mock_auth(), patch(
                "app.api.me.profile_service.get_onboarding_state",
                return_value=(profile, True, True),
            ):
                response = self.client.get(
                    "/api/v1/me",
                    headers={"Authorization": " ".join(("Bearer", "not-a-real-token"))},
                )
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.json()["next_step"], next_step)

    def test_completed_roles_are_returned_with_their_home_route(self) -> None:
        for role, next_step in (
            ("developer", "developer_home"),
            ("project_manager", "manager_home"),
        ):
            profile = {
                **self.profile,
                "role": role,
                "onboarding_step": 3,
                "onboarding_completed": True,
            }
            with self.subTest(role=role), self._mock_auth(), patch(
                "app.api.me.profile_service.get_onboarding_state",
                return_value=(profile, True, True),
            ):
                response = self.client.get(
                    "/api/v1/me",
                    headers={"Authorization": "Bearer valid"},
                )
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.json()["next_step"], next_step)

    def test_profile_creation_is_idempotent_for_missing_profile(self) -> None:
        query = Mock()
        query.select.return_value = query
        query.eq.return_value = query
        query.limit.return_value = query
        query.upsert.return_value = query
        query.execute.side_effect = [
            SimpleNamespace(data=[]),
            SimpleNamespace(data=[]),
            SimpleNamespace(data=[self.profile]),
        ]
        table = Mock(return_value=query)
        client = Mock()
        client.table = table

        with patch(
            "app.services.profile_service.supabase_service.get_client",
            return_value=client,
        ):
            result = ProfileService().get_or_create_profile("verified-user-id")

        self.assertEqual(result, self.profile)
        table.assert_called_with("profiles")
        query.upsert.assert_called_once_with(
            {
                "id": "verified-user-id",
                "role": None,
                "onboarding_step": 1,
                "onboarding_completed": False,
            },
            on_conflict="id",
            ignore_duplicates=True,
        )

    def test_profile_database_failure_is_reported(self) -> None:
        client = Mock()
        client.table.side_effect = OSError("database unavailable")
        with patch(
            "app.services.profile_service.supabase_service.get_client",
            return_value=client,
        ):
            with self.assertRaises(ProfileServiceError):
                ProfileService().get_or_create_profile("verified-user-id")

    def test_profile_creation_failure_returns_service_unavailable(self) -> None:
        with self._mock_auth(), patch(
            "app.api.me.profile_service.get_or_create_profile",
            side_effect=ProfileServiceError("database unavailable"),
        ):
            response = self.client.get(
                "/api/v1/me",
                headers={"Authorization": "Bearer valid"},
            )
        self.assertEqual(response.status_code, 503)


class OnboardingRoutingTests(unittest.TestCase):
    def test_incomplete_profile_routes_to_profile(self) -> None:
        self.assertEqual(
            get_next_step(
                {
                    "role": None,
                    "onboarding_step": 1,
                    "onboarding_completed": False,
                }
            ),
            "profile",
        )

    def test_completed_developer_routes_home(self) -> None:
        self.assertEqual(
            get_next_step(
                {
                    "role": "developer",
                    "onboarding_step": 3,
                    "onboarding_completed": True,
                }
            ),
            "developer_home",
        )

    def test_completed_project_manager_routes_home(self) -> None:
        self.assertEqual(
            get_next_step(
                {
                    "role": "project_manager",
                    "onboarding_step": 3,
                    "onboarding_completed": True,
                }
            ),
            "manager_home",
        )


class HealthEndpointTests(unittest.TestCase):
    def test_health_response_is_unchanged(self) -> None:
        response = TestClient(app).get("/api/v1/health")
        self.assertEqual(
            response.json(),
            {"status": "healthy", "service": "DevInsight Backend"},
        )


class HealthEndpointTests(unittest.TestCase):
    def test_health_response_is_unchanged(self) -> None:
        response = TestClient(app).get("/api/v1/health")
        self.assertEqual(
            response.json(),
            {"status": "healthy", "service": "DevInsight Backend"},
        )


if __name__ == "__main__":
    unittest.main()
