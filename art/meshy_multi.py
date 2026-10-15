"""Meshy multi-image-to-3D for the tool reference packs (Desktop/Break The Walls/meshy/<Name>/view_*.png).

Usage: python meshy_multi.py Name[:polycount] ...     e.g. python meshy_multi.py Vacuum_Basic Vacuum_Vortex:10000
Sends up to 4 views per model, downloads GLB + FBX + thumbnail to art/models/<Name>/ and logs credits to
art/LEDGER.md. About 30 credits per model. The key is read from outside the repo and never printed.
"""
import base64
import io
import json
import sys
import time
from datetime import date
from pathlib import Path

import requests
from PIL import Image

KEY_FILE = Path(r"C:\Users\rmcd9\Desktop\IdleMedievalArt\api.txt")
ART = Path(__file__).parent
PACKS = Path.home() / "Desktop" / "Break The Walls" / "meshy"
API = "https://api.meshy.ai/openapi/v1"
VIEW_ORDER = ("view_three_quarter", "view_left", "view_front", "view_right", "view_side", "view_top")


def meshy_key() -> str:
    for line in KEY_FILE.read_text(encoding="utf-8").splitlines():
        if line.lower().startswith("meshy"):
            return line.split("-", 1)[1].strip()
    sys.exit("no meshy key found")


def h(key):
    return {"Authorization": f"Bearer {key}"}


def data_uri(path: Path) -> str:
    im = Image.open(path).convert("RGB")
    im.thumbnail((1024, 1024))
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=92)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()


def submit(key, name, poly):
    views = [PACKS / name / f"{v}.png" for v in VIEW_ORDER if (PACKS / name / f"{v}.png").exists()][:4]
    body = {
        "image_urls": [data_uri(p) for p in views],
        "ai_model": "latest",
        "should_remesh": True,
        "topology": "triangle",
        "target_polycount": poly,
        "should_texture": True,
        "enable_pbr": False,
        "texture_resolution": "2k",
        "target_formats": ["glb", "fbx"],
    }
    r = requests.post(f"{API}/multi-image-to-3d", headers=h(key), json=body, timeout=180)
    if r.status_code not in (200, 202):
        raise RuntimeError(f"{name}: HTTP {r.status_code} {r.text[:300]}")
    return r.json()["result"], [p.name for p in views]


def wait(key, task_id):
    while True:
        t = requests.get(f"{API}/multi-image-to-3d/{task_id}", headers=h(key), timeout=60).json()
        if t["status"] in ("SUCCEEDED", "FAILED", "CANCELED"):
            return t
        time.sleep(15)


def main():
    key = meshy_key()
    jobs = []
    for arg in sys.argv[1:]:
        name, _, poly = arg.partition(":")
        jobs.append((name, int(poly or 8000)))
    start = requests.get(f"{API}/balance", headers=h(key), timeout=30).json()["balance"]
    print("balance before:", start, flush=True)
    subs = []
    for name, poly in jobs:
        try:
            tid, views = submit(key, name, poly)
            subs.append((name, poly, tid))
            print("submitted", name, "with", ", ".join(views), flush=True)
        except Exception as exc:
            print("FAILED", exc, flush=True)
    for name, poly, tid in subs:
        t = wait(key, tid)
        if t["status"] != "SUCCEEDED":
            print("FAILED", name, t["status"], t.get("task_error"), flush=True)
            continue
        out = ART / "models" / name
        out.mkdir(parents=True, exist_ok=True)
        for fmt in ("glb", "fbx"):
            url = t.get("model_urls", {}).get(fmt)
            if url:
                (out / f"{name}.{fmt}").write_bytes(requests.get(url, timeout=300).content)
        if t.get("thumbnail_url"):
            (out / "thumbnail.png").write_bytes(requests.get(t["thumbnail_url"], timeout=120).content)
        (out / "task.json").write_text(json.dumps({"id": tid, "polycount": poly, "kind": "multi-image-to-3d"}, indent=2))
        print("done", name, "credits", t.get("consumed_credits"), flush=True)
    end = requests.get(f"{API}/balance", headers=h(key), timeout=30).json()["balance"]
    print("balance after:", end, "spent:", start - end, flush=True)
    with open(ART / "LEDGER.md", "a", encoding="utf-8") as f:
        f.write(f"| {date.today()} | Meshy multi-image-to-3D: {', '.join(n for n, _, _ in subs)} | Meshy | "
                f"{start - end} credits |\n")


if __name__ == "__main__":
    main()
