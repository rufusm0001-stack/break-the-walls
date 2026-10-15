# UI Rules — chunky stud-toy UI, no AI slop

Every screen in the game follows these. The `ui-critic` agent checks screenshots against this
file before UI work is called done.

Sources:
- `docs/ui/RESEARCH.md`: Roblox docs and DevForum research.
- `research_notes/yt/UI_TUTORIAL_FINDINGS.md`: 17 YouTube UI tutorials, including "The
  Greatest Stud UI Tutorial on Roblox (w/ Figma)". The numbers below come from these.

When research changes a rule, update it here.

## Build everything from the kit

All UI is built through one module, `ReplicatedStorage.Modules.ToyUI`, which provides `Theme`,
`button`, `panel`, `label`, `bar` and `root`.
- No hand-built one-off buttons.
- No literal `Color3` in screen code: colours come from `ToyUI.Theme`.
- The kit's source is versioned in `studio/ToyUI.lua` in this repo.

## The toy stack (every button and panel)

1. **Slab:** a darker copy of the shape, the full height including the depth.
   - Colour is the face colour about 35–40% darker, hue nudged toward blue. Never plain
     black at partial transparency.
   - It carries the dark outline (`#1E1A2E`), so the outline wraps the whole silhouette.
2. **Face:** sits on top of the slab, raised by the depth.
   - Depth is 3 px on small buttons and 5 px on rail buttons and headers.
   - Every button in the same tier uses the same depth.
3. **Gradient:** `UIGradient`, Rotation 90, lighter at the top.
4. **Inner rim:** a `UIStroke` on the face (Border, Inner) in a lighter tint of the face colour,
   3 px. Required, not optional; every tutorial uses it.
5. **Studs:**
   - An ImageLabel using the procedural `stud_tile.png`, ScaleType Tile, TileSize 12 px,
     ImageTransparency 0.55–0.8.
   - It needs its own `UICorner`, because `ClipsDescendants` ignores rounded corners.
   - Never put studs on the slab.
6. **Text:**
   - White Fredoka One with a dark `UIStroke`: 2 px on small text, 3 px on titles and numbers.
   - A **hard shadow**: a duplicate label in `#1E1A2E`, offset 2 px down (3 px for titles),
     with no blur.
   - Keep at least 1/6 of the button height clear of the text on each side.

**Shine bars** (diagonal transparency bars) go on call-to-action/price buttons only, so the
screen keeps one focal point.

## Shape

- **Corner radius:** 4 px on brick buttons and panels; at most 7 px on softer cards. Fully
  round only for round icon buttons.
  - The old 12–16 px was rounder than any tutorial; that's part of why it looked generic.
- **Grid:** all sizes are whole multiples of 12 px (one stud), so studs never get cut in half
  at an edge.
- **Spacing:** panel padding 20 px, gap 16 px, equal on every side.

## Size budget (at the 1280x720 design size, under the root UIScale)

The previous HUD was far too big. These are hard caps.

| Element | Size |
|---|---|
| Rail button | 48x48 (4 studs), label 16 |
| HUD money number | 30 |
| Small HUD pill (money, shards) | about 192x48 |
| Cart bar | about 312x36 |
| Hotbar slot | 60x60 |
| Panel title | 40 |
| Item title | 24 |
| Body text | 16–18 (never below 14) |
| Call-to-action button | 192x48, label 24 |
| Close button | 36–48 |
| Panels | at most 50% width × 60% height on desktop; confirm dialogs about 1/3 × 1/3; up to 92% width on phone |

**Scaling:**
- Build in offset at 1280x720 inside one root `UIScale`, with
  `scale = min(vw/1280, vh/720)`.
- On small viewports (phones), multiply by 1.7 so a 48 px rail button stays at least 44 pt.
- Never scale the desktop UI up past 1.0.

## What "AI slop" means here (never do these)

- Dark translucent rectangles with a thin gold border and small serif or typewriter text (the
  ChatGPT build).
- Big soft rounded cards with no depth, no rim, no texture: our first pass.
- Emoji or plain letters standing in for icons.
- Walls of text, or tooltips longer than two short lines.
- Everything the same size and weight, with no focal point.
- Gradients that don't come from the palette.
- Panels that cover the whole screen on a phone.

## Panels

- **Body:** light cream, with faint studs at ImageTransparency about 0.8 and a 4 px outline.
- **Header:** a banner in the function colour straddling the top edge, with the title at 40.
- **Close:** a red square toy button at the top-right corner.
- One panel at a time, centred, with the game visible around it.
- **Shops:** the hero item goes first and larger. Every price is a green toy button with a
  currency icon.
- **Upgrade Book:**
  - One page per tool.
  - Three tracks, each with an icon, name, level pips and a price button.
  - Locked tools show as padlocked "???" cards.
  - "Your money" sits in the footer.

**Colour coding, always the same:**
- money: gold
- coal: charcoal
- diamonds and shards: cyan
- upgrades and buy: green
- shop: blue
- locked: grey
- close: red

## Icons

- Illustrated in one consistent style, generated as a set.
- The thick dark outline is baked into the PNG, because a `UIStroke` on an image outlines the
  rectangle.
- Add a hard shadow: a dark-tinted duplicate ImageLabel, offset 2 px.
- Source images ≤ 1024 px, ScaleType Fit.

## Layout

- **Left rail:** buttons for Upgrades, Shop and Map.
- **Top centre:** run progress.
- **Top right:** money, then shards.
- **Top left:** the mine zone list, shown only inside the mine.
- **Bottom centre:** cart bar above the hotbar.
- Bottom corners stay empty, because the phone joystick and jump button live there.

## Feel

- **Buttons:** hover to 1.05 and press to 0.95 on a `UIScale` child, never by tweening Size.
  Set AutoButtonColor = false.
- **Panel open:** UIScale 0.9→1 with Back easing over 0.2 s, plus a slide up of 5%.
- **Panel close:** reverse in 0.1 s.
- **Full-screen menus only:** BlurEffect 12 and camera FOV +5.
- **Buying:** the price button flashes green, coins fly to the money counter and a sound plays.
- **Not enough money:** the button shakes and the price flashes red; no popup.
- **Numbers:** count up rather than jump. Use commas below 10,000, then 1.2K, 3.4M.

## Verification (before calling any screen done)

- Screenshot at 1920x1080 and at a phone viewport, over the real mine scene.
- Check:
  - the size table
  - the same slab depth on every button in a tier
  - one outline weight per tier
  - no half studs
  - text clear of edges
  - nothing in the bottom corners
- Run `ui-critic`.
