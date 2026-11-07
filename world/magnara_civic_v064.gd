extends Node3D
# V0.64 / game-only Ring II civic services: accessible inn, registry counter and
# mundane clinic. Addresses, staff, geometry and economy are NOT new series canon.
const Rules = preload("res://systems/magnara_civic_rules_v064.gd")
const SERVICE_IDS: Array[String] = ["inn", "records", "clinic"]
const NAMES: Array[String] = ["Public Traveler's Inn", "Civic Wayfinding Desk", "Neighborhood Clinic"]
const SITES: Array[Vector3] = [
    Vector3(-96.0, 0.0, 423.0),
    Vector3(96.0, 0.0, 423.0),
    Vector3(96.0, 0.0, 479.0)
]
var hub: Node
var codex: Node
var player: CharacterBody3D
var initialized: bool = false
var panel: PanelContainer
var heading: Label
var details: Label
var feedback: Label
var actions: VBoxContainer
var selected: String = ""
var workers: Dictionary = {}
var mesh_cache: Dictionary = {}
var mat_cache: Dictionary = {}
var tick: float = 0.0

func _ready() -> void:
    add_to_group("magnara_civic_v064")
    set_process(false)
    call_deferred("_setup")

func _setup() -> void:
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(player):
        push_warning("V0.64 public civic quarter requires existing player, hub and Codex")
        return
    _make_streets()
    for i in range(SERVICE_IDS.size()):
        _make_service(i)
    _make_panel()
    initialized = true
    _update_workers()
    set_process(true)

func get_manifest() -> Dictionary:
    return {
        "version": 64, "city": "Magnara", "ring": 2, "source_status": "game_only",
        "civic_buildings": SERVICE_IDS.size(), "enterable": true,
        "night_cost": Rules.NIGHT_COST, "clinic_cost": Rules.CLINIC_COST,
        "proposed_coordinates_only": true,
        "three_connected_road_spines": true, "ring_iv_merchant_quarter_unchanged": true,
        "hub_save_same_file": true, "official_association_promotions": false
    }

func _mat(color: Color) -> StandardMaterial3D:
    var key: String = str(color)
    if mat_cache.has(key):
        return mat_cache[key]
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.roughness = 0.87
    mat_cache[key] = result
    return result

func _part(parent: Node3D, title: String, offset: Vector3, extent: Vector3,
        shade: Color, collidable: bool = false) -> MeshInstance3D:
    var piece := MeshInstance3D.new()
    piece.name = title
    piece.position = offset
    var size_key: String = str(extent)
    var shape: BoxMesh
    if mesh_cache.has(size_key):
        shape = mesh_cache[size_key]
    else:
        shape = BoxMesh.new()
        shape.size = extent
        mesh_cache[size_key] = shape
    piece.mesh = shape
    piece.material_override = _mat(shade)
    piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(piece)
    if collidable:
        var body := StaticBody3D.new()
        body.name = title + "Static"
        piece.add_child(body)
        var col := CollisionShape3D.new()
        col.name = "CivicV064WorldCollision"
        var bounds := BoxShape3D.new()
        bounds.size = extent
        col.shape = bounds
        body.add_child(col)
    return piece

func _sign(parent: Node3D, label: String, at: Vector3) -> void:
    var sign := Label3D.new()
    sign.name = "CivicV064Wayfinding"
    sign.text = label
    sign.position = at
    sign.font_size = 30
    sign.pixel_size = 0.006
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.no_depth_test = true
    parent.add_child(sign)

func _make_streets() -> void:
    # V0.62's three physical roads terminate at z=376. This section joins
    # them with 8 meters of shared pavement instead of a visual teleport.
    for x in [-62.0, 0.0, 62.0]:
        _part(self, "CivicV064NorthStreet", Vector3(x, 0.59, 439.5),
            Vector3(10.5, 0.14, 137.0), Color(0.66, 0.64, 0.60), true)
        for side in [-1.0, 1.0]:
            _part(self, "CivicV064PedestrianStrip", Vector3(x + 7.2 * side, 0.61, 439.5),
                Vector3(2.65, 0.14, 137.0), Color(0.78, 0.73, 0.65), true)
    for z in [423.0, 480.0]:
        _part(self, "CivicV064CrossAvenue", Vector3(0.0, 0.63, z),
            Vector3(130.0, 0.14, 8.8), Color(0.69, 0.67, 0.62), true)
    for x in [-62.0, 62.0]:
        for z in [400.0, 453.0, 497.0]:
            _part(self, "CivicV064LampPost", Vector3(x + 9.0, 2.1, z),
                Vector3(0.19, 3.0, 0.19), Color(0.39, 0.34, 0.27), true)
            _part(self, "CivicV064BlueLantern", Vector3(x + 9.0, 3.77, z),
                Vector3(0.64, 0.68, 0.64), Color(0.31, 0.68, 0.78))
    _part(self, "CivicV064PublicNoticePlinth", Vector3(0.0, 1.1, 452.0),
        Vector3(3.6, 1.05, 1.5), Color(0.53, 0.56, 0.55), true)
    _sign(self, "RING TWO / TRAVELERS, CIVIC SERVICES AND PUBLIC CARE / GAME-ONLY",
        Vector3(0.0, 5.2, 388.0))

