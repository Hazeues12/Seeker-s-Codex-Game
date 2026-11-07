extends Node3D
const Main = preload("res://scenes/main.tscn")
const Port = preload("res://systems/magnara_port_geography_v0731.gd")
const Trade = preload("res://systems/margerina_commerce_rules_v071.gd")
const Ocean = preload("res://world/margerina_ocean_commerce_v071.gd")
const Freight = preload("res://systems/magnara_local_logistics_rules_v073.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("V0.73.1 MAGNARA OUTER RING PORT CANON TEST FAILED: "+reason)
    get_tree().call_deferred("quit",1)

func _json(path: String) -> Dictionary:
    var file := FileAccess.open(path,FileAccess.READ)
    if file == null:
        return {}
    var value: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    return value if typeof(value) == TYPE_DICTIONARY else {}

func _run() -> void:
    var atlas: Dictionary = _json("res://data/magnara_atlas_v052.json")
    var water: Dictionary = Trade.registry()
    if atlas.is_empty() or not Port.validate_atlas(atlas,water) \
            or not Trade.valid_registry(water):
        _fail("atlas or commerce registry did not accept author-confirmed Ring VII main seaport and minor Ring II canals")
        return
    if int(atlas.get("ring_count",-1)) != 7 or Port.MAJOR_SEAPORT_RING != 7 \
            or Port.RING_TWO != 2:
        _fail("Magnara is not the correct seven-ring city")
        return
    if not Port.can_berth(7,"major_seaport","large") \
            or not Port.can_berth(7,"major_seaport","medium") \
            or not Port.can_berth(7,"major_seaport","small"):
        _fail("main ocean shipping has no authorized outer-ring seaport")
        return
    if Port.can_berth(2,"major_seaport","large") \
            or Port.can_berth(2,"major_seaport","small") \
            or Port.can_berth(2,"minor_canal_quay","large") \
            or not Port.can_berth(2,"minor_canal_quay",Port.CANAL_VESSEL):
        _fail("Ring II incorrectly contains deepwater harbor or rejects small local canal skiffs")
        return
    if not Port.is_inland_freight(2,"road_wagon_depot") \
            or Port.is_inland_freight(7,"road_wagon_depot") \
            or Port.allowed_inter_ring_leg(2,7,"preview_only"):
        _fail("inland depot or simulated survey was mistaken for an actual port crossing")
        return
    if Port.source_status().get("ring_two_to_outer_port_navigable_canal_mapped",true):
        _fail("unconfirmed continuous sea-capable canal falsely invented")
        return
    var fake: Dictionary = water.duplicate(true)
    fake["harbors"][0]["ring"] = 2
    if Trade.valid_registry(fake) or Port.validate_atlas(atlas,fake):
        _fail("commerce engine allows major port in Ring II after canon change")
        return
    var fake_canal: Dictionary = water.duplicate(true)
    fake_canal["local_canals"]["ocean_vessels_allowed"] = true
    if Trade.valid_registry(fake_canal) or Port.validate_atlas(atlas,fake_canal):
        _fail("existing canal quays accidentally support seagoing freighters")
        return
    for i in range(Trade.SHIP_COUNT):
        var manifest: Dictionary = Trade.ship_manifest(i,1,water)
        if manifest.get("major_seaport_ring",-1) != 7 \
                or bool(manifest.get("ring_two_ocean_dock",true)):
            _fail("seagoing vessel manifested to wrong ring")
            return
    if Freight.INLAND_DEPOT_AT != Freight.DOCK_AT \
            or Freight.INLAND_FREIGHT_ARRIVAL_Z != Freight.DOCK_TRIGGER_Z \
            or Freight.delivery(1,1).get("source_ring",0) != 2 \
            or bool(Freight.delivery(1,1).get("maritime_port",true)):
        _fail("old depot wrongly reclassified as maritime berth or save coordinate moved")
        return

    var game: Node3D = Main.instantiate() as Node3D
    add_child(game)
    for i in range(6):
        await get_tree().process_frame
    var player: CharacterBody3D = game.get_node_or_null("Player") as CharacterBody3D
    var hub: Node = game.get_node_or_null("HubManager")
    var maritime: Node = game.get_node_or_null("MargerinaOceanCommerceV071")
    var land: Node = game.get_node_or_null("MargerinaLandCommerceV071")
    var inland: Node = game.get_node_or_null("MagnaraLocalLogisticsV073")
    if player == null or hub == null or maritime == null or land == null or inland == null:
        _fail("Magnara loses city, actual freight or playable sea survey after ring correction")
        return
    if maritime.get_manifest().get("actual_harbor_ring",-1) != 7 \
            or maritime.get_manifest().get("survey_counter_ring",-1) != 2 \
            or bool(maritime.get_manifest().get("ring_two_has_major_ocean_berth",true)) \
            or bool(maritime.call("is_active")):
        _fail("Ring II physically loads ocean-going harbor or survey mislabels ring")
        return
    if bool(land.get_manifest().get("deepwater_docks_here",true)) \
            or land.get_manifest().get("street_transfers_ring",0) != 2 \
            or inland.get_manifest().get("maritime_dock",true) \
            or inland.get_manifest().get("inland_ring",0) != 2:
        _fail("Ring II land freight stockyard is still labeled a sea dock")
        return
    player.global_position = Ocean.PUBLIC_ENTRY-Vector3(2.4,0,0)
    var nearest: Dictionary = hub.call("_nearest_location")
    if str(nearest.get("id","")) != "ocean_v071_board" \
            or not str(nearest.get("title","")).contains("Ring VII"):
        _fail("existing Ring II scenic link does not explain outermost ring destination")
        return
    hub.call("_interact")
    if not bool(maritime.call("is_open")):
        _fail("survey counter no longer opens from working city controls")
        return
    var details: Label = maritime.get("details")
    if details == null or not details.text.contains("Ring II desk") \
            or not details.text.contains("Ring VII") \
            or not details.text.contains("minor canal"):
        _fail("user-visible survey still makes main port look physically inside Ring II")
        return
    maritime.call("_close")
    print("V0.73.1 OUTERMOST RING VII SEA PORT RING II LOCAL CANAL ONLY INLAND FREIGHT AND REMOTE SURVEY CANON PASS")
    game.queue_free()
    get_tree().call_deferred("quit",0)
