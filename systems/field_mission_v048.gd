extends Node3D

# V0.48 field assignment is GAME-ONLY content within the existing Ring Two prototype.
# Companion, hostile construct, and dialogue are not official novel characters.
const Rules = preload("res://systems/field_rules_v048.gd")
const Construct = preload("res://combat/sparring_construct.gd")
const MISSION_ID: String = "public_quarter_field_watch"
const REWARD_TOLA: int = 22
const DISPATCH: Vector3 = Vector3(17.0, 0.55, 72.0)
const CHECKPOINT: Vector3 = Vector3(15.0, 0.55, 84.0)
const THREAT: Vector3 = Vector3(12.0, 0.55, 94.0)
const CIVILIAN: Vector3 = Vector3(16.0, 0.55, 101.0)
const EVIDENCE: Vector3 = Vector3(8.0, 0.55, 101.0)

var hub: Node
var codex: Node
var society: Node
var arena: Node
var player: CharacterBody3D
var state: Dictionary = {}
var enemy: CharacterBody3D
var companion: Node3D
var companion_support_wait: float = 0.0
var update_clock: float = 0.0
var panel: PanelContainer
var message_label: Label
var selection_buttons: VBoxContainer
var saved_status: Label3D
var visual_markers: Dictionary = {}

func _ready() -> void:
    add_to_group("field_mission_v048")
    call_deferred("_setup")

func _setup() -> void:
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    society = get_tree().get_first_node_in_group("seeker_society")
    arena = get_tree().get_first_node_in_group("combat_arena")
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(player):
        push_warning("Field watch requires hub, Personal Codex and player")
        return
    if bool(codex.get("save_blocked")):
        push_warning("Existing Codex unreadable; field watch stays disabled to protect progress")
        return
    state = Rules.sanitize(codex.profile.get("field_mission_v048", {}))
    _make_markers()
    _make_companion()
    _make_panel()
    _ensure_state_visuals()
    if str(state.get("stage", "")) == "complete":
        _reconcile_completion()
    set_process(true)

func _make_markers() -> void:
    _marker("field_v048_dispatch", "FIELD WATCH / DISPATCH", DISPATCH, Color(0.30, 0.64, 0.84))
    _marker("field_v048_checkpoint", "FIELD WATCH / CHECKPOINT", CHECKPOINT, Color(0.71, 0.58, 0.27))
    _marker("field_v048_civilian", "FIELD WATCH / CIVILIAN", CIVILIAN, Color(0.32, 0.78, 0.66))
    _marker("field_v048_evidence", "FIELD WATCH / EVIDENCE", EVIDENCE, Color(0.86, 0.65, 0.35))
    saved_status = Label3D.new()
    saved_status.name = "FieldWatchStatus"
    saved_status.position = DISPATCH + Vector3(0, 3.2, 0)
    saved_status.font_size = 31
    saved_status.pixel_size = 0.006
    saved_status.no_depth_test = true
    saved_status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(saved_status)

func _marker(key: String, title: String, world_at: Vector3, color: Color) -> void:
    var anchor := Node3D.new()
    anchor.name = key
    anchor.position = world_at
    add_child(anchor)
    var model := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.18
    mesh.bottom_radius = 0.36
    mesh.height = 1.25
    model.mesh = mesh
    model.position = Vector3(0, 0.64, 0)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    model.material_override = mat
    model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    anchor.add_child(model)
    var label := Label3D.new()
    label.text = title
    label.position = Vector3(0, 2.25, 0)
    label.font_size = 26
    label.pixel_size = 0.005
    label.no_depth_test = true
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    anchor.add_child(label)
    visual_markers[key] = anchor
    hub.call("_add_location", key, title, anchor.global_position, anchor)

func _make_companion() -> void:
    companion = Node3D.new()
    companion.name = "VolunteerPatrolPartner"
    companion.position = DISPATCH + Vector3(-1.0, 0, 0)
    add_child(companion)
    var coat := StandardMaterial3D.new()
    coat.albedo_color = Color(0.28, 0.47, 0.65)
    _box(companion, "PatrolTunic", Vector3(0, 1.25, 0), Vector3(0.67, 0.89, 0.44), coat)
    _box(companion, "PatrolHead", Vector3(0, 1.98, 0), Vector3(0.42, 0.49, 0.42), coat)
    for side in [-1.0, 1.0]:
        _box(companion, "Leg", Vector3(side * 0.19, 0.48, 0), Vector3(0.24, 0.80, 0.30), coat)
    var label := Label3D.new()
    label.text = "VOLUNTEER PATROL PARTNER / GAME-ONLY"
    label.position = Vector3(0, 2.55, 0)
    label.font_size = 26
    label.pixel_size = 0.005
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    companion.add_child(label)

