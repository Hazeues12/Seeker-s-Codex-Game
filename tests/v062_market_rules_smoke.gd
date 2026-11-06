extends Node3D
const Rules = preload("res://systems/magnara_market_rules_v062.gd")
const TEMP_FILE: String = "user://v062_market_rules_test.json"

func _ready() -> void:
    call_deferred("_check")

func _fail(why: String) -> void:
    push_error("V0.62 MARKET RULES FAILED: " + why)
    get_tree().call_deferred("quit", 1)

func _check() -> void:
    if Rules.IDS.size() != 3 or Rules.ITEMS.size() != 3 or Rules.BASE_PRICES.size() != 3:
        _fail("three distinct everyday market goods are missing")
        return
    if Rules.is_open(479.0) or not Rules.is_open(480.0) or not Rules.is_open(1079.0) or Rules.is_open(1080.0):
        _fail("real daily market hours don't match their signs")
        return
    if not Rules.is_open(480.0 + 1440.0):
        _fail("vendors don't reopen the following day")
        return
    if not Rules.sanitize_social({})["vendors"].is_empty() or not Rules.sanitize_stock({}).is_empty():
        _fail("old save defaults aren't neutral")
        return
    if Rules.price("invented_clan", 1, {}, 0, 0) != 0 or Rules.remaining_stock("invented_clan", 1, {}) != 0:
        _fail("unknown goods can be sold through a forged shop")
        return
    if Rules.price("provisions", 1, {}, 0, 0) != 7:
        _fail("day-one public provision quote doesn't match the deterministic formula")
        return
    if Rules.price("provisions", 5, {}, 0, 0) != 6:
        _fail("day-to-day provision prices don't change in a bounded way")
        return
    if Rules.sell_price("provisions", 1, {}, 0, 0) != 2:
        _fail("buyback could produce a risk-free same-day arbitrage")
        return
    for shop in Rules.IDS:
        var stock: Dictionary = {}
        var initial: int = Rules.remaining_stock(shop, 1, stock)
        if initial < 3 or initial > 6:
            _fail("daily stock not constrained " + shop)
            return
        for n in range(initial):
            stock = Rules.record_purchase(stock, shop, 1)
            if stock.is_empty():
                _fail("purchases exhausted stock too soon " + shop)
                return
        if Rules.remaining_stock(shop, 1, stock) != 0 or not Rules.record_purchase(stock, shop, 1).is_empty():
            _fail("limited stock can be purchased indefinitely " + shop)
            return
        if Rules.remaining_stock(shop, 2, stock) < 3:
            _fail("next-day public supply didn't replenish " + shop)
            return
        for day in range(1, 12):
            var quote: int = Rules.price(shop, day, {}, 0, 0)
            var sell: int = Rules.sell_price(shop, day, {}, 0, 0)
            if quote < 4 or quote > 19 or sell <= 0 or sell >= quote:
                _fail("buyback or quote outside safe advertised limits " + shop)
                return
    var public: Dictionary = Rules.sanitize_social({})
    if not Rules.can_socialize(public, "provisions", 1):
        _fail("unmet merchants can't be approached")
        return
    var assisted: Dictionary = Rules.apply_social(public, "provisions", "assist", 1)
    if Rules.rapport(assisted, "provisions") != 2 or Rules.rapport(assisted, "textiles") != 0:
        _fail("merchant relationship leaked across vendors")
        return
    if not Rules.apply_social(assisted, "provisions", "assist", 1).is_empty():
        _fail("social choices can be farmed multiple times per day")
        return
    if Rules.price("provisions", 1, assisted, 0, 0) != 6:
        _fail("earned merchant rapport doesn't influence actual shop price")
        return
    if Rules.price("provisions", 1, assisted, 3, 0) != 5:
        _fail("neighboring residential trust doesn't affect the market")
        return
    var pressured: Dictionary = Rules.apply_social(assisted, "provisions", "pressure", 2)
    var again: Dictionary = Rules.apply_social(pressured, "provisions", "pressure", 3)
    if Rules.rapport(again, "provisions") != -2:
        _fail("merchant forgot intimidation")
        return
    if Rules.vendor_response(again, "provisions").find("wary") < 0:
        _fail("negative reputation has no visible seller consequence")
        return
    var hardware_base: int = Rules.price("hardware", 1, {}, 0, 0)
    if Rules.price("hardware", 1, {}, 0, 4) != hardware_base - 1:
        _fail("responsible workshop service has no commercial effect")
        return
    var fake_stock: Dictionary = Rules.sanitize_stock({
        "day:1:provisions": 5000,
        "day:2:unlicensed_special_eye": 900,
        "day:-1:hardware": 99,
        "day:4:textiles": -100
    })
    if fake_stock.size() != 2 or int(fake_stock["day:1:provisions"]) != 6 or int(fake_stock["day:4:textiles"]) != 0:
        _fail("counterfeit merchant stock passed validation")
        return
    var fake_social: Dictionary = Rules.sanitize_social({
        "vendors": {
            "provisions": {"rapport": 999, "days": {"day:1": "assist", "day:2": "mind_control", "day:-1": "assist"}},
            "forbidden_eye_merchant": {"rapport": 999}
        }
    })
    if Rules.rapport(fake_social, "provisions") != 6 or fake_social["vendors"].size() != 1:
        _fail("forged vendor influence wasn't clamped")
        return
    if not Rules.can_socialize(fake_social, "provisions", 2) or Rules.can_socialize(fake_social, "provisions", 1):
        _fail("invalid or legitimate merchant-day history sanitized incorrectly")
        return
    var file := FileAccess.open(TEMP_FILE, FileAccess.WRITE)
    if file == null:
        _fail("isolated market save path unavailable")
        return
    var persisted: Dictionary = {"social": assisted, "stock": fake_stock}
    file.store_string(JSON.stringify(persisted))
    file.close()
    file = FileAccess.open(TEMP_FILE, FileAccess.READ)
    if file == null:
        _fail("market saved record could not be opened")
        return
    var stored: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_FILE))
    if typeof(stored) != TYPE_DICTIONARY:
        _fail("market records corrupted on disk")
        return
    if Rules.sanitize_social(stored.get("social", {})) != assisted or Rules.sanitize_stock(stored.get("stock", {})) != fake_stock:
        _fail("both vendor history and purchased stock must survive reload")
        return
    print("V0.62 DAILY MARKET INVENTORY PRICES SOCIAL MEMORY AND SAVE RULES PASS")
    get_tree().call_deferred("quit", 0)
