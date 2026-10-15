# UI progress

Every screen and panel in the game, with its status. Update a row whenever you touch that screen, and add a screenshot to `ui/screenshots/`.

Status: `todo` · `in progress` · `needs polish` · `done`

| Screen / panel | Status | Instance path | Latest screenshot | Notes |
|----------------|--------|---------------|-------------------|-------|
| Main HUD (money, storage bar, hotbar) | needs polish | `PlayerGui.HUD` (StarterPlayerScripts.HUD), `PlayerGui.Crosshair` | `screenshots/core-loop/2026-10-15_vacuum-held.jpg` | Minimal ToyUI pass: money pill top right, storage bar + 2-slot hotbar (ViewportFrame icons) bottom centre, toasts. No zone name yet, no coin icon (needs a generated icon), ui-critic not run, phone viewport not checked. |
| Upgrade shop | todo | | | |
| Prestige panel | todo | | | |
| Settings | todo | | | |
| Number popups / hit effects | in progress | HUD (DepositPaid BillboardGui), ToolsClient (PunchPreview, flash, burst) | `screenshots/core-loop/2026-10-15_fists-grid-preview.jpg`, `2026-10-15_deposit-popup.jpg` | +$ popups out of the deposit machine; punch grid preview (orange centre, white ring), white flash + shake, predicted break burst. No sounds yet. |

## Style rules
Follow `docs/UI_RULES.md` and build everything with `studio/ToyUI.lua` (the stud-toy style: an outlined slab, a
raised face, a stud texture, Fredoka text with a hard shadow, 4 px corners).
Size budget at 1280x720: money pill 192x48, storage bar about 300x36, hotbar slot 60, body text 14-18.

## World screenshots
First-person shots of the built zones (2026-10-15) are in `ui/screenshots/world/`.
