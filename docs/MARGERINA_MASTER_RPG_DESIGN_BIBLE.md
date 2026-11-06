# Seeker’s Codex: World of Margerina
## Master RPG Design Bible — Canon-Led Implementation Roadmap

**Revision:** 1.0 • **Date:** 2026-11-05 • **Purpose:** Production source of truth for the evolving Godot RPG

> **Central player promise:** *I created my own Seeker, entered Margerina, and built a life and reputation that the world remembers.*

This design bible organizes the author's **Ultimate Open-World RPG Blueprint** into a buildable program. It is an implementation guide; it does **not** overwrite published Seeker's Codex canon. When a proposal conflicts with the author's latest locked chapter or explicit correction, **canon wins**.

## A. Status ledger — what is actually built

**Verified GitHub repository:** `Hazeues12/Seeker-s-Codex-Game` • development branch: `codex-modular-v31` • original browser game kept on `main`.

**Verified as of 2026-11-05:** The latest checked successful gameplay upgrade is **V0.41 Living Seeker Quarters**. `V0.42 Canal Commons` was packaged previously but **was not present in the checked GitHub branch**. A prepared installer is not evidence of a completed build, upload to itch.io, or playtest.

| Capability | Current evidence | Production status |
|---|---|---|
| iPhone browser play | User-tested through V0.39; ongoing iterations | Working prototype; regression-test every release |
| Multitouch/run + jump | `ui/mobile_controls.gd`, `characters/player_controller.gd` | Implemented in V0.39; test on-device |
| Double jump, wall/water running | `world/traversal_course.gd` | Local prototype only; water lane is shallow simulated traversal |
| Player customization | `ui/seeker_creator.gd`, `characters/procedural_seeker.gd` | Cosmetic prototype; full origin/life creator absent |
| Martial Muti and sparring | `combat/combat_arena.gd`, `combat/sparring_construct.gd` | Basic real-time combat; Seven Spokes not implemented |
| Seeker Quarters + Ring Two | `world/magnara_ring_two.gd`, `world/ring_two_daily_life.gd` | Modular outdoor geometry and interaction prototype |
| Visitor orientation / NPC dialogue | `world/ring_two_daily_life.gd` | Role-specific dialogues with separate saved progress |
| Full interiors, deep relationship memory, world politics | No verified implementation | Planned |
| Complete personal Codex and unified life history | No verified implementation | **Next core architecture priority** |
| Other nations / connected global atlas | No verified implementation | Long-term |

**Important:** Godot headless import/startup and Web export prove build integrity, not high frame rate, touch ergonomics, or zero glitches on Safari. Preserve known-good itch.io ZIPs.

## B. Canon hierarchy — rules we cannot casually rewrite

1. **Latest explicit author correction and published chapters.**
2. **Locked Seeker's Codex system notes and official atlas.**
3. **Provisional worldbuilding hypotheses**, clearly marked as such.
4. **Game-only mechanics and quests**, clearly marked as such.

Every location, technique, family, quest, character, and artifact record should have:

- `id`: stable machine-readable identifier
- `name`: display name
- `canon_status`: one of `confirmed`, `provisional`, `game_only`, `unverified`
- `source`: chapter, dossier, author decision, or development proposal
- `region_id`, `prerequisites`, and optional `spoiler_tier`

Avoid inventing precise ring assignments, entrance permissions, character bloodlines, hidden locations, or official Seeker promotion rules unless the canon establishes them. In particular, Rin's Chapter 90 mystery must not be prematurely exposed in routine exploration.

### Power-system locks

