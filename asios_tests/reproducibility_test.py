import hashlib, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
EVID = ROOT / 'evidence'
VERIFY = EVID / 'VERIFY_HASHES.sha256'
EXCLUDE = {'VERIFY_HASHES.sha256','LOCAL_RECALC.sha256'}

def sha256(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def rel(p):
    return p.resolve().relative_to(ROOT).as_posix()

def main():
    files = sorted(
        [p for p in EVID.rglob('*') if p.is_file() and p.name not in EXCLUDE],
        key=lambda p: rel(p)
    )
    recomputed = [f"{sha256(p)}  {rel(p)}" for p in files]
    expected = VERIFY.read_text().splitlines()

    if recomputed != expected:
        print("HASH MISMATCH")
        # emit diff context for auditors
        for a,b in zip(recomputed, expected):
            if a != b:
                print("EXPECTED:", b)
                print("GOT     :", a)
                break
        sys.exit(1)

    print("OK: hashes match")

if __name__ == "__main__":
    main()
