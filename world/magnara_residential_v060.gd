extends Node3D
# V0.60 WORLD FIRST / provisional 3D household district linked by a
# walkable pedestrian spine to the existing east professional Ring Two ward.
# Three residents use deterministic schedules and saved day-specific choices.
const Rules = preload("res://systems/residential_life_v060.gd")
const DISTRICT_NAME: String = "Magnara Public Residential Lane / GAME ONLY"
const HOME_X: float = 87.0

var player: CharacterBody3D
var hub: Node
var codex: Node
var initialized: bool = false
var residents: Dictionary = {}
var lamp: MeshInstance3D
var panel: PanelContainer
var title_label: Label
var description_label: Label
var reply_label: Label
var options: VBoxContainer
var current_id: String = ""
var update_clock: float = 0.0
var material_cache: Dictionary = {}
var mesh_cache: Dictionary = {}

func _ready() -> void:
    add_to_group("residential_life_v060")
    set_process(false)
    call_deferred("_setup")

func _setup() -> void:
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    if not is_instance_valid(player) or not is_instance_valid(hub) or not is_instance_valid(codex):
        push_warning("V0.60 needs the established Seeker player, city hub and Codex")
        return
    _make_neighborhood()
    _make_dialogue()
    initialized = true
    _refresh_positions()
    _refresh_lantern()
    set_process(true)

func get_manifest() -> Dictionary:
    return {
        "world": "Margerina",
        "district": DISTRICT_NAME,
        "era": "1500 A.S.",
        "household_count": Rules.IDS.size(),
        "physical_open_houses": 3,
        "road_link": "East Ring Two professional street / x=62,z=110",
        "local_street_end_m": Vector3(62.0, 0.55, 190.0),
        "daily_schedule": true,
        "distinct_noncanonical_residents": true,
        "save_key": "residential_v060",
        "source_status": "game_only",
        "unknown_national_borders_unchanged": true
    }

func _mat(tint: Color) -> StandardMaterial3D:
    var key: String = str(tint)
    if material_cache.has(key):
        return material_cache[key]
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = 0.83
    material_cache[key] = material
    return material

func _box(parent: Node3D, label: String, at: Vector3, size: Vector3,
        color: Color, solid: bool = false) -> MeshInstance3D:
    var obj := MeshInstance3D.new()
    obj.name = label
    var key: String = str(size)
    var shape: BoxMesh
    if mesh_cache.has(key):
        shape = mesh_cache[key]
    else:
        shape = BoxMesh.new()
        shape.size = size
        mesh_cache[key] = shape
    obj.mesh = shape
    obj.position = at
    obj.material_override = _mat(color)
    obj.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(obj)
    if solid:
        var collider_body := StaticBody3D.new()
        collider_body.name = label + "Solid"
        obj.add_child(collider_body)
        var collider := CollisionShape3D.new()
        collider.name = "ResidentialCollision"
        var volume := BoxShape3D.new()
        volume.size = size
        collider.shape = volume
        collider_body.add_child(collider)
    return obj

func _tag(parent: Node3D, label: String, at: Vector3) -> void:
    var billboard := Label3D.new()
    billboard.name = "NeighborhoodSign"
    billboard.text = label
    billboard.font_size = 31
    billboard.pixel_size = 0.006
    billboard.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    billboard.no_depth_test = true
    billboard.position = at
    parent.add_child(billboard)

