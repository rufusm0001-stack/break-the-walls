# Next session: paste this into a fresh Claude chat

> Break The Walls (Roblox, placeId 104446080960521, repo C:\Users\rmcd9\BreakTheWalls). Start with `git pull`, then
> read HANDOFF.md, AGENTS.md, CLAUDE.md, docs/STYLE_BIBLE.md, docs/UI_RULES.md and this file
> (NEXT_PROMPT.md).
>
> Do the jobs below in order. Serve files to Studio on port **8796**. Generate art with Gemini via `art/gen_icons.py`
> (the key is read inside the script; never print it). Upload images with the Studio MCP `upload_image`. Log every
> spend in `art/LEDGER.md`. Check everything in Play from the first-person camera, then update HANDOFF.md and
> STATUS.md, then commit and push. Never publish, and never spend Robux.

Owner feedback, 2026-10-15 (Rufus):

## 1. Quick UI fixes (do these first)
- **Centre cursor:** bring back a *small* dot in the middle of the screen. It should be white with a thin dark
  outline, about 6 px, in its own inset-free ScreenGui. It was removed in `HUD.client.lua`; see git history for the
  old version.
- **The bottom HUD looks tacky:**
  - The hotbar slots and the storage bar use pale cream (`T.cream`), which reads as a weird pale yellow.
  - Make the slot faces **white or light blue**, and keep the gold selector for the equipped slot.
  - Restyle the storage bar so it looks less flat and cheap.
  - The fist and vacuum hotbar icons look off on pale cream. Re-check them once the new icons (job 3) are in.
- **Sensitivity icon:** the settings row icon is a computer mouse, and Rufus didn't know what it was for. Swap it
  for a clearer one (for example a crosshair with arrows) or make the label obvious.

## 2. Arms: thinner and spread out a little
In `studio/FirstPersonArms.client.lua`:
- The arms are "too girthy". Scale **width and depth** down to about 0.8x and keep the length; right now
  `ARM_SCALE = 1.1` scales all three axes.
- Spread them slightly wider: `POSE.x` about 2.0 to 2.2.
- Tune live in Play by setting attributes on `Camera.ViewModel` (`x`, `y`, `z`, `pitch`, `yaw`, `roll`), then copy
  the result into `POSE`.

## 3. Icons: regenerate a better, consistent set (Gemini)
- **Coin:** the current one (a block grid on a disc) reads as "broken blocks". Make it a proper **shiny gold coin**,
  or a small stack of gold coins, with a simple emblem or a $ mark.
- **Fists, 6 tiers (bare plus 5 knuckle dusters):**
  - All of them must be **the same fist, same angle and same size**. Only the knuckle duster changes.
  - The duster always sits **on the knuckles**, never on the wrist; the diamond one is on the wrist at the moment.
  - Make them look **cooler**: bolder shapes, glow on the high tiers, spikes or fins on the last ones.
  - For consistency, generate `fist_0` first. Then make every tier with Gemini **image editing**: send the
    `fist_0` PNG as an input image (`inlineData`) plus the change.
- **Vacuums: 6 tiers instead of 4.** Suggested names: Basic, Turbo, Cyclone, Mega, Titan, Vortex.
  - Each tier looks cooler than the last.
  - **The last three get clearly BIGGER**: bigger tanks, wider nozzles, more parts.
  - Keep the same side-on angle across all six.
- **After uploading:** update `studio/Icons.lua` (`Vacuum` now runs 0-5) and the comment in `HUD.client.lua`.

## 4. Meshy reference packs (Rufus runs Meshy himself)
Make one folder per model under `Desktop\Break The Walls\meshy\<Name>\`. Each folder holds:
- **`icon.png`:** the hotbar/taskbar icon (the same image as in job 3).
- **Reference views on a plain light-grey background,** with no text and the same design in every view:
  - **Knuckle dusters** (`Knuckles_Bronze`, `Knuckles_Iron`, `Knuckles_Gold`, `Knuckles_Diamond`, `Knuckles_Energy`):
    **3 images**, front, side and top. Show the duster on its own (no hand), finger rings facing the camera in the
    front view.
  - **Vacuums** (the 6 tiers): **2 images**, the left side and the right side.
- **`prompt.txt`:** the Meshy text prompt for multi-image-to-3D, plus the settings:
  - polycount: 6-10k for tools
  - export FBX
  - for knuckles: "rings over the knuckles, sized for a blocky Roblox hand"
  - for vacuums: "pistol grip underneath, nozzle forward"

Generate the views with Gemini image editing from the icon image, so all the views match. Update
`art/MESHY_PROMPTS.md` to the 6 vacuum tiers and the knuckle-on-knuckles rule.

Rough cost: about 40 images, about $1.60 on Gemini. Say the total before you run the batch.

## 5. Smaller wall cubes and deeper walls (the map pass; check the part count)
The cubes you punch are too big. **Halve the wall cube size** (`Config.CUBE_SIZE` 2 to 1), which doubles the grid:
16x10 becomes **32x20** per layer. Also make the walls **deeper** (more layers). The loose floor cubes are fine at
0.6.

Things that have to change with it:
- `studio/BuildWorld.lua`: rebuild the walls per zone. The HiddenVein in Zone 2 needs to match too.
- `Config.Checkpoint.holeW` / `holeH`: these count cubes, so double them (4 x 6) to keep the hole the same size in
  studs.
- `Config.Fists.range` stays in studs.
- Rebalance `Hits` and `Value` per cube: 4x as many cubes would otherwise make zones 4x as long and pay 4x as much.
- `WallGrid` keys round positions to whole studs, so 1-stud cubes need half-stud-safe keys. Check them.
- **Part count:** 32x20 cubes with 4 layers is 2,560 parts per zone, about 7.7k for three zones. That's fine with
  StreamingEnabled off, but measure it. Run `studio/map_qa.luau` and `ZFight.lua` after the rebuild.

## Done when
- All five jobs are checked in Play: screenshots from the first-person camera in `ui/screenshots/`, and a clean
  console (apart from the known DataStore line until Studio API access is on).
- HANDOFF.md, STATUS.md and ui/UI_PROGRESS.md are updated, and everything is committed and pushed.
