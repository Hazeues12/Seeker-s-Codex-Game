# World of Margerina — V0.61 Working Service Quarter

**Era:** 1500 A.S. **Location:** Public side of Magnara Ring II, Janoah. **Status:** Internal browser RPG production build.

## What this milestone physically adds
A new working-class service lane continues the V0.52 western professional street north for approximately 140 meters in the existing 1m:1m Godot world. Its new crossing at provisional z=207 connects to the **east-side V0.60 residential street**, rather than making another isolated interior. There are three genuinely open, collidable public workshop rooms with an unblocked east-facing doorway, interior benches, roof structures and work props:
- **Forge Service** with repair anvil and safe hearth. This is a Ring II service shop; the canonical Onikaze Forge remains associated with Ring V and has not been moved.
- **Cloth Repair** with actual loom meshes, rolls and worktables. The named Ring V Nightweave Row remains untouched.
- **Freight Tally** with industrial ledger and inspection rack, alongside a prototype freight depot and **non-operating** rail siding. This is not a working train or a confirmed national rail route.

The public route also has paved sidewalks, street lamps, a crossing pavement, visible worker models, a daytime work board, and a signal lantern that changes with worker trust. The open rooms, sidewalks and freight platform have physics collision. Meshes and materials are reused; the overall device performance still needs real iPhone browser validation.

A critical world repair protects the hand-authored **0:1 geographic tile** from the older V0.54 generator's generic solid mass buildings, which previously could cover the residential street and new workshops with invisible/visible collision. The underlying 1:1 terrain and surveying grid remain; the approved seven-ring 26 km conceptual geography remains unchanged.

## Young Blood ideas brought into the 3D environment
A character who chose **Live a Trade** at the physical Life Registrar can earn local wages through **three distinct real-world-stage jobs**. At an open day-work board (08:00–19:00 in-game), select one employer, walk to a freight depot, collect the assigned materials, then travel into the correct workshop to finish. The final meaningful decision:
- **Careful work:** base 14 Tola (subject to local relations and personal background), +2 worker trust.
- **Rushed work:** base 17 Tola, -3 worker trust. This is a shortcut with consequences, not a reliable path to unlimited income.
- **Refuse unsafe work:** no wage, +1 worker trust.

A previously earned community relationship with the three residential households influences pay by +2 / 0 / -2 Tola depending on the threshold. Existing original-Seeker traits, perks and **debt** are applied using the V0.58 wage-withholding model. Each calendar day can record at most one completed paid shift, and the Personal Codex remembers job, outcome, receipt, trust, completed shifts and outstanding work materials. Forged unknown jobs and illegal transitions are rejected.

This is the **beginning** of 3D working-class life and career simulation, not yet nine full trades, fully simulated supply chains, taxes, economic market prices, buy/sell inventory, business ownership or NPC employment contracts. Workers follow low-cost game-clock positions, not sophisticated navigation AI or full motion animation. The cross-file Codex/game-currency save lacks a general crash-recovery journal. Close that gap before a release candidate.

## Canon fidelity
The named source-lore establishments (Nightweave Row, Onikaze Forge, Iron Cothon) keep their existing larger-city roles and proposed Ring V/VI placements. The new working service strip is provisional Ring II civic servicing; it is **not** presented as the entire industrial/artisan city. No family claim, licensed Seeker power, official guild appointment or rare inherited Eye is unlocked by employment. The known world beyond the Abyssal Line is excluded.

## Deliverables and tests
- `world/magnara_workshops_v061.gd`: actual street, interiors, depot, workers, mobile dialogue and shift interactions.
- `systems/magnara_workshop_rules_v061.gd`: pure validated employment stages, daily receipts, safe/rush/refuse outcomes and worker reputation.
- `data/magnara_workshops_v061.json`: local source status and site registry.
- `world/magnara_geography_v054.gd`: authored-neighborhood collision protection for tile 0:1.
- Main scene, hub, movement and Personal Codex integration.
- Dedicated V0.61 pure tests and instantiated physical-world tests, plus all V0.48–V0.60 regressions, Godot 4.4.1 import/startup and internal HTML5 export.

**Next physical scope:** More city blocks and varied housing on northward routes, larger civic and working centers, future author-locked Ring III transitions, and eventually the actual Ring V Artisan Promenade and Ring VI Iron Cothon. Keep public releases off until the larger game is playable, aesthetically cohesive and device-tested.
