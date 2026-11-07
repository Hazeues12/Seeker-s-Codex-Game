extends Node3D
const Main = preload("res://scenes/main.tscn")
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const Rig = preload("res://characters/procedural_seeker.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("V0.82 ANIME WORLD: " + reason)
    get_tree().call_deferred("quit", 1)

func _run() -> void:
    var game := Main.instantiate() as Node3D
    add_child(game)
    for frame in range(8):
        await get_tree().process_frame
    var player := game.get_node("Player") as CharacterBody3D
    var rig := player.get_node("AnimatedSeeker") as Rig
    var head := rig.body_root.get_node("Head") as MeshInstance3D
    var face := head.material_override as ShaderMaterial
    if not head.mesh is ArrayMesh or face == null or not face.get_shader_parameter("face_lighting") or face.next_pass == null:
        _fail("live player is missing its face ramp or hull")
        return
    if not rig.torso_mesh.mesh is CapsuleMesh or not rig.left_sleeve.mesh is CapsuleMesh:
        _fail("player still uses a box torso or sleeve")
        return
    rig.apply_player_appearance(2, 3, 2, 1)
    if rig.body_root.get_node("AnimeLocks").visible \
            or not (face.get_shader_parameter("base_color") as Color).is_equal_approx(Color(0.85, 0.65, 0.52)):
        _fail("creator hair or skin choice no longer reaches the live shader")
        return
    rig.apply_player_appearance(0, 0, 0, 0)
    rig.animate_state(0.09, 5.0)
    var held: float = rig.left_leg.rotation.x
    rig.animate_state(0.015, 5.0)
    if not is_equal_approx(held, rig.left_leg.rotation.x):
        _fail("locomotion pose moved between stepped samples")
        return
    rig.trigger_attack()
    rig.animate_state(0.001, 0.0)
    if not is_equal_approx(rig.right_arm.rotation.x, 1.35):
        _fail("attack presentation waited for the next pose sample")
        return
    player.call("_show_martial_pulse", Vector3.FORWARD)
    var stroke := game.get_node("MartialPulse") as MeshInstance3D
    if not stroke.mesh is ArrayMesh:
        _fail("Martial effect still uses a sphere")
        return

    var visuals := game.get_node("MagnaraPublishedRingVisualsV076")
    player.global_position = Vector3(Geo.CITY_CENTER.x + 3560.0, 0.76, Geo.CITY_CENTER.y)
    for tick in range(5):
        game.get_node("MagnaraGeographyV054").call("_refresh_cells")
        game.get_node("MagnaraSevenRingFoundationV074").call("_refresh_near")
    visuals.call("_refresh_tiles")
    var trees: Dictionary = visuals.get("decorated")
    var grove: MultiMeshInstance3D
    for entry in trees.values():
        grove = entry["root"].get_node_or_null("CommonsPaintedCanopyGPU") as MultiMeshInstance3D
        if grove != null:
            break
    if grove == null or not grove.material_override is ShaderMaterial or grove.multimesh.instance_count < 3:
        _fail("Commons trees did not receive batched painted canopy masses")
        return
    player.global_position = grove.to_global(grove.multimesh.get_instance_transform(0).origin) + Vector3(4, -4.4, 0)
    var camera := player.get_node("CameraPivot/Camera3D") as Camera3D
    camera.global_position = player.global_position + Vector3(2.9, 2.6, -3.9)
    camera.look_at(player.global_position + Vector3.UP * 1.32)
    for frame in range(12):
        await get_tree().process_frame
    print("V0.82 ANIME PLAYER FACE HULL POSE VFX AND PAINTED CANOPY PASS")
    if OS.has_feature("web"):
        await get_tree().create_timer(20.0).timeout
    game.queue_free()
    get_tree().call_deferred("quit", 0)
