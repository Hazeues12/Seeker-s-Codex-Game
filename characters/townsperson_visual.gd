class_name TownspersonVisual
extends Node3D

enum Form { MAN, WOMAN, CHILD }
const MODELS: Array[PackedScene] = [
    preload("res://characters/art/townsperson_man.glb"),
    preload("res://characters/art/townsperson_woman.glb"),
    preload("res://characters/art/townsperson_child.glb"),
]
const CEL = preload("res://shaders/townsperson_cel.gdshader")
const COATS: Array[Color] = [
    Color("#6E8792"), Color("#9E7253"), Color("#708371"), Color("#8C738D"),
    Color("#9C6458"), Color("#69788A"), Color("#968967"), Color("#7C8981"),
]
const TRIMS: Array[Color] = [
    Color("#B5A48A"), Color("#B99569"), Color("#A2A99D"), Color("#C5AA94"),
]
const SKINS: Array[Color] = [
    Color("#EDB994"), Color("#BF855D"), Color("#895742"),
    Color("#69453A"), Color("#D4A383"), Color("#F2CCAB"),
]
const HAIR: Array[Color] = [
    Color("#2B2733"), Color("#593D3C"), Color("#403133"), Color("#73615A"),
    Color("#574B41"), Color("#96939B"), Color("#382F3A"),
]
const POSE_INTERVAL: float = 1.0 / 12.0
const ANIMATE_DISTANCE_SQUARED: float = 55.0 * 55.0
static var _mid_mesh: ArrayMesh

var form: Form
var seed: int
var coat: Color
var skin: Color
var silhouette_scale: float = 1.0
var gait: float = 0.0
var pose: String = ""
var skeleton: Skeleton3D
var figure: MeshInstance3D
var palette: ShaderMaterial
var _bones: Dictionary = {}
var _rest: Array[Quaternion] = []
var _axes: Array[Quaternion] = []
var _root_rest: Vector3
var _elapsed: float = 0.0
var _clock: float


static func add_to(parent: Node3D, identity: String, selected_form: int = -1,
        clothing: Color = Color.TRANSPARENT, complexion: Color = Color.TRANSPARENT) -> TownspersonVisual:
    var resident := TownspersonVisual.new()
    resident.name = "Townsperson"
    resident.seed = absi(identity.hash())
    resident.form = (resident.seed % 2 if selected_form < 0 else selected_form) as Form
    resident.coat = coat_for(identity) if clothing.a == 0.0 else clothing
    resident.skin = SKINS[(resident.seed >> 5) % SKINS.size()] if complexion.a == 0.0 else complexion
    resident.silhouette_scale = 0.95 + float((resident.seed >> 10) % 9) * 0.0125
    resident.scale = Vector3.ONE * resident.silhouette_scale
    parent.add_child(resident)
    return resident


static func coat_for(identity: String) -> Color:
    return COATS[(absi(identity.hash()) >> 2) % COATS.size()]


static func mid_scale(identity: String) -> Vector3:
    var token: int = absi(identity.hash())
    var size: float = 0.95 + float((token >> 10) % 9) * 0.0125
    return Vector3(0.91, 0.97, 1.0) * size if token % 2 == Form.WOMAN else Vector3.ONE * size


static func mid_mesh() -> ArrayMesh:
    if _mid_mesh == null:
        var mesh := SurfaceTool.new()
        mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
        _loft_proxy(mesh, 0.0, [
            Vector3(0.21, 0.87, 0.14), Vector3(0.17, 1.10, 0.12),
            Vector3(0.27, 1.47, 0.15), Vector3(0.09, 1.63, 0.08)])
        _loft_proxy(mesh, 0.0, [
            Vector3(0.06, 1.62, 0.06), Vector3(0.14, 1.82, 0.11),
            Vector3(0.12, 2.01, 0.11), Vector3(0.05, 2.08, 0.06)])
        for side in [-1.0, 1.0]:
            _loft_proxy(mesh, side * 0.126, [
                Vector3(0.077, 0.03, 0.085), Vector3(0.076, 0.45, 0.085),
                Vector3(0.101, 0.91, 0.103)])
            _loft_proxy(mesh, side * 0.29, [
                Vector3(0.039, 0.96, 0.043), Vector3(0.073, 1.25, 0.067),
                Vector3(0.068, 1.49, 0.061)])
        mesh.generate_normals()
        _mid_mesh = mesh.commit()
    return _mid_mesh


