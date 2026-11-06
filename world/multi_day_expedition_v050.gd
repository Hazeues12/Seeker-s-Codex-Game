extends Node3D
# V0.50 GAME-ONLY public waystation assignment. Off-city map and scenic carriage.
# This is a vertical slice, not a new canon route or official Seeker examination.
const Rules = preload("res://systems/expedition_rules_v050.gd")
const Construct = preload("res://combat/sparring_construct.gd")
const RECEIPT: String = "waystation_convoy_v050"
const PAYOUT: int = 30
const DISPATCH: Vector3 = Vector3(20.0, 0.55, 67.0)
const CAMP: Vector3 = Vector3(278.0, 0.55, 85.0)
const THREAT: Vector3 = Vector3(288.0, 0.55, 88.0)
const CIVILIAN: Vector3 = Vector3(290.0, 0.55, 96.0)
const DOCUMENTS: Vector3 = Vector3(290.0, 0.55, 78.0)
const TRIP_SECONDS: float = 9.0

var hub: Node
var codex: Node
var arena: Node
var player: CharacterBody3D
var state: Dictionary = {}
var panel: PanelContainer
var message: Label
var options: VBoxContainer
var title_label: Label3D
var waystation: Node3D
var carriage: Node3D
var volunteer: Node3D
var enemy: CharacterBody3D
var location_nodes: Dictionary = {}
var riding: bool = false
var ride_clock: float = 0.0
var support_clock: float = 0.0

func _ready() -> void:
    add_to_group("multi_day_expedition_v050")
    set_process(false)
    call_deferred("_setup")

func _setup() -> void:
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    arena = get_tree().get_first_node_in_group("combat_arena")
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(player):
        push_warning("V0.50 expedition requires hub, Codex and player")
        return
    if bool(codex.get("save_blocked")):
        push_warning("V0.50 disabled: existing Personal Codex could not be loaded")
        return
    state = Rules.sanitize(codex.profile.get("expedition_v050", {}))
    _make_route()
    _make_panel()
    _set_visuals()
    var stage: String = str(state["stage"])
    if stage in ["outbound", "return_trip"]:
        _start_ride()
    elif stage in ["waystation", "rested", "engage", "response", "return_ready"]:
        _move_player_to_camp()
    elif stage in ["debrief", "complete"]:
        _move_player_to_city_if_remote()
    if stage == "complete":
        _settle_report()
    set_process(true)

func _add_marker(id: String, label: String, at: Vector3, color: Color) -> void:
    var marker := Node3D.new()
    marker.name = id
    marker.position = at
    add_child(marker)
    _part(marker, "Marker", Vector3(0, 0.73, 0), Vector3(0.44, 1.45, 0.44), color)
    var tag := Label3D.new()
    tag.text = label
    tag.position = Vector3(0, 2.15, 0)
    tag.font_size = 28
    tag.pixel_size = 0.0055
    tag.no_depth_test = true
    tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    marker.add_child(tag)
    hub.call("_add_location", id, label, at, marker)
    location_nodes[id] = marker

