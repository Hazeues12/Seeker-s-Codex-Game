# Seeker's Codex — V0.63 Verified World-Save Integrity

**Production target:** `codex-modular-v31` after separate staging validation. **Era:** 1500 A.S. **Canon status:** pure game-engine reliability; no new lore asserted.

## What changes

V0.62 introduced real merchant transactions: a single game save contains Tola, actual inventory, current day-market stock, character position, contracts and in-game time. Previously that file was written in-place, exposing the whole playthrough to partial writes if the browser storage operation failed mid-save.

V0.63 preserves the same legacy `user://margerina_v033.json` format and introduces `systems/game_save_integrity_v063.gd`. Each save:
1. Rejects invalid values and refuses to overwrite a previously existing corrupted primary.
2. Writes a separate pending JSON, flushes and verifies its exact bytes and schema.
3. Copies the known-good prior live file into a separately verified backup.
4. Renames the verified pending file into the live location, rather than writing in-place.
5. Reports success only after the live file has been read back and validated.

When loading, prefer the valid live file. If damaged or missing and a valid previous backup exists, load that older generation and attempt to restore it safely. If both are corrupt, never silently overwrite an existing damaged primary. A backup generally contains the *previous* successful save, not the exact interrupted transaction; a sudden failure can still lose the most recent uncommitted action.

The Personal Codex remains independently saved to `user://seeker_profile_v1.json`. Cross-file atomicity between the Personal Codex and game save is not claimed. Browser private mode, cleared site data, physical disk faults, Web export permissions and insufficient storage can still defeat persistence. No network or cloud backup is introduced.

## Validation gates

- Independent headless test `tests/v063_save_integrity_scene.tscn`: first write, second write, valid snapshot backup, damaged pending file, malformed payload rejection, damaged primary fallback, protected recovery and resuming subsequent saves.
- Full Godot import and startup, real V0.62 public-market purchases and reload, V0.61 working-district interactions, and an HTML5 export. All tests must run on the staging branch before copying to the production branch.
- Keep all previously authored Ring II geometry, mobile controls, Seven Spokes prototype, family/relationship and mission systems intact. Protect the original browser game on `main`.

## Still to build

The next *visible world* pass is civic life, usable lodging and wider physical streets; then Ring III and larger Ring IV districts after atlas/canon reconciliation. This save integrity milestone does not claim land ownership, business ownership, a finished city, global navigation or live crowd simulation.

Do not demand an immediate iPhone playtest; the wider 3D world remains in development.
