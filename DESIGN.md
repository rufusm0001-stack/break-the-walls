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
- **Style:** bright stud/brick Roblox look. Voxels are real Parts, chunky and satisfying, with a pop and a shake on hit.
- **Tools (hotbar 1-3):** Fists → Hammer → Drill / Cannon. Vacuum is always slot 2.
- **HUD:** Money (top left, big), Storage bar, Energy bar, hotbar at the bottom centre, zone name at the top.
- **Upgrades:** keep the 3-tab tree idea (Digging / Collection / Automation), but as a proper Roblox UI panel.
- **Zones:** each broken-through wall opens the next room. Walls get tougher, with new block types (brick, metal,
  gold ore) that are worth more.
- **Prestige:** TODO, after zones are in.

## Open questions
- Energy or no energy? The original uses it; Sami's version doesn't seem to.
- Sell pad or deposit machine?
- Starting numbers: wall size, voxel HP, sell price.
