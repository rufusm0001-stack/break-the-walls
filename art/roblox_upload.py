"""Upload models to Roblox through Open Cloud (Assets API) as Model assets, owned by Rufus (user 903739180).

Usage: python roblox_upload.py path/to/model.glb ...     (or a Name, meaning art/models/<Name>/<Name>.glb|.fbx)
Prints "uploaded <name> -> <assetId>" and appends the ids to art/models/uploaded.json. Then insert the asset in
Studio with the MCP insert_asset (or InsertService:LoadAsset in Edit) and move it into ServerStorage.ToolModels.
The key line is chosen by trying asset read on each Roblox key in api.txt; keys are never printed.
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
PROBE_ASSET = "126732731360060"  # the stud tile this game already uploaded


def roblox_key() -> str:
    for line in KEY_FILE.read_text(encoding="utf-8").splitlines():
        low = line.strip().lower()
        if not low.startswith(("roblox", "rolbox")):
            continue
        key = line.split(" - ", 1)[1].strip() if " - " in line else line.split("-", 1)[1].strip()
        r = requests.get(f"{API}/assets/{PROBE_ASSET}", headers={"x-api-key": key}, timeout=30)
        if r.ok:
            return key
    sys.exit("no Roblox key with Assets read access found in api.txt")


def resolve(arg: str) -> Path:
    p = Path(arg)
    if p.suffix:
        return p
    for ext in (".glb", ".fbx"):
        q = ART / "models" / arg / f"{arg}{ext}"
        if q.exists():
            return q
    raise FileNotFoundError(arg)


def upload(key: str, path: Path) -> str:
    request = {
        "assetType": "Model",
        "displayName": f"BTW_{path.stem}",
        "description": "Break The Walls tool model",
        "creationContext": {"creator": {"userId": CREATOR_USER_ID}},
    }
    r = requests.post(
        f"{API}/assets",
        headers={"x-api-key": key},
        files={
            "request": (None, json.dumps(request), "application/json"),
            "fileContent": (path.name, path.read_bytes(), CONTENT_TYPES[path.suffix.lower()]),
        },
        timeout=300,
    )
    if r.status_code != 200:
        raise RuntimeError(f"{path.name}: HTTP {r.status_code} {r.text[:300]}")
    op = r.json()
    op_path = op.get("path") or f"operations/{op['operationId']}"
    for _ in range(100):
        o = requests.get(f"{API}/{op_path}", headers={"x-api-key": key}, timeout=60).json()
        if o.get("done"):
            if "response" in o:
                return o["response"]["assetId"]
            raise RuntimeError(f"{path.name}: {o.get('error')}")
        time.sleep(3)
    raise RuntimeError(f"{path.name}: upload operation timed out")


def main() -> None:
    key = roblox_key()
    log_path = ART / "models" / "uploaded.json"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    log = json.loads(log_path.read_text()) if log_path.exists() else {}
    for arg in sys.argv[1:]:
        try:
            path = resolve(arg)
            asset_id = upload(key, path)
            log[path.stem] = asset_id
            log_path.write_text(json.dumps(log, indent=2))
            print("uploaded", path.stem, "->", asset_id, flush=True)
        except Exception as exc:
            print("FAILED", exc, flush=True)


if __name__ == "__main__":
    main()