func _mat(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.83
    return mat

func _part(parent: Node3D, label: String, at: Vector3, dimensions: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    mesh.name = label
    var shape := BoxMesh.new()
    shape.size = dimensions
    mesh.mesh = shape
    mesh.material_override = _mat(color)
    mesh.position = at
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(mesh)
    if solid:
        var body := StaticBody3D.new()
        body.name = label + "Collision"
        mesh.add_child(body)
        var collision := CollisionShape3D.new()
        var volume := BoxShape3D.new()
        volume.size = dimensions
        collision.shape = volume
        body.add_child(collision)
    return mesh

func _make_route() -> void:
    _add_marker("exp_v050_dispatch", "CARRIAGE DISPATCH / TALK", DISPATCH, Color(0.35, 0.58, 0.77))
    _add_marker("exp_v050_camp", "PUBLIC WAYSTATION / TALK", CAMP, Color(0.54, 0.67, 0.46))
    _add_marker("exp_v050_threat", "WAYSTATION WATCH / TALK", Vector3(279.0, 0.55, 90.5), Color(0.85, 0.55, 0.32))
    _add_marker("exp_v050_civilian", "WAYSTATION WORKER / TALK", CIVILIAN, Color(0.33, 0.72, 0.68))
    _add_marker("exp_v050_documents", "WAYSTATION RECORDS / TALK", DOCUMENTS, Color(0.79, 0.73, 0.39))
    _add_marker("exp_v050_return", "RETURN CARRIAGE / TALK", Vector3(269.0, 0.55, 85.0), Color(0.45, 0.60, 0.84))
    waystation = Node3D.new()
    waystation.name = "TemporaryRouteAndWaystation"
    add_child(waystation)
    # One local game-only corridor; no attempt to draw the entire Margerina atlas.
    _part(waystation, "TravelGround", Vector3(241.0, 0.0, 85.0), Vector3(130.0, 1.0, 43.0), Color(0.39, 0.49, 0.34), true)
    _part(waystation, "CarriageRoad", Vector3(242.0, 0.535, 85.0), Vector3(122.0, 0.07, 5.0), Color(0.68, 0.60, 0.46))
    _part(waystation, "WaystationHut", Vector3(279.0, 2.3, 67.5), Vector3(7.5, 3.6, 6.0), Color(0.50, 0.45, 0.38), true)
    _part(waystation, "WaystationRoof", Vector3(279.0, 4.18, 67.5), Vector3(8.1, 0.35, 6.5), Color(0.25, 0.30, 0.32), true)
    _part(waystation, "SupplyWagon", Vector3(290.0, 1.13, 78.0), Vector3(2.1, 1.2, 3.1), Color(0.43, 0.29, 0.17))
    _part(waystation, "MedicTent", Vector3(291.0, 1.9, 96.0), Vector3(3.8, 2.7, 3.1), Color(0.68, 0.65, 0.54))
    for i in range(18):
        var x: float = 183.0 + float(i) * 6.8
        var z: float = 73.0 if i % 2 == 0 else 98.0
        _part(waystation, "TreeTrunk_%d" % i, Vector3(x, 1.75, z), Vector3(0.45, 2.6, 0.45), Color(0.35, 0.27, 0.19))
        _part(waystation, "TreeCrown_%d" % i, Vector3(x, 3.6, z), Vector3(2.4, 2.3, 2.4), Color(0.29, 0.43, 0.29))
    title_label = Label3D.new()
    title_label.name = "ExpeditionStage"
    title_label.text = "PUBLIC WAYSTATION"
    title_label.font_size = 39
    title_label.pixel_size = 0.007
    title_label.no_depth_test = true
    title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    title_label.position = CAMP + Vector3(0, 3.8, 0)
    add_child(title_label)
    carriage = Node3D.new()
    carriage.name = "ScenicCarriage"
    add_child(carriage)
    _part(carriage, "CarriageBase", Vector3(0, 0.8, 0), Vector3(3.1, 0.5, 2.2), Color(0.37, 0.22, 0.13))
    _part(carriage, "CarriageRoof", Vector3(0, 2.35, 0), Vector3(3.5, 0.33, 2.4), Color(0.18, 0.28, 0.32))
    for side in [-1.0, 1.0]:
        for end in [-0.85, 0.85]:
            _part(carriage, "CarriagePost", Vector3(side * 1.30, 1.60, end), Vector3(0.14, 1.6, 0.14), Color(0.37, 0.22, 0.13))
        _part(carriage, "Wheel", Vector3(side * 1.5, 0.53, 0), Vector3(0.20, 0.95, 0.95), Color(0.16, 0.17, 0.17))
    carriage.visible = false
    volunteer = Node3D.new()
    volunteer.name = "TravelCompanionPrototype"
    add_child(volunteer)
    _part(volunteer, "Uniform", Vector3(0, 1.1, 0), Vector3(0.66, 1.25, 0.45), Color(0.25, 0.47, 0.57))
    _part(volunteer, "Head", Vector3(0, 1.94, 0), Vector3(0.44, 0.48, 0.43), Color(0.68, 0.55, 0.45))
    volunteer.visible = false

func _make_panel() -> void:
    var layer := CanvasLayer.new()
    layer.name = "WaystationChoiceLayer"
    layer.layer = 18
    get_parent().add_child(layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)
    panel = PanelContainer.new()
    panel.anchor_left = 0.13
    panel.anchor_right = 0.87
    panel.anchor_top = 0.14
    panel.anchor_bottom = 0.88
    panel.visible = false
    root.add_child(panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    panel.add_child(margin)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    margin.add_child(scroll)
    var contents := VBoxContainer.new()
    contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    contents.add_theme_constant_override("separation", 10)
    scroll.add_child(contents)
    var heading := Label.new()
    heading.text = "WAYSTATION ASSIGNMENT / DEVELOPMENT MISSION"
    heading.add_theme_font_size_override("font_size", 23)
    heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    contents.add_child(heading)
    message = Label.new()
    message.add_theme_font_size_override("font_size", 18)
    message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    contents.add_child(message)
    options = VBoxContainer.new()
    options.add_theme_constant_override("separation", 9)
    contents.add_child(options)
    var close := Button.new()
    close.text = "RETURN TO YOUR JOURNEY"
    close.custom_minimum_size.y = 52
    close.pressed.connect(_close)
    contents.add_child(close)

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func is_riding() -> bool:
    return riding

func _open(prompt: String, actions: Array[Dictionary]) -> void:
    message.text = prompt
    for old in options.get_children():
        options.remove_child(old)
        old.queue_free()
    for action in actions:
        var button := Button.new()
        button.text = str(action["label"])
        button.custom_minimum_size.y = 57
        button.add_theme_font_size_override("font_size", 18)
        button.pressed.connect(_act.bind(str(action["id"])))
        options.add_child(button)
    panel.show()

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()

func interact(kind: String) -> void:
    if riding or not is_instance_valid(codex) or bool(codex.get("save_blocked")):
        return
    var stage: String = str(state["stage"])
    match kind:
        "exp_v050_dispatch":
            if stage == "available":
                _open("Dispatch requests a volunteer to escort a supply carriage to a public waystation. The route takes an overnight camp; no Seeker rank is awarded.", [{"id":"accept", "label":"Accept the assignment"}])
            elif stage == "planning":
                _open("Prepare for the journey. Your equipment choice will influence the report and the people you help.", [
                    {"id":"equip_medicine", "label":"Prepare a medical support pack"},
                    {"id":"equip_survey", "label":"Prepare survey instruments"}])
            elif stage == "ready":
                _open("Your carriage and partner are waiting. The trip includes scenery and requires an overnight stop.", [{"id":"depart", "label":"Depart aboard the carriage"}])
            elif stage == "debrief":
                _open("You have returned to Magnara. File your report and claim the single field payment.", [{"id":"file_report", "label":"Submit final report"}])
            elif stage == "complete":
                _tell("Your report is already filed. This route has no repeat payout.")
            else:
                _tell("The assignment is active. Consult the waystation markers on the journey.")
        "exp_v050_camp":
            if stage == "waystation":
                _open("The carriage reaches the waystation. You can rest safely until the next in-game morning. Your companion will keep watch.", [{"id":"rest", "label":"Camp overnight and recover"}])
            else:
                _tell("The waystation camp is reserved for this assignment.")
        "exp_v050_threat":
            if stage == "rested":
                _open("A damaged field construct threatens a nearby route. Disable it without harming residents.", [{"id":"investigate", "label":"Approach and engage the rogue construct"}])
            else:
                _tell("The patrol route has no active assignment at this location.")
        "exp_v050_civilian":
            if stage == "response":
                _open("The construct is down. A worker is injured; helping now means leaving some records unsecured.", [{"id":"protect_civilians", "label":"Prioritize medical aid"}])
            else:
                _tell("The worker is not presently asking for help.")
        "exp_v050_documents":
            if stage == "response":
                _open("You can secure the shipment's reports, but the worker will have to wait for help.", [{"id":"secure_evidence", "label":"Prioritize the field documents"}])
            else:
                _tell("These reports aren't available in your current assignment.")
        "exp_v050_return":
            if stage == "return_ready":
                _open("Your response was recorded. Return to Magnara by carriage to file the report.", [{"id":"board_return", "label":"Board the return carriage"}])
            else:
                _tell("The return carriage is not ready yet.")

func _act(action: String) -> void:
    _close()
    if not is_instance_valid(hub) or not is_instance_valid(codex) or bool(codex.get("save_blocked")):
        return
    var day: int = _game_day()
    if action == "rest":
        if str(state["stage"]) != "waystation":
            return
        var target_day: int = maxi(day + 1, int(state["departure_day"]) + 1)
        # Day begins at 07:00; overnight camp is a deliberate, one-time transition.
        var advanced: Dictionary = Rules.advance(state, "rest", target_day)
        if advanced.is_empty():
            return
        hub.set("world_minutes", float(target_day - 1) * 1440.0 + 420.0)
        state = advanced
        _persist()
        _tell("Morning arrives on day %d. Your squad can now investigate." % target_day)
        return
    var next: Dictionary = Rules.advance(state, action, day)
    if next.is_empty():
        _tell("That decision is already recorded or is unavailable.")
        return
    state = next
    _persist()
    if action == "accept":
        _note("expedition:v050:accept", "Accepted a public waystation assignment", "Joined a game-only carriage mission outside Ring Two.")
    elif action in ["equip_medicine", "equip_survey"]:
        _note("expedition:v050:prepare", "Prepared for a multi-day route", "Selected %s as the field preparation." % str(state["preparation"]))
    elif action in ["protect_civilians", "secure_evidence"]:
        _note("expedition:v050:choice", "Made a field decision", "Selected %s after the waystation encounter." % action)
    if action in ["depart", "board_return"]:
        _start_ride()
    elif action == "file_report":
        _settle_report()
    else:
        _tell("Assignment updated: " + str(state["stage"]).replace("_", " "))

func _game_day() -> int:
    return int(floor(float(hub.get("world_minutes")) / 1440.0)) + 1

func _persist() -> void:
    codex.profile["expedition_v050"] = state.duplicate(true)
    codex.call("_save_profile")
    _set_visuals()
    if not riding and is_instance_valid(hub) and hub.has_method("_save_game"):
        hub.call("_save_game")

func _note(key: String, heading: String, details: String) -> void:
    if is_instance_valid(codex):
        codex.call("record_event", key, "public_waystation", heading, details)

func _set_visuals() -> void:
    var stage: String = str(state.get("stage", "available"))
    var in_country: bool = stage in ["outbound", "waystation", "rested", "engage", "response", "return_ready", "return_trip"]
    if is_instance_valid(waystation):
        waystation.visible = in_country
    if is_instance_valid(volunteer):
        volunteer.visible = stage in ["outbound", "waystation", "rested", "engage", "response", "return_ready", "return_trip"]
    if is_instance_valid(title_label):
        title_label.visible = in_country
        title_label.text = "WAYSTATION / " + stage.to_upper().replace("_", " ")
    var visible: Dictionary = {
        "exp_v050_dispatch": stage in ["available", "planning", "ready", "debrief", "complete"],
        "exp_v050_camp": stage == "waystation",
        "exp_v050_threat": stage == "rested",
        "exp_v050_civilian": stage == "response",
        "exp_v050_documents": stage == "response",
        "exp_v050_return": stage == "return_ready"
    }
    for id in visible:
        if location_nodes.has(id):
            var node: Node3D = location_nodes[id]
            node.visible = bool(visible[id])
    if stage == "engage" and not is_instance_valid(enemy) and is_instance_valid(player):
        _spawn_enemy()
    elif stage != "engage" and is_instance_valid(enemy):
        if is_instance_valid(arena) and arena.has_method("unregister_field_enemy"):
            arena.call("unregister_field_enemy", enemy)
        enemy.queue_free()
        enemy = null

func _spawn_enemy() -> void:
    enemy = Construct.new()
    enemy.name = "WaystationDamagedAutomaton"
    add_child(enemy)
    enemy.call("configure", player, "WAYSTATION ROGUE CONSTRUCT", THREAT, 2.1)
    enemy.call("set_patrol_bounds", Vector2(275.0, 302.0), Vector2(73.0, 106.0))
    enemy.connect("knocked_out", _enemy_down)
    if is_instance_valid(arena) and arena.has_method("register_field_enemy"):
        arena.call("register_field_enemy", enemy)

func _enemy_down() -> void:
    if str(state["stage"]) != "engage":
        return
    var next: Dictionary = Rules.advance(state, "enemy_defeated", _game_day())
    if next.is_empty():
        return
    state = next
    _persist()
    _note("expedition:v050:encounter", "Disabled a waystation construct", "Used field combat to make the public route safe.")
    _tell("The threat is disabled. Choose whether to aid a worker or secure records.")

func _start_ride() -> void:
    if riding or not is_instance_valid(player):
        return
    riding = true
    ride_clock = 0.0
    player.set_physics_process(false)
    carriage.visible = true
    _update_ride_position(0.0)
    set_process(true)

func _update_ride_position(progress: float) -> void:
    var outbound: bool = str(state["stage"]) == "outbound"
    var start_x: float = 185.0 if outbound else 281.0
    var end_x: float = 281.0 if outbound else 185.0
    carriage.global_position = Vector3(lerpf(start_x, end_x, progress), 0.65, 85.0)
    if is_instance_valid(player):
        player.global_position = carriage.global_position + Vector3(0.0, 1.35, 0.0)
        player.velocity = Vector3.ZERO
    if is_instance_valid(volunteer):
        volunteer.global_position = carriage.global_position + Vector3(0.7, 0.15, -0.45)

func _move_player_to_camp() -> void:
    if is_instance_valid(player):
        player.global_position = CAMP + Vector3(0, 0.95, 0)
        player.velocity = Vector3.ZERO

func _move_player_to_city_if_remote() -> void:
    if is_instance_valid(player) and player.global_position.x > 120.0:
        player.global_position = DISPATCH + Vector3(0, 1.0, 0)
        player.velocity = Vector3.ZERO

func _process(delta: float) -> void:
    if riding:
        ride_clock += delta
        var progress: float = clampf(ride_clock / TRIP_SECONDS, 0.0, 1.0)
        _update_ride_position(progress)
        if progress >= 1.0:
            var outbound: bool = str(state["stage"]) == "outbound"
            riding = false
            carriage.visible = false
            player.set_physics_process(true)
            if outbound:
                _move_player_to_camp()
            else:
                player.global_position = DISPATCH + Vector3(0, 0.95, 0)
            var action: String = "arrive_outbound" if outbound else "arrive_return"
            var next: Dictionary = Rules.advance(state, action, _game_day())
            if not next.is_empty():
                state = next
                _persist()
                _tell("Arrived at the waystation." if outbound else "Returned to Magnara. File your report at dispatch.")
        return
    if not is_instance_valid(volunteer) or not is_instance_valid(player):
        return
    var stage: String = str(state["stage"])
    if stage in ["waystation", "rested", "engage", "response", "return_ready"]:
        var target: Vector3 = player.global_position + Vector3(1.35, -0.2, -1.0)
        target.y = 0.55
        if volunteer.global_position.distance_to(target) > 24.0:
            volunteer.global_position = target
        else:
            volunteer.global_position = volunteer.global_position.move_toward(target, 3.1 * delta)
        support_clock = maxf(0.0, support_clock - delta)
        if stage == "engage" and is_instance_valid(enemy) and bool(enemy.call("is_active")) and support_clock <= 0.0:
            var partner: Dictionary = codex.profile.get("companion_v049", {})
            if int(partner.get("injury", 0)) < 65 and volunteer.global_position.distance_to(enemy.global_position) < 4.8:
                support_clock = 6.5
                enemy.call("take_strike", 7, volunteer.global_position)

func _settle_report() -> void:
    if str(state.get("stage", "")) != "complete" or not is_instance_valid(codex) or bool(codex.get("save_blocked")):
        return
    var outcome: String = str(state["outcome"])
    var prep: String = str(state["preparation"])
    var society_state: Dictionary = codex.profile.get("society", {})
    var decisions: Dictionary = society_state.get("decisions", {})
    if not decisions.has("field:waystation_v050"):
        decisions["field:waystation_v050"] = outcome
        society_state["decisions"] = decisions
        var reputations: Dictionary = society_state.get("reputation", {})
        var changes: Dictionary = {"association_trust": 1, "local_respect": 2} if outcome == "protect_civilians" else {"guild_reliability": 2, "local_respect": -1}
        if prep == "medicine" and outcome == "protect_civilians":
            changes["guild_reliability"] = 1
        if prep == "survey" and outcome == "secure_evidence":
            changes["association_trust"] = 1
        for key in changes:
            reputations[key] = clampi(int(reputations.get(key, 0)) + int(changes[key]), -20, 20)
        society_state["reputation"] = reputations
        codex.profile["society"] = society_state
        var companion_profile: Dictionary = codex.profile.get("companion_v049", {})
        if not companion_profile.has("v050_decision"):
            companion_profile["v050_decision"] = outcome
            var trust_delta: int = 1 if outcome == "protect_civilians" else 0
            companion_profile["loyalty"] = clampi(int(companion_profile.get("loyalty", 0)) + trust_delta, -3, 3)
            codex.profile["companion_v049"] = companion_profile
        _note("expedition:v050:report", "Completed a multi-day waystation mission", "Prepared %s; resolved %s; returned to Magnara after overnight field work." % [prep, outcome])
        codex.call("_save_profile")
    if is_instance_valid(hub) and hub.has_method("award_field_payout_once"):
        hub.call("award_field_payout_once", RECEIPT, PAYOUT)
        if not bool(state.get("paid", false)):
            state["paid"] = true
            codex.profile["expedition_v050"] = state.duplicate(true)
            codex.call("_save_profile")
    _tell("Waystation mission closed. Report and one-time payment recorded.")

func _tell(value: String) -> void:
    if is_instance_valid(hub) and hub.has_method("_announce"):
        hub.call("_announce", value)
