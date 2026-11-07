extends Node3D
# V0.61 / additional walkable working street in Magnara's PUBLIC Ring Two.
# This is a local service-and-workshop street, NOT the canon Ring V artisan
# promenade, Nightweave Row or the Iron Cothon. All street sites are GAME ONLY.
const Rules = preload("res://systems/magnara_workshop_rules_v061.gd")
const Origins = preload("res://systems/young_blood_origins_v058.gd")
const Residential = preload("res://systems/residential_life_v060.gd")
const WORKING_LANE_X: float = -62.0
const BOARD_POSITION: Vector3 = Vector3(-73.0, 0.62, 119.0)
const DEPOT_POSITION: Vector3 = Vector3(-46.0, 0.62, 195.0)
const OFFICE_HOUR_START: int = 480
const OFFICE_HOUR_END: int = 1140

var hub: Node
var codex: Node
var player: CharacterBody3D
var initialized: bool = false
var panel: PanelContainer
var title_label: Label
var description_label: Label
var feedback: Label
var choices: VBoxContainer
var current_station: String = ""
var resource_materials: Dictionary = {}
var resource_meshes: Dictionary = {}
var workers: Dictionary = {}
var tick: float = 0.0
var lantern: MeshInstance3D

func _ready() -> void:
    add_to_group("magnara_workshops_v061")
    set_process(false)
    call_deferred("_setup")

func _setup() -> void:
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(player):
        push_warning("V0.61 workshops require established player, hub and Personal Codex")
        return
    _build_district()
    _make_panel()
    initialized = true
    _update_workers()
    _refresh_lantern()
    set_process(true)

func get_manifest() -> Dictionary:
    return {
        "name": "Ring Two Working Service Lane", "status": "game_only",
        "era": "1500 A.S.", "physical_workshops": Rules.JOBS.size(),
        "job_stations": Rules.JOBS.size() + 2,
        "entrances": "three real open doorways",
        "road_axis_x": WORKING_LANE_X,
        "road_z_min": 109.0, "road_z_max": 248.0,
        "rail_link_live": false, "trains_operational": false,
        "class_variety": ["workshop", "freight", "repair"],
        "canon_ring_v_unchanged": true
    }

func _mat(color: Color) -> StandardMaterial3D:
    var key: String = str(color)
    if resource_materials.has(key):
        return resource_materials[key]
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.roughness = 0.81
    resource_materials[key] = result
    return result

func _part(parent: Node3D, label: String, at: Vector3, size: Vector3,
        color: Color, solid: bool = false) -> MeshInstance3D:
    var shape := MeshInstance3D.new()
    shape.name = label
    var key: String = str(size)
    var mesh: BoxMesh
    if resource_meshes.has(key):
        mesh = resource_meshes[key]
    else:
        mesh = BoxMesh.new()
        mesh.size = size
        resource_meshes[key] = mesh
    shape.mesh = mesh
    shape.material_override = _mat(color)
    shape.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    shape.position = at
    parent.add_child(shape)
    if solid:
        var body := StaticBody3D.new()
        body.name = label + "Solid"
        shape.add_child(body)
        var collider := CollisionShape3D.new()
        collider.name = "WorkingDistrictCollision"
        var box := BoxShape3D.new()
        box.size = size
        collider.shape = box
        body.add_child(collider)
    return shape

func _tag(parent: Node3D, caption: String, at: Vector3, size: int = 30) -> void:
    var sign := Label3D.new()
    sign.name = "WorkingDistrictSign"
    sign.text = caption
    sign.position = at
    sign.font_size = size
    sign.pixel_size = 0.006
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.no_depth_test = true
    parent.add_child(sign)

func _site(id: String, label: String, at: Vector3, parent: Node3D) -> void:
    var spot := Node3D.new()
    spot.name = "WorkSite_" + id
    spot.position = at
    parent.add_child(spot)
    _tag(spot, label + " / TALK", Vector3(0, 2.6, 0), 23)
    _part(spot, "VisibleJobMarker", Vector3(0, 0.64, 0),
        Vector3(0.58, 1.25, 0.58), Color(0.42, 0.68, 0.70))
    hub.call("_add_location", "work_v061_" + id, label, spot.global_position, spot)

