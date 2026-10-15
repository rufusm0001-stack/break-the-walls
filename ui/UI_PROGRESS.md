# UI progress

Every screen and panel in the game, with its status. Update a row whenever you touch that screen, and add a screenshot to `ui/screenshots/`.

Status: `todo` · `in progress` · `needs polish` · `done`

| Screen / panel | Status | Instance path | Latest screenshot | Notes |
|----------------|--------|---------------|-------------------|-------|
| Main HUD (money, storage bar, zone name) | todo | | | |
| Upgrade shop | todo | | | |
| Prestige panel | todo | | | |
| Settings | todo | | | |
| Number popups / hit effects | todo | | | |

## Style rules
Follow `docs/UI_RULES.md` and build everything with `studio/ToyUI.lua` (the stud-toy style: an outlined slab, a
raised face, a stud texture, Fredoka text with a hard shadow, 4 px corners).
Size budget at 1280x720: money pill 192x48, storage bar about 300x36, hotbar slot 60, body text 14-18.
