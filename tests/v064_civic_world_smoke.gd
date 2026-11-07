extends Node3D
const Main = preload("res://scenes/main.tscn")
const Rules = preload("res://systems/magnara_civic_rules_v064.gd")
const SaveIntegrity = preload("res://systems/game_save_integrity_v063.gd")

func _ready() -> void:
    call_deferred("_test")

func _fail(reason: String) -> void:
    push_error("V0.64 PHYSICAL CIVIC WORLD FAILED: " + reason)
    get_tree().call_deferred("quit", 1)

func _test() -> void:
    var scene: Node3D = Main.instantiate() as Node3D
    add_child(scene)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    var civic: Node = scene.get_node_or_null("MagnaraCivicV064")
    var hub: Node = scene.get_node_or_null("HubManager")
    var codex: Node = scene.get_node_or_null("PersonalCodex")
    var player: CharacterBody3D = scene.get_node_or_null("Player") as CharacterBody3D
    var market: Node = scene.get_node_or_null("MagnaraMarketsV062")
    var shops: Node = scene.get_node_or_null("MagnaraWorkshopsV061")
    var homes: Node = scene.get_node_or_null("MagnaraResidentialV060")
    if civic == null or hub == null or codex == null or player == null or market == null or shops == null or homes == null:
        _fail("new district detached old character or previous working neighborhoods")
        return
    if not bool(civic.get("initialized")):
        _fail("physical civic district was not actually built")
        return
    var manifest: Dictionary = civic.call("get_manifest")
    if int(manifest.get("civic_buildings", 0)) != 3 or int(manifest.get("ring", 0)) != 2 or str(manifest.get("source_status", "")) != "game_only":
        _fail("missing three actual game-only buildings or correct Ring Two boundary")
        return
    var services: Array[String] = ["inn", "records", "clinic"]
    for key in services:
        var house: Node = civic.get_node_or_null("CivicV064Building_" + key)
        if house == null:
            _fail("missing physical enterable service building " + key)
            return
        for name in ["CivicV064InteriorFloor", "CivicV064OpenDoorLintel", "CivicV064SolidRoof", "CivicV064ServiceCounter"]:
            var piece: Node = house.find_child(name, true, false)
            if piece == null or piece.find_child("CivicV064WorldCollision", true, false) == null:
                _fail("building lacks actual collision/interior/door: " + key + " / " + name)
                return
        var employee: Node = house.find_child("CivicV064Staff_" + key, true, false)
        if employee == null:
            _fail("service building has no real staff model " + key)
            return
    if civic.get_node("CivicV064Building_inn").find_child("CivicV064GuestBed", true, false) == null:
        _fail("booked room is a fake exterior")
        return
    if civic.get_node("CivicV064Building_clinic").find_child("CivicV064RecoveryCot", true, false) == null:
        _fail("clinic has no recovery interior")
        return
    for name in ["CivicV064NorthStreet", "CivicV064CrossAvenue", "CivicV064DoorwayPavement_inn", "CivicV064DoorwayPavement_records", "CivicV064DoorwayPavement_clinic"]:
        var ground: Node = civic.find_child(name, true, false)
        if ground == null or ground.find_child("CivicV064WorldCollision", true, false) == null:
            _fail("civic road or access pavement isn't physically collidable: " + name)
            return
    await get_tree().physics_frame
    for at in [Vector3(0, 6, 374), Vector3(-62, 6, 398), Vector3(0, 6, 423), Vector3(62, 6, 480), Vector3(0, 6, 503)]:
        var ray := PhysicsRayQueryParameters3D.create(at, at + Vector3(0, -10, 0))
        if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
            _fail("walkable Ring Two street missing actual collision at " + str(at))
            return
    var locations: Dictionary = {}
    for spot in hub.get("locations"):
        var id: String = str(spot.get("id", ""))
        if id.begins_with("civic_v064_"):
            locations[id] = spot
    if locations.size() != 3:
        _fail("all three physical service counters must support TALK / USE")
        return
    var initial_money: int = GameState.tola
    var old_stock: Dictionary = hub.get("market_stock_v062").duplicate(true)
    hub.set("world_minutes", 480.0)
    player.global_position = locations["civic_v064_inn"]["position"] + Vector3(0, 0.5, 0)
    if str(hub.call("_nearest_location").get("id", "")) != "civic_v064_inn":
        _fail("player cannot approach the actual inn desk")
        return
    hub.call("_interact")
    if not bool(civic.call("is_open")) or not bool(hub.call("_any_panel_open")):
        _fail("touch interface fails to open or freeze movement")
        return
    civic.call("_choose", "checkin")
    if GameState.tola != initial_money - Rules.NIGHT_COST:
        _fail("inn check-in did not pay its actual cost")
        return
    var after_booking: Dictionary = hub.get("civic_v064")
    if not Rules.has_receipt(after_booking, "nights", 1):
        _fail("paid room did not enter the saved live game")
        return
    civic.call("_choose", "checkin")
    if GameState.tola != initial_money - Rules.NIGHT_COST:
        _fail("room can be charged multiple times in one day")
        return
    hub.set("stamina", 23.0)
    hub.set("aura", 12.0)
    civic.call("_choose", "sleep")
    if absf(float(hub.get("world_minutes")) - 1800.0) > 0.1 or float(hub.get("stamina")) < 99.0 or float(hub.get("aura")) < 99.0:
        _fail("booked guest bed cannot deliver overnight restoration")
        return
    if not Rules.has_receipt(hub.get("civic_v064"), "slept", 1):
        _fail("overnight rest does not persist")
        return
    civic.call("_choose", "sleep")
    if absf(float(hub.get("world_minutes")) - 1800.0) > 0.1:
        _fail("paid overnight time skip can be duplicated")
        return
    civic.call("_close")
    hub.set("world_minutes", 2040.0)
    civic.call("_update_workers")
    if not civic.get_node("CivicV064Building_records/CivicV064Staff_records").visible:
        _fail("records clerk not on duty during office hours")
        return
    player.global_position = locations["civic_v064_records"]["position"] + Vector3(0, 0.5, 0)
    hub.call("_interact")
    if not bool(civic.call("is_open")):
        _fail("civic wayfinding counter is not interactable")
        return
    civic.call("_choose", "assist")
    if GameState.tola != initial_money - Rules.NIGHT_COST + Rules.CIVIC_HELP_PAY:
        _fail("daytime civic work did not pay the advertised Tola")
        return
    civic.call("_choose", "assist")
    if GameState.tola != initial_money - Rules.NIGHT_COST + Rules.CIVIC_HELP_PAY:
        _fail("public job payout can be farmed repeatedly")
        return
    civic.call("_close")
    player.global_position = locations["civic_v064_clinic"]["position"] + Vector3(0, 0.5, 0)
    hub.set("stamina", 9.0)
    hub.set("aura", 17.0)
    hub.call("_interact")
    if not bool(civic.call("is_open")):
        _fail("clinic interaction did not open")
        return
    civic.call("_choose", "treatment")
    if GameState.tola != initial_money - Rules.NIGHT_COST + Rules.CIVIC_HELP_PAY - Rules.CLINIC_COST:
        _fail("clinic recovery did not pay real currency")
        return
    if float(hub.get("stamina")) < 99 or float(hub.get("aura")) < 99:
        _fail("basic care did not change actual energy stats")
        return
    civic.call("_close")
    var expected_money: int = GameState.tola
    var expected_book: Dictionary = Rules.sanitize(hub.get("civic_v064"))
    var live: Dictionary = SaveIntegrity.load_best().get("data", {})
    if int(live.get("tola", -1)) != expected_money or Rules.sanitize(live.get("civic_v064", {})) != expected_book:
        _fail("actual Tola and civic receipts not committed in same verified save")
        return
    if hub.get("market_stock_v062") != old_stock:
        _fail("new public services mutated old market inventory records")
        return
    GameState.tola = 0
    hub.set("civic_v064", {})
    hub.call("_load_game", false)
    if GameState.tola != expected_money or Rules.sanitize(hub.get("civic_v064")) != expected_book:
        _fail("money and civic life choices cannot reload together")
        return
    hub.set("world_minutes", 2460.0)
    civic.call("_update_workers")
    if civic.get_node("CivicV064Building_records/CivicV064Staff_records").visible:
        _fail("records clerk never clocks off")
        return
    if not civic.get_node("CivicV064Building_inn/CivicV064Staff_inn").visible:
        _fail("24-hour inn counter deserted after office hours")
        return
    print("V0.64 THREE ENTERABLE CIVIC BUILDINGS INN CLINIC WORK AND PERSISTENT DAY CYCLE PASS")
    scene.queue_free()
    get_tree().call_deferred("quit", 0)
