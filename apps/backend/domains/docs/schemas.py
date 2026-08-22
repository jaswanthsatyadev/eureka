from typing import List, Dict, Any, Optional
from pydantic import BaseModel


class ProjectDocumentation(BaseModel):
    title: str
    working_principle: str
    wiring_steps: List[str]
    assembly_instructions: List[str]
    testing_steps: List[str]
    troubleshooting: List[Dict[str, str]]
    flowchart: Dict[str, Any]
    generated_at: str
