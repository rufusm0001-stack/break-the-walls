# Style Bible: indoor stud-built test facility

Reference: Sami's Roblox clip (x.com/samiYT13/status/2110715573823066543, frames in `references/roblox-competitor/`).
The game is an indoor, stud-built test facility: cool grey tread floors, blue-grey and darker grey wall panels,
yellow and black hazard stripes, chunky stud cubes for the breakable walls, and **one** small bright accent per room.
Cartoony shapes, but **not** green, grassy or purple. The skill's colour and lighting defaults (`applyCartoonLighting`,
the grass/purple palette) **don't apply** to this game.

## Never
- Purple or pink ambient light, grass, or outdoor parks.
- Near-white floors (they glare). The lightest floor is `#B8BEC8`.
- Pure black or pure white surfaces.
- Realistic textures (wood grain, rust, concrete PBR). Everything is Plastic with studs on top faces.
- Thin or spindly shapes. Keep everything chunky.
- The trademarked toy-brick brand name anywhere.

## Facility palette (shared by every zone)
| Use | Hex |
|---|---|
| Floor tile, light / dark (checker) | `#B8BEC8` / `#8E99A8` |
| Wall panels | `#6B7280` |
| Wall panel trim / pillars | `#565C68` |
| Ceiling | `#4A505C` |
| Hazard stripes | `#FFC627` / `#1E1E24` |
| Door / window frames | `#FFC627` |
| Dark metal (machines, vents) | `#3A3F4B` |
| Screens (Neon, saturated) | `#1FA7E0` |
| UI outline / text stroke | `#1E1E24` |

## Breakable cubes
- 2-stud cubes, Plastic, studs on top. Each zone mixes 2-3 shades of its rock so the wall never looks flat.
- Zone 1 stone `#C7CBD4` / `#A8ADB8`. Zone 2 orange ore `#E07A2E` / `#F2A04A` in cave rock `#7A5A45`.
  Zone 3 is in `docs/ZONE_BRIEFS.md`.

## Per-zone accent (one each)
| Zone | Accent |
|---|---|
| 1 Stone Facility | green `#3FD45B` (zone sign, deposit machine lights), plus a red alarm light and a plant |
| 2 Mine Cave | lantern amber `#FFB000` |
| 3 Security Vault | alarm red `#E5322D` (provisional) |

## Lighting (neutral and cool)
- Ambient (148,152,160), OutdoorAmbient (128,132,140). Never purple. (Tuned in Studio: indoors, more ambient washes the floor white.)
- Brightness 1, ClockTime 13, ColorShift_Top `#DCE0E6`, EnvironmentDiffuseScale 0.25, EnvironmentSpecularScale 0.2.
- ColorCorrection: brightness 0, contrast 0.15, saturation 0.05, white tint.
- No Atmosphere, Bloom, DepthOfField or SunRays. Fog is a cool grey `#9AA0AA`, starting at 200 and ending at 600.
- Rooms are lit by ceiling light strips (Neon `#E8ECF2` panels with SurfaceLights, kept off the floor colour) and by
  the zone accent. Ceiling SurfaceLights stay dim (brightness about 0.3, range 20): at 1.3 the floor rendered white. Zone 2 is warmer with its lanterns, but never dark.
- **Owner step:** set `Lighting.Technology` to ShadowMap by hand. Scripts can't set it.

## Building with parts
- Use `studio/StudKit.lua` `part()` for every world part: Plastic, studs on TOP only, smooth sides.
- Grid: room shells on a 4-stud grid; props and cubes on a 2-stud grid.
- Parts meet edge to edge. Never overlap coplanar faces in different colours (z-fighting). Run `studio/ZFight.lua`
  after every builder.
- Signs: `StudKit.boardText` on a 3D board with a darker 1-stud trim. Check them in Play.

## Scale (the R15 avatar is about 5.2 tall; the game is first person)
- Rooms: walls 24 tall up to the ceiling. Doors and openings at least 12 wide.
- Breakable wall: 32 wide x 20 tall (16 x 10 cubes).
- Machines: about 8-10 tall, so they read from first person without filling the screen.
