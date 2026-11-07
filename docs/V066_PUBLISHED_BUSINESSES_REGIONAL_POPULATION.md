# Seeker's Codex: Young Blood 3D — V0.66 Canon Businesses & Region Population Gates

**Engine:** Godot 4.4.1 Web, 1500 A.S. | **Continuity:** Canon published setting with explicitly game-only local implementation | **Protected:** original browser game `main`, 3D work `codex-modular-v31`.

## Source research

[Seeker's Codex: Beyond the Abyssal Line, Trial By Mercy: Darker Than Black Pt 8](https://www.royalroad.com/fiction/132012/seekers-codex-beyond-the-abyssal-line/chapter/4243742/trial-by-mercy-darker-than-black-pt-8) explicitly has Rin pass above Le'Bell's late-night forge-bread diners, the Avicci jewelry house known for Water/Earth-Muti-grown stones, and Vernal Divongcci's fragrance display. It also describes 24-hour shopping nearby and guild flags for Flama, BLADE and Terra Firma. That published chapter does not settle store owners, product SKU names, exact shop addresses, employees, opening and closing hours, or price lists; all those newly necessary implementation details are **game-only placeholders** and must not be published as canon.

The completed V0.65 character audit currently lists 64 named story figures/groups, 10 factions, and 10 known venues. V0.66 keeps that canonical registry, appends nine original civilian workers/customers/couriers, and extends the authored schedule/path map with three legitimate shopping destinations. Now **31 independent game-only civilians** have distinct routine anchors, plus six public story personalities at the Talking Boar: **37 ordinary onstage NPC models in the V0.65 system**, plus three scheduled V0.66 store workers. All use lightweight mesh stand-ins for mobile budget. This does **not** mean all the canon roster is physically present at once.

## Real V0.66 play content

Implemented 3 real, interior-accessible businesses just north of the Talking Boar along connected three-spine street geometry. Separate shops have solid floor/roof, an open doorway, counter, accessible public pavement and a scheduled employee. Le'Bell's includes kitchen oven, diner tables and bread trays; Avicci includes jewelry cases and display; Vernal Divongcci includes fragrance shelves and bottles. Characters can walk up and interact using the existing TALK / USE button. Shop windows and lamps are stylized placeholders.

**Prototype economy:** Le'Bell's offers a Forge-Bread Portion, Avicci offers a Water-Earth Pendant, Vernal Divongcci a Fragrance. All are original in-game merchandise inspired by the published product category, with game-only prices 9/34/17 Tola (minor deterministic daily +/-1 changes), limited daily stock, service hours and replenishment. Nighttime diners are supported at Le'Bell's. A purchased item is added to the existing player inventory, not a lore power. Tola, daily stock ledger and inventory are written together using V0.63's verified world-save path; any unverifiable purchase rolls back local money, items and stock. Existing V0.62 market and V0.64 inn/clinic records remain compatible. Personal Codex gets separate game-only purchase history.

## Regional people registry

`data/margerina_region_population_v066.json` registers **12 distinct region or city zones** with known characters and site anchors: Magnara's playable Ring II, remaining Magnara rings, Bodhira, Rajir, Zhushen, Vinlan, Albion, Dune States, Tsar Empire, Zirael, Curan, Guan Diego. Only Ring II is marked physical and allowed to instantiate NPCs; every other zone is **registry-only**, not pretend-accessible or populated. No teleporting William to historical Albion, 1486 Light Born to 1500, Rin to a civilian vendor stand, Seizen into public streets or the Onzu Squad into ordinary animal traffic. No cross-canonical family, clan, rare eye or guild rank is assigned to new citizens.

The data will allow later expansions to stream each region's own author-approved citizens, houses, guild membership, equipment, shops and schedules once geographical/chronological evidence is available. The location atlas is **not** yet fully implemented.

## Regression verification

- `tests/v066_business_rules_scene.tscn`: 12 regional gates, nine new residents, required original story roster, source-grounded shop categories, night hours, daily inventory, price/stock safety, no antagonists/covet summons in street population, no unsupported regional spawn.
- `tests/v066_business_world_scene.tscn`: entire current 3D scene, 3 physical storefronts with colliders/interiors and staff, route continuity, actual touch interactions, inventory/tola/day-ledger commits and disk reloads, 37 V0.65 population meshes, day/night schedules, old district state untouched.
- Staging GitHub Actions workflow validates both tests, V0.65 character world, V0.64 civic world, V0.63 verified saves, V0.62 trade regression and Web export. Main development branch promotion only after full green validation.

## Next author's-city milestones

Expand canonical shop inventories only when confirmed, build actual Flama/BLADE/Terra Firma guild halls with correct physical boundaries, plus a many-block city transit and city-business staffing network. Later physical cities need their distinct architectures, politics, families, squads, wildlife, shops and vehicles with sensible streaming budgets; this remains a long iterative world-building project. Content dialogue/personalities must follow verified public portrayals, with unpublished/sealed motives withheld from ambient NPCs. Continuous off-screen routine evaluation is deterministic simulation; it is not autonomous sentient NPC intelligence or a full real-world clock.

**Honesty note:** Godot headless and HTML5 export success cannot demonstrate actual iPhone Safari FPS, battery or browser-storage durability. Those are deferred device gates.