func _house(id: String, index: int) -> void:
    var z: float = Rules.HOME_Z[index]
    var building := Node3D.new()
    building.name = "OpenHouse_" + id
    building.position = Vector3(HOME_X, 0.0, z)
    add_child(building)
    var outer: Color = Color(0.67, 0.59, 0.52) if index == 0 else (
        Color(0.54, 0.59, 0.64) if index == 1 else Color(0.64, 0.64, 0.57))
    _box(building, "RealInteriorFloor", Vector3(0, 0.54, 0),
        Vector3(12.4, 0.12, 12.0), Color(0.67, 0.62, 0.53), true)
    _box(building, "RearStoneWall", Vector3(6.25, 2.75, 0),
        Vector3(0.42, 4.40, 12.4), outer, true)
    for side in [-1.0, 1.0]:
        _box(building, "SideStoneWall", Vector3(0, 2.75, side * 6.05),
            Vector3(12.65, 4.40, 0.42), outer, true)
        _box(building, "FrontDoorWing", Vector3(-6.25, 2.75, side * 4.0),
            Vector3(0.42, 4.40, 4.1), outer, true)
        _box(building, "InteriorWindow", Vector3(2.2, 2.9, side * 6.28),
            Vector3(1.65, 1.10, 0.09), Color(0.35, 0.68, 0.77))
    _box(building, "DoorLintel", Vector3(-6.25, 4.24, 0),
        Vector3(0.45, 1.45, 3.72), outer, true)
    _box(building, "CollidableSlateRoof", Vector3(0, 5.1, 0),
        Vector3(13.0, 0.26, 12.9), Color(0.25, 0.31, 0.34), true)
    _box(building, "HouseholdBench", Vector3(2.55, 0.95, 4.1),
        Vector3(3.1, 0.62, 0.84), Color(0.40, 0.31, 0.24), true)
    _box(building, "WorkTable", Vector3(3.15, 1.16, -3.25),
        Vector3(2.25, 0.85, 1.4), Color(0.43, 0.35, 0.27), true)
    _box(building, "RoofLantern", Vector3(-5.9, 4.35, 2.7),
        Vector3(0.49, 0.66, 0.49), Color(0.77, 0.71, 0.38))
    _box(building, "ThresholdStone", Vector3(-6.8, 0.55, 0),
        Vector3(2.0, 0.10, 3.0), Color(0.78, 0.69, 0.59), true)
    _tag(building, Rules.name_for(id).to_upper() + " / HOUSEHOLD",
        Vector3(-6.7, 5.65, 0))
    # Solid sidewalk has a real door path; buildings are enterable, not facades.
    _box(self, "HomeSpur_" + id,
        Vector3(71.1, 0.55, z), Vector3(19.5, 0.10, 3.2),
        Color(0.72, 0.68, 0.60), true)

func _make_resident(id: String, index: int) -> void:
    var actor := Node3D.new()
    actor.name = "ScheduledResident_" + id
    actor.position = Rules.position_at(id, float(hub.get("world_minutes")))
    add_child(actor)
    var coat: Color = Color(0.52, 0.43, 0.34) if index == 0 else (
        Color(0.35, 0.49, 0.59) if index == 1 else Color(0.51, 0.58, 0.39))
    TownspersonVisual.add_to(actor, id, index % 2, coat)
    _tag(actor, Rules.name_for(id).to_upper() + " / TALK", Vector3(0, 2.9, 0))
    hub.call("_add_location", "npc_v060_" + id, Rules.name_for(id), actor.global_position, actor)
    residents[id] = actor

