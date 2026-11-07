import logging
from dataclasses import dataclass
from typing import Annotated

import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from postgrest.exceptions import APIError
from supabase import SupabaseException
from supabase_auth.errors import (
    AuthApiError,
    AuthError,
    AuthInvalidJwtError,
)

from app.services.supabase_service import (
    SupabaseConfigurationError,
    supabase_service,
)

logger = logging.getLogger(__name__)
bearer_scheme = HTTPBearer(auto_error=False)


@dataclass(frozen=True)
class AuthenticatedUser:
    id: str


def _unauthorized() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired access token.",
        headers={"WWW-Authenticate": "Bearer"},
    )


def get_current_user(
    credentials: Annotated[
        HTTPAuthorizationCredentials | None,
        Depends(bearer_scheme),
    ],
) -> AuthenticatedUser:
    if credentials is None or not credentials.credentials:
        raise _unauthorized()

    try:
        response = supabase_service.get_auth_client().auth.get_user(
            credentials.credentials
        )
    except AuthInvalidJwtError as error:
        raise _unauthorized() from error
    except AuthApiError as error:
        if 400 <= error.status < 500 and error.status != 429:
            raise _unauthorized() from error
        logger.warning(
            "Supabase token verification failed (%s).",
            type(error).__name__,
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service is unavailable.",
        ) from error
    except (AuthError, APIError, httpx.HTTPError, OSError, SupabaseException) as error:
        logger.warning(
            "Supabase token verification failed (%s).",
            type(error).__name__,
        )
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service is unavailable.",
        ) from error
    except SupabaseConfigurationError as error:
        logger.error("Supabase authentication is not configured.")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service is unavailable.",
        ) from error

    user = response.user if response is not None else None
    if user is None or not user.id:
        raise _unauthorized()

    return AuthenticatedUser(id=str(user.id))
