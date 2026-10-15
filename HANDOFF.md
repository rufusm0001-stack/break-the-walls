# Handoff: where the last agent left off

> Rewrite this whole file at the end of every session, so it always shows the **current** state. The history goes in `STATUS.md`.

**Last updated:** 2026-10-15 (third pass: NEXT_PROMPT jobs 1-5)
**By:** Rufus's Claude (device: main PC)

## What changed this pass
### 1. HUD fixes (`studio/HUD.client.lua`, `studio/ToyUI.lua`, `studio/SettingsUI.client.lua`)
- **Centre dot:** a 6 px white dot with a thin navy outline in its own inset-free ScreenGui,
  `PlayerGui.CenterDot`, so it sits on the true screen centre.
- **Hotbar slots:** the faces are light blue (`T.sky`) instead of pale cream; the gold selector stays.
- **Storage bar:** now a facility-slate gauge.
  - Structure: a `T.slate` block with a dark inset well (`T.well`), a gloss strip on the fill and tick marks every
    10%.
  - Fill colour: green, then orange at 70%, then red when full.
  - The kit's fill gradient multiplied over the colour (it went olive), so the HUD makes it neutral.
- **Settings:** the sensitivity row is now **"AIM SENSITIVITY"** with a crosshair-and-arrows icon (`Icons.Aim`).
- New theme colours: `orange`, `sky`, `slate`, `well`.

### 2. Arms (`studio/FirstPersonArms.client.lua`)
- `ARM_LENGTH 1.1`, `ARM_WIDTH 0.88`: the arms keep the same length and are 0.8x as thick as before.
- `POSE.x` is now 2.15 (was 2.0), so they're spread a little wider.

### 3. Icons (`art/gen_icons.py`, `studio/Icons.lua`, `art/icons/`)
- **New set:**
  - coin: a stack of gold coins with a $
  - aim
  - fist_0 to fist_5: all the same fist, with the duster **on the knuckles**
  - vacuum_0 to vacuum_5: Basic, Turbo, Cyclone, Mega, Titan, Vortex. Tiers 3-5 are bigger, both in the art and
    through the per-tier `SCALE` fit.
- **How the set was made:**
  - Tier icons are Gemini **image edits** of fist_0 / vacuum_0.
  - Then two colour passes, because Rufus said "pale yellow is boring, not colourful enough": `--vivid` and
    `--vivid2`.
  - `cut()` adds a de-pink step (by hue), a 1.12 saturation boost, and `SKIN_MATCH`. SKIN_MATCH shifts the
    duster fists' skin to fist_0's yellow and the coin to the music note's yellow.
  - Rufus's targets: **fist_0 and the music note are the "nice yellow"**, and the Vortex has cogs.
