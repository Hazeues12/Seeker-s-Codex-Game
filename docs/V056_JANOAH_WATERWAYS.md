# Seeker's Codex — V0.56 Janoah Waterways and Rural Crossings

**Era:** 1500 A.S.  
**Area:** 6.144 km provisional Janoah transport corridor outside Magnara's proposed 26 km footprint.  
**Continuity:** All names, bridge locations, local bearings and the river course in this milestone are **game-only engineering placeholders** pending an author-approved continent map.

## Physical environment created

1. A north/south meandering *unnamed prototype river* crosses the route near local world x = 15,360m, z = 70m. Its course is derived from continuous world coordinates and is independent of terrain-tile creation order.
2. The channel is **carved into V0.55's actual triangle collision terrain** with sloping riverbanks and a bed around -3.1m; the visible water plane sits near -1.75m. This is a visually readable river, not a working swimming or boat simulation.
3. Separate **solid road bridge and freight trestle** cross the river. Both carry collision; road parapets, service pier supports and banks are positioned away from the road centerline.
4. The road and freight bed immediately beyond both ends of the bridge remain joined to the previous tile geometry; no fabricated cross-country railway station or train travel is claimed.
5. The channel is represented by three separate **256m river cells** for the local north/central/south band. Mesh vertices use the same deterministic world-space course to avoid cracks at tile boundaries.
6. A low-cost, Janoah-specific **regional environment palette** separates industrial outskirts, cultivated countryside and rolling hills. Its material functions are reusable across Janoah's future cells, but other countries require their own cultural asset sets.
7. Floodplain banks receive real terrain collision, sparse stone/scrub, and short paved walking terraces. The system caps active countryside cells at nine to preserve the mobile development baseline.

## Data and code
- `world/janoah_waterways_v056.gd`: stream geometry, profile and carving math, stored as deterministic functions.
- `world/janoah_environment_kit_v056.gd`: prototype Janoah ground, gravel and vegetation styling.
- `world/janoah_approach_v055.gd`: the same regional streaming node with a carved terrain profile, water mesh and separate collidable crossings.
- `data/janoah_waterways_v056.json`: explicit provenance, local position, crossing types, water-interaction limits and planned improvements.
- `data/janoah_approach_v055.json`: links to waterway and region art kit.
- `tests/v056_waterways_smoke.gd`: 3-cell continuity, collision, water, dry-bank, bridge and save regression test.

## Travel logic and canon status

Magnara remains a proposed 26 km seven-ring metropolis. The bridge/river sit on an **internal prototype axis** and do not assert where the city faces the ocean, where the Iron Cothon basins sit, or where any other nation or border lies. There is no new mapped river name, capital, village, or bridge from the novels.

The known-world registry keeps Zuba, the Krystal/Sunken Isles, Terragigantus and other beyond-Abyssal destinations outside this phase. Astraea, San Ciana and unknown settlement coordinates remain unplaced.

## Remaining work
- Terrain shader and river material fidelity beyond simple Godot primitives.
- Water immersion, wading, swimming and boat physics; rivers remain non-collidable surface decoration above a real terrain bed.
- Biome vegetation LOD, wildlife, seasonal weather and river ecology.
- Author-locked Janoah watershed maps, terrain and coastlines, approved city approaches and international roads.
- Real freight/passenger service, vehicles, long-distance travel and authored roadside destinations.
- iPhone browser performance validation; headless Godot checks prove build integrity, not stable device frame rate.

## Staging and release
Run the V0.56 dedicated Godot full-scene import/startup, tests for V0.48–V0.55, physical river+bridge tests, and Web export. Promote only a passing staging commit to `codex-modular-v31`. Do not modify `main`. Keep this internal until the world and gameplay are substantially complete, as requested.
