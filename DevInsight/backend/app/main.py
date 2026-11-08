import logging
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.concurrency import run_in_threadpool

from app.api.github import router as github_router
from app.api.me import router as me_router
from app.api.onboarding import router as onboarding_router
from app.config import get_settings
from app.services.supabase_service import (
    SupabaseConfigurationError,
    supabase_service,
)

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncGenerator[None, None]:
    try:
        supabase_service.initialize(get_settings())
    except SupabaseConfigurationError as error:
        logger.warning("Supabase verification skipped: %s", error)
    else:
        results = await run_in_threadpool(supabase_service.verify_required_tables)
        failed_tables = [name for name, accessible in results.items() if not accessible]
        if failed_tables:
            logger.warning(
                "Supabase verification incomplete for tables: %s",
                ", ".join(failed_tables),
            )
        else:
            logger.info("All required Supabase tables are accessible.")
    yield


app = FastAPI(
    title="DevInsight API",
    description="Backend API for DevInsight",
    version="1.0.0",
    lifespan=lifespan,
)
cors_allowed_origins = [
    origin.strip()
    for origin in get_settings().cors_allowed_origins.split(",")
    if origin.strip()
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_allowed_origins,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept"],
)
app.include_router(me_router)
app.include_router(onboarding_router)
app.include_router(github_router)


@app.get("/api/v1/health")
async def health_check() -> dict[str, str]:
    return {
        "status": "healthy",
        "service": "DevInsight Backend",
    }
