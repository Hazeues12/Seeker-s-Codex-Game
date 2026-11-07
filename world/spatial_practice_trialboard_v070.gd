extends Node3D
# V0.70 isolated public trialboard; a physical, streamed training room
# instantiated only when entered and freed on return. This is an authored
# orientation sandbox, NOT a genuine Spatial Ryōiki or hidden story world.
const Rules = preload("res://systems/spatial_practice_rules_v070.gd")
var player: CharacterBody3D
var hub: Node
var initialized: bool = false
var active: bool = false
var room: Node3D
var exit_marker: Node3D
var return_anchor: Vector3 = Rules.ENTRY
var elapsed: float = 0.0
var panel: PanelContainer
var details: Label
var enter_button: Button
var exit_button: Button
var message: Label

func _ready() -> void:
    add_to_group("v070_spatial_trialboard")
    set_process(false)
    call_deferred("_setup")

func _setup() -> void:
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    hub = get_tree().get_first_node_in_group("hub_manager")
    if not is_instance_valid(player) or not is_instance_valid(hub):
        push_warning("V0.70 Trialboard needs original player and Hub")
        return
    _make_portal()
    _make_ui()
    initialized = true
    set_process(true)

func _mat(tint: Color, translucent: bool = false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    material.roughness = 0.80
    if translucent:
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    return material

func _block(parent: Node3D, title: String, at: Vector3, dims: Vector3,
        tint: Color, solid: bool = false, translucent: bool = false) -> MeshInstance3D:
    var visual := MeshInstance3D.new()
    visual.name = title
    var box := BoxMesh.new()
    box.size = dims
    visual.mesh = box
    visual.material_override = _mat(tint,translucent)
    visual.position = at
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(visual)
    if solid:
        var body := StaticBody3D.new()
        body.name = title+"Physical"
        visual.add_child(body)
        var hit := CollisionShape3D.new()
        hit.name = "V070TrialCollision"
        var shape := BoxShape3D.new()
        shape.size = dims
        hit.shape = shape
        body.add_child(hit)
    return visual

func _label(parent: Node3D, text_value: String, at: Vector3) -> void:
    var label := Label3D.new()
    label.name = "V070TrialboardSign"
    label.text = text_value
    label.font_size = 27
    label.pixel_size = 0.0046
    label.position = at
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    parent.add_child(label)

func _make_portal() -> void:
    var entry := Node3D.new()
    entry.name = "V070PublicPracticeGate"
    entry.position = Rules.ENTRY - Vector3(0,0.85,0)
    add_child(entry)
    for flank in [-1.0,1.0]:
        _block(entry,"V070GateUpright",Vector3(flank*1.70,2.10,0),
            Vector3(0.40,3.7,0.50),Color(0.47,0.52,0.57),true)
    _block(entry,"V070GateLintel",Vector3(0,4.14,0),
        Vector3(3.9,0.43,0.58),Color(0.67,0.55,0.37),true)
    _block(entry,"V070PublicSimulationWindow",Vector3(0,2.02,0),
        Vector3(2.70,3.55,0.07),Color(0.24,0.55,0.76,0.32),false,true)
    _label(entry,"SPATIAL RULES / PUBLIC TRAINING SIMULATION",Vector3(0,5.10,0))
    var approach := Node3D.new()
    approach.name = "V070PracticeGateInteraction"
    approach.position = Vector3(0,0.87,-2.1)
    entry.add_child(approach)
    hub.call("_add_location","trial_v070_gate",
        "Public Spatial Practice Trialboard",approach.global_position,approach)
    exit_marker = Node3D.new()
    exit_marker.name = "V070RemoteExitMarker"
    exit_marker.position = Rules.EXIT
    add_child(exit_marker)
    _label(exit_marker,"RETURN / TALK + USE",Vector3(0,2.15,0))
    hub.call("_add_location","trial_v070_exit","Return From Practice Trialboard",
        exit_marker.global_position,exit_marker)
    exit_marker.visible = false

func _make_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "V070TrialboardCanvas"
    layer.layer = 34
    get_parent().add_child(layer)
    var screen := Control.new()
    screen.set_anchors_preset(Control.PRESET_FULL_RECT)
    screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(screen)
    panel = PanelContainer.new()
    panel.anchor_left = 0.08
    panel.anchor_right = 0.92
    panel.anchor_top = 0.09
    panel.anchor_bottom = 0.91
    panel.visible = false
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.063,0.074,0.116,0.985)
    style.border_color = Color(0.50,0.70,0.82)
    style.set_border_width_all(2)
    style.set_corner_radius_all(8)
    panel.add_theme_stylebox_override("panel",style)
    screen.add_child(panel)
    var margins := MarginContainer.new()
    for side in ["left","right","top","bottom"]:
        margins.add_theme_constant_override("margin_"+side,15)
    panel.add_child(margins)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation",11)
    margins.add_child(stack)
    var head := Label.new()
    head.text = "SUPERVISED SPATIAL PRACTICE / NONCANONICAL ROOM"
    head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    head.add_theme_font_size_override("font_size",22)
    stack.add_child(head)
    details = Label.new()
    details.size_flags_vertical = Control.SIZE_EXPAND_FILL
    details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(details)
    message = Label.new()
    message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(message)
    enter_button = Button.new()
    enter_button.text = "ENTER SUPERVISED ORIENTATION COURSE"
    enter_button.custom_minimum_size.y = 52
    enter_button.pressed.connect(_enter)
    stack.add_child(enter_button)
    exit_button = Button.new()
    exit_button.text = "RETURN TO PUBLIC MAGNARA"
    exit_button.custom_minimum_size.y = 52
    exit_button.pressed.connect(_leave)
    stack.add_child(exit_button)
    var close := Button.new()
    close.text = "CLOSE"
    close.custom_minimum_size.y = 50
    close.pressed.connect(_close)
    stack.add_child(close)

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func is_active() -> bool:
    return active

