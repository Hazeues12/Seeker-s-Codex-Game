extends Node3D
# One contextual public bulletin per game day, with actual consequences.
# The same Personal Codex JSON contains the choice, reputation and chronicle.
const Rules = preload("res://systems/city_routines_v051.gd")
const BULLETIN: Vector3 = Vector3(10.0, 0.55, 69.5)
var hub: Node
var codex: Node
var society: Node
var player: CharacterBody3D
var board: Node3D
var signal_light: MeshInstance3D
var panel: PanelContainer
var message_label: Label
var choices: VBoxContainer
var update_clock: float = 0.0
var visible_day: int = -1

func _ready() -> void:
    add_to_group("daily_events_v051")
    set_process(false)
    call_deferred("_setup")

func _setup() -> void:
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    society = get_tree().get_first_node_in_group("seeker_society")
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(player):
        push_warning("V0.51 bulletin requires the hub and Personal Codex")
        return
    _make_board()
    _make_dialogue()
    _refresh_light()
    set_process(true)

func _make_board() -> void:
    board = Node3D.new()
    board.name = "DailyCityBulletin"
    board.position = BULLETIN
    add_child(board)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.28, 0.30, 0.37)
    mat.roughness = 0.82
    var wooden := BoxMesh.new()
    wooden.size = Vector3(2.2, 1.8, 0.22)
    var stand := MeshInstance3D.new()
    stand.mesh = wooden
    stand.position = Vector3(0, 1.6, 0)
    stand.material_override = mat
    board.add_child(stand)
    var pole := MeshInstance3D.new()
    var pole_mesh := BoxMesh.new()
    pole_mesh.size = Vector3(0.18, 1.30, 0.18)
    pole.mesh = pole_mesh
    pole.position = Vector3(0, 0.72, 0)
    pole.material_override = mat
    board.add_child(pole)
    signal_light = MeshInstance3D.new()
    signal_light.name = "BulletinSignal"
    var lamp_mesh := SphereMesh.new()
    lamp_mesh.radius = 0.25
    lamp_mesh.height = 0.50
    signal_light.mesh = lamp_mesh
    signal_light.position = Vector3(0.0, 2.64, 0.0)
    board.add_child(signal_light)
    var label := Label3D.new()
    label.text = "CITY DUTY BULLETIN / TALK"
    label.position = Vector3(0.0, 3.0, 0.0)
    label.font_size = 34
    label.pixel_size = 0.006
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    board.add_child(label)
    if hub.has_method("_add_location"):
        hub.call("_add_location", "daily_v051_bulletin", "City Duty Bulletin", board.global_position, board)

func _make_dialogue() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 17
    layer.name = "CityBulletinCanvas"
    get_parent().add_child(layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)
    panel = PanelContainer.new()
    panel.anchor_left = 0.17
    panel.anchor_right = 0.83
    panel.anchor_top = 0.16
    panel.anchor_bottom = 0.88
    panel.visible = false
    root.add_child(panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_top", 14)
    margin.add_theme_constant_override("margin_bottom", 14)
    panel.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 10)
    margin.add_child(stack)
    var title := Label.new()
    title.text = "RING TWO / COMMUNITY DISPATCH"
    title.add_theme_font_size_override("font_size", 22)
    stack.add_child(title)
    message_label = Label.new()
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message_label.add_theme_font_size_override("font_size", 19)
    stack.add_child(message_label)
    var scrolling := ScrollContainer.new()
    scrolling.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_child(scrolling)
    choices = VBoxContainer.new()
    choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    choices.add_theme_constant_override("separation", 10)
    scrolling.add_child(choices)
    var close := Button.new()
    close.text = "RETURN TO MARGERINA"
    close.custom_minimum_size.y = 52
    close.pressed.connect(_close)
    stack.add_child(close)

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _day() -> int:
    return int(floor(float(hub.get("world_minutes")) / 1440.0)) + 1

func _saved() -> Dictionary:
    return codex.profile.get("daily_bulletin_v051", {})

func _prior_verified() -> bool:
    var social: Dictionary = codex.profile.get("society", {})
    var decisions: Dictionary = social.get("decisions", {})
    var expedition: Dictionary = codex.profile.get("expedition_v050", {})
    var completed: bool = str(expedition.get("stage", "")) == "complete"
    return decisions.has("civic:canal_incident") or decisions.has("field:public_quarter_watch") or completed or decisions.has("career:contract:0") or decisions.has("career:contract:1") or decisions.has("career:contract:2")

