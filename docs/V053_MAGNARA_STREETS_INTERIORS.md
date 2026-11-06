# Magnara World Construction — V0.53: Six Enterable Interiors and Connected Civic Streets

This is **physical world construction** in Godot, not a GUI or a mission system. No user playtest is requested until the first substantial finished release candidate.

## Canon boundaries
Magnara is a seven-ring city in Janoah. Ring Two houses the Seeker Quarters, public residential blocks, professional precinct, and secured Citadel. Chapter 90 supports pale-stone avenues, blue-resonance canals, iron bridges, bronze/sigil glass lamps, shops, residence balconies, professional offices, training and public life. The Citadel is secured and has thirteen towers. The city's exact compass bearings and ring assignments of most named places are NOT canon-fixed by these notes.

No new official Seeker rank, Pillar, restricted gate access, rare Eyes, Soul Bloom or secret location is introduced. New business names and room contents are temporary **game_only** architecture.

## New V0.53 physical upgrades
- Preserve the existing four V0.52 streamed urban wards, original Ring Two corridor, and all older game scenes and saves.
- Replace **four solid inner-row buildings** with actual accessible hollow rooms, with real open doorway space, collidable walls, interior counters/seating, roof deck and physical rooftop access steps:
  - West public: Canal Service House (game-only)
  - East public: Civic Dining Hall (game-only)
  - West professional: Seeker Medical Annex (game-only)
  - East professional: Supply Inspection Hall (game-only)
- Together with V0.52 public rest house and records hall, Ring Two now has **six real walk-in buildings**, not six fake facade doors.
- Add continuous solid pedestrian promenades to all four wards, bronze inset paving, freestanding arcaded colonnades, roofed canopies and institutional gateway silhouettes.
- West public: a solid waterside quay, low mooring posts and bronze protective guards broken at the two real iron bridge approaches.
- East public: a small paved civic square with two benches.
- West professional: a paved service courtyard with standing training pillars.
- East professional: solid cargo platform and tram workshop yard details. The tram itself remains an unboardable visual prototype.
- Reuse modular mesh shapes and materials, dynamic near-player ward streaming, and the existing collision-layer assumptions. Avoid enlarging NPC simulation or introducing gameplay state.
- Expand Magnara's world manifest and JSON atlas to enumerate actual open interiors and the provisional architecture.

## Validation gates
- Compile/import the complete game in Godot 4.4.1; run the whole-world main scene headlessly.
- Run V0.48–V0.52 regression checks without changing previous quests, inventory, controls, Personal Codex or mobile UI.
- Independently spawn the physical city with a dummy player and verify every one of six room entrances has no blocking body along a standing torso-level walking path.
- Verify all six buildings have solid roofs and final rooftop access steps; verify every ward has an actual promenade and arcade with substantial mesh/collision density.
- Verify the western canal has a real raised bridge deck and the quay guard does not obstruct either iron bridge route.
- Verify four cells load/unload based on distance, then export a full Web build.
- Promote the staged GitHub revision by fast-forward to `codex-modular-v31` only after all checks pass; leave `main` unchanged.

## Next world-first priorities
- Make Ring Two's entire street plan internally consistent, with legible wayfinding, proper level-of-detail, signs, stable world/door IDs and physically furnished lodgings.
- Build recognizable chapter-grounded Janoan architecture and the city's real transportation/interior experiences, then prepare a sourced placement audit for named landmarks.
- Start designing the distinct land-use and street structure of Magnara's remaining rings, retaining unknown functions as unassigned pending author confirmation.
- Connect real district maps and cross-ring transport without replacing the working iPhone control foundation.

**Development reality:** Godot headless geometry and export tests do not establish beautiful art, reliable 60 fps on iPhone, or a finished open world. This is one additional city construction milestone.
