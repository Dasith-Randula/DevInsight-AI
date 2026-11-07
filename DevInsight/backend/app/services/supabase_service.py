import logging

import httpx
from postgrest.exceptions import APIError
from supabase import Client, SupabaseException, create_client

from app.config import Settings

logger = logging.getLogger(__name__)

REQUIRED_TABLES = (
    "profiles",
    "user_preferences",
    "notification_settings",
)


class SupabaseConfigurationError(RuntimeError):
    """Raised when Supabase settings are absent or invalid."""


class SupabaseService:
    def __init__(self) -> None:
        self._client: Client | None = None
        self._auth_client: Client | None = None

    @property
    def is_configured(self) -> bool:
        return self._client is not None

    def initialize(self, settings: Settings) -> None:
        url = settings.supabase_url.strip() if settings.supabase_url else ""
        secret_key = (
            settings.supabase_secret_key.strip()
            if settings.supabase_secret_key
            else ""
        )
        if not url or not secret_key:
            self._client = None
            self._auth_client = None
            raise SupabaseConfigurationError(
                "SUPABASE_URL and SUPABASE_SECRET_KEY must be set in backend/.env."
            )

        try:
            publishable_key = (
                settings.supabase_publishable_key.strip()
                if settings.supabase_publishable_key
                else ""
            )
            client = create_client(url, secret_key)
            auth_client = create_client(
                url,
                publishable_key or secret_key,
            )
        except (SupabaseException, ValueError) as error:
            self._client = None
            self._auth_client = None
            raise SupabaseConfigurationError(
                "Supabase client configuration is invalid."
            ) from error

        self._client = client
        self._auth_client = auth_client

    def get_client(self) -> Client:
        if self._client is None:
            raise SupabaseConfigurationError(
                "Supabase is not configured. Set backend/.env first."
            )
        return self._client

    def get_auth_client(self) -> Client:
        if self._auth_client is None:
            raise SupabaseConfigurationError(
                "Supabase is not configured. Set backend/.env first."
            )
        return self._auth_client

    def verify_required_tables(self) -> dict[str, bool]:
        client = self.get_client()
        results: dict[str, bool] = {}

        for table_name in REQUIRED_TABLES:
            try:
                client.table(table_name).select("*").limit(1).execute()
            except (
                APIError,
                httpx.HTTPError,
                OSError,
                SupabaseException,
                ValueError,
            ) as error:
                results[table_name] = False
                logger.warning(
                    "Supabase table verification failed for %s (%s).",
                    table_name,
                    type(error).__name__,
                )
            else:
                results[table_name] = True
                logger.info("Supabase table is accessible: %s", table_name)

        return results


supabase_service = SupabaseService()
