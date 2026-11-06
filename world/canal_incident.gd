extends Node3D

# V0.47 public-quarter side incident, GAME_ONLY. No fictional story canon asserted.
# A small reactive scenario linking movement, civic action, professional record.
const INCIDENT_ID: String = "canal_incident"
const OUTCOMES: Array[String] = ["rescue_worker", "recover_cargo", "leave_scene"]
var hub: Node
var player: CharacterBody3D
var codex: Node
var society: Node
var notice_light: MeshInstance3D
var cargo_mesh: MeshInstance3D
var panel: PanelContainer
var content: Label
var choices: VBoxContainer
var current_site: String = ""

static func can_start(stage: String) -> bool:
    return stage == "unstarted"

static func can_resolve(stage: String, outcome: String) -> bool:
    return stage == "active" and OUTCOMES.has(outcome)

static func consequences(outcome: String) -> Dictionary:
    match outcome:
        "rescue_worker":
            return {"association_trust": 1, "local_respect": 2}
        "recover_cargo":
            return {"guild_reliability": 2, "local_respect": -1}
        "leave_scene":
            return {"local_respect": -1, "guild_reliability": -1}
        _:
            return {}

func _ready() -> void:
    add_to_group("canal_incident")
    call_deferred("_finish_setup")

func _finish_setup() -> void:
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    society = get_tree().get_first_node_in_group("seeker_society")
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(player) or not is_instance_valid(hub) or not is_instance_valid(codex):
        return
    _build_scene()
    _build_panel()
    _refresh_visuals()

func _state() -> Dictionary:
    if not is_instance_valid(codex):
        return {"stage": "unstarted", "outcome": ""}
    var events: Dictionary = codex.profile.get("civic_events", {})
    return events.get(INCIDENT_ID, {"stage": "unstarted", "outcome": ""})

func _stage() -> String:
    return str(_state().get("stage", "unstarted"))

func _save_active() -> void:
    if not is_instance_valid(codex) or bool(codex.get("save_blocked")):
        return
    var state: Dictionary = _state()
    if not can_start(str(state.get("stage", "unstarted"))):
        return
    var events: Dictionary = codex.profile.get("civic_events", {})
    events[INCIDENT_ID] = {"stage": "active", "outcome": ""}
    codex.profile["civic_events"] = events
    codex.call("record_event", "incident:canal:start", "civic_incident",
        "Responded to a canal-side emergency", "Agreed to assess a worker and a shipment in Ring Two's public quarter.")
    codex.call("_save_profile")

func _build_scene() -> void:
    _marker("incident_board", "CANAL NOTICE / PRESS TALK", Vector3(2.3, 0.55, 41.0), Color(0.47, 0.37, 0.23))
    _marker("incident_worker", "STRANDED CIVILIAN / PRESS TALK", Vector3(-2.1, 0.55, 52.5), Color(0.36, 0.61, 0.68))
    _marker("incident_cargo", "CARGO / PRESS TALK", Vector3(3.2, 0.55, 60.5), Color(0.69, 0.47, 0.27))
    notice_light = _box(self, "IncidentSignal", Vector3(2.3, 3.1, 41.0),
        Vector3(0.55, 0.55, 0.55), Color(0.93, 0.35, 0.24))
    cargo_mesh = _box(self, "SealedSupplyCrate", Vector3(3.2, 1.05, 60.5),
        Vector3(1.25, 0.96, 1.1), Color(0.58, 0.37, 0.24))

