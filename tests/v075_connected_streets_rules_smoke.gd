extends Node3D
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const City = preload("res://systems/magnara_seven_ring_rules_v074.gd")
const Streets = preload("res://systems/magnara_streetscape_rules_v075.gd")
const Port = preload("res://systems/magnara_port_geography_v0731.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("V0.75 ALL-RING STREET FABRIC RULES FAILED: "+reason)
    get_tree().call_deferred("quit",1)

func _run() -> void:
    var manifest: Dictionary = Streets.manifest()
    if manifest.get("radial_ring_crossings",0) != 84 \
            or manifest.get("radial_avenues",0) != City.RADIAL_COUNT \
            or manifest.get("seven_city_rings",0) != 7 \
            or manifest.get("physical_landmarks_placed",1) != 0 \
            or manifest.get("physical_port_docks_placed",1) != 0:
        _fail("city roads incorrectly change ring counts or create unapproved ports")
        return
    if Streets.MAX_JUNCTION_MARKERS > 5 \
            or Streets.MAX_NEAR_STREET_CHUNKS > 9 \
            or Streets.MAX_WINDOW_BAYS_PER_TILE > 128 \
            or Streets.STREET_LINES.size() != 11:
        _fail("unbounded nearby phone render budget")
        return
    var seen: Dictionary = {}
    for ring in range(1,8):
        for n in range(12):
            var j: Dictionary = Streets.junction(ring,n)
            if j.is_empty() or seen.has(j["id"]):
                _fail("missing or duplicated physical-scale road junction")
                return
            seen[j["id"]] = true
            var location: Vector3 = j["world_pos"]
            if City.ring_at(location) != ring or \
                    absf(Geo.radial_m(location)-(Geo.OUTER_BOUNDS_M[ring-1]-36.0)) > 0.01:
                _fail("ring-road and radial junction not aligned to actual built V0.74 road")
                return
            if City.radial_distance_to_road(location) > 0.1 \
                    or City.buildable(location,10.0) \
                    or not bool(j["no_canon_address"]):
                _fail("public ring/avenue junction obstructed by building or invented as named location")
                return
            if ring != 7 and bool(j["port_reserve_only"]):
                _fail("main ocean seaport assigned anywhere outside Ring VII")
                return
    if seen.size() != 84 or not Streets.junction(8,0).is_empty() \
            or not Streets.junction(1,12).is_empty() \
            or Port.MAJOR_SEAPORT_RING != 7:
        _fail("road junction or outermost port ring count wrong")
        return

    var distinct_styles: Dictionary = {}
    var tested: Dictionary = {}
    var total_roofs: int = 0
    var total_streets: int = 0
    for ring in range(1,8):
        var radius: float = (float(City.bounds(ring)["inner_m"]) + \
            float(City.bounds(ring)["outer_m"]))*0.5
        var center: Vector3 = Vector3(
            Geo.CITY_CENTER.x+radius,0.0,Geo.CITY_CENTER.y)
        var cell: Vector2i = Geo.tile_index(center)
        var candidates: Array[Vector2i] = [
            cell,cell+Vector2i(0,1),cell+Vector2i(-1,0)
        ]
        var floor_count: int = 0
        var roofs_in_ring: int = 0
        for tile in candidates:
            var streets: Array[Dictionary] = Streets.street_specs(tile)
            var roof: Array[Dictionary] = Streets.rooftops(tile)
            var facade: Array[Dictionary] = Streets.street_facades(tile)
            var lots: Array[Dictionary] = City.tile_slots(tile)
            if streets != Streets.street_specs(tile) \
                    or roof != Streets.rooftops(tile) \
                    or facade != Streets.street_facades(tile):
                _fail("civic exterior details change randomly after stream reload")
                return
            if roof.size() != lots.size() or facade.size() != lots.size()*2:
                _fail("roof crown or façade detail doesn't match exactly one base building")
                return
            if roof.size() > Streets.MAX_ROOF_CROWN_PER_TILE \
                    or facade.size() > Streets.MAX_WINDOW_BAYS_PER_TILE:
                _fail("ring decorations exceed mobile GPU instance caps")
                return
            for r in roof:
                distinct_styles[r["style"]] = true
                if r["size"].x < 2.0 or r["size"].y < 0.85 \
                        or not str(r["id"]).begins_with("mag_v074:"):
                    _fail("provisional roof doesn't follow real 3D block geometry")
                    return
            for lane in streets:
                if not Streets.allowed_segment(lane["world_pos"]) \
                        or not City.protected_existing_ward(lane["world_pos"]) == false:
                    _fail("fake neighborhood road overwrote legacy Seeker Quarter shops")
                    return
                if lane["axis"] not in ["north_south","east_west"] \
                        or not is_equal_approx(lane["half"],16.0):
                    _fail("local 32m walking routes are disconnected or wrongly oriented")
                    return
                floor_count += 1
            total_roofs += roof.size()
            total_streets += streets.size()
            roofs_in_ring += roof.size()
        if floor_count < 140 or roofs_in_ring < 100:
            _fail("Ring %d street grid is still too empty to look like a city" % ring)
            return
        tested[ring] = {"streets":floor_count,"roofline_forms":roofs_in_ring}
    if tested.size() != 7 or total_roofs < 800 or total_streets < 1200 \
            or distinct_styles.size() < 5:
        _fail("seven neighborhoods do not have sufficient long-scale varied urban texture")
        return

    # V0.33+ concrete player ward and all established shops must remain
    # exactly what they were before the city was expanded.
    if Streets.street_specs(Vector2i(0,0)).size() > 0 \
            or Streets.rooftops(Vector2i(0,0)).size() > 0:
        _fail("new procedural roads/rooflines overwrote the published Ring II hub")
        return
    var zrow_tile: Vector2i = Geo.tile_index(Vector3(0,0,1100))
    if not Streets.street_specs(zrow_tile).is_empty() \
            or Streets.rooftops(zrow_tile).size() > 0:
        _fail("new urban art overlays the original 3D Seeker Quarters roof parkour")
        return

    # Check 256m tile boundaries have roads with aligned shared endpoints.
    var tile := Vector2i(20,0)
    var east: Vector2i = tile+Vector2i(1,0)
    var north: Vector2i = tile+Vector2i(0,1)
    var test_x: Vector3 = Geo.tile_center(tile)+Vector3(128.0,0,14.0)
    var test_z: Vector3 = Geo.tile_center(tile)+Vector3(14.0,0,128.0)
    var near_x: Dictionary = Streets.local_road_to_grid(test_x)
    var near_z: Dictionary = Streets.local_road_to_grid(test_z)
    if near_x["near_north_south_lane"] > 0.1 \
            or near_z["near_east_west_lane"] > 0.1:
        _fail("neighboring 256m tile lane centerlines stop at tile edges")
        return
    if City.ring_at(Geo.tile_center(east)) == 0 \
            or City.ring_at(Geo.tile_center(north)) == 0:
        _fail("incorrect edge tiles used for valid ring-to-ring streets")
        return
    var near: Array[Dictionary] = Streets.junction_near(
        Streets.junction(4,0)["world_pos"])
    if near.is_empty() or near.size() > Streets.MAX_JUNCTION_MARKERS \
            or near[0]["id"] != Streets.junction(4,0)["id"]:
        _fail("roadway junction markers are not spatially streamed by proximity")
        return
    if City.geometry_report().get("deepwater_main_port_ring",-1) != 7:
        _fail("Ring VII seaport reserve altered by cosmetic city-scale development")
        return
    print("V0.75 ALL SEVEN RINGS LOCAL 28M STREET FABRIC 84 REAL AVENUE JUNCTIONS VARIED GPU ROOFS NO INVENTED LANDMARKS PASS")
    get_tree().call_deferred("quit",0)
