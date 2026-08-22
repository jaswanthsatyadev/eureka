from typing import Dict, Any
from fastapi import APIRouter, Depends, status
from apps.backend.core.security import get_current_user, UserContext
from .schemas import (
    CircuitMutation,
    AddComponentPayload,
    RemoveComponentPayload,
    MoveComponentPayload,
    RotateComponentPayload,
    ConnectPinsPayload,
    DisconnectPinsPayload,
    UpdatePropertyPayload,
)
from .service import apply_mutation

router = APIRouter(prefix="/projects/{project_id}/circuit", tags=["circuit"])


@router.post("/mutations")
async def post_mutation(
    project_id: str,
    mutation: CircuitMutation,
    current_user: UserContext = Depends(get_current_user),
):
    """Direct mutation entrypoint."""
    return await apply_mutation(project_id, mutation, current_user.to_actor())


@router.post("/components")
async def add_component(
    project_id: str,
    payload: AddComponentPayload,
    current_user: UserContext = Depends(get_current_user),
):
    """Granular REST endpoint: Adds a component instance to the circuit."""
    mutation = CircuitMutation(type="add_component", payload=payload.model_dump())
    return await apply_mutation(project_id, mutation, current_user.to_actor())


@router.delete("/components/{component_id}")
async def remove_component(
    project_id: str,
    component_id: str,
    current_user: UserContext = Depends(get_current_user),
):
    """Granular REST endpoint: Removes a component instance."""
    mutation = CircuitMutation(
        type="remove_component", payload={"component_id": component_id}
    )
    return await apply_mutation(project_id, mutation, current_user.to_actor())


@router.post("/wires")
async def connect_pins(
    project_id: str,
    payload: ConnectPinsPayload,
    current_user: UserContext = Depends(get_current_user),
):
    """Granular REST endpoint: Connects two pins with a wire."""
    mutation = CircuitMutation(type="connect_pins", payload=payload.model_dump())
    return await apply_mutation(project_id, mutation, current_user.to_actor())


@router.delete("/wires/{wire_id}")
async def disconnect_pins(
    project_id: str,
    wire_id: str,
    current_user: UserContext = Depends(get_current_user),
):
    """Granular REST endpoint: Removes a wire."""
    mutation = CircuitMutation(
        type="disconnect_pins", payload={"wire_id": wire_id}
    )
    return await apply_mutation(project_id, mutation, current_user.to_actor())
