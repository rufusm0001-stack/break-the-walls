# Handoff: where the last agent left off

> Rewrite this whole file at the end of every session, so it always shows the **current** state. The history goes in `STATUS.md`.

**Last updated:** 2026-10-15
**By:** Rufus's Claude (device: main PC)

## What was done
- **Zones 1, 2 and 3 are built** in Studio, all from code (`studio/BuildWorld.lua`). It's an indoor stud test facility in the
  `docs/STYLE_BIBLE.md` palette (rewritten for this game; the skill's colour defaults don't apply).
  - **Zone 1, Stone Facility:** spawn hall, a 16x10x2 stone wall, deposit machine, tool podium, upgrade board, and a ZONE 1 sign.
  - **Zone 2, Mine Cave:** the hub, with the landmark sign "NOT EVERY ROOM IS STRAIGHT FORWARD", then two tunnels.
    - Right tunnel: open, leading to the chamber with the orange ore wall.
    - Left tunnel: looks like a dead end, but has a small hidden ore vein (`HiddenPassage` attribute). Breaking it
      opens a crawl-through into the chamber.
    - Also: mine supports, lanterns, rails and a cart.
  - **Zone 3, Security Vault: PROVISIONAL.** Its brief is in `docs/ZONE_BRIEFS.md` and needs your review.
    - Spawn hall, then a red gate ("WARDEN ACTIVE"), then a round arena with `Boss_Placeholder` (the Warden).
    - The reinforced steel vault wall sits in a red vault frame (the landmark). The exit corridor ends at a
      "ZONE 4 - COMING SOON" sign.
- **First person:** `StarterPlayer.CameraMode = LockFirstPerson`. `StarterPlayerScripts.FirstPersonArms` draws blocky
  viewmodel arms (grey sleeves, tan cuffs, dark gloves), with a bob and a visual-only click jab.
- **Config:** `ReplicatedStorage.BTW.Config` holds the cube values, hits, storage, costs and zone bounds.
  `StarterPlayerScripts.ZoneMood` warms the colour correction in Zone 2.
- **Lighting:** neutral and cool, tuned in Studio. The values are in STYLE_BIBLE, and the reasons are commented in
  `B.lighting()`.
- **Settings:** StreamingEnabled is off. The Baseplate and default SpawnLocation were moved to ServerStorage, not
  deleted.
- **Verified:**
  - In Play, first-person screenshots of every zone are in `ui/screenshots/world/`.
  - `map_qa.luau`: floating 0, corner-hanging 0, tipped 0, zfight 0. `ZFight.lua` scan: 0.
  - Console: clean.
  - The map-critic ran and its verdict was "fix first". All 9 punch-list items were fixed and checked in Play,
    except the tool in hand (there are no tools yet).

## Exact state (Instance paths)
- `Workspace.World.Zone1|Zone2|Zone3`, each with:
  - `Shell` rooms (`SpawnHall`, `Hub`, `Chamber`, `Arena`, corridors)
  - `BreakableWall`, whose `Cube` parts carry the attributes `Zone`, `Hits` and `Value`
  - `Machines`, `Props`, `WallDecor`, `Lights`
  - `Spawn_ZoneN`: only Zone 1 is Enabled; Zones 2 and 3 are disabled checkpoints
- Zone 2 extras: `World.Zone2.LeftTunnel.HiddenVein`, `Rails`, `Supports`, `TunnelSigns`.
- Placeholders. Each one keeps its swappable `Visual` model separate from the `Function` folder that scripts use:
  - `DepositMachine_Placeholder`: `Function.DepositZone`, `Function.CounterScreen`
  - `ToolPodium_Placeholder`: `Function.BuyZone`, `Function.DisplayAnchor`
  - `UpgradeBoard_Placeholder`: `Function.Screen`, `Function.PromptPart`
  - `Zone3.Machines.Boss_Placeholder`: `Function.Hitbox`, with the attributes `BossName` and `MaxHP`
  - `Zone2.Props.MineCart_Placeholder`
- Dev tools: `ServerStorage.DevTools` holds `StudKit`, `ZFight`, `BuildWorld` and `MapQA`.
- To rebuild (Edit mode), call `B.init(StudKit, Config)`, then `B.lighting()`, then `B.zone1()`, `B.zone2()` and
  `B.zone3()`. Each zone rebuilds cleanly on its own; the folder is replaced.

## Meshy candidates (NOT generated; owner to check first)
No paid art was run. Placeholders that might be worth a Meshy model, most valuable first:
1. **DepositMachine**: the Zone 1 landmark, with one reskin per zone (facility, mine-wood, vault).
2. **Boss (the Warden)**: the security robot, 12-14 tall. It needs a rig later if it animates.
3. **ToolPodium**: the pedestal, plus a **Hammer** display model (the hammer is also needed as a held tool).
4. **MineCart** (Zone 2). Keep it part-built if it must show an ore fill level.
5. **VaultFrame emblem** (Zone 3): a round vault door.

Small props (crates, barrels, server racks, plants) are fine as parts.

## Owner steps
- **Set `Lighting.Technology` to ShadowMap by hand.** Scripts can't set it.
- **Set Avatar type to R15** in Game Settings → Avatar. I couldn't confirm it from a script.
- **Review the Zone 3 brief** (`docs/ZONE_BRIEFS.md`, PROVISIONAL), then sign it off or change it.
- **Pick the Meshy candidates** above. Nothing has been spent.
- **Save the place.** Nothing was published, and I didn't save to Roblox.

## Next step (start here)
1. **Core loop scripts:**
   - Fists punch, damaging cubes per `Config.Fists` (the cross5 pattern), with the grid preview
   - cubes falling as loose pickups
   - the Vacuum
   - storage
   - the deposit machine paying `Value`
   - money
   Server-authoritative; the client only predicts hits.
2. HUD with `studio/ToyUI.lua` (money, storage bar, hotbar). See `ui/UI_PROGRESS.md`.
3. Zone unlocks: break a wall to enable the next `Spawn_ZoneN` checkpoint.

## Watch out for
- Builder pipeline: serve `studio/` with `python -m http.server 8796 --bind 127.0.0.1` (8792 belongs to another
  project), set `HttpEnabled` on for the fetch, then turn it off again.
- On this PC, Python writes need `encoding='utf-8'`. Heredocs with tricky quotes fail in Git Bash, so write a .py
  file instead.
- Lighting gotcha: ceiling SurfaceLights above about 0.4 brightness wash the floor to white. Lanterns above about
  0.6 turn the whole cave orange.
