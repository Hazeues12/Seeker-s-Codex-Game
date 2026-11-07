extends Node3D

const MODEL = preload("res://characters/art/shinobi_black.glb")
const PAINT = preload("res://shaders/shinobi_painted_cel.gdshader")
const INK = preload("res://shaders/seeker_ink_v082.gdshader")
const SKIN_TINTS: Array[Vector3] = [
    Vector3(1.0, 1.0, 1.0), Vector3(0.37, 0.32, 0.35),
    Vector3(1.14, 1.19, 1.21), Vector3(0.82, 0.93, 0.74),
]

var skeleton: Skeleton3D
var skin_material: ShaderMaterial
var costume_material: ShaderMaterial
var contour: ShaderMaterial
var bone_indices: Dictionary = {}
var local_rests: Array[Quaternion] = []
var bone_axes: Array[Quaternion] = []
var pelvis_rest: Vector3


func _ready() -> void:
    var model := MODEL.instantiate()
    add_child(model)
    skeleton = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
    for bone in range(skeleton.get_bone_count()):
        bone_indices[skeleton.get_bone_name(bone)] = bone
        local_rests.append(skeleton.get_bone_pose_rotation(bone))
        bone_axes.append(skeleton.get_bone_global_rest(bone).basis.get_rotation_quaternion())
    pelvis_rest = skeleton.get_bone_pose_position(bone_indices[&"Pelvis"])

    contour = ShaderMaterial.new()
    contour.shader = INK
    contour.set_shader_parameter("width", 0.0035)
    for node in model.find_children("*", "MeshInstance3D", true, false):
        var part := node as MeshInstance3D
        var material := ShaderMaterial.new()
        material.shader = PAINT
        if part.name == &"Skin":
            skin_material = material
            material.set_shader_parameter("face_layer", true)
        elif part.name == &"Costume":
            costume_material = material
            material.next_pass = contour
        part.material_override = material
        part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func set_skin(skin_id: int) -> void:
    skin_material.set_shader_parameter("skin_tint", SKIN_TINTS[clampi(skin_id, 0, SKIN_TINTS.size() - 1)])


func set_outline_enabled(enabled: bool) -> void:
    costume_material.next_pass = contour if enabled else null


func present(clock: float, stride: float, pose: String) -> void:
    var wave: float = sin(clock)
    var lift: float = absf(cos(clock)) * stride * 0.028
    var chest := Vector3(-0.10 * stride + 0.012 * sin(clock * 0.54), wave * stride * 0.07, 0)
    var left_leg := Vector3(wave * stride * 0.64, 0, 0)
    var right_leg := Vector3(-wave * stride * 0.64, 0, 0)
    var left_knee: float = -maxf(0, -wave) * stride * 0.94
    var right_knee: float = -maxf(0, wave) * stride * 0.94
    var left_arm := Vector3(-wave * stride * 0.46, 0, 0.04 * stride)
    var right_arm := Vector3(wave * stride * 0.46, 0, -0.04 * stride)
    var left_elbow: float = 0.09 * stride + maxf(0, -wave) * stride * 0.40
    var right_elbow: float = 0.09 * stride + maxf(0, wave) * stride * 0.40

    match pose:
        "strike", "recover":
            var extension: float = 1.0 if pose == "strike" else 0.49
            chest = Vector3(-0.16, 0.31, -0.03) * extension
            left_arm = Vector3(0.32, -0.04, 0.15)
            right_arm = Vector3(1.43, -0.05, -0.33) * extension
            left_elbow = 0.82
            right_elbow = 0.16 if pose == "strike" else 0.66
        "guard":
            chest.x = -0.11
            left_arm = Vector3(0.72, 0, 0.36)
            right_arm = Vector3(0.70, 0, -0.36)
            left_elbow = 1.05
            right_elbow = 1.09
        "dodge":
            chest = Vector3(-0.46, 0.12, 0.06)
            lift = -0.16
            left_leg.x = 0.45
            right_leg.x = -0.30
            left_knee = -0.70
            right_knee = -0.45
            left_arm = Vector3(-0.32, 0, -0.12)
            right_arm = Vector3(-0.50, 0, 0.13)
        "air":
            chest.x = -0.19
            left_leg.x = 0.40
            right_leg.x = -0.20
            left_knee = -0.68
            right_knee = -0.86
            left_arm = Vector3(0.28, 0, -0.14)
            right_arm = Vector3(0.07, 0, 0.14)
            left_elbow = 0.42
            right_elbow = 0.31
        "stagger":
            chest = Vector3(0.20, -0.14, 0)
            left_arm.x = -0.32
            right_arm.x = -0.40

    skeleton.set_bone_pose_position(bone_indices[&"Pelvis"], pelvis_rest + Vector3.UP * lift)
    _turn(&"Chest", chest)
    _turn(&"Head", Vector3(-chest.x * 0.42, -chest.y * 0.35, 0.008 * sin(clock * 0.70)))
    _turn(&"UpperArm_L", left_arm)
    _turn(&"UpperArm_R", right_arm)
    _turn(&"Forearm_L", Vector3(left_elbow, 0, 0))
    _turn(&"Forearm_R", Vector3(right_elbow, 0, 0))
    _turn(&"Thigh_L", left_leg)
    _turn(&"Thigh_R", right_leg)
    _turn(&"Calf_L", Vector3(left_knee, 0, 0))
    _turn(&"Calf_R", Vector3(right_knee, 0, 0))
    _turn(&"Foot_L", Vector3(-0.5 * (left_leg.x + left_knee), 0, 0))
    _turn(&"Foot_R", Vector3(-0.5 * (right_leg.x + right_knee), 0, 0))
    _turn(&"Ribbon_0", Vector3(0, 0.10 * sin(clock * 1.32), 0.11 * sin(clock * 1.27)))
    _turn(&"Ribbon_1", Vector3(0, 0.13 * cos(clock * 1.19), 0.13 * cos(clock * 1.34)))
    _turn(&"SashTail", Vector3(-stride * 0.12 + 0.06 * wave, 0, 0.06 * wave))


func _turn(name: StringName, euler: Vector3) -> void:
    var bone: int = bone_indices[name]
    var axes: Quaternion = bone_axes[bone]
    var offset: Quaternion = axes.inverse() * Quaternion.from_euler(euler) * axes
    skeleton.set_bone_pose_rotation(bone, (local_rests[bone] * offset).normalized())
