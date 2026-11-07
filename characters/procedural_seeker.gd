extends Node3D

# V0.37: asset-free, articulated low-poly Seeker and sparring fighter rig.
# Cosmetic only; collision, damage, Aura and movement stay in existing scripts.
const ANIME_SHADER = preload("res://shaders/seeker_anime_v082.gdshader")
const INK_SHADER = preload("res://shaders/seeker_ink_v082.gdshader")
const ShinobiVisual = preload("res://characters/shinobi_black_visual.gd")
const POSE_INTERVAL := 1.0 / 12.0
var anime_style := false
var pose_clock := 0.0
var last_pose := ""
var ink: ShaderMaterial
var anime_gem_scale: Vector3
var shoulder_drapes: Array[MeshInstance3D] = []
const SPOKE_CLOTH: Dictionary = {
    "Martial": Color("#B0512F"), "Elemental": Color("#3E7C8C"),
    "Spirit": Color("#6E8C5A"), "Psychic": Color("#7C5E9C"),
    "Spatial": Color("#4A6FA5"), "Alchemy": Color("#997A3D"),
    "Abyssal": Color("#8C3A4E"),
}
const RANK_TRIM: Dictionary = {
    "Iron": Color("#8995A1"), "Bronze": Color("#AC7249"),
    "Silver": Color("#C4D4EA"), "Gold": Color("#E5B752"),
    "Grand": Color("#E5B752"), "Sage": Color("#E5B752"),
}
var spoke_sash: MeshInstance3D
var rank_cape: MeshInstance3D
var cape_edge: MeshInstance3D
var shinobi_visual: ShinobiVisual
var appearance: String = "seeker"
var animation_time: float = 0.0
var attack_time: float = 0.0
var impact_time: float = 0.0
var body_root: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var torso_mesh: MeshInstance3D
var left_sleeve: MeshInstance3D
var right_sleeve: MeshInstance3D
var left_pant: MeshInstance3D
var right_pant: MeshInstance3D
var cape_trim: MeshInstance3D
var aura_gem: MeshInstance3D
var accent: Color = Color(0.30, 0.72, 0.98)
var national_nation: String = ""
var national_accessories: Node3D

func configure(look: String = "seeker") -> void:
    appearance = look
    if not is_instance_valid(body_root):
        _build_rig()
    _apply_colors()

func configure_civilian(jacket: Color, skin: Color) -> void:
    configure("civilian")
    _color_civilian(jacket, skin)

func _color_civilian(jacket: Color, skin: Color) -> void:
    _color_clothes(jacket, jacket.darkened(0.33))
    for part in [body_root.get_node("Head"), body_root.get_node("Neck"),
            left_arm.get_node("LeftGlove"), right_arm.get_node("RightGlove")]:
        _tint(part, skin)
    for part in [aura_gem, cape_trim, body_root.get_node("FaceBand"),
            left_arm.get_node("LeftTrim"), right_arm.get_node("RightTrim")]:
        part.hide()

func configure_anime_player() -> void:
    _configure_anime("seeker", 0)
    spoke_sash = _box(body_root, "SpokeSash", Vector3(0, 1.32, -0.234),
        Vector3(0.15, 0.77, 0.045), Color.WHITE)
    spoke_sash.rotation.z = 0.52
    spoke_sash.hide()
    rank_cape = _cloth_panel("RankCape", 0.0, 1.0, Color("#222945"))
    cape_edge = _cloth_panel("RankCapeTrim", 0.90, 1.0, Color.WHITE)
    GameState.rank_changed.connect(apply_rank_clothing)
    apply_rank_clothing(GameState.seeker_rank)

func apply_shinobi_outfit(enabled: bool) -> void:
    if enabled and shinobi_visual == null:
        shinobi_visual = ShinobiVisual.new()
        shinobi_visual.name = "ShinobiBlack"
        add_child(shinobi_visual)
    if shinobi_visual != null:
        shinobi_visual.visible = enabled
    body_root.visible = not enabled
    last_pose = "outfit_change"

