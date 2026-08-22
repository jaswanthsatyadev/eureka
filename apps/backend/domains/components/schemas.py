from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field


class ComponentDefinition(BaseModel):
    id: str
    name: str
    category: str
    purpose: str
    structured_pins: List[Dict[str, Any]]
    electrical_characteristics: Dict[str, Any] = Field(default_factory=dict)
    manufacturer: Optional[str] = None
    part_number: Optional[str] = None
    unit_price: float = 0.0
    currency: str = "USD"
    asset_key: Optional[str] = None
    is_available: bool = True
    confidence: str = "high"


class ComponentSearchQuery(BaseModel):
    query: Optional[str] = None
    category: Optional[str] = None
    max_price: Optional[float] = None
