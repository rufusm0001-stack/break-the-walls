# Break the Walls: shared rules (Claude and Codex)

Follow the `roblox-stud-game` skill. (Codex: read `stud-kit/SKILL.md`.)

Read these first:
- `HANDOFF.md` (where the last agent left off)
- `DESIGN.md` (the game spec and the settled decisions)
- `docs/STYLE_BIBLE.md`
- `docs/UI_RULES.md`
- `docs/ZONE_BRIEFS.md`
- `ui/UI_PROGRESS.md`

## Hard rules
- **Palette and lighting come from docs/STYLE_BIBLE.md; the skill's colour defaults don't apply.**
- **The game is first person** (CameraMode LockFirstPerson, with blocky arms holding the tool). Check every screenshot from that view.
- **Never use the trademarked toy-brick brand name anywhere.** Say "stud" or "brick".
- **World parts are Plastic, with studs on top faces only.** Walls get smooth sides. Build with
  `studio/StudKit.lua`.
- **Build UI only with `studio/ToyUI.lua`.** No hand-built one-off buttons.
- **Every zone keeps its own palette and its one landmark,** as set in `docs/ZONE_BRIEFS.md`.
- **Stop Play before editing in Studio.** In `execute_luau`, require a *clone* of a module.
- **End each pass in Play,** with screenshots from the player camera. Run `studio/map_qa.luau`: floating, airborne
  and zfight must all be 0.
- **Keep API keys out of the repo.** Log every art spend in `art/LEDGER.md`.
- **Never publish, and never spend Robux.** The owner does those.
- **Roblox place:** "Break The Walls", placeId 104446080960521.
