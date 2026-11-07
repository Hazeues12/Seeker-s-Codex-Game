# Seeker's Codex: Young Blood 3D — V0.69 Triad Practice, Alchemic Seals and Public Guild Life

**Engine:** Godot 4.4.1/GDScript, 3D Compatibility/Web export with iPhone-style joystick and touch panels.

**Continuity:** 1500 A.S. known-world Margerina; Seeker's Codex lore-first. **Branch:** `codex-modular-v31`; original browser game `main` untouched. All newly generated training routines, public fees, and assignments are explicitly **game-only**. Sensitive facts, unrevealed personhood violations and the true Archwheel mechanisms remain absent from public client data.

## The Triad of Will and combat posture

Triad of Will: **Sight / Kyōmei-shi** is the most accessible of the three disciplines but still requires earned mentor/story authorization; **Steel / Kōshin** is Gold+; **Sovereignty / Ōi** is Grand+. William is a rare instructor and his expertise does **not** cause new players to receive three powers for free.

`combat/triad_posture_rules_v069.gd` explicitly differentiates ordinary **balance/posture** (all mortals have some, including non-Seekers) from the rare **Steel Will** technique. Everyone may train to keep balance, raise a defensive guard or time a reflex parry in the novice yard. Enhanced Sight windows require a story-approved Sight license; more powerful regeneration for trained Steel requires Gold+ **and** an individualized creator gate. An Ōi proximity calculation is only callable for authored Grand+ encounters, never a global crowd-stunning button or automatic citywide civilian attack.

Live integration:
- The player's existing mobile toggle **GUARD**, or **G** on desktop, opens a very short reflex parry of **0.13 s** when raised. A perfect parry (after 5 Stamina) avoids damage and pressures the nearest *actual hostile sparring construct*. Repeated sustained guarding reduces an ordinary character's balance and can break their posture. HUD exposes `POSTURE xx/100` and stagger time.
- Purple sparring constructs have posture, recovery and a brief stagger vulnerability when balance reaches zero. The next landed hit during the break is a stronger critical (1.45x). The existing attack range, hitboxes, health, KO and reset mechanics remain in use.
- These are public **combat-school play mechanics**, not a claim the player mastered the Will disciplines, or that all high-level Seekers are pressure-knockdown NPCs.

## Programming Alchemic seals: finite, secure and playable

`systems/alchemic_seal_rules_v069.gd` is a 3-rune visual programming interpreter, not arbitrary Python/GDScript execution:

1. **Trigger:** on impact, or when enough Aura is available.
2. **Condition:** `Aura >= cost`.
3. **Effect:** 18-Aura one-hit defensive ward or an 8-Aura nonharmful report signal.

The physical `world/seal_training_bench_v069.gd` at the public training-yard edge (game-only x14.8,z-24.2) exposes clickable mobile buttons, encodes the sequence, arms it, and persists the verified recipe/one-use-per-in-game-day receipts to the existing Personal Codex profile. A one-hit ward **actually intercepts** an incoming attack in the existing `CombatArena`; Aura expenditure and the world save must validate before it fires. Repeating the same trigger on the same day cannot provide infinite free shields.

**Canon boundaries:** This table is a supervised *Seeker Quarters practice* installation; it is **not** Hollow Thread Atelier's actual Ring V site. Users cannot program arbitrary teleports, dangerous elemental blasts, forced memory erasure, illicit Osteomorph alteration or unearned Muti via string evaluation. More complex equipment-attachment rules need legal and lore-confirmed prerequisites, actual craft inputs, wearables and combat attachments.

## Rank-aware Association/public civic work

`systems/guild_public_director_v069.gd` creates **three rotating, observable local operations** per day, with rewards generated deterministically from a bounded daily count of *real prototype shop transactions*:
- **Shop Watch** — Stray+ civic observation at an actual outer-quarter shopping approach.
- **Rooftop Route Safety** — Iron+ simple public roof inspection.
- **Training Yard Watch** — Iron+ safe supervision report at the public training yard.

