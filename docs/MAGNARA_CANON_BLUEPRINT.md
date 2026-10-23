# Seeker's Codex: Magnara — Canon-Aware World Blueprint (V0.40)

## Canon precedence
1. Author's latest locked corrections and published chapters (Chapter 90 supersedes exploratory atlases).
2. Seeker's Codex master atlas and official character/geography dossiers.
3. Clearly labeled game implementation proposals. **Gameplay placement is not story canon.**

## World hierarchy
- **Margerina** is the world. Rajistan, Chun, Janoah, Vinlan, Britannia, Germania, Americana etc. are different countries, not districts of one city.
- **Magnara** is a major Janoan seven-ring city. It cannot stand in for the entire world.
- **Ring Two** is the Seeker Quarters, with a **public/civic band**, **working Seeker professional band**, and **secured monumental band** containing the Seeker Citadel.

## Ring Two: confirmed anchors from Chapter 90
- Public living quarter: broad pale-stone avenues at four-carriage scale, blue-resonance canals and iron bridges, bronze lamps sealed by glass/sigils, inns, residences, balconies, shops, laundry and noodle service.
- Professional facilities: registration/certification offices, Seeker barracks, medical instruction, formal training courts, Soulwright personnel, Silver teams training and managed Aura exhaustion.
- Inner monumental precinct: ramparts, guarded institutional passages and the black-and-gold hexagonal **Seeker Citadel**, marked by **thirteen towers**.
- Authentic ambient life: civilians, professional Seekers, trams, coordinated patrols, paperwork, night training. The quarter is not empty, ruined, or restricted in its entirety.
- Rin's Chapter 90 nighttime mission is **published story canon**, not a generic quest template. Moisha's box position is **not revealed**, and this game prototype does not reveal it.

## Named Magnara landmarks to honor in later maps
- Steel Flame Tower, Iron Cothon, The Talking Boar (Crescent Halo), Grand Amphistad/Trial by Mercy venues, Mercy Deck, Founders' Bridge, Forgehouse, Nightweave Row, Hollow Thread Atelier, Onikaze Forge, and commercial/artisan rings. **Do not invent exact ring assignments where the text has not locked them.** Ring IV is connected to banking/trade; Ring V to forges and manufacturing in current canon notes.

## V0.40 gameplay implementation: provisional local geometry
- Preserve the already working hub at world origin and expand along game-axis `+Z`. This direction is **only local navigation, NOT a canonical north/south orientation**.
- `public` region at approximately z=30–70, `professional` z=70–105, and `citadel_approach` z=105–130 with skyline beyond.
- Streets, walls, low-poly roofs, signs and a 13-tower skyline are **scale placeholders**, not finalized reconstructions. NPC/crowd, tram, interiors, archives and secure access quests come later.
- The Citadel gate is **closed**. No guessed accessible interiors, authority levels, Pillar offices or mission-box location.
- Preserve joystick/camera multitouch, run+jump, double jump, wall/water traversal, training, Tola, quests, appearance and combat.
- Retain existing local saves; expand the position safety bounds to allow saved locations in the new walkable area. Never migrate/erase save files without a recovery path.

## Long-range technical architecture
- Separate `World -> Nation -> City -> District -> Cell -> Interactable` data; use stable IDs and source references in every content definition.
- Stream district cells by player proximity instead of rendering all seven rings and nations simultaneously. Expand with mesh batching, pooled NPCs, navigation profiles, and mobile performance budgets after profiling Safari.
- Keep two metadata flags: `canon_status = confirmed/provisional/game_only` and `source = chapter/atlas/author decision` to prevent a convenient game invention being remembered as official lore.
- Travel between **countries** must eventually support carriage, boat, Aratrum, train, sea routes and scenic transport; no instant assumption of one continental city.

## Delivery steps
1. **V0.40**: connected Ring Two cells, Chapter-90-inspired landmark silhouettes, 13 towers, stream/unload, save positions, preserve earlier features.
2. **V0.41–42**: authentic NPC duties (guild officials, medics, Soulwright staff, patrols), entrances/interiors in one public and one professional site, verification of canonical dialogues.
3. **V0.43+**: full Magnara ring map, tram routes, commerce/industry/harbor interfaces, faction reputation and consistent world-time.
4. **World atlas phase**: world-scale regions, country borders, ecology and oceans; route and loading infrastructure before city-scale asset multiplication.

## Essential validation
- One finger holds joystick, another presses jump while RUN is on, a third adjusts camera; no gesture cancellation.
- Same controls, combat and quests in old hub; rooftop parkour; new city region crosses seamlessly from z=30.
- Each streamed region loads at approach and unloads at distance; run+jump works while the region changes.
- Save at the professional precinct, reload in place, open LOOK, interact with Hanami after returning.
- iPhone Safari 3D frame-time, memory and battery tests are empirical; Godot headless validation does not prove stable mobile performance.
