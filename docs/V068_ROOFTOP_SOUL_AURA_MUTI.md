# Seeker's Codex: Young Blood 3D — V0.68 Rooftop Freedom and Soul/Aura/Muti Components

**Engine**: Godot 4.4.1 (GDScript + C++ physics, Web/iPhone renderer). **Branches**: only update `codex-modular-v31` after green staging. The historic browser `main` stays untouched. **Era**: 1500 A.S. Magnara; procedural northern Ring Two terrain and public district schedules remain GAME ONLY.

## Why this version follows the Gemini ideas in Godot

The current project already uses Godot for 3D rendering, camera, joystick, double jump, water run, wall run, collision, streaming, guild-life, saves and Web HTML5 exports. Switching to Python or Unreal now would unnecessarily destroy continuity and iPhone support. Implement the ECS **design pattern** in GDScript as data-driven composable dictionaries and pure functions first, then move hot-path computations to more efficient Godot components if profiling indicates need.

### A. Real street-to-roof and roof-to-roof movement (priority)

`systems/magnara_roof_rules_v068.gd` procedurally derives stable public rooftop routes from the six-parcel modular building geometry in V0.67:

- **Six actual collidable rooftop decks per chunk** aligned to the existing GPU-instanced roof mesh height.
- **Two street-to-roof access paths per chunk**, one on each side, via visible jumpable public stair scaffolds. Each vertical rise is at most 1.45m, with stable, predictable landings. These are real `StaticBody3D` planks, not a teleport or a cosmetic roof texture.
- **Roof-to-roof maintenance stepping planks** linking each side's three buildings; linked routes also cross to the next streamed 128m chunk. No floating long jump is required. The routes are visible maintenance structures; plank pitch adapts to different randomly generated floor counts. Across the roof connections, vertical differences remain within the same safe bound for landing and jumping.
- The existing two-jump / sprint / wall-running controller already supports the movement; **RUN + JUMP** to climb from street, **double-jump** to hop from one roof to the next. Keep momentum. Each building has a physics-backed landing. The physical network is created/deleted with its world chunk.
- Collision for roof decks, building shells and stepping planks is enabled only near the player to protect mobile frame budget; distant physics stays inactive. Landing and wall collision are tested in the full Godot scene. The player is not restricted to a flat two-dimensional road.

**Limit**: This expands functional parkour through the *15-chunk provisional northern district* only. It does not automatically make every older interior or all countries climbable. Future traversal includes ledge mantling, accessible interiors, rooftop rail and descent safety, climbing/zipline rules appropriate to the story, vehicles, elevation changes, and uninterrupted travel between built zones.

### B. Soul → Aura (Bucket and Tap) → Muti → Technique

`data/seeker_power_components_v068.json` provides a versioned metadata catalog; `systems/seeker_power_rules_v068.gd` validates identity, the Aura reservoir, output tap, replenishment, purity/control, seven established Muti Spokes, technique Aura requirements, lineage, startup time, trajectory and stage permission.

- Public basic strike `martial_pulse_v034` retains **12 Aura + 4 Stamina** and still uses the real V0.35 hit detection; it now passes through the four-layer check.
- Existing `systems/seven_spokes_training.gd` retains its costs (Martial 14, Elemental 20, Spirit 18, Alchemy 22, Psychic 21, Spatial 24, Abyssal 28). Its ordinary simulation is playable only at the supervised training yard; beginner casts are not permanent powers or high-tier mastery.
- If a real character's current aura is insufficient, their output cap is low, or required publicly granted Spoke is absent, the model rejects the technique. High rarity Celestial/ocular access is blocked in basic training.
- Public relic metadata references staff Sun, Tetsuba, known sword inventory and their user-visible lineage, with **no private hidden tags** in the exported file. More complete relic reaction and karma continuity require properly authored future content rather than fabricated automatic hostility.
- The model's Soul identity, Will and flame are **gameplay metadata**. The deeper cosmic soul-cycling purpose of the **Archwheel**, secret to five current-story people in the creator's canon, is intentionally **not simulated or revealed** to ordinary players, and there is **no automatic story-character reincarnation on KO**.
- `authored_eye_preview` has a strict story gate for Rin and only exposes public attack telemetry in a scripted situation. A generic Migeika copy loop, stage-based mastery and global time slowdown are intentionally **not** implemented from guesses.
- `supervised_domain` and `aura_output_at` support a game-only temporary *local* aura-output multiplier (within radius, without altering base-world physics). This proves the rule resolver for later authored Ryōiki effects, but does not grant Cyrus' Pale Desert, Seizen's Black Shrine, or other restricted domains to civilians or players.

