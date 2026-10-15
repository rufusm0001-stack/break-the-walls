"""Break The Walls UI icons via Gemini (gemini-2.5-flash-image, about $0.039 each).

Usage: python gen_icons.py [name ...]      (no names = every icon not generated yet)
       python gen_icons.py --cut           (only re-run the background cut on existing raw images)
Raw images go to Desktop/Break The Walls/icons/raw, cut-out 256px PNGs to icons/cut and art/icons in the repo.
Gemini can't draw transparency, so it paints on flat magenta and cut() flood-fills that away from the edges;
the thick dark outline stops the fill at the silhouette. The key is read from outside the repo (gen_refs.read_key).
"""
import base64
import sys
from collections import deque
from pathlib import Path

import numpy as np
import requests
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from gen_refs import read_key  # noqa: E402

DESK = Path.home() / "Desktop" / "Break The Walls" / "icons"
RAW, CUT = DESK / "raw", DESK / "cut"
REPO_ICONS = Path(__file__).parent / "icons"

STYLE = (
    "Style: one game UI icon for a bright, cheerful Roblox block game: a chunky glossy cartoon 3D render with simple "
    "blocky shapes, smooth plastic, saturated colours, a thick even dark navy (#1E1A2E) outline around the whole "
    "silhouette, soft light from the top left. Centred with a generous empty margin on every side. The background is "
    "one perfectly flat solid magenta (#FF00FF) colour with no gradient, no shadow, no floor, no glow. "
    "No pink, rose, salmon or magenta anywhere on the object itself. No text, no letters, no numbers, no frame, "
    "no circle or badge behind it."
)

FIST = (
    "a chunky blocky Roblox avatar fist seen from the front three-quarter view, knuckles towards the viewer, "
    "square boxy fingers, yellow-tan skin like a classic Roblox noob"
)
VAC = "a chunky handheld toy vacuum blaster pointing to the right, a long nozzle at the front, a pistol grip underneath"

ICONS = {
    "coin": "A single shiny gold coin seen slightly from the front, thick rim, with a raised square brick-cube "
    "emblem in its centre",
    "gear": "A chunky settings gear cog with eight square teeth and a round hole in the middle, light steel grey "
    "with a darker grey inner ring",
    "speaker": "A chunky loudspeaker icon with two curved sound-wave arcs coming out of it, white and light grey",
    "music": "A chunky double music note (two joined eighth notes), bright yellow",
    "mouse": "A chunky computer mouse seen from above at a slight angle, white with a light-blue scroll wheel",
    # tool tiers: fists, then knuckle dusters (they replace the hammer)
    "fist_0": f"{FIST}, bare, no gloves",
    "fist_1": f"{FIST}, wearing a chunky bronze-brown knuckle duster with four round rings across the knuckles",
    "fist_2": f"{FIST}, wearing a chunky polished steel-grey knuckle duster with four round rings and small rivets",
    "fist_3": f"{FIST}, wearing a chunky shiny gold knuckle duster with four round rings and a small red gem",
    "fist_4": f"{FIST}, wearing a chunky sparkling cyan diamond-crystal knuckle duster with four faceted rings",
    "fist_5": f"{FIST}, wearing a chunky glowing electric-blue energy knuckle duster crackling with small "
    "lightning sparks",
    "vacuum_0": f"{VAC}, dark grey metal body, hazard-yellow nozzle, a small blue glass tank on top",
    "vacuum_1": f"{VAC}, bigger, bright orange body with black stripes, a twin nozzle and a larger blue tank",
    "vacuum_2": f"{VAC}, big and powerful, glossy red body with chrome trim, a wide funnel nozzle and two glowing "
    "green tanks",
    "vacuum_3": f"{VAC}, huge and futuristic, white and cyan body, a swirling glowing cyan vortex in the nozzle, "
    "a big glowing tank",
}


def generate(key: str, name: str) -> Path:
    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"
    body = {"contents": [{"parts": [{"text": f"{ICONS[name]}. {STYLE}"}]}]}
    r = requests.post(url, headers={"x-goog-api-key": key}, json=body, timeout=180)
    if r.status_code != 200:
        raise RuntimeError(f"{name}: HTTP {r.status_code} {r.text[:300]}")
    for part in r.json()["candidates"][0]["content"]["parts"]:
        data = part.get("inlineData") or part.get("inline_data")
        if data:
            path = RAW / f"{name}.png"
            path.write_bytes(base64.b64decode(data["data"]))
            return path
    raise RuntimeError(f"{name}: no image in response")


def cut(name: str) -> Path:
    img = np.asarray(Image.open(RAW / f"{name}.png").convert("RGB")).astype(np.int16)
    h, w, _ = img.shape
    # background colour = median of the outer ring (Gemini's magenta drifts a little)
    ring = np.concatenate([img[0], img[-1], img[:, 0], img[:, -1]])
    bg = np.median(ring, axis=0)
    dist = np.abs(img - bg).sum(axis=2)
    magenta_ish = (img[..., 0] > 150) & (img[..., 2] > 150) & (img[..., 1] < 110)
    passable = (dist < 120) | magenta_ish
    seen = np.zeros((h, w), bool)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if passable[y, x] and not seen[y, x]:
                seen[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if passable[y, x] and not seen[y, x]:
                seen[y, x] = True
                q.append((y, x))
    while q:
        y, x = q.popleft()
        for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= ny < h and 0 <= nx < w and not seen[ny, nx] and passable[ny, nx]:
                seen[ny, nx] = True
                q.append((ny, nx))
    alpha = np.where(seen, 0, 255).astype(np.uint8)
    rgb = img.copy()
    # despill: pixels next to the cut that still lean magenta get pulled to the outline navy
    edge = (~seen) & magenta_ish
    rgb[edge] = (30, 26, 46)
    out = Image.fromarray(np.dstack([rgb.astype(np.uint8), alpha]), "RGBA")
    box = out.getbbox()
    if box:
        out = out.crop(box)
    side = max(out.size)
    sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    sq.paste(out, ((side - out.size[0]) // 2, (side - out.size[1]) // 2))
    sq = sq.resize((256, 256), Image.LANCZOS)
    CUT.mkdir(parents=True, exist_ok=True)
    REPO_ICONS.mkdir(parents=True, exist_ok=True)
    p = CUT / f"{name}.png"
    sq.save(p)
    sq.save(REPO_ICONS / f"{name}.png")
    return p


def main() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    args = sys.argv[1:]
    if "--cut" in args:
        for name in [a for a in args if a != "--cut"] or [p.stem for p in RAW.glob("*.png")]:
            print("cut", cut(name), flush=True)
        return
    names = args or [n for n in ICONS if not (RAW / f"{n}.png").exists()]
    key = read_key("gemini")
    for name in names:
        try:
            generate(key, name)
            print("saved", cut(name), flush=True)
        except Exception as exc:  # report and keep going with the batch
            print("FAILED", exc, flush=True)


if __name__ == "__main__":
    main()
