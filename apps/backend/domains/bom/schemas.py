from typing import List
from pydantic import BaseModel, Field


class BOMItem(BaseModel):
    catalog_id: str
    name: str
    category: str
    designators: List[str]
    quantity: int
    unit_price: float
    total_price: float
    currency: str = "USD"
    has_alternatives: bool = False


class BOMSnapshot(BaseModel):
    items: List[BOMItem]
    total_cost: float
    currency: str = "USD"
    calculated_at: str


class CostOptimizationRequest(BaseModel):
    target_budget: float
    currency: str = "USD"


class CostOptimizationResponse(BaseModel):
    achievable: bool
    proposed_substitutions: List[dict]
    estimated_total: float
