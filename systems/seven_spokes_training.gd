extends Node

# V0.46: supervised, GAME-ONLY simulations of the Seven Spokes.
# These are NOT trained abilities or permanent access to rare Arts.
# Celestial is an exceptional separate category, never in this cycle.
const SPOKES: Array[String] = [
    "Martial", "Elemental", "Spirit", "Alchemy", "Psychic", "Spatial", "Abyssal"
]
const COSTS: Array[int] = [14, 20, 18, 22, 21, 24, 28]
const COOLDOWNS: Array[float] = [0.8, 1.9, 3.0, 4.0, 3.6, 3.3, 5.0]
const DESCRIPTIONS: Array[String] = [
    "Close-range reinforcement strike", "Longer-range energy bolt",
    "Recover HP with a restorative pulse", "Absorb one incoming hit with a temporary ward",
    "Disrupt a sparring construct", "Short-range shift without crossing barriers",
    "Risky close-range impact with personal strain"
]
var current_index: int = 0
var cooldown_remaining: float = 0.0
var hub: Node
var arena: Node
var codex: Node
var player: CharacterBody3D
var mobile: Node
var style_button: Button
var art_button: Button
var caption: Label
var feedback: Label
var feedback_time: float = 0.0
var key_latched: bool = false

func _ready() -> void:
    add_to_group("spoke_training")
    call_deferred("_finish_setup")

static func specification(index: int) -> Dictionary:
    if index < 0 or index >= SPOKES.size():
        return {}
    return {"spoke": SPOKES[index], "cost": COSTS[index],
        "cooldown": COOLDOWNS[index], "description": DESCRIPTIONS[index],
        "training_only": true}

static func can_cast(index: int, aura: float, cooldown: float, at_training_ground: bool) -> bool:
    return not specification(index).is_empty() and aura >= float(COSTS[index]) and cooldown <= 0.0 and at_training_ground

func _finish_setup() -> void:
    hub = get_tree().get_first_node_in_group("hub_manager")
    arena = get_tree().get_first_node_in_group("combat_arena")
    codex = get_tree().get_first_node_in_group("personal_codex")
    mobile = get_tree().get_first_node_in_group("mobile_controls")
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    _make_ui()
    _refresh_ui()

func _process(delta: float) -> void:
    cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
    feedback_time = maxf(0.0, feedback_time - delta)
    var pressed: bool = Input.is_key_pressed(KEY_R)
    if pressed and not key_latched:
        _try_art()
    key_latched = pressed
    if is_instance_valid(feedback) and feedback_time <= 0.0:
        feedback.text = ""
    if is_instance_valid(art_button):
        art_button.text = "ART %.1fs" % cooldown_remaining if cooldown_remaining > 0.0 else "ART"

func _make_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "SupervisedMutiCanvas"
    layer.layer = 10
    get_parent().add_child(layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)
    style_button = Button.new()
    style_button.name = "CycleTrainingSpoke"
    style_button.text = "MUTI"
    style_button.offset_left = 775.0
    style_button.offset_top = 78.0
    style_button.offset_right = 895.0
    style_button.offset_bottom = 124.0
    style_button.add_theme_font_size_override("font_size", 19)
    style_button.pressed.connect(_next_style)
    root.add_child(style_button)
    caption = Label.new()
    caption.name = "TrainingStyleCaption"
    caption.offset_left = 902.0
    caption.offset_top = 87.0
    caption.offset_right = 1250.0
    caption.offset_bottom = 122.0
    caption.add_theme_font_size_override("font_size", 17)
    caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(caption)
    art_button = Button.new()
    art_button.name = "UseTrainingArt"
    art_button.offset_left = -397.0
    art_button.offset_top = -145.0
    art_button.offset_right = -285.0
    art_button.offset_bottom = -77.0
    art_button.anchor_left = 1.0
    art_button.anchor_top = 1.0
    art_button.anchor_right = 1.0
    art_button.anchor_bottom = 1.0
    art_button.text = "ART"
    art_button.add_theme_font_size_override("font_size", 20)
    art_button.pressed.connect(_try_art)
    root.add_child(art_button)
    feedback = Label.new()
    feedback.name = "TrainingArtFeedback"
    feedback.offset_left = 520.0
    feedback.offset_top = 169.0
    feedback.offset_right = 1260.0
    feedback.offset_bottom = 203.0
    feedback.add_theme_font_size_override("font_size", 18)
    feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(feedback)

func _next_style() -> void:
    current_index = (current_index + 1) % SPOKES.size()
    _refresh_ui()

func _refresh_ui() -> void:
    if is_instance_valid(caption):
        caption.text = "%s / TRAINING ONLY" % SPOKES[current_index]

func _announce(message: String) -> void:
    if is_instance_valid(feedback):
        feedback.text = message.substr(0, 110)
        feedback_time = 3.1

func _training_ground() -> bool:
    if not is_instance_valid(player):
        return false
    var where: Vector3 = player.global_position
    return absf(where.x) <= 11.3 and where.z >= -29.3 and where.z <= -16.1 and where.y < 6.0

func _try_art() -> void:
    if not is_instance_valid(player) or not is_instance_valid(hub) or not is_instance_valid(arena):
        return
    if not bool(hub.call("can_use_combat_actions")):
        return
    if not _training_ground():
        _announce("Basic Spoke simulations are available in the sparring yard only.")
        return
    if cooldown_remaining > 0.0:
        _announce("Technique recovering: %.1f s" % cooldown_remaining)
        return
    var cost: int = COSTS[current_index]
    if float(hub.get("aura")) < float(cost):
        _announce("Need %d Aura to practice %s." % [cost, SPOKES[current_index]])
        return
    var facing: Vector3 = -player.global_transform.basis.z
    if player.has_node("CameraPivot/Camera3D"):
        var camera: Camera3D = player.get_node("CameraPivot/Camera3D") as Camera3D
        facing = -camera.global_transform.basis.z
    facing.y = 0.0
    facing = facing.normalized()
    if facing.length_squared() < 0.01:
        facing = Vector3.FORWARD
    var result: Dictionary = arena.call("training_spoke_effect", SPOKES[current_index], facing)
    if not bool(result.get("ok", false)):
        _announce(str(result.get("message", "No available training target.")))
        return
    hub.set("aura", maxf(0.0, float(hub.get("aura")) - float(cost)))
    cooldown_remaining = COOLDOWNS[current_index]
    _announce("%s (-%d Aura): %s" % [SPOKES[current_index], cost, str(result.get("message", "Technique performed"))])
    if is_instance_valid(codex) and codex.has_method("record_event"):
        codex.call("record_event", "practice:spoke:%s" % SPOKES[current_index].to_lower(),
            "training_simulation", "Practiced the %s Spoke simulation" % SPOKES[current_index],
            "A supervised prototype drill. Does not grant Spoke mastery, inheritance, or an official Art.")