func _workshop(id: String, index: int) -> void:
    var room := Node3D.new()
    room.name = "OpenWorkshop_" + id
    room.position = Vector3(-96.0, 0.0, Rules.ZONES[index])
    add_child(room)
    var stone: Color = Color(0.43, 0.49, 0.52) if index == 0 else (
        Color(0.61, 0.56, 0.51) if index == 1 else Color(0.48, 0.53, 0.54))
    var roof: Color = Color(0.25, 0.30, 0.34)
    _part(room, "InteriorStoneFloor", Vector3(0, 0.53, 0),
        Vector3(18.2, 0.13, 14.0), Color(0.61, 0.61, 0.57), true)
    _part(room, "RearIndustrialWall", Vector3(-9.0, 2.88, 0),
        Vector3(0.4, 4.58, 14.4), stone, true)
    for side in [-1.0, 1.0]:
        _part(room, "SideIndustrialWall", Vector3(0, 2.88, side * 7.0),
            Vector3(18.4, 4.58, 0.4), stone, true)
        _part(room, "DoorwayWing", Vector3(9.0, 2.88, side * 4.8),
            Vector3(0.4, 4.58, 4.7), stone, true)
        _part(room, "HighIndustrialWindow", Vector3(-2.4, 3.4, side * 7.25),
            Vector3(2.55, 1.1, 0.08), Color(0.34, 0.74, 0.75))
    _part(room, "DoorLintel", Vector3(9.0, 4.43, 0),
        Vector3(0.44, 1.5, 4.7), stone, true)
    _part(room, "WorkshopRoofDeck", Vector3(0, 5.35, 0),
        Vector3(18.6, 0.23, 14.5), roof, true)
    _part(room, "BronzeVentStack", Vector3(-5.1, 6.8, -3.5),
        Vector3(1.4, 2.6, 1.4), Color(0.47, 0.37, 0.26))
    _part(room, "WorkshopWorkBench", Vector3(-2.5, 1.05, 3.5),
        Vector3(4.6, 0.75, 1.5), Color(0.41, 0.35, 0.30), true)
    _part(room, "WorkshopServiceTable", Vector3(-3.0, 1.08, -3.8),
        Vector3(3.8, 0.85, 1.9), Color(0.46, 0.36, 0.26), true)
    for n in range(3):
        _part(room, "WorkshopToolRack", Vector3(-7.0, 1.1 + float(n) * 0.52, 1.5),
            Vector3(0.55, 0.28, 3.4), Color(0.35, 0.32, 0.31))
    if index == 0:
        _part(room, "ForgeStoneAnvil", Vector3(3.5, 1.08, -2.0),
            Vector3(2.0, 0.9, 1.2), Color(0.34, 0.39, 0.45), true)
        _part(room, "ForgeSafeEmberHearth", Vector3(-5.1, 1.05, -4.9),
            Vector3(2.2, 0.9, 1.7), Color(0.74, 0.38, 0.21), true)
    elif index == 1:
        _part(room, "ClothRepairLoom", Vector3(3.0, 1.55, -3.0),
            Vector3(1.7, 2.0, 2.9), Color(0.49, 0.40, 0.26), true)
        _part(room, "PatternRolls", Vector3(1.9, 1.04, 3.7),
            Vector3(2.5, 0.5, 0.8), Color(0.65, 0.54, 0.44))
    else:
        _part(room, "FreightLedgerDesk", Vector3(2.1, 1.15, 3.0),
            Vector3(2.9, 0.95, 1.55), Color(0.43, 0.35, 0.26), true)
        _part(room, "ParcelInspectionRack", Vector3(2.5, 1.35, -3.0),
            Vector3(2.9, 1.8, 0.85), Color(0.47, 0.42, 0.31), true)
    _tag(room, Rules.job_label(id).to_upper() + " / GAME-ONLY SERVICE",
        Vector3(9.6, 6.1, 0))
    _part(self, "WorkshopDoorPath_" + id,
        Vector3(-77.5, 0.58, Rules.ZONES[index]),
        Vector3(19.0, 0.13, 3.4), Color(0.67, 0.65, 0.61), true)
    _site("finish_" + id, Rules.job_label(id) + " Workbench",
        Vector3(3.8, 0.6, 0.0), room)

