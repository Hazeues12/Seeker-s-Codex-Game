extends Node
const WorldGeoV054 = preload("res://systems/known_world_geometry_v054.gd")
const JanoahRegionV055 = preload("res://world/janoah_approach_v055.gd")
const SaveIntegrityV063 = preload("res://systems/game_save_integrity_v063.gd")

# Seeker's Codex — Margerina V0.33
# A self-contained starter hub. The three contracts are prototype gameplay,
# not new claims about published story canon or official Seeker examination rules.

const SAVE_FILE: String = "user://margerina_v033.json"
const CONTRACTS = [
    "Field Kit Delivery",
    "Medicinal Herb Survey",
    "Aura Technique Drills"
]
const REWARDS = [35, 45, 50]
const XP_REWARDS = [20, 30, 35]

var player: CharacterBody3D
var mobile: Control
var locations: Array[Dictionary] = []
var plants: Dictionary = {}
var gathered: Dictionary = {}
var contract_finished: Array[bool] = [false, false, false]
var active_contract: int = -1
var progress: int = 0
var inventory: Dictionary = {"Vitality Draught": 2, "Essence Tonic": 1}
var field_reward_receipts: Dictionary = {}
var market_stock_v062: Dictionary = {}
var aura: float = 100.0
var stamina: float = 100.0
var guild_rep: int = 0
var experience: int = 0
var world_minutes: float = 8.0 * 60.0
var interact_range: float = 3.2
var hud_clock: float = 0.0
var last_notice: String = "Find the contract board straight ahead. Use the joystick and tap TALK / USE nearby."
var notice_timeout: float = 12.0

var hud_layer: CanvasLayer
var ui: Control
var top_status: Label
var quest_status: Label
var proximity_label: Label
var notice_label: Label
var aura_bar: ProgressBar
var stamina_bar: ProgressBar
var board_panel: PanelContainer
var board_list: VBoxContainer
var bag_panel: PanelContainer
var bag_list: VBoxContainer


func _ready() -> void:
    add_to_group("hub_manager")
    # Main scene is still constructing children. Initialize afterward.
    set_process(false)
    call_deferred("_finish_setup")


func _finish_setup() -> void:
    if not is_inside_tree():
        return
    player = get_parent().get_node("Player") as CharacterBody3D
    mobile = get_tree().get_first_node_in_group("mobile_controls") as Control
    _make_environment()
    _make_hub()
    _make_interface()
    _load_game(false)
    _update_plants()
    _refresh_status()
    set_process(true)


func _origin_effects_v058() -> Dictionary:
    var life: Node = get_tree().get_first_node_in_group("young_blood_life_v057")
    if is_instance_valid(life) and life.has_method("get_origin_effects"):
        return life.call("get_origin_effects")
    return {}


func _process(delta: float) -> void:
    world_minutes += delta * 0.25
    if is_instance_valid(player):
        var horizontal_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
        var running: bool = is_instance_valid(mobile) and bool(mobile.get("sprinting"))
        var traits: Dictionary = _origin_effects_v058()
        var stamina_ceiling: float = float(traits.get("stamina_limit", 100.0))
        stamina = minf(stamina_ceiling, stamina)
        if running and horizontal_speed > 5.6 and stamina > 0.0:
            stamina = maxf(0.0, stamina - delta * 16.0)
        else:
            stamina = minf(stamina_ceiling, stamina + delta * 11.0 * float(traits.get("stamina_regen_mult", 1.0)))
        aura = minf(100.0, aura + delta * 4.5 * float(traits.get("aura_regen_mult", 1.0)))
    if notice_timeout > 0.0:
        notice_timeout -= delta
    hud_clock += delta
    if hud_clock >= 0.15:
        hud_clock = 0.0
        _refresh_status()
    if Input.is_key_pressed(KEY_E) and not _any_panel_open():
        if not _was_interact_held:
            _interact()
        _was_interact_held = true
    else:
        _was_interact_held = false


var _was_interact_held: bool = false


func can_sprint() -> bool:
    return stamina > 1.0


func spend_guard_stamina() -> bool:
    var required: float = 15.0 - float(_origin_effects_v058().get("guard_discount", 0))
    if stamina < required:
        return false
    stamina -= required
    _refresh_status()
    return true


func can_use_combat_actions() -> bool:
    return is_instance_valid(player) and is_instance_valid(board_panel) and not _any_panel_open()


func try_dodge() -> bool:
    if not can_use_combat_actions():
        return false
    if stamina < 18.0:
        _announce("Dodge needs 18 Stamina. Recover and try again.")
        return false
    stamina -= 18.0
    _refresh_status()
    return true


func try_martial_strike() -> bool:
    if not can_use_combat_actions():
        return false
    if aura < 12.0 or stamina < 4.0:
        _announce("Martial strike requires 12 Aura and 4 Stamina.")
        return false
    aura -= 12.0
    stamina -= 4.0
    var near_post: bool = false
    for spot in locations:
        if str(spot["id"]) == "dummy":
            near_post = player.global_position.distance_to(spot["position"]) <= 3.4
            break
    if near_post and active_contract == 2 and progress < 3:
        progress += 1
        _announce("Martial training strike %d/3. Use the board to claim at 3/3." % progress)
        _save_game()
    elif near_post:
        _announce("Practice strike! Accept Aura Technique Drills at the board to earn rewards.")
    else:
        _announce("Martial Muti: basic Aura-infused strike. Training targets are ahead.")
    _refresh_status()
    return true


