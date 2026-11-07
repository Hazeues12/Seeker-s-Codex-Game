# Seeker's Codex: Young Blood 3D — V0.75 City Streets First, Then Combat Systems

## Direct creator mandate: Magnara must FEEL enormous before further landmark placement

V0.74 established an editable *planning* footprint of **26 km across** and **~531 km²**, seven 1:1 metropolitan rings, 12 radial avenues, 7 circumferential routes and streamed urban exteriors. V0.75 concentrates on street-scale architectural density and connected roadway intersections. These dimensions/compass routes are **game-only planning measurements**, not locked official story map facts.

### Implemented in V0.75

- **Local streets in all 7 rings:** a 28m lattice of 32m-length road sections nestled **between** existing V0.74 block parcel rows, with pedestrian shoulder stripes and tile-boundary seam lanes. The 12 wide radial and 7 wide circular arterial roads remain authoritative; no invented navigable inter-ring waterways.
- **Roadways are on actually collidable V0.54 land**. V0.75 roads are low-cost GPU surface overlays on top of existing solid land; it does not individually create 531 km² of lane colliders. Building walls remain V0.74 proximity-activated physics shapes.
- **City skyline becomes less repetitive:** every visible base-building slot receives a deterministic, low-poly roof crown shape and two street-facing facade band/awning meshes. Vary the roof form and height by lot and ring. This is exterior-only geometry; there is no claim of finished building plans/interiors/NPC households outside already-authored Ring II.
- **84 arterial junctions:** all 7 ring roads intersect all 12 radial avenues at their actual previously rendered world coordinates. Up to **five** 3D wayfinding markers can appear near the player, without creating canon addresses or physically blocking avenue access. The existing phone CITY MAP displays proportional dots at all 84 intersections and the player's location.
- **Streaming and iPhone budget:** detail nodes attach only to up to nine previously streamed V0.74 near-tiles, and unload when their parent tiles go away. Each tile uses one mesh for its small street network and a maximum of two additional GPU instanced groups for roofs and exterior detailing. No independent dynamic light per lamppost, no speculative crowd spawn or fake port interconnect.
- **Seeker Quarters protected:** the original Ring II authored street, old rooftop course, Talking Boar, established shop entrances, residents and save system are never overwritten by hypothetical generic architecture. The outermost **Ring VII** is the only approved **main maritime port ring**; exact coastline, docks and Iron Cothon orientation remain unplaced.

### More lore ideas — tracked, not prematurely treated as canon gameplay

The new ideas for Rin's stances, conversion, Faye's medium summons and the God Tree's Stutter are strong long-term **candidate systems**. The correct game runtime is **Godot 4 / GDScript**, not an independent Python physics loop.

1. **Seamless weapon stances:** use stateful input buffers, animation transitions and weapon-model sockets, preserving current hitbox timing and running/jumping. Rin's **Tetsuba** and **Chi no Ryōken** have prior source mentions, but a **Yoru Oni** simultaneous-arsenal lock and the exact chronology of which weapons he carries together must be author-verified. Do not grant his swords to player-created characters or leak unearned canonical power. A tracking overlay for Chi no Ryōken requires its currently revealed Bloodhound/vision chronology to be explicitly confirmed.
2. **Technique Conversion / Muti Conversion:** separate the general idea of imitating animation timing from **extremely rare authored conversions** that can replace Muti substance. Neither is available to ordinary Seekers by default. Artemis Flamehart's projectile conversion is an **example proposal pending canon verification**, not an always-on ability for all ice users.
3. **Medium-required summons:** test actual raycast collision metadata tags and required summoning media, using allow-listed environment mediums and anti-teleport collision checks; never equate an Eidolon with a contract summon. Faye Wonder's Ossuary Hound / bone substrate is a proposal to confirm before published character ability data is changed.
4. **Stutter / soul-world pressure:** **story-gated, spoiler-sensitive** God Tree degradation may someday affect Aura recovery only through authored plot events. Do not arbitrarily decrease global recovery as the player gains XP, reveal hidden Soul/Archwheel cosmology to ordinary NPCs, or apply an unverified global nerf to all characters. Need confirmed chapter trigger events, unaffected groups, persistence rules and narrative consequences. Public exploration remains unchanged.

These are backlog entries, **not V0.75 gameplay unlocks**. The priority remains a seamless, convincingly enormous Magnara with authored city culture, transport routes, weather/water and all rings physically settled first.

## Tests and next steps

- `tests/v075_connected_streets_rules_scene.tscn`: verify 84 road junction positions, durable local lane seams and parcel clearance, distinct architectural shape variation in all seven rings, streaming caps, original Ring II exclusion, no invented national coastlines/places.
- `tests/v075_connected_streets_world_scene.tscn`: load the full real 3D Godot scene, teleport through all seven rings to inspect streets/roof meshes, verify loaded parent chunks/nearby junction signs, and protect the old Ring II save and business districts.
- CI must pass V0.75 validation, full V0.74→V0.54 regression and Web export before promotion to `codex-modular-v31`; original JSX browser game on `main` is never replaced.
- **Next urban pass:** address topography, scale of the city walls/gates and street-cut junction transitions, wider varieties of industrial/market/residential skyline at metropolitan scale, occlusion/LOD and real iPhone thermal performance. Only then fill already-placed ring blocks with historically/canon-accurate NPC cultures and authored landmarks.

**Device caveat:** GitHub headless and Web CI prove structural consistency, not guaranteed iPhone target FPS, smooth touch feel, or tested 26km continuous travel on a real device.
