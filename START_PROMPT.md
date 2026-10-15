# Full starting prompt for a new chat (copy everything below the line)

---

You're picking up **Break The Walls**, a Roblox game I'm making (I'm Rufus). Everything you need is below. Read all
of it before you touch anything.

## The game
- It's a Roblox incremental game, a remake of Pandorio's Steam game *Escape the Walls*. You're trapped in rooms
  whose walls are made of cubes, and the loop goes:
  1. Punch the wall (cross-shaped hit pattern).
  2. Broken cubes drop on the floor.
  3. Vacuum them up into your storage.
  4. Dump them at the deposit machine for money.
  5. Buy upgrades and better tools, break through, and move on to the next zone.
- It's **first person**, with your own avatar's arms on screen. The look is an indoor stud-brick test facility (grey
  and blue-grey panels, yellow and black hazard stripes, one accent colour per zone).
- There are **zones**: 1 Stone Facility (the tutorial), 2 Mine Cave (a maze with hidden paths) and 3 Security Vault
  (a boss room, still provisional).
- **Tools:** Fists, upgrading through **knuckle dusters** (bronze, iron, gold, diamond, energy), and the **Vacuum**,
  upgrading through 6 tiers (Basic, Turbo, Cyclone, Mega, Titan, Vortex). There's no hammer. Drones and excavators
  come later. No minecart for now.
- **Settled design:** no energy bar; money is paid only on deposit; a fast start; each zone has its own spawn area
  with a deposit machine, a tool podium and an upgrade board.

## Where everything is
- **Repo:** `C:\Users\rmcd9\BreakTheWalls`, on GitHub as **rufusm0001-stack/break-the-walls** (private).
  - The git identity is set per repo (Rufus <rufusm0001@gmail.com>); there's no global one.
  - The `gh` CLI isn't installed, so use plain `git push`.
  - Three people on three devices share this repo, so **`git pull` first and push at the end of every session**.
- **Roblox place:** "Break The Walls", placeId **104446080960521**, in Roblox Studio through the Studio MCP.
- **Art folder:** `C:\Users\rmcd9\Desktop\Break The Walls\`: generated icons (raw and cut), Meshy packs, and copies
  of the prompts.
- **Read these in the repo first:** `HANDOFF.md` (exact current state), `NEXT_PROMPT.md` (your job list),
  `AGENTS.md` and `CLAUDE.md` (hard rules), `DESIGN.md`, `docs/STYLE_BIBLE.md`, `docs/UI_RULES.md`,
  `docs/ZONE_BRIEFS.md` and `ui/UI_PROGRESS.md`.
- **Playbook:** the `roblox-stud-game` skill applies, but the **palette and lighting come only from
  docs/STYLE_BIBLE.md**. Ignore my other games' files (GameHub, Idle Medieval, coal mining, Escape Verity).

## API keys and paid services: strict rules
- **All keys live in `C:\Users\rmcd9\Desktop\IdleMedievalArt\api.txt`.** Never open, print, copy or commit that
  file, and never put a key in any file or message. Scripts read it themselves: `art/gen_refs.py` has `read_key()`,
  which `art/gen_icons.py` imports.
- **Gemini** (gemini-2.5-flash-image, about $0.039 an image): I've topped it up, so it's the art generator to use.
  - It can't draw transparency. `gen_icons.py` paints on flat magenta and cuts it out.
  - For a consistent set, use Gemini **image editing** (send the base PNG as `inlineData`).
- **OpenAI** (gpt-image): a fallback only, if I say so.
- **Uploading images to Roblox:** use the Studio MCP **`upload_image`**. Serve the folder on localhost and pass
  `http://127.0.0.1:<port>/file.png`. It's free and returns ImageLabel ids.
  - The Open Cloud key in api.txt had **no Assets scopes** the last time it was checked, so Open Cloud uploads fail
    until I add Assets API read + write.
- **Meshy:** I run it myself in a separate chat. You only prepare reference images and prompts.
- **Log every spend in `art/LEDGER.md`.** Before a batch over about $1, tell me the total.
- **Never publish the game and never spend Robux.** I do those.
- Before every push, grep the diff for key patterns.

## How to work in Studio
- **Getting scripts in:** the source of every script is in `studio/`. Serve the repo root with
  `python -m http.server 8796 --bind 127.0.0.1`; port 8792 belongs to another project.
  - In `execute_luau`, temporarily turn `HttpService.HttpEnabled` on.
  - Then `GetAsync("http://127.0.0.1:8796/studio/<file>")` followed by `ScriptEditorService:UpdateSourceAsync`.
  - Then restore HttpEnabled.
  - Edit the files in `studio/` (that's the source of truth), then install.
- **Stop Play before editing.** In `execute_luau`, require a **clone** of a module, never the live one.
- **Testing in Play:**
  - Pin the camera with `RunService:BindToRenderStep("PinCam", Enum.RenderPriority.Camera.Value, ...)` looking at a
    target.
  - Use `user_mouse_input` and `user_keyboard_input` for real input.
  - Mouse coordinates are in GUI space, which is 58 px higher than screenshot y (the top inset).
  - Aim at cube centres; a seam splits the damage.
- **UI:** build it only with `studio/ToyUI.lua` (ReplicatedStorage.Modules.ToyUI): slab, face, rim, studs, and
  Fredoka text with a hard shadow. No emoji, no letters standing in for icons.
- **Patch scripts:** Git Bash heredocs break on some quotes and backslashes on this PC. Write patch scripts as `.py`
  files, and use `encoding='utf-8'` whenever Python writes a file.
- **Every pass ends in Play:**
  - screenshots from the first-person camera, saved into `ui/screenshots/`
  - a clean console
  - `studio/map_qa.luau` and `ZFight.lua` after any map change

## What's built (detail in HANDOFF.md)
- **Server:** `ServerScriptService.GameServer` is server-authoritative. It handles punch validation, loose cubes
  (capped), the vacuum claiming cubes, deposit payouts, `leaderstats.Money`, checkpoints (a hole through a wall
  enables the next `Spawn_ZoneN`), and DataStore saving (money, checkpoint, storage, settings).
- **Client** (`StarterPlayerScripts`):
  - `ToolsClient`: the punch grid preview, prediction, chunk bursts, and the curved vacuum flights with trails
  - `HUD`: the money pill with the coin icon, the storage bar, and the 2-slot hotbar with tier icons
  - `SettingsUI`: gear button (key M), sensitivity, music and SFX sliders, and Left Alt to free the mouse
  - `Audio`: sounds plus an APM music playlist
  - `FirstPersonArms`: your avatar's own R15 arms, and a placeholder vacuum
- **Shared:** `ReplicatedStorage.BTW` holds `Config` (every number), `WallGrid`, `ClientState`, `Sounds` and
  `Remotes`. `ReplicatedStorage.Modules` holds `ToyUI` and `Icons`.
- **Not verified:** DataStore saving. Studio's "Enable Studio Access to API Services" is off. It's a security setting
  that only I change, so leave it to me and keep saving Studio-safe.

## What we're doing now
Do the 5 jobs in **`NEXT_PROMPT.md`**, in order:
1. **Quick UI fixes:** a small white centre cursor dot; hotbar slots in white or light blue instead of pale cream; a
   less tacky storage bar; a clearer sensitivity icon.
2. **Arms:** thinner (width about 0.8x, same length), spread a little wider.
3. **Icons:**
   - a proper gold coin
   - 6 fist tiers that are all the same fist with the duster **on the knuckles**, and cooler
   - 6 vacuum tiers, cooler, with the last three clearly bigger
4. **Meshy packs:** for each knuckle duster, `icon.png` + 3 views (front, side, top) + `prompt.txt`; for each
   vacuum, `icon.png` + 2 views (left side, right side) + `prompt.txt`. They go in
   `Desktop\Break The Walls\meshy\<Name>\`.
5. **Walls:** punchable cubes at half size (2 studs to 1, so 16x10 becomes 32x20 per layer), and deeper walls. Keep
   the loose floor cubes as they are. Fix the checkpoint hole size, the balance and the part count to match.

**Later, not now:** the tool podium shop (set the `FistTier` / `VacuumTier` player attributes on purchase), the
upgrade board (Radius, Power, Depth), swapping in the Meshy models when I import them, the Zone 3 boss, drones and
excavators, and a bigger UI pass.

## End of the session
1. Rewrite `HANDOFF.md`, add a dated entry at the top of `STATUS.md`, and update `ui/UI_PROGRESS.md` if the UI
   changed.
2. Tick off finished jobs in `NEXT_PROMPT.md`.
3. `git pull`, then commit (end the message with a Co-Authored-By line for the model you're running as), then push.
4. Tell me in plain words what changed, what you checked in Play, and anything I need to do (owner steps).
