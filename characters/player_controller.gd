
extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 9.0
@export var jump_velocity: float = 5.0

var gravity: float = 9.8

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta

    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = jump_velocity

    var input_dir := Input.get_vector(
        "ui_left", "ui_right",
        "ui_up", "ui_down"
    )

    var direction := Vector3(
        input_dir.x, 0.0, input_dir.y
    ).normalized()

    var speed := walk_speed

    if Input.is_key_pressed(KEY_SHIFT):
        speed = sprint_speed

    velocity.x = direction.x * speed
    velocity.z = direction.z * speed

    move_and_slide()
