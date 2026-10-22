
extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 9.0
@export var jump_velocity: float = 5.0

var gravity: float = 9.8
var mobile_controls: Control = null

func _ready() -> void:
    mobile_controls = get_tree().get_first_node_in_group("mobile_controls")

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta

    var keyboard_jump: bool = Input.is_action_just_pressed("ui_accept")
    var mobile_jump: bool = false

    if is_instance_valid(mobile_controls):
        mobile_jump = mobile_controls.consume_jump()

    if is_on_floor() and (keyboard_jump or mobile_jump):
        velocity.y = jump_velocity

    var input_dir: Vector2 = Input.get_vector(
        "ui_left",
        "ui_right",
        "ui_up",
        "ui_down"
    )

    var mobile_sprinting: bool = false

    if is_instance_valid(mobile_controls):
        if mobile_controls.movement.length() > 0.05:
            input_dir = mobile_controls.movement

        mobile_sprinting = mobile_controls.sprinting

    var direction: Vector3 = Vector3(
        input_dir.x,
        0.0,
        input_dir.y
    ).normalized()

    var speed: float = walk_speed

    if Input.is_key_pressed(KEY_SHIFT) or mobile_sprinting:
        speed = sprint_speed

    velocity.x = direction.x * speed
    velocity.z = direction.z * speed

    move_and_slide()
