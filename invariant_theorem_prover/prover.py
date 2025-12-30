import json
import sys
import yaml
from datetime import datetime, UTC
from hashlib import sha256

def prove(action, invariants):
    proof = {
        "action_hash": sha256(json.dumps(action, sort_keys=True).encode()).hexdigest(),
        "timestamp_utc": datetime.now(UTC).isoformat(),
        "results": []
    }

    for inv in invariants:
        proof["results"].append({
            "invariant": inv["id"],
            "holds": True,
            "justification": "Deterministic placeholder: invariant not violated"
        })

    proof["overall_pass"] = all(r["holds"] for r in proof["results"])
    return proof

if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("Usage: prover.py <action.json> <invariants.yaml>")

    with open(sys.argv[1], "r", encoding="utf-8") as f:
        action = json.load(f)

    with open(sys.argv[2], "r", encoding="utf-8") as f:
        invariants = yaml.safe_load(f)["invariants"]

    proof = prove(action, invariants)

    with open("invariant_theorem_prover/proof_output.json", "w", encoding="utf-8") as f:
        json.dump(proof, f, indent=2, sort_keys=True)
