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

    var sprint_allowed: bool = true
    var hub: Node = get_tree().get_first_node_in_group("hub_manager")
    if is_instance_valid(hub) and hub.has_method("can_sprint"):
        sprint_allowed = bool(hub.call("can_sprint"))
    var wants_sprint: bool = Input.is_key_pressed(KEY_SHIFT) or mobile_sprinting
    var speed: float = sprint_speed if wants_sprint and sprint_allowed else walk_speed
    var target: Vector3 = direction * (speed * input_dir.length())
    var rate: float = acceleration if input_dir.length() > 0.05 else braking
    velocity.x = move_toward(velocity.x, target.x, rate * delta)
    velocity.z = move_toward(velocity.z, target.z, rate * delta)
    move_and_slide()
