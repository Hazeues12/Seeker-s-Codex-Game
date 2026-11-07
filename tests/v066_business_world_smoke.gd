extends Node3D
const Main = preload("res://scenes/main.tscn")
const Rules = preload("res://systems/magnara_business_rules_v066.gd")
const NPC = preload("res://systems/character_population_rules_v065.gd")
const SaveIntegrity = preload("res://systems/game_save_integrity_v063.gd")

func _ready() -> void:
    call_deferred("_verify")

func _fail(reason: String) -> void:
    push_error("V0.66 PHYSICAL BUSINESSES FAILED: " + reason)
    get_tree().call_deferred("quit", 1)

func _verify() -> void:
    var scene: Node3D = Main.instantiate() as Node3D
    add_child(scene)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    var stores: Node = scene.get_node_or_null("MagnaraBusinessesV066")
    var citizens: Node = scene.get_node_or_null("MagnaraPopulationV065")
    var hub: Node = scene.get_node_or_null("HubManager")
    var codex: Node = scene.get_node_or_null("PersonalCodex")
    var player: CharacterBody3D = scene.get_node_or_null("Player") as CharacterBody3D
    if stores == null or citizens == null or hub == null or codex == null or player == null:
        _fail("businesses detached full game, characters, or Personal Codex")
        return
    if not bool(stores.get("initialized")):
        _fail("physical storefronts could not initialize")
        return
    for prior in ["MagnaraCivicV064","MagnaraMarketsV062","MagnaraWorkshopsV061","MagnaraResidentialV060","MagnaraGeographyV054"]:
        if scene.get_node_or_null(prior) == null:
            _fail("new physical business wiped previous city content: " + prior)
            return
    var info: Dictionary = stores.call("get_manifest")
    if int(info.get("actual_physical_businesses", 0)) != 3 or int(info.get("region_registry", 0)) < 12:
        _fail("world scene isn't three authored shops plus protected region metadata")
        return
    for id in Rules.IDS:
        var house: Node = stores.get_node_or_null("V066Shop_" + id)
        if house == null:
            _fail("actual published named shop building missing: " + id)
            return
        for part in ["V066StoreActualFloor", "V066StoreRearWall","V066StoreOpenDoorLintel","V066StoreSolidRoof","V066ShopCounter"]:
            var object: Node = house.find_child(part, true, false)
            if object == null or object.find_child("BusinessV066Collision", true, false) == null:
                _fail("shop has fake walls, no doorway or missing collidable floor: " + id + " / " + part)
                return
        var pavement: Node = stores.find_child("V066ShopApproach_" + id, true, false)
        if pavement == null or pavement.find_child("BusinessV066Collision", true, false) == null:
            _fail("walkable sidewalk doesn't reach " + id)
            return
        if house.find_child("V066StoreStaff_" + id, true, false) == null:
            _fail("shop has no actual employee")
            return
    if stores.get_node("V066Shop_lebells").find_child("V066Oven", true, false) == null:
        _fail("published late-night forge-bread diner has no real kitchen")
        return
    if stores.get_node("V066Shop_avicci").find_child("V066JewelryGlassCase", true, false) == null:
        _fail("published jewelry storefront lacks real product display")
        return
    if stores.get_node("V066Shop_vernal_divongcci").find_child("V066PerfumeBottle", true, false) == null:
        _fail("published perfumery interior lacks actual bottles")
        return
    await get_tree().physics_frame
    for origin in [Vector3(0, 6, 580), Vector3(0, 6, 620), Vector3(-62, 6, 650),
            Vector3(62, 6, 686), Vector3(0, 6, 705), Vector3(-94, 6, 620),
            Vector3(94, 6, 650), Vector3(-94, 6, 686)]:
        var ray := PhysicsRayQueryParameters3D.create(origin, origin + Vector3(0, -11, 0))
        if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
            _fail("new authored store or connected street has no floor collision at " + str(origin))
            return
    var actor_nodes: Dictionary = citizens.get("actors")
    if actor_nodes.size() < 37 or actor_nodes.has("rin_kairo") or actor_nodes.has("seizen_kairo"):
        _fail("nine new resident shoppers missing or covert cast leaked into public commerce")
        return
    for n in range(23, 32):
        if not actor_nodes.has("citizen_v065_%02d" % n):
            _fail("original civilian population wasn't expanded with separate shop residents")
            return
    var spots: Dictionary = {}
    for entry in hub.get("locations"):
        var key: String = str(entry.get("id", ""))
        if key.begins_with("shop_v066_"):
            spots[key] = entry
    if spots.size() != 3:
        _fail("three named business points aren't accessible through mobile TALK / USE")
        return
    var starting_cash: int = GameState.tola
    var old_market: Dictionary = hub.get("market_stock_v062").duplicate(true)
    var old_civic: Dictionary = hub.get("civic_v064").duplicate(true)
    hub.set("world_minutes", 1380.0)
    stores.call("_update_workers")
    if not stores.get_node("V066Shop_lebells/V066StoreStaff_lebells").visible:
        _fail("published late-night diner not staffed after 23:00")
        return
    if stores.get_node("V066Shop_avicci/V066StoreStaff_avicci").visible:
        _fail("daytime jewelry shop still pretending to be staffed at midnight")
        return
    player.global_position = spots["shop_v066_lebells"]["position"] + Vector3(0, 0.5, 0)
    if str(hub.call("_nearest_location").get("id", "")) != "shop_v066_lebells":
        _fail("player cannot physically walk up to diner service desk")
        return
    hub.call("_interact")
    if not bool(stores.call("is_open")) or not bool(hub.call("_any_panel_open")):
        _fail("touchscreen diner interaction failed")
        return
    var bread_price: int = Rules.quote("lebells", 1)
    stores.call("_choose", "purchase")
    if GameState.tola != starting_cash - bread_price or int(hub.get("inventory").get(Rules.item_for("lebells"), 0)) != 1:
        _fail("real dining purchase didn't update Tola and bag")
        return
    stores.call("_close")
    hub.set("world_minutes", 690.0)
    stores.call("_update_workers")
    if not stores.get_node("V066Shop_avicci/V066StoreStaff_avicci").visible or not stores.get_node("V066Shop_vernal_divongcci/V066StoreStaff_vernal_divongcci").visible:
        _fail("jewelry and perfumery staff didn't start their daytime shifts")
        return
    for id in ["avicci", "vernal_divongcci"]:
        player.global_position = spots["shop_v066_" + id]["position"] + Vector3(0, 0.5, 0)
        if str(hub.call("_nearest_location").get("id", "")) != "shop_v066_" + id:
            _fail("store counter interaction blocked: " + id)
            return
        hub.call("_interact")
        if not bool(stores.call("is_open")):
            _fail("business panel did not open: " + id)
            return
        stores.call("_choose", "purchase")
        if int(hub.get("inventory").get(Rules.item_for(id), 0)) != 1:
            _fail("valid purchased merchandise did not enter inventory: " + id)
            return
        stores.call("_close")
    var total: int = Rules.quote("lebells",1)+Rules.quote("avicci",1)+Rules.quote("vernal_divongcci",1)
    if GameState.tola != starting_cash-total:
        _fail("three retailers don't charge exact daily prices")
        return
    var shop_stock: Dictionary = Rules.sanitize_stock(hub.get("shop_stock_v066"))
    var disk: Dictionary = SaveIntegrity.load_best().get("data", {})
    if int(disk.get("tola", -1)) != starting_cash-total or Rules.sanitize_stock(disk.get("shop_stock_v066", {})) != shop_stock:
        _fail("retail Tola and stock not stored in same verified save")
        return
    if hub.get("market_stock_v062") != old_market or hub.get("civic_v064") != old_civic:
        _fail("new businesses damaged old market and civic receipts")
        return
    GameState.tola = 0
    hub.set("shop_stock_v066", {})
    hub.set("inventory", {})
    hub.call("_load_game", false)
    if GameState.tola != starting_cash-total or Rules.sanitize_stock(hub.get("shop_stock_v066")) != shop_stock:
        _fail("store ledger and Tola didn't survive real save reload")
        return
    for id in Rules.IDS:
        if int(hub.get("inventory").get(Rules.item_for(id), 0)) != 1:
            _fail("purchased item lost after loading game: " + id)
            return
    hub.set("world_minutes", 1750.0)
    stores.call("_update_workers")
    if not stores.get_node("V066Shop_lebells/V066StoreStaff_lebells").visible:
        _fail("diner fails to open just after midnight on next day")
        return
    if Rules.stock_for("lebells", 2, hub.get("shop_stock_v066")) <= 0:
        _fail("new-day restaurant supply never refreshes")
        return
    print("V0.66 THREE PHYSICAL PUBLISHED BUSINESSES THIRTY-SEVEN SCHEDULED NPCS VERIFIED PURCHASES AND RELOAD PASS")
    scene.queue_free()
    get_tree().call_deferred("quit", 0)
