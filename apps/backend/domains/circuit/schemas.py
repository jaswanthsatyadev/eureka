from typing import Dict, List, Optional, Any, Literal, Union
from pydantic import BaseModel, Field


class PinPosition(BaseModel):
    x: float
    y: float


class PinDefinition(BaseModel):
    name: str
    role: str
    position: PinPosition
    voltage_range: Optional[Dict[str, float]] = None
    max_current_ma: Optional[float] = None
    description: Optional[str] = None


class ComponentInstance(BaseModel):
    id: str
    catalog_id: str
    name: str
    category: str
    designator: str
    position: Dict[str, float]
    rotation: int = 0
    properties: Dict[str, Any] = Field(default_factory=dict)
    pins: Dict[str, PinDefinition] = Field(default_factory=dict)
    asset_url: Optional[str] = None
    view_box: Optional[Dict[str, float]] = None
    unit_price: float = 0.0
    currency: str = "USD"


class WireEndpoint(BaseModel):
    component_id: str
    pin_name: str


class Wire(BaseModel):
    id: str
    source: WireEndpoint
    target: WireEndpoint
    net_id: Optional[str] = None
    color: Optional[str] = None


class Net(BaseModel):
    id: str
    name: str
    net_type: str
    endpoints: List[WireEndpoint]


class CircuitGraph(BaseModel):
    schema_version: str = "1.0.0"
    components: List[ComponentInstance] = Field(default_factory=list)
    wires: List[Wire] = Field(default_factory=list)
    nets: List[Net] = Field(default_factory=list)
    requirements: Dict[str, Any] = Field(default_factory=dict)
    metadata: Dict[str, Any] = Field(default_factory=dict)


# Mutation Payloads (Convention #6)
class AddComponentPayload(BaseModel):
    component: ComponentInstance


class RemoveComponentPayload(BaseModel):
    component_id: str


class ReplaceComponentPayload(BaseModel):
    old_component_id: str
    new_component: ComponentInstance
    preserve_wiring: bool = True


class MoveComponentPayload(BaseModel):
    component_id: str
    position: Dict[str, float]


class RotateComponentPayload(BaseModel):
    component_id: str
    rotation: int


class ConnectPinsPayload(BaseModel):
    wire: Wire


class DisconnectPinsPayload(BaseModel):
    wire_id: str


class UpdatePropertyPayload(BaseModel):
    component_id: str
    key: str
    value: Any


class CircuitMutation(BaseModel):
    type: Literal[
        "add_component",
        "remove_component",
        "replace_component",
        "move_component",
        "rotate_component",
        "connect_pins",
        "disconnect_pins",
        "update_property",
    ]
    payload: Dict[str, Any]