func _context() -> String:
    var social: Dictionary = codex.profile.get("society", {})
    var decisions: Dictionary = social.get("decisions", {})
    var expedition: Dictionary = codex.profile.get("expedition_v050", {})
    return Rules.bulletin_context(_day(), decisions.has("civic:canal_incident"), str(expedition.get("stage", "")) == "complete")

func _context_text(context: String) -> String:
    match context:
        "canal":
            return "Following the canal incident, residents are reviewing public safety and requesting practical help. Earlier decisions are still part of the Association's local record."
        "expedition":
            return "The waystation assignment has generated fresh public questions about road safety, recovery and trustworthy field observations."
        _:
            return "Workshops, market stalls and the public walkway need regular support. Your conduct today will be remembered by the quarter."

func interact(kind: String) -> void:
    if kind != "daily_v051_bulletin" or not is_instance_valid(panel):
        return
    if bool(codex.get("save_blocked")):
        _tell("Personal Codex storage is unavailable; choices are disabled to protect the save.")
        return
    var day: int = _day()
    var context: String = _context()
    for child in choices.get_children():
        choices.remove_child(child)
        child.queue_free()
    if Rules.already_answered(_saved(), day):
        var days: Dictionary = _saved().get("days", {})
        var previous: Dictionary = days.get(Rules.day_key(day), {})
        message_label.text = "Day %d: your choice has already been recorded.\n%s" % [day, str(previous.get("choice", ""))]
    else:
        message_label.text = "Day %d — %s\n\n%s" % [day, context.capitalize(), _context_text(context)]
        _option("assist", "Join the public-service effort (helps civic trust)", true)
        _option("report", "File a verified observation (professional trust)", _prior_verified())
        _option("shortcut", "Accept an unverified fixer's shortcut (misconduct)", true)
    panel.show()

func _option(id: String, caption: String, enabled: bool) -> void:
    var button := Button.new()
    button.text = caption if enabled else caption + " — requires actual field records"
    button.disabled = not enabled
    button.custom_minimum_size.y = 55.0
    button.add_theme_font_size_override("font_size", 18)
    button.pressed.connect(_choose.bind(id))
    choices.add_child(button)

func _choose(choice: String) -> void:
    if bool(codex.get("save_blocked")):
        _close()
        return
    var day: int = _day()
    var context: String = _context()
    var result: Dictionary = Rules.response(_saved(), day, context, choice, _prior_verified())
    if result.is_empty():
        _tell("That choice is unavailable or was already recorded today.")
        _close()
        return
    var social: Dictionary = codex.profile.get("society", {})
    var rep: Dictionary = social.get("reputation", {})
    var changes: Dictionary = result.get("reputation", {})
    for key in changes:
        rep[key] = clampi(int(rep.get(key, 0)) + int(changes[key]), -20, 20)
    social["reputation"] = rep
    codex.profile["society"] = social
    codex.profile["daily_bulletin_v051"] = result["state"]
    var summary: String = ""
    match choice:
        "assist": summary = "Volunteered for the public service shift. Neighborhood respect and reliability improved."
        "report": summary = "Filed verified observations based on earlier field work. Professional trust improved."
        "shortcut": summary = "Accepted an unverified shortcut. Association trust fell and underworld attention rose."
    codex.call("record_event", "v051:bulletin:day_%d" % day, "city_event", "Day %d: public-quarter decision" % day, summary)
    codex.call("_save_profile")
    _tell(summary)
    _close()
    _refresh_light()

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()

func _refresh_light() -> void:
    if not is_instance_valid(signal_light) or not is_instance_valid(codex) or not is_instance_valid(hub):
        return
    var covered: bool = Rules.already_answered(_saved(), _day())
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.25, 0.65, 0.40) if covered else Color(0.91, 0.70, 0.29)
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    signal_light.material_override = mat

func _process(delta: float) -> void:
    update_clock += delta
    if update_clock < 0.8:
        return
    update_clock = 0.0
    if _day() != visible_day:
        visible_day = _day()
        _refresh_light()

func _tell(message: String) -> void:
    if is_instance_valid(hub) and hub.has_method("_announce"):
        hub.call("_announce", message)