- **Seven standard Spokes:** Elemental, Martial, Spirit (Spiritus / Spectral), Alchemy, Psychic, Spatial, Abyssal. **Celestial is rare and exceptional**, not an eighth ordinary starter-class choice.
- **Aura:** reservoir (`bucket`), safe output (`tap`), recovery, control and efficiency. Training, exhaustion and injury should matter independently.
- **Triad of Will:** Sight (Kyōmei-shi), Steel (Kōshin), Sovereignty (Ōi). Access respects locked rank/training restrictions; do not sell Sovereignty as a normal early-level perk. Sight is much more broadly accessible; Steel Gold+ in canon and Ōi Grand+ in general, with specific lore exceptions.
- **Soul Bloom:** Tier 1 Resonance Gate → Tier 2 Triad Sync → Tier 3 Eidolon Guard → Tier 4 World-Bend → Tier 5 Samsara.
- **Spirit Bloom:** Tier 1 Spirit Bloom → Tier 2 True Flow → Tier 3 Soul Manifestation → Tier 4 God-Killer → Tier 5 Samsara. Keep this **distinct** from Soul Bloom. Do not casually merge the two ladders.
- **Eidolon** reveals resonance and character development under canon-consistent prerequisites; not simply an XP purchase.
- **Ryōiki** and high-tier domains require separate validation of canon, mastery, cost and progression. Do not auto-grant one for finishing a generic skill tree.
- **Rare Eyes:** Viatra, Tokoyami, Azure Tenzan and others require legitimate lineage/history/awakening/training or a specifically approved story exception. **Genmugan** is Black Clan illusion discipline, not an independent eye.
- **Black Clan summoning:** Kairo Hiden: Kokukyūin — Nine Black Seals. The Jin seal activates Chief Inspector Nezubunta and the Onzu Squad; hand signs are activation keys, not independent power mutations.
- **Seeker ranks:** Stray → Iron → Bronze → Silver → Gold → Grand → Sage. Promotions require fictional institution approval and performance/exam/conduct logic, not raw XP alone.

## C. World model — authored regions, no planet-sized scene

Hierarchy: **World → Nation → Province/Region → City/Settlement → District → Streamed Cell → Interactable**.

Core future environments (subject to published geographic and cultural references): Rajistan; Chun; Janoah; Britannia; Vinlan; Tsar Empire; Germania; Americana; Africanus; Dune States; Astraea/Dark Continent; Abyssal Line. Implement in authored regional chunks with meaningful roads, caravans, harbors, stations and transitions. An entire country must not be represented by a single generic city map.

**Two play experiences** in the long-term design:

1. **Story Campaign** — follows Kai, Aria, Rin, Lila and their published chronology. Canon story facts remain controlled.
2. **Create-a-Seeker** — an original career alongside published history; player's actions can alter their local story but must not arbitrarily overwrite locked main-cast events.

**First world vertical slice:** Keep the verified working Magnara Ring Two project alive and deepen it. Design the Bodhira → Rajir starter route as a **subsequent separate authored region**, not as a destructive restart of the current GitHub game. The initial novel path remains Bodhira → Rajir → caravan ambush → Chun Black Forest → Janoah.

### Magnara Ring Two — verified design anchors

- Public band: pale stone streets wide enough for four carriages; blue-resonance waterways and iron bridges; bronze/sigil lamps; working inns, noodles, residences, services and normal civilians.
- Professional band: association registration/certification, training courts, medical instruction, Soulwright activity, barracks and coordinated Seeker squads.
- Secured institutional approach: Seeker Citadel, massive black-and-gold six-sided silhouette and thirteen towers. Publicly guarded, **not an unrestricted rookie dungeon**.
- Any local map-axis convention (currently `+Z` for the working prototype) is an implementation convenience, **not canonical north/south**.
- Exterior facades must evolve into interactable doors, small modular interiors, collision-correct rooftops and purposeful NPC schedules.

## D. The architecture that makes the world remember

### The Personal Codex and Event Ledger

Create a **single additive profile** alongside the existing saves. Suggested migration-safe file: `user://seeker_profile_v1.json`. Do not remove or rewrite `user://margerina_v033.json` or the current appearance/orientation saves.

Suggested structure:

