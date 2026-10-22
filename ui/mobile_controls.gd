extends Control

# V0.32: one-pointer Safari-friendly controls with a smooth visual joystick.
var movement: Vector2 = Vector2.ZERO
var sprinting: bool = false
var jump_requested: bool = false
var camera_drag: Vector2 = Vector2.ZERO

@onready var joystick: Control = $Joystick
@onready var joystick_base: Panel = $Joystick/JoystickBase
@onready var jump_button: Button = $JumpButton
@onready var sprint_button: Button = $SprintButton

var joystick_knob: Panel
var pointer_mode: int = 0  # 0 = idle, 1 = joystick, 2 = camera
var last_pointer_position: Vector2 = Vector2.ZERO
const JOYSTICK_RADIUS: float = 65.0
const DEAD_ZONE: float = 0.13

func _ready() -> void:
    Input.emulate_mouse_from_touch = true
    joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var ring_style := StyleBoxFlat.new()
    ring_style.bg_color = Color(0.09, 0.18, 0.30, 0.47)
    ring_style.border_color = Color(0.68, 0.83, 1.0, 0.85)
    ring_style.set_border_width_all(3)
    ring_style.set_corner_radius_all(90)
    joystick_base.add_theme_stylebox_override("panel", ring_style)

    joystick_knob = Panel.new()
    joystick_knob.name = "JoystickThumb"
    joystick_knob.size = Vector2(58.0, 58.0)
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var knob_style := StyleBoxFlat.new()
    knob_style.bg_color = Color(0.26, 0.63, 1.0, 0.90)
    knob_style.border_color = Color(1.0, 1.0, 1.0, 0.95)
    knob_style.set_border_width_all(2)
    knob_style.set_corner_radius_all(29)
    joystick_knob.add_theme_stylebox_override("panel", knob_style)
    joystick.add_child(joystick_knob)
    _place_knob_immediately()

    jump_button.pressed.connect(request_jump)
    sprint_button.toggle_mode = true
    sprint_button.button_pressed = false
    sprint_button.toggled.connect(_on_sprint_toggled)
    sprint_button.text = "RUN: OFF"

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index != MOUSE_BUTTON_LEFT:
            return
        if event.pressed:
            if joystick.get_global_rect().has_point(event.position):
                pointer_mode = 1
                _update_movement(event.position)
            elif event.position.x > get_viewport_rect().size.x * 0.43 and not _on_action_button(event.position):
                pointer_mode = 2
                last_pointer_position = event.position
        else:
            if pointer_mode == 1:
                movement = Vector2.ZERO
            pointer_mode = 0
    elif event is InputEventMouseMotion:
        if pointer_mode == 1:
            _update_movement(event.position)
        elif pointer_mode == 2:
            var change: Vector2 = event.position - last_pointer_position
            camera_drag += change.limit_length(90.0)
            last_pointer_position = event.position

func _process(delta: float) -> void:
    if not is_instance_valid(joystick_knob):
        return
    var center: Vector2 = (joystick.size - joystick_knob.size) * 0.5
    var target: Vector2 = center + movement * JOYSTICK_RADIUS
    var weight: float = 1.0 - exp(-22.0 * delta)
    joystick_knob.position = joystick_knob.position.lerp(target, weight)

func _on_action_button(position: Vector2) -> bool:
    return jump_button.get_global_rect().has_point(position) or sprint_button.get_global_rect().has_point(position)

func _update_movement(position: Vector2) -> void:
    var center: Vector2 = joystick.get_global_rect().get_center()
    var raw: Vector2 = ((position - center) / JOYSTICK_RADIUS).limit_length(1.0)
    if raw.length() < DEAD_ZONE:
        movement = Vector2.ZERO
    else:
        movement = raw

func _place_knob_immediately() -> void:
    if is_instance_valid(joystick_knob):
        joystick_knob.position = (joystick.size - joystick_knob.size) * 0.5

func consume_camera_drag() -> Vector2:
    var result: Vector2 = camera_drag
    camera_drag = Vector2.ZERO
    return result

func _on_sprint_toggled(enabled: bool) -> void:
    sprinting = enabled
    sprint_button.text = "RUN: ON" if enabled else "RUN: OFF"

func request_jump() -> void:
    jump_requested = true

func consume_jump() -> bool:
    if jump_requested:
        jump_requested = false
        return true
    return false

func release_controls() -> void:
    movement = Vector2.ZERO
    camera_drag = Vector2.ZERO
    jump_requested = false
    pointer_mode = 0
    sprint_button.button_pressed = false
    sprinting = false
    _place_knob_immediately()

# Retain compatibility with the existing V0.31 repair workflow.
func _on_sprint_down() -> void:
    pass

func _on_sprint_up() -> void:
    pass
