# Map and feel pass: starting prompt for a new chat (copy everything below the line)

---

You're joining **Break The Walls**, a Roblox game I'm making (I'm Rufus). This session has two halves.

1. **Get a feel for the game.** Play it properly, the way a new player would, and understand what's fun and what isn't.
2. **Make lots of changes to the map.** Layout, rooms, routes, landmarks, props, lighting, flow between zones.

You have real freedom on the map. But the game's code depends on certain names and numbers in the world, so read the
"Don't break these" section before you move anything. Read this whole prompt first, then the repo files it points to.

## 1. What the game is

- **What it's based on:** a Roblox remake of Pandorio's Steam game *Escape the Walls* (Unity, Steam page coming
  soon), with a Roblox stud-brick look and a much nicer UI.
  - Gameplay frames from the original are in `references/original-game/`.
  - A rival Roblox version by "Sami" is already live; its frames are in `references/roblox-competitor/`.
  - We copy the mechanics, not the names or art, and we want to beat Sami's version on feel, polish and map.
- **The loop:**
  1. You're trapped in a room whose wall is made of small cubes.
  2. **Punch** it (LMB, cross-shaped hit pattern). A grid preview shows which cubes you'll hit.
  3. Broken cubes drop on the floor as loose pickups.
  4. Switch to the **Vacuum** (slot 2, hold LMB) and suck them into your **storage** (50 at the start).
  5. Walk to the **deposit machine** and stand in it to cash your storage in for **money**.
  6. Spend money at the **tool podium** on better knuckle dusters (more damage) and better vacuums (more storage
     and range).
  7. Punch a hole all the way through the wall and the next zone opens. Its spawn becomes your checkpoint.
- **First person.** CameraMode is LockFirstPerson, and you see your own avatar's arms holding the tool (dusters on
  the fists, a Meshy vacuum in the right hand). **Judge every view from first person at head height**, because that's
  the only way players ever see the map.
