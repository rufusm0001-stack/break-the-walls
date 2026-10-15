"""Upload Meshy models to Roblox through Open Cloud (Assets API) as Model assets.

Usage: python roblox_upload.py name ...   (reads art/models/<name>/<name>.glb, falls back to .fbx)
Writes the resulting asset id into art/models/<name>/task.json under "robloxAssetId".
"""
import json
import sys
import time
from pathlib import Path

import requests

KEY_FILE = Path(r"C:\Users\rmcd9\Desktop\IdleMedievalArt\api.txt")
ART = Path(__file__).parent
CREATOR_USER_ID = "903739180"
API = "https://apis.roblox.com/assets/v1"
CONTENT_TYPES = {".glb": "model/gltf-binary", ".fbx": "model/fbx"}


def roblox_key() -> str:
    # Prefer the key made for this game; fall back to the older general one.
    lines = KEY_FILE.read_text(encoding="utf-8").splitlines()
    for prefix in ("roblox cooal mining game", "roblox coal mining game", "rolbox", "roblox"):
        for line in lines:
            if line.lower().startswith(prefix):
                return line.split("-", 1)[1].strip()
    sys.exit("no roblox key found")


def upload(key: str, name: str) -> str:
    folder = ART / "models" / name
    for ext in (".fbx", ".glb"):
        path = folder / f"{name}{ext}"
        if not path.exists():
            continue
        request = {
            "assetType": "Model",
            "displayName": f"FTD_{name}",
            "description": "Find The Diamond In The Coal - stud-style model",
            "creationContext": {"creator": {"userId": CREATOR_USER_ID}},
        }
        r = requests.post(
            f"{API}/assets",
            headers={"x-api-key": key},
            files={
                "request": (None, json.dumps(request), "application/json"),
                "fileContent": (path.name, path.read_bytes(), CONTENT_TYPES[ext]),
            },
            timeout=300,
        )
        if r.status_code != 200:
            print(f"{name}{ext}: HTTP {r.status_code} {r.text[:300]}", flush=True)
            continue
        operation = r.json()
        op_path = operation.get("path") or f"operations/{operation['operationId']}"
        for _ in range(60):
            op = requests.get(f"{API}/{op_path}", headers={"x-api-key": key}, timeout=60).json()
            if op.get("done"):
                if "response" in op:
                    return op["response"]["assetId"]
                raise RuntimeError(f"{name}: {op.get('error')}")
            time.sleep(3)
        raise RuntimeError(f"{name}: upload operation timed out")
    raise RuntimeError(f"{name}: no file could be uploaded")


def main() -> None:
    key = roblox_key()
    for name in sys.argv[1:]:
        try:
            asset_id = upload(key, name)
            meta_path = ART / "models" / name / "task.json"
            meta = json.loads(meta_path.read_text()) if meta_path.exists() else {}
            meta["robloxAssetId"] = asset_id
            meta_path.write_text(json.dumps(meta, indent=2))
            print("uploaded", name, "->", asset_id, flush=True)
        except Exception as exc:
            print("FAILED", exc, flush=True)


if __name__ == "__main__":
    main()