func _make_worker(id: String, index: int) -> void:
    var actor := Node3D.new()
    actor.name = "WorkshopWorker_" + id
    actor.position = Vector3(-79.0, 0.0, Rules.ZONES[index] + 6.5)
    add_child(actor)
    var coat := Color(0.39, 0.49, 0.58) if index == 0 else (
        Color(0.65, 0.53, 0.39) if index == 1 else Color(0.42, 0.47, 0.37))
    TownspersonVisual.add_to(actor, id, index % 2, coat)
    hub.call("_add_location", "npc_v061_" + id, Rules.job_label(id) + " Worker", actor.global_position, actor)
    workers[id] = actor

func _build_district() -> void:
    # Connect to the existing west professional district at z~=110.
    _part(self, "WorkingDistrictCollisionGround", Vector3(-70.0, 0.0, 179.0),
        Vector3(75.0, 1.0, 144.0), Color(0.50, 0.52, 0.54), true)
    _part(self, "NorthWorkingStreet", Vector3(-62.0, 0.58, 179.0),
        Vector3(10.5, 0.13, 143.0), Color(0.63, 0.61, 0.57), true)
    for side in [-1.0, 1.0]:
        _part(self, "WorkingPedestrianStrip", Vector3(-62.0 + side * 7.2, 0.61, 179.0),
            Vector3(2.8, 0.13, 143.0), Color(0.74, 0.72, 0.66), true)
        for n in range(8):
            _part(self, "BronzeStreetLampPost", Vector3(-62.0 + side * 9.0, 1.9, 117.0 + 17.0 * n),
                Vector3(0.17, 2.8, 0.17), Color(0.49, 0.37, 0.28))
            _part(self, "BronzeLampGlow", Vector3(-62.0 + side * 9.0, 3.38, 117.0 + 17.0 * n),
                Vector3(0.48, 0.55, 0.48), Color(0.24, 0.70, 0.78))
    # A new east-west public crossing links to V0.60's east residential lane.
    _part(self, "InterQuarterConnectorAvenue", Vector3(0, 0.60, 207.0),
        Vector3(124.0, 0.14, 9.0), Color(0.66, 0.64, 0.59), true)
    _part(self, "ResidentialRoadNorthernJoin", Vector3(62.0, 0.58, 200.5),
        Vector3(9.2, 0.13, 20.0), Color(0.70, 0.65, 0.58), true)
    _part(self, "CrossingPavingLeft", Vector3(-36.0, 0.65, 207.0),
        Vector3(10.0, 0.04, 7.4), Color(0.76, 0.74, 0.68))
    _part(self, "WorkingYardGravel", Vector3(-44.0, 0.59, 151.0),
        Vector3(19.0, 0.13, 28.0), Color(0.51, 0.50, 0.47), true)
    _part(self, "FreightLoadingPlatform", Vector3(-45.5, 0.90, 195.0),
        Vector3(8.8, 0.65, 10.0), Color(0.55, 0.56, 0.53), true)
    _part(self, "NonOperatingRailBed", Vector3(-39.4, 0.65, 173.0),
        Vector3(5.3, 0.19, 81.0), Color(0.39, 0.41, 0.43), true)
    for side in [-1.0, 1.0]:
        _part(self, "FreightRailSpur", Vector3(-39.4 + side * 1.25, 0.78, 173.0),
            Vector3(0.10, 0.10, 80.5), Color(0.59, 0.48, 0.35))
    for n in range(12):
        _part(self, "FreightTies", Vector3(-39.4, 0.75, 133.0 + float(n) * 7.0),
            Vector3(4.0, 0.12, 0.30), Color(0.30, 0.29, 0.28))
    for index in range(Rules.JOBS.size()):
        _workshop(Rules.JOBS[index], index)
        _make_worker(Rules.JOBS[index], index)
    var board := Node3D.new()
    board.name = "WorkingQuarterJobBoard"
    board.position = BOARD_POSITION
    add_child(board)
    _part(board, "WorkOfferBoard", Vector3(0, 1.52, 0),
        Vector3(2.85, 2.20, 0.34), Color(0.43, 0.34, 0.27), true)
    _tag(board, "MAGNARA / PUBLIC DAY WORK", Vector3(0, 3.38, 0))
    hub.call("_add_location", "work_v061_board", "Day Work Offers", BOARD_POSITION, board)
    var depot := Node3D.new()
    depot.name = "WorkingQuarterDepot"
    depot.position = DEPOT_POSITION
    add_child(depot)
    _part(depot, "PhysicalCargoCrate", Vector3(0, 0.88, 0),
        Vector3(1.8, 1.2, 1.7), Color(0.52, 0.39, 0.25), true)
    _tag(depot, "SUPPLIES / COLLECT WORK ORDER", Vector3(0, 2.5, 0))
    hub.call("_add_location", "work_v061_depot", "Working Supplies Depot", DEPOT_POSITION, depot)
    lantern = _part(self, "WorkshopSafetySignal", Vector3(-58.0, 3.35, 205.0),
        Vector3(0.61, 0.71, 0.61), Color(0.28, 0.65, 0.71))
    _tag(self, "PUBLIC WORKING SERVICE STREET / RING II / GAME ONLY",
        Vector3(-63.0, 5.60, 112.0))
    _tag(self, "LINK TO RESIDENTIAL LANE", Vector3(18.0, 4.30, 205.0), 25)

