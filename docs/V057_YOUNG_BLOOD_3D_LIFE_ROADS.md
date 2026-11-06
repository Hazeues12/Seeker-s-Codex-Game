# Seeker's Codex: Young Blood to 3D World — V0.57 Life Roads

## Source and scope
The author supplied a detailed summary of **Young Blood v385**, source filename `young-blood-v173.jsx`, with save version 303. The JSX file and complete written guide were **not found as accessible files in this run**. This integration is mapped to the author's summary, not claimed as a verified line-for-line port of that source.

**The game's objective:** Young Blood's character-built life, persistent social consequences, career choices and Muti depth translated into a genuinely traversable 3D known world. The open-world terrain and Magnara construction from V0.52–V0.56 remain the primary production priority. The v385 life systems are a design specification, not all present in the Godot project.

## Verified starting base (before V0.57)
- 3D Godot browser game, working prototype movement, double jump, wall traversal and touch input.
- Physical Magnara Ring Two urban expansion, six walkable provisional interiors, local countryside and river crossings.
- Limited character appearance editor, three provisional beginner contracts, basic NPC dialogue, relationship memory, daily events, limited companion and injuries, Seven Spokes training prototype, Personal Codex.
- No true 36-step exam, no full 10-origin creator, no eight-rank proof, no 3D Arcwheel legacy, no household life or nine distinct civilian trades.

## V0.57 physical milestone
A small **in-world public Life Road Registrar** is placed along Magnara's public Ring Two. The player walks there and uses the existing TALK / USE button to select a **home nation** (10 from the author-supplied Young Blood original creator list) and one of three permanently chosen starting roads.

- **Take the Exam**: candidate backstory; retains existing Stray/prototype starter contracts. This does *not* instantly start or complete the canonical Seeker Examination.
- **Already Sworn**: existing Iron licence **in the original character's game-only backstory**. Does not grant a Pillar seat, Gold status, mastery or secret arts. The choice is restricted for profiles whose prior rank conflicts with new-game registration.
- **Live a Trade**: civilian/unlicensed. The original Seeker contract board is gated for this road until official qualification mechanics are implemented. A physical one-day courier shift runs through a public parcel pickup and professional service handoff. Payment: eight Tola, at most once per day. This is the **first playable job**, not all nine trades.

The selections and courier stages are stored as a separate `life_v057` field in the existing `seeker_profile_v1.json` Personal Codex schema 1. Legacy saves without it stay valid. The original V0.33 `margerina_v033.json` save continues holding money, world clock and position; existing player and control scripts remain. Mutation requires successful disk read-back before confirming registration or payment.

### Critical continuity rules
- Canon ranks remain Stray → Iron → Bronze → Silver → Gold → Grand → Sage. **Candidate** is an entry state, not an additional rank. Pillars are appointments, not a rank.
- Seven Spokes remain Elemental, Martial, Spirit, Alchemy, Psychic, Spatial and Abyssal; Celestial is exceptional and gated. Bloodline Eyes require valid inherited ancestry; no unrestricted Viatra unlock. The Arcwheel is an endgame story secret, not a public discoverable location.
- Main cast (Kai, Rin, Aria, Lila) stay intact. Game-only characters are not retroactively written into published canon.
- Only the known side of the Abyssal Line is part of the present world build.
- The player's home nation is a **character background field**; no unapproved nation coordinates or teleportation are fabricated.
- Save receipts are deduplicated for paid shifts. The old game save is still separate, so full atomic multi-file transaction/recovery should be added before a release candidate.

## Adaptation roadmap — not implemented yet
| Young Blood v385 system | 3D design target | Current scope |
|---|---|---|
| Nation, family, origin, temperament | Accessible character creator with lineage restrictions | 10 home-nation selection only |
| 8 traits, trade-off burdens, perks | Choice-points, debt/oath consequences, clear negative effects | Future |
| Bucket, Tap, Recovery, Efficiency, Control | Deep Aura profile plus environmental technique effects | Future |
| 36-step examination | Traversable story routes, forest encounters, Trial by Mercy | Future |
| 9 trades, 10 careers, 13 guilds | Workplaces and qualifications grounded in cities | First courier trial |
| 9 reputations, social bonds, life goals | Persistent NPC and institutional reaction model | Existing limited system retained |
| Stances, position, enemy phases | Real-time 3D maneuvers, terrain/flanking and timing | Existing combat retained |
| Injuries, mortality, legacy | Body-part damage and game-only later-life records | Existing limited injury state |
| Romance, business, family, corruption | Consensual adult relationship arcs, lawful/illicit opportunity and consequences | Future, not claimed implemented |
| 26 Wonders, time, market, world history | Source-tracked geography, historical variants and simulated markets | V0.54 atlas plus limited civic events |

## Validation
Full Godot 4.4.1 project import and startup, prior V0.48–V0.56 regression tests, V0.57 life-choice and courier saved-state tests, Web export, plus Python checks for main-scene, interaction wiring and original save compatibility. Tests run on isolated staging; promote only passing revisions to `codex-modular-v31`. Original `main` branch remains unchanged.

This is an **early Young Blood life-path slice**, not a completed game or playable full examination. The user has specifically asked to test a finished build later, so do not request an interim download.
