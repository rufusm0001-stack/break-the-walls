# Handoff: where the last agent left off

> Rewrite this whole file at the end of every session, so it always shows the **current** state. The history goes in `STATUS.md`.

**Last updated:** 2026-10-15 (second pass: feel)
**By:** Rufus's Claude (device: main PC)

## What works in Play
**Core loop:** punch, loose cubes, vacuum, deposit, money. It's all server-authoritative, and every number is in
`ReplicatedStorage.BTW.Config`.

### Fists (slot 1): click or hold LMB
- The pattern is cross5: the centre takes full damage and the ring takes half, counted against each cube's `Hits`.
- The grid preview shows the orange centre and white ring. There's **no cursor or crosshair**: the preview is the aim.
- The server checks the equipped slot, the cooldown, the range, that the face points at the player, and line of
  sight.
- Feel:
  - a jab on the real punch
  - a punch sound and a dust puff
  - a camera kick
  - on a break, 7 bouncing chunks, a crack sound and a bigger kick
- The client predicts the break and restores the cube after 1 s if the server rejects it.

### Loose cubes
- `Workspace.Loose`, 0.6 studs, capped at 200 with merging.

### Vacuum (slot 2): hold LMB
- The server **claims** each cube in the cone: it anchors the cube and stamps `SuckedBy`, `SuckStart` and
  `SuckDur`, reserving storage space.
- Every client flies claimed cubes along a curved path (a sideways swing, a hop, a wobble and spin, shrinking) with a
  white Trail, into the nozzle. For the local player that's the real viewmodel mouth, `ClientState.nozzle`.
- The server banks the cube when the flight ends. While sucking, wind-streak particles show and the suction sound
  loops.

### Deposit, money and checkpoints
- **Deposit:** `DepositMachine_Placeholder.Function.DepositZone` pays in batches, with +$ popups and a cash sound.
- **Money:** `leaderstats.Money`.
- **Checkpoints:** a 2x3 hole through the wall enables `Spawn_Zone(N+1)`, and that zone becomes your respawn point
  once you walk into it.

### Arms
- **Your own avatar's arms:** `FirstPersonArms` clones your R15 `UpperArm`, `LowerArm` and `Hand` with your Shirt and
  BodyColors. A Humanoid inside `Camera.ViewModel` applies the shirt.
- Scale 1.1, coming in from the bottom corners and angled in.
- Pose numbers are in `POSE`, and you can tune them live in Play by setting the same-named attribute on
  `Camera.ViewModel` (x, y, z, pitch, yaw, roll, vacYaw).
- R6 falls back to blocky arms. Knuckle dusters will attach to `RightHand` / `LeftHand`.

### Audio (`StarterPlayerScripts.Audio`, ids in `ReplicatedStorage.BTW.Sounds`)
- Effects: punch x2, crack, pop (collect), a suction loop, a cash ding and a UI click.
- A shuffled APM music playlist of 4 tracks.
- Pro Sound Effects and APM audio is licensed by Roblox. The punch, pop, cash and click sounds are free Creator Store
  uploads.

### Settings (`StarterPlayerScripts.SettingsUI`)
- The gear sits top right, with the money pill to its left. Key **M** opens it.
- Sliders: mouse sensitivity (`UserInputService.MouseDeltaSensitivity`, default **0.45**), music and SFX.
- Values are saved with the player's data (`settings` in the DataStore) through `Remotes.Settings`, and echoed back
  as the player attributes `Set_*`.
- Hold **Left Alt** (or open the panel) to free the mouse; a visible Modal button does it.

### Verified in Play (screenshots in `ui/screenshots/core-loop/`)
- arms, the break burst, the vacuum swirl trails and the settings panel
- dragging a slider changed the server's `Set_sensitivity` to 0.27
- all 9 sounds report IsLoaded = true, and the music plays
- console: no script errors

