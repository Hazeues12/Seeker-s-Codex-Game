# Seeker's Codex: Young Blood 3D — V0.71 Larger Magnara, Weather Ocean, Maritime and Land Commerce

**Engine:** Godot 4.4.1 Web/Compatibility; iPhone-first. **Story era:** 1500 A.S. **Scope:** Known World only; no beyond-the-Abyssal content or speculative high-level antagonist spawns.

## Geographic canon and honest boundaries

Established names/systems: **Margerina, Janoah, Magnara's seven rings, Ring II Seeker Quarters, Iron Cothon (public commercial and restricted military basins), Janoah Sea, Gulf of Janoah, South Chun Sea, Tsarian Straits, Britannia Strait, Viridian Sea, Lake Lukka (Africanus's largest lake)**, and named waters in the creator's atlas. The existing V0.56 Janoah approach river and its two bridges are explicitly **game-only provisional** because its name, course, crossings and actual country coastline were never locked. **Emerald River, Lake Tsar, Lake Silva, and Lake Lucia/Lucita have no confirmed local coordinates/appropriate nation assignments** in current integrated game data; do not draw them in arbitrary nations.

The public Iron Cothon commercial-sailing survey is a **distant playable 1km scenic prototype** accessed through a public counter in Magnara. The scene's remote coordinate, quay/pier shapes, crews, schedules and exact shipping lane pairings are **not canonical map geography**. The military basin is never open to random civilians; there is no ship beyond the Abyssal Line. Countries not yet physically authored remain destinations *in simulation*, not claimable continuous crossings.

## Magnara expanded to 45 public 128m blocks

V0.67 retains **15** physically streamed Ring II cells (90 six-parcel buildings, 75 game-only residents). V0.71 adds **30 contiguous adjacent blocks** in a second, independent renderer:

- **180 new GPU-instanced building shells** (homes, tenements, workshops, shop shells, warehouses and guild-tenant massing), with simple per-floor windows, roof, awnings and balconies. Added to V0.67: **270 building shells** across 45 streamed cells, excluding all older authored venues.
- **360 additional distinct scheduled civilian profiles**, linked into **120 3-resident game-only households**; added to V0.67's 75: **435** original generated public civilians, *in addition to* V0.65/V0.66's separate established NPC work. New citizens have occupations, personality tags, home and work parcels, timed commuting/work/rest patterns and approachable job/household conversations stored in Personal Codex.
- Dynamic three-band LOD (under 20m full multi-part 3D/collision, up to 100m grouped GPU silhouettes, beyond 100m unloaded/hidden), per-cell 2-at-a-time construction and nine-neighbor cap, physical walls, roofs, several per-building stair approaches, and stepping decks between nearby roofs. New city street axes join V0.67 at x=±192m and z=1360m.
- All newer citizens and new building coordinates are **GAME ONLY**, never spawned as Kai, Rin, Aria, Lila, Seizen, a Pillar or any sealed faction. Buildings remain scaffolded external massing, not hundreds of final bespoke enterable interiors or original character outfits. Don't count a permanent NPC/house as physically loaded simultaneously.

Code: `systems/magnara_expansion_rules_v071.gd`, `world/magnara_expanded_wards_v071.gd`.

## More lifelike water and real water physics

`shaders/margerina_coastal_waves_v071.gdshader` renders an animated 1km subdivided water plane, with **three interfering travelling waves**, locally computed surface normals, viewing-angle Fresnel reflections, shallower water/outer sea gradients, multiple glints and wave-crest foam. Wind and sea weather are deterministic **in-game**, varying with the day. Wave amplitudes increase with distance from the sheltered coast and with wind. This is specifically tuned for Web/iPhone **Compatibility renderer**, not a claim of actual ray-traced reflections, refraction, volumetric foam, GPU compute FFT, or perfect ocean realism.