```json
{
  "schema_version": 1,
  "profile_id": "local-original-seeker-001",
  "identity": {"name": "New Seeker", "origin_id": "unselected", "background_id": "unselected"},
  "career": {"rank": "Stray", "guild_id": null, "certifications": [], "exam_history": []},
  "affinities": {"spokes": {}, "celestial_status": "locked", "ocular_lineage": null},
  "aura": {"reservoir": 100, "output": 10, "recovery": 1, "control": 1},
  "reputation": {
    "association_trust": 0, "public_fame": 0, "guild_reliability": 0,
    "national_standing": {}, "red_order_attention": 0,
    "underworld": 0, "soul_law_flags": []
  },
  "relationships": {},
  "history": [],
  "discovered_locations": [],
  "unlocked_techniques": [],
  "soul_development": {"soul_bloom_stage": 0, "spirit_bloom_stage": 0,
                       "eidolon": null, "ryoiki": null}
}
```

Every important action emits an event with **stable id, game clock, location, actors, context, and verified outcome**. Examples: `contract_completed`, `civilian_rescued`, `property_damaged`, `npc_met`, `training_session_completed`, `discovery_recorded`, `mission_abandoned`. Never grant rank or a named skill merely because a raw event count crossed an arbitrary threshold.

**Derived state** such as reputation, chronicle text, unlock eligibility, and NPC relationship affinity should be computed from rule-validated events and explicit decision data. Event replays and schema-versioned migration should enable debugging and save upgrades.

### A dynamic Codex UI (the star feature)

At minimum show character name and origin; earned Seeker rank; Aura stats; trained Spokes; guild status; profession record; named relationships; visits and discoveries; recent journal chronology; earned public/Association reputation; future Soul development as **unknown/locked** rather than fabricated outcomes. Example titles like “The Wandering Flame” are hypothetical until earned from approved conditions.

**Privacy and integrity:** Local prototype save is on the device/browser. Avoid collecting personal information. Use caps, timestamps, event deduplication and defensive JSON parsing. Preserve old saves on migration failure.

### Living NPC design

Use an inexpensive **schedule + state** model away from the player and fuller behavior close up:

- `home → work → rest → travel → special_event` by region and world time;
- persistent relationship flags, known encounters and significant mission outcomes;
- job-appropriate dialogue trees, equipment and services;
- near-player animation, navigation, dialogue and combat activated only when needed;
- remote simulation records only durable state, not thousands of expensive AI-agent ticks.

## E. Combat and traversal contracts

### Combat foundations

Add one honest technique per standard Spoke with distinct tactical uses **before** expanding to dozens of shallow attacks. Build transparent status effects and interaction rules (Elemental terrain, Martial stance/counter, Spirit sensing, Alchemy preparation, Psychic deception, Spatial repositioning, Abyssal risk). Advanced hybrid Arts are unlocked through mastery and authored constraints. Record technique usage, efficiency, strain, friendly-fire/property consequences, and opponent counter-learning.

**Enemy adaptation** begins deterministically: count repeated move patterns within a fight; warn/dodge/counter more effectively while respecting enemy skill and reaction time. Do not claim freeform sentience or persistent tactical intelligence without implementing it.

### Movement acceptance contract

Movement, camera, sprint, jump, dodge, strike, guard and interaction inputs must be **independent multitouch actions**. One finger on the joystick must not block another from using jump; RUN + JUMP + camera remains supported. Double-jump in air, wall-running along actual solid wall colliders, water-running where the world permits, land-reset, vault/climb and rooftop chaining are a core gameplay identity. Resource and combat rules can constrain abilities, but touch routing cannot arbitrarily cancel them.

## F. Seeker career, economy, companions, and world consequences

Association trust, public recognition, guild standing, national standing, Red Order attention, underworld relationships and Soul Law flags are **separate**. Contract evaluation considers professionalism, protected civilians, legal conduct, collateral damage and fulfillment of mission objectives.