func _make_panel() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "WorkingQuarterCanvas"
    canvas.layer = 19
    get_parent().add_child(canvas)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(root)
    panel = PanelContainer.new()
    panel.anchor_left = 0.12
    panel.anchor_right = 0.88
    panel.anchor_top = 0.10
    panel.anchor_bottom = 0.90
    panel.visible = false
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(0.06, 0.08, 0.11, 0.97)
    skin.border_color = Color(0.67, 0.54, 0.38)
    skin.set_border_width_all(2)
    skin.set_corner_radius_all(10)
    panel.add_theme_stylebox_override("panel", skin)
    root.add_child(panel)
    var margins := MarginContainer.new()
    margins.add_theme_constant_override("margin_left", 15)
    margins.add_theme_constant_override("margin_right", 15)
    margins.add_theme_constant_override("margin_top", 15)
    margins.add_theme_constant_override("margin_bottom", 15)
    panel.add_child(margins)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 12)
    margins.add_child(stack)
    title_label = Label.new()
    title_label.add_theme_font_size_override("font_size", 24)
    stack.add_child(title_label)
    description_label = Label.new()
    description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(description_label)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_child(scroll)
    choices = VBoxContainer.new()
    choices.add_theme_constant_override("separation", 9)
    choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(choices)
    feedback = Label.new()
    feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(feedback)
    var close := Button.new()
    close.text = "BACK TO THE WORKING STREET"
    close.custom_minimum_size.y = 54
    close.pressed.connect(_close)
    stack.add_child(close)

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _day() -> int:
    return maxi(1, int(floor(float(hub.get("world_minutes")) / 1440.0)) + 1)

func _shift_open() -> bool:
    var minute: int = posmod(int(hub.get("world_minutes")), 1440)
    return minute >= OFFICE_HOUR_START and minute < OFFICE_HOUR_END

func _civilian_eligible() -> bool:
    var profile: Dictionary = codex.get("profile")
    var life: Dictionary = profile.get("life_v057", {})
    return str(life.get("road", "")) == "trade"

func _state() -> Dictionary:
    var profile: Dictionary = codex.get("profile")
    return Rules.sanitize(profile.get("workshops_v061", {}))