func _cloth_panel(title: String, top: float, bottom: float, tint: Color) -> MeshInstance3D:
    var cloth := SurfaceTool.new()
    cloth.begin(Mesh.PRIMITIVE_TRIANGLES)
    var upper := Vector3(lerpf(0.32, 0.41, top), -top, 0.24 + top * 0.17)
    var lower := Vector3(lerpf(0.32, 0.41, bottom), -bottom, 0.24 + bottom * 0.17)
    var left_upper := Vector3(-upper.x, upper.y, upper.z)
    var left_lower := Vector3(-lower.x, lower.y, lower.z)
    for point in [left_upper, upper, lower, left_upper, lower, left_lower,
            lower, upper, left_upper, left_lower, lower, left_upper]:
        cloth.add_vertex(point)
    cloth.generate_normals()
    var mesh := MeshInstance3D.new()
    mesh.name = title
    mesh.mesh = cloth.commit()
    mesh.position = Vector3(0, 1.77, 0.0)
    mesh.material_override = _anime_material(tint, false, false)
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    body_root.add_child(mesh)
    return mesh

func apply_rank_clothing(rank: String) -> void:
    var licensed := RANK_TRIM.has(rank)
    rank_cape.visible = licensed
    cape_edge.visible = licensed
    cape_trim.visible = not licensed
    if not licensed:
        return
    var senior: bool = rank in ["Gold", "Grand", "Sage"]
    rank_cape.scale.y = 1.38 if senior else 0.62
    cape_edge.scale.y = rank_cape.scale.y
    cape_edge.position.z = 0.005
    _tint(rank_cape, Color("#8C5C2C") if senior else Color("#222945"))
    _tint(cape_edge, RANK_TRIM[rank])

func apply_spoke_sash(spoke: String) -> void:
    if spoke_sash == null:
        return
    spoke_sash.visible = SPOKE_CLOTH.has(spoke)
    if spoke_sash.visible:
        _tint(spoke_sash, SPOKE_CLOTH[spoke])


func configure_anime_civilian(jacket: Color, skin: Color, hair: int) -> void:
    _configure_anime("civilian", hair)
    _color_civilian(jacket, skin)
    _tint(body_root.get_node("Nose"), skin)
    for lapel in body_root.find_children("CoatLapel*", "MeshInstance3D", true, false):
        _tint(lapel, jacket.lightened(0.14))

func configure_anime_body(look: String) -> void:
    anime_style = true
    ink = ShaderMaterial.new()
    ink.shader = INK_SHADER
    configure(look)
    anime_gem_scale = aura_gem.scale


