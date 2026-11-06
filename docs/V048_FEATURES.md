# Margerina V0.48 — Public Field Watch, Companion, and Field Combat

This is a **game-only**, development-only mission in the *Seeker's Codex* world. The volunteer companion, rogue training automaton and assignment are prototype characters and events, not official canon. It adds no official Seeker promotions, Celestial, Bloodline Eyes, Eidolons, Soul Bloom, Spirit Bloom or Ryōiki.

## Playable mission chain
1. Speak to the field dispatch marker in the Ring Two professional precinct. Accept a supervised volunteer field watch.
2. A volunteer partner follows the player. Patrol to a second checkpoint and investigate an uncontrolled practice automaton.
3. The automaton is a **real enemy outside the original sparring yard**. Existing Martial strikes and guard/dodge combat work against it; its own AI attacks the player. The companion can assist with bounded, cooldown-limited strikes.
4. After the nonlethal takedown, choose exactly one: **protect civilians** or **secure evidence**. The other opportunity is closed.
5. Return to dispatch, file the report, and receive a one-time 22-Tola field payment and different reputation consequences. The Personal Codex records the decision.

## Persistent safety
- Mission stage/choice, its reputation receipt, and narrative history are written to the established `user://seeker_profile_v1.json` file without schema changes or deletion.
- The legacy `user://margerina_v033.json` also records a unique field-payment receipt alongside Tola. This prevents repeat payout if the player returns after mission completion and allows reconciliation if the ledger was saved before the currency credit.
- Completing the same report twice is blocked by deterministic stage transitions. The two choices are exclusive. The mission defaults to available only on a new profile.
- **Limitations:** Tola and Personal Codex are still separate saves, not a fully transactional database; loss of site storage can erase local progress. The companion uses a simple local follow rule, not complete navmesh pathfinding or a persistent squad AI. Enemy HP resets on mid-combat reload. The field mission is a reusable mission-system demonstration, not the complete game.
- Browser files are development artifacts. The user explicitly requested no premature playtesting of unfinished releases.

## Gate
Godot 4.4.1 source import, 150-frame startup, V0.44 and V0.46 regression smoke checks, V0.48 deterministic branch and JSON reload test, Web export, then *only after success* source commit to `codex-modular-v31`. Keep `main` unmodified.
