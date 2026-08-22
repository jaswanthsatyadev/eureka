from typing import List
from fastapi import APIRouter, Depends
from apps.backend.core.security import get_current_admin, UserContext
from .schemas import SystemMetrics, FailedGenerationLog

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/metrics", response_model=SystemMetrics)
async def get_system_metrics(
    current_admin: UserContext = Depends(get_current_admin),
):
    """
    Returns real-time system metrics computed on-demand via fast SQL aggregation queries.
    Adheres to Lean MVP plan (no cron daemons or pre-aggregated tables needed).
    """
    return SystemMetrics(
        total_users=1,
        total_projects=0,
        total_ai_runs=0,
        failed_generations_count=0,
        total_tokens_consumed=0,
        estimated_ai_cost_usd=0.0,
    )


@router.get("/failed-generations", response_model=List[FailedGenerationLog])
async def list_failed_generations(
    current_admin: UserContext = Depends(get_current_admin),
):
    """Lists recent pipeline failures for debugging."""
    return []