static func _loft_proxy(mesh: SurfaceTool, x: float, rings: Array[Vector3]) -> void:
    for row in range(rings.size() - 1):
        for side in range(6):
            var a: float = side * TAU / 6.0
            var b: float = (side + 1) * TAU / 6.0
            var low: Vector3 = rings[row]
            var high: Vector3 = rings[row + 1]
            var p := Vector3(x + low.x * cos(a), low.y, low.z * sin(a))
            var q := Vector3(x + low.x * cos(b), low.y, low.z * sin(b))
            var r := Vector3(x + high.x * cos(a), high.y, high.z * sin(a))
            var s := Vector3(x + high.x * cos(b), high.y, high.z * sin(b))
            for vertex in [p, q, s, p, s, r]:
                mesh.add_vertex(vertex)
    for row in [0, rings.size() - 1]:
        var ring: Vector3 = rings[row]
        for side in range(6):
            var a: float = side * TAU / 6.0
            var b: float = (side + 1) * TAU / 6.0
            var p := Vector3(x + ring.x * cos(a), ring.y, ring.z * sin(a))
            var q := Vector3(x + ring.x * cos(b), ring.y, ring.z * sin(b))
            mesh.add_vertex(Vector3(x, ring.y, 0))
            mesh.add_vertex(p if row > 0 else q)
            mesh.add_vertex(q if row > 0 else p)


func _ready() -> void:
    var model := MODELS[form].instantiate()
    add_child(model)
    skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
    figure = model.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
    for index in range(skeleton.get_bone_count()):
        _bones[skeleton.get_bone_name(index)] = index
        _rest.append(skeleton.get_bone_pose_rotation(index))
        _axes.append(skeleton.get_bone_global_rest(index).basis.get_rotation_quaternion())
    _root_rest = skeleton.get_bone_pose_position(_bones[&"Pelvis"])
    palette = ShaderMaterial.new()
    palette.shader = CEL
    _paint("coat_linear", coat)
    _paint("skin_linear", skin)
    _paint("trim_linear", TRIMS[(seed >> 7) % TRIMS.size()])
    _paint("hair_linear", HAIR[(seed >> 12) % HAIR.size()])
    figure.material_override = palette
    figure.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    _clock = float(seed % 360) * PI / 180.0
    _sample_pose()


func _paint(channel: String, color: Color) -> void:
    var linear := color.srgb_to_linear()
    palette.set_shader_parameter(channel, Vector3(linear.r, linear.g, linear.b))


func set_motion(walk: float, action: String = "") -> void:
    gait = clampf(walk, 0.0, 1.0)
    if pose != action:
        pose = action
        _sample_pose()


func _process(delta: float) -> void:
    _elapsed += delta
    if _elapsed < POSE_INTERVAL:
        return
    _clock += _elapsed * (2.1 + gait * 4.6)
    _elapsed = 0.0
    if not is_visible_in_tree():
        return
    var camera := get_viewport().get_camera_3d()
    if camera != null and global_position.distance_squared_to(camera.global_position) > ANIMATE_DISTANCE_SQUARED:
        return
    _sample_pose()


func _sample_pose() -> void:
    var wave: float = sin(_clock)
    var hips: float = absf(wave) * gait * 0.025
    var sway: float = wave * gait * 0.052
    var thigh_l: float = wave * gait * 0.42
    var thigh_r: float = -thigh_l
    var knee_l: float = -maxf(0.0, -wave) * gait * 0.49
    var knee_r: float = -maxf(0.0, wave) * gait * 0.49
    var arm_l: float = -wave * gait * 0.27
    var arm_r: float = -arm_l
    var elbow_l: float = 0.08
    var elbow_r: float = 0.10
    if pose == "sit":
        hips = -0.68 if form != Form.CHILD else -0.45
        thigh_l = 1.36
        thigh_r = 1.31
        knee_l = -1.35
        knee_r = -1.30
        arm_l = 0.61
        arm_r = 0.66
        elbow_l = 0.47
        elbow_r = 0.52
    elif pose == "recite":
        arm_r = 0.60 + 0.15 * sin(_clock)
        elbow_r = 0.62 + 0.16 * cos(_clock)
    skeleton.set_bone_pose_position(_bones[&"Pelvis"], _root_rest + Vector3.UP * hips)
    _turn(&"Chest", Vector3(-0.035 * gait + sin(_clock * 0.35) * 0.015, sway, 0))
    _turn(&"Head", Vector3(0.012 * cos(_clock * 0.55), -sway * 0.62, 0))
    _turn(&"Upper_L", Vector3(arm_l, 0, 0))
    _turn(&"Upper_R", Vector3(arm_r, 0, 0))
    _turn(&"Lower_L", Vector3(elbow_l, 0, 0))
    _turn(&"Lower_R", Vector3(elbow_r, 0, 0))
    _turn(&"Thigh_L", Vector3(thigh_l, 0, 0))
    _turn(&"Thigh_R", Vector3(thigh_r, 0, 0))
    _turn(&"Shin_L", Vector3(knee_l, 0, 0))
    _turn(&"Shin_R", Vector3(knee_r, 0, 0))


func _turn(name: StringName, motion: Vector3) -> void:
    var index: int = _bones[name]
    var axes: Quaternion = _axes[index]
    var offset: Quaternion = axes.inverse() * Quaternion.from_euler(motion) * axes
    skeleton.set_bone_pose_rotation(index, (_rest[index] * offset).normalized())
