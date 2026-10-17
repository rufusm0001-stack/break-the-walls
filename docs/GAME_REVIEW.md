# Game review: Break the Walls (2026-10-17)

Played in Studio Play (placeId 104446080960521), first person, with real mouse and keyboard input, from a fresh
save ($0, bare fists, Basic vacuum). Rufus's Claude, main PC. Screenshots are in `ui/screenshots/review/`.

> **Short version:** the core verbs work and the world looks good, but **the game has no reason to spend money
> yet**. You can punch through all three walls with the starter fists in about 10 minutes, and the upgrades barely
> change anything. The biggest wins are balance gating, a real break-through moment, and per-hit juice.

## How the session went (timings)

My tool calls added latency, so the times below are **real-player estimates** worked out from measured rates
(cubes broken per 10 s of held LMB, walk distances at WalkSpeed 16, and deposit ticks).

| Moment | Estimate | Notes |
|---|---|---|
| Spawn to wall | ~4 s walk | The wall is dead ahead. The goal is obvious within 10 s. |
| First full storage (50) | ~25 s | Punching about 13 s gives ~50 cubes. Vacuuming 50 takes **under 1.5 s**. |
| First deposit | ~35 s | It pays $50 in under a second. |
| First purchase (Bronze, $100) | **~80-90 s** | Two trips. On target for "first upgrade in about a minute". |
| Zone 1 break-through | **~2.5-3 min** | About 200 cubes broken. A 5-tall gap was walkable **before the checkpoint fired** (bug 1). |
| Zone 2 break-through | ~2-3 min (model) | Not punched through in this session. Modelled from measured ore rates. |
| Zone 3 break-through | ~2-3 min (model) | I measured steel at 3.1 cubes/s **with Bronze**. The vault is easy with starter tools. |
| Whole game | **~10 min** | DESIGN.md wants about 10 minutes for **Zone 1 alone**. |

Measured rates: bare fists on stone, about 3.5-5 cubes/s on a fresh face, dropping to ~1.2/s once you tunnel into
your own hole (loose cubes clog it and the ring cells hit nothing). Bronze on steel: 3.1/s.

## 1. First 60 seconds and onboarding

- **Good:** you spawn facing the wall with a yellow-edged path leading to it. Deposit is on the left, the podium on
  the right, and the hotbar shows fist + vacuum. The verb is obvious, and the grid preview teaches the cross pattern
  at once (`02_wall-grid-preview.jpg`).
- **Confusing:**
  - **Nothing tells you to vacuum or deposit.** There's no objective line. The "FULL - DEPOSIT!" bar text is the
    only hint, and it appears after you've already filled up.
  - **The spawn camera looks down at the floor.** The ZONE 1 sign is cut off at the top of the screen
    (`01_spawn-first-view.jpg`).
  - **The UPGRADES board is behind you at spawn** and does nothing when you walk up to it. It promises a feature
    that isn't there.
  - **The podium shows a hammer,** but the hammer was dropped from the design. A new player expects to buy a hammer.

## 2. Core loop feel

**Punch: decent base, thin feedback.**
- Hold-to-punch at 0.35 s works. The grid preview, flash, chunk burst and camera kick are there.
- But **nothing pays out on the hit.** Sami shows `+$1` on every hit (`references/roblox-competitor/01`), and we
  show nothing until the deposit.
- **There's no damage state.** A cube that needs two hits looks identical after the first one.
- **Cubes are tiny on screen.** With 1-stud cubes, a 5-cell cross is a small plus in the middle of a 32x20 face.
  The original's Radius upgrade grows it into a big diamond of about 25 cells
  (`references/original-game/05`), and that's where the satisfying feel comes from.
- **Tunnelling kills the rate.** Once you're inside your own hole, the pattern centres on the deeper cube and loose
  cubes block the ray, so punches whiff with no feedback.

**Vacuum: fun swirl, but trivially fast.**
- The curved flights and wind trails are nice.
- But storage fills (0 to 50) in **under 1.5 s**, so the vacuum is a button press, not an activity. Storage is the
  only real limit.
- "FULL - DEPOSIT!" in red is clear (`04_vacuum-full-in-1s.jpg`).
- **The held vacuum covers about 35% of the screen.** It hides the deposit machine when you turn around
  (`05_look-back-vacuum-hides-deposit.jpg`).

**Deposit: functional, not a moment.**
- It pays in 10s every 0.15 s, so $50 lands in under a second.
- From first person, standing in the zone, **I couldn't see the +$ popups** at all. They spawn above the machine
  and you're standing inside it (`07_deposit-no-popups-visible.jpg`).
- No cubes visibly ride the conveyor (Sami has this, `references/roblox-competitor/04`).
- No cash sound stood out, and no coins fly to the money pill.

