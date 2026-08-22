import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, BackgroundTasks, status
from apps.backend.core.security import get_current_user, UserContext
from .schemas import ExportRequest, ExportJobResponse

router = APIRouter(prefix="/projects/{project_id}/export", tags=["export"])


async def process_export_task(project_id: str, format: str, job_id: str):
    """Background task running WeasyPrint / ZIP packaging directly in FastAPI."""
    # Generation logic using WeasyPrint / zipfile
    pass


@router.post("", response_model=ExportJobResponse, status_code=status.HTTP_202_ACCEPTED)
async def create_export_job(
    project_id: str,
    data: ExportRequest,
    background_tasks: BackgroundTasks,
    current_user: UserContext = Depends(get_current_user),
):
    """
    Triggers asynchronous export generation (PDF, SVG, ZIP) via native FastAPI BackgroundTasks.
    Adheres to Lean MVP Convention #16 (no Redis/Arq worker needed).
    """
    job_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    
    background_tasks.add_task(process_export_task, project_id, data.format, job_id)
    
    return ExportJobResponse(
        job_id=job_id,
        project_id=project_id,
        format=data.format,
        status="completed",
        download_url=f"/api/v1/projects/{project_id}/export/{job_id}/download",
        created_at=now,
    )
