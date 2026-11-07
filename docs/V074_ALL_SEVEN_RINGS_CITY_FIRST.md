# Seeker's Codex: Young Blood 3D — V0.74 The Seven-Ring Magnara Foundation

## The order of development has changed

**Author instruction: build the footprint and scale of ALL SEVEN rings FIRST.** Magnara must feel enormous and fully connected before continuing with named shops, custom districts, NPC rosters, individual docks, and landmarks. Previous work overly concentrated on one Ring II corridor and made the entire city feel much too small.

V0.54 established a **proposed** one-Godot-unit-per-meter, **26 km diameter (~531 km² circular planning envelope)**, but only showed four plain generic solid blocks per 256 m chunk and nine adjacent chunks. V0.74 turns that abstract geometry into a city-wide framework: all seven concentric rings, circumferential roads, 12 radial connections, dense generic buildings, near collisions, distant skyline and a phone-friendly scale map. It is a planning envelope, not a published canonical diameter or population census.

### World-scale Ring Planning Status

| Ring | Proposed radii (km from temporary survey center) | Game/canon status |
|---|---:|---|
| I | 0–1.0 | Urban core planning shells; exact role and landmarks unassigned |
| II | 1.0–2.6 | **Seeker Quarters**: preserves real original guild, citizens, small canal piers, rooftops and authored locales; fills only unbuilt portions with generic exteriors |
| III | 2.6–4.7 | Urban zoning only; precise cultures and landmark positions unassigned |
| IV | 4.7–6.5 | Public merchant/banking functions are known broadly; individual institutions unplaced |
| V | 6.5–8.7 | Manufacturing/forging functions are known broadly; individual forge/industrial sites unplaced |
| VI | 8.7–10.7 | **Unassigned / outer infrastructure reserve**; explicitly NOT the major seaport |
| VII | 10.7–13.0 | **Outermost port ring**. Iron Cothon/main deepwater seaport belongs here. *Coastline/ship basins stay unplaced until the actual map is approved* |

The original V0.54 geographic dataset incorrectly titled **Ring VI as Iron Cothon/Harbor** and Ring VII as Outer/Soot Wards. The user's November 7 correction places main docks **in outermost Ring VII**. These conflicting older labels are repaired while preserving all seven radii and area measurements. Street placements and radial bearings remain game-only: they are not an author-published cardinal city plan.

## First complete playable city shell

- **7 continuous full-circumference arterials**, each modeled in real-size 3D strips with 192 curve segments per circular road. **12 radial avenues** join the inner city to the outermost ring. These use low-poly world meshes on top of the existing collision-backed, streamed 256 m land tiles; connecting across the entire 26km city is an actual geographic route, not a teleporter or menu.
- Near-city lots: **8×8 potential parcels per 256m tile (64 slots)**, filtered to keep arteries clear, with variable height/shape and ring-appropriate provisional color themes. One MultiMesh batch per walls, roofs, façade windows and horizontal courses. The exact counts depend on open road width and existing published districts. Built city shells never claim actual unique interiors/households or canon addresses.
- The **old four giant V0.54 cubes are suppressed when V0.74 is running**, avoiding geometry stacking and physically blocked highway routes. The standalone V0.54 terrain system and its existing smoke test retain their previous behavior. The original Ring II city/markets/canals/Seeker Citadel/guild route and V0.67–V0.73 published/local buildings are protected by exclusion areas and remain usable.
- **Physical wall collision** activates for at most 34 near-building lots within ~88m; the nine nearby 256m tiles are loaded in small batches, with a cap of 9. Offscreen buildings remain GPU meshes without full rigid-body/physics per building.
- **~1.9km extended urban horizon**: additional distant city silhouettes are flattened into a single bounded GPU MultiMesh, drawn from 512m macro-cells and omitted near full-detail streets. This gives mass and layered depth instead of an abrupt empty outer world and avoids spawning unnecessary physical civilians.
- **CITY MAP on iPhone and desktop:** proportional seven-ring atlas, all 12 radial roads, continuously updated player dot, ring identification, measured proposed distances and Ring VII port restriction. The map deliberately shows no invented shops, named streets or unverified coastline. Closing the map resumes normal movement.

## What “all seven rings built” means here

**The overall structure and traversal layout for all seven rings is implemented.** The outer rings now have procedural street/building *exteriors*, not finished playable interiors, service NPCs, resident families or narrative quests. Land terrain is streamed by V0.54 under the new architectural skeleton. There is **no claim of physically completing 531km² of detailed production art**, and not every possible street is guaranteed a fully constructed bridge, sewer or canal yet. The coastline and actual sea dock geometry are not authored or placed in this release. The previously completed remote maritime physics demo still loads separately, labeled **Ring VII scenic preview**.

This foundation-first order means **V0.75 and beyond** should prioritize correcting the master street/ring geometry, road junctions, citywide performance and building masses before dropping in more individually named businesses or quests. Individual neighborhoods can be gradually authored *inside the approved rings* once city scale and sectors are stable.

## Verification and safe rollout

- `tests/v074_all_seven_ring_rules_scene.tscn`: validate all 7 boundaries, sum to 531km², road access free of generic building obstruction, dense stable deterministic parcels in all seven rings, 1.9km skyline, iPhone budget and Ring VII port restrictions.
- `tests/v074_all_seven_ring_world_scene.tscn`: load real main scene, physically inspect each ring with land collider/ring-road geometry, dense visible buildings plus near collision and long-range skyline, iPhone city map open/close, and original Ring II save recovery.
- Full V0.73.1→V0.54 regression, original V0.46 Seven Spokes, Godot 4.4.1 headless startup, HTML5 Compatibility export. Promote from isolated staging branch to `codex-modular-v31` only if green; never modify original browser game `main`.
- **Device validation still necessary.** GitHub CI proves code executes and Web exports; it does not prove an iPhone can draw all these structures at target FPS, nor has it verified player traversal from one city edge to the other in a single continuous on-device session.
