from typing import Optional, Dict, Any
from fastapi import Depends, Header
from jose import jwt, JWTError
from .config import settings
from .exceptions import UnauthorizedException, ForbiddenException
from .logging import get_logger

logger = get_logger("security")


class UserContext:
    """Represents the authenticated user context."""
    def __init__(self, user_id: str, email: Optional[str] = None, role: str = "user", is_admin: bool = False):
        self.user_id = user_id
        self.email = email
        self.role = role
        self.is_admin = is_admin

    def to_actor(self) -> Dict[str, Any]:
        """Returns standard actor dictionary adhering to Convention #7."""
        return {
            "actor_type": "user",
            "user_id": self.user_id,
            "ai_run_id": None,
        }


async def get_token_from_header(authorization: Optional[str] = Header(None)) -> Optional[str]:
    """Extracts bearer token from Authorization header."""
    if not authorization:
        return None
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        return None
    return parts[1]


async def get_current_user(token: Optional[str] = Depends(get_token_from_header)) -> UserContext:
    """
    Authenticates request via Supabase JWT.
    In development mode without credentials, returns a mock user context if configured.
    """
    if not token:
        if settings.ENVIRONMENT == "development" and not settings.SUPABASE_URL:
            # Fallback dev user when Supabase is not yet configured
            return UserContext(
                user_id="00000000-0000-0000-0000-000000000001",
                email="dev@eureka.local",
                role="admin",
                is_admin=True,
            )
        raise UnauthorizedException("Authentication token required")

    try:
        # Verify JWT using secret if provided, or unverified claims for dev
        if settings.SUPABASE_JWT_SECRET:
            payload = jwt.decode(
                token,
                settings.SUPABASE_JWT_SECRET,
                algorithms=["HS256"],
                audience="authenticated",
            )
        else:
            payload = jwt.get_unverified_claims(token)

        user_id = payload.get("sub")
        if not user_id:
            raise UnauthorizedException("Invalid token: missing subject")

        email = payload.get("email")
        app_metadata = payload.get("app_metadata", {})
        user_metadata = payload.get("user_metadata", {})
        role = app_metadata.get("role", "user")
        is_admin = role == "admin" or user_metadata.get("is_admin", False)

        return UserContext(user_id=user_id, email=email, role=role, is_admin=is_admin)

    except JWTError as e:
        logger.warning(f"JWT verification failed: {str(e)}")
        raise UnauthorizedException("Invalid or expired authentication token")


async def get_current_admin(current_user: UserContext = Depends(get_current_user)) -> UserContext:
    """Ensures caller has admin privileges."""
    if not current_user.is_admin:
        raise ForbiddenException("Administrator privileges required")
    return current_user
