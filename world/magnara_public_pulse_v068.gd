extends Node3D
# V0.68 public economic pulse kiosk for Ring Two. This is a grounded
# game-only summary of observable workers, shop stock and Aura practice.
# It does NOT reveal Archwheel truths, the Red Order's private operations,
# fabricated national currency exchange rates, or Seeker promotions.
const Power = preload("res://systems/seeker_power_rules_v068.gd")
var hub: Node
var codex: Node
var player: CharacterBody3D
var initialized: bool = false
var panel: PanelContainer
var title: Label
var text_body: Label
var last_day: int = 0

func _ready() -> void:
    add_to_group("margerina_public_pulse_v068")
    set_process(false)
    call_deferred("_initialize")

func _initialize() -> void:
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(player):
        push_warning("V0.68 public pulse requires existing hub, player and Codex")
        return
    _make_kiosk()
    _make_ui()
    initialized = true
    set_process(true)

func get_manifest() -> Dictionary:
    return {
        "version": 68, "district": "Magnara / Ring Two",
        "physical_public_kiosk": initialized,
        "public_economy": "daily local work and observed shop units only",
        "national_rates": "not simulated",
        "faction_conspiracies": "not exposed",
        "arkwheel_lore": "not exposed",
        "power_chain": "Soul -> Aura -> Muti -> Technique",
        "all_public_game_only": true
    }

func _make_kiosk() -> void:
    var display := Node3D.new()
    display.name = "V068PublicDailyLifeKiosk"
    display.position = Vector3(13.4, 0.0, 712.0)
    add_child(display)
    var main := StaticBody3D.new()
    main.name = "V068KioskPhysicalBoard"
    display.add_child(main)
    var frame := MeshInstance3D.new()
    frame.name = "V068KioskFrame"
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.48, 2.6, 3.1)
    frame.mesh = mesh
    frame.position = Vector3(0, 2.04, 0)
    var frame_mat := StandardMaterial3D.new()
    frame_mat.albedo_color = Color(0.36, 0.29, 0.22)
    frame_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    frame.material_override = frame_mat
    main.add_child(frame)
    var shape := CollisionShape3D.new()
    shape.name = "V068KioskCollision"
    shape.position = frame.position
    var form := BoxShape3D.new()
    form.size = mesh.size
    shape.shape = form
    main.add_child(shape)
    var plaque := Label3D.new()
    plaque.name = "V068PublicInformationPlaque"
    plaque.text = "DAILY QUARTER NEWS / PUBLIC SERVICE"
    plaque.font_size = 27
    plaque.pixel_size = 0.004
    plaque.position = Vector3(-0.42, 3.9, 0.0)
    plaque.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    plaque.no_depth_test = true
    display.add_child(plaque)
    var use_point := Node3D.new()
    use_point.name = "V068PublicBoardApproach"
    use_point.position = Vector3(-3.5, 0.83, 0)
    display.add_child(use_point)
    hub.call("_add_location", "pulse_v068_public", "Public Quarter Daily Report", use_point.global_position, use_point)

func _make_ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "V068PublicPulseCanvas"
    canvas.layer = 27
    get_parent().add_child(canvas)
    var background := Control.new()
    background.set_anchors_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(background)
    panel = PanelContainer.new()
    panel.anchor_left = 0.09
    panel.anchor_right = 0.91
    panel.anchor_top = 0.08
    panel.anchor_bottom = 0.92
    panel.visible = false
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(0.065,0.082,0.119,0.98)
    skin.border_color = Color(0.65,0.57,0.40)
    skin.set_border_width_all(2)
    skin.set_corner_radius_all(10)
    panel.add_theme_stylebox_override("panel", skin)
    background.add_child(panel)
    var margin := MarginContainer.new()
    for side in ["left","top","right","bottom"]:
        margin.add_theme_constant_override("margin_"+side,16)
    panel.add_child(margin)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 10)
    margin.add_child(column)
    title = Label.new()
    title.add_theme_font_size_override("font_size", 22)
    title.text = "MAGNARA / PUBLIC DAILY LIFE"
    column.add_child(title)
    text_body = Label.new()
    text_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(text_body)
    var close := Button.new()
    close.text = "RETURN TO THE CITY"
    close.custom_minimum_size.y = 52
    close.pressed.connect(_close)
    column.add_child(close)

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()

func interact(key: String) -> void:
    if not initialized or key != "pulse_v068_public":
        return
    if player.global_position.distance_to(Vector3(9.9,0.83,712.0)) > float(hub.get("interact_range")):
        return
    _refresh()
    panel.show()
    if is_instance_valid(codex) and codex.has_method("record_event"):
        codex.call("record_event", "v068:public_quarter_bulletin",
            "public_world", "Visited the daily public quarter bulletin",
            "Observed current non-secret district hours, retail traffic and the basic Aura principle.")

func _refresh() -> void:
    var pulse: Dictionary = Power.public_local_pulse(
        float(hub.get("world_minutes")), hub.get("shop_stock_v066"))
    last_day = int(pulse["day"])
    var local_hour: int = int(pulse["hour"])
    var status: String = str(pulse["public_activity"])
    var observed: int = int(pulse["observed_shop_units_today"])
    var aura: float = float(hub.get("aura"))
    text_body.text = "Day %d / %02d:00\nLocal life: %s\n" % [last_day, local_hour,status]
    text_body.text += "Recorded physical shop transactions today: %d units\n" % observed
    text_body.text += "Your current Aura reserve: %.1f\n" % aura
    text_body.text += "\nTHE FOUR LAYERS\nSoul: unique identity and Will\n"
    text_body.text += "Aura: reserve (Bucket), output (Tap), recovery and control\n"
    text_body.text += "Muti: practiced ways of using Aura\nTechnique: an authored action with cost, trajectory and lineage\n"
    text_body.text += "\nThe Seven Spokes remain part of the supervised yard."
    text_body.text += "\nA city's real trade and people require observation over time."
    text_body.text += "\nThese shop hours and prototype figures describe this game district only."

func _process(delta: float) -> void:
    if is_open():
        _refresh()