func _make_environment() -> void:
    var sky_node := WorldEnvironment.new()
    sky_node.name = "ClearAfternoon"
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.55, 0.72, 0.90)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.72, 0.77, 0.88)
    env.ambient_light_energy = 0.65
    sky_node.environment = env
    get_parent().add_child(sky_node)


func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.85
    return mat


func _box(parent: Node3D, name: String, position: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
    var block := MeshInstance3D.new()
    block.name = name
    var mesh := BoxMesh.new()
    mesh.size = size
    block.mesh = mesh
    block.material_override = _material(color)
    block.position = position
    parent.add_child(block)
    if solid:
        var collider_body := StaticBody3D.new()
        collider_body.name = "Solid"
        block.add_child(collider_body)
        var collider := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collider.shape = shape
        collider_body.add_child(collider)
    return block


func _cylinder(parent: Node3D, name: String, position: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
    var shape := MeshInstance3D.new()
    shape.name = name
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    shape.mesh = mesh
    shape.material_override = _material(color)
    shape.position = position
    parent.add_child(shape)
    return shape


func _sign(parent: Node3D, title: String, elevation: float = 2.6) -> void:
    var sign := Label3D.new()
    sign.text = title
    sign.font_size = 46
    sign.pixel_size = 0.006
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.no_depth_test = true
    sign.position = Vector3(0, elevation, 0)
    parent.add_child(sign)


func _add_location(identifier: String, title: String, place: Vector3, node: Node3D) -> void:
    locations.append({"id": identifier, "title": title, "position": place, "node": node})


func _make_hub() -> void:
    var world := Node3D.new()
    world.name = "SeekerQuarterHub"
    get_parent().add_child(world)
    _box(world, "PaleStoneMainPath", Vector3(0, 0.56, -7), Vector3(3.2, 0.08, 28), Color(0.69, 0.66, 0.61))
    _box(world, "CrossPath", Vector3(0, 0.56, -5), Vector3(18, 0.08, 2.8), Color(0.68, 0.65, 0.59))
    for index in range(8):
        var x: float = -16.0 if index % 2 == 0 else 16.0
        var z: float = -14.0 + floorf(float(index) / 2.0) * 9.0
        _box(world, "LanternPillar_%d" % index, Vector3(x, 1.6, z), Vector3(0.45, 2.3, 0.45), Color(0.33, 0.38, 0.44))
        _box(world, "LanternGlow_%d" % index, Vector3(x, 2.85, z), Vector3(0.85, 0.75, 0.85), Color(0.95, 0.79, 0.42))
    for i in range(4):
        var xx: float = -14.0 if i % 2 == 0 else 14.0
        var zz: float = -16.0 + float(i / 2) * 19.0
        _box(world, "SeekerQuarterHouse_%d" % i, Vector3(xx, 2.25, zz), Vector3(5.0, 3.5, 4.0), Color(0.48, 0.50, 0.54), true)
        _box(world, "HouseRoof_%d" % i, Vector3(xx, 4.15, zz), Vector3(5.6, 0.45, 4.5), Color(0.31, 0.36, 0.45))

    var board := Node3D.new()
    board.name = "GuildContractBoard"
    board.position = Vector3(0, 0.5, -5.0)
    world.add_child(board)
    _box(board, "WoodFrame", Vector3(0, 1.4, 0), Vector3(2.4, 1.8, 0.3), Color(0.39, 0.24, 0.13), true)
    _box(board, "Parchment", Vector3(0, 1.45, 0.19), Vector3(2.1, 1.5, 0.04), Color(0.82, 0.72, 0.52))
    _cylinder(board, "BoardPostLeft", Vector3(-0.94, 0.55, 0), 0.10, 1.1, Color(0.29, 0.20, 0.16))
    _cylinder(board, "BoardPostRight", Vector3(0.94, 0.55, 0), 0.10, 1.1, Color(0.29, 0.20, 0.16))
    _sign(board, "GUILD CONTRACTS", 2.8)
    _add_location("board", "Guild Contract Board", board.global_position, board)

    var npc := Node3D.new()
    npc.name = "HanamiQuartermaster"
    npc.position = Vector3(6.0, 0.5, -4.0)
    world.add_child(npc)
    _cylinder(npc, "Robe", Vector3(0, 1.1, 0), 0.45, 1.3, Color(0.30, 0.48, 0.68))
    var head := SphereMesh.new()
    head.radius = 0.36
    head.height = 0.72
    var head_node := MeshInstance3D.new()
    head_node.mesh = head
    head_node.material_override = _material(Color(0.73, 0.49, 0.34))
    head_node.position = Vector3(0, 2.00, 0)
    npc.add_child(head_node)
    _sign(npc, "HANAMI - QUARTERMASTER", 2.9)
    _add_location("hanami", "Hanami", npc.global_position, npc)

    var dummy := Node3D.new()
    dummy.name = "PracticePost"
    dummy.position = Vector3(0, 0.5, -12.0)
    world.add_child(dummy)
    _cylinder(dummy, "TrainingPole", Vector3(0, 1.0, 0), 0.21, 1.7, Color(0.54, 0.37, 0.21))
    _box(dummy, "StrikingTarget", Vector3(0, 1.6, 0.2), Vector3(0.9, 0.9, 0.35), Color(0.64, 0.48, 0.31), true)
    _sign(dummy, "AURA TRAINING", 2.8)
    _add_location("dummy", "Training Post", dummy.global_position, dummy)

    var herbs := [Vector3(-4.0, 0.5, -10.0), Vector3(-7.0, 0.5, -7.0), Vector3(-4.0, 0.5, -15.0)]
    for i in range(herbs.size()):
        var herb := Node3D.new()
        herb.name = "MedicinalHerb_%d" % (i + 1)
        herb.position = herbs[i]
        world.add_child(herb)
        _cylinder(herb, "HerbStem", Vector3(0, 0.30, 0), 0.16, 0.60, Color(0.21, 0.62, 0.28))
        _box(herb, "LeafLeft", Vector3(-0.26, 0.53, 0), Vector3(0.58, 0.12, 0.30), Color(0.26, 0.75, 0.39))
        _box(herb, "LeafRight", Vector3(0.26, 0.40, 0), Vector3(0.56, 0.12, 0.30), Color(0.15, 0.55, 0.32))
        _sign(herb, "HERB %d" % (i + 1), 1.5)
        var herb_id := "herb%d" % i
        plants[herb_id] = herb
        _add_location(herb_id, "Medicinal Herb", herb.global_position, herb)

    var arrival := Node3D.new()
    arrival.name = "EntrySign"
    arrival.position = Vector3(0, 0.5, 3.5)
    world.add_child(arrival)
    _box(arrival, "StoneMarker", Vector3(0, 1.2, 0), Vector3(3.8, 1.5, 0.4), Color(0.45, 0.53, 0.60))
    _sign(arrival, "MAGNARA - SEEKER QUARTERS", 2.6)


func _make_interface() -> void:
    hud_layer = CanvasLayer.new()
    hud_layer.name = "SeekerHudLayer"
    hud_layer.layer = 8
    get_parent().add_child(hud_layer)
    ui = Control.new()
    ui.name = "HudRoot"
    ui.set_anchors_preset(Control.PRESET_FULL_RECT)
    ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_layer.add_child(ui)

    var header := PanelContainer.new()
    header.set_anchors_preset(Control.PRESET_TOP_LEFT)
    header.offset_left = 14
    header.offset_top = 12
    header.offset_right = 530
    header.offset_bottom = 122
    header.add_theme_stylebox_override("panel", _panel_style())
    ui.add_child(header)
    var header_margin := MarginContainer.new()
    header_margin.add_theme_constant_override("margin_left", 12)
    header_margin.add_theme_constant_override("margin_top", 7)
    header_margin.add_theme_constant_override("margin_right", 12)
    header_margin.add_theme_constant_override("margin_bottom", 7)
    header.add_child(header_margin)
    var header_stack := VBoxContainer.new()
    header_stack.add_theme_constant_override("separation", 1)
    header_margin.add_child(header_stack)
    top_status = _label(header_stack, "SEEKER / STRAY", 20)
    aura_bar = _progress(header_stack, "AURA", Color(0.29, 0.75, 0.91))
    stamina_bar = _progress(header_stack, "STAMINA", Color(0.95, 0.75, 0.28))

    quest_status = _label(ui, "CONTRACT: Find the guild board", 19)
    quest_status.set_anchors_preset(Control.PRESET_TOP_LEFT)
    quest_status.offset_left = 545
    quest_status.offset_top = 127
    quest_status.offset_right = 1190
    quest_status.offset_bottom = 164

    var inventory_button := _hud_button("BAG", -322, 12, -218, 65)
    inventory_button.pressed.connect(_toggle_bag)
    var save_button := _hud_button("SAVE", -210, 12, -106, 65)
    save_button.pressed.connect(_save_with_notice)
    var load_button := _hud_button("LOAD", -98, 12, -8, 65)
    load_button.pressed.connect(_load_with_notice)

    proximity_label = _label(ui, "", 20)
    proximity_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    proximity_label.anchor_left = 0.26
    proximity_label.anchor_right = 0.78
    proximity_label.anchor_top = 1.0
    proximity_label.anchor_bottom = 1.0
    proximity_label.offset_top = -100
    proximity_label.offset_bottom = -65
    proximity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var interact_button := Button.new()
    interact_button.text = "TALK / USE"
    interact_button.add_theme_font_size_override("font_size", 24)
    interact_button.anchor_left = 1.0
    interact_button.anchor_right = 1.0
    interact_button.anchor_top = 1.0
    interact_button.anchor_bottom = 1.0
    interact_button.offset_left = -200
    interact_button.offset_right = -15
    interact_button.offset_top = -310
    interact_button.offset_bottom = -245
    interact_button.pressed.connect(_interact)
    ui.add_child(interact_button)

    notice_label = _label(ui, "", 20)
    notice_label.anchor_left = 0.18
    notice_label.anchor_right = 0.82
    notice_label.anchor_top = 1.0
    notice_label.anchor_bottom = 1.0
    notice_label.offset_top = -64
    notice_label.offset_bottom = -24
    notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    board_panel = _make_menu_panel("Contract Board")
    board_list = board_panel.get_node("Margin/VBox/Scroll/Entries") as VBoxContainer
    bag_panel = _make_menu_panel("Seeker Inventory")
    bag_list = bag_panel.get_node("Margin/VBox/Scroll/Entries") as VBoxContainer


func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.055, 0.08, 0.14, 0.86)
    style.border_color = Color(0.40, 0.62, 0.80, 0.78)
    style.set_border_width_all(2)
    style.set_corner_radius_all(10)
    return style


func _label(parent: Node, text_value: String, font_size: int) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(label)
    return label


func _progress(parent: VBoxContainer, name_text: String, color: Color) -> ProgressBar:
    var row := HBoxContainer.new()
    parent.add_child(row)
    var short_name := _label(row, name_text, 16)
    short_name.custom_minimum_size = Vector2(94, 18)
    var bar := ProgressBar.new()
    bar.min_value = 0.0
    bar.max_value = 100.0
    bar.value = 100.0
    bar.show_percentage = false
    bar.custom_minimum_size = Vector2(365, 16)
    bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var fill := StyleBoxFlat.new()
    fill.bg_color = color
    fill.set_corner_radius_all(4)
    bar.add_theme_stylebox_override("fill", fill)
    row.add_child(bar)
    return bar


func _hud_button(name_text: String, x0: float, y0: float, x1: float, y1: float) -> Button:
    var button := Button.new()
    button.text = name_text
    button.add_theme_font_size_override("font_size", 20)
    button.anchor_left = 1.0
    button.anchor_right = 1.0
    button.offset_left = x0
    button.offset_right = x1
    button.offset_top = y0
    button.offset_bottom = y1
    ui.add_child(button)
    return button


func _make_menu_panel(title_text: String) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.anchor_left = 0.18
    panel.anchor_right = 0.82
    panel.anchor_top = 0.13
    panel.anchor_bottom = 0.88
    panel.add_theme_stylebox_override("panel", _panel_style())
    panel.visible = false
    ui.add_child(panel)
    var margin := MarginContainer.new()
    margin.name = "Margin"
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_bottom", 10)
    panel.add_child(margin)
    var stack := VBoxContainer.new()
    stack.name = "VBox"
    stack.add_theme_constant_override("separation", 7)
    margin.add_child(stack)
    _label(stack, title_text, 27)
    var scroll := ScrollContainer.new()
    scroll.name = "Scroll"
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_child(scroll)
    var entries := VBoxContainer.new()
    entries.name = "Entries"
    entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    entries.add_theme_constant_override("separation", 8)
    scroll.add_child(entries)
    var close_button := Button.new()
    close_button.text = "CLOSE"
    close_button.custom_minimum_size = Vector2(0, 45)
    close_button.pressed.connect(func(): panel.hide())
    stack.add_child(close_button)
    return panel


func _clear_list(list_node: VBoxContainer) -> void:
    for child in list_node.get_children():
        list_node.remove_child(child)
        child.queue_free()


func _any_panel_open() -> bool:
    var editor: Node = get_tree().get_first_node_in_group("seeker_creator")
    var ring_journal: Node = get_tree().get_first_node_in_group("ring_two_life")
    var journal_open: bool = is_instance_valid(ring_journal) and bool(ring_journal.call("is_open"))
    var codex: Node = get_tree().get_first_node_in_group("personal_codex")
    var codex_open: bool = is_instance_valid(codex) and bool(codex.call("is_open"))
    var relations: Node = get_tree().get_first_node_in_group("seeker_relationships")
    var relations_open: bool = is_instance_valid(relations) and bool(relations.call("is_open"))
    var canal: Node = get_tree().get_first_node_in_group("canal_incident")
    var canal_open: bool = is_instance_valid(canal) and bool(canal.call("is_open"))
    var field: Node = get_tree().get_first_node_in_group("field_mission_v048")
    var field_open: bool = is_instance_valid(field) and bool(field.call("is_open"))
    var expedition: Node = get_tree().get_first_node_in_group("multi_day_expedition_v050")
    var expedition_busy: bool = is_instance_valid(expedition) and (bool(expedition.call("is_open")) or bool(expedition.call("is_riding")))
    var bulletin: Node = get_tree().get_first_node_in_group("daily_events_v051")
    var bulletin_open: bool = is_instance_valid(bulletin) and bool(bulletin.call("is_open"))
    var young_life: Node = get_tree().get_first_node_in_group("young_blood_life_v057")
    var life_open: bool = is_instance_valid(young_life) and bool(young_life.call("is_open"))
    var homes: Node = get_tree().get_first_node_in_group("residential_life_v060")
    var homes_open: bool = is_instance_valid(homes) and bool(homes.call("is_open"))
    var workshops: Node = get_tree().get_first_node_in_group("magnara_workshops_v061")
    var workshops_open: bool = is_instance_valid(workshops) and bool(workshops.call("is_open"))
    var market: Node = get_tree().get_first_node_in_group("magnara_markets_v062")
    var market_open: bool = is_instance_valid(market) and bool(market.call("is_open"))
    return board_panel.visible or bag_panel.visible or journal_open or codex_open or relations_open or canal_open or field_open or expedition_busy or bulletin_open or life_open or homes_open or workshops_open or market_open or (is_instance_valid(editor) and bool(editor.call("is_open")))


func _nearest_location() -> Dictionary:
    var closest: Dictionary = {}
    var best_distance: float = interact_range
    if not is_instance_valid(player):
        return closest
    for spot in locations:
        var key: String = str(spot["id"])
        if key.begins_with("herb") and (active_contract != 1 or gathered.has(key)):
            continue
        var spot_node: Node3D = spot["node"] as Node3D
        if (key.begins_with("npc_") or key.begins_with("field_v048_") or key.begins_with("exp_v050_")) and (not is_instance_valid(spot_node) or not spot_node.visible):
            continue
        var place: Vector3 = spot_node.global_position if key.begins_with("npc_") else spot["position"]
        var distance: float = player.global_position.distance_to(place)
        if distance < best_distance:
            best_distance = distance
            closest = spot
    return closest


func _interact() -> void:
    if _any_panel_open():
        return
    var nearest := _nearest_location()
    if nearest.is_empty():
        _announce("Move closer to the board, Hanami, herbs or the training post.")
        return
    var kind: String = str(nearest["id"])
    match kind:
        "board":
            _open_board()
        "hanami":
            _talk_to_hanami()
        "dummy":
            _train_at_post()
        "npc_canal", "npc_vendor", "npc_scout":
            _npc_dialogue(kind)
        _:
            if kind.begins_with("npc_ring2_"):
                var life: Node = get_tree().get_first_node_in_group("ring_two_life")
                if is_instance_valid(life) and life.has_method("interact"):
                    life.call("interact", kind)
            elif kind.begins_with("incident_"):
                var civic: Node = get_tree().get_first_node_in_group("canal_incident")
                if is_instance_valid(civic) and civic.has_method("interact"):
                    civic.call("interact", kind)
            elif kind.begins_with("field_v048_"):
                var field: Node = get_tree().get_first_node_in_group("field_mission_v048")
                if is_instance_valid(field) and field.has_method("interact"):
                    field.call("interact", kind)
            elif kind.begins_with("exp_v050_"):
                var expedition: Node = get_tree().get_first_node_in_group("multi_day_expedition_v050")
                if is_instance_valid(expedition) and expedition.has_method("interact"):
                    expedition.call("interact", kind)
            elif kind.begins_with("market_v062_"):
                var market: Node = get_tree().get_first_node_in_group("magnara_markets_v062")
                if is_instance_valid(market) and market.has_method("interact"):
                    market.call("interact", kind)
            elif kind.begins_with("work_v061_") or kind.begins_with("npc_v061_"):
                var workshops: Node = get_tree().get_first_node_in_group("magnara_workshops_v061")
                if is_instance_valid(workshops) and workshops.has_method("interact"):
                    workshops.call("interact", kind)
            elif kind.begins_with("npc_v060_"):
                var residential: Node = get_tree().get_first_node_in_group("residential_life_v060")
                if is_instance_valid(residential) and residential.has_method("interact"):
                    residential.call("interact", kind)
            elif kind.begins_with("yb_v057_") or kind == "yb_v059_archive":
                var life_road: Node = get_tree().get_first_node_in_group("young_blood_life_v057")
                if is_instance_valid(life_road) and life_road.has_method("interact"):
                    life_road.call("interact", kind)
            elif kind == "daily_v051_bulletin":
                var city_events: Node = get_tree().get_first_node_in_group("daily_events_v051")
                if is_instance_valid(city_events) and city_events.has_method("interact"):
                    city_events.call("interact", kind)
            elif kind.begins_with("herb"):
                _gather_herb(kind)
    # Log first NPC meetings/known public landmarks after the real interaction.
    var codex: Node = get_tree().get_first_node_in_group("personal_codex")
    if is_instance_valid(codex) and codex.has_method("record_interaction"):
        codex.call("record_interaction", kind, str(nearest["title"]))
    var relations: Node = get_tree().get_first_node_in_group("seeker_relationships")
    if is_instance_valid(relations) and bool(relations.call("supports", kind)):
        relations.call("open_dialogue", kind, str(nearest["title"]))


func _npc_dialogue(kind: String) -> void:
    var hour: int = int(floor(float(int(world_minutes) % 1440) / 60.0))
    match kind:
        "npc_canal":
            _announce("Canal guide: 'The bronze lamps illuminate Ring Two at dusk. Stay clear of the waterways.'")
        "npc_vendor":
            _announce("Market seller: 'Supplies arrive from all across Margerina. Hanami handles the official guild stock.'")
        "npc_scout":
            _announce("Seeker scout: 'Patrols rotate at sundown. It's hour %d; train before the next watch.'" % hour)


func _open_board() -> void:
    bag_panel.hide()
    _clear_list(board_list)
    _label(board_list, "Magnara Seeker Quarters - Provisional contracts (Stray)", 18)
    var life_road: Node = get_tree().get_first_node_in_group("young_blood_life_v057")
    var not_licensed: bool = is_instance_valid(life_road) and life_road.has_method("may_accept_seeker_contracts") and not bool(life_road.call("may_accept_seeker_contracts"))
    if not_licensed:
        _label(board_list, "Your current civilian life road does not grant licensed Seeker work. Register through official qualification in a later chapter.", 17)
    for index in range(CONTRACTS.size()):
        var button := Button.new()
        button.custom_minimum_size = Vector2(0, 66)
        button.add_theme_font_size_override("font_size", 19)
        var title_text: String = CONTRACTS[index]
        if not_licensed:
            button.disabled = true
        var award: String = "%d Tola / %d XP" % [REWARDS[index], XP_REWARDS[index]]
        if contract_finished[index]:
            button.text = "COMPLETE - " + title_text + "\n" + award
            button.disabled = true
        elif active_contract == index and progress >= _goal_for(index) and index != 0:
            button.text = "CLAIM REWARD - " + title_text + "\n" + award
        elif active_contract == index:
            button.text = "ACTIVE (%d/%d) - " % [progress, _goal_for(index)] + title_text
            button.disabled = true
        elif active_contract >= 0:
            button.text = "LOCKED UNTIL CURRENT CONTRACT ENDS - " + title_text
            button.disabled = true
        else:
            button.text = "ACCEPT - " + title_text + "\n" + award
        button.pressed.connect(_choose_contract.bind(index))
        board_list.add_child(button)
    board_panel.show()


func _goal_for(index: int) -> int:
    return 1 if index == 0 else 3


func _choose_contract(index: int) -> void:
    var life_road: Node = get_tree().get_first_node_in_group("young_blood_life_v057")
    if is_instance_valid(life_road) and life_road.has_method("may_accept_seeker_contracts") and not bool(life_road.call("may_accept_seeker_contracts")):
        _announce("A civilian life road does not grant a Seeker work licence.")
        return
    if contract_finished[index]:
        return
    if active_contract == index:
        if index != 0 and progress >= _goal_for(index):
            _finish_contract()
        board_panel.hide()
        return
    if active_contract != -1:
        return
    active_contract = index
    progress = 0
    gathered.clear()
    if index == 0:
        inventory["Field Kit"] = int(inventory.get("Field Kit", 0)) + 1
        _announce("Field Kit accepted. Deliver it to Hanami (blue-robed NPC).")
    elif index == 1:
        _announce("Find three green medicinal herbs west of the main path.")
    else:
        _announce("Train at the wooden post south of the contract board. Requires Aura.")
    _update_plants()
    board_panel.hide()
    _save_game()


func _talk_to_hanami() -> void:
    if active_contract == 0 and int(inventory.get("Field Kit", 0)) > 0:
        inventory["Field Kit"] = int(inventory.get("Field Kit", 0)) - 1
        progress = 1
        _finish_contract()
        return
    _announce("Hanami: 'Keep your gear ready. Essence Tonics cost %d Tola today.'" % int(_origin_effects_v058().get("tonic_price", 12)))
    _open_bag(true)


func _train_at_post() -> void:
    if active_contract != 2:
        _announce("This wooden post is for Aura drills. Check the contract board first.")
        return
    if aura < 15.0:
        _announce("Not enough Aura for a strike. Recover before continuing.")
        return
    if progress >= 3:
        _announce("Training complete. Return to the contract board to claim your reward.")
        return
    aura -= 15.0
    stamina = maxf(0.0, stamina - 6.0)
    progress += 1
    _announce("Aura strike %d/3! -15 Aura. Return to the board at 3/3." % progress)
    _save_game()


func _gather_herb(herb_id: String) -> void:
    if active_contract != 1 or gathered.has(herb_id):
        return
    gathered[herb_id] = true
    progress = gathered.size()
    inventory["Medicinal Herb"] = int(inventory.get("Medicinal Herb", 0)) + 1
    _update_plants()
    _announce("Medicinal herbs %d/3 gathered. Return to the board when ready." % progress)
    _save_game()


func _update_plants() -> void:
    for key in plants.keys():
        var node: Node3D = plants[key]
        node.visible = active_contract == 1 and not gathered.has(key)


func _finish_contract() -> void:
    if active_contract < 0 or progress < _goal_for(active_contract):
        return
    var old_contract: int = active_contract
    if old_contract == 1:
        inventory["Medicinal Herb"] = maxi(0, int(inventory.get("Medicinal Herb", 0)) - 3)
    contract_finished[old_contract] = true
    GameState.earn_tola(REWARDS[old_contract])
    experience += XP_REWARDS[old_contract]
    guild_rep += 1
    active_contract = -1
    progress = 0
    gathered.clear()
    _update_plants()
    _announce("CONTRACT COMPLETE! +%d Tola, +%d XP, +1 guild reputation." % [REWARDS[old_contract], XP_REWARDS[old_contract]])
    _save_game()
    var codex: Node = get_tree().get_first_node_in_group("personal_codex")
    if is_instance_valid(codex) and codex.has_method("record_contract"):
        codex.call("record_contract", old_contract, CONTRACTS[old_contract], REWARDS[old_contract], XP_REWARDS[old_contract])
    var society: Node = get_tree().get_first_node_in_group("seeker_society")
    if is_instance_valid(society) and society.has_method("record_contract_outcome"):
        society.call("record_contract_outcome", old_contract)


func _toggle_bag() -> void:
    if bag_panel.visible:
        bag_panel.hide()
    else:
        _open_bag(false)


func _open_bag(shop_mode: bool) -> void:
    board_panel.hide()
    _clear_list(bag_list)
    _label(bag_list, "Tola: %d / Guild reputation: %d / XP: %d" % [GameState.tola, guild_rep, experience], 20)
    for name_text in ["Vitality Draught", "Essence Tonic", "Field Kit", "Medicinal Herb"]:
        var amount: int = int(inventory.get(name_text, 0))
        _label(bag_list, "%s: %d" % [name_text, amount], 18)
    var drink := Button.new()
    drink.text = "USE ESSENCE TONIC (+35 Aura)"
    drink.custom_minimum_size.y = 48
    drink.disabled = int(inventory.get("Essence Tonic", 0)) < 1
    drink.pressed.connect(_drink_tonic)
    bag_list.add_child(drink)
    var recover := Button.new()
    recover.text = "USE VITALITY DRAUGHT (+35 Stamina)"
    recover.custom_minimum_size.y = 48
    recover.disabled = int(inventory.get("Vitality Draught", 0)) < 1
    recover.pressed.connect(_drink_draught)
    bag_list.add_child(recover)
    if shop_mode:
        var buy := Button.new()
        buy.text = "BUY ESSENCE TONIC FROM HANAMI - %d TOLA" % int(_origin_effects_v058().get("tonic_price", 12))
        buy.custom_minimum_size.y = 48
        buy.disabled = GameState.tola < int(_origin_effects_v058().get("tonic_price", 12))
        buy.pressed.connect(_buy_tonic)
        bag_list.add_child(buy)
    bag_panel.show()


func _drink_tonic() -> void:
    if int(inventory.get("Essence Tonic", 0)) <= 0:
        return
    inventory["Essence Tonic"] = int(inventory.get("Essence Tonic", 0)) - 1
    aura = minf(100.0, aura + 35.0)
    bag_panel.hide()
    _announce("Essence Tonic used. Aura restored.")
    _save_game()


func _drink_draught() -> void:
    if int(inventory.get("Vitality Draught", 0)) <= 0:
        return
    inventory["Vitality Draught"] = int(inventory.get("Vitality Draught", 0)) - 1
    stamina = minf(100.0, stamina + 35.0)
    bag_panel.hide()
    _announce("Vitality Draught used. Stamina restored.")
    _save_game()


func _buy_tonic() -> void:
    var price: int = int(_origin_effects_v058().get("tonic_price", 12))
    if not GameState.spend_tola(price):
        _announce("Not enough Tola for an Essence Tonic.")
        return
    inventory["Essence Tonic"] = int(inventory.get("Essence Tonic", 0)) + 1
    bag_panel.hide()
    _announce("Bought 1 Essence Tonic for %d Tola." % price)
    _save_game()


func _refresh_status() -> void:
    if not is_instance_valid(top_status):
        return
    var day: int = int(floor(world_minutes / 1440.0)) + 1
    var minute_of_day: int = int(world_minutes) % 1440
    top_status.text = "%s SEEKER | %d TOLA | REP %d | XP %d | DAY %d %02d:%02d" % [GameState.seeker_rank.to_upper(), GameState.tola, guild_rep, experience, day, int(minute_of_day / 60), minute_of_day % 60]
    aura_bar.value = aura
    stamina_bar.value = stamina
    if active_contract < 0:
        quest_status.text = "CONTRACT: Visit the board (%d/3 done)" % _finished_count()
    else:
        quest_status.text = "%s: %d/%d" % [CONTRACTS[active_contract], progress, _goal_for(active_contract)]
    var spot := _nearest_location()
    if spot.is_empty():
        proximity_label.text = "Approach a landmark, then tap TALK / USE"
    else:
        proximity_label.text = "NEAR: " + str(spot["title"]) + " - TAP TALK / USE"
    notice_label.text = last_notice if notice_timeout > 0.0 else ""


func _finished_count() -> int:
    var result: int = 0
    for complete in contract_finished:
        if complete:
            result += 1
    return result


func _announce(message: String) -> void:
    last_notice = message
    notice_timeout = 7.0
    _refresh_status()


# V0.48: one-time prototype field pay, kept in the existing version-1 save.
func award_field_payout_once(receipt_id: String, amount: int) -> bool:
    var allowed_receipts: Dictionary = {"public_quarter_field_watch": 22, "waystation_convoy_v050": 30}
    if not allowed_receipts.has(receipt_id) or int(allowed_receipts[receipt_id]) != amount:
        return false
    if field_reward_receipts.has(receipt_id):
        return false
    field_reward_receipts[receipt_id] = true
    GameState.earn_tola(amount)
    _save_game()
    return true


func _save_game() -> bool:
    var data := {
        "version": 1,
        "tola": GameState.tola,
        "rank": GameState.seeker_rank,
        "xp": experience,
        "rep": guild_rep,
        "aura": aura,
        "stamina": stamina,
        "world_minutes": world_minutes,
        "active": active_contract,
        "progress": progress,
        "finished": contract_finished,
        "inventory": inventory,
        "gathered": gathered,
        "position": [player.global_position.x, player.global_position.y, player.global_position.z],
        "camera_yaw": player.get("wanted_yaw"),
        "camera_pitch": player.get("wanted_pitch"),
        "field_reward_receipts": field_reward_receipts,
        "market_stock_v062": market_stock_v062
    }
    if not SaveIntegrityV063.write_verified(data):
        _announce("Save failed verification. Your previous game was protected; check browser storage.")
        return false
    return true

func _save_with_notice() -> void:
    if _save_game():
        _announce("Game saved and verified with a protected previous save.")


func _load_with_notice() -> void:
    _load_game(true)


func _load_game(show_feedback: bool) -> void:
    var checked: Dictionary = SaveIntegrityV063.load_best()
    var source: String = str(checked.get("source", "none"))
    if source == "none":
        if show_feedback:
            if FileAccess.file_exists(SAVE_FILE):
                _announce("Saved game is unreadable. The original file was not overwritten.")
            else:
                _announce("No saved game found yet. Play a contract, then tap SAVE.")
        return
    var data: Dictionary = checked.get("data", {})
    if source == "backup":
        if SaveIntegrityV063.restore_backup():
            _announce("Recovered the previous verified game after a damaged save.")
        else:
            _announce("Previous save loaded, but storage recovery failed. New saves are protected.")
    GameState.tola = maxi(0, int(data.get("tola", 100)))
    GameState.seeker_rank = str(data.get("rank", "Stray"))
    experience = maxi(0, int(data.get("xp", 0)))
    guild_rep = maxi(0, int(data.get("rep", 0)))
    aura = clampf(float(data.get("aura", 100.0)), 0.0, 100.0)
    stamina = clampf(float(data.get("stamina", 100.0)), 0.0, 100.0)
    world_minutes = maxf(0.0, float(data.get("world_minutes", 480.0)))
    active_contract = clampi(int(data.get("active", -1)), -1, 2)
    progress = clampi(int(data.get("progress", 0)), 0, 3)
    # Market purchases, bag contents and Tola are committed in the same
    # legacy save file. The new key defaults to empty on older profiles.
    var market_raw: Variant = data.get("market_stock_v062", {})
    if typeof(market_raw) == TYPE_DICTIONARY:
        market_stock_v062 = market_raw
    else:
        market_stock_v062 = {}
    var existing_field_receipts: Variant = data.get("field_reward_receipts", {})
    if typeof(existing_field_receipts) == TYPE_DICTIONARY:
        field_reward_receipts = existing_field_receipts
    var completed: Variant = data.get("finished", [false, false, false])
    if typeof(completed) == TYPE_ARRAY and completed.size() == 3:
        for i in range(3):
            contract_finished[i] = bool(completed[i])
    var items: Variant = data.get("inventory", {})
    if typeof(items) == TYPE_DICTIONARY:
        inventory = items
    var picked: Variant = data.get("gathered", {})
    if typeof(picked) == TYPE_DICTIONARY:
        gathered = picked
    var position_data: Variant = data.get("position", [])
    if typeof(position_data) == TYPE_ARRAY and position_data.size() == 3:
        var new_pos := Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
        if (absf(new_pos.x) < 33.5 and new_pos.z > -29.5 and new_pos.z < 129.0) or (absf(new_pos.x) < 105.5 and new_pos.z >= 30.0 and new_pos.z < 109.5) or WorldGeoV054.safe_city_save(new_pos) or JanoahRegionV055.safe_approach_save(new_pos):
            player.global_position = new_pos
            player.velocity = Vector3.ZERO
    var yaw: float = float(data.get("camera_yaw", 0.0))
    var pitch: float = float(data.get("camera_pitch", 0.0))
    player.set("wanted_yaw", yaw)
    player.set("wanted_pitch", pitch)
    var pivot: Node3D = player.get_node("CameraPivot")
    pivot.rotation = Vector3(pitch, yaw, 0.0)
    _update_plants()
    board_panel.hide()
    bag_panel.hide()
    if show_feedback:
        _announce("Saved game restored. Welcome back to the Seeker Quarters.")