- **Where things are:**
  - Ids are in `ReplicatedStorage.Modules.Icons` (`Vacuum` now runs 0-5).
  - The contact sheet is `art/icons/_contact_sheet.png`.
  - Older versions are in `Desktop\Break The Walls\icons\old_v1..v3\`.

### 4. Tool models
- **Vacuums (Meshy, Rufus runs it):**
  - Each `Desktop\Break The Walls\meshy\Vacuum_<Tier>\` holds `icon.png`, **4 views** (left, right = mirrored left,
    front, three-quarter) and `prompt.txt`.
  - Made by `art/gen_meshy_packs.py`. The overview sheet is `meshy\_vacuum_views_sheet.png`.
- **Knuckle dusters: Blender, not Meshy** (Rufus's call), so they fit the hand exactly.
  - Rebuilt in a second pass: Rufus said the first ones "lack colour and depth and look nothing like the icons".
  - Each tier is now modelled after its icon:
    - Bronze: four fat copper rings on a thick bar.
    - Iron: a steel plate with cone spikes, rivets and spiked end caps.
    - Gold: ring ridges, an orange-gold band, and a ruby in a pronged bezel.
    - Diamond: four glass crystal blocks with glowing cores and crystal spikes.
    - Energy: a navy bar with a glowing wire edge, lightning, glowing rings and blade spikes.
  - The comparison is `art/blender/export/_icons_vs_models.png`.
  - `art/blender/knuckles.py` runs headless (Cycles previews, about 2 minutes):
    `"C:/Program Files/Blender Foundation/Blender 5.1/blender.exe" -b -P art/blender/knuckles.py`.
  - Output in `Desktop\Break The Walls\blender\`: `Knuckles_<Tier>.fbx` and `.glb` (one mesh per material, named
    `<Tier>_<Material>`), `preview_<Tier>.png`, `knuckles.blend`, `knuckles_spec.txt` and
    `knuckles_colours.json` (Roblox Color + Material per mesh, because importers can drop material colours).
    Copies are in `art/blender/export/`.
  - Sizes come from the R15 RightHand measured in Play: **1.042 x 0.317 x 1.204** studs. The first-person copy is
    0.92 x 0.35 x 1.06.
  - The origin is the hand centre, so the weld C0 is `CFrame.identity`. Everything sits on the punching end
    (hand -Y), and the spikes point to the hand's front (-Z): turn it 180 degrees if that's wrong in game.
- `art/MESHY_PROMPTS.md` is updated: 6 vacuum tiers, and dusters are built in Blender.

### 5. Walls: 1-stud cubes, deeper (`Config`, `WallGrid`, `GameServer`, `BuildWorld`, `ToolsClient`)
- **Grid and depth:**
  - `Config.CUBE_SIZE = 1`, and the face is `WALL_CUBES = { w = 32, h = 20 }`.
  - Depth is per zone (`Zones[n].wallDepth`): 5, 6 and 7 layers.
  - The layers past the 4-stud doorway reach into the corridor behind it. That corridor's hazard stripe has a gap
    there (`corridorNoBand`).
- **WallGrid keys are in half studs** (`math.round(x*2)`), so 1-stud cubes with .5 centres key reliably.
  `WallGrid.q()` snaps a coordinate. The server's hole check uses both.
- **Checkpoint:** `holeW 4, holeH 6, maxStartRow 3`. That's the same 4x6-stud hole as before, through all layers.
- **Balance (first pass):**
  - Hits: Zone 1 = 1, Zone 2 = 1.5, Zone 3 = 2. Values are unchanged (1 / 3 / 8).
  - A 50-cube storage trip pays the same as before; it just fills faster.
  - Zone 1's hole is 120 cubes, about 40-50 punches.
- **Rebuilding:** `B.rebuildWalls(n)` rebuilds only zone n's walls (and the Zone 2 HiddenVein, 8x6x4 = 192 cubes).
  It uses its own seeded Random, so it never shifts the rest of the layout. It yields every 4 columns.
- **Part count:** 3,200 + 3,840 + 4,480 wall cubes. The workspace is now **13,456 parts** (was 2,734).
  StreamingEnabled is off.
- **Client:** break chunks scale with the cube size (5 chunks instead of 7).

### Checked in Play (screenshots in `ui/screenshots/pass3/`)
- the centre dot, slimmer arms and the light-blue hotbar
- the settings panel with the AIM row
- tier 5 icons swapping in on the hotbar (FistTier and VacuumTier attributes)
- punching 1-stud cubes: the grid preview fits one cube, the centre breaks in one hit, the ring darkens
- a **4x6 hole through all 5 layers fired "ZONE 2 IS OPEN"**
- the vacuum collected all 4 loose cubes, and the gauge fill is a clean green
- `map_qa`: no issues; ZFight: 0 in Zones 1-3
- console: only the known DataStore line

## Exact state (Instance paths touched)
- `ReplicatedStorage.Modules.ToyUI`, `ReplicatedStorage.Modules.Icons`
- `ReplicatedStorage.BTW.Config`, `ReplicatedStorage.BTW.WallGrid`
- `ServerScriptService.GameServer`
- `StarterPlayerScripts.HUD`, `StarterPlayerScripts.SettingsUI`, `StarterPlayerScripts.FirstPersonArms`,
  `StarterPlayerScripts.ToolsClient`
- `ServerStorage.DevTools.BuildWorld`
- `Workspace.World.Zone1/2/3.BreakableWall` (rebuilt), `Zone2.LeftTunnel.HiddenVein` (rebuilt), and 6 Hazard
  stripes removed from the Zone 1/3 corridors
- Every source is in `studio/`. Install: serve the repo root on port **8796**, then `GetAsync` + `UpdateSourceAsync`.

## Owner steps
- **Save the place** in Studio (File → Save to Roblox). The wall rebuild and the scripts live in the open session.
- **Meshy: the 6 vacuums.**
  - Upload the 4 views from each `meshy\Vacuum_<Tier>\` folder; the settings are in prompt.txt.
  - Import each FBX, then `insert_asset` it into `ServerStorage.MeshyImports` under the same name.
- **Knuckle dusters:**
  - Check `art/blender/export/_icons_vs_models.png` first.
  - Import `Desktop\Break The Walls\blender\Knuckles_*.fbx` (or `.glb`) with File → Import 3D.
  - Then ask the next agent to wire them in.
- **Turn on Game Settings → Security → "Enable Studio Access to API Services"** to test saving. That's still open.
- From before: `Lighting.Technology` = ShadowMap, Avatar R15, review Zone 3.

Nothing was published and no Robux was spent. This pass spent about $3.0 on Gemini (logged in `art/LEDGER.md`).

## Next step (start here)
1. **Weld the dusters on.**
   - Once Rufus imports the Blender FBXs, clone the tier's model onto `RightHand` / `LeftHand` with
     `C0 = CFrame.identity`, and colour it from `knuckles_colours.json`.
   - Do it on both the character and `Camera.ViewModel`. The viewmodel copy is scaled (0.88, 1.1, 0.88).
   - Drive it from the `FistTier` attribute.
2. **Swap the vacuum placeholder** for the Meshy `Vacuum_<Tier>` models, scaled by tier (about 1.2x, 1.35x, 1.5x for
   tiers 3-5).
3. **Tool podium shop:** add `Config.Knuckles` / `Config.Vacuums` tier tables and set FistTier / VacuumTier on
   purchase.
4. **Upgrade board:** Radius, Power, Depth.
   - Punching a hole now needs many punches, so Radius (a bigger pattern) and Depth (hit more than 1 layer) matter a
     lot. Balance them together.

## Watch out for
- **Part count:**
  - 13.5k parts is fine on PC.
  - If phones lag, options are StreamingEnabled, or merging untouched back layers into one part until the layer in
    front breaks.
- **Punching into a hole** centres the pattern on the deeper cube, so the face-layer ring cubes take only half
  damage. That's by design (it's how cross5 works), but it makes Depth upgrades important.
- **The `--vivid` / `--vivid2` icon passes overwrite `raw/<name>.png` in place.** Back up raw/ first; old_v1-v3 are
  there.
- **`ToyUI.bar`'s gradient is tinted with the starting fill colour,** so changing the fill colour later goes muddy.
  The HUD neutralises it; other bars may need the same fix.
- **MCP testing:**
  - `user_mouse_input` y is GUI space (screenshot y minus 58).
  - Pin the camera at `RenderPriority.Camera.Value`. At +1 it runs after the arms update, and they vanish from the
    frame.
- **Git Bash heredocs** break on some quotes, and Python turns `\b` in a normal string into a backspace. Use
  raw strings or the Write tool for Windows paths.
