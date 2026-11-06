# Seeker's Codex: World of Margerina — Finished-Build Gates

User direction: keep developing on GitHub; don't repeatedly ask the user to test early prototypes. The target is a substantive, cohesive release. Retain the previous verified build and do automatic checks as milestones advance.

**No premature 'finished' claims.** A successful Godot Web export is a technical check, not a finished RPG.

## Required for the first full playable release
1. An authored region with start, middle and finish; reliable saves, resets, return travel and fail-safe spawn points.
2. Mobile multi-touch: camera, joystick, RUN + JUMP, midair double-jump, wall/water traversal, combat inputs and menus tested in browser and eventually on physical iPhone.
3. Dialogues with real action hooks, mutually exclusive outcomes, trade, relationships, optional adult courtship, ethics, professional conduct, and reactions over time.
4. Seven Spokes and Aura systems represented with appropriately distinct mechanics; no canon-defying unlocks; actual enemy types, counters and reasonable balance.
5. Seeker Association career contracts, examinations, guild opportunities and professional progression separated from combat XP.
6. NPC routines, functional interiors, guild/home base, player ownership of choices and character memory in Personal Codex.
7. Real mission travel/encounter/return loop including meaningful consequences and companions.
8. Source-aware canon audit against locked story chapters; provisional game material always labeled and never silently promoted to canon.
9. Regression tests, performance budgets, accessibility, sound, UX polish and repeatable Web build. Rollback branch must stay intact.

## Deployment principles
- `codex-modular-v31` remains the development branch; `main` preserved.
- New feature installers run Godot checks **before** committing gameplay changes.
- Daily development updates report actual completed features and specific remaining blockers.
- Keep GitHub Actions artifact exports available for later, but don't route the user to itch.io or ask them to install until a release candidate truly meets the above criteria.
