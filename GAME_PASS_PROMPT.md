# Whole-game pass: starting prompt for a new chat (copy everything below the line)

---

You're joining **Break The Walls**, a Roblox game I'm making (I'm Rufus). Your job this session is the **whole
game**: gameplay, feel, balance, progression, tools, UI and HUD, audio, the map, and polish.

Work in two halves:

1. **Get a real feel for the game.** Play it start to finish like a new player, then write an honest review.
2. **Make lots of changes** across the whole game, from the list we agree on.

You have a lot of freedom. But other code depends on certain names, numbers and remotes, so read "Don't break
these" before changing anything. Read this whole prompt first, then the repo files it points to.

## 1. What the game is

- **What it's based on:** a Roblox remake of Pandorio's Steam game *Escape the Walls* (Unity, Steam page coming
  soon), with a Roblox stud-brick look and a far nicer UI.
  - Frames from the original are in `references/original-game/`. Its upgrade tree has three tabs:
    - **Digging:** Radius / Hit Power / Depth.
    - **Collection:** pickup radius, bag capacity, collectors.
    - **Automation:** digger and collector robots.
  - A rival Roblox version by "Sami" is already live; its frames are in `references/roblox-competitor/`. It has a
    storage bar, +$ popups on every hit, a deposit machine, tool podiums with "You can buy the Hammer!" toasts,
    zone signs, a timed gold reward and a Robux cannon.
  - **We copy mechanics, not names or art,** and we want to beat Sami on feel, juice, UI and map.
- **The core loop:**
  1. Trapped in a room whose wall is made of small cubes.
  2. **Punch** it (LMB, cross-shaped pattern, with a grid preview).
  3. Broken cubes drop as loose pickups.
  4. **Vacuum** them (slot 2, hold LMB) into your **storage**.
  5. Stand in the **deposit machine** to cash in for **money**.
  6. Buy better **knuckle dusters** (damage) and **vacuums** (storage and range) at the **tool podium**.
  7. Punch a hole through the wall, and the next zone opens and becomes your checkpoint.
- **First person** (LockFirstPerson). You see your own avatar's R15 arms, with Blender-made dusters on the fists
  and a Meshy vacuum in the right hand. **Judge everything from the first-person view**, because that's all players
  ever see.
- **Settled design (don't reopen these):**
  - no energy bar
  - money only on deposit
  - a fast start (first upgrade in about a minute)
  - each zone has its own spawn area with a deposit machine, a tool podium and an upgrade board
  - each zone has its own twist
- **Zones:**
  - **Zone 1, Stone Facility:** the tutorial. A straight room with the wall dead ahead.
  - **Zone 2, Mine Cave:** "Not every room is straight forward". A hub with a big sign, then two tunnels. The right
    tunnel leads to the chamber with the orange ore wall. The left looks like a dead end but hides a breakable ore
    vein that opens a shortcut.
  - **Zone 3, Security Vault: PROVISIONAL.** A "WARDEN ACTIVE" gate, then a round arena with a placeholder boss
    robot (no fight yet), then a steel vault wall in a red frame, then a "ZONE 4 - COMING SOON" sign.
- **Tools today:**
  - **Knuckles:** Bronze, Iron, Gold, Diamond, Energy. Damage x1.5 / 2 / 3 / 4.5 / 6.
  - **Vacuums:** Basic, Turbo, Cyclone, Mega, Titan, Vortex. Storage 50 to 350, range 18 to 32.
  - Both are bought at the podium: E buys knuckles, F buys a vacuum.
  - The prices are a first guess.
- **Not built yet** (candidates for this session or later; your review decides the order):
  - the **upgrade board** (Radius / Power / Depth, plus collection upgrades)
  - the **Zone 3 boss fight**
  - third-person tool welds (others can't see your tools yet)
  - the next tier on display on the podium
  - a proper zone-unlock moment
  - automation (drones / excavators)
  - Zone 4 and up (maze rooms, boss rooms, timed walls, hidden layers)
  - prestige
  - quests / onboarding
  - leaderboards
  - Robux products (design only; I do anything that costs Robux)

## 2. Where everything is

- **Repo:** `C:\Users\rmcd9\BreakTheWalls`, on GitHub as **rufusm0001-stack/break-the-walls** (private).
  - Three people on three devices share it.
  - **`git pull` first and push at the end.**
  - The git identity is per repo, and there's no `gh` CLI, so use plain git.
- **Roblox place:** "Break The Walls", placeId **104446080960521**, driven through the **Roblox Studio MCP**. Check
  with `list_roblox_studios` that you're on the right place.
- **Art folder:** `C:\Users\rmcd9\Desktop\Break The Walls\` (icons, Meshy packs, Blender exports).
- **Read these in the repo, in this order:**
  1. `HANDOFF.md`: the exact current state, every system, and the latest notes. If it disagrees with this prompt,
     **HANDOFF wins**.
  2. `AGENTS.md` and `CLAUDE.md`: the hard rules.
  3. `DESIGN.md`: the spec and the settled decisions.
  4. `docs/STYLE_BIBLE.md` (palette, lighting, building rules), `docs/ZONE_BRIEFS.md` and `docs/UI_RULES.md`.
  5. `ui/UI_PROGRESS.md`, `STATUS.md` (newest first), `TASKS.md`, `NEXT_PROMPT.md` (the last job list, all done),
     `START_PROMPT.md` (general onboarding), and `art/MESHY_PROMPTS.md` / `art/LEDGER.md`.
- **Skills:**
  - `roblox-stud-game` gives you the method, kit and lessons. Read its `references/LESSONS_GAMEHUB.md` and its UI
    references.
  - `roblox-game` is my general Roblox brain (an Obsidian vault). Use it for UI, monetisation, progression,
    performance and level-design research.
  - **This game's palette and lighting come only from `docs/STYLE_BIBLE.md`.** The skills' grass, purple and
    cartoony defaults don't apply.
- **Ignore my other games entirely:** GameHub / "Good Games Only", Idle Medieval, the coal mining game, Escape
  Verity, the Orsted cave.
  - `studio/` still has leftover kit files from other games that aren't used here: `CartClient.lua`,
    `DiamondClient.lua`, `HUDClient.lua`, `HotbarClient.lua`, `WorldSpin.client.lua`, `TerrainToStuds.lua`.
  - Grep before trusting any of them. Delete them from the repo if nothing uses them.

## 3. How the game is built (the code map)

All source is in `studio/`, which is the source of truth. Edit there, then install into Studio.

| Where in Studio | File | What it does |
|---|---|---|
| `ServerScriptService.GameServer` | `GameServer.server.lua` | Server-authoritative. Punch validation (range, cooldown, line of sight), damage with `fistMul`, loose cubes (capped and merged), the vacuum claiming cubes plus banking, deposit payouts, `leaderstats.Money`, the tool shop (BuyFist / BuyVacuum prompts), checkpoints (hole through a wall enables the next `Spawn_ZoneN`), and DataStore saving (money, checkpoint, storage, tiers, settings). Has the Studio-only `ServerStorage.DevGiveMoney` hook. |
| `StarterPlayerScripts.ToolsClient` | `ToolsClient.client.lua` | Punch input, the grid preview, hit prediction, chunk bursts, and vacuum input with curved, swirling cube flights and trails. |
| `StarterPlayerScripts.FirstPersonArms` | `FirstPersonArms.client.lua` | Your avatar's R15 arms in first person, the duster and vacuum models by tier, punch jabs, the vacuum shake and wind. The pose is tunable live through attributes on `Camera.ViewModel`. |
| `StarterPlayerScripts.HUD` | `HUD.client.lua` | Money pill with coin icon, the storage gauge, the 2-slot hotbar with tier icons, the centre dot, toasts, and podium prompt labels. |
| `StarterPlayerScripts.SettingsUI` | `SettingsUI.client.lua` | Gear button (M): aim sensitivity, music and SFX sliders. Left Alt frees the mouse. |
| `StarterPlayerScripts.Audio` | `Audio.client.lua` | Sound effects and the music playlist. |
| `StarterPlayerScripts.ZoneMood` | `ZoneMood.client.lua` | Per-zone colour-correction and fog tint. |
| `ReplicatedStorage.BTW.Config` | `Config.lua` | **Every tunable number:** cube size, wall size and depth, fists, patterns, the vacuum, storage, knuckle and vacuum tiers, loose cubes, deposit, checkpoint, save, settings, zones. |
| `ReplicatedStorage.BTW.WallGrid` | `WallGrid.lua` | Wall cube lookup in half-stud keys, and `q()` snapping. |
| `ReplicatedStorage.BTW.ClientState`, `Sounds`, `Remotes` | `ClientState.lua`, `Sounds.lua` | Shared client state (Jab event, equipped, vacuuming, nozzle), sound ids, and remotes. |
| `ReplicatedStorage.Modules.ToyUI`, `Icons` | `ToyUI.lua`, `Icons.lua` | The UI kit (slab, face, rim, studs, Fredoka text with a hard shadow) and the uploaded icon ids. |
| `ReplicatedStorage.ToolModels` | (assets) | `Knuckles_<Tier>`, `Vacuum_<Tier>`. |
| `ServerStorage.DevTools` | `BuildWorld.lua`, `StudKit.lua`, `ZFight.lua`, `map_qa.luau` | The map builder (`B.init`, `B.lighting`, `B.zone1/2/3`, `B.rebuildWalls(n)`) and the QA tools. |

**The world:**

- Zones run along **-Z**, and the floor is at Y = 0.
- Rooms are 64 wide, with ceilings at 24 (the arena is 34).
- Each zone's breakable wall is a 32 x 20 face of **1-stud cubes**, `wallDepth` 5 / 6 / 7 deep.
- About **13.5k parts**, mostly wall cubes. StreamingEnabled is off.
- Placeholders keep a swappable **`Visual`** model separate from a **`Function`** folder that the scripts use.

## 4. Don't break these

Before you rename or move anything, **grep `studio/` for the name** and see what reads it.

- **Remotes and attributes** that the server and clients share: the names in `Remotes`, plus the player attributes
  `FistTier`, `VacuumTier` and `StorageMax`, and the cube attributes `Zone`, `Hits` and `Value`.
  - If you change a remote's arguments, change both ends and validate on the server.
  - **Never trust client amounts.**
- **The save schema** (`Config.Save.store = "BTW_Player_v1"`).
  - Adding fields is fine, with defaults for old saves.
  - Renaming or removing fields breaks existing saves: migrate them, or bump the store version on purpose and say so.
- **The wall grid:** 1-stud cubes in a flat `WALL_CUBES` w x h face, `wallDepth` deep. `WallGrid` and the
  checkpoint hole check depend on it. If you move a wall, move its whole grid, and check that the checkpoint still
  fires.
- `Workspace.World.ZoneN` names, `BreakableWall`, `Zone2.LeftTunnel.HiddenVein`, and `Spawn_ZoneN` (only Zone 1
  is Enabled at the start).
- **Function parts:**
  - `DepositMachine_Placeholder.Function.DepositZone` / `CounterScreen`
  - `ToolPodium_Placeholder.Function.BuyZone` (with its prompts) / `DisplayAnchor`
  - `UpgradeBoard_Placeholder.Function.Screen` / `PromptPart`
  - `Boss_Placeholder.Function.Hitbox`
- `Config.Zones[n].zMax` / `zMin` / `spawn`.
- **Anything another session is working on.** Check `TASKS.md` and claim your work there, then push straight away.

## 5. Part one: play it and write the review (do this before big changes)

1. `git pull`. Read the files in section 2. Install nothing yet; look at what's live.
2. **Play it properly**, in first person, with real input (`user_mouse_input` / `user_keyboard_input`). Feel the
   real early game **before** using `ServerStorage.DevGiveMoney`.
   - Spawn, then walk to the wall. Is the goal obvious within 10 seconds?
   - Punch. Does it feel **satisfying**? Think about hit feedback: sound, shake, chunks, the grid preview, how fast
     cubes break, the cooldown.
   - Vacuum. Is sucking cubes fun? Is the storage limit felt? Is it clear when you're full?
   - Deposit. Is the payout a moment (popups, sound, the counter)? Is it easy to find from the wall?
   - Podium. Can you read the prompts? Is buying a tier a moment? Do you see your new tool?
   - **Break through Zone 1.** How long did it take? How many trips? Does breaking through feel like an event?
   - Zone 2: both tunnels, the hidden vein, the ore wall. Zone 3: the arena and the vault.
   - Settings, music, sensitivity, the HUD at 1280x720, and in a phone-sized window if you can.
   - **Testing tips:**
     - Pin the camera with `RunService:BindToRenderStep("PinCam", Enum.RenderPriority.Camera.Value, ...)`. At
       `+1` the arms vanish.
     - Mouse y is in GUI space: screenshot y minus 58.
     - Aim at cube centres.
3. **Time it.**
   - Seconds to the first deposit, to the first purchase, and to each break-through.
   - Money per minute in each zone.
   - Price of each tier against what you can earn by then.
4. Take **first-person screenshots** of every moment above and save them to `ui/screenshots/review/`.
5. Write **`docs/GAME_REVIEW.md`**, an honest player's-eye review:
   - **First 60 seconds and onboarding:** what's confusing?
   - **Core loop feel:** punch, vacuum, deposit. What's juicy and what's flat?
   - **Pacing and balance,** with your timings and a table of tier prices against earnings per zone. Where is it
     too grindy or too fast?
   - **Progression:** what do I want next at each point? Is there always a goal on screen? What's missing (the
     upgrade board, quests, automation, prestige)?
   - **UI and HUD:** clarity, size, style against `docs/UI_RULES.md`, toasts, prompts, and feedback for "storage
     full" / "can't afford" / "zone open".
   - **Audio:** missing sounds, volume balance, music fit.
   - **Map:** distances, sightlines, scale in first person, each zone's identity and twist, transitions, lighting,
     landmarks.
   - **Tools:** do the models and icons read well? Does each tier feel like an upgrade?
   - **Performance:** part count, frame rate, any hitching when walls break.
   - **Bugs** you hit, with repro steps.
   - **Against the references:** what Sami's version or the original does better, and what we can beat.
   - **The 15 changes that would most improve the game,** ranked by impact against effort, with a size estimate
     (S / M / L) and what each touches (gameplay / balance / UI / audio / map / art).
6. **Stop and show me** the review and the ranked list, with screenshots, using the ask/next-step box. I'll pick.
   - Obvious small fixes (an outright bug, an unreadable label, a floating prop) you can just do. List them.

## 6. Part two: make the changes (after I pick)

Expect lots of changes across the game. How to work:

- **Gameplay and balance:**
  - All numbers live in `Config`. Change numbers there, never as magic numbers in scripts.
  - Keep the server authoritative.
  - After every balance change, re-time the early game and update the table in `GAME_REVIEW.md`.
- **Feel / juice:** make hits, breaks, the vacuum, deposits, purchases and break-throughs feel great.
  - Client prediction for instant feedback, with the server deciding the outcome.
  - Screen shake, flashes, popups, sounds, particles, the counter rolling up.
  - Keep it readable; don't drown the screen.
- **UI:**
  - Build it only with `ToyUI`, following `docs/UI_RULES.md`.
  - No emoji, and no letters standing in for icons.
  - Size budget at 1280x720: money pill about 192x48, bars about 300x36, hotbar slot 60, body text 14-18.
  - Phones scale x1.7. Check desktop and phone width.
  - Run the `ui-critic` agent (`.claude/agents/ui-critic.md`) on new screens.
- **Map:**
  - Change `studio/BuildWorld.lua` and rebuild. Never hand-edit the live map; the next rebuild wipes it.
  - Phase order per zone: layout, then shells, then the wall, then the spawn area and machines, then landmarks,
    then props, then lighting, then QA.
  - Rules:
    - One hero landmark per zone, visible from the entrance.
    - Routes at least 10 wide, openings at least 12 wide.
    - No empty floor patch over about 30x30. Props in clusters of 2-5 against the walls.
    - Clear sightlines to the wall, the deposit and the podium.
    - Signs readable from about 30 studs, and checked **in Play**.
    - Saturated, darker neons. Never near-white floors.
    - No z-fighting, nothing floating.
  - **Lighting is fragile:**
    - Ceiling SurfaceLights above about 0.4 wash floors white.
    - Cave lanterns above about 0.6 turn everything orange.
    - Red beacons above about 0.5 go pink.
  - Run `map_qa` and `ZFight` after every map change; both must be 0.
  - Run the `map-critic` agent at the end and fix its list.
- **Part count:** report it after map or wall changes. If phones might struggle, propose StreamingEnabled or
  merging the untouched back layers of the walls.
- **Zone 3 is provisional:** redesign it freely, and keep its brief marked PROVISIONAL until I sign it off.
- **Art:**
  - Part-built placeholders only, named `<Thing>_Placeholder`, with `Visual` + `Function`.
  - No paid art without asking: Gemini icons cost about $0.04 each, Meshy is mine to run, and OpenAI is a fallback
    only.
  - If art would really help, ask with a cost and log it in `art/LEDGER.md`.
  - List Meshy candidates in HANDOFF.md.
- **After each chunk of work:**
  - Play it in first person and check the whole loop still works: punch, vacuum, deposit, buy, break through.
  - Clean console. The known DataStore line is fine: Studio API access is off, and that setting is mine.
  - Screenshots.
  - Commit with a clear message. Small, frequent commits are better than one giant one.

## 7. Studio workflow and gotchas

- **Install scripts:**
  - Serve the repo root with `python -m http.server 8796 --bind 127.0.0.1`. Port 8792 belongs to another project.
  - In `execute_luau`, set `HttpService.HttpEnabled = true`.
  - `GetAsync("http://127.0.0.1:8796/studio/<file>")`, then `ScriptEditorService:UpdateSourceAsync` (or `.Source`
    for small DevTools modules).
  - Restore HttpEnabled.
- **Stop Play before editing.** Require a **clone** of modules in `execute_luau`, because the live one may be
  cached.
- **Big builds freeze Studio:** one zone per call, `task.wait()` between chunks, ChangeHistoryService recordings.
- **On this PC:**
  - Git Bash heredocs break on quotes and backslashes, so write patch scripts as `.py` files.
  - Python file writes need `encoding='utf-8'` (cp1252 once truncated a file mid-write).
  - Use raw strings for Windows paths.
- **Owner-only settings:** `Lighting.Technology` (scripts can't touch it) and Studio security settings.
- **`ToyUI.bar`'s gradient** is tinted with the starting fill colour; neutralise it if you change the fill
  colour later.
- **The icon scripts' `--vivid` passes** overwrite `raw/` in place; back it up first.

## 8. Keys, money and safety

- **All API keys live in `C:\Users\rmcd9\Desktop\IdleMedievalArt\api.txt`.** Never open, print, copy or commit it,
  and never put a key in a file or a message. The art scripts read it themselves.
  - A Roblox key line was partly printed into a log once; I'm regenerating it. Don't repeat that.
- **Never publish the game, never spend Robux, never change Studio security settings.** I do those.
- **Before every push,** grep the staged diff for key patterns (`sk-`, `AIza`, `msy_`, `api_key =`).
- **Never mutate another player's save.** Test saving with Studio-safe code paths only.

## 9. Finishing the session

1. Rewrite `HANDOFF.md`: everything that changed (per system, with exact Instance paths), part count, QA results,
   balance table, Meshy candidates, owner steps, and the **next step**.
2. Add a dated entry at the top of `STATUS.md`. Update `DESIGN.md` for any design changes I approved,
   `docs/ZONE_BRIEFS.md` / `STYLE_BIBLE.md` / `UI_RULES.md` if they changed, `ui/UI_PROGRESS.md`, and `TASKS.md`.
3. If there's clearly more to do, write a fresh `NEXT_PROMPT.md` job list for the next chat.
4. `git pull`, then commit (end the message with a Co-Authored-By line for the model you're running as), then push.
5. Tell me in plain words:
   - what changed
   - what you checked in Play, and what you didn't
   - what I need to do (save the place in Studio, review Zone 3, turn on Studio API access to test saving, anything
     else)

Talk to me in plain, short English. I type fast with typos; read the intent. When a choice is genuinely mine
(design direction, anything that costs money or Robux, big redesigns), ask with options. Otherwise use your
judgement and keep going.
