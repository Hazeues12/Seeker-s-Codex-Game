extends Node3D

const Main = preload("res://scenes/main.tscn")
const Rig = preload("res://characters/procedural_seeker.gd")
const Visual = preload("res://characters/shinobi_black_visual.gd")
const Creator = preload("res://ui/seeker_creator.gd")
const PASS := "V0.87 SHINOBI BLACK SKINNED AVATAR POSES AND APPEARANCE SAVE PASS"


func _ready() -> void:
    call_deferred("_run")


func _check(valid: bool, reason: String) -> bool:
    if not valid:
        push_error("V0.87 SHINOBI VISUAL: " + reason)
        get_tree().call_deferred("quit", 1)
    return valid


func _run() -> void:
    var game := Main.instantiate() as Node3D
    add_child(game)
    for frame in range(8):
        await get_tree().process_frame
    var player := game.get_node("Player") as CharacterBody3D
    var creator := game.get_node("SeekerCreator") as Creator
    var rig := player.get_node("AnimatedSeeker") as Rig
    var avatar := rig.shinobi_visual
    if not _check(creator.outfit_option.selected == 1 and avatar != null
            and avatar.is_visible_in_tree() and not rig.body_root.is_visible_in_tree(),
            "a fresh player spawned the legacy primitive rig"):
        return

    var meshes := avatar.find_children("*", "MeshInstance3D", true, false)
    if not _check(avatar.skeleton.get_bone_count() == 18 and meshes.size() == 3,
            "the imported costume did not mount its deforming mesh layers"):
        return
    for node in meshes:
        var mesh := node as MeshInstance3D
        if not _check(mesh.skin != null and mesh.mesh is ArrayMesh
                and mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR] is PackedColorArray,
                "a mesh layer is missing its skin or painted colors"):
            return
    avatar.set_outline_enabled(false)
    if not _check(avatar.costume_material.next_pass == null and avatar.is_visible_in_tree(),
            "the costume needs the outline pass to show its geometry"):
        return
    avatar.set_outline_enabled(true)
    var forearm := avatar.skeleton.find_bone("Forearm_R")
    var calf := avatar.skeleton.find_bone("Calf_R")
    rig.animate_state(0.10, 0.0)
    var idle_arm: Quaternion = avatar.skeleton.get_bone_pose_rotation(forearm)
    var idle_calf: Quaternion = avatar.skeleton.get_bone_pose_rotation(calf)
    rig.animate_state(0.10, 0.0, false, "guard")
    if not _check(not avatar.skeleton.get_bone_pose_rotation(forearm).is_equal_approx(idle_arm),
            "the new rig did not bend its elbow in guard"):
        return
    rig.animate_state(0.10, 0.0, false, "", true)
    if not _check(not avatar.skeleton.get_bone_pose_rotation(calf).is_equal_approx(idle_calf),
            "the new rig did not bend its knee in the air"):
        return
    rig.trigger_attack()
    rig.animate_state(0.0, 0.0)
    if not _check(rig.last_pose == "strike", "the hit pose missed the impact frame"):
        return

    creator.skin_option.select(1)
    creator._save_appearance()
    creator.outfit_option.select(0)
    creator._apply_preview()
    if not _check(rig.body_root.is_visible_in_tree() and not avatar.is_visible_in_tree(),
            "the existing Seeker Clothing option cannot be restored"):
        return
    creator._load_appearance()
    creator._apply_preview()
    var skin_tint: Vector3 = avatar.skin_material.get_shader_parameter("skin_tint")
    if not _check(creator.outfit_option.selected == 1 and avatar.is_visible_in_tree()
            and skin_tint.is_equal_approx(Visual.SKIN_TINTS[1]),
            "outfit and skin selection did not reload"):
        return
    var old_look := FileAccess.open(Creator.SAVE_FILE, FileAccess.WRITE)
    old_look.store_string('{"version":1,"name":"Legacy Seeker","coat":2,"hair":1,"skin":3}')
    old_look.close()
    creator._load_appearance()
    creator._apply_preview()
    if not _check(creator.outfit_option.selected == 0 and creator.coat_option.selected == 2
            and creator.hair_option.selected == 1 and rig.body_root.is_visible_in_tree(),
            "a pre-V0.87 appearance did not preserve its outfit and selections"):
        return

    if OS.has_feature("web"):
        game.queue_free()
        await get_tree().process_frame
        _render_turnaround()
        for frame in range(8):
            await get_tree().process_frame
    print(PASS)
    if OS.has_feature("web"):
        await get_tree().create_timer(18.0).timeout
    get_tree().call_deferred("quit", 0)


func _render_turnaround() -> void:
    var world := WorldEnvironment.new()
    world.environment = Environment.new()
    world.environment.background_mode = Environment.BG_COLOR
    world.environment.background_color = Color("#EBE7E0")
    add_child(world)
    for index in range(3):
        var figure := Visual.new()
        figure.position.x = 1.52 - 1.52 * index
        figure.rotation.y = [0.0, PI, -0.65][index]
        add_child(figure)
        figure.set_outline_enabled(index == 2)
        figure.present(0.0, 0.0, "guard" if index == 2 else "")
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 2.88
    camera.position = Vector3(0, 1.24, -6.5)
    add_child(camera)
    camera.look_at(Vector3(0, 1.25, 0))
    camera.make_current()
