# Seeker’s Codex — V0.55 Janoah Regional Approaches

## World-first development
This milestone builds a real streamed Janoah landscape immediately beyond Magnara’s proposed outer urban envelope. The 26 km Magnara planning diameter, local X/Z compass bearing, road and rail routes are **author-editable game-planning geometry**, not settled chapter geography. No release or mobile playtest is requested yet.

## Physical 3D deliverable
- From the outer tile boundary at local X=11,392m to X=17,536m, construct a **6,144-meter-long provisional route**; 768m total lateral width.
- Terrain uses 256m x 256m cells, a generated 17 x 17 grid of terrain vertices per cell (16 samples per side), actual triangle collision shapes and continuous procedural heights. Terrain gets gently taller away from level road and freight corridors.
- Separate visual land-use phases: industrial edge (4 cell columns), cultivated countryside (8), rolling interior countryside (12). These are game-only Janoah landscape studies, not assigned historic regional names or coastlines.
- A continuous 14-meter road with shoulders; adjacent dry freight rail on a gravel bed. Track is structural scenery and does not operate a train. These corridors are connected to the existing Magnara terrain's road centerline at Z=70m.
- Three simple collidable roadside waystations, sparse low-poly trees, limited cargo storage and rocks. Waystation IDs are temporary; no NPCs or services are invented.
- Load at most 3x3 cells around the player. Outside the corridor, this system stays unloaded. The old 256m city grid still owns its own existing territory.
- Preserve all existing main-scene nodes, mobile controls, combat, Personal Codex, V0.33 save structure and older mission histories. Extend position validation to the newly collidable region.

## Source locks
Janoah is an industrial republic with rail, guilds, factories, international travel and firearms. The **spatial orientation of this route is provisional**, so it does not lock a real national border or imply a canonical city exit direction. No known-world coastlines, unapproved capital names, continents, Abyssal-Line destinations or foreign-city coordinates are generated. The data records remain editable.

**Game files:** `world/janoah_approach_v055.gd`, `data/janoah_approach_v055.json`, `data/known_world_v054.json`, the V0.54 ring geometry and the `scenes/main.tscn` integration.

## Technical verification
- Validate the manifest against the known-world source registry and block false country-border or coastal geography.
- Import and start the complete Godot game with V0.55 loaded.
- Run V0.48–V0.54 mission, companion, personal decisions, district, six physical interiors and geographic registry regression tests.
- In an independent Godot 3D scene, stream representative local tiles from the Janoah industrial edge to countryside and hills, inspect the colliders, perform ground raycasts, verify three waystations, test the exact city/regional boundary, region safe-save bounds, phase changes and dynamic tile unloading.
- Export Web artifacts only for internal development and promote the tested staging branch via safe non-force fast-forward to `codex-modular-v31`. Preserve the original `main`.

## Remaining major world work
The geographic registry is still abstract, and the full known-world continents are unbuilt. We still need author-approved national borders, authentic landscape identities, connected regional travel with vehicles and time passage, real transport stations, unique cities and cultures, designed architectural assets, wildlife, villages, seasonal variations, and actual mobile Safari testing. **The successful Godot CI test will not mean a complete open-world RPG.**
