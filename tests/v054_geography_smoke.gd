extends Node3D

const Geo = preload("res://systems/known_world_geometry_v054.gd")
const City = preload("res://world/magnara_geography_v054.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("V0.54 GEOGRAPHIC AUDIT FAILED: " + reason)
    get_tree().call_deferred("quit", 1)

func _run() -> void:
    var f := FileAccess.open("res://data/known_world_v054.json", FileAccess.READ)
    if f == null:
        _fail("missing known-world file")
        return
    var data: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    if typeof(data) != TYPE_DICTIONARY:
        _fail("invalid known-world registry JSON")
        return
    var regions: Array = data.get("nations", [])
    var towns: Array = data.get("settlements", [])
    var magnara: Dictionary = data.get("magnara", {})
    var rings: Array = magnara.get("ring_specs", [])
    if regions.size() != 13 or towns.size() != 19 or rings.size() != 7:
        _fail("nation, settlement or ring count changed")
        return
    var settlement_ids: Dictionary = {}
    for item in towns:
        var id: String = str(item["id"])
        if settlement_ids.has(id) or item["geographic_coordinates"] != null:
            _fail("duplicate or falsely geolocated city " + id)
            return
        settlement_ids[id] = true
        if str(item.get("dimension_status", "")) != "planning_only":
            _fail("proposed footprint marked as canon " + id)
            return
    var scope: Dictionary = data.get("scope", {})
    if not (scope.get("excluded", []) as Array).has("Zuba") or not (scope.get("boundary_unverified", []) as Array).has("Astraea"):
        _fail("Abyssal-line boundary policy missing")
        return
    var chain: Dictionary = data.get("routes", {})
    if not bool(chain.get("curan_island_no_invented_land_bridge", false)):
        _fail("Curan island crossing wrongly treated as a road")
        return
    for route in chain.get("edges", []):
        if route.get("route_length_km", "unset") != null or route.get("route_geometry", "unset") != null:
            _fail("unapproved exact international distance/coordinate")
            return
    if absf(Geo.circular_envelope_area_km2(26.0) - 530.929) > 0.15:
        _fail("Magnara planning envelope must be ~531 square kilometers")
        return
    var widths: Array[float] = [1000.0, 2600.0, 4700.0, 6500.0, 8700.0, 10700.0, 13000.0]
    for n in range(7):
        var target_m: float = widths[n]
        if absf(float(rings[n]["outer_radius_m"]) - target_m) > 0.01:
            _fail("incorrect ring boundary " + str(n + 1))
            return
        if Geo.ring_for_radius_m(target_m - 0.1) != n + 1:
            _fail("ring interior misclassified " + str(n + 1))
            return
        if Geo.ring_for_radius_m(target_m) != (n + 2 if n < 6 else 0):
            _fail("ring boundary misclassified " + str(n + 1))
            return
        if absf(Geo.ring_area_km2(n + 1) - float(rings[n]["envelope_area_km2_proposed"])) > 0.01:
            _fail("ring area mismatch " + str(n + 1))
            return
    if Geo.ring_for_position(Vector3(0.0, 1.0, 70.0)) != 2:
        _fail("existing Ring Two prototype no longer lives in Ring II")
        return
    if Geo.ring_for_position(Vector3(-1700.0, 1.0, 70.0)) != 1:
        _fail("Magnara center is not Ring I")
        return
    if Geo.safe_city_save(Vector3(15000.0, 1.0, 70.0)) or not Geo.safe_city_save(Vector3(10000.0, 1.0, 70.0)):
        _fail("city save bounds are not an honest proposed radius")
        return
    if Geo.tile_index(Vector3(0, 1, 70)) != Vector2i.ZERO or Geo.tile_index(Vector3(130, 1, 70)) != Vector2i(1, 0):
        _fail("one-meter terrain cell indexing")
        return
    var world := Node3D.new()
    world.name = "KnownWorldGeographyTest"
    add_child(world)
    var explorer := Node3D.new()
    explorer.name = "Player"
    explorer.position = Vector3(0.0, 1.0, 70.0)
    world.add_child(explorer)
    var geography: Node3D = City.new()
    world.add_child(geography)
    await get_tree().process_frame
    await get_tree().process_frame
    var report: Dictionary = geography.call("get_manifest")
    if report.get("city") != "Magnara" or int(report.get("city_diameter_m_proposed", 0)) != 26000:
        _fail("manifest missing 1:1 Magnara plan")
        return
    var cells: Dictionary = geography.get("cells")
    if cells.size() != 9 or not cells.has("0:0") or not cells.has("1:0"):
        _fail("legacy district and adjacent terrain cells not streamed")
        return
    var home: Node3D = cells["0:0"]
    var underlay: MeshInstance3D = home.find_child("OneToOneGround256m", true, false) as MeshInstance3D
    if not is_instance_valid(underlay) or underlay.visible:
        _fail("legacy city floor overwritten by streamed terrain")
        return
    var connector: Node = home.find_child("OldCityToGeographyStreetConnector", true, false)
    if connector == null:
        _fail("terrain streets do not connect to old Ring Two avenue")
        return
    explorer.position = Vector3(256.0, 1.0, 70.0)
    geography.call("_refresh_cells")
    await get_tree().physics_frame
    cells = geography.get("cells")
    var next: Node3D = cells.get("1:0", null)
    if not is_instance_valid(next) or next.find_child("OneToOneEastWestStreet", true, false) == null:
        _fail("new one-to-one physical street missing")
        return
    var probe := PhysicsRayQueryParameters3D.create(
        Vector3(256.0, 6.0, 70.0), Vector3(256.0, -2.0, 70.0))
    if get_world_3d().direct_space_state.intersect_ray(probe).is_empty():
        _fail("geographic ground has no physical collision")
        return
    explorer.position = Vector3(8000.0, 1.0, 70.0)
    geography.call("_refresh_cells")
    cells = geography.get("cells")
    if cells.size() > 9 or cells.size() < 4:
        _fail("large city keeps too much terrain in memory")
        return
    if geography.call("get_ring_at", explorer.position) != 6:
        _fail("maritime planning ring not placed at proposed distance")
        return
    explorer.position = Vector3(10000.0, 1.0, 70.0)
    geography.call("_refresh_cells")
    if geography.call("get_ring_at", explorer.position) != 7:
        _fail("outer ring mis-zoned")
        return
    cells = geography.get("cells")
    if cells.has("0:0") or cells.size() > 9:
        _fail("legacy tiles were not culled or active cap exceeded")
        return
    world.queue_free()
    print("V0.54 KNOWN WORLD ATLAS AND 1:1 MAGNARA GEOGRAPHY PASS")
    get_tree().call_deferred("quit", 0)
