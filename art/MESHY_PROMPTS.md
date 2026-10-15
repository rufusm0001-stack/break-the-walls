# Meshy prompts: Break The Walls

The tool line is **Fists → Knuckle Dusters (5 tiers)** plus **Vacuum (6 tiers: Basic, Turbo, Cyclone, Mega, Titan,
Vortex)**. The Hammer is dropped.

**Ready-made packs (2026-10-15):** `Desktop\Break The Walls\meshy\Vacuum_<Tier>\` each hold `icon.png`, four
reference views (`view_left`, `view_right` (mirrored left), `view_front`, `view_three_quarter`) and `prompt.txt`
with the Meshy multi-image prompt and settings. Made by `art/gen_meshy_packs.py` (Gemini edits of the icons).

**Knuckle dusters are NOT a Meshy job any more:** they're built in Blender to fit the R15 hand exactly
(`art/blender/knuckles.py` writes `Desktop\Break The Walls\blender\Knuckles_<Tier>.fbx` + `knuckles_spec.txt`).
The rule either way: the duster sits **on the knuckles** (the punching end of the hand), never the wrist.
Drones and excavators come later, and the minecart waits.

**Settings for every job** (from the stud-game playbook):
- Text-to-3D (or image-to-3D if a reference PNG exists), art style "cartoon" / stylised.
- **Polycount 6k-10k** for held tools, 16-20k for machines. Low polycounts came out melted; the credits are the same.
- Texture on, PBR off (we restyle to Plastic/SmoothPlastic in Studio).
- Export **FBX**. Import with File → Import 3D. It lands in the inventory; then `insert_asset` it into
  `ServerStorage.MeshyImports`.
- Name the export exactly as the **Name** column, so scripts can find it.

Shared style line, appended to every prompt:
> chunky blocky Roblox game style, simple bold shapes, smooth glossy plastic, bright saturated colours, clean flat
> colour regions, no realistic detail, no text, no logos, single object, centred

## Knuckle dusters
Built in Blender (see above). The old Meshy prompts are in git history if they're ever needed.

## Vacuums (held in the right hand, nozzle pointing forward; about 3 studs long in game)
Pistol grip underneath, nozzle forward. Upload all four views from the pack folder (multi-image to 3D).

| Name | Tier | Prompt |
|---|---|---|
| `Vacuum_Basic` | 1 | Basic: a cobalt-blue body, a yellow flared nozzle, a cyan tank on top, an orange pistol grip |
| `Vacuum_Turbo` | 2 | Turbo: a fiery orange body with yellow stripes, a red multi-barrel nozzle, a cyan tank |
| `Vacuum_Cyclone` | 3 | Cyclone: a mint-green body with chrome trim, a clear canister with a white cyclone swirl, a light-blue flared nozzle |
| `Vacuum_Mega` | 4 | Mega (clearly bigger): a cherry-red body, a big glass dome tank, gauges, blue hoses, a wide yellow funnel nozzle |
| `Vacuum_Titan` | 5 | Titan (bigger still): purple armour plates with gold trim, lime-green tanks, a wide gold cannon nozzle |
| `Vacuum_Vortex` | 6 | Vortex (the biggest): a blue and white futuristic body, glowing cyan rings, gold gear cogs, a huge glowing vortex nozzle |

Tiers 4-6 must be visibly bigger in game too: scale the imported models up (about 1.2x, 1.35x, 1.5x of Basic).

## Machines (one per zone; reskin later)
| Name | Prompt |
|---|---|
| `DepositMachine` | A chunky toy conveyor deposit machine about as tall as a door: a dark grey metal box with a sloped conveyor belt running up into a square opening, green glowing light strips down both sides, a big screen on the front for a money counter, yellow and black hazard stripes on the base |
| `ToolPodium` | A chunky square display pedestal for a toy shop: a dark grey stepped base with yellow and black hazard trim, a glowing green top plate where an item floats, a small screen on the front |
| `Warden` | A big friendly-scary blocky security robot boss about three times a person's height: a boxy steel-blue armoured body, one large glowing red visor eye, chunky shoulder plates with red alarm lights, big square fists, short thick legs. No mouth |

When a model is in, log it in `art/LEDGER.md` (date, name, credits).
