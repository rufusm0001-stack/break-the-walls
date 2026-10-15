# Design notes

## Reference
- **Original:** *Escape the Walls* by Pandorio (Unity, Steam page coming soon). Gameplay clips are on X at
  x.com/pandorioltd/status/2110335569255657628 and x.com/pandorioltd/status/2108549714282983605.
  Frames are in `references/original-game/`.
- **Roblox competitor:** Sami's version (x.com/samiYT13/status/2110715573823066543) is already on Roblox. Frames are in
  `references/roblox-competitor/`. Learn from it, and beat it on feel and UI.
- **Our place:** "Break The Walls", placeId **104446080960521**.

## Core loop (from the original)
1. You're trapped in a room. The walls are made of **voxels** (small cubes on a grid).
2. **Punch** the wall (Fists tool). A punch hits a cross-shaped pattern of voxels around the aim point. The grid
   preview shows which voxels the punch will take: orange for the centre / most damage, white for the edge.
3. Each punch costs **Energy** (bar at the bottom left, 100 max, refills over time).
4. Broken voxels fall to the floor as loose cubes.
5. Switch to the **Vacuum** (hold LMB) to suck up the loose cubes. The HUD counts **Voxels** carried.
6. Stand on the **sell pad** and press E to sell your voxels for **Money**.
7. Press TAB to spend Money in the upgrade tree. Break through deeper layers (darker/rusty blocks show up behind the
   front layer) and escape.

## Upgrade tree (from the original, TAB menu, 3 tabs)
- **Digging:** Radius I-III (+1 voxel), Hit Power I-III (+25% base damage), Depth I-III (+1 voxel deep).
  Costs are 50 / 150 / 400. Leads to Energy (capacity and recovery) and Digging Tools (new ways to break blocks).
- **Collection:** Collection Area, Pickup Radius I-II, Bag Capacity, Capacity I-II, Collection Tools, Improved /
  Powerful Collector, Tool Slot 3 (300).
- **Automation:** Digger Robot (Hit Power, Speed), Collector Robot (Collection Capacity, Speed).
- Node states: Buy / Purchased (green) / Not enough money / Locked / Coming Soon.

## What the Roblox competitor added
- A **Storage** bar (0/100) instead of a plain voxel count, so carry capacity is part of the economy.
- **+$1 popups** on every hit. That makes punching feel like it pays out straight away.
- A **Deposit machine** (a conveyor you dump voxels into) and a **Research Points** machine.
- Tools are bought at **podiums** in the room ("Tools are sold here!"), with a toast when you can afford one:
  "You can buy the Hammer!"
- Rooms are **zones** ("ZONE 1" over the wall), plus a timed gold reward (bottom right) and a premium tool offer
  (CANNON, Robux) at the top right.

## Our version: Roblox theme, better feel
- **Style:** colourful stud/brick toy style (we follow the `roblox-stud-game` playbook). Cubes are real Parts that
  pop and shake when hit.
- **Tools (hotbar):** 1 Fists, 2 Vacuum. Both upgrade in tiers at the tool podium (decided 2026-10-15, the Hammer is dropped):
  Fists → Bronze / Iron / Gold / Diamond / Energy **knuckle dusters** worn on the avatar's own hands, and Vacuum → Basic / Turbo / Mega / Vortex.
  Drones and excavators come later (automation); no minecart yet. Prompts are in `art/MESHY_PROMPTS.md`.
- **HUD:** Money (top left), Storage bar, hotbar at the bottom centre, zone name at the top. There is **no energy bar**.
- **Upgrades:** the 3-tab tree (Digging / Collection / Automation) as a proper toy-style panel.
- **Prestige:** TODO, after zones 1-3 are in.

## Decisions (settled 2026-10-15)
| Question | Decision |
|----------|----------|
| Energy | **None.** You can punch as fast as the tool cooldown allows. Speed comes from tool and cooldown upgrades instead. |
| Selling | **Deposit machine.** Walk up and dump your storage into a conveyor machine, and +$ popups fly out. It can be upgraded later (auto-deposit, multiplier). |
| Payout | **Money only on deposit.** Hits just break cubes. This keeps the vacuum and storage meaningful. |
| Pacing | **Fast start.** First upgrade in about 1 minute, Zone 1 cleared in about 10 minutes. |
| Structure | **Sections like the Roblox version.** Each section has its own spawn area (deposit machine, tool podium, upgrade board) and its own rock type and theme twist. |

## Starting numbers (Zone 1, all in the Config module)
| Value | Start |
|-------|-------|
| Cube size | 2 studs |
| Zone 1 wall | 16 wide x 10 tall x 2 deep cubes (32 x 20 studs) |
| Hits per cube (Fists) | 2 |
| Punch cooldown | 0.35 s |
| Punch pattern | cross of 5 cubes (centre takes full damage, the ring takes half) |
| Cube value | $1 (stone) |
| Storage | 50 cubes |
| First upgrades | $50 / $150 / $400 (Radius, Power, Depth), like the original |
| Knuckle dusters (tier 1) | replaces the Hammer: price and damage to balance (Config.Hammer numbers are the placeholder) |

## Sections / zones
Every section = **spawn area** (safe room: deposit machine, tool podium, upgrade board, zone sign) → **the wall
area** → the way into the next section. Each section has a new rock type that's worth more, a new palette, and a
twist.

| # | Theme | Rock | Twist |
|---|-------|------|-------|
| 1 | Stone facility, the starter room | Grey stone ($1) | Straight forward: break through the one wall in front of you. A tutorial. |
| 2 | **Mine cave** | **Orange ore blocks** ($3) | **Not straight forward.** A sign at the entrance reads "Not every room is straight forward". The cave splits left and right, with dead ends and hidden paths, and players have to find the way through. |
| 3 | TBD | TBD | **Boss room:** a boss you fight before the wall opens. |
| 4+ | TBD | Each harder and worth more | Mix: maze rooms, boss rooms, timed walls, hidden layers (like the rusty layer in the original). |

**Bosses (some sections):** an arena room, with a boss you hit with the same tools. When it's beaten it drops a big
cube burst and opens the path. Design them once zones 1-2 work.

## Still open
- Themes for zones 3+ and the first boss.
- Prestige rules.
- Robux items (the competitor sells a premium Cannon). Decide later; the owner handles anything that costs Robux.
