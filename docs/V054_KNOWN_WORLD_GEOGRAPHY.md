# Seeker's Codex: Known World — 1500 A.S.
## V0.54 Geographic Foundation / World First

**Author direction:** Use believable continental travel, maintain enormous capital cities, preserve distinct cultures, and do not prematurely release unfinished prototype builds. The 26 km Magnara, 18 km Zhushen, and 15 km New Rehli/Albion city sizes are **author-supplied editable planning targets**. They are NOT measurements proved by the novels.

### What the game now uses
- **1 Godot unit = 1 meter**, without changing any previous character-control, combat, or quest mechanic.
- Magnara's proposed **13,000-meter center-to-edge radius** and seven band boundaries: 1,000 / 2,600 / 4,700 / 6,500 / 8,700 / 10,700 / 13,000 meters. Ideal envelope ≈ 531 km². Actual streets, coastlines, and coast-side Ring VI geometry remain unapproved.
- Current V0.33–V0.53 Ring Two prototype is placed in the **Ring II radius band** by a temporary technical offset, city center `(-1700, 70)` in the local Godot X/Z plane. This has NO canonical compass bearing, does not imply Ring I's exact location in the novels, and can be migrated when the real city map is locked.
- **256m × 256m** deterministic terrain cells in a capped **3×3 near-player grid**, including a physical ground collider and connected cross-streets. Existing Ring Two floor and buildings are retained; the overlap tile's extra visual surface stays hidden to avoid Z-fighting.
- A source-safe **provisional massing layer** of only four generic buildings per outside cell, with seven distinct zoning palettes and sparse street facades. This is scaffolding for terrain/roads, **not** thousands of finished houses, verified land-use boundaries, or promised city-wide interiors.
- The generic Ring VI tiles are dry until the Iron Cothon coastline is known; we do not invent sea basins.
- New city save-position validation recognizes plausible 1:1 points inside the proposed footprint, preserving original V0.33 save keys and the existing Personal Codex. Old saves remain readable.
- Explicit regional registry: **13 named cultural/national theaters**, **19 supplied named settlement records** (including historic), **five non-city site sizes**, a proposed **8,000–12,000 km** known-world theater width (NOT a measured planet), and travel graph topology without fake kilometer distances or country latitude/longitude.
- The historical and cultural notes guide later art. No new national capital names, political borders or continent maps have been fabricated.

### Continental boundary rules
Included current-known-world registry: Rajistan, Chun, Janoah, Britannia, Vinlan, Germania, Tsar Empire, Dune States, Africanus, Americana, Zirael, Curan, and Jaorea, plus applicable known-side islands and central seas. Excluded: Zuba, Krystal/Sunken Isles, Terragigantus and anything beyond the Abyssal Line. Astraea and San Ciana remain unplaced until their location relative to the Line is verified.

**Travel continuity:** The New Rehli-to-Chun caravan route is a multi-stage, roughly month-long journey in the supplied story outline. We store the event and waypoints, but do not invent kilometers, national borders, coastline coordinates, or a Curan-to-Rajistan land bridge.

### Architectural and social differences to maintain
Rajistan: monastery / market / pilgrimage / Martial schools; Chun: ritual administration / Ocular clans / imperial gates / automata; Janoah: industrial trains / guns / guilds / multicultural quarters; Britannia: nobility / Sun heraldry / monarchy / rural class contrast; Vinlan: fjords / forging / distinct war fellowship; Tsar: winter logistics / legions; Germania: industrial civilian society and restricted research; Dune States: deserts and coastline, water rights and occupational consequences; Africanus: five discrete internal blocs; Americana: multiple distinct regions, no generic monoculture; Curan: island ports and embargoes; Zirael: biologically credible aquatic settlements; Jaorea: contested civic lives and border defense.

These are **design cues**; they are not yet 3D geography outside Magnara. No one national building set should simply be reskinned into another.

### Preserve 1500 A.S. and earlier eras separately
Ashford-on-Lea and Moor Town carry historical 1486 A.S. entries. The game may eventually need year-based damage/reconstruction variants. Historical locations are NOT silently copied unchanged into the 1500 A.S. city map.

### What is not built yet
- No entire Janoah country terrain, definitive borders, actual oceans or settled coastlines.
- No full 531 km² of authored streets; the 256m streamed terrain cells deliberately use simple structural massing only.
- No author-approved compass projection of Magnara's named landmarks and no constructed inland government/harbor core.
- No trains carrying players across rings and no physical roads connecting the countries.
- No ready-for-release iPhone Safari performance proof. Headless Godot/Web export validation cannot replace real mobile profiling.

### Next world-first construction steps
1. Artist-authored surface/terrain topology and genuine scale-appropriate Magnara landmark footprints, while preserving the 26 km coordinate model.
2. Establish a measured regional landmass **only after** coastline and country-border approvals, then generate terrain/water/wilderness tiles at that scale.
3. Place named settlements at author-approved relative positions; derive multi-stage caravan and transport networks from narrative travel times, not arbitrary neighboring cells.
4. Create distinct modular asset libraries per nation, plus history variants (1486 vs 1500).
5. Profile current mobile build; adapt streaming radius, polygon counts and collision density to actual device constraints.
6. Finish city blocks and route gameplay before public release.

**Source of truth:** `data/known_world_v054.json` is the editable registry for physical dimensions, rings, settlements, travel topology and boundary exceptions. `data/magnara_atlas_v052.json` remains an implementation-era Ring Two district audit; when they disagree about geographic scale, the later V0.54 geography registry controls, pending author revision.
