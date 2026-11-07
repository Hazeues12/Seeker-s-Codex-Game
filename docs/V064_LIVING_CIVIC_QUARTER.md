# Seeker's Codex — Young Blood 3D / V0.64 Living Civic Quarter

**Scope:** physically connected Magnara Ring II extension, 1500 A.S. **Provenance:** game-only prototype; all new coordinates, service clerks, building shapes, NPC schedules and prices are provisional gameplay details rather than canonized city geography.

## What V0.64 builds

A new roughly 137-meter northern set of streets continues all three V0.62 public market north-south roads. Two more east-west cross avenues connect those three streets. They have real collidable 3D surfaces, pavements, lighting, signs, and a public notice plinth. Three actually enterable public-service buildings stand off the streets, each with an open collision-correct doorway, physical floor and roof, counter, interior furniture and a pedestrian approach. Standard mobile TALK / USE and touch menus reach every building.

Services:

- **Traveler's inn:** 24-hour staffed counter, 18 Tola per room-day, one booking per in-game day. A paid booking permits **one** rest until 06:00 the following in-game morning, restoring the current ordinary stamina and aura values. At least two beds and a locker are built; no player property deed, lease or ownership system is claimed.
- **Civic wayfinding and records counter:** staffed 09:00–17:00; free direction board and voluntary records assistance paying 5 Tola once per in-game day. This is civilian municipal paperwork, **not** official Association certification or an invented promotion.
- **Neighborhood clinic:** staffed 07:00–20:00; free ordinary care guidance and a basic 7-Tola rest/recovery service. This restores the current prototype aura/stamina bars, **not** permanent injuries, forbidden techniques or irreversible supernatural conditions.

Staff have day-dependent active/absent presence with small on-duty movement. This is a **schedule/visibility prototype**, not free-roaming AI or crowded simulation.

## Real persistence

`systems/magnara_civic_rules_v064.gd` contains deterministic opening hours, bounded prices and four day-stamped receipt types (`nights`, `slept`, `treatments`, `helped`), accepting only valid day keys and booleans. Each action changes GameState Tola, the hub's current in-game time and/or current energy, and civic receipts in a **single verified V0.63 world-save write** at `user://margerina_v033.json`. All live values are rolled back if the disk-verified commit fails. Old saves default to an empty civic record. Daily limits prevent duplicate payments/benefits for the same service-day.

For successful services a dated game-only history entry is separately recorded in the Personal Codex. Personal Codex and world save are still separate files; two-file atomicity is not claimed. Previous market, workshop, residences, player creator, Seven Spokes prototype, story route, family archive, iPhone controls and exploration remain attached.

## Validation contract

- `tests/v064_civic_rules_scene.tscn` checks exact hours, fees, day counting, paid-room eligibility, repeat-use prevention and malformed ledger rejection.
- `tests/v064_civic_world_scene.tscn` instantiates the whole main game, checks physical floors, roof, doorways, beds, record shelves, staff, collision, connected street access, real TALK / USE, day changes, Tola, replay prevention, saving/reloading and old district retention.
- Staging workflow requires headless Godot 4.4.1 import/startup, both V0.64 tests, preexisting V0.63 save integrity, V0.62 market trading, V0.61 workshops, V0.54 geography and a Web export.
- Only after green staging checks should changes land in `codex-modular-v31`. The original `main` browser-game branch stays untouched.

## Limits and next construction priority

City meshes and civic-service staff are lightweight placeholder art. Lodging does not yet place the character asleep in a persistent room interior; the bed exists physically but room booking and time advance are managed through the service interface. No population-scale crowds, functioning healthcare career, complex inns, regional rail, deed economy or full 531 km² metropolis is claimed. Continued broader Ring III/Ring IV expansion must respect the approved city atlas and geography. No immediate manual iPhone test is required during world construction.
