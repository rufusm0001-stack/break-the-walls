# Break the Walls: rules for Claude

A Roblox incremental game, inspired by the Steam game *Break the Walls*. **Three people on three devices and three accounts** work on it, each with their own Claude. This repo is how sessions hand work over to each other.

## Start of every session
1. `git pull`
2. Read `HANDOFF.md`. It shows exactly where the last agent left off.
3. Read `ui/UI_PROGRESS.md` and look at `references/` before touching any UI or art.
4. Claim your task in `TASKS.md` (put your name next to it), then commit and push straight away so nobody else picks the same task.

## End of every session
1. Rewrite `HANDOFF.md`: what you did, the exact Instance paths you touched, the next step, and anything to watch out for.
2. Add a short dated entry to the top of `STATUS.md`.
3. If you changed UI: update the row in `ui/UI_PROGRESS.md` and save a screenshot to `ui/screenshots/`.
4. `git pull` again, then commit and push.

## Game rules
- Follow the reference game's mechanics, but don't copy its names, art or text. Everything gets a Roblox theme.
- UI must look polished and consistent. Follow the style rules in `ui/UI_PROGRESS.md` and use readable numbers (1.2K, 3.4M, ...).
- Keep all tunable numbers (costs, wall HP, multipliers) in one Config module.
- Only edit what your task covers. If you need to change something another person owns, write it in `HANDOFF.md` instead.
