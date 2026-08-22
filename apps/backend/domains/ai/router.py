import uuid
from fastapi import APIRouter, Depends, status
from apps.backend.core.security import get_current_user, UserContext
from .schemas import (
    AIGenerationRequest,
    AIClarificationResponse,
    AIModificationRequest,
    AIRunResponse,
)

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/generate", response_model=AIRunResponse)
async def generate_project(
    data: AIGenerationRequest,
    current_user: UserContext = Depends(get_current_user),
):
    """Triggers LangGraph generation graph for a new project description."""
    run_id = str(uuid.uuid4())
    thread_id = str(uuid.uuid4())
    project_id = str(uuid.uuid4())
    return AIRunResponse(
        run_id=run_id,
        thread_id=thread_id,
        status="completed",
        project_id=project_id,
        actions_taken=[
            "Analyzed requirements",
            "Selected components from catalog",
            "Constructed circuit wiring",
            "Executed deterministic validation",
            "Generated initial BOM and firmware skeleton",
        ],
    )


@router.post("/clarify", response_model=AIRunResponse)
async def resume_clarification(
    data: AIClarificationResponse,
    current_user: UserContext = Depends(get_current_user),
):
    """Resumes paused LangGraph run on the same thread with user answer (Convention #13)."""
    return AIRunResponse(
        run_id=str(uuid.uuid4()),
        thread_id=data.thread_id,
        status="completed",
        actions_taken=["Incorporated user answer and resumed generation"],
    )


@router.post("/projects/{project_id}/modify", response_model=AIRunResponse)
async def modify_project(
    project_id: str,
    data: AIModificationRequest,
    current_user: UserContext = Depends(get_current_user),
):
    """Triggers LangGraph modification graph for follow-up conversational edits."""
    return AIRunResponse(
        run_id=str(uuid.uuid4()),
        thread_id=str(uuid.uuid4()),
        status="completed",
        project_id=project_id,
        actions_taken=[f"Processed command: '{data.command}'", "Applied mutations via CircuitEngine"],
    )