func _make_neighborhood() -> void:
    _box(self, "ResidentialStreetWalkable", Vector3(62.0, 0.55, 150.0),
        Vector3(8.7, 0.13, 82.0), Color(0.73, 0.68, 0.59), true)
    _box(self, "ResidentialSidewalkLeft", Vector3(54.5, 0.55, 150.0),
        Vector3(2.9, 0.13, 82.0), Color(0.70, 0.68, 0.63), true)
    _box(self, "ResidentialSidewalkRight", Vector3(68.1, 0.55, 150.0),
        Vector3(2.8, 0.13, 82.0), Color(0.70, 0.68, 0.63), true)
    _box(self, "ResidentialPublicCourt", Vector3(58.0, 0.57, 151.0),
        Vector3(13.0, 0.14, 14.0), Color(0.76, 0.71, 0.62), true)
    _box(self, "CourtyardCommunityBench", Vector3(52.5, 0.96, 150.0),
        Vector3(3.8, 0.64, 0.95), Color(0.44, 0.34, 0.25), true)
    _box(self, "CivicWellBase", Vector3(53.0, 0.93, 158.0),
        Vector3(2.7, 0.76, 2.7), Color(0.51, 0.57, 0.59), true)
    _box(self, "CivicWellRoof", Vector3(53.0, 3.08, 158.0),
        Vector3(3.2, 0.17, 2.6), Color(0.28, 0.34, 0.37))
    for side in [-1.0, 1.0]:
        _box(self, "CivicWellPost", Vector3(53.0 + side * 1.22, 2.0, 158.0),
            Vector3(0.21, 2.3, 0.21), Color(0.53, 0.43, 0.32))
    _box(self, "SharedMarketAwning", Vector3(53.7, 3.30, 140.0),
        Vector3(6.2, 0.16, 3.7), Color(0.40, 0.58, 0.64))
    _box(self, "NeighborhoodNoticeBoard", Vector3(52.0, 1.70, 140.0),
        Vector3(3.9, 2.0, 0.23), Color(0.42, 0.33, 0.26))
    lamp = _box(self, "HouseholdTrustLantern", Vector3(55.5, 3.03, 151.0),
        Vector3(0.54, 0.66, 0.54), Color(0.30, 0.65, 0.72))
    _tag(self, "MAGNARA / LIVING HOUSEHOLDS / GAME ONLY",
        Vector3(62.0, 5.70, 116.0))
    for i in range(Rules.IDS.size()):
        _house(Rules.IDS[i], i)
        _make_resident(Rules.IDS[i], i)

func _make_dialogue() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "ResidentialDialogueCanvas"
    canvas.layer = 18
    get_parent().add_child(canvas)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(root)
    panel = PanelContainer.new()
    panel.anchor_left = 0.12
    panel.anchor_right = 0.88
    panel.anchor_top = 0.09
    panel.anchor_bottom = 0.90
    panel.visible = false
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(0.065, 0.080, 0.117, 0.97)
    skin.border_color = Color(0.48, 0.66, 0.70)
    skin.set_border_width_all(2)
    skin.set_corner_radius_all(10)
    panel.add_theme_stylebox_override("panel", skin)
    root.add_child(panel)
    var margins := MarginContainer.new()
    margins.add_theme_constant_override("margin_left", 14)
    margins.add_theme_constant_override("margin_right", 14)
    margins.add_theme_constant_override("margin_top", 13)
    margins.add_theme_constant_override("margin_bottom", 13)
    panel.add_child(margins)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 10)
    margins.add_child(stack)
    title_label = Label.new()
    title_label.add_theme_font_size_override("font_size", 24)
    stack.add_child(title_label)
    description_label = Label.new()
    description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description_label.add_theme_font_size_override("font_size", 17)
    stack.add_child(description_label)
    options = VBoxContainer.new()
    options.add_theme_constant_override("separation", 8)
    stack.add_child(options)
    reply_label = Label.new()
    reply_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    reply_label.add_theme_font_size_override("font_size", 17)
    stack.add_child(reply_label)
    var close := Button.new()
    close.text = "RETURN TO THE NEIGHBORHOOD"
    close.custom_minimum_size.y = 52
    close.pressed.connect(_close)
    stack.add_child(close)

func _state() -> Dictionary:
    if not is_instance_valid(codex):
        return Rules.empty_state()
    var profile: Dictionary = codex.get("profile")
    return Rules.sanitize(profile.get("residential_v060", {}))

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _day() -> int:
    return maxi(1, int(floor(float(hub.get("world_minutes")) / 1440.0)) + 1)

func get_resident_position(id: String) -> Vector3:
    if residents.has(id):
        return (residents[id] as Node3D).global_position
    return Vector3.ZERO

func _process(delta: float) -> void:
    update_clock += delta
    if update_clock >= 0.12:
        update_clock = 0.0
        _refresh_positions()

func _refresh_positions() -> void:
    if not is_instance_valid(hub):
        return
    var minute: float = float(hub.get("world_minutes"))
    for id in Rules.IDS:
        if residents.has(id):
            var npc: Node3D = residents[id]
            if is_instance_valid(npc):
                npc.position = Rules.position_at(id, minute)

