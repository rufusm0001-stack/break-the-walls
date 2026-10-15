# Handoff: where the last agent left off

> Rewrite this whole file at the end of every session, so it always shows the **current** state. The history goes in `STATUS.md`.

**Last updated:** 2026-10-15
**By:** Rufus (device: main PC)

## What was being worked on
- Settled the design questions: no energy, a deposit machine, money only on deposit, a fast start, and sections each
  with their own spawn area and twist (Zone 2 = a mine cave with orange ore and a left/right maze, with boss rooms
  later). All of it is in `DESIGN.md`.
- Adopted the `roblox-stud-game` playbook: the kit is copied into `studio/`, `art/`, `docs/` and `.claude/agents/`.
- Drafted `docs/ZONE_BRIEFS.md` for zones 1-2. **It still needs the owner's sign-off.**

## Exact state
- Roblox place: **Break The Walls**, placeId **104446080960521**. Nothing has been built in it yet.

## Next step (start here)
1. Get sign-off on `docs/ZONE_BRIEFS.md`.
2. Studio settings: Avatar R15, StreamingEnabled off.
3. Build Zone 1: lighting first, then the spawn room, the breakable cube wall, Fists punching with a grid preview,
   the Vacuum, the deposit machine, and Money.
4. The HUD with ToyUI (money, storage, hotbar).

## Watch out for
- Tune all the numbers in the Config module (see the starting numbers in DESIGN.md).
