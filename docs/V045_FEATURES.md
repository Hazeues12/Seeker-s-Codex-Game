# Margerina V0.45 — Decisions, Trade & Social Consequences

**Scope:** A self-contained, game-only relationship/economy simulation placed on the existing V0.44 Personal Codex and seven provisional Ring Two NPC roles. It is not a finished game or an addition to published *Seeker's Codex* canon.

## Consequential dialogue
- Dialogue is a scrollable mobile panel that uses existing `TALK / USE`; no new thumb action is needed. All seven existing roles expose different work, civic, ethical and social decisions.
- Mutually exclusive, one-time decisions prevent choosing both success and betrayal for the same job. NPCs adjust greetings based on completed deliveries, misconduct reports, local standing and professional reliability.
- A neighborhood task lets a player accept a note from the Noodle Vendor, deliver it to the Canal Resident for **12 Tola and reputation**, or betray the trust with disciplinary consequences. Job state persists across reloads.
- Registration offers a truthful contract report only after actual existing mission completion, or a false claim (rejected and recorded). Medical donations cost 6 Tola and raise local standing; Silver-team practice consumes 15 Stamina; Soulwright public study and Citadel protocol have clear lawful/unlawful branches.
- An attempted 18-Tola bribe at the secured Citadel is **refused, confiscated and reported**. No level, rank, inaccessible content, secret, or authorization is for sale.

## Economy
- **BUY** Canal Trade Cloth at 14 Tola, or 12 with high vendor rapport; **SELL** at 8. Resale cannot create arbitrage income. Transactions update the V0.33 inventory and Tola save, and are chronicled under the Personal Codex.
- Existing Field Kit, Medicinal Herb, Aura recovery items, quest rewards, and shop rules are untouched. The new trade item is never required by an earlier mission.

## Adult romance and seduction boundaries
- Player must voluntarily declare their custom Seeker 18+ to access romance. Only two explicitly adult **game-only placeholder NPC roles**, aged 27 and 28, permit optional courtship scenarios.
- Rapport, mutual interest and consent control respectful flirting and a possible public date. There are friendship/no-romance paths. No pressure, coercion, forced intimacy or explicit sexual scenes. No canonical named characters gain invented relationships.
- The confirmed-adult gate affects only player-authored romance interactions, not official age or Seeker rank eligibility.

## Memory, reputation and safeguards
- One existing `user://seeker_profile_v1.json` stores `society.reputation`, `society.decisions`, `society.quests`, and adult romantic statuses; `schema_version = 1` remains backward compatible. V0.38 appearance, V0.41 orientation and V0.33 contract saves are not replaced.
- Reputation dimensions: Association Trust, Public Fame, Guild Reliability, Neighborhood Respect, Underworld Attention. Each is bounded and independent.
- **Professional rank** remains exam- and performance-based, not an automatic level-up, reputation threshold, romance interaction or bribe reward. Soul Bloom and Spirit Bloom are separate; rare Eyes, Celestial, Eidolon and Ryōiki do not unlock from a generic menu.
- Supports V0.44 social interactions without erasing prior rapport.

## Release gating
- Run headless import and 150-frame startup, V0.44 memory regression smoke test, V0.45 event/reputation/job/romance smoke test with explicit `timeout`, and complete Web export.
- Passing headless checks proves basic parse and logic only, not a production-quality iPhone game. Mobile performance, UI layout, quest design, animation, balancing, full combat, quest completeness and many regions still require development before finished release.
- Keep validated intermediate Web artifacts for developer rollback, **but do not invite the user to play incomplete builds**. Game testing can be batched closer to release.
