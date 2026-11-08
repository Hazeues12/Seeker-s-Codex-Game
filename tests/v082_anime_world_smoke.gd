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
    var creator := game.get_node("SeekerCreator")
    (creator.get("outfit_option") as OptionButton).select(0)
    creator.call("_apply_preview")
    var sashes: OptionButton = creator.get("sash_option")
    sashes.select(2)
    creator.call("_save_appearance")
    sashes.select(0)
    creator.call("_load_appearance")
    creator.call("_apply_preview")
    var sash := rig.spoke_sash.material_override as ShaderMaterial
    if not rig.spoke_sash.visible or sash.get_shader_parameter("base_color") != Color("#3E7C8C"):
        _fail("the Elemental sash did not keep its exact tint after reload")
        return
    GameState.set_rank("Iron")
    if not rig.rank_cape.visible or not is_equal_approx(rig.rank_cape.scale.y, 0.62):
        _fail("Iron is missing its short cape")
        return
    GameState.set_rank("Gold")
    if not is_equal_approx(rig.rank_cape.scale.y, 1.38):
        _fail("Gold is missing its long cape")
        return
    GameState.set_rank("Stray")
    if rig.rank_cape.visible:
        _fail("Stray was given a licensed rank cape")
        return
    GameState.set_rank("Iron")
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
    rig.pose_clock = 0.0
    rig.last_pose = ""
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
    var foliage := grove.get_parent().get_node_or_null("CommonsPaintedFoliageGPU") as MultiMeshInstance3D
    if foliage == null or not foliage.material_override is ShaderMaterial \
            or foliage.multimesh.instance_count != grove.multimesh.instance_count * 11:
        _fail("Commons trees did not receive their painted foliage cards")
        return
    if foliage.multimesh.get_instance_color(0) != grove.multimesh.get_instance_color(0):
        _fail("Foliage card did not inherit its crown palette")
        return
    player.global_position = grove.to_global(grove.multimesh.get_instance_transform(0).origin) + Vector3(4, -4.4, 0)
    var camera := player.get_node("CameraPivot/Camera3D") as Camera3D
    camera.global_position = player.global_position + Vector3(2.9, 2.6, -3.9)
    camera.look_at(player.global_position + Vector3.UP * 1.32)
    for frame in range(12):
        await get_tree().process_frame
    var cart := visuals.get_node("CommonsCartV081")
    var life := visuals.get_node("CommonsLifeV080")
    var courtyard: Vector3 = cart.get("court")
    game.get_node("HubManager").set("world_minutes", 1140.0)
    player.global_position = courtyard + Vector3(0, 0.75, 3.0)
    for tick in range(5):
        game.get_node("MagnaraGeographyV054").call("_refresh_cells")
        game.get_node("MagnaraSevenRingFoundationV074").call("_refresh_near")
    visuals.call("_refresh_tiles")
    var vendor: TownspersonVisual = cart.get("vendor")
    var poet: TownspersonVisual = life.get("poet")
    var family: Array = life.get("family")
    if vendor == null or poet == null or family.size() != 3:
        _fail("Commons cast failed to stream at the evening courtyard")
        return
    for civilian in [vendor, poet] + family:
        if civilian.figure.skin == null or civilian.figure.material_override.shader != TownspersonVisual.CEL:
            _fail("Commons civilian lacks the painted skinned outfit")
            return
    if vendor.form != TownspersonVisual.Form.WOMAN or poet.form != TownspersonVisual.Form.MAN \
            or family[2].form != TownspersonVisual.Form.CHILD or family[2].pose != "sit":
        _fail("Commons residents lost their distinct models or seated pose")
        return
    var data: Dictionary = visuals.get("decorated")
    var layer: Node3D = data[Geo.cell_id(Geo.tile_index(courtyard))]["root"]
    var paving := layer.get_node("V076CommonsParkGroundGPU") as MultiMeshInstance3D
    if not paving.material_override is ShaderMaterial:
        _fail("Commons ground is missing its painted grass and paving")
        return
    var grass := layer.find_child("CommonsWindGrass*", true, false) as MultiMeshInstance3D
    if grass == null or grass.multimesh.instance_count <= 0 or grass.multimesh.instance_count > 150:
        _fail("Commons lawn is missing its bounded grass batch")
        return
    camera.global_position = courtyard + Vector3(9.0, 6.0, 10.5)
    camera.look_at(courtyard + Vector3(0, 0.85, -0.5))
    for frame in range(12):
        await get_tree().process_frame
    print("V0.82 ANIME PLAYER FACE HULL POSE VFX AND PAINTED CANOPY PASS")
    if OS.has_feature("web"):
        await get_tree().create_timer(20.0).timeout
    game.queue_free()
    get_tree().call_deferred("quit", 0)