func _make_service(index: int) -> void:
    var key: String = SERVICE_IDS[index]
    var building := Node3D.new()
    building.name = "CivicV064Building_" + key
    building.position = SITES[index]
    add_child(building)
    var color: Color = Color(0.55, 0.50, 0.44) if index == 0 else (
        Color(0.66, 0.65, 0.59) if index == 1 else Color(0.67, 0.72, 0.69))
    var roof: Color = Color(0.30, 0.34, 0.38) if index == 0 else Color(0.33, 0.39, 0.41)
    var trim: Color = Color(0.65, 0.48, 0.27) if index == 0 else (
        Color(0.39, 0.56, 0.67) if index == 1 else Color(0.39, 0.62, 0.56))
    var facing: float = 1.0 if index == 0 else -1.0
    var edge: float = 9.0
    _part(building, "CivicV064InteriorFloor", Vector3(0, 0.54, 0),
        Vector3(18.0, 0.14, 18.0), Color(0.74, 0.68, 0.59), true)
    _part(building, "CivicV064RearWall", Vector3(-facing * edge, 3.0, 0),
        Vector3(0.42, 5.0, 18.2), color, true)
    for side in [-1.0, 1.0]:
        _part(building, "CivicV064SideWall", Vector3(0.0, 3.0, side * edge),
            Vector3(18.2, 5.0, 0.42), color, true)
        _part(building, "CivicV064EntranceWing", Vector3(facing * edge, 3.0, side * 5.75),
            Vector3(0.42, 5.0, 6.5), color, true)
    _part(building, "CivicV064OpenDoorLintel", Vector3(facing * edge, 4.85, 0),
        Vector3(0.45, 1.3, 5.0), color, true)
    _part(building, "CivicV064SolidRoof", Vector3(0, 5.58, 0),
        Vector3(18.65, 0.28, 18.65), roof, true)
    _part(building, "CivicV064FrontTrim", Vector3(facing * 9.30, 5.18, 0),
        Vector3(0.23, 0.35, 16.0), trim)
    _part(building, "CivicV064ServiceCounter", Vector3(-facing * 1.7, 1.25, 0),
        Vector3(1.6, 1.16, 6.6), Color(0.44, 0.37, 0.31), true)
    if index == 0:
        for side in [-1.0, 1.0]:
            _part(building, "CivicV064GuestBed", Vector3(-facing * 4.3, 1.0, side * 5.0),
                Vector3(2.3, 0.73, 4.2), Color(0.42, 0.48, 0.58), true)
            _part(building, "CivicV064BedPillow", Vector3(-facing * 4.3, 1.46, side * 6.05),
                Vector3(1.55, 0.16, 0.75), Color(0.87, 0.83, 0.74))
        _part(building, "CivicV064GuestLockers", Vector3(-facing * 6.6, 1.18, 0),
            Vector3(0.9, 1.3, 1.8), Color(0.49, 0.40, 0.32), true)
    elif index == 1:
        for side in [-1.0, 1.0]:
            _part(building, "CivicV064PublicRecordShelf", Vector3(-facing * 6.4, 1.82, side * 5.4),
                Vector3(1.0, 2.6, 2.5), Color(0.42, 0.36, 0.30), true)
        _part(building, "CivicV064MapTable", Vector3(facing * 3.5, 1.04, -5.0),
            Vector3(3.2, 0.94, 2.4), Color(0.51, 0.45, 0.36), true)
    else:
        for side in [-1.0, 1.0]:
            _part(building, "CivicV064RecoveryCot", Vector3(-facing * 4.5, 0.95, side * 4.6),
                Vector3(2.5, 0.70, 3.9), Color(0.63, 0.70, 0.70), true)
        _part(building, "CivicV064SupplyCabinet", Vector3(-facing * 6.45, 2.0, 0),
            Vector3(0.8, 2.9, 2.4), Color(0.62, 0.65, 0.59), true)
    var street_x: float = -62.0 if index == 0 else 62.0
    var doorway_x: float = SITES[index].x + facing * 9.0
    _part(self, "CivicV064DoorwayPavement_" + key,
        Vector3((street_x + doorway_x) * 0.5, 0.65, SITES[index].z),
        Vector3(absf(doorway_x - street_x) + 2.0, 0.14, 3.2),
        Color(0.78, 0.74, 0.67), true)
    _sign(building, NAMES[index].to_upper() + " / PUBLIC SERVICE",
        Vector3(0, 6.4, 0))
    var marker := Node3D.new()
    marker.name = "CivicV064InteractionPoint"
    marker.position = Vector3(facing * 11.0, 0.67, 0)
    building.add_child(marker)
    hub.call("_add_location", "civic_v064_" + key, NAMES[index],
        marker.global_position, marker)
    var employee := Node3D.new()
    employee.name = "CivicV064Staff_" + key
    employee.position = Vector3(-facing * 3.15, 0.0, 0)
    building.add_child(employee)
    _part(employee, "CivicV064StaffTorso", Vector3(0, 1.22, 0),
        Vector3(0.65, 0.98, 0.42), trim)
    _part(employee, "CivicV064StaffHead", Vector3(0, 1.96, 0),
        Vector3(0.42, 0.44, 0.40), Color(0.61, 0.48, 0.36))
    for side in [-1.0, 1.0]:
        _part(employee, "CivicV064StaffLeg", Vector3(side * 0.19, 0.43, 0),
            Vector3(0.19, 0.79, 0.28), Color(0.32, 0.33, 0.37))
    workers[key] = employee

