# Seeker's Codex: Young Blood 3D — V0.72 Public Interiors & Steerable Coastal Skiff

**Target:** Godot 4.4.1 / Compatibility Web / iPhone touch. **Era:** Margerina 1500 A.S. **Lore discipline:** all new 30 public venues, shifts, skiff pier, voyage limits and harbor coordinates are **game-only**. The original published shops, guilds, Seeker powers, restricted Iron Cothon military basin and unseen Abyssal Line remain story-locked.

## 1. Every extended Magnara ward gets a real enterable interior

V0.71 expanded Magnara Ring II from 15 to 45 streamed cells, with 270 modular public building shells and 435 generated game-only civilians (separate from canonical published-cast NPCs). In V0.72 **one building in each of the 30 newer blocks** gains a walk-through ground-floor venue.

- **30 public rooms**, one per new 128m block, not 30 extra counted buildings. The facade on plot #2 is rendered in true four-piece segments on the first floor, with a **2.4m open door gap** and physical threshold. Upper floors continue as opaque massing with solid collisions and rooftop routes. This avoids the invisible-wall/pictured-interior problem.
- Floors, outer masonry, split front wall, lintel, wooden shelves, counter, table, seats, equipment stock and light objects are all actual 3D geometry. Primary floor, wall and furniture elements have independent physics collision.
- Six repeatable **game-only** types — public tailoring workroom, merchant ledger annex, neighborhood common room, wagonwright, print shop, supply sorting studio. No publication or author confirmation is implied for the exact shop names, ownership, architecture or placement.
- Each venue has **one existing original civilian (#11 in that cell)**, with a consistent name, household and work role shared with V0.71. From 09:10 to 17:30 game time that citizen works *inside* the building and is suppressed from the outdoor procedural pedestrian LOD. The indoor NPC changes between morning work, a midday break, afternoon service and closing. They leave the venue outside those hours. The other residents retain their previous schedules.
- Use the original **TALK/USE** iPhone control near the door or the physical employee. Topics: job, household, local civilian trade. Personal Codex records the public visit. No invented Phantom Tola, secret shipments, guaranteed income or surprise guild promotion.
- Interiors are attached to the existing 30-cell streamer only when the relevant block is loaded. A maximum of **9 interior instances** are loaded at once, like the corresponding 9 resident chunks. Leaving the district unloads all physical rooms and local furniture. Existing V0.67 public buildings, published stores and story venues remain unchanged.

Source: `systems/magnara_interiors_rules_v072.gd`, `world/magnara_ward_interiors_v072.gd`, targeted updates to `systems/magnara_expansion_rules_v071.gd`, `world/magnara_expanded_wards_v071.gd` and `systems/hub_manager.gd`.

## 2. A small ship you can steer on the weather ocean

V0.71 already rendered a 1km coastal survey, three interference-wave bands, Fresnel-style surface coloring, river current animation, six scheduled cargo vessels and actual 4-point simulated buoyancy. V0.72 adds **one distinct, controllable public skiff**.

- A physical finger pier with access from the public quay leads to an actual **AnimatableBody3D** wooden skiff with a deck collider, railings, helm and hull. The player can jump aboard, walk, jump or BURST on deck; their `CharacterBody3D` remains under the world, never parented to the boat or teleported across the ocean at helm.
- From the on-board helm, use TALK/USE to enable a small iPhone helm overlay: **LEFT, RIGHT, FASTER, SLOWER, LEAVE HELM**. On desktop **arrow keys** steer and adjust power; keyboard arrows do not shove the character off deck. The iPhone left joystick remains free to move the character independently.
- Speed accelerates/brakes gradually (max 7 m/s), direction turns gradually with rate linked to speed, wind adds realistic drift and stronger weather reduces drive efficiency. The small craft uses the **same CPU wave field and four-point pitch, roll and heave** as the existing cargo fleet. The operation is a deterministic prototype, not a full rigid-body/CFD fluid simulation.
- A capped 18-instance translucent **GPU mesh wake** renders surface-following foam, emitted at a fixed temporal interval and fading over 4.5 seconds while underway. No particle emitter or expensive GPU compute required for Web.
- Safe bounds prevent the craft exiting the **1km preview tile** or crossing into unknown country coasts or beyond the Abyssal Line. Releasing the helm never strips the player of movement or invents a voyage. Exiting the harbor unloads the entire boat, wakes and the sea tile; saving during this temporary visit still stores the safe Magnara entry position.

Source: `systems/ocean_helm_rules_v072.gd`, `world/steerable_skiff_v072.gd`, integrated into `world/margerina_ocean_commerce_v071.gd`, existing parkour controller and main gameplay scene.

## 3. Explicit limitations

- The new 30 interiors are **small first-floor public spaces**, not bespoke furnishings for all 270 buildings or 270 production-ready enterable homes. There is no authored second-floor navigation or finished costume/animation production for all NPCs yet.
- The ocean is a **playable but distant provisional harbor preview**, and its merchant destinations are not confirmed exact national sea routes. Ship wind/pitch and basic surface drag are physical gameplay approximations; no full 3D fluid pressure field, complex keel/sail/ballast calculations, underwater-caustic illumination, shorebreaker interaction, spray/splash particle collisions, or ocean-wide country navigation yet.
- Lake Lukka is named/registered for Africanus, and additional known-world lakes/rivers remain unplaced until their location/culture is confirmed. The existing V0.56 game-only river remains river-current animated and the old road bridge stays functional. Do not fabricate extra national lakes/ports.
- This release is Web/iPhone-first, but **hardware iPhone thermal load, touch hit regions and FPS are unverified by headless CI**.
- World simulation includes bounded public freight; no automatic canon faction war or unapproved Seeker sovereign pressure scenes.

## 4. Verification and proposed continuation

- `tests/v072_interiors_helm_rules_scene.tscn` checks 30 unique workrooms with opening measurements, deterministic identity/household shifts and non-duplicated indoor/street work, weather-sensitive small boat propulsion, wind drift, fading wakes and world bounds.
- `tests/v072_interiors_helm_world_scene.tscn` loads the actual Godot 3D scene; checks the open doorway via horizontal physics rays, walkable floor, staff presence/schedules and UI, interior unload, live skiff deck collision, mobile helm, genuine vessel movement and carriage of player, visible foam wake, and safe harbor save/return.
- Regression tests cover V0.71 city/water/trade, V0.70 Aura/trolley/Spatial tutorial, V0.69 posture/seals/guild, V0.68 rooftops, V0.67 streaming, V0.66 published stores, V0.65 population, V0.64 civic, V0.63 save, V0.62 markets, V0.61 workshops, V0.54 geography, V0.46 Seven Spokes. Must pass HTML5 export in staging then final development build.
- **Next V0.73 focus:** connected neighborhoods with authored larger interiors, genuinely changing store inventories/warehouse goods through completed local transport trips, deeper family NPC schedules and physical ferry routes after the coastal survey placement is author-approved. Improve ocean wake/spray, land-water transitions and safe shore wave interaction after actual iPhone device profiling.
