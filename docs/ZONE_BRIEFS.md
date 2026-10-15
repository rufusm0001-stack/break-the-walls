# Zone briefs (Zones 1-2 signed off 2026-10-15; Zone 3 PROVISIONAL)

Sizes are in studs. The R15 avatar is about 5.2 tall. Every world part is Plastic, with studs on top faces only. Each
zone has **one** accent colour and **one** landmark you can see from its entrance.

## Layout of every section
- **Spawn area:** about 60 x 40, a safe room. From spawn you can see the deposit machine (left), the tool podium
  (right), the upgrade board (back wall) and the breakable wall straight ahead, with the zone sign above it.
- **Main floor path:** 10 wide, from spawn to the wall, in the zone's path colour.
- **Room walls:** 24 tall up to the ceiling (raised from 16 so the 20-tall breakable wall fits). The breakable wall is 32 wide x 20 tall (16 x 10 cubes of 2 studs).

## Zone 1: Stone Facility (the starter)
| | |
|---|---|
| Room walls | `#6B7280` panels, pillars `#565C68`, a hazard trim band in `#FFC627` / `#1E1E24` stripes (palette from STYLE_BIBLE) |
| Floor | checker tiles `#B8BEC8` / `#8E99A8` |
| Path | hazard-edged walkway `#8E99A8` with yellow edge lines |
| Breakable cubes | stone `#C7CBD4` (light) with darker `#A8ADB8` cubes mixed in, about 30%, so it doesn't look flat |
| Accent | green `#3FD45B` (zone sign, deposit machine lights, +$ text) |
| Lamps | yellow wall strips, head `#FFE27A`, light `#FFF1C4` |
| Landmark | **the deposit machine**: a big conveyor with green neon side strips, cubes riding up it, and a $ counter screen. About 10 tall. |
| Props | crates, a potted plant, wall screens and vents, repeated in clusters along the side walls |
| Sign | "ZONE 1" in 3D green letters above the breakable wall |

## Zone 2: Mine Cave (twist: not every room is straight forward)
| | |
|---|---|
| Room walls | rough cave rock `#6B4B3A`, darker `#553A2D`, with wooden mine supports (beams `#8B5A2B`) every 10 studs |
| Floor | packed dirt `#8A6A4F`, plus a mine-cart rail line (rails `#9AA0A8`, sleepers `#6E4A26`) |
| Path | `#A07C55` |
| Breakable cubes | **orange ore** `#E07A2E` with flecks `#F2A04A`, set in cave rock `#7A5A45` |
| Accent | lantern amber `#FFB000` |
| Lamps | hanging lanterns, head `#FFB000`, warm light `#FFC46B` |
| Landmark | **a big wooden sign on posts** at the cave entrance reading "NOT EVERY ROOM IS STRAIGHT FORWARD", lit by 2 lanterns |
| Layout twist | The cave splits into **left and right tunnels**. One leads on and the other is a dead end, with some ore as a consolation. Some walls hide side passages. Players have to explore to find the way through. |
| Props | mine carts, pickaxe racks, barrels, crystal clusters in orange |
| Mood | warmer ColorCorrection and light fog (`ZoneMood`) |

## Zone 3: Security Vault (PROVISIONAL: built as a placeholder, needs the owner's review)
| | |
|---|---|
| Twist | **Boss room.** A blocky security robot (the "Warden") guards the vault. Beat it, then break the reinforced vault wall. |
| Room walls | the facility panels `#6B7280`, with steel-blue armour plates `#4E6A8A` and red alarm strips |
| Floor | dark checker `#8E99A8` / `#6F7A8A`, with a red-striped arena ring |
| Breakable cubes | **reinforced steel** `#9FB4C8` / `#7F95AB`, with bolt cubes `#5E6E80`. Worth $8, 4 Fists hits. |
| Accent | alarm red `#E5322D` (rotating alarm beacons, the arena ring, the vault door frame) |
| Lamps | ceiling strips, plus red alarm beacons on the pillars |
| Landmark | **the vault door frame** around the breakable wall: a thick red-and-steel frame with a round vault-door emblem on top, about 26 tall |
| Layout | spawn area (deposit, podium, upgrade board) → gate → **round arena** (radius 28) with `Boss_Placeholder` in the middle → the vault wall at the far end |
| Props | server racks, security cameras, steel crates, a warning sign: "WARDEN ACTIVE" |

## Zone 4+ (to design)
- Mix the twists: maze rooms, boss rooms, timed walls, hidden layers.
