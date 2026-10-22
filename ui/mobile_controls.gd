
extends Control

var movement: Vector2 = Vector2.ZERO
var sprinting: bool = false
var jump_requested: bool = false

@onready var joystick: Control = $Joystick
@onready var jump_button: Button = $JumpButton
@onready var sprint_button: Button = $SprintButton

var joystick_touch_id: int = -1
var joystick_center: Vector2
var joystick_radius: float = 65.0

func _ready() -> void:
    joystick_center = joystick.get_global_rect().get_center()

    jump_button.pressed.connect(request_jump)
    sprint_button.button_down.connect(_on_sprint_down)
    sprint_button.button_up.connect(_on_sprint_up)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            if joystick.get_global_rect().has_point(event.position):
                if joystick_touch_id == -1:
                    joystick_touch_id = event.index
                    update_joystick(event.position)
        elif event.index == joystick_touch_id:
            joystick_touch_id = -1
            movement = Vector2.ZERO

    elif event is InputEventScreenDrag:
        if event.index == joystick_touch_id:
            update_joystick(event.position)

func update_joystick(position: Vector2) -> void:
    var offset: Vector2 = position - joystick_center
    movement = (offset / joystick_radius).limit_length(1.0)

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
    joystick_touch_id = -1

func _on_sprint_down() -> void:
    sprinting = true

func _on_sprint_up() -> void:
    sprinting = false