func _persist(next_work: Dictionary, next_origin: Dictionary = {}) -> bool:
    if not is_instance_valid(codex) or bool(codex.get("save_blocked")):
        return false
    var original: Dictionary = codex.get("profile")
    var next_profile: Dictionary = original.duplicate(true)
    next_profile["workshops_v061"] = Rules.sanitize(next_work)
    if not next_origin.is_empty():
        next_profile["origin_v058"] = Origins.sanitize(next_origin)
    codex.set("profile", next_profile)
    codex.call("_save_profile")
    var disk := FileAccess.open("user://seeker_profile_v1.json", FileAccess.READ)
    if disk == null:
        codex.set("profile", original)
        return false
    var loaded: Variant = JSON.parse_string(disk.get_as_text())
    disk.close()
    if typeof(loaded) != TYPE_DICTIONARY:
        codex.set("profile", original)
        return false
    var verified: bool = Rules.sanitize(loaded.get("workshops_v061", {})) == Rules.sanitize(next_work)
    if not next_origin.is_empty():
        verified = verified and Origins.sanitize(loaded.get("origin_v058", {})) == Origins.sanitize(next_origin)
    if not verified:
        codex.set("profile", original)
    return verified

func _button(caption: String, key: String, enabled: bool = true) -> void:
    var button := Button.new()
    button.text = caption
    button.disabled = not enabled
    button.custom_minimum_size.y = 52
    button.pressed.connect(_choose.bind(key))
    choices.add_child(button)

func interact(id: String) -> void:
    if not initialized or (not id.begins_with("work_v061_") and not id.begins_with("npc_v061_")):
        return
    if bool(codex.get("save_blocked")):
        hub.call("_announce", "The Personal Codex isn't writable. Work is paused to protect your record.")
        return
    current_station = "worker_" + id.trim_prefix("npc_v061_") if id.begins_with("npc_v061_") else id.trim_prefix("work_v061_")
    feedback.text = ""
    _refresh()
    panel.show()

func _refresh() -> void:
    for child in choices.get_children():
        choices.remove_child(child)
        child.queue_free()
    var record: Dictionary = _state()
    var active: Dictionary = record["active"]
    title_label.text = "MAGNARA / WORKING SERVICE QUARTER"
    description_label.text = "%s\n%s\nWorker trust: %d | Completed shifts: %d\n%s" % [
        Rules.stage_label(record),
        Rules.neighborhood_reply(record),
        int(record["worker_trust"]), int(record["completed"]),
        "Office open" if _shift_open() else "Office closed for new shifts (08:00–19:00)"]
    if not _civilian_eligible():
        description_label.text += "\nLicensed Seeker training and civilian work are separate. Register Live a Trade to use this introductory employment board."
        return
    if current_station == "board":
        if active.is_empty():
            for job in Rules.JOBS:
                _button("ACCEPT: " + Rules.job_label(job), "accept:" + job,
                    _shift_open() and not record["days"].has("day:%d" % _day()))
        else:
            description_label.text += "\nFinish the existing order before accepting another."
    elif current_station == "depot":
        if str(active.get("stage", "")) == "accepted":
            _button("COLLECT THE ASSIGNED WORK MATERIALS", "collect")
        else:
            description_label.text += "\nMaterials are only issued against an accepted order."
    elif current_station.begins_with("worker_"):
        var worker_id: String = current_station.trim_prefix("worker_")
        description_label.text += "\n" + Rules.job_label(worker_id) + " crew: The shift foreman expects verified orders, materials and safe work."
    elif current_station.begins_with("finish_"):
        var job_id: String = current_station.trim_prefix("finish_")
        if str(active.get("job", "")) == job_id and str(active.get("stage", "")) == "carrying":
            _button("COMPLETE CAREFULLY / FAIR PAY / +2 WORKER TRUST", "finish:careful")
            _button("RUSH WORK / HIGHER PAY / -3 WORKER TRUST", "finish:rush")
            _button("REFUSE UNSAFE WORK / NO PAY / +1 TRUST", "finish:refuse")
        else:
            description_label.text += "\nThis bench requires the matching job order and collected materials."