func get_safe_save_position() -> Vector3:
    return return_anchor if active and Rules.safe_return(return_anchor) else Rules.ENTRY

func get_manifest() -> Dictionary:
    return {"version":70, "initialized":initialized,
        "active_room_count":1 if active and is_instance_valid(room) else 0,
        "max_active_rooms":Rules.MAX_ACTIVE_ROOMS,
        "unloaded_when_inactive":not is_instance_valid(room),
        "public_training_only":true,
        "grants_spatial_technique":false,"authored_bosses_spawn":false,
        "seamless_render_target_portal":false,
        "secret_ryoiki_or_archwheel":false}

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()

func _refresh() -> void:
    if not is_instance_valid(details):
        return
    details.text = ("In the practice room: %s\n" % ("YES" if active else "NO"))
    details.text += "An isolated 3D movement test loads on entry and frees on exit.\n"
    details.text += "You can walk, double-jump and practice Aura Burst without earning a Spatial Spoke.\n"
    details.text += "No Ryōiki, Chronofault, pocket-dimension or sealed boss is involved."
    if active:
        details.text += "\nAutomatic safe return after %.0f sec." % maxf(0.0,Rules.ARENA_TIME_LIMIT-elapsed)
    enter_button.disabled = active
    exit_button.disabled = not active

func interact(key: String) -> void:
    if not initialized:
        return
    if key == "trial_v070_gate":
        if player.global_position.distance_to(Rules.ENTRY) > 5.0:
            return
        _refresh()
        message.text = "A public movement simulation. Supervision grants no rare Spatial mastery."
        panel.show()
    elif key == "trial_v070_exit" and active:
        _refresh()
        message.text = "Return with your current health, equipment and Aura."
        panel.show()

func _create_room() -> void:
    room = Node3D.new()
    room.name = "V070LoadedTrialArena"
    room.position = Rules.ARENA
    add_child(room)
    _block(room,"V070TrialFloor",Vector3(0,-0.03,0),
        Rules.FLOOR_SIZE,Color(0.57,0.58,0.60),true)
    for pair in [
        {"name":"First","position":Vector3(-6,0.90,-2),"size":Vector3(3.1,0.42,3.1)},
        {"name":"Second","position":Vector3(-1,1.80,2),"size":Vector3(3.1,0.38,3.1)},
        {"name":"Third","position":Vector3(4,2.55,4),"size":Vector3(3.1,0.38,3.1)}
    ]:
        _block(room,"V070"+str(pair["name"])+"JumpPlatform",
            pair["position"],pair["size"],Color(0.37,0.60,0.72),true)
    for side in [-1.0,1.0]:
        _block(room,"V070SimulationRail",
            Vector3(side*11.35,1.30,0.0),Vector3(0.28,2.0,23.0),
            Color(0.42,0.44,0.52),true)
        _block(room,"V070FarSimulationRail",
            Vector3(0,1.30,side*11.35),Vector3(23.0,2.0,0.28),
            Color(0.42,0.44,0.52),true)
    _label(room,"PRACTICE RULES / OBSERVE AND MOVE / NO MASTERY",
        Vector3(0,5.45,-4))

func _enter() -> void:
    if not initialized or active:
        return
    var exp: Node = get_tree().get_first_node_in_group("multi_day_expedition_v050")
    var busy: bool = is_instance_valid(exp) and bool(exp.call("is_riding"))
    var decision: Dictionary = Rules.valid_entry(GameState.seeker_rank,
        player.global_position.distance_to(Rules.ENTRY) <= 5.0,busy,active)
    if not bool(decision.get("allowed",false)):
        message.text = str(decision.get("reason","Not available."))
        return
    return_anchor = player.global_position
    if not Rules.safe_return(return_anchor):
        return_anchor = Rules.ENTRY
    _create_room()
    active = true
    elapsed = 0.0
    exit_marker.visible = true
    _close()
    player.velocity = Vector3.ZERO
    player.global_position = Rules.SPAWN

func _leave() -> void:
    if not active:
        _close()
        return
    var destination: Vector3 = get_safe_save_position()
    active = false
    elapsed = 0.0
    if is_instance_valid(room):
        room.queue_free()
        room = null
    exit_marker.visible = false
    player.velocity = Vector3.ZERO
    player.global_position = destination
    _close()

func _process(delta: float) -> void:
    if active:
        elapsed += delta
        if elapsed >= Rules.ARENA_TIME_LIMIT:
            _leave()
        elif is_open():
            _refresh()
