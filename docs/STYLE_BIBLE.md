# Style Bible — stud-voxel toy look

Reference: Prehistoric Farm (Roblox). Chunky cubes, a stud tile texture on faces, flat
saturated colours, soft daylight, nothing realistic. Every model, part and texture follows this.

## Never

- Realistic materials (wood grain, cobblestone, metal scratches, PBR rust). ChatGPT's build
  used these; that's the look we're leaving.
- Pure black or pure white surfaces. Coal is dark charcoal-blue, not #000.
- Thin or spindly shapes. Everything is chunky, a bit oversized, readable from far away.
- The word "LEGO" in any prompt, asset name or in-game text (trademark). Say
  "building-brick toy" or "stud blocks".

## Palette

| Use | Hex |
|---|---|
| Grass / dark grass | `#6CC24A` / `#3E8E2F` |
| Sky | `#6EC6FF` |
| Wood / dark wood | `#B5713B` / `#7A4A26` |
| Brick red | `#D9483B` |
| Sunny yellow | `#FFD23F` |
| Lava / lava glow | `#FF7A1A` / `#FFB000` |
| Crystal purple / teal | `#9B5CFF` / `#2EE6C8` |
| Stone / dark stone | `#8A8F99` / `#5D626B` |
| Coal | `#3A3A4A` (`#2B2B33` read as pure black under coloured room lights) |
| Gold coal fleck | `#F5B800` |
| Platinum | `#D6E3F0` |
| Diamond | `#7FE8FF` |
| UI outline / text stroke | `#1E1A2E` |

## Building with parts

- Grid: terrain and cave walls on a 4-stud grid; props and detail on a 2-stud grid.
- All world parts are `Plastic` with Roblox's built-in `Studs` surface on every face (`Inlet`
  on the bottom). Tested 2026-10-06: it gives the stud toy look for free, with no textures
  and no performance cost. A custom stud MaterialVariant is only worth making if we want
  bevelled block edges like Prehistoric Farm.
- Coal blocks are Parts (there will be thousands), never MeshParts.
- Lighting: sunny surface with soft shadows; cave uses PointLights on lava, crystals and
  lanterns instead of darkness. Coloured fog in the cave is fine; black fog is not.

## Meshes (Meshy)

Pipeline: reference image (Gemini) → Meshy image-to-3D → Roblox (Open Cloud upload or Studio
import). Settings: `should_remesh: true`, `topology: triangle`, `should_texture: true`,
`enable_pbr: false`, polycount per budget below.

| Asset | Triangle budget |
|---|---|
| Hand tool (pickaxe) | 1,500 |
| Cart | 3,000 |
| NPC | 6,000 |
| Hero prop (Great Furnace) | 10,000 |
| Small prop (lantern, crate) | 800 |

## Reference image prompt template

> A single [OBJECT], chunky voxel toy style built from small cube blocks with little round
> studs on the top surfaces like a building-brick toy, bright saturated colours, simple bold
> shapes, 3/4 front view, centred, plain flat light grey background, soft even lighting,
> no text, no ground, no shadow, no other objects.

Long tools must be described upright, never diagonal. Ban written labels explicitly.

## Tool and cart tiers

Each tier changes the silhouette, not just the colour. Higher tiers glow (crystal, lava,
rainbow). Exact tier lists live in `ReplicatedStorage.Modules` data modules once built.
