# Young Blood 3D — V0.70: Aura Mobility, Moving Public Carrier and Spatial Practice

**Target engine:** Godot 4.4.1, Web/GL Compatibility and iPhone touch controls. **Story era:** 1500 A.S., Known World Janoah/Magnara only. All new Burst movement, trolley timings, addresses and orientation-room geometry are **GAME-ONLY training prototypes**; they do not redefine Seeker rank, cultural geography, or the secrets of the Archwheel.

## 1. Physical freedom: controlled Aura momentum + better jumps

The public training-grade **Aura Momentum Burst** is implemented as a real collision-aware horizontal impulse, not a teleport or forced transform:

- One new **BURST** button on the existing iPhone controller, next to GUARD. Desktop uses `R`. Joystick, sprint, double jump, wall run, guard, dodge and camera remain active.
- Cost: **16 Aura + 8 Stamina**, checked through the existing **Soul → Aura → Martial Muti → Technique** authorization in `systems/seeker_power_rules_v068.gd`; one resource charge per press, with a **1.60-second cooldown**.
- Burst speed 16 m/s, held for 0.36 seconds (theoretical straight-line range 5.76 m). The physical capsule still uses `move_and_slide()`; gravity, wall collision and rooftop collisions continue through the burst.
- Jump buffering: 0.13 seconds; late jump tolerance/coyote: 0.11 seconds; moving-deck floor snap 0.20 m. Airborne double-jump and prior wall-run logic remain. Ordinary movement is enabled during the prototype carrier ride.
- This is a generic authored training mechanic, **not** Kai's Hanuman Step, Aria's Spark Rush or William's Lumen Step; none is granted to custom characters without story authority.

Code: `systems/aura_parkour_rules_v070.gd`, `characters/player_controller.gd`, `ui/mobile_controls.gd`, `ui/mobile_controls.tscn`, `systems/hub_manager.gd`, `data/seeker_power_components_v068.json`.

## 2. Actually rideable moving transport

`world/magnara_moving_carrier_v070.gd` creates one **two-stop prototype public inspection trolley** on the existing x=0 shop-street road between z=608 and z=690.

- Real `Path3D`, authored `Curve3D`, `PathFollow3D`, and `AnimatableBody3D(sync_to_physics = false)` moved directly each physics frame 3D components.
- Genuine physical deck collider (3.6m x 6.2m); the player can **jump onto, run across and jump off** at any point. The player remains a normal `CharacterBody3D`, *never* parented to the vehicle or moved by scripted per-frame teleports.
- 82m reversible journey at 5 m/s, 2-second dwell at each end; deterministic direction and timing in `systems/magnara_carrier_rules_v070.gd`.
- Both actual station approaches feature signage and a phone-sized TALK/USE timetable. The game-only rail track is visible on the existing roads. This is **not an official Seeker's Codex Janoah train route, the Iron Cothon railroad or a Skyport**.
- The old V0.50 expedition carriage and its forced sit/ride mode remain unchanged.

Per official Godot 4.4 physics, CharacterBody3D adds a moving platform's velocity during `move_and_slide()`. The trolley is an AnimatableBody3D moved explicitly in the physics tick with `sync_to_physics = false`, because `true` is intended for animation-driven synchronized bodies and can overwrite direct scripted transforms. We rely on Godot's moving-platform handling instead of parenting the player or disabling movement.

## 3. Supervised Spatial rules: an *unloadable room*, not a canon Ryōiki

`systems/spatial_practice_rules_v070.gd` and `world/spatial_practice_trialboard_v070.gd` provide a public orientation course at the old Seeker training grounds.

- Visible game-only practice arch, nearby TALK/USE touchscreen panel, an **Enter supervised orientation** button and a reachable exit marker.
- On entry, a **separate fully collidable 23m room** loads at a controlled remote coordinate, containing a ground, rails and three elevated movement platforms. The player may freely walk, sprint, jump and Burst.
- On return (or after six minutes), the room instance is **freed** and the exact safe public entry position restored; there can be at most **one** room.
- Existing `systems/hub_manager.gd` saves the safe public entry coordinates even if the SAVE button is pressed while inside. Unloaded geometry is never serialized as the player's next startup location.
- This is a **physical game prototype**, not an optical render-target portal or mathematically non-Euclidean world-space swap. It grants no Spatial Muti, pocket domain, Chronofault, authentic Sugoroku board, Ryōiki or Eidolon and does not reveal Archwheel secrets.

## 4. Guild public mission responsiveness

The existing, rank-gated daily Association prototype now recognizes a **fourth local public service duty**: an Iron+ trolley-stop safety report, physically located near the north stop. Like other public assignments, it is determined from the public game day and observed shop activity, one tracked assignment at a time, and paid Tola only once/day on a verified save. All Red Order, Family, Phantom Tola, Pillar dispatch and high-rank raid escalation remains story-locked. Reaching an official Seeker rank does not automatically activate a Will discipline or licensed Spatial power.

## 5. Checks and next work

- `tests/v070_mobility_carrier_trial_rules_scene.tscn`: exact burst/gating and costs, coyote/second-jump rules, Seven Spoke catalogue continuity, reversible train timetable and loadable trialboard permission/expiry, no powers or secret story content leaked.
- `tests/v070_mobility_carrier_trial_world_scene.tscn`: real Godot main world, iPhone Burst button, actual resource deduction and cooldown, rail collisions and moving deck passenger follow, physical return portal entry/exit, safe-in-trial save and unload, all previous physical scenes still present.
- Regression tests cover V0.69 live posture/parry/seal and civic payouts; V0.68 physical roof routes, V0.67 crowds/chunk streaming, V0.66 shops, V0.65 NPC lore roster, V0.64 civic life, V0.63 verified save, V0.62 market, V0.61 workshops, V0.54 geography and V0.46 Seven Spokes. Godot HTML5 release artifact must pass before promoting into development branch.

**iPhone performance still unmeasured:** actual Safari framerate, touch burst control reachability, motion jitter at physics update, vehicle/carrier rider stability, background-tab recovery and large-world thermal load need hands-on hardware verification. Headless CI validates determinism and collision but cannot replace device profiling.

**Potential V0.71:** retain momentum and allow safe rooftop mantling/collision-aware ledge grabs, extend public trolley routes only after real district boundaries, create actual Seeker guild dispatch NPC shifts and household conversations, and add an authored/secret-safe trigger volume rule engine for gated Spatial boss encounters. Avoid blanket auto-Pillar hunts, unapproved Soul crime laws or automatic rebirth on KO.
