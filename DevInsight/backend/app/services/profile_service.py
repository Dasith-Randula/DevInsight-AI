import httpx
from postgrest.exceptions import APIError
from supabase import Client, SupabaseException

from app.services.supabase_service import (
    SupabaseConfigurationError,
    supabase_service,
)

PROFILE_DATABASE_ERRORS = (
    APIError,
    httpx.HTTPError,
    OSError,
    SupabaseConfigurationError,
    SupabaseException,
    ValueError,
)


class ProfileServiceError(RuntimeError):
    """Raised when a profile cannot be read or created."""


class ProfileService:
    def get_or_create_profile(self, user_id: str) -> dict[str, object]:
        try:
            client = supabase_service.get_client()
            profile = self._find_profile(client, user_id)
            if profile is not None:
                return profile

            (
                client.table("profiles")
                .upsert(
                    {
                        "id": user_id,
                        "role": None,
                        "onboarding_step": 1,
                        "onboarding_completed": False,
                    },
                    on_conflict="id",
                    ignore_duplicates=True,
                )
                .execute()
            )
            profile = self._find_profile(client, user_id)
        except PROFILE_DATABASE_ERRORS as error:
            raise ProfileServiceError(
                "The profile could not be retrieved or created."
            ) from error

        if profile is None:
            raise ProfileServiceError("The profile could not be retrieved or created.")
        return profile

    def get_onboarding_state(
        self, user_id: str
    ) -> tuple[dict[str, object], bool, bool]:
        profile = self.get_or_create_profile(user_id)
        try:
            client = supabase_service.get_client()
            preferences_saved = self._has_record(
                client,
                "user_preferences",
                "user_id",
                user_id,
            )
            notifications_saved = self._has_record(
                client,
                "notification_settings",
                "user_id",
                user_id,
            )
        except PROFILE_DATABASE_ERRORS as error:
            raise ProfileServiceError(
                "The onboarding state could not be retrieved."
            ) from error
        return profile, preferences_saved, notifications_saved

    @staticmethod
    def _find_profile(client: Client, user_id: str) -> dict[str, object] | None:
        response = (
            client.table("profiles")
            .select("*")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )
        rows = response.data
        if not rows:
            return None
        return rows[0]

    @staticmethod
    def _has_record(
        client: Client,
        table_name: str,
        field: str,
        value: str,
    ) -> bool:
        response = (
            client.table(table_name)
            .select(field)
            .eq(field, value)
            .limit(1)
            .execute()
        )
        return bool(response.data)


profile_service = ProfileService()
