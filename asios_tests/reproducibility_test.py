import hashlib, pathlib, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
EVID = ROOT / 'evidence'
VERIFY = EVID / 'VERIFY_HASHES.sha256'

def sha_lines(paths):
    out=[]
    for p in sorted(paths):
        h=hashlib.sha256(p.read_bytes()).hexdigest()
        out.append(f"{h}  {p}")
    return out

def main():
    # recompute excluding verification artifacts
    files=[p for p in EVID.rglob('*') if p.is_file() and p.name not in ('VERIFY_HASHES.sha256','LOCAL_RECALC.sha256')]
    recomputed=sha_lines(files)
    expected=VERIFY.read_text().splitlines()
    if recomputed!=expected:
        print('HASH MISMATCH')
        sys.exit(1)
    print('OK: hashes match')

if __name__=='__main__':
    main()
