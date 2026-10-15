# Handoff: where the last agent left off

> Rewrite this whole file at the end of every session, so it always shows the **current** state. The history goes in `STATUS.md`.

**Last updated:** 2026-10-15
**By:** Rufus's Claude (device: main PC)

## What was done
- **The core loop works in Play:** punch, then the cubes drop, then vacuum, then deposit, then money goes up.
  It's server-authoritative, and every number is in `ReplicatedStorage.BTW.Config`.
  - **Fists (slot 1):** click or hold LMB.
    - The server takes the cube under the crosshair and applies `Config.Patterns.cross5`: the centre takes full
      damage and the ring takes half.
    - Damage builds up against each cube's `Hits` attribute (`Damage` attribute). Cracked cubes darken toward
      `#3A3F4B`.
    - The client draws a grid preview (orange centre, white ring) on the face under the crosshair. It also
      predicts the flash, the shake and the break, and puts the cube back after 1 s if the server rejects it.
    - The server checks: equipped slot, cooldown (×0.85 slack), range (`Fists.range` + 3 from the cube centre),
      that the face points at the player, and line of sight (adjacent wall cubes are allowed).
  - **Loose cubes:** `Workspace.Loose`, created by the server and owned by the server, collision group "Loose"
    (doesn't collide with "Players").
    - They carry `Count` and `Value`.
    - Past `Config.Loose.maxCount` (200), a new drop merges into a loose cube within 6 studs. If none is that
      close, the oldest one is recycled.
  - **Vacuum (slot 2):** hold LMB. The client sends the camera look vector about every 0.15 s.
    - The server pulls loose cubes inside the cone (`Vacuum.range` / `coneDot`) and collects them within
      `collectRadius`, up to `Config.Storage.start` (50).
  - **Deposit:** standing in any zone's `DepositMachine_Placeholder.Function.DepositZone` pays the stored Value in
    batches of 10 every 0.15 s, with +$ BillboardGui popups.
  - **Money:** `leaderstats.Money` (IntValue). Storage is shown through the player attributes `StorageCount` and
    `StorageMax`.
- **Checkpoints:** when a zone's `BreakableWall` has a hole 2 wide x 3 tall that goes through both layers and starts
  in the bottom 2 rows (`Config.Checkpoint`), the server enables `Spawn_Zone(N+1)` and toasts everyone.
  - A player who walks into an open zone gets it saved as their checkpoint and `RespawnLocation`.
  - `Players.CharacterAutoLoads` is now **false**: GameServer loads the character after the data loads, so the
    first spawn is already at the right checkpoint.
  - Tested in Play: breaking through Zone 1 enabled Spawn_Zone2.
- **Saving:** DataStore `BTW_Player_v1`, key `u_<UserId>`. It holds `{ money, checkpoint, storageCount, storageValue }`.
  - It loads with 3 retries, saves with UpdateAsync on leave, autosaves every 60 s, and saves in BindToClose.
  - If the load fails, it never saves over that player's data.
  - **Not verified yet:** this Studio session has API access off, so GetAsync fails. See Owner steps.
- **HUD** (`StarterPlayerScripts.HUD`, ToyUI only):
  - Money pill, top right (counts up).
  - Storage bar, bottom centre (turns red with "FULL - DEPOSIT!").
  - A 2-slot hotbar, with a gold selector and ViewportFrame icons of the real held models (no emoji or letters).
  - Also: an equip name tag, a centre crosshair dot (its own inset-free ScreenGui), and toasts.
- **FirstPersonArms:** the jab now fires only on a real punch (`ClientState.Jab`). The right hand holds a part-built
  Vacuum when slot 2 is equipped; it shakes and its mouth spins while sucking.
- **Verified in Play** (screenshots in `ui/screenshots/core-loop/`):
  - punched a walk-through hole in Zone 1, then Spawn_Zone2 was enabled
  - vacuumed 12 cubes, giving 12/50
  - deposited, with +$10 popups and money going up
  - a punch fired from the client at a Zone 3 cube far out of range was ignored
  - Console: no script errors. The only lines are the DataStore access line and its follow-up print.

## Exact state (Instance paths)
- `ReplicatedStorage.BTW`:
  - `Config`: added `Fists.slot`/`range`, `Patterns`, `Vacuum`, `Loose`, `Deposit`, `Checkpoint` and `Save`
  - `WallGrid`: shared cube key/index/pattern maths
  - `ClientState`: client-only equip, vacuuming and Jab state
  - `Remotes`: created at runtime by GameServer. They are `Punch`, `Vacuum`, `Equip`, `DepositPaid` and `Toast`.
- `ReplicatedStorage.Modules`:
  - `ToyUI` (from `studio/ToyUI.lua`)
  - `Icons`, with `StudTile = rbxassetid://126732731360060`, uploaded free via upload_image
- `ServerScriptService.GameServer`
- `StarterPlayerScripts`: `ToolsClient`, `HUD`, `FirstPersonArms` (updated), and `ZoneMood` (untouched)
- The source of everything is in `studio/` under the same names (`*.server.lua` and `*.client.lua`).
  - Install: serve the repo root on port 8796, then `GetAsync` + `ScriptEditorService:UpdateSourceAsync`.
  - Note that the URL is `/studio/<file>`.
- Zone 2's `LeftTunnel.HiddenVein` cubes have `Hits`, so they're punchable too.
- The old kit files `studio/HUDClient.lua`, `HotbarClient.lua`, `CartClient.lua` and `DiamondClient.lua` belong to
  the coal game. They're **not** installed and not used.

## Owner steps
- **Turn on Game Settings → Security → "Enable Studio Access to API Services"**, so DataStore saving can be tested
  in Studio. I didn't change a security setting.
  - Then in Play: earn money, Stop, Play again, and the money should still be there.
  - Until then the console shows one engine line, `StudioAccessToApisNotAllowed`.
- From before, still open:
  - set `Lighting.Technology` to ShadowMap
  - set Avatar to R15
  - review the Zone 3 brief
  - pick the Meshy candidates
- **Save the place.** Nothing was published, and nothing was saved to Roblox.

## Next step (start here)
1. **Verify saving** once API access is on (above).
2. **Upgrade board** (`UpgradeBoard_Placeholder`): the Digging tab first, with Radius, Power and Depth at
   `Config.FirstUpgradeCosts`. The pattern code is ready for it: `WallGrid.cells` takes any pattern name, and
   damage is a multiplier.
3. **Tool podium + Hammer** (`Config.Hammer`, pattern `cross9`, already defined).
   - Slot 3 in the hotbar.
   - Add the model to `FirstPersonArms` the same way as the Vacuum.
4. Wall regen or reset per server: right now broken walls stay broken until the server restarts.
5. A Zone 3 boss gate, so the wall only opens after the Warden. GameServer doesn't gate it yet.

## Watch out for
- **Serve on port 8796** (8792 belongs to another project): `python -m http.server 8796 --bind 127.0.0.1` from the
  repo root. Turn `HttpEnabled` on for the fetch, then restore it.
- **The vacuum is fast** (pullSpeed 38, collect radius 3.5). A screenshot taken mid-pull is hard to time; hold LMB
  for only about 150 ms.
- **Punch preview on recessed cubes:** when you aim into a hole, the ring cells of the back layer sit behind
  front-layer cubes and are hidden. That's correct (they still take damage).
- **Testing from MCP:** pin the camera with `BindToRenderStep("PinCam", Camera priority)`, look at a target point,
  then use `user_mouse_input` (hold) for real input.
