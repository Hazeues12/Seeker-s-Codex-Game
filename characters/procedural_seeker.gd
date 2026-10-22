extends Node3D

# V0.37: asset-free, articulated low-poly Seeker and sparring fighter rig.
# Cosmetic only; collision, damage, Aura and movement stay in existing scripts.
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

func configure(look: String = "seeker") -> void:
    appearance = look
    if not is_instance_valid(body_root):
        _build_rig()
    _apply_colors()

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
    var primitive := BoxMesh.new()
    primitive.size = dimensions
    item.mesh = primitive
    item.position = at
    item.material_override = _material(color)
    item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(item)
    return item

func _sphere(parent: Node3D, node_name: String, at: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = node_name
    var primitive := SphereMesh.new()
    primitive.radius = 0.5
    primitive.height = 1.0
    primitive.radial_segments = 10
    primitive.rings = 5
    item.mesh = primitive
    item.scale = dimensions * 2.0
    item.position = at
    item.material_override = _material(color)
    item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(item)
    return item

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
    for item in [torso_mesh, left_sleeve, right_sleeve, cape_trim]:
        (item.material_override as StandardMaterial3D).albedo_color = jacket
    for item in [left_pant, right_pant]:
        (item.material_override as StandardMaterial3D).albedo_color = pants
    (aura_gem.material_override as StandardMaterial3D).albedo_color = accent

func trigger_attack() -> void:
    attack_time = 0.32

func trigger_impact() -> void:
    impact_time = 0.24

func animate_state(delta: float, planar_speed: float, dodging: bool = false, posture: String = "") -> void:
    if not is_instance_valid(body_root):
        return
    animation_time += delta * (4.2 + minf(planar_speed, 9.0) * 0.90)
    attack_time = maxf(0.0, attack_time - delta)
    impact_time = maxf(0.0, impact_time - delta)
    var stride: float = clampf(planar_speed / 5.5, 0.0, 1.35)
    var wave: float = sin(animation_time)
    var swing: float = wave * stride * 0.62
    left_leg.rotation.x = lerpf(left_leg.rotation.x, swing, minf(1.0, delta * 15.0))
    right_leg.rotation.x = lerpf(right_leg.rotation.x, -swing, minf(1.0, delta * 15.0))
    var l_arm: float = -swing * 0.75
    var r_arm: float = swing * 0.75
    var lean: float = 0.04 + stride * 0.07
    if posture == "windup":
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
        r_arm = 1.35
        l_arm = -0.30
        lean = 0.20
    if dodging:
        lean = 0.47
        r_arm = -0.42
        l_arm = -0.42
    left_arm.rotation.x = lerpf(left_arm.rotation.x, l_arm, minf(1.0, delta * 20.0))
    right_arm.rotation.x = lerpf(right_arm.rotation.x, r_arm, minf(1.0, delta * 20.0))
    body_root.rotation.x = lerpf(body_root.rotation.x, lean, minf(1.0, delta * 14.0))
    body_root.position.y = absf(wave) * stride * 0.06
    aura_gem.scale = Vector3.ONE * (1.0 + 0.12 * sin(animation_time * 0.55))