Tola supports contract payment, travel, lodging, medicine, repairs, food, training and gear. Crafting/jobs require resources, time and legitimate access. Outfits and uniforms carry meaningful identity cues and legal social meaning, not purely armor points.

Companions have schedules, abilities, goals, relationships, opinions and remembered joint missions. They can disagree, leave, join, aid in travel conversations and react to moral outcomes, with lore-approved limits. Squad commands must work with mobile controls.

## G. The repeatable gameplay loop

**Morning:** wake, eat, recover, review guild contracts and personal Codex.

**Preparation:** research a target, choose an approach, buy medicines, coordinate a squad.

**Travel:** ride a carriage, boat or train while the world remains visible; optional roadside events and companion dialogue.

**Encounter:** scout, negotiate/hunt/fight, manage Aura, environment and consequences.

**Return:** file report, earn or lose trust and Tola, update relationships, reveal mystery threads, rest and train.

Each milestone should implement a **complete short version** of this loop rather than one disconnected UI feature.

## H. Milestone plan with verifiable exit criteria

| Milestone | Scope | Acceptance gate |
|---|---|---|
| V0.42 Canal Commons | Existing prepared enterable public-quarter room, rooftop loop, discoveries | Source committed and Web build + iPhone playtest pass; not verified installed as of audit |
| **V0.43 Personal Codex Foundation** | New profile schema, safe save migration, identity, career, event chronology, in-game Codex UI | Interact with known NPC → event appears → reload browser → event persists; older saves still load |
| V0.44 Living Contacts | Persistent NPC relationship reactions, daily jobs, interaction dialogue state | NPC remembers encounter on return; story-only events protected |
| V0.45 Seeker Conduct | Reportable contract outcomes, separate reputation metrics, simple non-lethal choice | Same mission yields distinct recorded aftermath; Association rank unchanged unless authorized |
| V0.46 Spoke Proving Yard | Distinct baseline techniques for all Seven standard Spokes, Aura model and training prerequisites | Each Spoke changes approach; all abilities obey costs and environment guards |
| V0.47 Full Regional Mission | One complete mission: briefing, preparation, local travel, encounter, return and Codex entry | Complete 20–40 minute repeatable vertical slice on iPhone |
| V0.48+ Bodhira / Rajir prototype | Start authored campaign region separate from Magnara scene, travel transition foundation | Consistent chronology, geography and safe region switching |
| Later | Guilds, squads, other nations, wilderness/ecology, spiritual evolution, vehicles, advanced secrets, co-op | Approved canon and performance gates before release |

### Performance and release gates

1. **Never change `main`** to install a Godot prototype upgrade; keep work on the existing development branch.
2. GitHub Action tests: import, script parse, headless startup, Web export, artifact `index.html`/`.js`/`.wasm`/`.pck` validation, and non-destructive commit.
3. iPhone Safari playtest: responsive multitouch; reliable RUN+JUMP; rooftop collisions; no stuck player; stable UI; save → reload; return to old hub.
4. Profiling: use distance-based streaming, material reuse, pooled effects and disabled distant NPC animations. Do not load every nation or city at once.
5. Keep last good ZIP on itch.io; browser storage is device/site-specific and clearing it can delete local progress.

## I. Decisions kept open rather than invented

- Exact geographic orientation and ring assignments of every Magnara landmark.
- Player origins with special bloodlines and the legal training system that grants rare Eyes.
- The official access rules for high-rank Association spaces and advanced examinations.
- Canon-safe player presence during the main cast’s storyline.
- Which portions of the world atlas have final, author-approved geography.
- Platform plan for later native iOS/PC versions and optional co-op.

**Production rule:** If an entry lacks author-confirmed grounding, make it clear that it is a **game-only** experience, never a newly “locked” franchise fact.

---

## The non-negotiable design target

**Fun movement + mechanically distinct Muti + credible living citizens + earned advancement + durable world memory.** These five parts must work together. A bigger world with only static facades is not a substitute for the player's own life in Margerina.
