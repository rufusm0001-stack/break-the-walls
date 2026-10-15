# Status log

## 2026-10-15 (Rufus's Claude, main PC): UI icons
- Made 15 icons with Gemini after the top-up (about $0.62): coin, gear, mouse, music, speaker, 6 fist tiers and 4 vacuum tiers. They're cut from magenta, uploaded with upload_image, and wired into the money pill, gear, settings rows and hotbar (tier-aware). Checked in Play.

## 2026-10-15 (Rufus's Claude, main PC): feel pass: avatar arms, sounds, settings, vacuum swirl
- Arms are now your own avatar's R15 arms (cloned meshes and shirt, x1.1, angled in from the bottom corners). There's no cursor or crosshair now.
- Punching got chunk bursts, dust and a camera kick. Loose cubes are smaller (0.6).
- The vacuum now claims cubes, and every client flies them along curved paths with white wind trails into the nozzle.
- Added sounds and an APM music playlist (BTW.Sounds), plus a gear button and a Settings panel (sensitivity, music, SFX), saved with the player's data. M opens it, and Left Alt frees the mouse.
- Design: the Hammer is dropped. The tools are now knuckle-duster tiers and vacuum tiers (art/MESHY_PROMPTS.md).
- Gemini icon generation is blocked (HTTP 402, prepaid credit used up). Nothing was spent. The script is ready (art/gen_icons.py).

## 2026-10-15 (Rufus's Claude, main PC): core loop + minimal HUD
- Added the server-authoritative core loop. Fists punch with cross5 and a grid preview, broken cubes drop as capped loose cubes, the Vacuum stores them, the deposit machine pays out with +$ popups, and Money is in leaderstats. Saving uses DataStore and is Studio-safe.
- When a wall has a passable hole, the next Spawn_ZoneN is enabled and becomes the player's checkpoint. Added a ToyUI HUD (money, storage bar, 2-slot hotbar). FirstPersonArms now jabs on real punches and holds a part-built Vacuum.
- Verified in Play: broke through Zone 1 (Spawn_Zone2 opened), vacuumed to 12/50, deposited (+$10 popups, money up), and an out-of-range exploit punch was ignored. Screenshots are in ui/screenshots/core-loop/.
- Saving is NOT verified yet: Studio API access is off (an owner step in HANDOFF.md). Nothing was published, and no art was paid for. The stud tile upload was free.

## 2026-10-15 (Rufus's Claude, main PC): Zones 1-3 built
- Rewrote docs/STYLE_BIBLE.md for this game: an indoor stud facility, neutral and cool lighting. Added the palette and first-person rules to AGENTS.md, and wrote the Zone 3 brief (PROVISIONAL).
- Built Zones 1-3 from code (studio/BuildWorld.lua): rooms, breakable cube walls (984 cubes), spawn areas, deposit machines, tool podiums, upgrade boards, signs, props, and a placeholder Boss. Added ReplicatedStorage.BTW.Config, FirstPersonArms and ZoneMood.
- QA: map_qa 0 / ZFight 0 / console clean. The map-critic punch list (9 items) is fixed and checked in Play. Screenshots are in ui/screenshots/world/.
- No paid art was run, and nothing was published. The Meshy candidates and owner steps are in HANDOFF.md.

## 2026-10-15 (Rufus, main PC): design decisions
- Settled: no energy, a deposit machine, pay on deposit, a fast start, and sections with their own spawn area and a twist each (Zone 2 = a mine-cave maze, boss rooms later).
- Adopted the roblox-stud-game playbook. The kit is copied into studio/, art/, docs/ and .claude/agents/. Drafted docs/ZONE_BRIEFS.md (awaiting sign-off).

## 2026-10-15 (Rufus, main PC): references
- Watched the 2 original clips (Escape the Walls) and Sami's Roblox clip. Saved 16 frames to references/ and wrote the mechanics and upgrade tree into DESIGN.md. Place: 104446080960521.

## 2026-10-15 (Rufus, main PC)
- Added the handoff system for working across 3 devices and accounts: HANDOFF.md, ui/UI_PROGRESS.md, ui/screenshots/, references/, and task claiming in TASKS.md.
- Created the repo with a README, CLAUDE.md, DESIGN.md and TASKS.md. No game code yet.
