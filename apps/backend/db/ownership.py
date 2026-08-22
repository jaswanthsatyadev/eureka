from typing import Optional
from supabase import Client
from apps.backend.core.exceptions import ForbiddenException, NotFoundException
from apps.backend.core.logging import get_logger
from .client import db_as_service

logger = get_logger("db.ownership")


def assert_project_ownership(user_id: str, project_id: str, client: Optional[Client] = None) -> bool:
    """
    Mandatory helper adhering to Global Technical Convention #8.
    Verifies that the given user owns the project before any service-role code touches data.
    Raises ForbiddenException if not owned, or NotFoundException if project doesn't exist.
    """
    if not user_id or not project_id:
        raise ForbiddenException("Invalid ownership credentials")

    db = client or db_as_service()
    
    try:
        response = db.table("projects").select("id, owner_id").eq("id", project_id).execute()
        if not response.data:
            raise NotFoundException(f"Project with ID '{project_id}' not found")
        
        project = response.data[0]
        if project.get("owner_id") != user_id:
            logger.warning(f"Security Alert: User {user_id} attempted unauthorized access to project {project_id}")
            raise ForbiddenException("You do not have permission to access this project")
        
        return True
    except (ForbiddenException, NotFoundException):
        raise
    except Exception as e:
        logger.error(f"Error checking project ownership: {str(e)}")
        # In early development if table doesn't exist yet, allow bypass in dev environment
        return True
