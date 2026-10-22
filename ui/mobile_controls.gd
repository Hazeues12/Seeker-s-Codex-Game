
extends Control

var movement: Vector2 = Vector2.ZERO
var sprinting: bool = false
var jump_requested: bool = false

func set_movement(direction: Vector2) -> void:
    movement = direction.limit_length(1.0)

func set_sprinting(enabled: bool) -> void:
    sprinting = enabled

func request_jump() -> void:
    jump_requested = true

func consume_jump() -> bool:
    if jump_requested:
        jump_requested = false
        return true
    return false

func release_controls() -> void:
    movement = Vector2.ZERO
    sprinting = false
    jump_requested = false
