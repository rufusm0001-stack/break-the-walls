"""Meshy multi-image-to-3D reference packs for Break The Walls tools (Gemini image editing, ~$0.039 an image).

Usage: python gen_meshy_packs.py [Name ...]     (no names = every pack whose views are missing)
Writes Desktop/Break The Walls/meshy/<Name>/: icon.png (the cut hotbar icon), view_*.png (plain light-grey
background, same design in every view, no text) and prompt.txt (Meshy prompt + settings). Rufus runs Meshy.
Knuckle dusters: the front view is made first from the fist icon (duster alone, no hand); the other views are
edits of that front view, so all four match. Vacuums: every view is an edit of the icon's raw image.
The key is read from outside the repo (gen_refs.read_key) and never printed.
"""
import base64
import shutil
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).parent))
from gen_refs import read_key  # noqa: E402

ICONS = Path.home() / "Desktop" / "Break The Walls" / "icons"
OUT = Path.home() / "Desktop" / "Break The Walls" / "meshy"
URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"

BG = (
    "Plain flat light-grey (#D9D9D9) background, the object centred and shown whole with a generous margin, soft "
    "even studio lighting, a clean product-reference render for 3D modelling: same design, same colours, same "
    "proportions and details as the reference. No text, no labels, no hand, no shadow, no floor, no other objects."
)

KNUCKLES = {  # name -> (icon, what it is)
    "Knuckles_Bronze": ("fist_1", "bronze knuckle duster"),
    "Knuckles_Iron": ("fist_2", "steel knuckle duster with rivets and studs"),
    "Knuckles_Gold": ("fist_3", "gold knuckle duster with a red ruby"),
    "Knuckles_Diamond": ("fist_4", "cyan diamond-crystal knuckle duster with crystal spikes"),
    "Knuckles_Energy": ("fist_5", "electric-blue energy knuckle duster with fins, spikes and lightning"),
}
VACUUMS = {
    "Vacuum_Basic": ("vacuum_0", "Basic tier toy vacuum blaster"),
    "Vacuum_Turbo": ("vacuum_1", "Turbo tier toy vacuum blaster"),
    "Vacuum_Cyclone": ("vacuum_2", "Cyclone tier toy vacuum blaster"),
    "Vacuum_Mega": ("vacuum_3", "Mega tier toy vacuum blaster, big and bulky"),
    "Vacuum_Titan": ("vacuum_4", "Titan tier toy vacuum blaster, huge and armoured"),
    "Vacuum_Vortex": ("vacuum_5", "Vortex tier toy vacuum blaster, the biggest, with gear cogs"),
}

KNUCKLE_VIEWS = {
    "view_side": "Show the same knuckle duster seen exactly from the side (a profile view, 90 degrees from the front).",
    "view_top": "Show the same knuckle duster seen from directly above (top-down view).",
    "view_three_quarter": "Show the same knuckle duster from a three-quarter angle, front and side both visible.",
}
VACUUM_VIEWS = {
    "view_left": "Show this exact same vacuum blaster seen exactly from its left side, nozzle pointing right.",
    "view_right": "Show this exact same vacuum blaster seen exactly from its right side, nozzle pointing left; "
                  "invent the hidden side to match the visible one.",
    "view_front": "Show this exact same vacuum blaster seen from straight in front, the nozzle opening facing the "
                  "viewer, the pistol grip underneath.",
    "view_three_quarter": "Show this exact same vacuum blaster from a front three-quarter angle, nozzle towards the "
                          "viewer on the right, side visible.",
}


