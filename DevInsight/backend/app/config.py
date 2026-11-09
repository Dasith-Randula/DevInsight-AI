from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=BACKEND_DIR / ".env",
        env_file_encoding="utf-8",
        env_ignore_empty=True,
        extra="ignore",
    )

    supabase_url: str | None = None
    supabase_secret_key: str | None = Field(default=None, repr=False)
    supabase_publishable_key: str | None = Field(default=None, repr=False)
    github_token: str | None = Field(default=None, repr=False)
    github_cache_minutes: int = Field(default=15, ge=10, le=15)
    cors_allowed_origins: str = ""


@lru_cache
def get_settings() -> Settings:
    return Settings()
