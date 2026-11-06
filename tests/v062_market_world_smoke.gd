extends Node3D
# V0.62 full instantiated main scene: actual accessible housing, streets,
# real market trade, one-file coins+inventory+stock and social save memory.
const World = preload("res://scenes/main.tscn")
const MarketRules = preload("res://systems/magnara_market_rules_v062.gd")

func _ready() -> void:
    call_deferred("_check")

func _fail(why: String) -> void:
    push_error("V0.62 PHYSICAL MARKET WORLD FAILED: " + why)
    get_tree().call_deferred("quit", 1)

func _check() -> void:
    var world: Node3D = World.instantiate() as Node3D
    add_child(world)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    var market: Node = world.get_node_or_null("MagnaraMarketsV062")
    var hub: Node = world.get_node_or_null("HubManager")
    var codex: Node = world.get_node_or_null("PersonalCodex")
    var player: CharacterBody3D = world.get_node_or_null("Player") as CharacterBody3D
    var old_homes: Node = world.get_node_or_null("MagnaraResidentialV060")
    var old_works: Node = world.get_node_or_null("MagnaraWorkshopsV061")
    var geo: Node = world.get_node_or_null("MagnaraGeographyV054")
    if not is_instance_valid(market) or not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(player) or not is_instance_valid(old_homes) or not is_instance_valid(old_works) or not is_instance_valid(geo):
        _fail("new world removed prior city, controls, Codex or live residential/workshop zone")
        return
    if not bool(market.get("initialized")):
        _fail("market didn't initialize inside real Magnara main scene")
        return
    var manifest: Dictionary = market.call("get_manifest")
    if int(manifest.get("ring", 0)) != 2 or manifest.get("source_status", "") != "game_only":
        _fail("new public stalls were mislabeled as another canon city ring")
        return
    if int(manifest.get("home_count", 0)) != 6 or int(manifest.get("distinct_home_classes", 0)) != 3 or int(manifest.get("public_market_stalls", 0)) != 3:
        _fail("new mixed-income district lacks six actual homes or three stalls")
        return
    for name in ["NorthMarketConnectedStreet", "CommercialRoadSouthConnector", "EastMarketSouthConnector", "MarketCrossAvenue", "CivicMarketplacePaving"]:
        var ground: Node = market.find_child(name, true, false)
        if ground == null or ground.find_child("MarketWorldCollision", true, false) == null:
            _fail("new connected road lacks a physical collision surface: " + name)
            return
    for home_id in ["west_worker_one", "west_worker_two",
        "east_townhouse_one", "east_townhouse_two",
        "market_lodging_one", "market_lodging_two"]:
        var house: Node3D = market.get_node_or_null("OpenHome_" + home_id) as Node3D
        if not is_instance_valid(house):
            _fail("home is an unbuilt procedural silhouette " + str(home_id))
            return
        for part_name in ["ActualHomeFloor", "TrueSolidHomeRoof", "ResidenceOpenDoorLintel", "HomeInteriorTable"]:
            var part: Node = house.find_child(part_name, true, false)
            if part == null or part.find_child("MarketWorldCollision", true, false) == null:
                _fail("house missing collision, actual furniture or open door: " + str(home_id))
                return
    var locs: Dictionary = {}
    for entry in hub.get("locations"):
        var id: String = str(entry.get("id", ""))
        if id.begins_with("market_v062_"):
            locs[id] = entry
    if locs.size() != 3:
        _fail("three vendor stalls weren't integrated with TALK / USE")
        return
    for shop in MarketRules.IDS:
        var stall: Node = market.get_node_or_null("PublicStall_" + shop)
        if not is_instance_valid(stall):
            _fail("physical public stall missing " + shop)
            return
        var awning: Node = stall.find_child("MerchantMarketAwning", true, false)
        var counter: Node = stall.find_child("PhysicalTradeCounter", true, false)
        var vendor: Node = stall.find_child("MarketVendor_" + shop, true, false)
        if awning == null or counter == null or counter.find_child("MarketWorldCollision", true, false) == null or vendor == null:
            _fail("stall isn't physically stocked and staffed " + shop)
            return
    await get_tree().physics_frame
    for point in [Vector3(0, 5, 239), Vector3(62, 5, 219), Vector3(0, 5, 345)]:
        var test_ray := PhysicsRayQueryParameters3D.create(point, point + Vector3(0, -8, 0))
        if get_world_3d().direct_space_state.intersect_ray(test_ray).is_empty():
            _fail("road connection is visually painted without collision: " + str(point))
            return
    var old_cash: int = GameState.tola
    var old_inventory: Dictionary = hub.get("inventory").duplicate(true)
    var shop_id: String = "market_v062_provisions"
    var target: Vector3 = locs[shop_id]["position"]
    player.global_position = target + Vector3(0, 0.5, 0)
    var nearest: Dictionary = hub.call("_nearest_location")
    if str(nearest.get("id", "")) != shop_id:
        _fail("player cannot locate and talk to real market stall")
        return
    hub.call("_interact")
    if not bool(market.call("is_open")) or not bool(hub.call("_any_panel_open")):
        _fail("market trade panel did not open or protect joystick movement")
        return
    var expected_buy: int = MarketRules.price("provisions", 1, {}, 0, 0)
    market.call("_choose", "buy")
    if GameState.tola != old_cash - expected_buy:
        var debug_quote: int = market.call("_quote", "provisions")
        var shown_message: String = str(market.get("feedback").text)
        var state_stock: Dictionary = hub.get("market_stock_v062")
        _fail("Purchase balance mismatch: before=%d actual=%d expected=%d quote=%d day=%d stock=%s feedback=%s" % [
            old_cash, GameState.tola, old_cash - expected_buy, debug_quote,
            int(market.call("_day")), JSON.stringify(state_stock), shown_message])
        return
    var after_purchase: Dictionary = hub.get("inventory")
    if int(after_purchase.get("Travel Rations", 0)) != int(old_inventory.get("Travel Rations", 0)) + 1:
        _fail("traded items were not placed into the actual game bag")
        return
    var tracked: Dictionary = hub.get("market_stock_v062")
    if MarketRules.remaining_stock("provisions", 1, tracked) != MarketRules.remaining_stock("provisions", 1, {}) - 1:
        _fail("physical market did not record the remaining supply")
        return
    var stored_game := FileAccess.open("user://margerina_v033.json", FileAccess.READ)
    if stored_game == null:
        _fail("coin, inventory and daily market stock were not saved")
        return
    var raw: Variant = JSON.parse_string(stored_game.get_as_text())
    stored_game.close()
    if typeof(raw) != TYPE_DICTIONARY or int(raw.get("tola", -1)) != GameState.tola:
        _fail("real saved currency differs from traded currency")
        return
    if market.call("_inventory_counts", raw.get("inventory", {})) != market.call("_inventory_counts", after_purchase) or MarketRules.sanitize_stock(raw.get("market_stock_v062", {})) != MarketRules.sanitize_stock(tracked):
        _fail("the trade split coins, goods or daily stock across files")
        return
    market.call("_choose", "social:assist")
    var memory: Dictionary = market.call("_social")
    if MarketRules.rapport(memory, "provisions") != 2:
        _fail("helping a shopkeeper has no persistent relationship impact")
        return
    market.call("_choose", "social:assist")
    if MarketRules.rapport(market.call("_social"), "provisions") != 2:
        _fail("one-day social choices can be exploited for endless discounts")
        return
    var receipt: int = MarketRules.sell_price("provisions", 1, memory, 0, 0)
    market.call("_choose", "sell")
    if int(hub.get("inventory").get("Travel Rations", 0)) != int(old_inventory.get("Travel Rations", 0)):
        _fail("selling did not remove the traded goods")
        return
    if GameState.tola != old_cash - expected_buy + receipt:
        _fail("sell price was not correctly credited in real Tola")
        return
    market.call("_close")
    var profile_file := FileAccess.open("user://seeker_profile_v1.json", FileAccess.READ)
    if profile_file == null:
        _fail("seller relationship Codex is not persisted")
        return
    var saved_profile: Variant = JSON.parse_string(profile_file.get_as_text())
    profile_file.close()
    if typeof(saved_profile) != TYPE_DICTIONARY or MarketRules.rapport(saved_profile.get("market_v062", {}), "provisions") != 2:
        _fail("merchant social memory didn't survive real Codex save")
        return
    # Restore the old game from disk and ensure supply and money really match
    # what was saved in the same file (not just live variables).
    var expected_cash: int = GameState.tola
    var expected_stock: Dictionary = hub.get("market_stock_v062").duplicate(true)
    GameState.tola = 0
    hub.set("inventory", {})
    hub.set("market_stock_v062", {})
    hub.call("_load_game", false)
    if GameState.tola != expected_cash or market.call("_inventory_counts", hub.get("inventory")) != market.call("_inventory_counts", old_inventory) or MarketRules.sanitize_stock(hub.get("market_stock_v062")) != MarketRules.sanitize_stock(expected_stock):
        _fail("market coins, actual bag and bought-stock ledger cannot reload together")
        return
    hub.set("world_minutes", 1200.0)
    market.call("_update_vendors")
    if market.get_node("PublicStall_provisions/MarketVendor_provisions").visible:
        _fail("vendors don't go off duty after the market closes")
        return
    market.call("interact", shop_id)
    var before_closed: int = GameState.tola
    market.call("_choose", "buy")
    if GameState.tola != before_closed:
        _fail("player can buy real goods from a closed market")
        return
    market.call("_close")
    hub.set("world_minutes", 1920.0)
    market.call("_update_vendors")
    if not market.get_node("PublicStall_provisions/MarketVendor_provisions").visible:
        _fail("merchant doesn't return when a new market day begins")
        return
    if MarketRules.remaining_stock("provisions", 2, hub.get("market_stock_v062")) < 3:
        _fail("new day did not replenish the local supply")
        return
    if not world.get_node_or_null("MagnaraCityV052") or not world.get_node_or_null("MagnaraWorkshopsV061"):
        _fail("market expansion removed an old district")
        return
    print("V0.62 ENTERABLE HOUSING STAFFED MARKET AND PERSISTENT TRADES PASS")
    world.queue_free()
    get_tree().call_deferred("quit", 0)
