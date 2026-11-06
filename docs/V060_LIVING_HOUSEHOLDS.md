# Seeker's Codex: V0.60 — Magnara's Living Household Lane

## Objective
Advance the world **first** and make Young Blood's promise, "power remembers," visible through a physically walkable, socially persistent neighborhood rather than a disconnected menu.

### What was implemented
- A **physically connected pedestrian lane** north of the existing eastern Ring Two professional street. Exact local x/z placements are game-only coordinates, not locked descriptions from the novels. This begins near (62, 110) and reaches a courtyard north of the previous playable district, still within the planned 26 km Magnara city envelope.
- **Three enterable, collidable homes**, each with an actual open doorway, floor, roof, room furniture, exterior pedestrian spur and visible house sign. One communal court contains a bench, water-well structure, awning, public board and a **trust-colored lantern**. There is no city teleportation or nationally unapproved geometry.
- Three **game-only everyday residents**: Canal Weaver, Freight Yard Technician, and Quarter Tutor. Every resident is a modest 3D character model, visible in the main Godot world. Their clock-driven positions follow deterministic home → work → public community → home journeys without heavy physics-based NPC navigation. Shift times vary slightly, giving a feeling of independent lives. These NPCs have no canon familial relationship to the main cast.
- TALK / USE uses the moving resident's actual world position. Residents offer three one-per-day social decisions: help household work (+2 trust), listen to concerns (+1 trust), or pressure for favor (-2 trust). Each household keeps an independent record capped to [-6,+6].
- Choices persist under `residential_v060` inside `seeker_profile_v1.json`, with one receipt per in-game day. Repeating a choice for the same resident on the same day is blocked, and the write is read back before announcing a recorded result. The earlier save format remains unchanged and old saves default to neutral neighbors.
- Real reactions: previously helped residents welcome the player; pressured residents become wary. The neighborhood lantern shifts **green** for net trust >=3 and **red** for net trust <=-3, while neutral neighborhoods remain blue.
- An existing **publicly disclosed, unverified Black Clan claim** can provoke cautious questions from a neutral resident. Private lineage histories remain private. No institution, rank, ocular art or inherited privilege is granted by the neighborhood.
- The Personal Codex now shows separate household rapport, help/pressure actions, and total community trust.

### Core code
- `systems/residential_life_v060.gd`: pure deterministic daily schedules, bounded household social records, privacy-aware reactions, repeat-action prevention and source-backed labels.
- `world/magnara_residential_v060.gd`: physical interiors, street, NPC meshes, moving coordinates, mobile-friendly dialogue and visible consequences.
- `scenes/main.tscn`: attaches neighborhood directly to the original scene.
- `systems/hub_manager.gd`, `characters/player_controller.gd`: connects live TALK / USE, blocks movement while the panel is open.
- `systems/personal_codex.gd`: renders household history.
- `tests/v060_residential_smoke.gd`: pure rules + persistence tests.
- `tests/v060_residential_world_smoke.gd`: real world instantiation, physical home collision, resident schedule movement, interaction, modal, social reactions and disk reload.

### What remains unfinished
This is still a prototype slice, not a completed 26 km city, not three fully animated family households with children, and not a complete autonomous NPC simulator. Residents are simple articulated low-poly meshes moved along scripted sidewalk waypoints, not animated action character rigs or trained pathfinding agents. Household interiors have minimal furniture; none are player-owned property. Long-term family businesses, rent, utility bills, pregnancy, marriage, consensual adult romance, schooling, economic markets, dozens of occupations and full 24-hour supply chains remain major systems to construct. No final iPhone graphics/frame-rate or touch-input playtest has occurred.

### Canon and boundaries
The Ring Two quarter, Seeker Association and working canals are established at the setting level; these particular houses, neighbors and local bearing are **provisional game-only compositions**. They do not introduce named canonical characters, official clan affiliation, restricted Citadel access or global terrain coordinates. Year: **1500 A.S.** The beyond-Abyssal lands remain excluded, matching `data/known_world_v054.json`.

### Production plan
The next world-first work should extend the larger footprint of Magnara using source-locked districts, meaningful transport corridors and distinctive class environments: **workshops, wealthier residences, poor outer wards, real working markets, and industrial logistics**. Family contracts and chosen relationships should increasingly be attached to these physical places. Before release, ensure UI responsiveness on an actual iPhone and build crash-safe multi-file transactions.

**Testing:** full Godot 4.4.1 import/startup, V0.48–V0.59 regressions, V0.60 pure/scene tests and browser export must all pass on staging before any development-branch promotion. Do not publish or modify `main`.
