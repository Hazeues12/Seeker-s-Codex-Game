extends Node3D

const Main = preload("res://scenes/main.tscn")
const City = preload("res://world/magnara_city_v052.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("RING TWO CANAL: " + reason)
    get_tree().call_deferred("quit", 1)

func _walk(mobile: Control, direction: float, ticks: int) -> void:
    mobile.set("movement", Vector2(0, direction))
    for tick in range(ticks):
        await get_tree().physics_frame
    mobile.set("movement", Vector2.ZERO)

func _run() -> void:
    var game := Main.instantiate() as Node3D
    add_child(game)
    for frame in range(5):
        await get_tree().process_frame
    var player := game.get_node("Player") as CharacterBody3D
    var city := game.get_node("MagnaraCityV052")
    var hub := game.get_node("HubManager")
    var mobile := game.get_node("MobileUI/MobileControls") as Control
    var former_dry_position := Vector3(-72.0, 0.50, 47.5)
    player.global_position = former_dry_position
    player.velocity = Vector3.ZERO
    city._refresh_cells()
    await get_tree().physics_frame

    var water := city.find_child("BlueResonanceCanalSurface", true, false) as MeshInstance3D
    if water == null or not (water.material_override is ShaderMaterial):
        _fail("west canal has no animated current material")
        return
    for channel_x in [-72.0, -53.85]:
        var ray := PhysicsRayQueryParameters3D.create(Vector3(channel_x, 2, 47.5),
            Vector3(channel_x, -2, 47.5), 1, [player.get_rid()])
        var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
        if hit.is_empty() or not is_equal_approx(hit["position"].y, City.CANAL_BED_Y):
            _fail("terrain or pavement still fills the channel at x=" + str(channel_x) + " hit=" + str(hit))
            return
    var sample: Dictionary = city.get_water_surface_at(former_dry_position)
    if sample.is_empty() or sample["flow_velocity"].x <= 0.0 \
            or not city.get_water_surface_at(Vector3(-72.0, 0.50, 43.0)).is_empty():
        _fail("current fails to follow the channel or leaks onto its bank")
        return

    # A position saved back when the channel had flat ground remains usable.
    player.global_position = former_dry_position
    if not hub._save_game():
        _fail("could not create the old-position save")
        return
    player.global_position = Vector3.ZERO
    hub._load_game(false)
    if not player.global_position.is_equal_approx(former_dry_position):
        _fail("old position changed during load")
        return
    for tick in range(56):
        await get_tree().physics_frame
    if not bool(player.get("water_contact_v071")) or player.global_position.y <= City.CANAL_BED_Y:
        _fail("player did not float after loading over the channel: " + str(player.global_position))
        return

    var ramp_directions := {Vector2(-99.0, 47.0): -1.0, Vector2(-77.0, 47.9): 1.0}
    for entry: Vector2 in ramp_directions:
        player.global_position = Vector3(entry.x, City.CANAL_WATER_Y, entry.y)
        player.velocity = Vector3.ZERO
        await _walk(mobile, ramp_directions[entry], 110)
        if not player.is_on_floor() or bool(player.get("water_contact_v071")) or player.global_position.y < 0.48:
            _fail("player could not walk out at the canal ramp: " + str(player.global_position))
            return

    # The joystick crosses one bridge in each direction with no jump input.
    player.global_position = Vector3(-88.0, 0.80, 43.2)
    player.velocity = Vector3.ZERO
    await _walk(mobile, 1.0, 132)
    if player.global_position.z <= 52.8 or not player.is_on_floor():
        _fail("west footbridge is not walkable from the quay: " + str(player.global_position))
        return
    player.global_position = Vector3(-62.0, 0.55, 53.2)
    player.velocity = Vector3.ZERO
    await _walk(mobile, -1.0, 132)
    if player.global_position.z >= 43.8 or not player.is_on_floor():
        _fail("east footbridge is not walkable from the far bank: " + str(player.global_position))
        return

    player.global_position = Vector3(250, 1, 250)
    city._refresh_cells()
    await get_tree().process_frame
    if is_instance_valid(water) or not city.get_water_surface_at(former_dry_position).is_empty():
        _fail("canal visuals or physics stayed active after its ward unloaded")
        return
    print("V0.77 RING TWO CURRENT TWO WALKABLE BRIDGES SAFE CANAL EXITS AND OLD SAVES PASS")
    game.queue_free()
    get_tree().call_deferred("quit", 0)
