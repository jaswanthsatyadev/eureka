from fastapi import APIRouter, Depends
from datetime import datetime, timezone
from apps.backend.core.security import get_current_user, UserContext
from .schemas import ProjectDocumentation

router = APIRouter(prefix="/projects/{project_id}/docs", tags=["docs"])


@router.get("", response_model=ProjectDocumentation)
async def get_docs(
    project_id: str,
    current_user: UserContext = Depends(get_current_user),
):
    """Retrieves full generated documentation package including wiring steps and flowchart."""
    now = datetime.now(timezone.utc).isoformat()
    return ProjectDocumentation(
        title="Project Documentation",
        working_principle="The microcontroller reads input sensor data, processes thresholds, and controls output actuators.",
        wiring_steps=["1. Connect GND rail", "2. Connect 5V/3.3V power", "3. Wire data pins to GPIO"],
        assembly_instructions=["Mount components on breadboard or prototype board"],
        testing_steps=["Verify power lines with multimeter before turning on"],
        troubleshooting=[{"symptom": "LED does not turn on", "solution": "Check polarity and resistor"}],
        flowchart={"nodes": [], "edges": []},
        generated_at=now,
    )