func _box(parent: Node3D, title: String, offset: Vector3, size: Vector3, mat: Material) -> void:
    var part := MeshInstance3D.new()
    part.name = title
    var mesh := BoxMesh.new()
    mesh.size = size
    part.mesh = mesh
    part.position = offset
    part.material_override = mat
    part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(part)

func _make_panel() -> void:
    var layer := CanvasLayer.new()
    layer.name = "FieldWatchDialogue"
    layer.layer = 15
    get_parent().add_child(layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)
    panel = PanelContainer.new()
    panel.anchor_left = 0.15
    panel.anchor_right = 0.85
    panel.anchor_top = 0.16
    panel.anchor_bottom = 0.86
    panel.visible = false
    root.add_child(panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_top", 20)
    margin.add_theme_constant_override("margin_bottom", 20)
    panel.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 11)
    margin.add_child(stack)
    var heading := Label.new()
    heading.text = "PUBLIC FIELD WATCH / PROTOTYPE"
    heading.add_theme_font_size_override("font_size", 25)
    stack.add_child(heading)
    message_label = Label.new()
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message_label.add_theme_font_size_override("font_size", 20)
    stack.add_child(message_label)
    selection_buttons = VBoxContainer.new()
    selection_buttons.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_child(selection_buttons)
    var leave := Button.new()
    leave.text = "RETURN TO THE STREET"
    leave.custom_minimum_size.y = 48.0
    leave.pressed.connect(_close_panel)
    stack.add_child(leave)

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _open_panel(prompt: String, choices: Array[Dictionary]) -> void:
    message_label.text = prompt
    for old in selection_buttons.get_children():
        selection_buttons.remove_child(old)
        old.queue_free()
    for choice in choices:
        var button := Button.new()
        button.text = str(choice["label"])
        button.custom_minimum_size.y = 55.0
        button.add_theme_font_size_override("font_size", 19)
        button.pressed.connect(_act.bind(str(choice["action"])))
        selection_buttons.add_child(button)
    panel.show()

func _close_panel() -> void:
    if is_instance_valid(panel):
        panel.hide()

func interact(kind: String) -> void:
    if not is_instance_valid(codex) or bool(codex.get("save_blocked")):
        return
    var stage: String = str(state.get("stage", "available"))
    match kind:
        "field_v048_dispatch":
            if stage == "available":
                _open_panel("Join a volunteer patrol along the professional precinct. A partner will accompany you. This does not grant Seeker rank.", [{"action":"accept", "label":"Accept supervised field watch"}])
            elif stage == "debrief":
                _open_panel("Your companion has returned. Submit your report to record the outcome and receive one assignment payment.", [{"action":"report", "label":"File report and collect field pay"}])
            elif stage == "complete":
                _tell("Filed report: %s. The assignment has already paid out." % str(state.get("choice", "")))
            else:
                _tell("Continue the field watch. Your partner is keeping pace.")
        "field_v048_checkpoint":
            if stage == "patrol":
                _open_panel("Your partner spots a rogue training automaton obstructing the route. Engage and disable it without harming residents.", [{"action":"checkpoint", "label":"Proceed with defensive engagement"}])
            else:
                _tell("This checkpoint has already been surveyed or is not yet assigned.")
        "field_v048_civilian":
            if stage == "response":
                _open_panel("The automaton is disabled. A shaken civilian needs assistance. Helping them means leaving evidence unsecured for now.", [{"action":"protect_civilians", "label":"Help the civilian first"}])
            else:
                _tell("There is nobody currently requesting help here.")
        "field_v048_evidence":
            if stage == "response":
                _open_panel("An evidence container could explain why the automaton was loose. Securing it now may leave the civilian waiting.", [{"action":"secure_evidence", "label":"Secure the evidence first"}])
            else:
                _tell("Evidence is not ready to be collected.")

func _act(action: String) -> void:
    _close_panel()
    var next: Dictionary = Rules.advance(state, action)
    if next.is_empty() or not is_instance_valid(codex) or bool(codex.get("save_blocked")):
        _tell("This decision is unavailable or already recorded.")
        return
    state = next
    codex.profile["field_mission_v048"] = state.duplicate(true)
    codex.call("_save_profile")
    _ensure_state_visuals()
    if action == "report":
        _reconcile_completion()
    else:
        var messages := {"accept":"A volunteer joins your patrol. Visit the checkpoint along the avenue.",
            "checkpoint":"The automaton is active. Disable it with your trained combat actions.",
            "protect_civilians":"Civilian aid recorded. Return to the dispatch marker.",
            "secure_evidence":"Evidence secured. Return to the dispatch marker."}
        _tell(str(messages.get(action, "Field journal updated.")))