## 3. Pacing and balance

**Main finding: the walls don't gate on upgrades.**
- Bare fists break every zone's wall in roughly 1 minute of punching.
- Money buys convenience you don't need. There's no point where you **must** buy something to continue, and no
  point where an upgrade visibly changes the wall.
- **Bronze does nothing in Zone 1.** Stone has 1 HP, so bare fists already one-shot the centre cell. The ring takes
  0.5 bare and 0.75 with Bronze, and both need two hits. Your first purchase has no visible effect.
- Iron (x2) is the first tier that changes anything: ring cells one-shot.

**Earnings and tier prices (model from measured rates, `docs/balance_model.py`; EFF 0.45 matches the measured
rates):**

| Zone | Kit | Cubes/s | Trip (s) | $/trip | $/min | Break-through (punching only) |
|---|---|---|---|---|---|---|
| 1 | Bare fists + Basic (50) | 3.9 | 18 | $50 | $162 | 53 s (204 cubes) |
| 1 | Bronze + Turbo (75) | 5.8 | 19 | $75 | $239 | 35 s |
| 1 | Iron + Cyclone (100) | 6.4 | 22 | $100 | $275 | 32 s |
| 2 | Bronze + Turbo (75) | 3.9 | 31 | $225 | $436 | 63 s (245 cubes) |
| 2 | Iron + Cyclone (100) | 5.1 | 31 | $300 | $575 | 48 s |
| 2 | Gold + Mega (150) | 6.4 | 36 | $450 | $751 | 38 s |
| 3 | Iron + Cyclone (100) | 3.9 | 39 | $800 | $1,229 | 74 s (286 cubes) |
| 3 | Gold + Mega (150) | 5.8 | 40 | $1,200 | $1,809 | 49 s |
| 3 | Diamond + Titan (225) | 6.4 | 50 | $1,800 | $2,160 | 44 s |
| 3 | Energy + Vortex (350) | 6.4 | 71 | $2,800 | $2,356 | 44 s |

**Tier price against what you have when you get there:**

| Tier | Price | When a player can afford it | Needed? |
|---|---|---|---|
| Bronze | 100 | ~1.5 min (Zone 1) | No visible effect in Zone 1 |
| Turbo | 150 | ~2.5 min (Zone 1) | Nice |
| Iron | 400 | ~4 min, early Zone 2 | Biggest feel jump |
| Cyclone | 600 | Zone 2 | Nice |
| Gold | 1,500 | ~3 min into Zone 2 | No |
| Mega | 2,000 | Zone 2 / 3 | No |
| Diamond | 5,000 | ~3 min of Zone 3 grinding | No: the wall is already broken |
| Titan | 7,000 | Zone 3 grinding | No |
| Energy | 15,000 | ~7 min of Zone 3 grinding | No |
| Vortex | 20,000 | ~9 min of Zone 3 grinding | No |

- **Too fast:** the walls.
- **Too grindy for no reason:** tiers 4-5, which cost more than Zone 3 pays before you've left it.
- **Walk time dominates the Zone 2 and 3 trips:** about 10 s of walking against 15-20 s of punching. The ore wall is
  ~70 studs from the Zone 2 deposit.

## 4. Progression: is there always a goal?

- **Short-term:** fill storage, then deposit. Only implicit.
- **Mid-term:** the next tool tier. The podium prompts are hidden (bug 3), so you can't see the price unless you
  know to press E.
- **Long-term:** the next zone. Obvious, but it doesn't need money.
- **Missing:**
  - The upgrade book (Radius / Power / Depth, collection).
  - An on-screen objective.
  - A reason to stay after Zone 3: prestige, automation or Zone 4.
  - Anything social: the game is meant to be co-op, but there's no party, no shared goal and no leaderboard.

## 5. UI and HUD (against `docs/UI_RULES.md`)

- **Good:**
  - The money pill with the coin stack and the gear button are on-style.
  - The storage gauge's green to orange to red with ticks reads well.
  - The hotbar tier icons update.
  - The settings panel is clean (`20_settings.jpg`).
- **Problems:**
  - **Toasts are always green.** "NEED $X" should be red; the HUD ignores the colour argument the server sends.
  - There's no "storage full" feedback beyond the bar text: no flash, no sound, no arrow to the deposit.
  - There's no "you can afford X" hint.
  - There's no zone name or progress on the HUD. UI_RULES puts run progress at the top centre.
  - The hotbar slot labels "FISTS" / "VACUUM" appear on switch. That's fine.
  - **Phone viewport not checked** this session.

## 6. Audio

- Music plays (SoundService.Music at volume 0.5, scaled by the settings slider). Punch and vacuum sounds exist.
- **Missing:**
  - a distinct cube-break pop that scales with combo
  - a deposit cash register / coin cascade
  - a purchase fanfare
  - a "storage full" thunk
  - a break-through crash and fanfare
  - zone ambience (cave drips, vault alarm hum)

