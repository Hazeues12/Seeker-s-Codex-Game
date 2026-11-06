# Seeker's Codex — Magnara World-First Reconstruction (V0.52)

## Direction correction
This milestone prioritizes **the physical city**. Earlier V0.33–V0.51 iterations added systems and very small, largely block-shaped sections; those mechanics stay intact, but Magnara is not a completed city. This upgrade establishes the first large connected street expansion.

## Confirmed story anchors
Magnara is a **seven-ring Janoan city**. Chapter 90 places the **Seeker Quarters in Ring Two**, comprising a public living band (four-carriage pale-stone avenues, blue-resonance canals, iron bridges, bronze-sigil lamps, shops, laundry, inns and residential balconies), a professional band (registration, barracks, medics, Soulwrights, training and patrols), and a secured Citadel with a **hexagonal black-and-gold silhouette and thirteen towers**. These are canon traits.

Keep the Citadel gate closed. No invented contents of restricted rooms and no invented location of Rin's package. Do not assign named sites such as the Talking Boar, Forgehouse, Hollow Thread Atelier, or Onikaze Forge to arbitrary ring coordinates without supporting story material. Ring IV's banking and trade and Ring V's forges and manufacturing are partial region notes, **not** permission to invent the full ring atlas.

## V0.52 actual world changes
- Preserve the preexisting V0.40 Seeker Quarters corridor and all gameplay nodes.
- Add **four streamed and collidable Ring Two ward cells**, west/east by public/professional zones, at centers ±70 local x, z=50/90. Each cell is 72 × 40 world units, joined to the existing corridor at x = ±34 and connected by an east–west avenue around local z=70.
- Add **sixteen streetside buildings**, including two **hollow, physically enterable interiors** (a provisional public rest house and professional records hall) with real wall collision, doors left clear, furniture, lanterns, roof decks and climbing steps.
- Add a **lower canal bed and two functional iron bridges** in the western public cell, public vendor stalls and awnings, residences with windows and balconies, city service courtyards, a tram stop, and glass-sigil lanterns.
- Add a **visual, non-boardable ambient tram** running across the main east–west boulevard. A real ride/passenger route is a separate future task. Distant skyline shapes are decorative and do not pretend the other city rings are built.
- Existing V0.40 cells now unload based on actual 2D distance from the player, instead of rendering the central district when the player is far sideways. The new wards stream in with a wide hysteresis margin to avoid rapid loads.
- Extend safe local-save x positions within the newly collidable city extent. Keep V0.33, V0.38, V0.41 and Personal Codex file formats unchanged.

## Canon status
All four ward coordinates, side-street alignments, new building identities and signage are **game-only provisional placements**. The road bearing does **not** establish official north/south geography. The established institutions remain the chapter source of truth.

## Roadmap: finish Magnara before broad new feature releases
1. Physically complete all Ring Two block connections and street landmarks with an authored reference map, stable building IDs, roof navigation and two or more functional interiors per populated cell.
2. Produce high-quality, modular architecture and art direction for Janoah (stone, bronze, industrial transport, glass/Aura fixtures), replace prototype humanoid meshes, lighting, water and animations. Profile iPhone WebGL.
3. Expand the **seven-ring world atlas** carefully, placing named landmarks only after author confirmation or chapter citations. Ring IV trade/banking and Ring V manufacturing/forges should be distinct. Remaining ring functions stay unassigned until lore is audited.
4. Build real ring-to-ring road, tram and carriage connections, then ports/rail to other Margerina nations as separate streamed regions.
5. Fill those regions with interiors, shops, guild quarters, households, civilians, wildlife, weather and consequences. Existing relationship and quest systems attach to authored places.
6. Finish compatibility/performance, collision, mobile input and regression gates before the first release playtest.

## Automated validation
Staging branch `magnara-world-v052-staging` validates Godot import and startup, the previous V0.48–V0.51 regression tests, four streaming cells, non-illusory collidable building density, actual room door clearance, unloading, and a Web export. Only promote the staged commit to `codex-modular-v31` after staging checks pass. `main` remains untouched.

**This is a substantial city expansion, not the whole seven-ring Magnara or a finished RPG.**