func _configure_anime(look: String, hair: int) -> void:
    configure_anime_body(look)
    shoulder_drapes.append(_sphere(left_arm, "ShoulderDrape", Vector3(0.09, -0.08, 0),
        Vector3(0.18, 0.15, 0.164), Color(0.19, 0.32, 0.47)))
    shoulder_drapes.append(_sphere(right_arm, "ShoulderDrape", Vector3(-0.09, -0.08, 0),
        Vector3(0.18, 0.15, 0.164), Color(0.19, 0.32, 0.47)))
    body_root.get_node("FaceBand").hide()
    for side in [-1.0, 1.0]:
        var eye_x: float = side * 0.115
        _sphere(body_root, "InkEye", Vector3(eye_x, 2.19, -0.285),
            Vector3(0.071, 0.043, 0.034), Color(0.10, 0.065, 0.09))
        _sphere(body_root, "EyeWhite", Vector3(eye_x, 2.185, -0.315),
            Vector3(0.053, 0.028, 0.012), Color(0.94, 0.88, 0.83))
        _sphere(body_root, "Iris", Vector3(eye_x, 2.185, -0.327),
            Vector3(0.023, 0.026, 0.009), Color(0.19, 0.14, 0.24))
        var brow := _box(body_root, "Brow", Vector3(eye_x, 2.26, -0.302),
            Vector3(0.105, 0.018, 0.018), Color(0.13, 0.085, 0.11))
        brow.rotation.z = side * -0.13
    _sphere(body_root, "Nose", Vector3(0, 2.108, -0.278),
        Vector3(0.029, 0.037, 0.030), Color(0.69, 0.48, 0.37))
    _box(body_root, "Mouth", Vector3(0, 2.027, -0.282),
        Vector3(0.068, 0.014, 0.013), Color(0.39, 0.20, 0.24))
    body_root.get_node("LeftEye").hide()
    body_root.get_node("RightEye").hide()
    body_root.get_node("Hair").hide()
    for side in [-1.0, 1.0]:
        var lapel := _box(body_root, "CoatLapel", Vector3(side * 0.145, 1.51, -0.203),
            Vector3(0.07, 0.40, 0.055), Color(0.65, 0.50, 0.29))
        lapel.rotation.z = side * -0.35
    var locks := _pivot(body_root, "AnimeLocks", Vector3.ZERO)
    var hair_colors: Array[Color] = [Color(0.17, 0.14, 0.23), Color(0.30, 0.19, 0.17),
        Color(0.21, 0.21, 0.25), Color(0.38, 0.25, 0.17)]
    var hair_tint: Color = hair_colors[posmod(hair, hair_colors.size())]
    var fringe_count: int = 3 if hair == 2 else 5
    for index in range(fringe_count):
        var x: float = (float(index) - float(fringe_count - 1) * 0.5) * 0.106
        var lock := _sphere(locks, "Fringe", Vector3(x, 2.37 - absf(x) * 0.38, -0.196),
            Vector3(0.088, 0.13 if hair == 2 else 0.163, 0.124), hair_tint)
        lock.rotation.z = (0.30 if hair == 1 else -0.29) + x * 1.1
    _sphere(locks, "HairCap", Vector3(0, 2.365, 0.034), Vector3(0.335, 0.218, 0.295),
        hair_tint.darkened(0.19))
    for side in [-1.0, 1.0]:
        var lock := _sphere(locks, "TempleLock", Vector3(side * 0.274, 2.265, 0.02),
            Vector3(0.084, 0.14 if hair == 2 else 0.19, 0.19), hair_tint.darkened(0.12))
        lock.rotation.z = side * 0.17

func _tint(part: MeshInstance3D, color: Color) -> void:
    if part.material_override is ShaderMaterial:
        (part.material_override as ShaderMaterial).set_shader_parameter("base_color", color)
    else:
        (part.material_override as StandardMaterial3D).albedo_color = color

func _anime_material(color: Color, face: bool, outline: bool) -> ShaderMaterial:
    var material := ShaderMaterial.new()
    material.shader = ANIME_SHADER
    material.set_shader_parameter("base_color", color)
    material.set_shader_parameter("face_lighting", face)
    if outline:
        material.next_pass = ink
    return material