`world/public_guild_director_v069.gd` creates a real public Seeker Association/civic notice board near x16,z8 and three reachable target markers on city routes. The player accepts a task, physically travels to its destination, uses **TALK/USE**, and is paid once per job/day. Accepted/finished daily tasks and one-time Tola rewards are saved together in the existing V0.63 verified world-save format, compatible with the V0.62 market and V0.66 businesses. An assignment expires on the next day unless completed. No free rank promotions or speculative permanent Seeker licenses; the civilian-friendly public observation mission isn't an official Iron-Seeker contract.

There is **no fabricated Phantom Tola economic feed**, Red Order occupation of Ring VII, algorithmic assignment of Pillars, or unverified Grand raid reward. These could only become authored high-rank campaigns once the corresponding story events and fictional economy details are approved. The family and guild affiliation data still come from the canon registry and character story gates.

## More freedom on actual established rooftops

`world/magnara_legacy_roofways_v069.gd` adds **four real eight-step public access ramps** up to existing V0.65 Talking Boar and V0.66 Le'Bell's/Avicci/Vernal Divongcci roofs. These buildings already had physical roof colliders, but previously lacked access from adjacent streets. A 16-plank elevated game-only maintenance walk links the western roofs of Le'Bell's and Vernal, enabling continuous roof exploration on that side. This complements V0.68's streaming high-rise parkour in the northern block area.

The new approach scaffolds are real collidable `StaticBody3D` platforms and stylized low-cost Toon meshes. They leave doorways and interiors intact. Jump and double jump continue from the existing mobile controls.

**Limit:** These are prototype public access paths, **not** a fully authored climb-anywhere system over every building or the entire known world. Later improvements include lip grabs, vertical ledge mantles, rope/rail travel, continuous open-world high-speed parkour and streaming-aware moving platforms. The official guild/shop architecture still needs final character and environmental art.

## Other supplied concepts mapped safely

- **High-speed Aura impulses:** design an original *game-only* burst for traversal after movement/RAM profiling; preserve Kai's Hanuman Step and Aria's Spark Rush as canon-story techniques, not freely learnable novice actions.
- **Rail transport:** use path-follow motion and train-carrier velocity/moving platforms. Don't parent/unparent a CharacterBody3D without handling world transforms, collisions and rollback; wait until the authentic Janoah station/route is authored.
- **Spatial Trialboards and portals:** requires approved Spatial-spoke access and a streamed destination; no generic teleport into an unpublished domain. Implement portal/physics abstraction only after plot gates are mapped.
- **Abyssal Line:** world beyond the known geography remains future content and story gated; no fabricated ocean Leviathan spawns or endgame hazards inside Magnara.
- **Soul crimes and Association heat:** illegal Muti and personhood violations need author-approved legal taxonomy, evidence, jurisdiction, safeguards against false detection, and high-level NPC scheduling; no auto-Pillar hunting based on a simple heat number.
- **Eidolons:** major externalized soul entities and boss phases are **scripted encounters** with canonical summon contracts and phase thresholds, not an automatic Seizen Shinigami spawn at arbitrary HP or plot-era.
- **Arcwheel:** its true function is held by five current-story characters per the creator's secret-canon notes. No public client-visible implementation or automatic reincarnation of Kai/William after a generic KO.

## Test/approval gates

- `tests/v069_will_seals_guild_rules_scene.tscn` — rank/story Will gates, physical posture/parry thresholds, anti-script seal grammar/one-use ledgers, rank-aware civic tasks, no-repeat payouts and no secret occupation injections.
- `tests/v069_will_seals_guild_world_scene.tscn` — full Godot scene, four collidable old-building roof stairways, physical west roof catwalk raycast, actual construct pressure/parry/guard damage, mobile-seal UI, persistent one-hit defensive ward, public Association board, real world marker, verified Tola and mission ledger on save/reload, previous districts preserved.
- Regressions V0.68 actual roof hops/verified Aura, V0.67 streaming, V0.66 published shops, V0.65 canon population, V0.64 civic, V0.63 atomic save, V0.62 market, V0.61 working quarter, V0.54 known-world geometry plus V0.46 Seven Spokes.
- Official `Repair and Build Margerina` on `codex-modular-v31` must export Web again after staging suite green.

**Device gate still open:** iPhone Safari FPS/thermal performance, accurate GUARD touch timing, 2-finger input, roof step landing, working UI hit areas and background tab storage persistence. Headless Godot test is necessary but not a substitute for device playtesting.
