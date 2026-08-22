from typing import List, Dict, Any
from pydantic import BaseModel


class SystemMetrics(BaseModel):
    total_users: int
    total_projects: int
    total_ai_runs: int
    failed_generations_count: int
    total_tokens_consumed: int
    estimated_ai_cost_usd: float


class FailedGenerationLog(BaseModel):
    id: str
    stage: str
    error_detail: str
    project_id: str
    created_at: str