## 7. Map

- **Zone 1 Stone Facility:**
  - It's clear: the wall is straight ahead, and the room is dressed.
  - The ceiling light strips bloom pure white (`05`).
  - The ZONE 1 sign is clipped at the top of the spawn view.
  - The red alarm lights are a nice touch.
- **Zone 2 Mine Cave:**
  - The strongest identity: the big NOT EVERY ROOM IS STRAIGHT FORWARD sign with lanterns, the rails and the orange
    ore (`11_zone2-hub-sign.jpg`).
  - But the **ore chamber is dark and bare** (`12`): brown on brown with nothing on the floor.
  - The ore wall is far from the deposit.
  - **The hidden vein isn't hidden.** It's bright ore in a dead end with a "DEAD END..?" sign (`14`). That's
    friendly, but it's not a secret.
- **Zone 3 Security Vault:**
  - Great first sightline: the WARDEN ACTIVE gate frames the robot and the vault (`15`).
  - The vault wall in its red frame looks like a real landmark (`16`).
  - **The ZONE 3 sign over the gate is tiny white text on dark blue,** which is on the never-do list.
  - The boss is a static placeholder.
- **Transitions:** none. You walk through a hole in the wall and you're in the next room with no fanfare (bug 1).

## 8. Tools (models and icons)

- **Knuckles:** Energy looks great (`17`). Bronze reads as two flat red slabs, like oven mitts lying on the forearms
  (`09`). The dusters sit on the back of the hand, not the knuckles, from the camera's view.
- **Vacuums:**
  - Basic and Cyclone are colourful and fine (`19`), but huge on screen.
  - **Vortex looks bad:** dark, brown-grey, melted-looking Meshy mesh, and it covers half the screen (`18`). It
    doesn't match its icon. Rufus hates exactly this.
- **Pop-in:** the first time you equip a new tier, the model and its hotbar icon are blank for about 1 s while the
  asset loads.
- **Arms:** the avatar arms read as big black boxes at the bottom corners. Acceptable, but they take a lot of screen.

## 9. Performance

- 13,456 parts; StreamingEnabled is off.
- 60 fps idle; 60 fps while punching steel with Energy (worst frame 29 ms). No hitching seen on PC.
- Phones aren't tested. The wall cubes are most of the parts, so merging untouched back layers would be the first
  move if phones lag.

## 10. Bugs (with repro)

1. **You can walk through without the checkpoint.** Punch a ~5-wide x 5-tall hole through all 5 layers in Zone 1
   (`10_through-wall-no-checkpoint.jpg`). You fit through (avatar 5.2 tall), but `Config.Checkpoint` needs 4 x 6
   fully clear, so `Spawn_Zone2` stays disabled and no "ZONE 2 IS OPEN" fires.
   - Fix: also open the zone when a player's root crosses the wall's back plane.
2. **Toast colour is ignored.** Press E at the podium with $0: "NEED $100 FOR BRONZE KNUCKLES" shows green.
   `HUD.client.lua:309` drops the second argument.
3. **The podium prompts are invisible.** Both ProximityPrompts sit on `BuyZone`, which is inside the yellow counter
   at y=3, so the counter occludes their BillboardGuis.
   - In Play, standing 8 studs from the podium, no prompt shows on screen (`08_podium-prompts-hidden-hammer.jpg`),
     but E still buys.
   - The two prompts also stack on the same adornee.
4. **Tool pop-in:** see above. Fix: `ContentProvider:PreloadAsync` the ToolModels and icons at join.
5. **The preview vanishes inside a hole,** or hides behind loose cubes, so punches whiff with no feedback.
6. **Grid preview on orange ore:** the orange centre outline is invisible on orange cubes (`13`).
7. Minor: `StorageMax` only updates through `pushStats`. Setting `VacuumTier` by hand (tests) leaves the gauge at
   50. That's fine in real play.

## 11. Against the references

- **Sami does better:**
  - +$ on every hit
  - a big red arrow over the deposit machine
  - cubes visibly riding the deposit conveyor
  - a storage bar with a character icon, bottom-left
  - an "You can buy the Hammer!" affordability hint
  - a timed gold reward and a premium tool offer (retention and money)
- **The original does better:**
  - the Radius upgrade (a huge hit grid with a gradient: centre orange, edges white)
  - hidden rusty layers that need Depth
  - a 3-tab upgrade tree you open with TAB
- **Where we already win:**
  - the map identity per zone (the cave sign, the vault frame)
  - the vacuum swirl
  - the stud UI kit
  - tool tiers you can see on your own hands
