# Young Blood 3D — V0.67 Modular Buildings, Streaming and Crowd LOD

**Target:** `codex-modular-v31` after staging green. Godot 4.4.1 Web/GL Compatibility, iPhone-first. **Canon:** 1500 A.S., Janoah/Magnara; all newly generated buildings and local workers are GAME ONLY. The original browser `main` branch remains unchanged.

## 1. Modular architecture: six reusable parts

`systems/magnara_stream_rules_v067.gd` defines a deterministic address-based six-piece kit:
- **ground** — street-level base;
- **middle** — 1 to 4 reusable upper storey sections;
- **roof** — cap variation;
- **awning** — optional storefront/shade;
- **balcony** — optional projection;
- **window** — repeated casement modules.

Materials mix five Janoah-inspired slate, stone, aged brass and plaster palette families. Each scenic parcel varies floor count, footprint, roof style, awning, balcony and window geometry using a stable ID and fixed seed. It is never a different building after leaving and returning. Six parcels per block, 15 available block addresses = **90 deterministic *building shells*** in this one Ring II extension, rather than 90 unique models or 90 available shop interiors.

**Authentic buildings remain special cases:** The Talking Boar, Le'Bell's, Avicci, Vernal Divongcci, homes, clinics and workshops from previous versions retain their actual interiors, inventories, doors and canon/status annotations. New generated houses are scenic sealed shells that require separate authoring if a player should enter. Architecture, social roles and country style must be refined with the creator's published atlas and region-specific lore; this generated prototype is **not** an assertion that northern Magnara's measured street grid is canonical.

## 2. World partition: actual create/delete of 128m chunks

`world/magnara_streamed_blocks_v067.gd` covers a **3 wide × 5 long** game-only extension of Ring II between z=720 and z=1360, with a street connector at z=711-720 to V0.66's shops. Each cell is 128m, with neighborhood x values -128/0/128. Streets and sidewalks are collision-bearing meshes, while building collisions activate only close to the player; outside the stream window, the whole chunk node (including geometry, people and colliders) is freed.

- **9 maximum active chunks**; center ± one chunk in two axes.
- **2 new chunks built per update** (0.38s interval), nearest first, avoiding abrupt 9-chunk instantiation.
- Old chunks are removed immediately when they fall outside the area, including all dynamic NPCs and physics.
- Stable deterministic `(x,z)` tile addresses preserve identity and architectural layout without writing thousands of static instances to save files.
- The active survey terrain from V0.54 is still retained as collision support, while overlapping speculative giant solid cubes are suppressed within the now hand-authored central north corridor.

**Claim limitation:** This does *not* create the remaining 26km Magnara, let alone the known world; it establishes reusable engineering capacity for region-by-region expansions.

## 3. Crowd Level of Detail (LOD)

Two systems now enforce the same distance budgets:
1. The **existing 37 NPC 3D models** in V0.65/V0.66 gain a 0-20m detailed visible mesh with a collision capsule; 20-100m uses 2 low-poly boxes and **no** physical body collision; beyond 100m the model is hidden. All canon cast visibility still follows original story gates. All ambient models are placeholders, not final character art.
2. **New streamed district civilians:** 5 original names with stable role, disposition, household ID, address and deterministic lifestyle schedule per block = **75 planned identities across all 15 blocks**. During play only loaded blocks are evaluated; nearby civilians get multi-part 3D proxy, physical capsule and TALK/USE conversation. Midrange civilians ride deterministic sidewalk rails in a *single MultiMesh draw group per chunk*, and far/dormant civilians don't draw or pathfind. Their job and daily clock update analytically during offscreen time; reentering reconstructs their correct location.

No canonical high-tier characters, sealed Red Order adversaries, Nezubunta, the Onzu Squad, or important families are procedurally generated in these new apartments. Canon Squad Three remains at author-gated venues rather than appearing on generic city pavements. New civilians' family/household links are entirely original game-only entries, with no invented relationship to published cast.

**Behavior limits:** Current close characters face the approaching player and can converse, but they use authored rail schedules rather than advanced navigation/path planning, behavior trees, simulated memory of every offscreen event or high-quality skeletal animation. Near-vs-mid LOD is a rendering/physics budget and can later support animations, jobs, familial schedules and incident-driven dialogue as those content systems are added.

## 4. GPU instancing and culling

All six architectural module types are drawn by separate `MultiMeshInstance3D` nodes **per chunk**. Instances reuse a single unit-box GPU mesh with transform scaling and per-instance tint. Per-chunk clustering matters: Godot's MultiMesh is culled **as a whole batch**, not per-instance, so no one global MultiMesh across the planet. Midrange NPC crowds also use an instanced mesh per chunk. Each instance group sets a maximum visibility range and shadows are disabled for the cheap massing. Close characters are individual nodes only while needed.

**Occlusion truth:** GL Compatibility on iPhone and HTML5 is the active renderer in `project.godot`. Godot's CPU occlusion culling with `OccluderInstance3D` is an additional setup+CPU cost and has not been baked/enabled for this new extension. The release implements **real chunk unloading, distance LOD, renderer frustum-batched visibility and GPU instancing**, not a claim that hidden geometry behind the Citadel is currently excluded by tested hardware occlusion. Opaque-depth testing still occurs normally; an actual occlusion backend should only be enabled after device profiling. Godot references:
- [Optimization using MultiMeshes](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html)
- [MultiMesh in Godot 4.4](https://docs.godotengine.org/en/4.4/classes/class_multimesh.html)
- [OccluderInstance3D and CPU caveats](https://docs.godotengine.org/en/stable/classes/class_occluderinstance3d.html)

## 5. Character gameplay and established city preservation

The northern residents now answer through the existing mobile TALK/USE interaction without polluting the persistent hub's location array with unloaded Node pointers. Each streamed NPC has a fixed work/household role and distinct shift and rail position. Conversations about work, household or daily patterns are recorded in the Personal Codex as unique game-only encounters. The stored event persists if the chunk unloads and the NPC is later reconstructed; it never rewrites novel continuity or moves a published character.

## 6. Validation

New functional smoke scenes:
- `tests/v067_stream_rules_scene.tscn`: exhaustive addresses, 90 reproducible modular houses, 75 unique household-linked citizens, 15 possible chunk cells, 9 active cap, plot gating, daily schedules and near/mid/far thresholds.
- `tests/v067_stream_world_scene.tscn`: boots full Godot scene, streams 9 real chunks with 54 loaded buildings, verifies six live MultiMeshes per chunk, road geometry/colliders, nearby building physics, existing named NPC LOD, new citizen LOD and proximity interaction, Personal Codex disk persistence, unloads all chunks by leaving city, reconstructs same people/houses on return.
- Legacy functional regression: V0.66 named shops and verified purchases; V0.65 canon NPC memory; V0.64 civic buildings and daily life; V0.63 save integrity; V0.62 market, V0.61 workshops and V0.54 known-world geography; successful WebGL export.

**Explicit device gate still needed:** 30/60fps, frame spikes from chunk creation, RAM allocation, iPhone Safari GPU/thermal behavior, touch target ergonomics and background tab restore must be observed on actual device after release. Headless CI can prove functionality but not mobile performance.

## Next after V0.67

Layer individual long-term character and household plans, squads, jobs/guild HQ activity, destination-aware local navigation and physical inventory on top of this foundation. Populate other country modules only after atlas, chronology, and cultural architecture are approved. Replace proxy figures with character-authored rigging/animations when an art pipeline is available. Measure occlusion effectiveness versus CPU cost before enabling it in the shipping Web renderer.
