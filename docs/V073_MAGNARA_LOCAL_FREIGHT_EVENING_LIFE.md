# Seeker's Codex: Young Blood 3D — V0.73 Real Local Freight and Evening Households

**Engine:** Godot 4.4.1 Web / iPhone Compatibility. **Scope:** the physical known-world Ring II public streets of Magnara, 1500 A.S. All new receipt IDs, courier waypoints, routine visiting hours and cargo quantities are original **game-only simulations**, not canonical house names or an official national trade ledger.


## Author-confirmed outermost Ring VII port correction (November 7, 2026)

**Magnara's main sea-facing docks, large oceangoing harbor and Iron Cothon maritime freight basins belong to the OUTERMOST Ring VII.** Ring II is the Seeker Quarters: its public canals may have **small shallow-draft local landing piers only**. The existing Ring II goods yard and courier route at approximately (14, 1382) is an **inland land-wagon receiving depot**, never a coast, a port or a large-ship berth. The Ring II harbor-survey counter opens a **separately loaded remote Ring VII scenic preview**, not a physical inter-ring crossing. The exact shoreline and the route from Ring II canal to Ring VII seaport are not mapped or author-approved, so the game must not claim that ships or barges already traverse it.

## The cargo now travels through the city

V0.71 had **three real moving public freight wagons** cycling along the road from z≈732 to z≈1400. Previously their cargo labels were illustrative and did not change other shop systems. In V0.73, crossing the north depot at z≈1395 during the **northbound** segment actually **queues a single physical local delivery**. A full 3D courier with cargo, a collision capsule, boots, coat and crate then walks a safe sequence of existing public street intersections to a workroom.

- Three freight wagons can each initiate **one local delivery per in-game day**, using a stable receipt ID `v073_d<day>_w<wagon>`. A duplicated dock callback cannot create additional goods.
- The initial pilot loops across **12 directly connected public venues** over four game days, in x=-1/0/+1 and rows 5–8 of the existing V0.71 ward extension. This does **not** imply every one of Magnara's 270 modular buildings receives an actual cargo convoy yet. The other 18 new outer-ring venues are unaffected by the first pilot.
- Each delivery starts at the physical freight station, travels along road-axis waypoints, then approaches the actual open venue door from **outside**. Freight completion requires reaching the entire route. No inventory changes on dock arrival, animation start, scene reload or menu open.
- Once goods arrive, the existing public workroom's persistent **inventory increases by four bounded units** (starting at two, up to a limit of 18). Up to six crates are visibly represented as **actual collidable furniture stock** along the rear storage wall. Their physical shapes are disabled when the visible crates are absent. The existing Local Commerce TALK/USE conversation reports the exact current ledger count and work category.
- On arrival a verified saved-game write records both updated stock and a consumed receipt. An incomplete courier's **pending state/elapsed position** is also saved with the original character data, so reopening the game resumes its ongoing route. No money changes hands with the player; country-specific freight labels remain hypothetical rather than actual border crossings.

The freight station near x≈14,z≈1375 has new visible staged goods, a public desk, and a TALK/USE notice that reports which wagon is awaiting arrival, in transit or has delivered.

Code: `systems/magnara_local_logistics_rules_v073.gd` for cargo authorization, fixed delivery descriptions, road waypoints, ledger sanitization, receipt replay gates, and courier progress; `world/magnara_local_logistics_v073.gd` for real 3D courier/depot UI and inventory commit; V0.71 wagon receives a small physical-dock crossing callback. The verified save remains version 1 and continues to support previous profiles.

## More recognizable civilian life after work

The V0.72 public workrooms already have one original civilian (#11) serving daytime shifts. V0.73 adds a **second existing roster resident (#10)** as a visible neighbor or household guest between **17:40 and 20:20 game time**, using the same existing name and household that were already allocated to the public ward. When physically inside a workroom this person is suppressed from the street NPC LOD, preventing the same person from appearing in two places at once.

These visits add an identifiable off-duty social routine and TALK/USE conversation. This is not a new Seeker character, does not alter the sealed squad era, and grants no Soul/Will power or new faction affiliation.

## Hard limitations and continued production

- **Zero fabrications:** no country-border shipment, protected Iron Cothon military access, Phantom Tola dealing, Red Order dispatch, unlocked Abyssal Line, or invisible full-world journey. The initial freight pilot is **local-city-only**.
- **Population budget:** the previous 270 modular Ring II building shells and 435 V0.67+V0.71 generated resident identities remain; this version adds **no claimed 360 more NPCs**. Delivery couriers are only three actual temporary worker models. The after-hours guests are pre-existing characters (#10), not duplicate identities.
- **Realism:** port ocean physics, 3D wind wave fields, optional skiff steering and ship wakes are preserved from V0.71/V0.72. This version focuses on real freight movement and stored material goods, not a second pass of beach waves or underwater lighting.
- **iPhone performance:** courier bodies are hidden and have disabled collision beyond 170m from the player, but ledger travel progression remains. Workroom stock geometry is loaded only with the previous nine-neighbor district cap. Real hardware FPS, touch hit targets, thermal overhead and movement smoothness still need device verification.
- **Next:** link actual local warehouse inventories to original canonical businesses only after a carefully designed public sourcing layer; add visibly unloading port cranes/porters, longer shipping schedules without claiming unverified national routes, larger multistory interiors and family visits between households (subject to geography/physical door access). Lakes and rivers not mapped in creator canon remain unplaced rather than guessed.

## Automated tests

1. `tests/v073_local_freight_rules_scene.tscn`: three physical wagon identifiers, 12 real road-visible workrooms, courier path length/termination, one-time receipts, ledger sanitation against forged goods and unsupported national routes, and no duplicated resident between evening world/room LOD.
2. `tests/v073_local_freight_world_scene.tscn`: instantiates actual Godot game, interacts with public depot, stimulates real V0.71 wagon crossing the depot, sees the collidable crate-carrying courier, verifies a safe in-transit save/reload, completes delivery and checks six collidable store crates, one-time persisted stock, and the evening worker/guest identity. Also checks old Magnara/ship modules remain.
3. Regression: V0.72 live interiors and player-carrying skiff, V0.71 world-wave/ship/swim, V0.70 moving trolley and trialboard, V0.69 posture/safe alchemy/guild, V0.68 roofs, V0.67 population/streaming, V0.66 shops, V0.65 people, V0.64 civic, V0.63 verified saves, V0.62 market, V0.61 work, V0.54 atlas, V0.46 Spokes; Web export. Promote to `codex-modular-v31` only after stage passes, keep original browser `main` untouched.
