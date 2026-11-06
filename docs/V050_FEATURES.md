# Margerina V0.50 — A Multi-Day Public Waystation Mission

**Status:** internal Godot Web development milestone only. No premature user playtest or finished-game claim.

## Connected mission loop
1. Accept a public transport assignment from the Ring Two dispatch marker (game-only role).
2. Choose a medical kit or survey kit as mission preparation. The choice affects the final report's secondary reputation.
3. Board a short moving 3D carriage through a lightweight, procedurally constructed green corridor. The player is a passenger and may look around; controls resume at the station.
4. Camp overnight. The mission deliberately advances the in-game clock to the following morning (no real-world waiting).
5. Investigate and disable a field automaton. Its strikes and counters use the existing combat system; the volunteer helps when uninjured.
6. Decide whether to prioritize civilian medical aid or recovering official evidence, with mutually exclusive results.
7. Ride the carriage back to Magnara and file a final professional report. Reputation and companion trust reflect the choices.
8. Collect one 30-Tola field payment with a separate receipt guard in the legacy hub save, without repeating payment when revisiting dispatch.

## Persistence & scope
- Deterministic saved state and progress are retained in the existing Personal Codex JSON. Preparations, departure day, overnight rest, outcome and final report survive reload.
- Incomplete missions resume from a safe camp, carriage restart, or city dispatch; the carriage's exact progress isn't persisted because the short ride can safely restart.
- No existing character appearance, inventory, contract, or core save is reset. Player location and the day clock save through the existing hub system.
- The waystation is a self-contained game-only corridor and is **not** asserted as a locked map route or official canon geography. No rare Eyes, Celestial, Soul Bloom, Spirit Bloom, Eidolon or rank promotions.
- The existing local browser storage is not transactional across both game and Codex saves; receipt guards reduce payout duplication but cannot promise atomic crash recovery.

## Validation
- Godot 4.4.1 headless import and game startup, existing V0.48 + V0.49 state regression, V0.50 invalid transitions/alternate branches/overnight day/JSON roundtrip tests, and Web export.
- All gameplay-source commits are gated on success and limited to `codex-modular-v31`. `main` remains unchanged.
- This is still far from a finished RPG. Art assets, transportation depth, quest variety, NPC schedules, localization, iPhone UX tests, and more regions remain open.
