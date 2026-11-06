extends Node3D

# V0.55 validates an actual collision-backed road and landscape,
# the 256m city boundary, streamed region stages and saved coordinates.
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const Region = preload("res://world/janoah_approach_v055.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("V0.55 JANOAH APPROACH FAILURE: " + message)
    get_tree().call_deferred("quit", 1)

func _run() -> void:
    var f := FileAccess.open("res://data/janoah_approach_v055.json", FileAccess.READ)
    if f == null:
        _fail("region manifest missing")
        return
    var parsed: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        _fail("malformed region manifest")
        return
    var record: Dictionary = parsed
    var terrain: Dictionary = record.get("terrain", {})
    if int(terrain.get("total_length_m", 0)) != 6144 or int(terrain.get("tile_size_m", 0)) != 256:
        _fail("wrong corridor scale")
        return
    if str(record.get("canon_status", "")) != "game_only_local_preview":
        _fail("provisional region misidentified as established lore")
        return
    if not bool(record.get("safety", {}).get("no_unverified_nation_borders", false)):
        _fail("unapproved international border added")
        return
    if not Region.eligible_tile(Vector2i(45, 0)) or not Region.eligible_tile(Vector2i(68, 1)):
        _fail("corridor endpoint tile excluded")
        return
    if Region.eligible_tile(Vector2i(44, 0)) or Region.eligible_tile(Vector2i(69, 0)) or Region.eligible_tile(Vector2i(48, 2)):
        _fail("landscape streamed outside provisional corridor")
        return
    if Region.phase_for_tile(Vector2i(47, 0)) != "industrial_outskirts" \
        or Region.phase_for_tile(Vector2i(53, 0)) != "farmed_countryside" \
        or Region.phase_for_tile(Vector2i(61, 0)) != "rolling_interior_route":
        _fail("regional land-use stages not differentiated")
        return
    if not Region.safe_approach_save(Vector3(11520.0, 1.0, 70.0)) \
        or not Region.safe_approach_save(Vector3(17535.0, 2.0, 70.0)) \
        or Region.safe_approach_save(Vector3(11000.0, 1.0, 70.0)) \
        or Region.safe_approach_save(Vector3(19000.0, 1.0, 70.0)) \
        or Region.safe_approach_save(Vector3(12000.0, 100.0, 70.0)):
        _fail("unsafe save limits or missing regional saves")
        return
    if Geo.tile_index(Vector3(11392.0, 1.0, 70.0)).x != 45:
        _fail("city-to-Janoah streaming border does not align to 256m tiles")
        return
    for seam in [11392.0, 12544.0, 14464.0, 16384.0, 17520.0]:
        if absf(Region.height_at(seam, 70.0) - 0.50) > 0.02:
            _fail("main trade road lifts off flat route at " + str(seam))
            return
    if Region.height_at(13000.0, 180.0) <= Region.height_at(13000.0, 70.0):
        _fail("country terrain is a perfectly flat road-plane")
        return

    var world := Node3D.new()
    world.name = "RegionalWorldSmoke"
    add_child(world)
    var player := Node3D.new()
    player.name = "Player"
    player.position = Vector3(11520.0, 1.0, 70.0)
    world.add_child(player)
    var region: Node3D = Region.new()
    world.add_child(region)
    await get_tree().process_frame
    await get_tree().physics_frame
    var manifest: Dictionary = region.call("get_manifest")
    if manifest.get("region") != "Janoah / Magnara approach" or int(manifest.get("nearby_cell_cap", 0)) != 9:
        _fail("region display manifest invalid")
        return
    var seen_phases: Dictionary = {}
    for tile_x in [45, 48, 53, 55, 61, 63, 68]:
        player.position = Geo.tile_center(Vector2i(tile_x, 0)) + Vector3.UP
        region.call("_refresh_cells")
        await get_tree().physics_frame
        var loaded: Dictionary = region.get("cells")
        if loaded.size() < 4 or loaded.size() > 9 or not loaded.has("%d:0" % tile_x):
            _fail("nearby 3x3 streaming missing tile " + str(tile_x))
            return
        var cell: Node3D = loaded["%d:0" % tile_x]
        if cell.find_child("JanoahRegionalTerrainSurface", true, false) == null \
            or cell.find_child("JanoahTerrainCollision", true, false) == null \
            or cell.find_child("JanoahThroughRoad", true, false) == null \
            or cell.find_child("FreightRail", true, false) == null:
            _fail("real terrain, road or freight structures missing at " + str(tile_x))
            return
        var collision: CollisionShape3D = cell.find_child("CollisionShape3D", true, false) as CollisionShape3D
        if collision == null or not (collision.shape is ConcavePolygonShape3D):
            _fail("collision terrain is not a triangle heightfield at " + str(tile_x))
            return
        var ray := PhysicsRayQueryParameters3D.create(
            player.position + Vector3(0.0, 6.0, 0.0),
            player.position + Vector3(0.0, -3.0, 0.0))
        var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
        if hit.is_empty():
            _fail("player could fall through Janoah terrain at " + str(tile_x))
            return
        seen_phases[Region.phase_for_tile(Vector2i(tile_x, 0))] = true
        if tile_x in [48, 55, 63]:
            if cell.find_child("PublicWaystationPlatform", true, false) == null \
                or cell.find_child("WaitingBench", true, false) == null:
                _fail("roadside waystation missing " + str(tile_x))
                return
        if tile_x == 61 and loaded.has("45:0"):
            _fail("distant regional tiles stayed resident in memory")
            return
    if seen_phases.size() != 3:
        _fail("approach landscape lacks three distinct stages")
        return
    player.position = Vector3(0.0, 1.0, 70.0)
    region.call("_refresh_cells")
    if region.call("active_cell_count") != 0:
        _fail("rural landscape did not unload on return to city")
        return
    world.queue_free()
    print("V0.55 COLLIDABLE JANOAH REGIONAL APPROACH AND STREAMING PASS")
    get_tree().call_deferred("quit", 0)