func _enemy_knocked_out() -> void:
    if str(state.get("stage", "")) != "engage":
        return
    _act("enemy_defeated")
    _tell("Threat disabled! Decide between protecting the civilian or securing evidence.")

func _ensure_state_visuals() -> void:
    var stage: String = str(state.get("stage", "available"))
    if is_instance_valid(companion):
        companion.visible = stage in ["patrol", "engage", "response", "debrief"]
    if is_instance_valid(saved_status):
        saved_status.text = "FIELD WATCH: " + stage.to_upper().replace("_", " ")
    if visual_markers.has("field_v048_checkpoint"):
        visual_markers["field_v048_checkpoint"].visible = stage == "patrol"
        visual_markers["field_v048_civilian"].visible = stage == "response"
        visual_markers["field_v048_evidence"].visible = stage == "response"
    if stage == "engage" and not is_instance_valid(enemy):
        _spawn_enemy()
    elif stage != "engage" and is_instance_valid(enemy):
        if is_instance_valid(arena) and arena.has_method("unregister_field_enemy"):
            arena.call("unregister_field_enemy", enemy)
        enemy.queue_free()
        enemy = null

func _spawn_enemy() -> void:
    enemy = Construct.new()
    enemy.name = "UncontrolledPracticeAutomaton"
    add_child(enemy)
    enemy.call("configure", player, "ROGUE TRAINING AUTOMATON", THREAT, 2.0)
    enemy.call("set_patrol_bounds", Vector2(7.0, 17.5), Vector2(85.0, 103.0))
    enemy.connect("knocked_out", _enemy_knocked_out)
    if is_instance_valid(arena) and arena.has_method("register_field_enemy"):
        arena.call("register_field_enemy", enemy)

func _process(delta: float) -> void:
    var stage: String = str(state.get("stage", "available"))
    if stage not in ["patrol", "engage", "response", "debrief"] or not is_instance_valid(player):
        return
    update_clock += delta
    companion_support_wait = maxf(0.0, companion_support_wait - delta)
    if not is_instance_valid(companion):
        return
    var desired: Vector3 = player.global_position + Vector3(-1.55, 0, -1.25)
    desired.y = 0.55
    var distance: float = companion.global_position.distance_to(desired)
    if distance > 30.0:
        companion.global_position = desired
    elif distance > 1.7:
        companion.global_position = companion.global_position.move_toward(desired, minf(3.7 * delta, distance))
    if stage == "engage" and is_instance_valid(enemy) and bool(enemy.call("is_active")) and companion_support_wait <= 0.0:
        if companion.global_position.distance_to(enemy.global_position) < 4.6 and player.global_position.distance_to(enemy.global_position) < 11.0:
            companion_support_wait = 5.0
            enemy.call("take_strike", 8, companion.global_position)
            _tell("Your patrol partner assists with a restrained Martial strike.")

func _reconcile_completion() -> void:
    if str(state.get("stage", "")) != "complete":
        return
    var choice: String = str(state.get("choice", ""))
    if not Rules.CHOICES.has(choice):
        return
    var s: Dictionary = codex.profile.get("society", {})
    var decisions: Dictionary = s.get("decisions", {})
    if not decisions.has("field:public_quarter_watch"):
        decisions["field:public_quarter_watch"] = choice
        s["decisions"] = decisions
        var rep: Dictionary = s.get("reputation", {})
        var delta: Dictionary = {"association_trust": 1, "local_respect": 2} if choice == "protect_civilians" else {"association_trust": 1, "guild_reliability": 2, "local_respect": -1}
        for key in delta:
            rep[key] = clampi(int(rep.get(key, 0)) + int(delta[key]), -20, 20)
        s["reputation"] = rep
        codex.profile["society"] = s
        codex.call("record_event", "v048:field:report", "field_assignment", "Completed public-quarter field watch", "Chose %s alongside a volunteer. Game-only field assignment." % choice)
        codex.call("_save_profile")
    if is_instance_valid(hub) and hub.has_method("award_field_payout_once"):
        hub.call("award_field_payout_once", MISSION_ID, REWARD_TOLA)
        if not bool(state.get("paid", false)):
            state["paid"] = true
            codex.profile["field_mission_v048"] = state.duplicate(true)
            codex.call("_save_profile")
    _tell("Field watch complete: %s. Association record updated; payment available once." % choice)

func _tell(message: String) -> void:
    if is_instance_valid(hub) and hub.has_method("_announce"):
        hub.call("_announce", message)
