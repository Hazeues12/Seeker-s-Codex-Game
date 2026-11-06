# Margerina V0.49 — Companion Trust, Injury & Adaptive Field Threat
Development-only extension on top of verified V0.48. No finished game release and no player playtest required.

## Companion persistence
- Game-only volunteer partner remains the same V0.48 field companion. Loyalty (-3 to 3), injury (0 to 100), interventions and recovery date persist in the existing Personal Codex JSON under `companion_v049`.
- During the field fight, the companion can intercept up to three valid enemy attacks, sustaining injury instead of the player. Interception stops after the cap or if the partner is too wounded. The partner provides reduced support while injured.
- After a completed mission, the partner's trust responds to the actual civilian/evidence outcome once. No repeating the dialogue to farm loyalty.
- At dispatch after mission completion, the player can arrange recovery that removes 24 injury at most once per in-game day, preserving injury across reloads.

## Enemy response
- Rogue field automaton tracks rapid repeated hits and can guard when pressured, instead of repeating the same stagger pattern. Original sparring constructs retain their separate training behavior.

## Canon & releases
- Roles, dialogue and numbers are game-only prototypes. No new canonical characters, official Seeker ranks, forced romance, Eye abilities, Soul Bloom, Spirit Bloom, or Citadel access are created.
- The new file extends `user://seeker_profile_v1.json`, preserving its schema and the V0.33 Tola, quest and appearance saves.
- V0.49 workflow: import, startup, V0.44 & V0.46 & V0.48 regression tests, V0.49 bounded-state save test, Web export, and commit to development branch only after all pass.
- Browser artifact is retained for developer rollback. User requested to wait for a substantially finished release before playing.
