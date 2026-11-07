extends Node3D
const Main = preload("res://scenes/main.tscn")
const Ward = preload("res://systems/magnara_expansion_rules_v071.gd")
const Interior = preload("res://systems/magnara_interiors_rules_v072.gd")
const Rules = preload("res://systems/magnara_local_logistics_rules_v073.gd")
const Integrity = preload("res://systems/game_save_integrity_v063.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("V0.73 REAL MAGNARA LOCAL TRADE AND HOUSEHOLDS FAILED: "+message)
    get_tree().call_deferred("quit",1)

func _run() -> void:
    var game: Node3D = Main.instantiate() as Node3D
    add_child(game)
    for n in range(6):
        await get_tree().process_frame
    var player: CharacterBody3D = game.get_node_or_null("Player") as CharacterBody3D
    var hub: Node = game.get_node_or_null("HubManager")
    var city: Node = game.get_node_or_null("MagnaraExpandedWardsV071")
    var interior: Node = game.get_node_or_null("MagnaraWardInteriorsV072")
    var trade: Node = game.get_node_or_null("MargerinaLandCommerceV071")
    var depot: Node = game.get_node_or_null("MagnaraLocalLogisticsV073")
    if player == null or hub == null or city == null or interior == null \
            or trade == null or depot == null:
        _fail("new freight system didn't mount in existing playable scene")
        return
    for name in ["MagnaraStreamedBlocksV067","MagnaraPopulationV065",
            "MagnaraBusinessesV066","PublicGuildDirectorV069",
            "MagnaraMovingCarrierV070","MargerinaOceanCommerceV071"]:
        if game.get_node_or_null(name) == null:
            _fail("V0.73 removed original city, trade or canon scene "+name)
            return
    if not bool(depot.get("initialized")) or depot.get_manifest().get(
            "daily_wagon_unload_capacity",0) != 3:
        _fail("public three-wagon depot didn't initialize after old road traffic")
        return
    var desk: Node3D = depot.get_node_or_null("V073WorkingPublicFreightDepot") as Node3D
    if desk == null or desk.get_node_or_null("V073CargoManifestDesk") == null:
        _fail("freight office is only a menu without a built physical depot")
        return
    var player_tola: int = GameState.tola
    hub.set("world_minutes",620.0)
    # The ledger counter is 7m south of the actual unloading berth.
    # Stay at the physical counter, not the wagon center.
    player.global_position = desk.global_position+Vector3(-3.2,0.84,0)
    var notice: Dictionary = hub.call("_nearest_location")
    if str(notice.get("id","")) != "logistics_v073_depot" \
            or not notice.has("title"):
        _fail("freight receipt office can't be opened with the iPhone TALK / USE")
        return
    hub.call("_interact")
    if not bool(depot.call("is_open")) or not bool(hub.call("_any_panel_open")):
        _fail("actual freight dock inspector UI doesn't open on mobile")
        return
    depot.call("_close")

    # First wagon physically crosses the known northern road endpoint.
    # Its pending consignment cannot be manufactured by opening a menu.
    var receipt: String = Rules.receipt_key(1,0)
    if hub.get("local_trade_v073")["pending"].has(receipt):
        _fail("public depot started a fake shipment before a wagon physically docked")
        return
    trade.set("seconds",110.0)
    trade.call("_physics_process",0.01)
    trade.set("seconds",112.0)
    trade.call("_physics_process",0.01)
    var ledger: Dictionary = Rules.clean(hub.get("local_trade_v073"))
    if not ledger["pending"].has(receipt):
        _fail("physical V0.71 north-bound wagon never triggered its local freight courier")
        return
    var workers: Dictionary = depot.get("couriers")
    if not workers.has(receipt):
        _fail("wagon changed stock ledger without spawning visible physical courier")
        return
    var carrier: AnimatableBody3D = workers[receipt]
    if carrier.get_node_or_null("V073CourierRealCollision") == null \
            or carrier.get_node_or_null("V073PhysicalCarriedCargo") == null:
        _fail("delivery worker lacks collision or physically carried cargo")
        return
    player.global_position = Rules.DOCK_AT
    depot.call("_process",0.18)
    if not carrier.visible or carrier.collision_layer != 1:
        _fail("nearby cargo courier isn't a real visible solid moving actor")
        return
    if ledger["receipts"].has(receipt):
        _fail("stock is credited before the real porter reaches a room")
        return
    if not bool(hub.call("_save_game")):
        _fail("the pending public freight parcel failed verified save")
        return
    var saved: Dictionary = Integrity.load_best().get("data",{})
    if not Rules.clean(saved.get("local_trade_v073",{}))["pending"].has(receipt):
        _fail("an interrupted on-road consignment isn't persisted in verified save")
        return
    hub.call("_load_game",false)
    depot.call("_sync_couriers")
    ledger = Rules.clean(hub.get("local_trade_v073"))
    if ledger["pending"].size() != 1 or not depot.get("couriers").has(receipt):
        _fail("saving and reopening restarted or duplicated the same courier")
        return

    # Move to the real destination in west Ring II. Check stock crates and
    # civic resident shifts while those physical cells are streamed nearby.
    var destination_cell := Vector2i(-1,5)
    var destination: Dictionary = Interior.site(destination_cell)
    player.global_position = destination["door_world"]+Vector3(0,0,2.2)
    for i in range(5):
        city.call("_refresh_chunks")
    city.call("_refresh_crowds")
    interior.call("_refresh")
    if not interior.get("sites").has("-1:5"):
        _fail("cargo destination did not create a real ground-floor workroom")
        return
    var workroom: Dictionary = interior.get("sites")["-1:5"]
    var stock_crates: Array = workroom["stock_crates"]
    var before_count: int = 0
    for crate in stock_crates:
        if (crate as MeshInstance3D).visible:
            before_count += 1
    if before_count != Rules.INITIAL_STOCK:
        _fail("physical store inventory was inflated before shipment delivery")
        return
    depot.call("_process",1.0)
    if Rules.stock(Rules.clean(hub.get("local_trade_v073")),destination_cell) != Rules.INITIAL_STOCK:
        _fail("small elapsed step falsely credited undelivered goods")
        return
    depot.call("_process",190.0)
    ledger = Rules.clean(hub.get("local_trade_v073"))
    if not ledger["receipts"].has(receipt) \
            or ledger["pending"].has(receipt) \
            or Rules.stock(ledger,destination_cell) != Rules.INITIAL_STOCK+Rules.DELIVERY_UNITS:
        _fail("finished 3D road courier did not deliver exactly four goods with one verified receipt")
        return
    interior.call("_refresh")
    var after_count: int = 0
    for crate in stock_crates:
        if (crate as MeshInstance3D).visible:
            after_count += 1
    if after_count != Rules.INITIAL_STOCK+Rules.DELIVERY_UNITS:
        _fail("new public stock did not produce six actual visible workroom crates")
        return
    if not depot.get("couriers").is_empty():
        _fail("a completed freight route was not unloaded from mobile scene budget")
        return
    if GameState.tola != player_tola:
        _fail("background local trade forged new player Tola")
        return
    if bool(depot.call("_register_wagon_dock",0,1)):
        _fail("wounded callback reissues an already completed wagon receipt")
        return
    if not bool(hub.call("_save_game")):
        _fail("verified save failed after actual physical freight arrival")
        return
    hub.call("_load_game",false)
    if Rules.stock(Rules.clean(hub.get("local_trade_v073")),destination_cell) != 6:
        _fail("closing and restoring game lost legitimate in-world delivered goods")
        return

    # After-hours local social visit uses resident #10's SAME profile and
    # suppresses the duplicate street model for that exact time window.
    hub.set("world_minutes",1110.0)
    player.global_position = destination["door_world"]+Vector3(0,0,1.5)
    city.call("_refresh_crowds")
    interior.call("_refresh")
    workroom = interior.get("sites")["-1:5"]
    var guest: Node3D = workroom["guest"]
    var staff: Node3D = workroom["staff"]
    var visitor: Dictionary = Rules.visitor(destination_cell,1110.0)
    if not guest.visible or staff.visible \
            or bool(Ward.resident_state(destination_cell,Rules.VISITOR_INDEX,1110.0)["visible"]):
        _fail("existing evening resident is duplicated outside or morning staff never leaves")
        return
    player.global_position = guest.global_position+Vector3(0,0,0.80)
    var neighbor: Dictionary = hub.call("_nearest_location")
    if str(neighbor.get("id","")) != "interior_v072_guest_-1:5" \
            or str(neighbor.get("title","")) != str(visitor["name"]):
        _fail("evening guest isn't a real addressable original resident")
        return
    hub.call("_interact")
    if not bool(interior.call("is_open")):
        _fail("evening household conversation doesn't open")
        return
    interior.call("_topic","Local Commerce")
    if not str(interior.get("story").text).contains("6 public goods units"):
        _fail("public indoor discussion doesn't report exact persisted actual cargo stock")
        return
    interior.call("_close")

    player.global_position = Vector3(0,1.0,0)
    city.call("_refresh_chunks")
    interior.call("_refresh")
    if int(interior.call("active_count")) != 0:
        _fail("V0.73 building stock and neighbor model stay loaded after leaving district")
        return
    if game.get_node_or_null("MargerinaOceanCommerceV071") == null:
        _fail("new local cargo loop destroyed older weather ocean and real ship features")
        return
    print("V0.73 LIVE WAGON TO ROAD COURIER REAL SIX CRATES SAVED ONCE DELIVERY EVENING FAMILY AND ORIGINAL OCEAN PASS")
    game.queue_free()
    get_tree().call_deferred("quit",0)