- **Where we can beat both:**
  - a real break-through event
  - a stud upgrade book
  - co-op parties
  - zone twists (hidden vein, boss)

## 12. The 15 changes that would help most

Ranked by impact against effort. Size: S = under an hour, M = a few hours, L = a day or more.

| # | Change | Why | Size | Touches |
|---|---|---|---|---|
| 1 | **Gate walls on upgrades.** Per-zone cube HP that actually needs the next tiers, plus a minimum tool tier per zone ("Needs Iron Knuckles" shown on the wall), and rebalance prices to the table. | Money is pointless today, and the whole game takes 10 minutes. This is the incremental loop. | M | balance, gameplay, UI |
| 2 | **Break-through moment + checkpoint fix.** Open the zone when you walk through (bug 1), with a debris burst, screen flash, a ZONE N OPEN banner, a fanfare, and the next zone's sign lighting up. Server-wide for co-op. | It's the main goal and currently silent. | M | gameplay, UI, audio |
| 3 | **Stud upgrade book (Rufus's pick).** Two pages: Digging (Radius / Power / Depth) and Collection (storage, pickup range, deposit speed), with pips, BUY, and locked "???" tiers. | It's the missing mid-term goal. Radius is what makes punching feel big. | L | UI, gameplay, balance |
| 4 | **Per-hit juice.** Predicted +$ / +cube popups, crack overlays on damaged cubes, a pitch-rising break pop, a bigger burst on the last hit. | The first 10 seconds sell the game, and Sami has +$ on hits. | M | gameplay feel, audio |
| 5 | **Objective line, top centre (Rufus's HUD pick).** "Punch the wall", "Vacuum the cubes (2)", "Deposit at the machine", "Buy Bronze at TOOLS", "Break through!" Then the zone goal, plus a bobbing arrow to the deposit when storage is full. | Onboarding, and there's always a goal on screen. | M | UI |
| 6 | **Podium fix.** Move the prompts above the counter, one per side; put the next-tier knuckles and vacuum models on display (spinning) instead of the hammer; add a "You can afford Iron Knuckles!" toast. | Bug 3. Players can't see what's for sale. | S-M | map, UI |
| 7 | **Deposit moment.** Cubes fly from you onto the conveyor and ride it, the counter screen rolls up, a coin cascade flies to the money pill, a cash sound plays, and popups sit at eye level. | It's the payoff of every trip. | M | feel, UI, audio |
| 8 | **Trip balance.** Storage gets a real cap that the vacuum fills over about 3-5 s, not 1 s. Shorter walks in Zones 2 and 3 (a deposit chute near each wall). Loose cubes stop clogging tunnels (they slide out or despawn into storage when you're close). | Walking dominates later trips, and tunnelling stalls. | S-M | balance, map |
| 9 | **Viewmodel pass.** A smaller, lower vacuum (about 20% of the screen); dusters on the knuckles, not lying flat on the arm; remake Vortex (Claude Design or Blender, not Meshy); thinner arms. | You stare at this the whole game. | M | art |
| 10 | **Small fixes:** red toasts (bug 2), preloading (bug 4), a high-contrast preview on orange (bug 6), and a preview shown on the deeper cube when aiming into a hole (bug 5). | Outright bugs. | S | UI, gameplay |
| 11 | **Sign and lighting pass.** Raise the spawn camera pitch and lower the ZONE 1 sign into view; make the ZONE 3 sign big 3D text; dim the ceiling strips that bloom white; light and dress the Zone 2 ore chamber. | First-person readability. | S-M | map |
| 12 | **Zone 3 Warden fight.** A simple 3-phase boss (punch its weak plates, dodge a laser sweep), which then drops a cube burst and opens the vault. | Zone 3's twist is missing. | L | gameplay, art, audio |
| 13 | **Loading screen (approved).** Dark drifting dots, a hand-drawn title with a crack, a TIP line, and a thin bar. | First impression; it's already designed. | M | UI |
| 14 | **Third-person tool welds.** Other players see your dusters and vacuum. | Co-op: showing off tiers is a reason to buy. | S-M | gameplay, art |
| 15 | **Leaderboard + endgame hook.** An in-world "Walls broken / Money" board at spawn, plus a teaser for prestige or Zone 4. | A reason to come back after 10 minutes. | M | UI, gameplay |

**Later (bigger) items:**
- the co-op lobby place with party pads (needs publishing to test teleport)
- automation robots
- prestige
- Zone 4+
- Robux products (design only)

## Obvious small fixes (safe to just do)
- Bug 2: red toasts for errors.
- Bug 3: podium prompts visible.
- Bug 4: preload the tool models.
- Bug 6: grid preview contrast in Zone 2.
- Bug 1: the walk-through checkpoint. Small code, but it changes when zones unlock, so it ships with #2.
