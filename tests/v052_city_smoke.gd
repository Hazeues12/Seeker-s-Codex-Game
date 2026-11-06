extends Node3D

# V0.52 world-first CI: instantiate the real streamed city and verify walkable
# collision geometry, interiors and cell load/unload. No player saves changed.
const CityScript = preload("res://world/magnara_city_v052.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("V0.52 WORLD GEOMETRY FAILED: " + reason)
    get_tree().call_deferred("quit", 1)

func _run() -> void:
    var world := Node3D.new()
    world.name = "MargerinaSmokeWorld"
    add_child(world)
    var explorer := Node3D.new()
    explorer.name = "Player"
    explorer.position = Vector3(0.0, 1.0, 50.0)
    world.add_child(explorer)
    var city: Node3D = CityScript.new()
    world.add_child(city)
    await get_tree().process_frame
    await get_tree().process_frame
    var manifest: Dictionary = city.call("get_manifest")
    if str(manifest.get("city", "")) != "Magnara" or str(manifest.get("district", "")).find("Ring Two") < 0:
        _fail("wrong city/district manifest")
        return
    if (manifest.get("streamed_cells", []) as Array).size() != 4:
        _fail("city requires four connected wards")
        return
    var checks: Dictionary = {
        "west_public": Vector3(-70.0, 1.1, 50.0),
        "west_professional": Vector3(-70.0, 1.1, 90.0),
        "east_public": Vector3(70.0, 1.1, 50.0),
        "east_professional": Vector3(70.0, 1.1, 90.0)
    }
    for key in checks:
        explorer.global_position = checks[key]
        city.call("_refresh_cells")
        var loaded: Dictionary = city.get("active_cells")
        if not loaded.has(key):
            _fail("missing streamed cell: " + str(key))
            return
        var cell: Node3D = loaded[key]
        var solids: Array[Node] = cell.find_children("*", "CollisionShape3D", true, false)
        var visuals: Array[Node] = cell.find_children("*", "MeshInstance3D", true, false)
        if solids.size() < 10 or visuals.size() < 65:
            _fail("ward is only a facade or has insufficient walkable geometry: " + str(key))
            return
        if key == "east_public" and cell.find_child("EnterablePublicRestHouse", true, false) == null:
            _fail("public interior absent")
            return
        if key == "west_professional" and cell.find_child("EnterableSeekerRecordsHall", true, false) == null:
            _fail("professional interior absent")
            return
        await get_tree().physics_frame
    explorer.global_position = Vector3(70.0, 1.1, 50.0)
    city.call("_refresh_cells")
    await get_tree().physics_frame
    # The public rest house front entrance is clear at humanoid torso height.
    # This guards against a fake painted doorway with full collision.
    var passage := PhysicsRayQueryParameters3D.create(
        Vector3(80.0, 1.6, 38.0), Vector3(87.0, 1.6, 38.0))
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(passage)
    if not hit.is_empty():
        _fail("rest-house door is physically blocked by " + str(hit.get("collider", "unknown")))
        return
    explorer.global_position = Vector3(-89.0, 1.1, 100.0)
    city.call("_refresh_cells")
    await get_tree().physics_frame
    var passage_west := PhysicsRayQueryParameters3D.create(
        Vector3(-79.0, 1.6, 101.0), Vector3(-89.0, 1.6, 101.0))
    hit = get_world_3d().direct_space_state.intersect_ray(passage_west)
    if not hit.is_empty():
        _fail("records-hall door is physically blocked")
        return
    var active: Dictionary = city.get("active_cells")
    if active.has("east_public") or not active.has("west_professional"):
        _fail("distant cells failed to unload or nearby cell failed to load")
        return
    world.queue_free()
    print("V0.52 MAGNARA CITY GEOMETRY AND INTERIORS PASS")
    get_tree().call_deferred("quit", 0)
