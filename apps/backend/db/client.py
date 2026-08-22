from typing import Optional
from supabase import create_client, Client
from apps.backend.core.config import settings
from apps.backend.core.logging import get_logger

logger = get_logger("db.client")

_service_client: Optional[Client] = None


def get_service_client() -> Client:
    """Returns singleton Supabase client with service-role permissions (bypasses RLS)."""
    global _service_client
    if _service_client is None:
        if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
            logger.warning("Supabase service credentials not configured. DB queries will fail until credentials are provided.")
            # Create a dummy client or placeholder
            return create_client("https://placeholder.supabase.co", "placeholder-key")
        _service_client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_ROLE_KEY
        )
    return _service_client


def db_as_service() -> Client:
    """
    Returns Supabase client with SERVICE-ROLE bypass permissions.
    WARNING: Every code path using this MUST call `assert_project_ownership(user_id, project_id)` first!
    """
    return get_service_client()


def db_as_user(jwt_token: Optional[str] = None) -> Client:
    """
    Returns Supabase client scoped to the authenticated user (honoring Postgres RLS).
    """
    if not settings.SUPABASE_URL or not settings.SUPABASE_ANON_KEY:
        return create_client("https://placeholder.supabase.co", "placeholder-key")
    
    client = create_client(settings.SUPABASE_URL, settings.SUPABASE_ANON_KEY)
    if jwt_token:
        client.postgrest.auth(jwt_token)
    return client
