# V0.76 — Seeker's Codex: Live Published Canon Audit and Magnara Seven-Ring Styles

**Branch:** `codex-modular-v31` after CI green. **Engine:** Godot 4.4.1 Web / iPhone. **Story date:** 1500 A.S. **Audit date:** 2026-11-07.

## Verification happens BEFORE new gameplay is implemented

The creator asked to stop assuming that every proposed mechanic or previous assistant label is canon. This release begins with live research of the published serial, review of prior creator corrections across conversations, and comparison of the existing repo world bible/atlas. A versioned source registry is now in:

`data/magnara_published_city_audit_v076.json`.

Primary public chapters:
- [The United States of Janoah (The Steel Flame Republic)](https://www.royalroad.com/fiction/132012/seekers-codex-beyond-the-abyssal-line/chapter/2689891/the-united-states-of-janoahthe-steel-flame-republic). **Explicit ring descriptions** identify III The Commons (parks, bridges and families), IV The Academies (sigil-glass domes), V The Markets (crowded mixed-culture commerce), VII The Iron Cothon (major harbor, trade basin and inner war basin); also Steel Flame Tower, Seeker Citadel, blue-resonance waterways, rails and upper skyport.
- [Trial by Mercy: Darker Than Black](https://www.royalroad.com/fiction/132012/seekers-codex-beyond-the-abyssal-line/chapter/3787095/trial-by-mercy-darker-than-black) features Ring V guard checkpoint and late-night workshops, armorers, markets, and rooftops. This supports including workshop texture in market-ring streets.
- [Trial by Mercy](https://www.royalroad.com/fiction/132012/seekers-codex-beyond-the-abyssal-line/chapter/2718339/trial-by-mercy) shows citywide glow, trams, steel/sea atmosphere, elevated streets and bridges. This is visual atmosphere, **not a survey map**.

Creator chat corrections take precedence over older prototype labels, especially **main seaport in outermost Ring VII** and allowing only **minor local canal piers in Ring II**. The official story and creator discussions support original Ring II public Seeker Quarters, but do NOT establish exact global compass orientation, seven ring radii or every named business address.

### Corrected ring chart

| Ring | Verified / provisional identity | V0.76 exterior-only expression |
|---|---|---|
| I | Center/Steel Flame Tower core, exact site coordinates unapproved | Previous neutral city silhouette, no newly invented palace |
| II | Seeker Quarters; already physically authored neighborhood | **No new overwrite** of published shops and rooftops |
| III | **The Commons**, published | Smaller building heights, deliberate open lots, grass courts and leafy canopy silhouettes |
| IV | **The Academies**, published | Lighter academic tones and a bounded set of glass-dome silhouettes |
| V | **The Markets**, published; workshop/forge streets also appear | Dense mixed-color street awnings and food-market architectural texture |
| VI | Specific district identity is not adequately resolved | Neutral existing shell art, no invented industrial faction or harbor |
| VII | **The Iron Cothon**, published and creator-confirmed main outer port | Neutral tall hoist/gantry exterior silhouettes; **no authored shoreline or docks** |

The previously hard-coded labels **“Ring IV Merchant District”** and **“Ring V pure Foundry District”** were too narrow or incorrect compared with the published chapter. Updated source and runtime paths:
- `data/known_world_v054.json`
- `data/magnara_atlas_v052.json`
- `systems/known_world_geometry_v054.gd`
- `systems/magnara_seven_ring_rules_v074.gd`

## What was actually implemented

- 26km / ~531km² remains an **editable city-development planning envelope**, not a book-published length. 7 original ring meshes, 12 provisional radial roads, 84 road intersections, major original local roads and the distant 1.9km skyline remain.
- Ring III leaves a **deterministic subset of previously generic building plots open**, adds GPU-instanced low grass terraces and occasional canopy trees. This makes the published Commons read as a recognizable city district and preserves physically walkable underlying terrain.
- Ring IV generates a sparse set of budget-limited **sigil-glass colored academy dome exteriors** above existing generic roof massing, with no named university address.
- Ring V generates **market stall awnings** directly against existing block fronts, without doubling resident NPC counts, pretending an existing commodity transaction, or changing Ring II shop inventory.
- Ring VII generates generic port-adjacent industrial gantry silhouettes without physically placing either the merchant basin or the protected inner war harbor in an unknown location.
- All additions are bounded **MultiMesh GPU instances attached to existing streamed city chunks**, never a new kilometer-wide physics scene. No new scripts expand original combat, undo saved NPC schedule accuracy, unlock sealed character abilities or add a second economy.
- The source validation is a real engine rule: visual building service will refuse to initialize if the versioned published-ring evidence registry is missing or invalid. Nearby materials remain bounded by existing 9-tile streaming; no code makes the whole city's 531km² fully resident at once.

## Audited ideas held for later rather than forced into the game

- **Tola batch/provenance/Phantom Tola:** original story demonstrates that currency forms and aura counterfeits exist, and connected lore files refer to encoded Sigil-Tola. **Do not invent a specific Sigil schema, counterfeiting pattern, magical “inflation” metric, starting player asset lineage or convert existing saves until a real audited economy transaction and compatibility migration are designed.**
- **NPC Blackboard/Utility AI:** appropriate for true public civilians once their actual environmental and work schedules are physically connected. Do **not** assert Red Order has captured Ring VII or spawn grand Seekers for an unobserved offense; faction politics and investigations must be authored and story-gated.
- **Will/Sovereignty reactions:** Triad rank gates already exist from V0.69; broad civilian panic must respect Gold/Grand restriction and not treat random civilians as combat targets or reveal Seizen's private techniques.
- **Rin's three-weapon transition:** published Yoru Oni exists, and Tetsuba/Chi no Ryōken have separate chronology in project canon. No proof of simultaneous current-era wielding means **weapon-set state machine is deferred**. Keep it an optional later authored animation system.
- **Technique Conversion, Muti Conversion, medium manifestations:** require confirmed characters, exact ritual prerequisites and physical tagged hitbox tests. Eidolons and ordinary summons are different.
- **God Tree Stutter:** no indiscriminate `Aura.recovery *= 0.85` on every story act; cosmology is spoiler-sensitive and the effect is not fully verified.

The visual effort improves **scale/visual identity**, not the simulation of political economy or secret combat trees.

## Validation

- `tests/v076_published_zones_rules_scene.tscn`: verifies published chapter sources, exact ring labels and site-boundary disclaimers, changed grid layouts, consistent deterministic greenhouse/academy/market/port style and no fake ability unlocks.
- `tests/v076_published_zones_world_scene.tscn`: boots the full game and enters Ring III, IV, V and VII, verifies actual GPU meshes on streamed 3D parent tiles and the 1.9km skyline, then returns to existing Ring II and checks saved character persistence.
- CI re-runs **all V0.75 → V0.54 and original V0.46** regressions, published port constraints, live ocean trade/skiff checks and HTML5 Web export before branch promotion.

### Still not completed

- Not all seven rings have finished individual NPCs, enterable buildings, authored estates, civic transport routes, or verified culture-specific neighborhoods.
- Terrain remains provisional and still needs a topography pass matching basalt cliffs, train viaducts, canals and the final shoreline. Don't invent exact high cliff or Iron Cothon coordinates.
- Real iPhone FPS, thermal throttling, long continuous road traversal and touch controls still require hardware validation.
- Future work will continue **audit → source-gated city-scale implementation → CI → browser export → promote**, before building named sites or special combat systems.
