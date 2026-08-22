from typing import Optional, Literal
from pydantic import BaseModel


class ExportRequest(BaseModel):
    format: Literal["pdf", "png", "svg", "json", "zip"] = "pdf"


class ExportJobResponse(BaseModel):
    job_id: str
    project_id: str
    format: str
    status: str  # "completed" | "processing" | "failed"
    download_url: Optional[str] = None
    created_at: str
