extends Node3D
const Shop = preload("res://systems/magnara_business_rules_v066.gd")
const Population = preload("res://systems/character_population_rules_v065.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("V0.66 REGIONAL BUSINESS RULES FAILED: " + reason)
    get_tree().call_deferred("quit", 1)

func _run() -> void:
    var regional: Dictionary = Shop.read_region_registry()
    if not Shop.valid_regions(regional):
        _fail("unbuilt overseas cities allowed to spawn active population")
        return
    var real: int = 0
    var areas: Array = regional.get("regions", [])
    if areas.size() < 12:
        _fail("missing country and city population registry")
        return
    for area in areas:
        if bool(area.get("physical_implemented", false)):
            real += 1
            if str(area.get("id", "")) != "magnara_ring_two":
                _fail("foreign regional populations falsely activated")
                return
    if real != 1:
        _fail("more or fewer than one actual fully gated region")
        return
    var cast: Dictionary = Population.load_registry()
    if not Population.valid_roster(cast):
        _fail("V0.65 canon cast changed or 31 civilians malformed")
        return
    if (cast.get("civilian_roster", []) as Array).size() < 31:
        _fail("missing nine retail workers, couriers and visitors")
        return
    for forbidden in ["rin_kairo", "seizen_kairo", "yobokari_morningstar", "chief_inspector_nezubunta", "onzu_squad"]:
        if Shop.may_activate("magnara_ring_two", "1500 A.S.", Population.find_actor(cast, forbidden), "trial_week_open_world_parallel"):
            _fail("secret or enemy actor automatically spawned: " + forbidden)
            return
    var william: Dictionary = Population.find_actor(cast, "william_lockhart")
    if not Shop.may_activate("magnara_ring_two", "1500 A.S.", william, "trial_week_open_world_parallel"):
        _fail("legitimate Magnara public guildmaster hidden")
        return
    if Shop.may_activate("albion_britannia", "1500 A.S.", william, "trial_week_open_world_parallel") or Shop.may_activate("magnara_ring_two", "1486 A.S.", william, "trial_week_open_world_parallel"):
        _fail("canon character transported across era or unavailable city")
        return
    for visitor in (cast.get("civilian_roster", []) as Array).slice(22, 31):
        if not Shop.may_activate("magnara_ring_two", "1500 A.S.", visitor, "trial_week_open_world_parallel"):
            _fail("new local retailer won't show up in home city")
            return
        if Shop.may_activate("zhushen_chun", "1500 A.S.", visitor, "trial_week_open_world_parallel"):
            _fail("filler visitor leaked to distant country")
            return
        var anchor: String = str(visitor.get("work_anchor", ""))
        if not Population.POINTS.has(anchor) or not anchor.begins_with("shop_"):
            _fail("shop visitor does not follow real roads or authored storefronts")
            return
    var starts: Array[Vector3] = Population.street_path("market_square", "shop_vernal")
    if starts.size() < 5 or not Population.path_position("market_square","shop_vernal",1.0).is_equal_approx(Population.at_anchor("shop_vernal")):
        _fail("market pedestrian has no connected shop road")
        return
    for store in Shop.IDS:
        if Shop.name_for(store).is_empty() or Shop.item_for(store).is_empty() or Shop.quote(store, 1) < 1:
            _fail("verified book inventory has missing name or invalid price")
            return
        if Shop.stock_for(store, 1, {}) < 1:
            _fail("store had no first-day stock")
            return
        var count: int = Shop.stock_for(store, 1, {})
        var sold: Dictionary = {}
        for i in range(count):
            sold = Shop.record_buy(store, 1, sold)
            if sold.is_empty():
                _fail("valid daily stock purchase rejected")
                return
        if Shop.stock_for(store, 1, sold) != 0 or not Shop.record_buy(store, 1, sold).is_empty():
            _fail("sold-out merchandise can be generated for free")
            return
        if Shop.stock_for(store, 2, sold) <= 0:
            _fail("new day inventory did not replenish")
            return
    if not Shop.open_for("lebells", 1420.0) or not Shop.open_for("lebells", 30.0) or Shop.open_for("lebells", 630.0):
        _fail("late-night canonical diner schedule not present")
        return
    if Shop.open_for("avicci", 570.0) or not Shop.open_for("avicci", 720.0) or Shop.open_for("avicci", 1220.0):
        _fail("prototype jewelry hours not enforced")
        return
    if Shop.open_for("vernal_divongcci", 600.0) or not Shop.open_for("vernal_divongcci", 1100.0):
        _fail("perfumery shifts not enforced")
        return
    if Shop.staff_activity("lebells", 1350.0) != "late_night_service" or Shop.staff_activity("avicci", 1300.0) != "off_shift":
        _fail("distinct employee day/night service routines disappeared")
        return
    if Shop.visitor_activity(3, 300.0) == Shop.visitor_activity(4, 300.0):
        _fail("different shoppers have identical arrival patterns")
        return
    var invalid: Dictionary = Shop.sanitize_stock({"day:1:lebells": 3, "day:5:avicci": 2,
        "day:5:forbidden": 12, "day:-1:lebells": 5, "day:1.5:lebells": 6,
        "day:99:lebells": "ten", "day:2:vernal_divongcci": 77})
    if invalid.size() != 3 or int(invalid.get("day:2:vernal_divongcci", -1)) != 36:
        _fail("invalid ledger entries accepted without sanitization")
        return
    print("V0.66 TWELVE REGIONS THREE CANON BUSINESSES THIRTY-ONE CIVILIAN ROUTINES AND TRANSACTION RULES PASS")
    get_tree().call_deferred("quit", 0)