### C. Public quarter time/economy pulse

`world/magnara_public_pulse_v068.gd` adds a real collidable information kiosk near the link from the published shops to northern roof district (around x=13.4, z=712). Interact using TALK/USE: observe game day/hour, current public local shift, recorded daily unit sales from the existing verified V0.66 shop ledger, and the Soul/Aura/Muti/Technique chain. It never spends Tola, modifies business prices, creates unverified international exchange rates, or invents faction political control. The public bulletin logs discovery in the Personal Codex.

**Macro-economy and clandestine faction mechanics** remain unactivated. The Gemini example of 9T–16T, Phantom Tola exchange rates, automatic Red Order ring occupation and secrecy leaks require separate author-verified facts and a game design decision. All global faction politics and active espionage remain plot-gated, outside the public civilian simulation.

### D. Anime look on mobile

V0.67's building modules and close models now apply Godot's built-in `BaseMaterial3D.DIFFUSE_TOON` with low specular cost in the Compatibility renderer, and the public kiosk uses the same. This is a **first-pass anime material** rather than a custom multi-band cel shader with complex ink outlines, custom shadows or a guarantee of thousands of high-detail NPCs. Building GPU instancing and LOD remain central to iPhone performance.

[Godot official StandardMaterial3D Toon diffuse](https://docs.godotengine.org/en/4.4/classes/class_basematerial3d.html) · [Godot CharacterBody3D move_and_slide and floor snaps](https://docs.godotengine.org/en/4.4/classes/class_characterbody3d.html).

## Validation / CI gates

- `tests/v068_roof_power_rules_scene.tscn`: verifies rooftop geometry in all 15 chunks (rise and gap safety, deterministic regeneration, bounded collider budget), all seven supervised Spokes unchanged, pure technique authorizations, Aura recovery/output vs reserve, story-locked characters and domains, local-only sandbox law overrides, fake exchange rates forbidden.
- `tests/v068_roof_world_scene.tscn`: loads full 3D Godot world, streams 9 chunks, verifies active stair/bridge MultiMeshes and actual rooftop/stair raycast landing physics, confirms unloading/reloading, tests public bulletin interactions and correct 12-Aura/4-Stamina Martial strike.
- Regression suite: V0.67 streamed city, V0.66 physical published shops, V0.65 public canon cast, V0.64 civic work/inn/clinic, V0.63 verified save, V0.62 market, V0.61 workshops, V0.54 geography and Web export.
- Final development branch Web build must pass again after staging promotion.

Device validation remains needed for iPhone Safari FPS, invisible wall clipping, sudden fast-teleport chunk updates, stair landing ergonomics, GPU drawcalls, thermals and upload/download build performance. **Godot CI does not automatically prove good frame rate or full platform reachability on a phone.**

## Later phases

1. Real cinematic 3D anime outfits, character-authored weapon rigs, affordable outline passes for hero units, sampled animation and unique combat effects.
2. Individual canon character obligations, guilds, families, squads and story mission timelines. More actual guild and shop interiors, then complete Magnara ring-by-ring.
3. Reactive public lineage metadata only for author-confirmed situations, player-owned techniques and Kairo eye features gated to scripted combat. Local Ryōiki physics volumes with authoritative battle rules, then larger spatial subframes.
4. Background regional economics using verified playable supply chains; faction politics only when storyline and hidden-knowledge safeguards are approved.
5. Author-approved Archwheel consequences when the story permits it, with spoiler-safe public gameplay and immutable canon character deaths/stakes; never implement auto-Kai/William reincarnation as a default game-over trick.
