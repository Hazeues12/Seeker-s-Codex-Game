extends Node3D
const Main = preload("res://scenes/main.tscn")
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const CityRules = preload("res://systems/magnara_seven_ring_rules_v074.gd")
const Detail = preload("res://systems/magnara_streetscape_rules_v075.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("V0.75 LIVE 26KM MAGNARA STREETSCAPES FAILED: "+message)
    get_tree().call_deferred("quit",1)

func _run() -> void:
    var game: Node3D = Main.instantiate() as Node3D
    add_child(game)
    for i in range(8):
        await get_tree().process_frame
    var player: CharacterBody3D = game.get_node_or_null("Player") as CharacterBody3D
    var geography: Node = game.get_node_or_null("MagnaraGeographyV054")
    var city: Node = game.get_node_or_null("MagnaraSevenRingFoundationV074")
    var streets: Node = game.get_node_or_null("MagnaraStreetscapeV075")
    var hub: Node = game.get_node_or_null("HubManager")
    if player == null or geography == null or city == null \
            or streets == null or hub == null:
        _fail("real game lost the 26 km geography, city frame or V0.75 road service")
        return
    for old in ["MagnaraRingTwo","MagnaraCityV052","MagnaraStreamedBlocksV067",
        "MagnaraExpandedWardsV071","MagnaraWardInteriorsV072",
        "MargerinaOceanCommerceV071","MagnaraLocalLogisticsV073",
        "MagnaraLegacyRoofwaysV069","MagnaraMovingCarrierV070"]:
        if game.get_node_or_null(old) == null:
            _fail("live city extension deleted published neighborhood or sea feature "+old)
            return
    if not bool(city.get("initialized")) or not bool(streets.get("initialized")) \
            or streets.get_manifest().get("radial_ring_crossings",-1) != 84:
        _fail("full city street detail didn't attach to the existing seven-ring city")
        return
    if game.get_node_or_null("MagnaraStreetscapeV075") == city:
        _fail("street decoration replaced the authoritative seven-ring generator")
        return
    var tested: Dictionary = {}
    var sample_radii: Array[float] = [
        520.0,1770.0,3520.0,5510.0,7620.0,9710.0,11840.0]
    for n in range(7):
        var ring: int = n+1
        var angle: float = 1.30 if ring == 2 else 0.0
        var radius: float = sample_radii[n]
        player.global_position = Vector3(
            Geo.CITY_CENTER.x+radius*cos(angle),1.6,
            Geo.CITY_CENTER.y+radius*sin(angle))
        player.velocity = Vector3.ZERO
        for attempt in range(5):
            geography.call("_refresh_cells")
            city.call("_refresh_near")
        city.call("_refresh_collision")
        streets.call("_refresh_tiles")
        streets.call("_refresh_junctions")
        await get_tree().physics_frame
        var frame: Dictionary = city.call("get_manifest")
        var view: Dictionary = streets.call("get_manifest")
        if int(frame.get("current_ring",0)) != ring:
            city.call("_status")
            frame = city.call("get_manifest")
        if int(frame.get("current_ring",0)) != ring:
            _fail("live Ring %d lost its city atlas position" % ring)
            return
        if int(view.get("physically_loaded_near_tiles",0)) > 9 \
                or int(view.get("parent_city_loaded_near_tiles",0)) > 9 \
                or int(view.get("active_road_intersections",0)) > 5:
            _fail("Ring %d loaded too many physical streets or signs for iPhone" % ring)
            return
        if int(view.get("roof_crown_variants_visible",0)) < 35 \
                or int(view.get("facade_variants_visible",0)) < 70 \
                or int(view.get("local_street_segments_visible",0)) < 150:
            _fail("Ring %d still looks like four bare cubes, no dense local street fabric" % ring)
            return
        var chunks: Dictionary = city.get("near_tiles")
        var street_chunks: Dictionary = streets.get("styled_tiles")
        var visible_street: MeshInstance3D
        var roof: MultiMeshInstance3D
        var facade: MultiMeshInstance3D
        for key in street_chunks.keys():
            if not chunks.has(key):
                _fail("new streets retained a chunk that original V0.74 has unloaded")
                return
            var accent: Node3D = street_chunks[key]["root"]
            if not is_instance_valid(accent) \
                    or not accent.is_ancestor_of(chunks[key]["node"]) == false:
                _fail("street grid not parented to the matching original tile")
                return
            var road: MeshInstance3D = accent.get_node_or_null(
                "V075ContinuousInterBuildingStreetsGPU")
            if road != null and road.mesh != null:
                visible_street = road
            if roof == null:
                roof = accent.get_node_or_null(
                    "V075ProvisionalRoofCrownShapesGPU") as MultiMeshInstance3D
                facade = accent.get_node_or_null(
                    "V075ProvisionalFacadeReliefGPU") as MultiMeshInstance3D
        if visible_street == null or roof == null or facade == null \
                or roof.multimesh == null or facade.multimesh == null:
            _fail("ring %d exterior only tracks numbers but draws no local roads/architecture" % ring)
            return
        if roof.multimesh.instance_count > CityRules.PLOTS_PER_TILE \
                or facade.multimesh.instance_count > CityRules.PLOTS_PER_TILE*2:
            _fail("ring %d geometry exceeded bounded GPU tile instance budget" % ring)
            return
        if (visible_street.mesh as ArrayMesh).get_surface_count() < 1 \
                or (visible_street.mesh as ArrayMesh).surface_get_array_len(0) < 100:
            _fail("ring %d road grid only contains an empty placeholder" % ring)
            return
        tested[ring]=view["local_street_segments_visible"]
    if tested.size() != 7:
        _fail("not all seven zones have fully loaded city-scale street texture")
        return

    # One real radial/circular crossing is physically present. A marker
    # appears on foot and disappears when the player leaves that ring.
    var specific: Dictionary = Detail.junction(4,0)
    player.global_position = specific["world_pos"]+Vector3(0,1.60,0)
    for i in range(4):
        geography.call("_refresh_cells")
        city.call("_refresh_near")
    streets.call("_refresh_tiles")
    streets.call("_refresh_junctions")
    var crossings: Dictionary = streets.get("junction_nodes")
    if not crossings.has(specific["id"]) or crossings.size() > 5:
        _fail("real roadway intersection lacks its nearby ring/avenue street marker")
        return
    var sign_root: Node3D = crossings[specific["id"]]
    if not is_instance_valid(sign_root) \
            or sign_root.get_node_or_null("V075LocalRoadJunctionSurveySign") == null:
        _fail("major Ring IV avenue has no actual visible 3D wayfinding")
        return
    if sign_root.global_position.distance_to(specific["sign_world"]) > 0.01:
        _fail("survey sign doesn't align with actual ring/radial intersection")
        return

    var original: Vector3 = Vector3(0,1.0,70)
    player.global_position = original
    geography.call("_refresh_cells")
    for i in range(4):
        city.call("_refresh_near")
    streets.call("_refresh_tiles")
    streets.call("_refresh_junctions")
    var original_center: Vector2i = Geo.tile_index(original)
    var retained: Dictionary = streets.get("styled_tiles")
    if not retained.has(Geo.cell_id(original_center)):
        _fail("original Seeker Quarter tile is no longer under full seven-ring streamer")
        return
    var existing: Dictionary = retained[Geo.cell_id(original_center)]
    if int(existing["streets"]) != 0 or int(existing["rooflines"]) != 0:
        _fail("new speculative urban grid painted over original authored public quarter")
        return
    if not streets.get("junction_nodes").is_empty():
        _fail("remote 84 junction signs remain loaded while walking in original hub")
        return
    if not bool(hub.call("_save_game")) \
            or city.get_manifest().get("deepwater_main_port_ring",-1) != 7:
        _fail("existing character save or outermost Ring VII seaport was changed")
        return

    print("V0.75 LIVE ALL SEVEN 26KM RINGS LOCAL WALKABLE STREET FABRIC GPU ROOF VARIETY ROAD JUNCTION SIGNS ORIGINAL QUARTER AND SAVES PASS")
    game.queue_free()
    get_tree().call_deferred("quit",0)