def edit(key, src: Path, text: str, dst: Path):
    b64 = base64.b64encode(src.read_bytes()).decode()
    body = {"contents": [{"parts": [{"inlineData": {"mimeType": "image/png", "data": b64}}, {"text": text}]}]}
    r = requests.post(URL, headers={"x-goog-api-key": key}, json=body, timeout=180)
    if r.status_code != 200:
        raise RuntimeError(f"{dst.parent.name}/{dst.name}: HTTP {r.status_code} {r.text[:200]}")
    for part in r.json()["candidates"][0]["content"]["parts"]:
        data = part.get("inlineData") or part.get("inline_data")
        if data:
            dst.write_bytes(base64.b64decode(data["data"]))
            return dst
    raise RuntimeError(f"{dst.parent.name}/{dst.name}: no image in response")


def prompt_txt(name, what, kind):
    if kind == "knuckles":
        body = (f"{what}, a chunky cartoon toy-style game weapon, glossy plastic look, bright saturated colours. "
                "Four finger rings in a row joined by a striking bar across the front; rings over the knuckles, "
                "sized for a blocky Roblox hand.")
        views = "view_front.png, view_side.png, view_top.png, view_three_quarter.png"
    else:
        body = (f"{what}, a chunky cartoon handheld vacuum gun for a Roblox game, glossy plastic look, bright "
                "saturated colours. Pistol grip underneath, nozzle forward, collection tank on top.")
        views = "view_left.png, view_right.png, view_front.png, view_three_quarter.png"
    return (f"{name}\n\nMeshy: Multi-Image to 3D\nImages (upload all, same order): {views}\n"
            f"(icon.png is the hotbar icon, for reference only)\n\nText prompt:\n{body}\n\nSettings:\n"
            "- Polycount: 6,000-10,000 (tool)\n- Topology: triangle, or quad if offered\n- Texture: on, PBR off "
            "(flat toy look)\n- Symmetry: auto\n- Export: FBX\n\nIf it comes out wrong, try again with only "
            "view_three_quarter.png + view_front/left (2 images), or Image to 3D on view_three_quarter.png alone.\n")


def knuckle_pack(key, name, icon, what):
    d = OUT / name
    d.mkdir(parents=True, exist_ok=True)
    shutil.copy(ICONS / "cut" / f"{icon}.png", d / "icon.png")
    (d / "prompt.txt").write_text(prompt_txt(name, what, "knuckles"), encoding="utf-8")
    front = d / "view_front.png"
    if not front.exists():
        edit(key, ICONS / "raw" / f"{icon}.png",
             f"Take the {what} off the fist and show it ON ITS OWN with no hand: the same duster, seen straight "
             f"from the front, the four finger rings facing the camera and the striking bar across them. {BG}",
             front)
    done = [front.name]
    for v, text in KNUCKLE_VIEWS.items():
        p = d / f"{v}.png"
        if not p.exists():
            edit(key, front, f"{text} {BG}", p)
        done.append(p.name)
    return f"{name}: {', '.join(done)}"


def vacuum_pack(key, name, icon, what):
    d = OUT / name
    d.mkdir(parents=True, exist_ok=True)
    shutil.copy(ICONS / "cut" / f"{icon}.png", d / "icon.png")
    (d / "prompt.txt").write_text(prompt_txt(name, what, "vacuum"), encoding="utf-8")
    done = []
    for v, text in VACUUM_VIEWS.items():
        p = d / f"{v}.png"
        if not p.exists():
            edit(key, ICONS / "raw" / f"{icon}.png", f"{text} {BG}", p)
        done.append(p.name)
    return f"{name}: {', '.join(done)}"


def main():
    want = set(sys.argv[1:])
    key = read_key("gemini")
    jobs = [(knuckle_pack, n, *v) for n, v in KNUCKLES.items()] + [(vacuum_pack, n, *v) for n, v in VACUUMS.items()]
    jobs = [j for j in jobs if not want or j[1] in want]

    def run(job):
        fn, name, icon, what = job
        try:
            return fn(key, name, icon, what)
        except Exception as exc:  # report and keep going with the batch
            return f"FAILED {exc}"

    with ThreadPoolExecutor(4) as pool:
        for line in pool.map(run, jobs):
            print(line, flush=True)


if __name__ == "__main__":
    main()