## Art
- **Gemini is blocked: HTTP 402, prepaid credit used up.** No icons were made, and $0 was spent (logged).
  - Once Rufus tops up at ai.studio, run `python art/gen_icons.py` and it makes all 15 icons:
    - coin, gear, speaker, music, mouse
    - fist_0 to fist_5 (bare, bronze, iron, gold, diamond, energy knuckles)
    - vacuum_0 to vacuum_3
  - About $0.60. The raw images go to `Desktop\Break The Walls\icons\raw`. The cut 256px PNGs go to `icons\cut` and
    to `art/icons/`.
  - The key is read inside the script and never printed.
- **Uploading:**
  - The Studio MCP `upload_image` works with no key (the stud tile went up that way).
  - The Open Cloud key in api.txt had no scopes the last time it was checked, so it needs the
    **Assets API read + write** permission before Open Cloud imports will work.
- **Meshy:** Rufus is running it himself. The prompts are in `art/MESHY_PROMPTS.md`: 5 knuckle dusters, 4 vacuums,
  the deposit machine, the podium and the Warden.

## Exact state (Instance paths)
- `ReplicatedStorage.BTW`:
  - `Config`: new `Vacuum.minFlight`/`maxFlight`/`swirl`, `Loose.size` 0.6, and `Settings`
  - `WallGrid`
  - `ClientState`: `menuOpen`, `nozzle`, `shake`/`kick()`, `Sfx`
  - `Sounds`
  - `Remotes`: Punch, Vacuum, Equip, DepositPaid, Toast, and the new **Settings**
- `ReplicatedStorage.Modules`: `ToyUI`, `Icons` (StudTile)
- `ServerScriptService.GameServer`
- `StarterPlayerScripts`: `ToolsClient`, `HUD`, `SettingsUI` (new), `Audio` (new), `FirstPersonArms` (rewritten),
  `ZoneMood`
- Every source is in `studio/` under the same names. Install: serve the repo root on port **8796**, then `GetAsync`
  `/studio/<file>` + `ScriptEditorService:UpdateSourceAsync`.

## Owner steps
- **Turn on Game Settings → Security → "Enable Studio Access to API Services"**, so DataStore saving can be tested.
  I didn't change it; it's a security setting. Then:
  - earn money and change a setting
  - Stop, then Play again
  - both should still be there
- **Top up Gemini** (or say to use OpenAI instead) for the icons.
- **Meshy models:** knuckle dusters and vacuums first.
- From before, still open:
  - `Lighting.Technology` = ShadowMap
  - Avatar R15
  - review Zone 3
  - save the place

Nothing was published and no Robux was spent.

## Next step (start here)
1. Icons, once Gemini is topped up. Then put the coin on the money pill, the fist and vacuum icons on the hotbar,
   and the gear icon on the gear (replacing the 3D placeholders).
2. Swap the placeholder vacuum for `Vacuum_Basic` and add the knuckle models on the hand.
3. Tool podium shop: knuckle tiers and vacuum tiers (add `Config.Knuckles` and `Config.Vacuums` tier tables).
4. Upgrade board (Digging: Radius, Power, Depth).
5. Map pass, last: deeper walls, maybe smaller wall cubes. That's Rufus's call, see below.

## Watch out for
- **"Blocks too big":** this pass shrank the **loose** cubes (0.9 to 0.6) and made breaks burst into chunks.
  - The **wall** cubes are still 2 studs.
  - Shrinking them is a map rebuild: 1-stud cubes would be 4x the parts per layer.
  - Rufus said the map comes last, so ask before doing it.
- **MCP testing:**
  - `user_mouse_input` coordinates are in GUI space; the screenshot includes the 58 px top inset, so subtract 58
    from a y read off a screenshot.
  - Pin the camera with `BindToRenderStep("PinCam", Camera priority)`.
- **The punch aim on a cube seam** splits damage between the two cubes. Aim at cube centres when testing.
- **The player list** (leaderstats) shows top right in a live game and may overlap the gear and money pill.
  Check it in a real client.
- **Git Bash heredocs:** they break on some quotes on this PC. Write patch scripts to `$TMP/*.py` instead.
