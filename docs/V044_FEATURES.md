# Seeker's Codex: World of Margerina — V0.44 Living Relationships

## Verified install
The V0.44 GitHub Actions run validated the Godot 4.4.1 import and startup, NPC save/reload and deduplication, and Web export before committing gameplay files to `codex-modular-v31`.

## Personal memory
- V0.43 Personal Codex and V0.44 social decisions live together in `user://seeker_profile_v1.json`.
- The first interaction with an NPC creates an acquaintance record. V0.44 provides three one-time topics: their work, respectful recognition, or a demand for special treatment.
- Each NPC has an independent, bounded rapport score from -3 to +3. Discussions are remembered after a browser reload.
- Positive, neutral and negative choices create different dialogue and attitudes, but do not award Tola, XP, rank, guild membership, Citadel access or rare powers.
- The existing V0.33 quest/inventory save, V0.38 appearance save and V0.41 Ring Two orientation save remain untouched.

## Seven game-only conversation roles
Noodle Vendor; Canal Resident; Registration Clerk; Medical Instructor; Silver Team Instructor; Soulwright Officer; Citadel Patrol Sentry.

All these are **provisional gameplay roles**, not newly established named characters from the official story. Their schedules, personalities, job titles and conversation examples do not establish story canon.

## Controls and continuity
- Talk through the existing **TALK / USE** button. A dialogue menu temporarily pauses player movement, then restores it on close.
- All existing multitouch controls, sprint-plus-jump, double-jump, wall-running, water-running, combat and exploration remain as they were.
- Professional Seeker promotion still requires formal examinations and appropriate career consequences, not XP or a friendship meter.
- Rare Eyes, Celestial, Soul Bloom, Spirit Bloom, Eidolons and Ryōiki are not casually unlocked.
- Protected lore: no unknown secrets, no fabricated restricted Citadel interiors, and no revelation of Rin's Chapter 90 box location.

## Manual iPhone playtest
1. Confirm the **MY CODEX** screen displays current character name and preexisting history.
2. Visit the Registration Clerk in the professional precinct and choose a dialogue topic.
3. Speak again: the chosen option should be unavailable and the clerk's attitude should reflect the prior choice.
4. Reload the same itch.io domain and revisit the clerk. Verify rapport, choice history and original quest progress persist.
5. Try a contrasting response with a different NPC. Confirm attitudes are tracked **per person**.
6. Check joystick + camera + RUN/JUMP, combat and other interactions after closing the conversation menu.
7. Keep the previous playable itch.io build as backup until mobile performance and UI are checked.

## Technical scope
This is a lightweight rule-based, role-specific social memory prototype rather than a language model or an always-running full NPC simulation. Follow-up milestones can add character relationships, branching quests, faction reputation and NPC schedules without replacing the Personal Codex save.
