from typing import List, Optional, Dict, Any, Literal
from pydantic import BaseModel, Field


class AffectedPin(BaseModel):
    component_id: str
    pin_name: str


class Finding(BaseModel):
    rule_id: str
    message: str
    severity: Literal["critical", "warning", "info"]  # Convention #9
    affected_component_ids: List[str] = Field(default_factory=list)
    affected_pins: List[AffectedPin] = Field(default_factory=list)
    suggestion: Optional[str] = None
    confidence: Optional[str] = "high"


class ValidationResult(BaseModel):
    is_valid: bool
    findings: List[Finding]
    validated_at: str
