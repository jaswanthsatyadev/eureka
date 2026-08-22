from typing import List, Optional
from pydantic import BaseModel


class GeneratedCode(BaseModel):
    platform: str  # "arduino" | "esp32"
    source_code: str
    required_libraries: List[str]
    is_stale: bool = False
    generated_at: str
