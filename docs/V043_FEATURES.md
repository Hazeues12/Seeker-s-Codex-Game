# Margerina V0.43 — Personal Codex / Persistent Seeker History

**Implementation target:** `codex-modular-v31` only, based on the verified V0.41 source (V0.42 isn't required or assumed installed).

## Gameplay
- New **MY CODEX** button above the left joystick opens an in-game career and chronology panel.
- Actual conversations with Hanami, market residents and Ring Two roles are recorded as `npc_met` events, once per resident.
- Completed starter contracts create a `contract_completed` event **after the original reward succeeds**. Already-completed contracts in older V0.41 saves are backfilled without paying rewards again.
- First visits to the public quarter, professional quarter and restricted Citadel approach are recorded through actual player position.
- Event details include an immutable ID, type, day, clock, location, and `canon_status: game_only` so gameplay is never mistaken for author-established lore.
- Character name reads existing saved LOOK data. Rank, XP, Tola, current Aura and local guild reputation come from the working save/in-memory state, not a fictitious independent progression system.
- No Seeker rank promotions, chosen bloodlines, awakened Eyes, Soul Bloom, Spirit Bloom, Eidolons, or Ryōiki unlocks are invented.

## Persistence and migration
- New additive `user://seeker_profile_v1.json`, retaining the entire V0.33 quest save, V0.38 appearance save, and V0.41 orientation save unchanged.
- Deduplicated event log (240-entry cap), defensive JSON schema validation, and a pending-file save followed by rename to reduce partial writes. Existing unreadable or unsupported profile files are not overwritten.
- `main` untouched, browser artifact includes Web export. Build-time validation does **not** prove Safari/local-storage persistence; test on your iPhone.

## iPhone playtest
1. Confirm joystick + RUN + JUMP + camera multitouch still work in the training yard.
2. Tap **MY CODEX** above joystick. It should show the name saved under LOOK, Stray rank unless legitimately changed, and no invented advanced powers.
3. Close the Codex, talk to Hanami (or the market seller), reopen; contact appears once.
4. Complete a previously unfinished starter contract; its completion appears once, without any new free Tola on reload.
5. Explore the Ring Two public/professional quarter, reopen Codex, observe the location entries. The restricted Citadel approach remains restricted.
6. Save, reload the same browser origin, and confirm contacts and events persist; older quests and appearance must still restore.
7. If the profile file is corrupt or an unsupported schema, the Codex should show a warning and refuse overwriting it.

## Planned next
Persistent NPC interaction flags (V0.44), distinct reputation metrics and conduct (V0.45), authentic Seven Spokes (V0.46), authored complete regional mission loop. This new ledger is the groundwork, not those finished features.
