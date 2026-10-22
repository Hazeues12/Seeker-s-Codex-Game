
extends Control

var movement: Vector2 = Vector2.ZERO
var sprinting: bool = false
var jump_requested: bool = false

@onready var joystick: Control = $Joystick
@onready var jump_button: Button = $JumpButton
@onready var sprint_button: Button = $SprintButton

var joystick_active: bool = false
var joystick_radius: float = 65.0
var joystick_knob: Panel

func _ready() -> void:
    # Fix for mobile browsers that emulate touch as mouse.
    Input.emulate_mouse_from_touch = true

    joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $Joystick/JoystickBase.mouse_filter = Control.MOUSE_FILTER_IGNORE

    jump_button.pressed.connect(request_jump)

    # RUN becomes a tap-to-toggle button.
    sprint_button.toggle_mode = true
    sprint_button.toggled.connect(_on_sprint_toggled)
    sprint_button.text = "RUN: OFF"

    # Create a visible joystick thumb.
    joystick_knob = Panel.new()
    joystick_knob.name = "JoystickThumb"
    joystick_knob.size = Vector2(56, 56)
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.25, 0.65, 1.0, 0.95)
    style.border_color = Color(1, 1, 1, 0.9)
    style.set_border_width_all(2)
    style.set_corner_radius_all(28)

    joystick_knob.add_theme_stylebox_override(
        "panel", style
    )

    joystick.add_child(joystick_knob)
    reset_joystick()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index != MOUSE_BUTTON_LEFT:
            return

        if event.pressed:
            if joystick.get_global_rect().has_point(event.position):
                joystick_active = true
                update_joystick(event.position)
        elif joystick_active:
            reset_joystick()

    elif event is InputEventMouseMotion:
        if joystick_active:
            update_joystick(event.position)

func update_joystick(pointer_position: Vector2) -> void:
    var center: Vector2 = joystick.get_global_rect().get_center()
    var offset: Vector2 = pointer_position - center

    movement = (offset / joystick_radius).limit_length(1.0)

    # Ignore tiny accidental movements.
    if movement.length() < 0.10:
        movement = Vector2.ZERO

    update_knob()

func update_knob() -> void:
    if is_instance_valid(joystick_knob):
        var center: Vector2 = joystick.size * 0.5

        joystick_knob.position = (
            center
            - joystick_knob.size * 0.5
            + movement * joystick_radius
        )

func reset_joystick() -> void:
    joystick_active = false
    movement = Vector2.ZERO
    update_knob()

func _on_sprint_toggled(enabled: bool) -> void:
    sprinting = enabled

    if enabled:
        sprint_button.text = "RUN: ON"
    else:
        sprint_button.text = "RUN: OFF"

func request_jump() -> void:
    jump_requested = true

func consume_jump() -> bool:
    if jump_requested:
        jump_requested = false
        return true

    return false

func release_controls() -> void:
    reset_joystick()
    sprint_button.button_pressed = false
    sprinting = false
    jump_requested = false

func _on_sprint_down() -> void:
    sprinting = true

func _on_sprint_up() -> void:
    sprinting = false
