extends Node3D
const Main = preload("res://scenes/main.tscn")
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const Rules = preload("res://systems/magnara_seven_ring_rules_v074.gd")
const Integrity = preload("res://systems/game_save_integrity_v063.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("V0.74 LIVE ALL SEVEN MAGNARA CITY RINGS FAILED: "+reason)
    get_tree().call_deferred("quit",1)

func _run() -> void:
    var game: Node3D = Main.instantiate() as Node3D
    add_child(game)
    for i in range(7):
        await get_tree().process_frame
    var player: CharacterBody3D = game.get_node_or_null("Player") as CharacterBody3D
    var hub: Node = game.get_node_or_null("HubManager")
    var city: Node = game.get_node_or_null("MagnaraSevenRingFoundationV074")
    var geo: Node = game.get_node_or_null("MagnaraGeographyV054")
    if player == null or hub == null or city == null or geo == null:
        _fail("full seven-ring framework not mounted with the original player, saves and 256m terrain")
        return
    for old in ["MagnaraRingTwo","MagnaraCityV052","MagnaraStreamedBlocksV067",
        "MagnaraExpandedWardsV071","MagnaraWardInteriorsV072",
        "MargerinaOceanCommerceV071","MagnaraLocalLogisticsV073",
        "MagnaraLegacyRoofwaysV069","MagnaraMovingCarrierV070"]:
        if game.get_node_or_null(old) == null:
            _fail("older physically authored Seeker Quarter or sea/trade system deleted: "+old)
            return
    if not bool(city.get("initialized")) or not is_instance_valid(city.get("ring_roads")):
        _fail("seven great circumferential roads and radial corridors did not render")
        return
    var road: MeshInstance3D = city.get("ring_roads")
    var annulus: ArrayMesh = road.mesh as ArrayMesh
    if annulus == null or annulus.get_surface_count() == 0 \
            or road.name != "V074AllSevenRingsAndTwelveRadialAvenues":
        _fail("world shows ring names in UI but has no 26km physical-scale road mesh")
        return
    if annulus.surface_get_array_len(0) < 7*Rules.CIRCUMFERENCE_SEGMENTS*6:
        _fail("seven ring arteries are too low resolution for a vast urban perimeter")
        return
    var map_panel: PanelContainer = city.get("map_panel")
    var chart: Control = city.get("map_control")
    if map_panel == null or chart == null or chart.get_script() == null:
        _fail("iPhone city map with all seven radial rings and live player position missing")
        return
    city.call("_toggle_map")
    if not bool(city.call("is_map_open")) or not bool(hub.call("_any_panel_open")) \
            or not str(city.get("map_label").text).contains("km"):
        _fail("touch ring map cannot pause normal game interaction or show scale")
        return
    city.call("_close_map")
    if bool(city.call("is_map_open")):
        _fail("open seven-ring map cannot be closed before walking")
        return
    var examined: Dictionary = {}
    var test_radii: Array[float] = [520.0,1770.0,3520.0,5510.0,
        7620.0,9710.0,11840.0]
    for n in range(7):
        var radius: float = test_radii[n]
        # Test Ring II away from the old authored x=0 physical hub.
        var angle: float = 1.30 if n == 1 else 0.00
        var at := Vector3(Geo.CITY_CENTER.x+radius*cos(angle),
            1.6,Geo.CITY_CENTER.y+radius*sin(angle))
        player.global_position = at
        player.velocity = Vector3.ZERO
        for count in range(5):
            geo.call("_refresh_cells")
            city.call("_refresh_near")
        city.call("_refresh_collision")
        city.call("_refresh_skyline",true)
        city.call("_status")
        await get_tree().physics_frame
        var ring: int = n+1
        var report: Dictionary = city.call("get_manifest")
        var geo_report: Dictionary = geo.call("get_manifest")
        if int(report.get("current_ring",0)) != ring \
                or int(geo.call("get_ring_at",at)) != ring:
            _fail("travel to actual Ring %d doesn't show its correct city zone" % ring)
            return
        if int(report.get("near_tiles_loaded",0)) > 9 \
                or int(geo.call("active_cell_count")) > 9 \
                or int(report.get("physically_active_near_walls",0)) > Rules.MAX_CLOSE_COLLIDERS:
            _fail("Ring %d exceeds bounded iPhone collision or tile budget" % ring)
            return
        if int(report.get("near_exterior_buildings",0)) < 40:
            _fail("Ring %d still looks like a few lonely V0.54 square boxes (%d)" % [
                ring,int(report.get("near_exterior_buildings",0))])
            return
        if int(report.get("far_skyline_gpu_buildings",0)) < 100:
            _fail("Ring %d skyline disappears just outside current 256m street" % ring)
            return
        if report.get("physical_ocean_docks_built",true) \
                or report.get("original_seeker_quarters_preserved",false) != true:
            _fail("Ring %d inserted unapproved coast, shops or displaced original Ring Two" % ring)
            return
        var chunks: Dictionary = city.get("near_tiles")
        var found_building: StaticBody3D
        for key in chunks.keys():
            var generated: Dictionary = chunks[key]
            if generated["sites"].size() > 0 and not generated["colliders"].is_empty():
                found_building = generated["colliders"].values()[0] as StaticBody3D
                break
        if not is_instance_valid(found_building):
            _fail("Ring %d has painted buildings but no physical nearby wall" % ring)
            return
        var origin: Vector3 = found_building.global_position
        var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
            origin+Vector3(0,10.0,0),origin+Vector3(0,-10.0,0))
        ray.exclude = [player.get_rid()]
        var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
        if hit.is_empty() or hit.get("collider") != found_building:
            _fail("Ring %d generated building wall has no actual collider" % ring)
            return
        if not Geo.safe_city_save(at):
            _fail("Ring %d is visually drawn but cannot be saved/explored" % ring)
            return
        examined[ring] = {
            "near_buildings":report["near_exterior_buildings"],
            "far_gpu_buildings":report["far_skyline_gpu_buildings"]}
    if examined.size() != 7:
        _fail("could not reach some parts of the 26km seven-ring city")
        return
    # Test a preserved public Seeker Quarter and the original world HUD.
    player.global_position = Vector3(0,1.0,70)
    geo.call("_refresh_cells")
    city.call("_refresh_near")
    city.call("_status")
    if city.call("get_manifest").get("current_ring",0) != 2 \
            or game.get_node_or_null("MagnaraWardInteriorsV072") == null:
        _fail("Ring II restored to wrong place / published venues removed")
        return
    if not bool(hub.call("_save_game")):
        _fail("the existing verified save failed after full-city ring travel")
        return
    var saved: Dictionary = Integrity.load_best().get("data",{})
    var pos: Array = saved.get("position",[])
    if pos.size() != 3 or absf(float(pos[0])) > 3.0:
        _fail("original character position corrupted by the global ring map")
        return
    print("V0.74 LIVE SEVEN TRAVERSABLE MAGNARA RINGS 26KM CITY ALL 12 AVENUES DENSE GPU BLOCKS PHYSICS 2KM SKYLINE IPHONE MAP AND OLD SAVE PASS")
    game.queue_free()
    get_tree().call_deferred("quit",0)
