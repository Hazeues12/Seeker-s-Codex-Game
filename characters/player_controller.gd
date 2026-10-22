extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 9.0
@export var jump_velocity: float = 5.0
@export var acceleration: float = 17.0
@export var braking: float = 23.0
@export var camera_turn_sensitivity: float = 0.0045

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_node: Camera3D = $CameraPivot/Camera3D

var gravity: float = 9.8
var mobile_controls = null
var wanted_yaw: float = 0.0
var wanted_pitch: float = 0.0

# V0.34: independent, cooldown-limited prototype Martial actions.
var attack_cooldown: float = 0.0
var dodge_cooldown: float = 0.0
var dodge_time: float = 0.0
var dodge_direction: Vector3 = Vector3.ZERO

func _ready() -> void:
    mobile_controls = get_tree().get_first_node_in_group("mobile_controls")
    camera_node.position = Vector3(0.0, 1.6, 5.5)
    camera_node.rotation_degrees = Vector3(-15.0, 0.0, 0.0)

func _process(delta: float) -> void:
    if not is_instance_valid(mobile_controls):
        return
    var drag: Vector2 = mobile_controls.consume_camera_drag()
    wanted_yaw -= drag.x * camera_turn_sensitivity
    wanted_pitch = clampf(
        wanted_pitch - drag.y * camera_turn_sensitivity,
        deg_to_rad(-25.0),
        deg_to_rad(22.0)
    )
    var smoothing: float = 1.0 - exp(-11.0 * delta)
    camera_pivot.rotation.y = lerp_angle(camera_pivot.rotation.y, wanted_yaw, smoothing)
    camera_pivot.rotation.x = lerp_angle(camera_pivot.rotation.x, wanted_pitch, smoothing)

func _physics_process(delta: float) -> void:
    if not is_instance_valid(mobile_controls):
        mobile_controls = get_tree().get_first_node_in_group("mobile_controls")

    if not is_on_floor():
        velocity.y -= gravity * delta

    var keyboard_jump: bool = Input.is_action_just_pressed("ui_accept")
    var mobile_jump: bool = false
    if is_instance_valid(mobile_controls):
        mobile_jump = mobile_controls.consume_jump()
    if is_on_floor() and (keyboard_jump or mobile_jump):
        velocity.y = jump_velocity

    var input_dir: Vector2 = Input.get_vector(
        "ui_left", "ui_right", "ui_up", "ui_down"
    )
    var mobile_sprinting: bool = false
    if is_instance_valid(mobile_controls):
        if mobile_controls.movement.length() > 0.05:
            input_dir = mobile_controls.movement
        mobile_sprinting = mobile_controls.sprinting

    var right: Vector3 = camera_node.global_transform.basis.x
    var forward: Vector3 = -camera_node.global_transform.basis.z
    right.y = 0.0
    forward.y = 0.0
    right = right.normalized()
    forward = forward.normalized()
    var direction: Vector3 = (right * input_dir.x - forward * input_dir.y).normalized()

    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
    dodge_time = maxf(0.0, dodge_time - delta)
    var wants_attack: bool = Input.is_key_pressed(KEY_F)
    var wants_dodge: bool = Input.is_key_pressed(KEY_Q)
    if is_instance_valid(mobile_controls):
        wants_attack = mobile_controls.consume_attack() or wants_attack
        wants_dodge = mobile_controls.consume_dodge() or wants_dodge
    var hub: Node = get_tree().get_first_node_in_group("hub_manager")
    var actions_allowed: bool = true
    if is_instance_valid(hub) and hub.has_method("can_use_combat_actions"):
        actions_allowed = bool(hub.call("can_use_combat_actions"))
    if actions_allowed and wants_attack and attack_cooldown <= 0.0 and dodge_time <= 0.0:
        var strike_allowed: bool = true
        if is_instance_valid(hub) and hub.has_method("try_martial_strike"):
            strike_allowed = bool(hub.call("try_martial_strike"))
        if strike_allowed:
            attack_cooldown = 0.40
            _show_martial_pulse(forward)
    if actions_allowed and wants_dodge and dodge_cooldown <= 0.0 and is_on_floor():
        var dodge_allowed: bool = true
        if is_instance_valid(hub) and hub.has_method("try_dodge"):
            dodge_allowed = bool(hub.call("try_dodge"))
        if dodge_allowed:
            dodge_direction = direction if direction.length() > 0.10 else forward
            dodge_direction = dodge_direction.normalized()
            dodge_time = 0.19
            dodge_cooldown = 0.95

    var sprint_allowed: bool = true
    if is_instance_valid(hub) and hub.has_method("can_sprint"):
        sprint_allowed = bool(hub.call("can_sprint"))
    var wants_sprint: bool = Input.is_key_pressed(KEY_SHIFT) or mobile_sprinting
    var speed: float = sprint_speed if wants_sprint and sprint_allowed else walk_speed
    var target: Vector3 = direction * (speed * input_dir.length())
    var rate: float = acceleration if input_dir.length() > 0.05 else braking
    if dodge_time > 0.0:
        velocity.x = dodge_direction.x * 11.5
        velocity.z = dodge_direction.z * 11.5
    else:
        velocity.x = move_toward(velocity.x, target.x, rate * delta)
        velocity.z = move_toward(velocity.z, target.z, rate * delta)
    move_and_slide()


func _show_martial_pulse(facing: Vector3) -> void:
    # V0.35 forwards the existing accepted Martial strike to actual hit detection.
    var arena: Node = get_tree().get_first_node_in_group("combat_arena")
    if is_instance_valid(arena) and arena.has_method("player_strike"):
        arena.call("player_strike", facing)
    # A tiny, temporary effect keeps the Web/mobile build lightweight.
    var pulse := MeshInstance3D.new()
    pulse.name = "MartialPulse"
    var sphere := SphereMesh.new()
    sphere.radius = 0.42
    sphere.height = 0.84
    pulse.mesh = sphere
    var material := StandardMaterial3D.new()
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = Color(0.31, 0.78, 1.0, 0.72)
    pulse.material_override = material
    pulse.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    get_parent().add_child(pulse)
    pulse.global_position = global_position + Vector3.UP * 1.20 + facing * 1.35
    pulse.scale = Vector3(0.28, 0.28, 0.28)
    var effect := create_tween()
    effect.tween_property(pulse, "scale", Vector3(2.3, 1.15, 1.6), 0.21)
    effect.tween_callback(pulse.queue_free)