func _build_rig() -> void:
    body_root = Node3D.new()
    body_root.name = "AnimatedBody"
    add_child(body_root)
    torso_mesh = _box(body_root, "SeekerCoat", Vector3(0, 1.32, 0), Vector3(0.78, 0.88, 0.43), Color.WHITE)
    _box(body_root, "Belt", Vector3(0, 0.93, -0.03), Vector3(0.84, 0.14, 0.48), Color(0.15, 0.17, 0.22))
    _box(body_root, "Collar", Vector3(0, 1.79, -0.05), Vector3(0.67, 0.13, 0.46), Color(0.20, 0.24, 0.32))
    _box(body_root, "Neck", Vector3(0, 1.87, 0), Vector3(0.26, 0.24, 0.27), Color(0.65, 0.42, 0.31))
    _sphere(body_root, "Head", Vector3(0, 2.13, 0), Vector3(0.31, 0.37, 0.29), Color(0.69, 0.48, 0.37))
    _box(body_root, "Hair", Vector3(0, 2.43, 0.02), Vector3(0.62, 0.16, 0.57), Color(0.12, 0.15, 0.20))
    _box(body_root, "FaceBand", Vector3(0, 2.26, -0.28), Vector3(0.56, 0.10, 0.07), Color(0.15, 0.20, 0.28))
    _box(body_root, "LeftEye", Vector3(-0.12, 2.20, -0.303), Vector3(0.065, 0.042, 0.028), Color(0.91, 0.97, 1.0))
    _box(body_root, "RightEye", Vector3(0.12, 2.20, -0.303), Vector3(0.065, 0.042, 0.028), Color(0.91, 0.97, 1.0))

    left_arm = _pivot(body_root, "LeftShoulder", Vector3(-0.51, 1.69, 0))
    right_arm = _pivot(body_root, "RightShoulder", Vector3(0.51, 1.69, 0))
    left_sleeve = _box(left_arm, "LeftSleeve", Vector3(0, -0.31, 0), Vector3(0.29, 0.59, 0.32), Color.WHITE)
    right_sleeve = _box(right_arm, "RightSleeve", Vector3(0, -0.31, 0), Vector3(0.29, 0.59, 0.32), Color.WHITE)
    _box(left_arm, "LeftGlove", Vector3(0, -0.69, -0.035), Vector3(0.27, 0.27, 0.27), Color(0.22, 0.26, 0.33))
    _box(right_arm, "RightGlove", Vector3(0, -0.69, -0.035), Vector3(0.27, 0.27, 0.27), Color(0.22, 0.26, 0.33))
    _box(left_arm, "LeftTrim", Vector3(0, -0.55, -0.17), Vector3(0.30, 0.08, 0.05), Color(0.32, 0.75, 0.98))
    _box(right_arm, "RightTrim", Vector3(0, -0.55, -0.17), Vector3(0.30, 0.08, 0.05), Color(0.32, 0.75, 0.98))

    left_leg = _pivot(body_root, "LeftHip", Vector3(-0.22, 0.94, 0))
    right_leg = _pivot(body_root, "RightHip", Vector3(0.22, 0.94, 0))
    left_pant = _box(left_leg, "LeftPant", Vector3(0, -0.39, 0), Vector3(0.33, 0.72, 0.38), Color.WHITE)
    right_pant = _box(right_leg, "RightPant", Vector3(0, -0.39, 0), Vector3(0.33, 0.72, 0.38), Color.WHITE)
    _box(left_leg, "LeftBoot", Vector3(0, -0.78, -0.085), Vector3(0.36, 0.24, 0.49), Color(0.16, 0.18, 0.23))
    _box(right_leg, "RightBoot", Vector3(0, -0.78, -0.085), Vector3(0.36, 0.24, 0.49), Color(0.16, 0.18, 0.23))
    cape_trim = _box(body_root, "RearCoatTail", Vector3(0, 0.86, 0.20), Vector3(0.72, 0.57, 0.09), Color.WHITE)
    aura_gem = _sphere(body_root, "AuraInsignia", Vector3(0, 1.42, -0.26), Vector3(0.14, 0.14, 0.06), Color(0.40, 0.91, 1.0))
    (aura_gem.material_override as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _pivot(parent: Node3D, node_name: String, at: Vector3) -> Node3D:
    var result := Node3D.new()
    result.name = node_name
    result.position = at
    parent.add_child(result)
    return result

func _material(color: Color) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.roughness = 0.83
    return result

func _box(parent: Node3D, node_name: String, at: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = node_name
    var rounded: bool = anime_style and dimensions.y >= 0.23 and dimensions.x >= 0.16 \
        and dimensions.z >= 0.18 and node_name != "RearCoatTail"
    if rounded:
        var rounded_mesh := CapsuleMesh.new()
        rounded_mesh.radius = minf(dimensions.x, dimensions.z) * 0.5
        rounded_mesh.height = maxf(dimensions.y, rounded_mesh.radius * 2.0)
        rounded_mesh.radial_segments = 14
        rounded_mesh.rings = 5
        item.mesh = rounded_mesh
        item.scale = Vector3(dimensions.x / (rounded_mesh.radius * 2.0), 1.0,
            dimensions.z / (rounded_mesh.radius * 2.0))
    else:
        var primitive := BoxMesh.new()
        primitive.size = dimensions
        item.mesh = primitive
    item.position = at
    item.material_override = _anime_material(color, false, rounded and (appearance != "civilian" or node_name == "SeekerCoat")) if anime_style else _material(color)
    item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(item)
    return item

func _sphere(parent: Node3D, node_name: String, at: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = node_name
    var primitive := SphereMesh.new()
    primitive.radius = 0.5
    primitive.height = 1.0
    primitive.radial_segments = 24 if anime_style and appearance != "civilian" else 12
    primitive.rings = 12 if anime_style and appearance != "civilian" else 5
    item.mesh = primitive
    if anime_style:
        if node_name == "Head":
            item.mesh = _taper_profile(primitive, 0.76)
        elif node_name in ["Fringe", "TempleLock"]:
            item.mesh = _taper_profile(primitive, 0.24)
    item.scale = dimensions * 2.0
    item.position = at
    if anime_style and node_name != "AuraInsignia":
        item.material_override = _anime_material(color, node_name in ["Head", "Nose"], dimensions.y >= 0.09)
    else:
        item.material_override = _material(color)
    item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(item)
    return item

func _taper_profile(source: SphereMesh, lower_width: float) -> ArrayMesh:
    var arrays: Array = source.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
    for index in range(vertices.size()):
        var point: Vector3 = vertices[index]
        var blend: float = clampf((point.y + 0.48) / 0.44, 0.0, 1.0)
        var width: float = lerpf(lower_width, 1.0, blend * blend * (3.0 - 2.0 * blend))
        var slope: float = (1.0 - lower_width) * 6.0 * blend * (1.0 - blend) / 0.44
        var normal: Vector3 = normals[index]
        normals[index] = Vector3(normal.x / width, normal.y - point.x * slope * normal.x / width,
            normal.z).normalized()
        vertices[index].x *= width
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh

func _apply_colors() -> void:
    var jacket: Color = Color(0.19, 0.32, 0.47)
    var pants: Color = Color(0.19, 0.24, 0.30)
    accent = Color(0.32, 0.78, 1.0)
    if appearance == "guardian":
        jacket = Color(0.38, 0.23, 0.29)
        pants = Color(0.26, 0.18, 0.22)
        accent = Color(1.0, 0.66, 0.26)
    elif appearance == "skirmisher":
        jacket = Color(0.27, 0.22, 0.45)
        pants = Color(0.20, 0.16, 0.34)
        accent = Color(0.65, 0.48, 1.0)
    _color_clothes(jacket, pants)
    (aura_gem.material_override as StandardMaterial3D).albedo_color = accent

func _color_clothes(jacket: Color, pants: Color) -> void:
    for item in [torso_mesh, left_sleeve, right_sleeve, cape_trim]:
        _tint(item, jacket)
    for item in shoulder_drapes:
        _tint(item, jacket)
    for item in [left_pant, right_pant]:
        _tint(item, pants)

func apply_national_outfit(nation: String) -> void:
    # 3D game costume silhouettes inspired by the author's Young Blood guide.
    # Cosmetic only: no canon military status, rank or inherited abilities.
    if appearance != "seeker":
        return
    if not is_instance_valid(body_root):
        _build_rig()
        _apply_colors()
    if national_nation == nation and is_instance_valid(national_accessories):
        return
    national_nation = nation
    if is_instance_valid(national_accessories):
        national_accessories.queue_free()
    national_accessories = Node3D.new()
    national_accessories.name = "NationalClothing"
    body_root.add_child(national_accessories)
    var outfit: Node3D = national_accessories
    match nation:
        "Janoah":
            _box(outfit, "WorkVest", Vector3(0.0, 1.28, -0.225),
                Vector3(0.69, 0.53, 0.08), Color(0.43, 0.42, 0.39))
            _box(outfit, "UtilityPocket", Vector3(0.21, 1.09, -0.28),
                Vector3(0.23, 0.18, 0.07), Color(0.28, 0.35, 0.41))
        "Rajistan":
            var sash := _box(outfit, "SaffronDrapedWrap", Vector3(-0.07, 1.36, -0.31),
                Vector3(0.22, 0.91, 0.09), Color(0.88, 0.55, 0.17))
            sash.rotation.z = -0.40
            _box(outfit, "TempleWaistCloth", Vector3(0.0, 0.86, -0.29),
                Vector3(0.75, 0.20, 0.12), Color(0.70, 0.41, 0.14))
        "Chun":
            var cross_left := _box(outfit, "LeftCrossCollar", Vector3(-0.13, 1.67, -0.27),
                Vector3(0.15, 0.43, 0.09), Color(0.64, 0.21, 0.22))
            cross_left.rotation.z = -0.55
            var cross_right := _box(outfit, "RightCrossCollar", Vector3(0.13, 1.67, -0.28),
                Vector3(0.15, 0.43, 0.09), Color(0.20, 0.44, 0.42))
            cross_right.rotation.z = 0.55
            _box(outfit, "RobeOverpanel", Vector3(0.08, 1.22, -0.285),
                Vector3(0.34, 0.54, 0.06), Color(0.25, 0.36, 0.39))
        "Vinlan":
            _box(outfit, "FurMantle", Vector3(0.0, 1.76, 0.02),
                Vector3(1.15, 0.26, 0.57), Color(0.76, 0.72, 0.65))
            _box(outfit, "WinterClasp", Vector3(0.0, 1.70, -0.36),
                Vector3(0.24, 0.16, 0.11), Color(0.54, 0.64, 0.68))
        "Britannia":
            _box(outfit, "OathTabard", Vector3(0.0, 1.22, -0.285),
                Vector3(0.45, 0.98, 0.08), Color(0.84, 0.81, 0.67))
            _box(outfit, "SunHeraldicBand", Vector3(0.0, 1.43, -0.345),
                Vector3(0.30, 0.19, 0.07), Color(0.88, 0.67, 0.25))
            _box(outfit, "CapeShoulderClasp", Vector3(0.0, 1.81, 0.22),
                Vector3(0.79, 0.13, 0.10), Color(0.67, 0.52, 0.32))
        "Germania":
            _box(outfit, "GreatcoatFrontLeft", Vector3(-0.20, 0.78, -0.235),
                Vector3(0.30, 0.60, 0.12), Color(0.25, 0.30, 0.33))
            _box(outfit, "GreatcoatFrontRight", Vector3(0.20, 0.78, -0.235),
                Vector3(0.30, 0.60, 0.12), Color(0.25, 0.30, 0.33))
            _box(outfit, "HighCollar", Vector3(0.0, 1.87, -0.19),
                Vector3(0.67, 0.24, 0.16), Color(0.37, 0.34, 0.32))
        "Tsar Empire":
            _box(outfit, "FurTrimmedCollar", Vector3(0.0, 1.80, 0.04),
                Vector3(1.05, 0.22, 0.60), Color(0.83, 0.84, 0.82))
            _box(outfit, "WinterBuckle", Vector3(0.0, 1.29, -0.28),
                Vector3(0.27, 0.23, 0.12), Color(0.49, 0.57, 0.66))
        "Zirael":
            _box(outfit, "WaterproofHood", Vector3(0.0, 2.30, 0.10),
                Vector3(0.80, 0.63, 0.52), Color(0.28, 0.42, 0.54))
            _box(outfit, "FaceWrap", Vector3(0.0, 2.01, -0.29),
                Vector3(0.58, 0.15, 0.11), Color(0.36, 0.55, 0.63))
        "Africanus":
            var mantle := _box(outfit, "WovenShoulderWrap", Vector3(0.31, 1.39, -0.17),
                Vector3(0.33, 0.92, 0.30), Color(0.74, 0.47, 0.20))
            mantle.rotation.z = -0.20
            _box(outfit, "WeavePatternBand", Vector3(0.30, 1.49, -0.35),
                Vector3(0.36, 0.11, 0.08), Color(0.31, 0.56, 0.49))
        "Americana":
            _box(outfit, "DusterTail", Vector3(0.0, 0.71, 0.24),
                Vector3(0.84, 0.80, 0.11), Color(0.53, 0.42, 0.31))
            var scarf := _box(outfit, "DusterNeckerchief", Vector3(0.0, 1.78, -0.25),
                Vector3(0.57, 0.17, 0.12), Color(0.61, 0.25, 0.19))
            scarf.rotation.z = -0.11
        _:
            # Unknown or unset origin: do not invent a national costume.
            pass

func trigger_attack() -> void:
    attack_time = 0.32

func trigger_impact() -> void:
    impact_time = 0.24

func animate_state(delta: float, planar_speed: float, dodging: bool = false, posture: String = "",
        airborne: bool = false) -> void:
    if not is_instance_valid(body_root):
        return
    animation_time += delta * (4.2 + minf(planar_speed, 9.0) * 0.90)
    attack_time = maxf(0.0, attack_time - delta)
    impact_time = maxf(0.0, impact_time - delta)
    var pose: String = "dodge" if dodging else posture
    if pose.is_empty() and attack_time > 0.0:
        pose = "strike" if attack_time > 0.12 else "recover"
    if pose.is_empty() and airborne:
        pose = "air"
    if anime_style:
        pose_clock += delta
        if pose == last_pose and pose_clock < POSE_INTERVAL:
            return
        pose_clock = fposmod(pose_clock, POSE_INTERVAL)
        last_pose = pose
    var stride: float = clampf(planar_speed / 5.5, 0.0, 1.35)
    if is_instance_valid(shinobi_visual) and shinobi_visual.visible:
        shinobi_visual.present(animation_time, stride, pose)
        return
    var wave: float = sin(animation_time)
    var swing: float = wave * stride * 0.62
    var seated: bool = posture == "picnic"
    left_leg.rotation.x = lerpf(left_leg.rotation.x, 1.45 if seated else swing, 1.0 if anime_style else minf(1.0, delta * 15.0))
    right_leg.rotation.x = lerpf(right_leg.rotation.x, 1.45 if seated else -swing, 1.0 if anime_style else minf(1.0, delta * 15.0))
    var l_arm: float = -swing * 0.75
    var r_arm: float = swing * 0.75
    var lean: float = 0.04 + stride * 0.07
    if seated:
        l_arm = 0.75
        r_arm = 0.84 + 0.20 * sin(animation_time * 0.5)
        lean = 0.09
    elif posture == "recite":
        l_arm = 0.32
        r_arm = 0.66 + 0.38 * sin(animation_time * 0.62)
    elif posture == "windup":
        r_arm = -0.48
        l_arm = 0.32
        lean = -0.20
    elif posture == "guard":
        r_arm = 1.08
        l_arm = 1.08
        lean = -0.06
    elif posture == "stagger" or impact_time > 0.0:
        r_arm = -0.60
        l_arm = -0.60
        lean = -0.28
    elif attack_time > 0.0:
        r_arm = 0.73 if anime_style and pose == "recover" else 1.35
        l_arm = -0.30
        lean = 0.20
    if dodging:
        lean = 0.47
        r_arm = -0.42
        l_arm = -0.42
    left_arm.rotation.x = lerpf(left_arm.rotation.x, l_arm, 1.0 if anime_style else minf(1.0, delta * 20.0))
    right_arm.rotation.x = lerpf(right_arm.rotation.x, r_arm, 1.0 if anime_style else minf(1.0, delta * 20.0))
    body_root.rotation.x = lerpf(body_root.rotation.x, lean, 1.0 if anime_style else minf(1.0, delta * 14.0))
    body_root.position.y = -0.70 if seated else absf(wave) * stride * 0.06
    aura_gem.scale = (anime_gem_scale if anime_style else Vector3.ONE) * (1.0 + 0.12 * sin(animation_time * 0.55))


func apply_player_appearance(skin_id: int, hair_id: int, coat_id: int, aura_id: int) -> void:
    if not is_instance_valid(body_root) or appearance != "seeker":
        return
    if is_instance_valid(shinobi_visual) and shinobi_visual.visible:
        shinobi_visual.set_skin(skin_id)
        return
    var skins: Array[Color] = [Color(0.69, 0.48, 0.37), Color(0.35, 0.23, 0.18), Color(0.85, 0.65, 0.52), Color(0.61, 0.49, 0.31)]
    var coats: Array[Color] = [Color(0.19, 0.32, 0.47), Color(0.19, 0.39, 0.31), Color(0.13, 0.15, 0.22), Color(0.51, 0.20, 0.25)]
    var auras: Array[Color] = [Color(0.32, 0.78, 1.0), Color(1.0, 0.79, 0.31), Color(0.72, 0.50, 1.0), Color(0.34, 0.88, 0.55)]
    var skin_color: Color = skins[clampi(skin_id, 0, skins.size() - 1)]
    var jacket_color: Color = coats[clampi(coat_id, 0, coats.size() - 1)]
    var aura_color: Color = auras[clampi(aura_id, 0, auras.size() - 1)]
    for part_name in ["Head", "Neck"]:
        var part: MeshInstance3D = body_root.get_node(part_name) as MeshInstance3D
        _tint(part, skin_color)
    if anime_style:
        _tint(body_root.get_node("Nose"), skin_color)
    _color_clothes(jacket_color, jacket_color.darkened(0.33))
    (aura_gem.material_override as StandardMaterial3D).albedo_color = aura_color
    for sleeve in ["LeftTrim", "RightTrim"]:
        var parent: Node3D = left_arm if sleeve == "LeftTrim" else right_arm
        var trim: MeshInstance3D = parent.get_node(sleeve) as MeshInstance3D
        _tint(trim, aura_color)

    if not body_root.has_node("HairSpikes"):
        var spikes := Node3D.new()
        spikes.name = "HairSpikes"
        body_root.add_child(spikes)
        for i in range(3):
            _box(spikes, "Spike%d" % i, Vector3(-0.21 + float(i) * 0.21, 2.55 + float(i % 2) * 0.09, -0.04), Vector3(0.16, 0.30, 0.32), Color(0.12, 0.15, 0.20))
    if not body_root.has_node("HairTopknot"):
        _sphere(body_root, "HairTopknot", Vector3(0.0, 2.61, 0.10), Vector3(0.16, 0.20, 0.16), Color(0.12, 0.15, 0.20))
    var style: int = clampi(hair_id, 0, 3)
    var hair: MeshInstance3D = body_root.get_node("Hair") as MeshInstance3D
    var spikes_node: Node3D = body_root.get_node("HairSpikes") as Node3D
    var topknot: MeshInstance3D = body_root.get_node("HairTopknot") as MeshInstance3D
    hair.visible = style != 3 and not anime_style
    if anime_style:
        body_root.get_node("AnimeLocks").visible = style != 3
    hair.scale = Vector3(1.0, 0.65 if style == 1 else 1.0, 1.0)
    spikes_node.visible = style == 1
    topknot.visible = style == 2
