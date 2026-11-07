extends RefCounted
# V0.66: Published storefront names/categories; products, prices, staff,
# addresses and hours are game-only. This is the prototype Ring II outer band,
# NOT the formal Ring IV Merchant Quarter.
const IDS: Array[String] = ["lebells", "avicci", "vernal_divongcci"]
const NAMES: Array[String] = ["Le'Bell's", "Avicci", "Vernal Divongcci"]
const ITEMS: Array[String] = ["Le'Bell's Forge-Bread Portion", "Avicci Water-Earth Pendant", "Vernal Divongcci Fragrance"]
const PRICES: Array[int] = [9, 34, 17]
const STOCK: Array[int] = [12, 4, 6]
const STAFF_ROLES: Array[String] = ["kitchen attendant", "jewelry attendant", "perfumery attendant"]
const REGIONS_FILE: String = "res://data/margerina_region_population_v066.json"
const MAX_DAYS: int = 1500

static func name_for(shop: String) -> String:
    var index: int = IDS.find(shop)
    return NAMES[index] if index >= 0 else "Unknown business"

static func item_for(shop: String) -> String:
    var index: int = IDS.find(shop)
    return ITEMS[index] if index >= 0 else ""

static func open_for(shop: String, world_minutes: float) -> bool:
    if not IDS.has(shop) or not is_finite(world_minutes):
        return false
    var local: int = posmod(int(floorf(maxf(0.0, world_minutes))), 1440)
    match shop:
        "lebells":
            # Open late enough for the published late-night diners.
            return local >= 660 or local < 120
        "avicci":
            return local >= 600 and local < 1200
        "vernal_divongcci":
            return local >= 630 and local < 1260
    return false

static func quote(shop: String, day: int) -> int:
    var index: int = IDS.find(shop)
    if index < 0 or day < 1:
        return 0
    return PRICES[index] + posmod(day + 2 * index, 3) - 1

static func sanitize_stock(value: Variant) -> Dictionary:
    var result: Dictionary = {}
    if typeof(value) != TYPE_DICTIONARY:
        return result
    var raw: Dictionary = value
    var keys: Array = raw.keys()
    keys.sort()
    for key in keys:
        var stamp: String = str(key)
        var parts: PackedStringArray = stamp.split(":")
        if parts.size() != 3 or parts[0] != "day" or not parts[1].is_valid_int() or not IDS.has(parts[2]):
            continue
        var day: int = int(parts[1])
        if day < 1 or day > 1000000:
            continue
        var count: Variant = raw[key]
        if typeof(count) != TYPE_INT and typeof(count) != TYPE_FLOAT:
            continue
        result[stamp] = clampi(int(count), 0, 36)
        if result.size() >= MAX_DAYS:
            break
    return result

static func stock_for(shop: String, day: int, book: Variant) -> int:
    var index: int = IDS.find(shop)
    if index < 0 or day < 1:
        return 0
    var available: int = STOCK[index] + posmod(day + index, 3)
    var purchased: int = int(sanitize_stock(book).get("day:%d:%s" % [day, shop], 0))
    return maxi(0, available - purchased)

static func record_buy(shop: String, day: int, book: Variant) -> Dictionary:
    if stock_for(shop, day, book) < 1:
        return {}
    var result: Dictionary = sanitize_stock(book)
    var stamp: String = "day:%d:%s" % [day, shop]
    result[stamp] = int(result.get(stamp, 0)) + 1
    return result

static func staff_activity(shop: String, world_minutes: float) -> String:
    if not IDS.has(shop):
        return "none"
    if not open_for(shop, world_minutes):
        return "off_shift"
    var local: int = posmod(int(world_minutes), 1440)
    if shop == "lebells" and (local >= 1200 or local < 120):
        return "late_night_service"
    if shop == "avicci":
        return "display_and_jewel_consultation"
    if shop == "vernal_divongcci":
        return "fragrance_blending_and_customers"
    return "kitchen_and_diners"

static func visitor_activity(visitor: int, world_minutes: float) -> String:
    if visitor < 0 or visitor >= 9:
        return "offstage"
    var hour: int = posmod(int(world_minutes) + visitor * 103, 1440)
    if hour < 330:
        return "home"
    if hour < 480:
        return "arriving"
    if hour < 950:
        return "customer_browsing"
    if hour < 1110:
        return "departing"
    return "home"

static func read_region_registry() -> Dictionary:
    var file := FileAccess.open(REGIONS_FILE, FileAccess.READ)
    if file == null:
        return {}
    var json := JSON.new()
    var ok: int = json.parse(file.get_as_text())
    file.close()
    if ok != OK or typeof(json.data) != TYPE_DICTIONARY:
        return {}
    return json.data

static func valid_regions(value: Variant) -> bool:
    if typeof(value) != TYPE_DICTIONARY:
        return false
    var data: Dictionary = value
    if int(data.get("version", 0)) != 1 or str(data.get("era", "")) != "1500 A.S.":
        return false
    var regions: Variant = data.get("regions", [])
    if typeof(regions) != TYPE_ARRAY:
        return false
    var seen: Dictionary = {}
    var real_regions: int = 0
    for entry in regions:
        if typeof(entry) != TYPE_DICTIONARY:
            return false
        var key: String = str(entry.get("id", ""))
        if key.is_empty() or seen.has(key):
            return false
        seen[key] = true
        if bool(entry.get("physical_implemented", false)):
            real_regions += 1
            if key != "magnara_ring_two":
                return false
        if str(entry.get("spawn_policy", "")) not in ["physical_limited", "registry_only"]:
            return false
    return seen.size() >= 7 and real_regions == 1

static func may_activate(region: String, era: String, character: Dictionary, phase: String) -> bool:
    # Physical spawns depend on author-approved plot phase and genuinely built
    # geography. New national entries are not magically populated overnight.
    if region != "magnara_ring_two" or era != "1500 A.S." or phase != "trial_week_open_world_parallel":
        return false
    var kind: String = str(character.get("kind", ""))
    if kind == "game_only":
        return str(character.get("region_id", "")) == region
    if kind == "canon":
        return str(character.get("public_visibility", "")) == "public" \
            and ["boar_staff", "trial_week_boar"].has(str(character.get("spawn_policy", ""))) \
            and str(character.get("scene_venue", "")) == "talking_boar"
    return false