func _refresh_lantern() -> void:
    if not is_instance_valid(lamp):
        return
    var trust: int = Rules.total_community_trust(_state())
    if trust >= 3:
        lamp.material_override = _mat(Color(0.29, 0.83, 0.52))
    elif trust <= -3:
        lamp.material_override = _mat(Color(0.92, 0.39, 0.30))
    else:
        lamp.material_override = _mat(Color(0.30, 0.65, 0.72))

func interact(kind: String) -> void:
    if not initialized or not kind.begins_with("npc_v060_"):
        return
    if bool(codex.get("save_blocked")):
        hub.call("_announce", "Neighborhood memory is unavailable. Existing save protected.")
        return
    var id: String = kind.trim_prefix("npc_v060_")
    if not Rules.IDS.has(id):
        return
    current_id = id
    reply_label.text = ""
    _refresh_dialogue()
    panel.show()

func _refresh_dialogue() -> void:
    for child in options.get_children():
        options.remove_child(child)
        child.queue_free()
    var profile: Dictionary = codex.get("profile")
    var record: Dictionary = _state()
    var family: Variant = profile.get("family_v059", {})
    title_label.text = Rules.name_for(current_id).to_upper() + " / MAGNARA HOUSEHOLDS"
    description_label.text = "%s\nShift: %s | Rapport: %d\n%s" % [
        Rules.social_facts(current_id), Rules.phase_at(current_id, float(hub.get("world_minutes"))),
        Rules.rapport(record, current_id),
        Rules.neighborhood_reaction(record, current_id, family)]
    var available: bool = Rules.can_choose(record, current_id, _day())
    for choice in Rules.DECISIONS:
        var button := Button.new()
        button.custom_minimum_size.y = 50
        match choice:
            "help": button.text = "HELP WITH HOUSEHOLD WORK (+ trust)"
            "listen": button.text = "LISTEN TO THEIR FAMILY CONCERNS (+ respect)"
            "pressure": button.text = "PRESSURE FOR A SPECIAL FAVOR (- trust)"
        if not available:
            button.text += " / Already decided today"
        button.disabled = not available
        button.pressed.connect(_decide.bind(choice))
        options.add_child(button)

func _save_decision(new_state: Dictionary) -> bool:
    if not is_instance_valid(codex) or bool(codex.get("save_blocked")):
        return false
    var original: Dictionary = codex.get("profile")
    var updated: Dictionary = original.duplicate(true)
    updated["residential_v060"] = Rules.sanitize(new_state)
    codex.set("profile", updated)
    codex.call("_save_profile")
    var file := FileAccess.open("user://seeker_profile_v1.json", FileAccess.READ)
    if file == null:
        codex.set("profile", original)
        return false
    var read: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(read) != TYPE_DICTIONARY:
        codex.set("profile", original)
        return false
    var valid: bool = Rules.sanitize(read.get("residential_v060", {})) == Rules.sanitize(new_state)
    if not valid:
        codex.set("profile", original)
    return valid

func _decide(choice: String) -> void:
    var id: String = current_id
    var day: int = _day()
    var saved: Dictionary = Rules.decide(_state(), id, choice, day)
    if saved.is_empty():
        reply_label.text = "You've already made today's decision for this household."
        _refresh_dialogue()
        return
    if not _save_decision(saved):
        reply_label.text = "Unable to verify the household record. No change applied."
        return
    codex.call("record_event", "v060:household:%s:day:%d" % [id, day],
        "household_choice", "Your conduct with " + Rules.name_for(id),
        "Decision: " + choice + ". Neighborhood rapport: %d. Game-only local resident." % Rules.rapport(saved, id))
    _refresh_lantern()
    match choice:
        "help": reply_label.text = "They thank you for helping with the neighborhood's shared work."
        "listen": reply_label.text = "They appreciate that you listened without demanding anything."
        "pressure": reply_label.text = "The resident steps back. They'll remember the pressure."
    _refresh_dialogue()

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()