func _make_panel() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "CivicCanvasV064"
    canvas.layer = 22
    get_parent().add_child(canvas)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(root)
    panel = PanelContainer.new()
    panel.anchor_left = 0.11
    panel.anchor_right = 0.89
    panel.anchor_top = 0.08
    panel.anchor_bottom = 0.91
    panel.visible = false
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.07, 0.095, 0.135, 0.98)
    style.border_color = Color(0.58, 0.63, 0.57)
    style.set_border_width_all(2)
    style.set_corner_radius_all(9)
    panel.add_theme_stylebox_override("panel", style)
    root.add_child(panel)
    var margin := MarginContainer.new()
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 14)
    panel.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 9)
    margin.add_child(stack)
    heading = Label.new()
    heading.add_theme_font_size_override("font_size", 24)
    stack.add_child(heading)
    details = Label.new()
    details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(details)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_child(scroll)
    actions = VBoxContainer.new()
    actions.add_theme_constant_override("separation", 8)
    actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(actions)
    feedback = Label.new()
    feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(feedback)
    var close := Button.new()
    close.text = "RETURN TO MAGNARA"
    close.custom_minimum_size.y = 50
    close.pressed.connect(_close)
    stack.add_child(close)

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()

func _clock() -> float:
    return float(hub.get("world_minutes"))

func _book() -> Dictionary:
    return Rules.sanitize(hub.get("civic_v064"))

func _button(label: String, action: String, enabled: bool = true) -> void:
    var button := Button.new()
    button.text = label
    button.custom_minimum_size.y = 51
    button.disabled = not enabled
    button.pressed.connect(_choose.bind(action))
    actions.add_child(button)

func interact(id: String) -> void:
    if not initialized or not id.begins_with("civic_v064_"):
        return
    selected = id.trim_prefix("civic_v064_")
    if not SERVICE_IDS.has(selected):
        return
    feedback.text = ""
    _refresh()
    panel.show()

func _refresh() -> void:
    for child in actions.get_children():
        actions.remove_child(child)
        child.queue_free()
    var clock: float = _clock()
    var day: int = Rules.day_at(clock)
    var time: int = Rules.local_minute(clock)
    var open: bool = Rules.open_for(selected, clock)
    var book: Dictionary = _book()
    heading.text = NAMES[SERVICE_IDS.find(selected)].to_upper()
    details.text = "Ring Two / Day %d / %02d:%02d / %s\nTola: %d / Stamina: %.0f / Aura: %.0f" % [
        day, int(time / 60), time % 60, "STAFFED" if open else "OFF DUTY",
        GameState.tola, float(hub.get("stamina")), float(hub.get("aura"))]
    if selected == "inn":
        details.text += "\nPublic room: %d Tola each in-game day. Book a room, then use it for one full night's rest." % Rules.NIGHT_COST
        _button("BOOK TODAY'S ROOM / %d TOLA" % Rules.NIGHT_COST, "checkin",
            Rules.can("checkin", clock, book, GameState.tola))
        _button("SLEEP UNTIL 06:00 NEXT MORNING", "sleep",
            Rules.can("sleep", clock, book, GameState.tola))
    elif selected == "records":
        details.text += "\nDesk open 09:00-17:00. Public wayfinding and voluntary parcel sorting."
        _button("READ PUBLIC WAYFINDING", "read", true)
        _button("ASSIST WITH TODAY'S RECORD SORTING / +%d TOLA" % Rules.CIVIC_HELP_PAY,
            "assist", Rules.can("assist", clock, book, GameState.tola))
    else:
        details.text += "\nClinic staffed 07:00-20:00. A routine rest-and-recovery visit costs %d Tola." % Rules.CLINIC_COST
        _button("REQUEST BASIC MEDICAL GUIDANCE", "advice", true)
        _button("RECOVER STAMINA AND AURA / %d TOLA" % Rules.CLINIC_COST,
            "treatment", Rules.can("treatment", clock, book, GameState.tola))

