"""Meshy image-to-3D for the reference images in art/refs. Keys are read from outside the repo.

Usage: python meshy.py name[:polycount] ...    e.g. python meshy.py pickaxe_starter:2000 coal_node:2500
Downloads GLB, FBX and the thumbnail to art/models/<name>/ and logs credits to art/LEDGER.md.
"""
import base64
import json
import sys
import time
from datetime import date
from pathlib import Path

import requests

KEY_FILE = Path(r"C:\Users\rmcd9\Desktop\IdleMedievalArt\api.txt")
ART = Path(__file__).parent
API = "https://api.meshy.ai/openapi/v1"


def meshy_key() -> str:
    for line in KEY_FILE.read_text(encoding="utf-8").splitlines():
        if line.lower().startswith("meshy"):
            return line.split("-", 1)[1].strip()
    sys.exit("no meshy key found")


def headers(key: str) -> dict:
    return {"Authorization": f"Bearer {key}"}


def balance(key: str) -> int:
    return requests.get(f"{API}/balance", headers=headers(key), timeout=30).json()["balance"]


def submit(key: str, name: str, polycount: int) -> str:
    image = base64.b64encode((ART / "refs" / f"{name}.png").read_bytes()).decode()
    body = {
        "image_url": f"data:image/png;base64,{image}",
        "ai_model": "latest",
        "topology": "triangle",
        "target_polycount": polycount,
        "should_remesh": True,
        "should_texture": True,
        "enable_pbr": False,
        "symmetry_mode": "auto",
    }
    r = requests.post(f"{API}/image-to-3d", headers=headers(key), json=body, timeout=120)
    if r.status_code not in (200, 202):
        raise RuntimeError(f"{name}: HTTP {r.status_code} {r.text[:300]}")
    return r.json()["result"]


def wait(key: str, task_id: str) -> dict:
    while True:
        task = requests.get(f"{API}/image-to-3d/{task_id}", headers=headers(key), timeout=60).json()
        if task["status"] in ("SUCCEEDED", "FAILED", "CANCELED"):
            return task
        time.sleep(10)


def download(url: str, path: Path) -> None:
    path.write_bytes(requests.get(url, timeout=300).content)


def main() -> None:
    key = meshy_key()
    jobs = []
    for arg in sys.argv[1:]:
        name, _, poly = arg.partition(":")
        jobs.append((name, int(poly or 3000)))
    start = balance(key)
    print("balance before:", start, flush=True)

    submitted = []
    for name, poly in jobs:
        try:
            submitted.append((name, poly, submit(key, name, poly)))
            print("submitted", name, flush=True)
        except Exception as exc:
            print("FAILED", exc, flush=True)

    for name, poly, task_id in submitted:
        task = wait(key, task_id)
        if task["status"] != "SUCCEEDED":
            print("FAILED", name, task["status"], task.get("task_error"), flush=True)
            continue
        out = ART / "models" / name
        out.mkdir(parents=True, exist_ok=True)
        urls = task["model_urls"]
        for fmt in ("glb", "fbx"):
            if urls.get(fmt):
                download(urls[fmt], out / f"{name}.{fmt}")
        if task.get("thumbnail_url"):
            download(task["thumbnail_url"], out / "thumbnail.png")
        (out / "task.json").write_text(json.dumps({"id": task_id, "polycount": poly}, indent=2))
        print("done", name, "->", out, flush=True)

    end = balance(key)
    spent = start - end
    print("balance after:", end, "spent:", spent, flush=True)
    with open(ART / "LEDGER.md", "a", encoding="utf-8") as ledger:
        ledger.write(f"| {date.today()} | Meshy image-to-3D | {', '.join(n for n, _, _ in submitted)} | {spent} credits |\n")


if __name__ == "__main__":
    main()
