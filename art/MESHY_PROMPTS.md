# Meshy prompts: Break The Walls

The tool line is **Fists → Knuckle Dusters (5 tiers)** plus **Vacuum (4 tiers)**. The Hammer is dropped.
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

## Knuckle dusters (worn over the blocky Roblox hand; one-handed, the size of a fist)
Model them **lying flat, finger holes facing the camera**, so they snap onto the viewmodel hand.

| Name | Tier | Prompt |
|---|---|---|
| `Knuckles_Bronze` | 1 | A chunky toy knuckle duster with four big round finger rings in a row and a thick curved palm grip underneath, warm bronze-brown metal with slightly darker edges |
| `Knuckles_Iron` | 2 | A chunky toy knuckle duster with four big round finger rings, polished steel grey with small round rivets along the top bar and a dark grip wrap |
| `Knuckles_Gold` | 3 | A chunky toy knuckle duster with four big round finger rings, shiny gold with a square red gem set in the middle of the top bar and a black grip |
| `Knuckles_Diamond` | 4 | A chunky toy knuckle duster whose four finger rings are faceted cyan diamond crystal, a white-silver frame and small crystal spikes on top |
| `Knuckles_Energy` | 5 | A chunky sci-fi knuckle duster, a dark navy frame with four glowing electric-blue energy rings, small blue lightning fins on top and a glowing core in the grip |

## Vacuums (held in the right hand, nozzle pointing forward; about 3 studs long in game)
Model them **side-on, nozzle pointing left**, with a pistol grip underneath.

| Name | Tier | Prompt |
|---|---|---|
| `Vacuum_Basic` | 1 | A chunky handheld toy vacuum blaster: a dark grey boxy body, a long hazard-yellow nozzle with a wide square mouth, a small blue glass tank on top showing grey cubes inside, a black pistol grip underneath |
| `Vacuum_Turbo` | 2 | A chunky handheld toy vacuum blaster: a bright orange body with black stripes, twin side-by-side nozzles, a bigger blue tank on top, a black pistol grip, a small fan vent on the back |
| `Vacuum_Mega` | 3 | A big chunky handheld vacuum cannon: a glossy red body with chrome trim, a wide funnel-shaped nozzle, two green glowing tanks on top, a black pistol grip and a front handle |
| `Vacuum_Vortex` | 4 | A huge futuristic vacuum cannon: a white and cyan body, a round nozzle with a swirling cyan vortex inside, one big glowing cyan tank, chunky fins along the back, a black pistol grip |

## Machines (one per zone; reskin later)
| Name | Prompt |
|---|---|
| `DepositMachine` | A chunky toy conveyor deposit machine about as tall as a door: a dark grey metal box with a sloped conveyor belt running up into a square opening, green glowing light strips down both sides, a big screen on the front for a money counter, yellow and black hazard stripes on the base |
| `ToolPodium` | A chunky square display pedestal for a toy shop: a dark grey stepped base with yellow and black hazard trim, a glowing green top plate where an item floats, a small screen on the front |
| `Warden` | A big friendly-scary blocky security robot boss about three times a person's height: a boxy steel-blue armoured body, one large glowing red visor eye, chunky shoulder plates with red alarm lights, big square fists, short thick legs. No mouth |

When a model is in, log it in `art/LEDGER.md` (date, name, credits).