func _verify_receipt(kind: String, day: int) -> bool:
    var loaded: Dictionary = Rules.sanitize(hub.get("civic_v064"))
    var stored: Dictionary = Rules.sanitize({})
    var checked: Dictionary = preload("res://systems/game_save_integrity_v063.gd").load_best()
    var data: Dictionary = checked.get("data", {})
    if not data.is_empty():
        stored = Rules.sanitize(data.get("civic_v064", {}))
    return Rules.has_receipt(loaded, kind, day) and Rules.has_receipt(stored, kind, day) \
        and int(data.get("tola", -1)) == GameState.tola

func _commit(action: String) -> void:
    if not Rules.can(action, _clock(), _book(), GameState.tola):
        feedback.text = "This service is closed, already used today, or you cannot afford it."
        _refresh()
        return
    var day: int = Rules.day_at(_clock())
    var receipt: String = ""
    var debit: int = 0
    var credit: int = 0
    match action:
        "checkin":
            receipt = "nights"
            debit = Rules.NIGHT_COST
        "sleep":
            receipt = "slept"
        "treatment":
            receipt = "treatments"
            debit = Rules.CLINIC_COST
        "assist":
            receipt = "helped"
            credit = Rules.CIVIC_HELP_PAY
        _:
            return
    var updated: Dictionary = Rules.mark(_book(), receipt, day)
    if updated.is_empty():
        feedback.text = "Today's receipt was already recorded."
        return
    var old_coin: int = GameState.tola
    var old_time: float = _clock()
    var old_stamina: float = float(hub.get("stamina"))
    var old_aura: float = float(hub.get("aura"))
    var old_book: Dictionary = _book()
    if debit > 0 and not GameState.spend_tola(debit):
        feedback.text = "You need more Tola to use this service."
        return
    if credit > 0:
        GameState.earn_tola(credit)
    hub.set("civic_v064", updated)
    if action == "sleep":
        hub.set("world_minutes", Rules.next_morning(old_time))
        hub.set("stamina", 100.0)
        hub.set("aura", 100.0)
    elif action == "treatment":
        hub.set("stamina", 100.0)
        hub.set("aura", 100.0)
    var persisted: bool = bool(hub.call("_save_game")) and _verify_receipt(receipt, day)
    if not persisted:
        # Save could fail: return the real money, clock, energy and receipt
        # to the previous state. Never show success for an unverified receipt.
        GameState.tola = old_coin
        GameState.tola_changed.emit(old_coin)
        hub.set("world_minutes", old_time)
        hub.set("stamina", old_stamina)
        hub.set("aura", old_aura)
        hub.set("civic_v064", old_book)
        feedback.text = "Storage failed verification. Your payment and action were reversed."
        _refresh()
        return
    var names: Dictionary = {
        "checkin": "Booked a local travel room", "sleep": "Slept at the public inn",
        "treatment": "Visited the neighborhood clinic", "assist": "Assisted at the civic records desk"
    }
    if is_instance_valid(codex) and codex.has_method("record_event"):
        codex.call("record_event", "v064:%s:day:%d" % [action, day],
            "public_civic_service", str(names[action]),
            "Game-only Ring Two daily-life service; verified receipt and Tola saved together.")
    feedback.text = "%s. Your verified city-life record was saved." % str(names[action])
    _refresh()

func _choose(action: String) -> void:
    if action == "read":
        feedback.text = "Public directions: Market street lies to the south; civil lodging and neighborhood services lie along this lane. The guarded Citadel is not open to casual visitors."
        return
    if action == "advice":
        feedback.text = "Clinic staff: Rest, food, water and safe training all matter. Seek professional instruction before pushing aura output beyond control."
        return
    _commit(action)

func _update_workers() -> void:
    var minute: float = float(Rules.local_minute(_clock()))
    for key in SERVICE_IDS:
        if workers.has(key):
            var actor: Node3D = workers[key]
            var working: bool = Rules.open_for(key, _clock())
            actor.visible = working
            actor.position.z = sin(minute * 0.020 + float(SERVICE_IDS.find(key))) * 0.25 if working else 0.0

func _process(delta: float) -> void:
    tick += delta
    if tick >= 0.65:
        tick = 0.0
        _update_workers()