func _box(parent: Node3D, title: String, position: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    mesh.name = title
    var geometry := BoxMesh.new()
    geometry.size = dimensions
    mesh.mesh = geometry
    mesh.position = position
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.77
    mesh.material_override = mat
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(mesh)
    return mesh

func _marker(identifier: String, title: String, at: Vector3, color: Color) -> void:
    var marker := Node3D.new()
    marker.name = identifier
    marker.position = at
    add_child(marker)
    _box(marker, "PlaceMarker", Vector3(0.0, 1.05, 0.0), Vector3(0.62, 1.50, 0.44), color)
    var label := Label3D.new()
    label.text = title
    label.position = Vector3(0.0, 2.2, 0.0)
    label.font_size = 30
    label.pixel_size = 0.0058
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    marker.add_child(label)
    if hub.has_method("_add_location"):
        hub.call("_add_location", identifier, title, marker.global_position, marker)

func _build_panel() -> void:
    var layer := CanvasLayer.new()
    layer.name = "CanalIncidentHud"
    layer.layer = 13
    get_parent().add_child(layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)
    panel = PanelContainer.new()
    panel.anchor_left = 0.22
    panel.anchor_right = 0.78
    panel.anchor_top = 0.17
    panel.anchor_bottom = 0.85
    panel.visible = false
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(0.07, 0.10, 0.14, 0.97)
    skin.border_color = Color(0.56, 0.75, 0.76)
    skin.set_border_width_all(2)
    panel.add_theme_stylebox_override("panel", skin)
    root.add_child(panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_top", 14)
    margin.add_theme_constant_override("margin_bottom", 14)
    panel.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 8)
    margin.add_child(stack)
    var heading := Label.new()
    heading.text = "RING TWO / CIVIC INCIDENT"
    heading.add_theme_font_size_override("font_size", 24)
    stack.add_child(heading)
    content = Label.new()
    content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_theme_font_size_override("font_size", 18)
    stack.add_child(content)
    choices = VBoxContainer.new()
    choices.size_flags_vertical = Control.SIZE_EXPAND_FILL
    choices.add_theme_constant_override("separation", 7)
    stack.add_child(choices)
    var exit := Button.new()
    exit.text = "CONTINUE EXPLORING"
    exit.custom_minimum_size.y = 50.0
    exit.pressed.connect(_close)
    stack.add_child(exit)

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func interact(id: String) -> void:
    if not id.begins_with("incident_") or not is_instance_valid(panel):
        return
    current_site = id
    _refresh_choices()
    panel.show()

func _choice(title: String, action: String) -> void:
    var b := Button.new()
    b.text = title
    b.custom_minimum_size.y = 56.0
    b.pressed.connect(_choose.bind(action))
    choices.add_child(b)

func _refresh_choices() -> void:
    for b in choices.get_children():
        choices.remove_child(b)
        b.queue_free()
    var state: String = _stage()
    if state == "resolved":
        var outcome: String = str(_state().get("outcome", ""))
        content.text = "Recorded incident outcome: %s. Your professional record and this public signal retain the decision. No further reward can be claimed." % outcome.replace("_", " ")
        return
    if state == "unstarted":
        content.text = "A canal-side alarm reports a civilian in distress and a supply shipment at risk. Accepting the notice begins a small public-duty incident. This is game-only prototype content."
        if current_site == "incident_board":
            _choice("ACCEPT / INVESTIGATE", "start")
        return
    if current_site == "incident_worker":
        content.text = "The trapped worker needs help. You can intervene here, or leave and prioritize the shipment instead. Only one resolution will be recorded."
        _choice("HELP THE CIVILIAN / protect life", "rescue_worker")
    elif current_site == "incident_cargo":
        content.text = "The supply crate is intact. Securing it would keep the registered delivery on schedule, but the civilian still needs assistance."
        _choice("SECURE THE CARGO / prioritize delivery", "recover_cargo")
    else:
        content.text = "Incident active. Investigate the civilian near z=52 or the shipment near z=60. You may withdraw, with a lasting effect on your neighborhood record."
        _choice("WITHDRAW / leave the incident unresolved", "leave_scene")

func _choose(action: String) -> void:
    if action == "start":
        _save_active()
        _refresh_choices()
        _refresh_visuals()
        return
    if not can_resolve(_stage(), action):
        return
    if not is_instance_valid(society):
        society = get_tree().get_first_node_in_group("seeker_society")
    if not is_instance_valid(society) or not society.has_method("record_civic_response"):
        content.text = "Professional records unavailable; the incident was not submitted."
        return
    if not bool(society.call("record_civic_response", action)):
        content.text = "This outcome was already recorded or could not be saved."
        return
    _refresh_choices()
    _refresh_visuals()

func _refresh_visuals() -> void:
    if not is_instance_valid(notice_light) or not is_instance_valid(cargo_mesh):
        return
    var state: String = _stage()
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.94, 0.35, 0.25) if state == "unstarted" else Color(0.94, 0.72, 0.21)
    if state == "resolved":
        mat.albedo_color = Color(0.29, 0.81, 0.63) if str(_state().get("outcome", "")) == "rescue_worker" else Color(0.43, 0.61, 0.84)
    notice_light.material_override = mat
    cargo_mesh.visible = not (state == "resolved" and str(_state().get("outcome", "")) == "recover_cargo")

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()
