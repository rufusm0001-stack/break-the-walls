"""Break The Walls UI icons via Gemini (gemini-2.5-flash-image, about $0.039 each).

Usage: python gen_icons.py [name ...]      (no names = every icon not generated yet; bases before edits)
Tier icons are Gemini image EDITS of fist_0 / vacuum_0 (EDITS), so every tier keeps the same fist or body.
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
from PIL import Image, ImageEnhance

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
    "one chunky blocky Roblox avatar right fist punching towards the viewer at a three-quarter angle, the flat front "
    "row of four square knuckles clearly facing the viewer, square boxy fingers curled in, a short square wrist "
    "behind, yellow-tan skin like a classic Roblox noob"
)
VAC = (
    "a chunky handheld toy vacuum blaster seen exactly from the side, pointing to the right, a nozzle at the front "
    "on the right, a pistol grip underneath, a collection tank on top"
)

# Edits keep the base image (same fist / same vacuum, same angle and framing) and change only the tool.
KEEP = (
    "Edit this image. Keep the exact same pose, camera angle, framing, outline thickness, lighting, art style and the "
    "same flat solid magenta (#FF00FF) background. No pink, rose or magenta on the object. No text."
)
DUSTER = (
    "Add {what} worn over the four knuckles: the finger rings go around the four fingers right at the knuckles and "
    "the striking bar runs across the front of the knuckles facing the viewer. Nothing on the wrist. The fist "
    "itself stays exactly the same, the same bright saturated yellow skin. Make the knuckle duster bright, vivid "
    "and saturated in its own colour, like a cheerful toy."
)

ICONS = {
    "coin": "A small stack of three thick shiny gold coins, the top coin tilted slightly towards the viewer with a "
    "bold raised dollar sign ($) embossed in its centre and a ridged rim, bright gold with warm highlights. The "
    "dollar sign is the only symbol allowed",
    "aim": "A chunky aiming crosshair reticle seen flat-on: a thick white ring with a small bright orange dot in the "
    "centre, and four chunky light-blue arrows outside the ring pointing outwards up, down, left and right",
    "gear": "A chunky settings gear cog with eight square teeth and a round hole in the middle, light steel grey "
    "with a darker grey inner ring",
    "speaker": "A free-standing chunky loudspeaker cone shape seen from the side with two curved sound-wave arcs "
    "coming out of it, white and light grey with a dark grey cone, nothing behind it (no circle, no badge, no button)",
    "music": "A chunky double music note (two joined eighth notes), bright yellow",
    "mouse": "A chunky computer mouse seen from above at a slight angle, white with a light-blue scroll wheel",
    # tool tier bases; the other tiers are EDITS of these
    "fist_0": f"{FIST}, bare, no gloves, nothing on the hand",
    "vacuum_0": f"{VAC}, simple and stubby, dark grey metal body, hazard-yellow nozzle, a small blue glass tank on "
    "top. The vacuum fills about 70% of the image width. No app-icon tile, no rounded square, no border",
}

# name -> (base image, edit instruction). Base images must exist in raw/ first.
EDITS = {
    "fist_1": ("fist_0", DUSTER.format(what="a chunky bronze knuckle duster with four thick round rings, warm "
                                            "brown-orange polished metal")),
    "fist_2": ("fist_0", DUSTER.format(what="a chunky polished steel knuckle duster with four rings, a row of "
                                            "rivets and four short stubby studs sticking out of the front bar")),
    "fist_3": ("fist_0", DUSTER.format(what="a chunky shiny gold knuckle duster with four rings, a big red ruby "
                                            "set in the middle of the front bar and a soft warm golden glow")),
    "fist_4": ("fist_0", DUSTER.format(what="a chunky faceted cyan diamond-crystal knuckle duster with four "
                                            "rings, sharp crystal spikes rising from the front bar, sparkles "
                                            "and a bright cyan glow")),
    "fist_5": ("fist_0", DUSTER.format(what="a bold glowing electric-blue energy knuckle duster with four rings, "
                                            "big angular fins and spikes along the front bar, crackling white "
                                            "lightning arcs and a strong blue glow")),
    "vacuum_1": ("vacuum_0", "Turn it into the Turbo tier: the same size and shape, bright orange body with black "
                             "racing stripes, a twin-barrel nozzle and a slightly larger blue tank."),
    "vacuum_2": ("vacuum_0", "Turn it into the Cyclone tier: the same size, glossy teal-green body with chrome "
                             "trim, a clear canister on top with a white spinning cyclone swirl inside, and a "
                             "flared nozzle."),
    "vacuum_3": ("vacuum_0", "Turn it into the Mega tier: make it clearly MUCH BIGGER and bulkier, filling much "
                             "more of the image: a big glossy red body, a huge round tank on top, a wide funnel "
                             "nozzle and extra hoses and parts."),
    "vacuum_4": ("vacuum_0", "Turn it into the Titan tier: make it HUGE and heavy, filling most of the image: thick "
                             "bright royal-purple armour plates with bright shiny gold trim, two big glowing "
                             "lime-green tanks, exhaust vents and a wide flared bright gold cannon nozzle. Bright, "
                             "saturated toy colours, no grey or brown."),
    "vacuum_5": ("vacuum_0", "Turn it into the Vortex tier, the biggest and coolest: make it ENORMOUS, filling the "
                             "image: a sleek white and cyan futuristic body, a huge nozzle with a swirling glowing "
                             "cyan vortex inside, glowing cyan rings around a big tank, and fins."),
}

# Colour pass (owner, 2026-10-15: "not colourful enough, pale yellow is boring"): an in-place Gemini edit of the
# existing raw image that keeps the design and only makes the colours richer. Run: gen_icons.py --vivid name ...
VIVID_KEEP = (
    "Edit this image. Keep the exact same object, design, shape, pose, camera angle, framing, outline and the flat "
    "solid magenta (#FF00FF) background. Only make the colours much richer and more vivid: deeper saturation, "
    "punchier highlights, bolder contrast, like a bright cheerful mobile game icon. No pink, rose or magenta on the "
    "object. No text."
)
SKIN = " The skin becomes a rich, warm, saturated golden yellow like the classic Roblox noob (#F5CD30), not pale."
VIVID = {
    "coin": " The gold becomes a deep, rich, shiny saturated gold-yellow with warm orange shading, not pale.",
    "gear": " The steel becomes a bright saturated sky blue with a deep blue inner ring and a bright yellow hub.",
    "speaker": " The speaker body becomes bright saturated blue with a vivid orange cone, and the sound-wave arcs "
    "become bright yellow.",
    "music": "",
    **{f"fist_{i}": SKIN for i in range(6)},
    "vacuum_0": " Make the body a deeper charcoal with a bright saturated yellow nozzle and a vivid blue tank.",
    "vacuum_1": " Make the orange more vivid and fiery.",
    "vacuum_2": " Make the teal more vivid and add bright yellow accents.",
    "vacuum_3": " Make the red more vivid and the trim brighter.",
    "vacuum_4": " Make the gold trim brighter and the green tanks glow more.",
    "vacuum_5": " Make the cyan glow more vivid and add a few chunky bright cogs (gear wheels) on the side of the "
    "body and around the nozzle, like turbine gears that spin.",
}

# Second colour pass (owner: fist_0 and the music note are the target; the rest still too dull). Brighter candy
# colours, no dark grey/brown/black bodies. Duster fists also get fist_0 as a skin-colour reference image.
CANDY = (
    " Use bright, light, candy-toy colours as saturated and cheerful as a bright yellow music note icon: replace any "
    "dark grey, black, brown or dull metal with bright saturated colours, keep only the dark navy outline dark."
)
VIVID2 = {
    **{f"fist_{i}": " The SECOND image is the colour reference: make the fist's skin exactly the same bright yellow "
       "as the fist in the second image. Make the knuckle duster brighter and more vivid in its own colour."
       for i in range(1, 6)},
    "gear": " Make the gear a bright saturated electric blue with a bright yellow hub, glossy highlights.",
    "speaker": " Make the speaker body bright saturated blue, the cone bright orange and the waves bright yellow.",
    "aim": " Make the ring bright yellow, the centre dot bright red and the arrows bright saturated blue.",
    "vacuum_0": " Body bright cobalt blue, nozzle bright yellow, tank bright cyan, grip bright orange.",
    "vacuum_1": " Body bright fiery orange with bright yellow stripes, nozzle bright red, tank bright cyan.",
    "vacuum_2": " Body bright mint green with bright yellow trim, chrome becomes bright light blue, canister bright cyan.",
    "vacuum_3": " Body bright cherry red with bright yellow trim and nozzle, tank bright cyan, hoses bright blue.",
    "vacuum_4": " Body bright royal purple with bright gold trim, tanks bright lime green, nozzle bright gold.",
    "vacuum_5": " Body bright electric blue and white with bright cyan glow, cogs bright gold, nozzle glowing cyan.",
}

SATURATION = 1.12
# name -> reference whose warm yellow it copies (coin copies the music note: owner wants a "nice yellow")
SKIN_MATCH = {**{f"fist_{i}": "fist_0" for i in range(1, 6)}, "coin": "music"}

# Hotbar icons are fitted into a square; per-tier scale keeps the big vacuums visibly bigger.
SCALE = {"vacuum_0": 0.74, "vacuum_1": 0.77, "vacuum_2": 0.80, "vacuum_3": 0.90, "vacuum_4": 0.95, "vacuum_5": 1.0}


def generate(key: str, name: str, vivid: int = 0) -> Path:
    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"
    if vivid:
        b64 = base64.b64encode((RAW / f"{name}.png").read_bytes()).decode()
        parts = [{"inlineData": {"mimeType": "image/png", "data": b64}}]
        if vivid == 2:
            if name.startswith("fist_"):
                ref = base64.b64encode((RAW / "fist_0.png").read_bytes()).decode()
                parts.append({"inlineData": {"mimeType": "image/png", "data": ref}})
            parts.append({"text": VIVID_KEEP + CANDY + VIVID2[name]})
        else:
            parts.append({"text": VIVID_KEEP + VIVID[name]})
    elif name in EDITS:
        base, change = EDITS[name]
        b64 = base64.b64encode((RAW / f"{base}.png").read_bytes()).decode()
        parts = [{"inlineData": {"mimeType": "image/png", "data": b64}}, {"text": f"{KEEP} {change}"}]
    else:
        parts = [{"text": f"{ICONS[name]}. {STYLE}"}]
    r = requests.post(url, headers={"x-goog-api-key": key}, json={"contents": [{"parts": parts}]}, timeout=180)
    if r.status_code != 200:
        raise RuntimeError(f"{name}: HTTP {r.status_code} {r.text[:300]}")
    for part in r.json()["candidates"][0]["content"]["parts"]:
        data = part.get("inlineData") or part.get("inline_data")
        if data:
            path = RAW / f"{name}.png"
            path.write_bytes(base64.b64decode(data["data"]))
            return path
    raise RuntimeError(f"{name}: no image in response")


def _hsv(a):
    a = a.astype(np.float32) / 255
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx, mn = a.max(-1), a.min(-1)
    d = np.maximum(mx - mn, 1e-6)
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    s = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    return h, s, mx


def _rgb(h, s, v):
    c = v * s
    x = c * (1 - np.abs((h / 60) % 2 - 1))
    m = v - c
    z = np.zeros_like(h)
    k = (h // 60).astype(int) % 6
    r = np.choose(k, [c, x, z, z, x, c])
    g = np.choose(k, [x, c, c, x, z, z])
    b = np.choose(k, [z, z, x, c, c, x])
    return (np.stack([r + m, g + m, b + m], -1) * 255).clip(0, 255)


def _skin(a):
    h, s, v = _hsv(a)
    return (h > 26) & (h < 55) & (s > 0.35) & (v > 0.45), h, s, v


# Duster fists drift more orange/duller than fist_0; shift their warm skin pixels to fist_0's median colour.
def skin_match(img, ref_name="fist_0"):
    ref = np.asarray(Image.open(RAW / f"{ref_name}.png").convert("RGB"))
    rm, rh, rs, rv = _skin(ref)
    m, h, s, v = _skin(img)
    if m.sum() == 0:
        return img
    dh = np.median(rh[rm]) - np.median(h[m])
    ks = np.median(rs[rm]) / max(np.median(s[m]), 1e-3)
    kv = np.median(rv[rm]) / max(np.median(v[m]), 1e-3)
    out = img.astype(np.float32).copy()
    out[m] = _rgb(h[m] + dh, np.clip(s[m] * ks, 0, 1), np.clip(v[m] * kv, 0, 1))
    return out.astype(np.int16)


def cut(name: str) -> Path:
    img = np.asarray(Image.open(RAW / f"{name}.png").convert("RGB")).astype(np.int16)
    if name in SKIN_MATCH:
        img = skin_match(img, SKIN_MATCH[name])
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
    # trapped pockets (a gear's hole, a ring's inside) never touch the edge: drop anything that is strongly
    # magenta anywhere, since the prompt bans pink on the subject
    strong = (img[..., 0] > 170) & (img[..., 2] > 140) & (img[..., 1] < 100) & (np.abs(img[..., 0] - img[..., 2]) < 110)
    seen = seen | strong
    alpha = np.where(seen, 0, 255).astype(np.uint8)
    rgb = img.copy()
    # despill: pixels next to the cut that still lean magenta get pulled to the outline navy
    edge = (~seen) & magenta_ish
    rgb[edge] = (30, 26, 46)
    # magenta that leaked onto the object (reflections, glow) becomes neutral grey of the same brightness
    r, g, b = img[..., 0], img[..., 1], img[..., 2]
    mx, mn = img.max(axis=2), img.min(axis=2)
    span = np.maximum(mx - mn, 1)
    # hue only matters on the magenta side of red (red max, blue over green) or of blue (blue max, red over green)
    hue = np.where((mx == r) & (b > g), 360 - 60 * (b - g) / span, 0)
    hue = np.where((mx == b) & (r > g), 240 + 60 * (r - g) / span, hue)
    # magenta/pink band is about 280-342 deg; ruby red (350+) stays
    pinkish = (~seen) & (hue > 280) & (hue < 342) & (span > 50)
    lum = (0.3 * r + 0.59 * g + 0.11 * b).astype(np.int16)
    rgb[pinkish] = np.stack([lum, lum, lum], axis=-1)[pinkish]
    # a flat saturation boost on every icon (owner wants them colourful); the outline navy barely changes
    rgb_img = ImageEnhance.Color(Image.fromarray(rgb.astype(np.uint8), "RGB")).enhance(SATURATION)
    out = Image.fromarray(np.dstack([np.asarray(rgb_img), alpha]), "RGBA")
    box = out.getbbox()
    if box:
        out = out.crop(box)
    side = max(out.size)
    canvas = int(round(side / SCALE.get(name, 1.0)))
    sq = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    sq.paste(out, ((canvas - out.size[0]) // 2, (canvas - out.size[1]) // 2))
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
    if "--vivid" in args or "--vivid2" in args:  # in-place colour pass; overwrites raw/<name>.png, back up first
        from concurrent.futures import ThreadPoolExecutor
        key = read_key("gemini")
        level = 2 if "--vivid2" in args else 1

        def one(name):
            try:
                generate(key, name, vivid=level)
                return f"saved {cut(name)}"
            except Exception as exc:  # report and keep going with the batch
                return f"FAILED {exc}"

        with ThreadPoolExecutor(5) as pool:
            for line in pool.map(one, [a for a in args if not a.startswith("--vivid")]):
                print(line, flush=True)
        return
    names = args or [n for n in list(ICONS) + list(EDITS) if not (RAW / f"{n}.png").exists()]
    key = read_key("gemini")
    for name in names:
        try:
            generate(key, name)
            print("saved", cut(name), flush=True)
        except Exception as exc:  # report and keep going with the batch
            print("FAILED", exc, flush=True)


if __name__ == "__main__":
    main()
