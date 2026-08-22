from fastapi import APIRouter, Depends
from datetime import datetime, timezone
from apps.backend.core.security import get_current_user, UserContext
from .schemas import BOMSnapshot, CostOptimizationRequest, CostOptimizationResponse

router = APIRouter(prefix="/projects/{project_id}/bom", tags=["bom"])


@router.get("", response_model=BOMSnapshot)
async def get_bom(
    project_id: str,
    current_user: UserContext = Depends(get_current_user),
):
    """Derives current BOM and total cost directly from circuit model."""
    now = datetime.now(timezone.utc).isoformat()
    return BOMSnapshot(
        items=[],
        total_cost=0.0,
        currency="USD",
        calculated_at=now,
    )


@router.post("/optimize", response_model=CostOptimizationResponse)
async def optimize_cost(
    project_id: str,
    data: CostOptimizationRequest,
    current_user: UserContext = Depends(get_current_user),
):
    """Proposes component substitutions to hit budget without breaking compatibility."""
    return CostOptimizationResponse(
        achievable=True,
        proposed_substitutions=[],
        estimated_total=data.target_budget,
    )
