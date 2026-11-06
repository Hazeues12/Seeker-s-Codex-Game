extends Node

# V0.45 optional dialogue outcomes, pricing, courtship, jobs, and misconduct.
# Replaces only the V0.44 conversation UI; historic save data remains intact.
var society: Node
var codex: Node
var panel: PanelContainer
var heading: Label
var greeting: Label
var reply: Label
var choice_list: VBoxContainer
var current_kind: String = ""
var current_name: String = ""

func _ready() -> void:
    add_to_group("seeker_relationships")
    call_deferred("_setup")

func _setup() -> void:
    society = get_tree().get_first_node_in_group("seeker_society")
    codex = get_tree().get_first_node_in_group("personal_codex")
    var layer := CanvasLayer.new()
    layer.name = "ConsequentialDialogueLayer"
    layer.layer = 13
    get_parent().add_child(layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)
    panel = PanelContainer.new()
    panel.anchor_left = 0.14
    panel.anchor_right = 0.86
    panel.anchor_top = 0.08
    panel.anchor_bottom = 0.90
    panel.visible = false
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(0.035, 0.065, 0.11, 0.98)
    skin.border_color = Color(0.46, 0.70, 0.82)
    skin.set_border_width_all(3)
    skin.set_corner_radius_all(11)
    panel.add_theme_stylebox_override("panel", skin)
    root.add_child(panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 17)
    margin.add_theme_constant_override("margin_right", 17)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 14)
    panel.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 7)
    margin.add_child(stack)
    heading = Label.new()
    heading.add_theme_font_size_override("font_size", 25)
    stack.add_child(heading)
    greeting = Label.new()
    greeting.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    greeting.add_theme_font_size_override("font_size", 16)
    stack.add_child(greeting)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_child(scroll)
    choice_list = VBoxContainer.new()
    choice_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    choice_list.add_theme_constant_override("separation", 6)
    scroll.add_child(choice_list)
    reply = Label.new()
    reply.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    reply.add_theme_font_size_override("font_size", 18)
    reply.custom_minimum_size.y = 62
    stack.add_child(reply)
    var leave := Button.new()
    leave.text = "LEAVE CONVERSATION"
    leave.custom_minimum_size = Vector2(0, 48)
    leave.pressed.connect(_close)
    stack.add_child(leave)

func supports(kind: String) -> bool:
    if not is_instance_valid(society):
        society = get_tree().get_first_node_in_group("seeker_society")
    return is_instance_valid(society) and bool(society.call("supports", kind))

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func open_dialogue(kind: String, display_name: String) -> void:
    if not supports(kind) or not is_instance_valid(panel):
        return
    codex = get_tree().get_first_node_in_group("personal_codex")
    if not is_instance_valid(codex):
        return
    current_kind = kind
    current_name = display_name
    reply.text = "Your decisions can change what this resident remembers and how your Seeker is regarded."
    panel.show()
    _refresh_options()

func _refresh_options() -> void:
    for old in choice_list.get_children():
        choice_list.remove_child(old)
        old.queue_free()
    if not is_instance_valid(society) or not is_instance_valid(codex):
        return
    var score: int = int(codex.call("get_contact_rapport", current_kind))
    var status: String = str(society.call("get_romance_status", current_kind))
    heading.text = current_name.to_upper() + "  |  MAGNARA RING TWO"
    greeting.text = "Rapport: %d  |  %s\n%s\n%s" % [score,
        ("Personal relationship: " + status) if not status.is_empty() else "Professional / social acquaintance",
        str(society.call("get_reputation_summary")),
        str(society.call("get_npc_reaction", current_kind))]
    for option in society.call("options_for", current_kind):
        var button := Button.new()
        button.custom_minimum_size = Vector2(0, 46)
        button.add_theme_font_size_override("font_size", 17)
        var available: bool = bool(option.get("available", false))
        var reason: String = str(option.get("reason", ""))
        button.text = str(option.get("label", "Action"))
        if not available and not reason.is_empty():
            button.text += " [" + reason + "]"
        button.disabled = not available
        button.pressed.connect(_choose.bind(str(option.get("id", ""))))
        choice_list.add_child(button)
    if choice_list.get_child_count() == 0:
        var empty := Label.new()
        empty.text = "No further choices here at present. Continue exploring the neighborhood."
        empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        choice_list.add_child(empty)

func _choose(option_id: String) -> void:
    if not is_instance_valid(society):
        return
    var result: Dictionary = society.call("act", current_kind, option_id)
    reply.text = str(result.get("message", "No response was recorded."))
    _refresh_options()

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()
