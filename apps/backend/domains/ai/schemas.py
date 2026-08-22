from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


class AIGenerationRequest(BaseModel):
    prompt: str = Field(..., min_length=5, description="Natural language project description")
    target_budget: Optional[float] = None
    preferred_controller: Optional[str] = None


class AIClarificationResponse(BaseModel):
    thread_id: str
    answer: str


class AIModificationRequest(BaseModel):
    command: str = Field(..., min_length=2, description="Natural language modification command")


class AIRunResponse(BaseModel):
    run_id: str
    thread_id: str
    status: str  # "completed" | "clarification_needed" | "in_progress" | "failed"
    clarifying_question: Optional[str] = None
    actions_taken: List[str] = Field(default_factory=list)
    project_id: Optional[str] = None
