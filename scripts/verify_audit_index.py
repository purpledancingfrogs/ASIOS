import hashlib, os, sys

def sha256_file(p: str) -> str:
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def parse_audit_index(path: str):
    items = []
    cur_path = None
    for line in open(path, "r", encoding="utf-8", errors="replace"):
        s = line.strip()
        if s.startswith("- path:"):
            cur_path = s.split(":",1)[1].strip().strip('"').strip("'")
        elif s.startswith("path:") and cur_path is None:
            cur_path = s.split(":",1)[1].strip().strip('"').strip("'")
        elif s.startswith("sha256:") and cur_path:
            h = s.split(":",1)[1].strip().lower()
            items.append((cur_path, h))
            cur_path = None
    return items

def main():
    idx = ".asios/audit_index.yaml"
    if not os.path.exists(idx):
        print(f"Missing {idx}")
        return 1
    items = parse_audit_index(idx)
    if not items:
        print("No artifacts parsed from audit_index.yaml")
        return 1
    bad = 0
    for rel, exp in items:
        p = rel.replace("\\","/")
        if not os.path.exists(p):
            print(f"FAIL missing: {rel}")
            bad += 1
            continue
        got = sha256_file(p)
        if got != exp:
            print(f"FAIL hash: {rel}\n  expected {exp}\n  got      {got}")
            bad += 1
        else:
            print(f"OK   {rel}")
    return 0 if bad == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