`systems/ocean_hydrodynamics_v071.gd` mirrors the GPU wave equation in CPU physics: `surface_height(x,z,t,wind)`, `surface_normal`, `buoyancy` sampling **four different points** for ship heave, pitch and roll. Real `AnimatableBody3D` hulls with deck colliders can be jumped onto from physical finger-piers. The existing player controller now queries water height and uses actual swimming/vertical surface recovery, damping and inland river current. Water is not a solid collision plane. A safety respawn at the scenic harbor protects players who fall into the unsupported deep seabed; **no Archwheel reincarnation** or canonical deaths inferred.

The Janoah game's V0.56 provincial river still flows over the same protected road/freight bridge terrain. New `shaders/margerina_river_currents_v071.gdshader` gives directional ripples, small surface normals and current foam; CPU-sampled water surface and current are confined to the established provisional river tile. Existing bridge/canyon collision remains.

## Ships and real local commerce traffic

`data/margerina_water_commerce_registry_v071.json` is the source-of-truth *label* registry for 16 named water features, harbor access boundaries and **hypothetical game-only trade routes**. `systems/margerina_commerce_rules_v071.gd` makes deterministic per-day public shipping manifests and city freight schedules.

- The playable harbor shows **six actively moving vessels**: two small, two medium cargo ships and two large merchant vessels. Each has a real solid deck and cargo crates, distinct hull dimensions/draft, a crew/cargo listing, a safe berth and wave-driven motion (weather/nearshore effects). **18 original dock workers** and cargo warehouses/stock piles occupy the public quays. The harbour is an interactive scenic visit from an existing Magnara street, automatically unloaded after leaving.
- World destination labels cover known nations **Chun, Britannia, Rajistan, Germania, Americana and Vinlan** as **game-only trade previews**. The ships appear to arrive/depart at their local quay/horizon, and a public board reports simulations. **They do not yet traverse canon-confirmed shore-to-shore distances or carry actual verified intercontinental contracts**.
- The actual Ring II roads also have **three collidable moving cargo wagons** with visible freight and bounded deterministic routes. They are labeled as proposed merchant transfer corridors to **Rajistan, Chun and Britannia**, not proof these particular national road crossings were confirmed. They do not create free player Tola or secretly change merchant stock, national diplomacy or guild rank.

Code: `world/margerina_ocean_commerce_v071.gd`, `world/margerina_land_commerce_v071.gd`.

## What's next as the game expands

1. Finish **quality** inside these new wards: real building plans and interiors, regional families, artisan workshops, fully animated NPCs and guild markets, multi-lot neighborhoods and quality object materials, not just extra shells.
2. Elevate water toward higher fidelity: shore slope, shallow-water refraction approximation, wakes, spray, foam at rock contact, underwater lighting, interaction-based swimming/diving/boat steering and performance tiering. Profile iPhone thermal, frame pacing, memory and loading after entering/leaving the 1km sea tile.
3. Author-approve the real **Iron Cothon coastline**, mapped lake and river positions, continent/country connections and official trade lanes before moving this preview onto the real Margerina map.
4. Build physical country roads/sea regions incrementally with 3D navigable vessels, freight terminals, docks, town labor markets and real regional supply/demand. Preserve coast/military boundaries, NPC schedules and story restrictions.

## Automated validation

- `tests/v071_city_ocean_rules_scene.tscn`: 30 non-overlapping cells, exactly 180 shells, 360 identities and 120 households, reproducible schedules, 20m/100m LOD, bounded wave height/normal, four-point weather-dependent buoyancy, ship classes, all water canon tags, no Abyssal beyond-line spawns.
- `tests/v071_city_ocean_world_scene.tscn`: actual Godot gameplay scene, loaded close NPC interaction and physical roof raycast, distant chunk unload, real sea shader, six buoyant ship decks and physical river current, ocean swimming, safe-save/return from remote harbor and 3 freight wagons.
- All legacy V0.70→V0.54 regression scenes plus Seven Spokes and HTML5 export in staging. Promote to `codex-modular-v31` only after green staging and final development build; do not alter browser game `main`.

**Unfinished truth:** A 1km survey tile and local visual shipping loops are not a globally continuous sea with all intercountry trade simulated. Hardware device FPS, visual quality and ship boarding convenience remain to be tested on an actual iPhone.
