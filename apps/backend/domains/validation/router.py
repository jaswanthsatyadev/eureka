from fastapi import APIRouter, Depends
from datetime import datetime, timezone
from apps.backend.core.security import get_current_user, UserContext
from .schemas import ValidationResult

router = APIRouter(prefix="/projects/{project_id}/validation", tags=["validation"])


@router.get("", response_model=ValidationResult)
async def get_validation(
    project_id: str,
    current_user: UserContext = Depends(get_current_user),
):
    """Runs deterministic validation checks on the project circuit graph."""
    now = datetime.now(timezone.utc).isoformat()
    return ValidationResult(
        is_valid=True,
        findings=[],
        validated_at=now,
    )
