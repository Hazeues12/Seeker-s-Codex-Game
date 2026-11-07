extends Node3D
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const Layout = preload("res://systems/magnara_seven_ring_rules_v074.gd")
const Port = preload("res://systems/magnara_port_geography_v0731.gd")

func _ready() -> void:
    call_deferred("_audit")

func _fail(message: String) -> void:
    push_error("V0.74 FULL MAGNARA SEVEN RING RULES FAILED: "+message)
    get_tree().call_deferred("quit",1)

func _load(path: String) -> Dictionary:
    var f := FileAccess.open(path,FileAccess.READ)
    if f == null:
        return {}
    var data: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    return data if typeof(data) == TYPE_DICTIONARY else {}

func _audit() -> void:
    var doc: Dictionary = _load("res://data/known_world_v054.json")
    var v052: Dictionary = _load("res://data/magnara_atlas_v052.json")
    var water: Dictionary = _load("res://data/margerina_water_commerce_registry_v071.json")
    if doc.is_empty() or v052.is_empty() or water.is_empty():
        _fail("missing geographic source")
        return
    var city: Dictionary = doc.get("magnara",{})
    var ring_specs: Array = city.get("ring_specs",[])
    var bounds: Array[float] = [1000.0,2600.0,4700.0,6500.0,8700.0,10700.0,13000.0]
    var envelope: float = Geo.circular_envelope_area_km2(26.0)
    var info: Dictionary = Layout.geometry_report()
    if ring_specs.size() != 7 or v052["rings"].size() != 7 \
            or absf(envelope-530.929) > 0.15 \
            or info.get("diameter_m",0) != 26000.0:
        _fail("all-ring 26 km playable masterplan wrong")
        return
    var sum_area: float = 0.0
    for ring in range(1,8):
        var bounds_info: Dictionary = Layout.bounds(ring)
        if absf(float(bounds_info["outer_m"])-bounds[ring-1]) > 0.01 \
                or absf(float(ring_specs[ring-1]["outer_radius_m"])-bounds[ring-1]) > 0.01 \
                or bounds_info["area_km2"] <= 0.0:
            _fail("ring %d has wrong outer boundary or non-traversable land area" % ring)
            return
        sum_area += float(bounds_info["area_km2"])
        var r: float = float(bounds_info["inner_m"])+0.5*(
            float(bounds_info["outer_m"])-float(bounds_info["inner_m"]))
        var p := Vector3(Geo.CITY_CENTER.x+r,0,Geo.CITY_CENTER.y)
        if Layout.ring_at(p) != ring or Layout.ring_title(ring).is_empty() \
                or not Geo.safe_city_save(p+Vector3.UP):
            _fail("ring %d cannot be explored or saved physically" % ring)
            return
        if Layout.ring_at(Vector3(Geo.CITY_CENTER.x+float(bounds_info["outer_m"]),
                0,Geo.CITY_CENTER.y)) != (ring+1 if ring < 7 else 0):
            _fail("ring edge is discontinuous")
            return
    if absf(sum_area-envelope) > 0.005:
        _fail("seven rings don't cover the whole 531 km² envelope")
        return
    if not Port.validate_atlas(v052,water) or info.get("deepwater_main_port_ring",0) != 7 \
            or ring_specs[5]["port_status"] != "not_the_primary_seaport" \
            or ring_specs[6]["id"] != "outer_maritime_port":
        _fail("Ring VI/ Ring VII seaport location correction regressed")
        return
    if str(v052.get("city_plan_status","")) != "v074_full_seven_ring_foundation_first":
        _fail("we are placing landmarks before completing whole city scaffold")
        return
    if Layout.RADIAL_COUNT != 12 or Layout.CIRCUMFERENCE_SEGMENTS < 160 \
            or Layout.MAX_NEAR_CELLS != 9 or Layout.MAX_CLOSE_COLLIDERS > 40 \
            or Layout.VIEWSHED_MAX < 1800.0 or Layout.PLOTS_PER_TILE < 48:
        _fail("city streets or local mobile renderer too sparse or over budget")
        return
    for angle_num in range(Layout.RADIAL_COUNT):
        var angle: float = Layout.radial_angle(angle_num)
        var at := Vector3(Geo.CITY_CENTER.x+3700*cos(angle),0,
            Geo.CITY_CENTER.y+3700*sin(angle))
        if Layout.radial_distance_to_road(at) > 0.5 \
                or Layout.buildable(at,11.0):
            _fail("radial highway blocked by a generated solid building")
            return
    for ring in range(1,8):
        var road_at := Vector3(Geo.CITY_CENTER.x+Geo.OUTER_BOUNDS_M[ring-1]-36.0,
            0,Geo.CITY_CENTER.y)
        if Layout.buildable(road_at,12.0):
            _fail("the actual circular highway corridor is obstructed by dense buildings")
            return
    var unique_lots: Dictionary = {}
    var populated_rings: Dictionary = {}
    var count: int = 0
    for ring in range(1,8):
        var center_radius: float = (float(Layout.bounds(ring)["inner_m"])+
            float(Layout.bounds(ring)["outer_m"]))*0.5
        var at := Vector3(Geo.CITY_CENTER.x+center_radius,0,Geo.CITY_CENTER.y)
        var center_tile: Vector2i = Geo.tile_index(at)
        var candidates: Array[Dictionary] = []
        for xo in range(-1,2):
            for zo in range(-1,2):
                candidates.append_array(Layout.tile_slots(center_tile+Vector2i(xo,zo)))
        var matched: int = 0
        for lot in candidates:
            if unique_lots.has(lot["id"]):
                _fail("unique urban building ID appears in two zones")
                return
            unique_lots[lot["id"]] = true
            if lot["ring"] == ring:
                matched += 1
            if lot["actual_interior"] or lot["actual_occupant"] \
                    or lot["purpose"] != "game_only_exterior_massing":
                _fail("placeholder city silhouette became a false complete building or NPC")
                return
            if not Layout.buildable(lot["world_pos"]):
                _fail("generated building blocks a circular/radial highway")
                return
            count += 1
        if matched < 70:
            _fail("Ring %d doesn't feel like a whole urban district: only %d generated parcels" % [ring,matched])
            return
        populated_rings[ring]=matched
    if count < 550 or populated_rings.size() != 7:
        _fail("city still has only sparse 4-block V0.54 massing")
        return
    if not Layout.protected_existing_ward(Vector3(0,0,980)) \
            or Layout.buildable(Vector3(0,0,980)) \
            or Layout.protected_existing_ward(Vector3(3000,0,980)):
        _fail("existing Ring II detailed interiors would be overwritten")
        return
    var far_at := Vector3(Geo.CITY_CENTER.x+5200.0,0,Geo.CITY_CENTER.y)
    var wanted: Array[Vector2i] = Layout.far_wanted(far_at)
    if wanted.size() < 8 or wanted.size() > 48:
        _fail("visible distant GPU city doesn't extend beyond 500m")
        return
    var skyline_lots: Array[Dictionary] = []
    for tile in wanted.slice(0,8):
        skyline_lots.append_array(Layout.far_specs(tile))
    if skyline_lots.size() < 100:
        _fail("distant city looks empty because no horizon silhouettes were generated")
        return
    if Layout.tile_slots(Vector2i(0,0)) != Layout.tile_slots(Vector2i(0,0)) \
            or Layout.far_specs(Vector2i(6,5)) != Layout.far_specs(Vector2i(6,5)):
        _fail("city changes identity or lot geometry between stream/load")
        return
    if Layout.ring_at(Vector3(30000,0,0)) != 0 \
            or not Layout.bounds(0).is_empty() \
            or Layout.buildable(Vector3(30000,0,0)):
        _fail("city construction leaked beyond 26km or into unmapped nations")
        return
    print("V0.74 ALL SEVEN RINGS PHYSICAL 26KM CITY 531KM2 DENSE URBAN PARCELS 12 RADIAL ROADS RING VII PORT CANON RULES PASS")
    get_tree().call_deferred("quit",0)
