from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from apps.backend.core.security import get_current_user, get_current_admin, UserContext
from .schemas import ComponentDefinition

router = APIRouter(prefix="/components", tags=["components"])


@router.get("", response_model=List[ComponentDefinition])
async def search_components(
    q: Optional[str] = Query(None, description="Search term"),
    category: Optional[str] = Query(None, description="Filter by category"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    """Searches the reusable component catalog."""
    return []


@router.get("/{component_id}", response_model=ComponentDefinition)
async def get_component(component_id: str):
    """Retrieves detailed component definition and pin layout."""
    return ComponentDefinition(
        id=component_id,
        name="ESP32 Development Board",
        category="Microcontrollers",
        purpose="WiFi & Bluetooth enabled microcontroller",
        structured_pins=[],
        unit_price=4.50,
        currency="USD",
    )


@router.post("", response_model=ComponentDefinition, status_code=status.HTTP_201_CREATED)
async def create_component(
    data: ComponentDefinition,
    current_admin: UserContext = Depends(get_current_admin),
):
    """Admin endpoint: Creates a new catalog component."""
    return data