func _choose(key: String) -> void:
    var state: Dictionary = _state()
    if not _civilian_eligible():
        feedback.text = "Only registered civilian workers can accept these provisional assignments."
        return
    if key.begins_with("accept:"):
        if not _shift_open():
            feedback.text = "The work board is closed. Return during civic office hours."
            return
        var job: String = key.trim_prefix("accept:")
        var next: Dictionary = Rules.accept(state, job, _day())
        if next.is_empty() or not _persist(next):
            feedback.text = "No new shift available; check your existing work record."
            return
        feedback.text = "Shift accepted: %s. Go to the freight depot to collect materials." % Rules.job_label(job)
    elif key == "collect":
        var carrying: Dictionary = Rules.collect(state)
        if carrying.is_empty() or not _persist(carrying):
            feedback.text = "The materials can't be issued without an open shift."
            return
        feedback.text = "Materials collected. Bring them to the matching workshop's workbench."
    elif key.begins_with("finish:"):
        var outcome: String = key.trim_prefix("finish:")
        var active: Dictionary = state.get("active", {})
        var required: String = current_station.trim_prefix("finish_")
        if str(active.get("job", "")) != required or not current_station.begins_with("finish_"):
            feedback.text = "This workbench is not your assigned workplace."
            return
        var done: Dictionary = Rules.complete(state, outcome, _day())
        if done.is_empty():
            feedback.text = "The job is already settled or needs collected materials."
            return
        var profile: Dictionary = codex.get("profile")
        var original_origin: Dictionary = Origins.sanitize(profile.get("origin_v058", {}))
        var community: int = Residential.total_community_trust(profile.get("residential_v060", {}))
        var gross: int = Rules.pays(outcome, community)
        var money: Dictionary = {"net": 0, "gross": 0, "withheld": 0, "origin": original_origin}
        if gross > 0:
            money = Origins.courier_payment(original_origin, gross)
        var origin_change: Dictionary = money["origin"]
        if not _persist(done, origin_change):
            feedback.text = "Cannot confirm your work record. No wages issued."
            return
        GameState.earn_tola(int(money["net"]))
        hub.call("_save_game")
        codex.call("record_event", "v061:work:%d" % _day(), "workshop_shift",
            "Worked in Magnara's public service quarter",
            "%s / %s | gross %d, debt withheld %d, wages %d Tola. Source: game-only." % [
                Rules.job_label(required), outcome, int(money["gross"]),
                int(money["withheld"]), int(money["net"])])
        feedback.text = "Work recorded. Wages +%d Tola (debt withheld %d). The crews will remember." % [
            int(money["net"]), int(money["withheld"])]
        _refresh_lantern()
    _refresh()

func _refresh_lantern() -> void:
    if not is_instance_valid(lantern):
        return
    var trust: int = int(_state()["worker_trust"])
    var color: Color = Color(0.24, 0.78, 0.49) if trust >= 4 else (
        Color(0.89, 0.39, 0.30) if trust <= -4 else Color(0.28, 0.65, 0.71))
    lantern.material_override = _mat(color)

func _update_workers() -> void:
    if not is_instance_valid(hub):
        return
    var minute: float = fposmod(float(hub.get("world_minutes")), 1440.0)
    for i in range(Rules.JOBS.size()):
        var id: String = Rules.JOBS[i]
        if not workers.has(id):
            continue
        var worker: Node3D = workers[id]
        if minute < 420.0 or minute >= 1170.0:
            worker.position = Vector3(-98.0, 0.0, Rules.ZONES[i] - 3.0)
        else:
            var shift: float = sin(minute * 0.025 + float(i)) * 2.3
            worker.position = Vector3(-79.0, 0.0, Rules.ZONES[i] + shift)

func _process(delta: float) -> void:
    tick += delta
    if tick > 0.25:
        tick = 0.0
        _update_workers()

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()
