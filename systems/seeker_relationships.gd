extends Node
# V0.44: role-specific, persistent social memory. All dialogue is GAME-ONLY.
# No romance, reward farming, ranks, secret access, or new story canon.
const FamilyV059 = preload("res://systems/young_blood_family_v059.gd")
const ROLES = {
    "npc_ring2_noodles": {"title": "NOODLE VENDOR", "duty": "Workers and Seekers share these streets long after sunset.", "thanks": "You noticed our work. I'll remember that kindness.", "refusal": "Treating the workers of this quarter poorly won't earn you a favor."},
    "npc_ring2_canal": {"title": "CANAL RESIDENT", "duty": "The blue-resonance canals and bronze lanterns serve this entire quarter.", "thanks": "It's reassuring when a Seeker listens to the people who live here.", "refusal": "The public waterways aren't yours to command."},
    "npc_ring2_register": {"title": "REGISTRATION CLERK", "duty": "The Association verifies records and certifications through proper channels.", "thanks": "Responsible visitors make this office easier to operate.", "refusal": "No paperwork or demand will grant an unearned Seeker rank."},
    "npc_ring2_medic": {"title": "MEDICAL INSTRUCTOR", "duty": "Responsible Aura recovery and safe training protect the entire squad.", "thanks": "A Seeker who takes recovery seriously helps keep others safe.", "refusal": "Ignoring exhaustion doesn't make a fighter stronger."},
    "npc_ring2_trainer": {"title": "SILVER TEAM INSTRUCTOR", "duty": "Our Silver squad practices timing, formations and communication.", "thanks": "You understand that teamwork matters as much as strength.", "refusal": "A disrespectful challenge tells me little about your actual skill."},
    "npc_ring2_soulwright": {"title": "SOULWRIGHT OFFICER", "duty": "The public stations teach observation and caution in field work.", "thanks": "Curiosity paired with restraint is worth encouraging.", "refusal": "Restricted records are unavailable to visitors."},
    "npc_ring2_sentry": {"title": "CITADEL PATROL SENTRY", "duty": "The public may use the approach, but the Citadel gate remains guarded.", "thanks": "Thank you for respecting the boundary. I'll remember your conduct.", "refusal": "Access denied. Pressuring a sentry won't change authorization."}
}
const TOPICS = [
    {"id": "work", "label": "Ask about their work", "change": 0, "reply": "duty"},
    {"id": "respect", "label": "Show respect for their duties", "change": 1, "reply": "thanks"},
    {"id": "demand", "label": "Demand special treatment", "change": -1, "reply": "refusal"}
]
var codex: Node
var panel: PanelContainer
var heading: Label
var greeting: Label
var reply: Label
var choices: VBoxContainer
var current_kind: String = ""
var current_name: String = ""

func _ready() -> void:
    add_to_group("seeker_relationships")
    call_deferred("_setup")

func _setup() -> void:
    codex = get_tree().get_first_node_in_group("personal_codex")
    var layer := CanvasLayer.new()
    layer.name = "SeekerConversationCanvas"
    layer.layer = 13
    get_parent().add_child(layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)
    panel = PanelContainer.new()
    panel.anchor_left = 0.19
    panel.anchor_right = 0.81
    panel.anchor_top = 0.15
    panel.anchor_bottom = 0.87
    panel.visible = false
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(0.055, 0.085, 0.15, 0.98)
    skin.border_color = Color(0.40, 0.71, 0.83)
    skin.set_border_width_all(3)
    panel.add_theme_stylebox_override("panel", skin)
    root.add_child(panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    panel.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 8)
    margin.add_child(stack)
    heading = Label.new()
    heading.add_theme_font_size_override("font_size", 23)
    stack.add_child(heading)
    greeting = Label.new()
    greeting.add_theme_font_size_override("font_size", 18)
    greeting.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(greeting)
    choices = VBoxContainer.new()
    choices.size_flags_vertical = Control.SIZE_EXPAND_FILL
    choices.add_theme_constant_override("separation", 7)
    stack.add_child(choices)
    reply = Label.new()
    reply.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    reply.add_theme_font_size_override("font_size", 18)
    stack.add_child(reply)
    var leave := Button.new()
    leave.text = "CONTINUE EXPLORING"
    leave.custom_minimum_size = Vector2(0, 46)
    leave.pressed.connect(_close)
    stack.add_child(leave)

func supports(kind: String) -> bool:
    return ROLES.has(kind)

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func open_dialogue(kind: String, display_name: String) -> void:
    if not supports(kind) or not is_instance_valid(panel):
        return
    if not is_instance_valid(codex):
        codex = get_tree().get_first_node_in_group("personal_codex")
    if not is_instance_valid(codex):
        return
    current_kind = kind
    current_name = display_name
    reply.text = "Choose a topic. This character will remember your response."
    _refresh_choices()
    panel.show()

func _refresh_choices() -> void:
    for node in choices.get_children():
        choices.remove_child(node)
        node.queue_free()
    var role: Dictionary = ROLES.get(current_kind, {})
    heading.text = str(role.get("title", current_name))
    var score: int = int(codex.call("get_contact_rapport", current_kind))
    var attitude: String = "acquainted"
    if score >= 2:
        attitude = "comfortable with you"
    elif score <= -2:
        attitude = "wary of you"
    elif score > 0:
        attitude = "warming up to you"
    elif score < 0:
        attitude = "cautious around you"
    greeting.text = "This resident remembers your conversations and is " + attitude + "."
    var profile: Dictionary = codex.get("profile")
    var family_response: String = FamilyV059.relationship_response(
        profile.get("family_v059", {}), current_kind)
    if not family_response.is_empty():
        greeting.text += "\n" + family_response
    for topic in TOPICS:
        var topic_id: String = str(topic["id"])
        var used: bool = bool(codex.call("has_social_choice", current_kind, topic_id))
        var button := Button.new()
        button.custom_minimum_size = Vector2(0, 49)
        button.add_theme_font_size_override("font_size", 17)
        button.text = ("DISCUSSED: " if used else "ASK: ") + str(topic["label"])
        button.disabled = used
        button.pressed.connect(_choose.bind(topic_id))
        choices.add_child(button)

func _choose(topic_id: String) -> void:
    var role: Dictionary = ROLES.get(current_kind, {})
    for topic in TOPICS:
        if str(topic["id"]) != topic_id:
            continue
        var answer: String = str(role.get(str(topic["reply"]), ""))
        var title: String = "Spoke to " + current_name + ": " + str(topic["label"])
        var recorded: bool = bool(codex.call("remember_social_choice", current_kind, current_name, topic_id, title, answer, int(topic["change"])))
        reply.text = (str(role.get("title", current_name)) + ": '" + answer + "'") if recorded else "That conversation is already part of your history."
        _refresh_choices()
        return

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()
