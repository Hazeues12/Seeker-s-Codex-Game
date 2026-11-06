# Seeker's Codex — V0.62 Magnara Public Market & Mixed-Income Neighborhoods

**Production branch:** `codex-modular-v31` after staging validation. **Year:** 1500 A.S. **Priority:** Build physical, traversable World of Margerina first.

## Actual connected 3D city construction
This milestone extends Magnara's public **Ring II** beyond the two earlier prototype lanes, maintaining an approximately 1 unit = 1 meter street scale. It builds three continued north-south spines, two east-west cross avenues, a small public market square, a civic well, road lights and pedestrian approaches.

**Six enterable homes with real collision** represent three socioeconomic contexts: two modest worker rowhouses on the western street, two better-appointed eastern townhouses, and two market lodgings near the central trading lane. Each has an actual open doorway, continuous floor, roof, furniture, shelving, pavement spur and exterior wayfinding. Their class labels describe game-only building typologies; these homes do not confer hereditary nobility or establish new canon streets.

Three distinct **public market stalls** have mesh counters, merchandise props, awnings, crate storage, simple 3D vendors, posted signage and an in-game day schedule. The market operates 08:00–18:00. Each merchant goes off duty afterward. Visitors travel and interact with an actual stall using existing TALK / USE and iPhone UI. The established resident and worker quarters, old bridge/river exploration, and current Seeker systems remain.

## Actual market mechanics and saved consequences
The stalls respectively trade **Travel Rations**, **Repair Cloth** and **Tool Parts**. These are provisional generic items, rather than named canon relics or guild artifacts. Their price is computed deterministically each in-game day with bounded variation, capped stock (3–6 purchased units per day) and modest discounts/surcharges based on the individual's merchant rapport, the V0.60 neighborhood community trust, and V0.61 responsible workshop conduct.

The player can **buy or sell one unit** at a time, using real Tola and the existing in-game inventory. The buyback quote is a fraction of the selling price, blocking obvious same-day buy/sell arbitrage. Item name, money and bought-stock ledger **share one existing game-save file**; the V0.62 transaction reads the file back and checks the three states match. Player identity and merchant relationships remain separately in the Personal Codex because they do not need to participate in coin/item commits.

Each vendor also offers three separate daily social choices: *listen* (+1 rapport), *help with deliveries* (+2) or *pressure for a discount* (-2). Only one social response per vendor per day counts, preventing unlimited rapport gains. Individual merchants remember how the original Seeker treated them, and their prices respond. The Personal Codex shows these social relationships. Saving older profiles requires no new mandatory fields.

## Canon and geography boundaries
Magnara's proposed 26 km, seven-ring plan still guides physical scale. This public market provides routine household services; it does not move the canonical **Ring IV Merchant Quarter**, **Ring V Artisan Promenade**, Nightweave Row, Onikaze Forge or **Ring VI Iron Cothon**. The precise coordinates of these new streets are *not* new lore facts. No new named canonical inhabitant, national border, rare Muti, Seeker rank, secret Eye or restricted Citadel entry is invented.

The V0.54 256 m geographic tiling remains live, and tile 0:1's generic masses are suppressed to avoid blocking authored neighborhoods. This is a hand-built small extension within the conceptual full-scale city; **it is not a claim that all 531 km² of Magnara is completed**.

## Implementation files
- `world/magnara_markets_v062.gd`: actual connected streets, six open homes, staffed stalls, real buy/sell, mobile UI, deterministic day schedule.
- `systems/magnara_market_rules_v062.gd`: bounded stock, safe buyback pricing, reputation rules and daily social records.
- `data/magnara_market_registry_v062.json`: proposed map site registry, class variation and explicit source provenance.
- `systems/hub_manager.gd`: market stock belongs to the SAME legacy game save as money and inventory, interaction routing, modal handling.
- `characters/player_controller.gd`, `systems/personal_codex.gd`, `scenes/main.tscn`: integration and persistent social view.
- `tests/v062_market_rules_smoke.gd` and `tests/v062_market_world_smoke.gd`: price/stock validation, old-save compatibility, real-world physical collision, buyer/seller transactions, true disk reload, social memory and clock-based stall closures.

## Current limits / next steps
Street buildings and residents are prototype low-poly shapes rather than final art. No working shop supply chain, cargo simulation, homes with owned property deeds, room tenancy, full household life, crowds, immersive food usage, long-distance commerce, functioning trains or regional market economics exist yet. A single existing game-save write contains money, inventory and stock together, but the old save file still lacks a fully crash-atomic temp-file-and-rename procedure. That is a release gate.

Further world construction should branch into broader Ring III urban civic neighborhoods and Ring IV's canonical commercial breadth after reconciling exact landmark positions with lore. There should be varied architecture, social classes, open interiors, guarded government precincts and meaningful transport before declaring Magnara finished. **Do not request a new iPhone playtest while the broader world is unfinished.**
