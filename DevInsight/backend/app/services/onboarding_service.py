from datetime import datetime, timezone
from typing import Final

import httpx
from postgrest.exceptions import APIError
from supabase import Client, SupabaseException

from app.services.supabase_service import (
    SupabaseConfigurationError,
    supabase_service,
)

PROFILE_DATABASE_ERRORS: Final = (
    APIError,
    httpx.HTTPError,
    OSError,
    SupabaseConfigurationError,
    SupabaseException,
    ValueError,
)
VALID_ROLES: Final = frozenset({"developer", "project_manager"})


class OnboardingServiceError(RuntimeError):
    """Raised when onboarding data cannot be saved or retrieved."""


class DuplicateUsernameError(OnboardingServiceError):
    """Raised when a username is already assigned to another user."""


class OnboardingIncompleteError(OnboardingServiceError):
    """Raised when an onboarding step is attempted before its prerequisites."""


class OnboardingService:
    def get_onboarding_state(self, user_id: str) -> dict[str, object]:
        try:
            client = supabase_service.get_client()
            profile = self._find_one(client, "profiles", "id", user_id)
            if profile is None:
                raise OnboardingServiceError("Profile could not be retrieved.")

            preferences = self._find_one(
                client,
                "user_preferences",
                "user_id",
                user_id,
            )
            notifications = self._find_one(
                client,
                "notification_settings",
                "user_id",
                user_id,
            )
        except OnboardingServiceError:
            raise
        except PROFILE_DATABASE_ERRORS as error:
            raise OnboardingServiceError(
                "Onboarding state could not be retrieved."
            ) from error

        return {
            "profile": profile,
            "preferences": preferences,
            "notifications": notifications,
        }

    def save_profile(self, user_id: str, values: dict[str, object]) -> dict[str, object]:
        try:
            client = supabase_service.get_client()
            current_profile = self._find_one(client, "profiles", "id", user_id)
            existing_username = (
                client.table("profiles")
                .select("id")
                .ilike("username", str(values["username"]))
                .limit(1)
                .execute()
                .data
            )
            if any(row["id"] != user_id for row in existing_username):
                raise DuplicateUsernameError("Username is already in use.")

            current_step = int((current_profile or {}).get("onboarding_step") or 1)
            profile_values: dict[str, object] = {
                **values,
                "id": user_id,
                "onboarding_step": max(current_step, 2),
                "updated_at": self._now(),
            }
            if current_profile is None:
                profile_values["onboarding_completed"] = False

            (
                client.table("profiles")
                .upsert(profile_values, on_conflict="id")
                .execute()
            )
            saved_profile = self._find_one(client, "profiles", "id", user_id)
        except DuplicateUsernameError:
            raise
        except APIError as error:
            if error.code == "23505":
                raise DuplicateUsernameError(
                    "Username is already in use."
                ) from error
            raise OnboardingServiceError("Profile could not be saved.") from error
        except PROFILE_DATABASE_ERRORS as error:
            raise OnboardingServiceError("Profile could not be saved.") from error

        if saved_profile is None:
            raise OnboardingServiceError("Profile could not be saved.")
        return saved_profile

    def save_preferences(
        self,
        user_id: str,
        interests: list[str],
    ) -> None:
        try:
            client = supabase_service.get_client()
            self._require_profile(client, user_id)
            (
                client.table("user_preferences")
                .upsert(
                    {
                        "user_id": user_id,
                        "interests": interests,
                        "updated_at": self._now(),
                    },
                    on_conflict="user_id",
                )
                .execute()
            )
            profile = self._find_one(client, "profiles", "id", user_id)
            if profile is not None and not profile.get("onboarding_completed"):
                step = max(int(profile.get("onboarding_step") or 1), 3)
                (
                    client.table("profiles")
                    .update({"onboarding_step": step, "updated_at": self._now()})
                    .eq("id", user_id)
                    .execute()
                )
        except OnboardingIncompleteError:
            raise
        except PROFILE_DATABASE_ERRORS as error:
            raise OnboardingServiceError("Preferences could not be saved.") from error

    def save_notifications(
        self,
        user_id: str,
        email_enabled: bool,
        push_enabled: bool,
        topics: list[str],
    ) -> None:
        try:
            client = supabase_service.get_client()
            self._require_profile(client, user_id)
            if self._find_one(client, "user_preferences", "user_id", user_id) is None:
                raise OnboardingIncompleteError(
                    "Save preferences before notification settings."
                )
            (
                client.table("notification_settings")
                .upsert(
                    {
                        "user_id": user_id,
                        "email_enabled": email_enabled,
                        "push_enabled": push_enabled,
                        "topics": topics,
                        "updated_at": self._now(),
                    },
                    on_conflict="user_id",
                )
                .execute()
            )
        except OnboardingIncompleteError:
            raise
        except PROFILE_DATABASE_ERRORS as error:
            raise OnboardingServiceError(
                "Notification settings could not be saved."
            ) from error

    def complete_onboarding(self, user_id: str) -> dict[str, object]:
        try:
            client = supabase_service.get_client()
            profile = self._require_profile(client, user_id)
            role = profile.get("role")
            if role not in VALID_ROLES:
                raise OnboardingIncompleteError(
                    "Complete profile setup with a valid role first."
                )
            if self._find_one(client, "user_preferences", "user_id", user_id) is None:
                raise OnboardingIncompleteError(
                    "Save preferences before completing onboarding."
                )
            if (
                self._find_one(client, "notification_settings", "user_id", user_id)
                is None
            ):
                raise OnboardingIncompleteError(
                    "Save notification settings before completing onboarding."
                )

            response = (
                client.table("profiles")
                .update(
                    {
                        "onboarding_step": 3,
                        "onboarding_completed": True,
                        "updated_at": self._now(),
                    }
                )
                .eq("id", user_id)
                .select("id,role,onboarding_step,onboarding_completed")
                .execute()
            )
            if not response.data:
                raise OnboardingServiceError("Onboarding could not be completed.")
            return response.data[0]
        except OnboardingIncompleteError:
            raise
        except PROFILE_DATABASE_ERRORS as error:
            raise OnboardingServiceError("Onboarding could not be completed.") from error

    @staticmethod
    def _find_one(
        client: Client,
        table_name: str,
        field: str,
        value: str,
    ) -> dict[str, object] | None:
        response = (
            client.table(table_name)
            .select("*")
            .eq(field, value)
            .limit(1)
            .execute()
        )
        return response.data[0] if response.data else None

    @staticmethod
    def _require_profile(client: Client, user_id: str) -> dict[str, object]:
        profile = OnboardingService._find_one(client, "profiles", "id", user_id)
        if (
            profile is None
            or int(profile.get("onboarding_step") or 1) < 2
            or profile.get("role") not in VALID_ROLES
        ):
            raise OnboardingIncompleteError(
                "Complete profile setup before continuing."
            )
        return profile

    @staticmethod
    def _now() -> str:
        return datetime.now(timezone.utc).isoformat()


onboarding_service = OnboardingService()
