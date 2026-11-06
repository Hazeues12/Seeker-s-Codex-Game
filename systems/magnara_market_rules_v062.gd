extends RefCounted
# V0.62 provisional Ring II public market, three vendors, daily goods and rapport.
# World coordinates and the particular merchants are GAME ONLY.
const IDS: Array[String] = ["provisions", "textiles", "hardware"]
const NAMES: Array[String] = ["Provision Seller", "Cloth Merchant", "Repair Parts Merchant"]
const ITEMS: Array[String] = ["Travel Rations", "Repair Cloth", "Tool Parts"]
const BASE_PRICES: Array[int] = [8, 12, 15]
const ACTS: Array[String] = ["listen", "assist", "pressure"]
const OPEN_AT: int = 480
const CLOSE_AT: int = 1080

static func title_for(shop: String) -> String:
    var i: int = IDS.find(shop)
    return NAMES[i] if i >= 0 else "Unknown stall"

static func item_for(shop: String) -> String:
    var i: int = IDS.find(shop)
    return ITEMS[i] if i >= 0 else ""

static func is_open(world_minutes: float) -> bool:
    var local: float = fposmod(world_minutes, 1440.0)
    return local >= float(OPEN_AT) and local < float(CLOSE_AT)

static func remaining_stock(shop: String, day: int, stock_data: Variant) -> int:
    if not IDS.has(shop) or day < 1:
        return 0
    var i: int = IDS.find(shop)
    var available: int = 3 + posmod(day + 2 * i, 4)
    var ledger: Dictionary = sanitize_stock(stock_data)
    var bought: int = int(ledger.get("day:%d:%s" % [day, shop], 0))
    return maxi(0, available - bought)

static func sanitize_stock(value: Variant) -> Dictionary:
    var result: Dictionary = {}
    if typeof(value) != TYPE_DICTIONARY:
        return result
    var raw: Dictionary = value
    var keys: Array = raw.keys()
    keys.sort()
    for key in keys:
        var text_key: String = str(key)
        var parts: PackedStringArray = text_key.split(":")
        if parts.size() != 3 or parts[0] != "day" or not parts[1].is_valid_int():
            continue
        if int(parts[1]) < 1 or not IDS.has(parts[2]):
            continue
        result[text_key] = clampi(int(raw[key]), 0, 6)
        if result.size() >= 1500:
            break
    return result

static func record_purchase(value: Variant, shop: String, day: int) -> Dictionary:
    if remaining_stock(shop, day, value) <= 0:
        return {}
    var next: Dictionary = sanitize_stock(value)
    var key: String = "day:%d:%s" % [day, shop]
    next[key] = int(next.get(key, 0)) + 1
    return next

static func empty_social() -> Dictionary:
    return {"version": 1, "vendors": {}}

static func sanitize_social(value: Variant) -> Dictionary:
    var clean: Dictionary = empty_social()
    if typeof(value) != TYPE_DICTIONARY:
        return clean
    var raw: Dictionary = value
    var vendors: Variant = raw.get("vendors", {})
    if typeof(vendors) != TYPE_DICTIONARY:
        return clean
    for shop in IDS:
        if not vendors.has(shop):
            continue
        var candidate: Variant = vendors[shop]
        if typeof(candidate) != TYPE_DICTIONARY:
            continue
        var vendor: Dictionary = candidate
        var old_days: Variant = vendor.get("days", {})
        var days: Dictionary = {}
        if typeof(old_days) == TYPE_DICTIONARY:
            var keys: Array = old_days.keys()
            keys.sort()
            for key in keys:
                var stamp: String = str(key)
                var event: String = str(old_days[key])
                if stamp.begins_with("day:") and stamp.substr(4).is_valid_int() and int(stamp.substr(4)) > 0 and ACTS.has(event):
                    days[stamp] = event
                    if days.size() >= 2000:
                        break
        clean["vendors"][shop] = {
            "rapport": clampi(int(vendor.get("rapport", 0)), -6, 6),
            "days": days
        }
    return clean

static func rapport(value: Variant, shop: String) -> int:
    if not IDS.has(shop):
        return 0
    var clean: Dictionary = sanitize_social(value)
    return int(clean["vendors"].get(shop, {}).get("rapport", 0))

static func can_socialize(value: Variant, shop: String, day: int) -> bool:
    if not IDS.has(shop) or day < 1:
        return false
    var clean: Dictionary = sanitize_social(value)
    var vendor: Dictionary = clean["vendors"].get(shop, {})
    return not vendor.get("days", {}).has("day:%d" % day)

static func apply_social(value: Variant, shop: String, action: String, day: int) -> Dictionary:
    if not ACTS.has(action) or not can_socialize(value, shop, day):
        return {}
    var result: Dictionary = sanitize_social(value)
    var vendor: Dictionary = result["vendors"].get(shop, {"rapport": 0, "days": {}})
    var effect: int = 2 if action == "assist" else (1 if action == "listen" else -2)
    vendor["rapport"] = clampi(int(vendor["rapport"]) + effect, -6, 6)
    var old_days: Dictionary = vendor.get("days", {})
    old_days["day:%d" % day] = action
    vendor["days"] = old_days
    result["vendors"][shop] = vendor
    return result

static func price(shop: String, day: int, social: Variant, residential_trust: int,
        workshop_trust: int) -> int:
    var i: int = IDS.find(shop)
    if i < 0 or day < 1:
        return 0
    # Reproducible public daily supply swings; bounded (+/- 2) and never
    # speculative real-world pricing claims.
    var swing: int = posmod(day + i * 2, 5) - 2
    var affinity: int = rapport(social, shop)
    var merchant_delta: int = -1 if affinity >= 2 else (1 if affinity <= -2 else 0)
    var local_delta: int = -1 if residential_trust >= 3 else (1 if residential_trust <= -3 else 0)
    var worker_delta: int = -1 if shop == "hardware" and workshop_trust >= 4 else 0
    return maxi(4, BASE_PRICES[i] + swing + merchant_delta + local_delta + worker_delta)

static func sell_price(shop: String, day: int, social: Variant, residential_trust: int,
        workshop_trust: int) -> int:
    var quote: int = price(shop, day, social, residential_trust, workshop_trust)
    return maxi(1, int(floorf(float(quote) * 0.35))) if quote > 0 else 0

static func vendor_response(value: Variant, shop: String) -> String:
    var trust: int = rapport(value, shop)
    if trust >= 3:
        return "The merchant trusts you to keep agreements and offers fair attention."
    if trust <= -3:
        return "The merchant remembers being pressured and speaks cautiously."
    if trust > 0:
        return "The merchant recognizes your interest in the neighborhood."
    if trust < 0:
        return "Your earlier behavior has made the stall owner wary."
    return "A working merchant with customers, deliveries and a life beyond your errands."
