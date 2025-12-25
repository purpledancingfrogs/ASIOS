import json
import sys
from datetime import datetime

ALLOWED_TYPES = {"LAPTOP_FS"}
REQUIRED_FIELDS = {
    "mission_id",
    "schema_version",
    "created_at",
    "env",
    "created_by_agent",
    "type",
    "payload"
}

def validate_mission(mission):
    # Check required top-level fields
    for field in REQUIRED_FIELDS:
        if field not in mission:
            raise ValueError(f"Missing required field: {field}")

    # Check mission type
    if mission["type"] not in ALLOWED_TYPES:
        raise ValueError(f"Unsupported mission type: {mission['type']}")

    # Validate datetime format
    try:
        datetime.fromisoformat(mission["created_at"].replace("Z", "+00:00"))
    except Exception as e:
        raise ValueError(f"Invalid created_at timestamp: {e}")

    # Check payload steps
    if "steps" not in mission["payload"] or not isinstance(mission["payload"]["steps"], list):
        raise ValueError("Payload must contain a list of steps")

    for i, step in enumerate(mission["payload"]["steps"]):
        if "op" not in step or "path" not in step:
            raise ValueError(f"Step {i} missing 'op' or 'path'")
        if step["op"] not in {"CREATE_FILE", "REPLACE_FILE", "INSERT_AFTER_MARKER", "DELETE_FILE", "RUN_SCRIPT"}:
            raise ValueError(f"Step {i} has invalid op: {step['op']}")

    return True

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python validate_mission.py <mission_file.json>")
        sys.exit(1)

    with open(sys.argv[1], "r") as f:
        mission_data = json.load(f)

    try:
        validate_mission(mission_data)
        print("Mission file is valid ✅")
    except Exception as e:
        print(f"Validation error ❌: {e}")
        sys.exit(1)