- **Settled design (don't reopen these):**
  - no energy bar
  - money only on deposit
  - a fast start (first upgrade in about a minute, Zone 1 in about 10 minutes)
  - every zone has its own spawn area with a deposit machine, a tool podium and an upgrade board
  - each zone has its own twist
- **Zones today:**
  - **Zone 1, Stone Facility:** the tutorial. A straight room, and the wall is straight ahead.
  - **Zone 2, Mine Cave:** the twist is "Not every room is straight forward".
    - A hub with a big sign, then two tunnels.
    - The right tunnel leads to the chamber with the orange ore wall.
    - The left one looks like a dead end, but it hides a small breakable ore vein that opens a shortcut into the
      chamber.
  - **Zone 3, Security Vault: PROVISIONAL**, needs my review. A spawn hall, a red "WARDEN ACTIVE" gate, then a round
    arena with a placeholder boss robot. After that, a reinforced steel vault wall in a big red frame, then an exit
    corridor to a "ZONE 4 - COMING SOON" sign.
- **Coming later, not this session:** the upgrade board (Radius / Power / Depth), the Zone 3 boss fight, drones and
  excavators, Zone 4 and up (maze rooms, boss rooms, timed walls, hidden layers), and prestige.

## 2. Where everything is

- **Repo:** `C:\Users\rmcd9\BreakTheWalls`, on GitHub as **rufusm0001-stack/break-the-walls** (private).
  - Three people on three devices share it.
  - **`git pull` before you start and push when you finish.**
  - The git identity is per repo, and there's no `gh` CLI, so use plain git.
- **Roblox place:** "Break The Walls", placeId **104446080960521**, driven through the **Roblox Studio MCP**.
- **Art folder:** `C:\Users\rmcd9\Desktop\Break The Walls\` (icons, Meshy packs, Blender exports).
- **Read these in the repo, in this order:**
  1. `HANDOFF.md`: the exact current state and the last agent's notes. Trust it over this prompt if they differ.
  2. `AGENTS.md` and `CLAUDE.md`: the hard rules.
  3. `DESIGN.md`: the spec and the settled decisions.
  4. `docs/STYLE_BIBLE.md`: the palette, lighting values and building rules for **this** game.
  5. `docs/ZONE_BRIEFS.md`: the per-zone colours, landmark and twist.
  6. `docs/UI_RULES.md` and `ui/UI_PROGRESS.md`.
  7. `STATUS.md` (newest first) and `TASKS.md`.
  8. `START_PROMPT.md`: the general onboarding, keys, and Studio workflow.
- **Skills:**
  - `roblox-stud-game`: the method, tools and map lessons. Read its `references/LESSONS_GAMEHUB.md`.
  - `roblox-game`: my general Roblox brain (an Obsidian vault). Use it for map and level-design research if you
    want it.
  - **This game's palette and lighting come only from `docs/STYLE_BIBLE.md`.** The skills' grass, purple and
    cartoony defaults don't apply.
- **Ignore my other games entirely:** GameHub / "Good Games Only", Idle Medieval, the coal mining game, Escape
  Verity and the Orsted cave. Don't follow their files, memories, rules or layouts.

## 3. How the world is built today (read before changing it)

- **The map is built from code:** `studio/BuildWorld.lua`, installed as `ServerStorage.DevTools.BuildWorld`.
  - Call `B.init(StudKit, Config)` first.
  - `B.lighting()` sets the lighting.
  - `B.zone1()`, `B.zone2()` and `B.zone3()` each delete and rebuild `Workspace.World.ZoneN`.
  - `B.rebuildWalls(n)` rebuilds only that zone's breakable wall (and Zone 2's hidden vein), using its own seeded
    Random.
- **Helpers inside it:**
  - `room()`: a floor, walls with openings and pillars, a hazard band and a ceiling. Styles are `facility`, `cave`
    and `vault`.
  - `ceilingLights()`, `lantern()`, `breakable()`, `walkway()`, `wallSign()`, `spawnPad()`
  - the placeholders: `depositMachine`, `toolPodium`, `upgradeBoard`, and the boss
  - the props: crates, plants, barrels, crystals, server racks, wall screens, vents, alarm lights, security cameras
- **Kit:** `studio/StudKit.lua` (`part`, `boardText`, `lamp`, ...) and `studio/ZFight.lua`.
  - Every part is Plastic, with studs on the **top face only**.
  - Signs use `boardText` (PixelsPerStud scales with the board, LightInfluence 0).
- **QA tools:**
  - `studio/map_qa.luau` (installed as `ServerStorage.DevTools.MapQA`) reports floating, tipped, unanchored and
    z-fighting parts. It scans `World.ZoneN.Props` and `.Machines`.
  - `ZFight.lua` `scan(workspace.World)`.
  - **Both must report 0 when you finish.**
- **Layout:**
  - Zones run along **-Z**, and the floor top is **Y = 0**.
  - Zone 1 is about z 0 to -60, Zone 2 about -62 to -164, and Zone 3 about -166 to -284.
  - Rooms are 64 wide (x -32 to 32), with 24-tall ceilings (the Zone 3 arena is 34).
  - Breakable walls are a 32 x 20 face of **1-stud cubes**, `wallDepth` layers deep (5 / 6 / 7 per zone).
  - The deeper layers reach into the corridor behind the doorway.
- **Part count:** about **13.5k**, mostly wall cubes (3,200 + 3,840 + 4,480). StreamingEnabled is off.
  - Keep an eye on this.
  - If a change adds a lot of parts, say how many and why.
  - Decorative detail is cheaper as fewer, bigger parts.
- **Lighting is tuned and fragile:**
  - Ceiling SurfaceLights above about 0.4 brightness wash the floors white.
  - Cave lanterns above about 0.6 turn the whole cave orange.
  - Red beacons above about 0.5 turn the vault walls pink.
  - Change lighting carefully, and check it from first person.

## 4. Don't break these (the scripts depend on them)

The gameplay code lives in:

- `ServerScriptService.GameServer`
- the `StarterPlayerScripts` (`ToolsClient`, `HUD`, `FirstPersonArms`, `SettingsUI`, `ZoneMood`, `Audio`)
- `ReplicatedStorage.BTW` (`Config`, `WallGrid`, `ClientState`, `Remotes`, `Sounds`) and
  `ReplicatedStorage.Modules` (`ToyUI`, `Icons`)

Before you move or rename anything, **grep the `studio/` sources for the name** and check what reads it.

- `Workspace.World.ZoneN` folder names, and `BreakableWall` folders whose `Cube` parts carry the attributes `Zone`,
  `Hits` and `Value`.
  - The wall must stay on the **1-stud grid**.
  - `WallGrid` keys cubes in half studs, and the server's hole check expects a flat face of
    `WALL_CUBES` w x h, `wallDepth` deep.
  - If you move a wall, move its whole grid, and check that the checkpoint still fires.
- `Zone2.LeftTunnel.HiddenVein` (the `HiddenPassage` attribute).
- `Spawn_ZoneN` SpawnLocations. Only Zone 1 is Enabled at the start; a hole through a wall enables the next one.
- The placeholders' **`Function`** folders, which the scripts use:
  - `DepositMachine_Placeholder.Function.DepositZone` and `.CounterScreen`
  - `ToolPodium_Placeholder.Function.BuyZone`, which carries the BuyFist (E) and BuyVacuum (F) ProximityPrompts,
    and `.DisplayAnchor`
  - `UpgradeBoard_Placeholder.Function.Screen` and `.PromptPart`
  - `Boss_Placeholder.Function.Hitbox`, with `BossName` and `MaxHP`

  You can move, rotate, restyle or rebuild the **`Visual`** model freely; it's meant to be swapped for meshes.
  Keep the Function parts working.
- `Config.Zones[n].zMax` / `zMin` (ZoneMood and checkpoints) and `spawn`. If zone extents change, update Config.
- `ReplicatedStorage.ToolModels` (the vacuum and duster meshes).

## 5. Part one: get a feel for it (do this first, before changing anything)

1. `git pull`, then read the files in section 2. Check that Studio is connected and on the right place
   (`list_roblox_studios`).
2. Start Play and actually play it, in first person, with real input:
   - **Walk from spawn to the wall.** How far is it? What do you see first? Is it obvious what to do?
   - **Punch until cubes fall.** Use the Studio-only `ServerStorage.DevGiveMoney:Invoke(player, amount)` only once
     you've felt the real early game.
   - **Vacuum, fill storage, walk to the deposit machine, cash in.** How long is the round trip? Is the machine easy
     to find from the wall?
   - **Buy a tier at the podium.** Can you read the prompt?
   - **Break through Zone 1** (or use the money hook to speed up). Then walk into Zone 2, try both tunnels, find the
     hidden vein, and reach the ore wall. Then Zone 3 and the arena.
   - Testing tips:
     - Pin the camera with `RunService:BindToRenderStep("PinCam", Enum.RenderPriority.Camera.Value, ...)` for
       exact shots. At `+1` priority the arms vanish from the frame.
     - `user_mouse_input` y is in GUI space: screenshot y minus 58.
     - Aim at cube centres.
3. Take **first-person screenshots** along the way and save them to `ui/screenshots/feel/`:
   - spawn
   - the walk to the wall
   - mid-punch
   - the vacuum
   - the deposit
   - the podium
   - each zone's entrance
   - each tunnel
   - the arena
4. Write `docs/FEEL_NOTES.md`: an honest player's-eye review. Cover:
   - **First 60 seconds:** is the goal obvious? Is the wall the hero of the view?
   - **Walking distances:** wall to deposit to podium. Too far is boring, too close is cramped. Give numbers in
     studs and seconds.
   - **Sightlines:** from each spawn, can you see the wall, the deposit and the podium? Do props block anything?
   - **Scale in first person:** do rooms feel huge and empty, or tight? Do machines read at the right size?
   - **Each zone's identity and twist:** does Zone 2 actually feel like a maze? Does the hidden vein feel like a
     discovery or a chore? Does Zone 3 feel like a boss room?
   - **Transitions:** what does breaking through feel like? Is there a reward moment (reveal, light change, sound,
     sign)? Is the next zone's entrance exciting?
   - **Lighting and mood in each zone** from first person.
   - **Performance:** check the part count and frame rate.
   - **Versus the references:** compare with `references/original-game/` and `references/roblox-competitor/`. What
     does Sami's map do better (spawn rooms with machines, zone signs, a tidy compact layout)? What can we do
     better?
   - **The 10 changes that would most improve the map,** ranked.
5. **Stop and show me** the notes and the ranked list, with screenshots, before the big changes. Use the
   ask/next-step box. I'll say which to do. Small obvious fixes you can just do: a floating prop, an unreadable
   sign, a blocked sightline.

## 6. Part two: the map changes (after I've picked from your list)

Expect a lot of changes. Work like this:

- **Change the builder, not the live place.** Edit `studio/BuildWorld.lua`, install it, and rebuild the zone.
  Hand-edits in Studio get wiped the next time someone rebuilds.
  - If something is genuinely easier by hand, make it in code anyway, or write down exactly what you did in
    HANDOFF.md.
- **Phase order per zone:** layout, then room shells, then the breakable wall, then the spawn area and machines,
  then landmarks, then props, then lighting, then QA.
  - Block big shapes first and check them from first person before adding detail.
- **Map rules (from my playbook, adapted to this indoor game):**
  - **Scale:** the R15 avatar is about 5.2 tall. Doors and openings are at least 12 wide. Main routes are at least
    10 wide.
  - **One hero landmark per zone,** visible from the zone's entrance, about 1.5x taller than anything near it, with
    light and some motion. Never stacked boxes.
  - **No empty floor patch bigger than about 30x30.**
    - Props in clusters of 2-5, with small rotation and size jitter, against the walls.
    - Keep the route and the sightlines to the wall, the deposit and the podium clear.
  - **Props:** low props near machines. Mount lights on walls and pillars, not on posts in the walkway.
  - **Colour:** each zone keeps its STYLE_BIBLE palette and its **one** accent, with 2-3 shades per surface so
    nothing looks flat. Use saturated, darker neons (pale neon blows out to white). Never use near-white floors.
  - **Signs:** big, readable from about 30 studs, and checked **in Play** (Edit-mode captures don't render
    SurfaceGuis). Top-face text runs along the part's Z axis.
  - **No z-fighting:** parts meet edge to edge, never overlapping coplanar faces in different colours. Run ZFight
    after every builder change.
  - **Nothing floating, and nothing poking through walls.**
- **Ideas worth considering.** These are suggestions, not orders; your feel notes decide:
  - make breaking through a moment (light or colour change, a sign reveal, the next room's landmark framed in the
    hole)
  - tighten the walk between wall, deposit and podium
  - a more mazy, explorable Zone 2, with a second hidden passage
  - a Zone 3 arena that feels like a boss room (cover, walkways, the vault as a looming backdrop)
  - windows or glass looking ahead into the next zone, as a teaser
  - ambient motion (fans, conveyor belts, blinking screens)
  - better spawn rooms in the style of Sami's (machines in a tidy row, a big zone sign)
  - a clear Zone 4 teaser
- **Zone 3 is provisional.** You can redesign it more freely. Update its brief in `docs/ZONE_BRIEFS.md`, and keep
  it marked PROVISIONAL until I sign it off.
- **Models:**
  - Build part-built placeholders only, named `<Thing>_Placeholder`, with a `Visual` model and a `Function`
    folder.
  - **Don't run paid art** (Gemini, Meshy, OpenAI) unless I say so.
  - List models that might deserve a Meshy pass in HANDOFF.md.
- **After every zone you change:**
  - Play it in first person.
  - Make sure the core loop still works there: punch, vacuum, deposit, buy, and the checkpoint firing on
    break-through.
  - Run map_qa and ZFight (both 0).
  - Check the console is clean. The known DataStore line is fine, because "Studio Access to API Services" is off
    and that's mine to change.
  - Take screenshots.
- **Before calling it done:**
  - Run the **map-critic** agent (`.claude/agents/map-critic.md`, read-only) over all the zones and fix its punch
    list.
  - Re-run QA.
  - Take a final set of first-person screenshots to `ui/screenshots/map-pass/`.

## 7. Studio workflow and gotchas

- **Installing scripts:**
  - Serve the repo root with `python -m http.server 8796 --bind 127.0.0.1`. Port 8792 belongs to another
    project.
  - In `execute_luau`, set `HttpService.HttpEnabled = true` temporarily.
  - `GetAsync("http://127.0.0.1:8796/studio/<file>")`, then `ScriptEditorService:UpdateSourceAsync` (or `.Source`
    for DevTools modules).
  - Restore HttpEnabled.
  - `studio/` is the source of truth.
- **Stop Play before editing.** In `execute_luau`, **require a clone** of a module, never the live one (it may be
  cached).
- **Big builds can freeze Studio:** build one zone per `execute_luau` call, with `task.wait()` between chunks.
  Wrap each rebuild in a ChangeHistoryService recording.
- **Windows and Python:**
  - Git Bash heredocs break on some quotes, so write patch scripts as `.py` files.
  - Always use `encoding='utf-8'` when Python writes files (cp1252 once truncated a file mid-write).
  - Use raw strings for Windows paths.
- **Lighting:** `Lighting.Technology` can't be read or set from scripts. That's an owner step.

## 8. Keys, money and safety rules

- **All API keys live in `C:\Users\rmcd9\Desktop\IdleMedievalArt\api.txt`.** Never open, print, copy or commit it,
  and never put a key in a file or a message.
- **This pass shouldn't need any paid service.** If you think it does, ask first, and log every spend in
  `art/LEDGER.md`.
- **Never publish the game, never spend Robux, never change Studio security settings.** I do those.
- **Before every push,** grep the staged diff for key patterns (`sk-`, `AIza`, `msy_` and similar).

## 9. Finishing the session

1. Rewrite `HANDOFF.md` with:
   - what changed per zone, with exact Instance paths
   - the new part count
   - the QA results
   - Meshy candidates
   - owner steps
   - the next step
2. Add a dated entry at the top of `STATUS.md`. Update `docs/ZONE_BRIEFS.md` (and `docs/STYLE_BIBLE.md` if lighting
   or the palette changed), `ui/UI_PROGRESS.md`, and `TASKS.md`.
3. `git pull`, then commit (end the message with a Co-Authored-By line for the model you're running as), then push.
4. Tell me in plain words:
   - what you changed
   - what you checked in Play, and what you didn't
   - what I need to do (save the place in Studio, review Zone 3, anything else)

Talk to me in plain, short English. I type fast with typos; read the intent. If a choice is genuinely mine
(a redesign direction, anything that costs money), ask with options. Otherwise, use your judgement and keep going.
