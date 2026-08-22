from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from apps.backend.core.security import get_current_user, UserContext
from apps.backend.core.exceptions import NotFoundException
from .schemas import ProjectCreate, ProjectUpdate, ProjectSummary, ProjectDetail

router = APIRouter(prefix="/projects", tags=["projects"])


@router.post("", response_model=ProjectSummary, status_code=status.HTTP_201_CREATED)
async def create_project(
    data: ProjectCreate,
    current_user: UserContext = Depends(get_current_user),
):
    """Creates a new electronics project."""
    # Stub implementation returning a scaffolded project
    import uuid
    from datetime import datetime, timezone
    now = datetime.now(timezone.utc).isoformat()
    project_id = str(uuid.uuid4())
    return ProjectSummary(
        id=project_id,
        owner_id=current_user.user_id,
        title=data.title,
        category=data.category or "General",
        status="draft",
        is_favorite=False,
        current_version_id=None,
        created_at=now,
        updated_at=now,
    )


@router.get("", response_model=List[ProjectSummary])
async def list_projects(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    category: Optional[str] = None,
    search: Optional[str] = None,
    favorite_only: bool = False,
    current_user: UserContext = Depends(get_current_user),
):
    """Lists projects owned by the authenticated user with limit/offset pagination."""
    return []


@router.get("/{project_id}", response_model=ProjectDetail)
async def get_project(
    project_id: str,
    current_user: UserContext = Depends(get_current_user),
):
    """Loads a project and its current active circuit graph snapshot."""
    from datetime import datetime, timezone
    now = datetime.now(timezone.utc).isoformat()
    return ProjectDetail(
        id=project_id,
        owner_id=current_user.user_id,
        title="Sample Project",
        category="IoT",
        status="active",
        is_favorite=False,
        current_version_id="1",
        created_at=now,
        updated_at=now,
        circuit={
            "schema_version": "1.0.0",
            "components": [],
            "wires": [],
            "nets": [],
            "requirements": {
                "summary": "Sample requirement",
                "inputs": [],
                "outputs": [],
                "connectivity": []
            },
            "metadata": {}
        }
    )


@router.patch("/{project_id}", response_model=ProjectSummary)
async def update_project(
    project_id: str,
    data: ProjectUpdate,
    current_user: UserContext = Depends(get_current_user),
):
    """Updates project metadata (rename, category, favorite)."""
    from datetime import datetime, timezone
    now = datetime.now(timezone.utc).isoformat()
    return ProjectSummary(
        id=project_id,
        owner_id=current_user.user_id,
        title=data.title or "Updated Project",
        category=data.category or "General",
        status=data.status or "active",
        is_favorite=data.is_favorite if data.is_favorite is not None else False,
        current_version_id="1",
        created_at=now,
        updated_at=now,
    )


@router.delete("/{project_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_project(
    project_id: str,
    current_user: UserContext = Depends(get_current_user),
):
    """Soft-deletes a project."""
    return None
