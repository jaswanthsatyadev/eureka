from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel, Field


class ProjectCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=120)
    category: Optional[str] = "General"
    description: Optional[str] = None


class ProjectUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=120)
    category: Optional[str] = None
    is_favorite: Optional[bool] = None
    status: Optional[str] = None


class ProjectSummary(BaseModel):
    id: str
    owner_id: str
    title: str
    category: str
    status: str
    is_favorite: bool
    current_version_id: Optional[str] = None
    created_at: str
    updated_at: str


class ProjectDetail(ProjectSummary):
    circuit: Dict[str, Any]
    validation_summary: Optional[Dict[str, Any]] = None
    bom_summary: Optional[Dict[str, Any]] = None
