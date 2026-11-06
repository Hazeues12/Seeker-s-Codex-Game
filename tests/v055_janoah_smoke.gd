extends Node3D

const Geo = preload("res://systems/known_world_geometry_v054.gd")
const Janoah = preload("res://world/janoah_approach_v055.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("V0.55 JANOAH TERRAIN TEST FAILED: " + reason)
    get_tree().call_deferred("quit", 1)

func _run() -> void:
    var atlas_handle := FileAccess.open("res://data/janoah_approach_v055.json", FileAccess.READ)
    if atlas_handle == null:
        _fail("missing corridor registry")
        return
    var atlas_data: Variant = JSON.parse_string(atlas_handle.get_as_text())
    atlas_handle.close()
    if typeof(atlas_data) != TYPE_DICTIONARY:
        _fail("corridor registry must be valid JSON")
        return
    var atlas: Dictionary = atlas_data
    var location: Dictionary = atlas.get("terrain", {})
    var root_scope: Dictionary = atlas.get("safety", {})
    if atlas.get("nation") != "Janoah" or atlas.get("canon_status") != "game_only_local_preview":
        _fail("landscape inadvertently marked as canonical terrain")
        return
    if int(location.get("total_length_m", -1)) != 6144 or int(location.get("corridor_width_m", -1)) != 768:
        _fail("wrong physical route scale")
        return
    if not bool(root_scope.get("no_abyssal_line_crossover", false)) or not bool(root_scope.get("unknown_capitals_still_unplaced", false)):
        _fail("unapproved nation placement or boundary")
        return
    var main_file := FileAccess.open("res://data/known_world_v054.json", FileAccess.READ)
    var master: Variant = JSON.parse_string(main_file.get_as_text())
    main_file.close()
    if typeof(master) != TYPE_DICTIONARY:
        _fail("known world cannot be parsed")
        return
    var linked_regions: Array = master.get("implemented_local_geographic_regions", [])
    if linked_regions.size() != 1 or str(linked_regions[0].get("nation", "")) != "Janoah":
        _fail("Janoah corridor is not registered as a local region")
        return
    for entry in master.get("settlements", []):
        if entry.get("geographic_coordinates", "missing") != null:
            _fail("unconfirmed continental settlement coordinates were introduced")
            return
    if Janoah.eligible_tile(Vector2i(44, 0)) or not Janoah.eligible_tile(Vector2i(45, -1)) or not Janoah.eligible_tile(Vector2i(68, 1)) or Janoah.eligible_tile(Vector2i(69, 0)):
        _fail("city/hinterland tile boundary mismatch")
        return
    if Janoah.eligible_tile(Vector2i(50, 2)) or Janoah.eligible_tile(Vector2i(50, -2)):
        _fail("wrong regional width")
        return
    if not Janoah.safe_approach_save(Vector3(11600.0, 3.0, 70.0)) or not Janoah.safe_approach_save(Vector3(17400.0, 8.0, 70.0)):
        _fail("real route positions cannot be saved")
        return
    if Janoah.safe_approach_save(Vector3(9000.0, 1.0, 70.0)) or Janoah.safe_approach_save(Vector3(18500.0, 1.0, 70.0)) or Janoah.safe_approach_save(Vector3(13000.0, 1.0, 700.0)):
        _fail("world save boundary overflows planned region")
        return
    if absf(Janoah.height_at(11392.0, 70.0) - 0.50) > 0.001 or absf(Janoah.height_at(11648.0, 70.0) - 0.50) > 0.001:
        _fail("highway no longer meets flat city exit")
        return
    if Janoah.height_at(13500.0, 170.0) <= 0.50:
        _fail("landscape has no actual elevation beyond paved route")
        return
    if Janoah.phase_for_tile(Vector2i(46, 0)) != "industrial_outskirts" or Janoah.phase_for_tile(Vector2i(53, 0)) != "farmed_countryside" or Janoah.phase_for_tile(Vector2i(62, 0)) != "rolling_interior_route":
        _fail("regional landscape variety not implemented")
        return
    var scene := Node3D.new()
    scene.name = "RegionalTerrainSmokeWorld"
    add_child(scene)
    var visitor := Node3D.new()
    visitor.name = "Player"
    visitor.position = Vector3(11370.0, 1.0, 70.0)
    scene.add_child(visitor)
    var janoah: Node3D = Janoah.new()
    scene.add_child(janoah)
    await get_tree().process_frame
    await get_tree().process_frame
    var metadata: Dictionary = janoah.call("get_manifest")
    if not bool(metadata.get("physical_heightfield", false)) or int(metadata.get("nearby_cell_cap", 0)) > 9:
        _fail("terrain geometry/cell-cap manifest inaccurate")
        return
    var active: Dictionary = janoah.get("cells")
    if not active.has("45:0") or active.size() > 9:
        _fail("city exit does not preload first rural corridor")
        return
    var first: Node3D = active["45:0"]
    for entity in ["JanoahRegionalTerrainSurface", "JanoahTerrainCollision", "JanoahThroughRoad", "FreightRail", "FreightSleeper"]:
        if first.find_child(entity, true, false) == null:
            _fail("actual regional geometry missing " + entity)
            return
    await get_tree().physics_frame
    var road_ray := PhysicsRayQueryParameters3D.create(Vector3(11520.0, 9.0, 70.0), Vector3(11520.0, -2.0, 70.0))
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(road_ray)
    if hit.is_empty():
        _fail("no real collision beneath the route")
        return
    visitor.position = Vector3(53.0 * 256.0, 1.0, 70.0)
    janoah.call("_refresh_cells")
    await get_tree().physics_frame
    active = janoah.get("cells")
    if active.size() != 9 or active.has("45:0") or not active.has("53:0"):
        _fail("country stream failed to load and unload at distance")
        return
    var field: Node3D = active["53:0"]
    if field.find_child("CultivatedStrip", true, false) == null:
        _fail("farm landscape stage missing")
        return
    visitor.position = Vector3(63.0 * 256.0, 1.0, 70.0)
    janoah.call("_refresh_cells")
    active = janoah.get("cells")
    if not active.has("63:0") or (active["63:0"] as Node3D).find_child("RoadsideStoneOutcrop", true, false) == null:
        _fail("rolling terrain stage missing")
        return
    if (active["63:0"] as Node3D).find_child("PublicWaystationPlatform", true, false) == null:
        _fail("scenic public roadside shelter is missing")
        return
    visitor.position = Vector3(69.0 * 256.0 + 1000.0, 1.0, 70.0)
    janoah.call("_refresh_cells")
    active = janoah.get("cells")
    if active.size() != 0:
        _fail("terrain remains loaded beyond the built region")
        return
    scene.queue_free()
    print("V0.55 PHYSICAL JANOAH APPROACH AND REGIONAL STREAMING PASS")
    get_tree().call_deferred("quit", 0)
