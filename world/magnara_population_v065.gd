extends Node3D
# V0.65: 3D street population + author-referenced guildhouse. Game-only layout,
# schedules and civilian names. Do not invent canonical character actions.
const Rules = preload("res://systems/character_population_rules_v065.gd")
const PROFILE_PATH: String = "user://seeker_profile_v1.json"
const GUILD_X: float = -30.0
const GUILD_Z: float = 555.0
const CULL_METERS: float = 125.0

var initialized: bool = false
var registry: Dictionary = {}
var hub: Node
var codex: Node
var player: CharacterBody3D
var actors: Dictionary = {}
var spawned: Dictionary = {}
var skins: Dictionary = {}
var meshes: Dictionary = {}
var tick_clock: float = 0.0
var panel: PanelContainer
var title_label: Label
var details: Label
var feedback: Label
var options: VBoxContainer
var selected_id: String = ""

func _ready() -> void:
    add_to_group("magnara_population_v065")
    set_process(false)
    call_deferred("_setup")

func _setup() -> void:
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    registry = Rules.load_registry()
    if not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(player) or not Rules.valid_roster(registry):
        push_error("V0.65 population cannot initialize incomplete or invalid canon registry")
        return
    _make_roads()
    _make_talking_boar()
    _make_population()
    _make_panel()
    initialized = true
    _tick()
    set_process(true)

func get_manifest() -> Dictionary:
    return {
        "version": 65, "city": "Magnara", "source_status": "game_only_engine",
        "canon_registry": (registry.get("canon_cast", []) as Array).size(),
        "factions": (registry.get("factions", []) as Array).size(),
        "known_venues": (registry.get("known_venues", []) as Array).size(),
        "civilian_registry": (registry.get("civilian_roster", []) as Array).size(),
        "physical_npcs": actors.size(),
        "canonical_visible_only_when_legitimate": true,
        "story_phase": Rules.PHASE,
        "living_rules": true, "ring_two_guildhouse": "talking_boar",
        "exact_guildhouse_coordinates_are_canon": false,
        "private_story_spawns_blocked": true
    }

func _mat(color: Color) -> StandardMaterial3D:
    var id: String = str(color)
    if skins.has(id):
        return skins[id]
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.roughness = 0.82
    skins[id] = result
    return result

func _box(parent: Node3D, title: String, position: Vector3, size: Vector3,
        color: Color, solid: bool = false) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.name = title
    part.position = position
    var key: String = str(size)
    var mesh: BoxMesh
    if meshes.has(key):
        mesh = meshes[key]
    else:
        mesh = BoxMesh.new()
        mesh.size = size
        meshes[key] = mesh
    part.mesh = mesh
    part.material_override = _mat(color)
    part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(part)
    if solid:
        var body := StaticBody3D.new()
        body.name = title + "Body"
        part.add_child(body)
        var collider := CollisionShape3D.new()
        collider.name = "PopulationV065Collision"
        var block := BoxShape3D.new()
        block.size = size
        collider.shape = block
        body.add_child(collider)
    return part

func _caption(parent: Node3D, text: String, position: Vector3) -> void:
    var label := Label3D.new()
    label.name = "PopulationV065Caption"
    label.text = text
    label.position = position
    label.font_size = 26
    label.pixel_size = 0.005
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    parent.add_child(label)

func _make_roads() -> void:
    # V0.64 had 137m north streets at x=-62,0,62 ending z=508;
    # extend all to z=580 and build an actual transverse connection at 548.
    for x in [-62.0, 0.0, 62.0]:
        _box(self, "V065LinkedGuildStreet", Vector3(x, 0.60, 543.0),
            Vector3(10.5, 0.14, 74.0), Color(0.68, 0.65, 0.58), true)
        for side in [-1.0, 1.0]:
            _box(self, "V065PedestrianWalk", Vector3(x + side * 7.2, 0.63, 543.0),
                Vector3(2.7, 0.12, 74.0), Color(0.76, 0.72, 0.65), true)
    _box(self, "V065GuildCrossStreet", Vector3(0.0, 0.64, 548.0),
        Vector3(130.0, 0.12, 9.4), Color(0.68, 0.67, 0.63), true)
    _caption(self, "MAGNARA / RING TWO / RESIDENTS AND GUILD LIFE",
        Vector3(0.0, 5.7, 518.0))
    for x in [-62.0, 62.0]:
        for z in [527.0, 560.0]:
            _box(self, "V065StreetLamp", Vector3(x + 9.0, 2.0, z),
                Vector3(0.18, 3.0, 0.18), Color(0.37, 0.33, 0.26), true)
            _box(self, "V065ResonanceLantern", Vector3(x + 9.0, 3.65, z),
                Vector3(0.64, 0.66, 0.64), Color(0.29, 0.63, 0.76))

func _make_talking_boar() -> void:
    var house := Node3D.new()
    house.name = "TalkingBoarV065"
    house.position = Vector3(GUILD_X, 0, GUILD_Z)
    add_child(house)
    var wall := Color(0.53, 0.43, 0.35)
    var wood := Color(0.39, 0.29, 0.21)
    var bronze := Color(0.70, 0.53, 0.29)
    _box(house, "TalkingBoarActualFloor", Vector3(0, 0.56, 0),
        Vector3(23.0, 0.18, 23.0), Color(0.62, 0.52, 0.41), true)
    _box(house, "TalkingBoarRearWall", Vector3(-11.5, 3.0, 0),
        Vector3(0.42, 5.0, 23.3), wall, true)
    for side in [-1.0, 1.0]:
        _box(house, "TalkingBoarSideWall", Vector3(0, 3.0, side * 11.5),
            Vector3(23.3, 5.0, 0.42), wall, true)
        _box(house, "TalkingBoarDoorWing", Vector3(11.5, 3.0, side * 7.6),
            Vector3(0.42, 5.0, 7.8), wall, true)
    _box(house, "TalkingBoarOpenDoorLintel", Vector3(11.5, 4.8, 0),
        Vector3(0.44, 1.48, 7.7), wall, true)
    _box(house, "TalkingBoarSolidRoof", Vector3(0, 5.62, 0),
        Vector3(24.0, 0.32, 24.0), Color(0.29, 0.31, 0.32), true)
    _box(house, "TalkingBoarBarCounter", Vector3(-5.8, 1.17, 1.0),
        Vector3(2.0, 1.12, 9.8), wood, true)
    _box(house, "TalkingBoarDispatchDesk", Vector3(-3.0, 1.08, -7.5),
        Vector3(3.6, 0.89, 1.9), wood, true)
    for i in range(3):
        var z: float = -4.5 + float(i) * 5.5
        _box(house, "TalkingBoarGuestTable", Vector3(4.3, 1.09, z),
            Vector3(2.3, 0.85, 1.6), wood, true)
    _box(house, "TalkingBoarBoarSign", Vector3(11.88, 3.7, 0),
        Vector3(0.30, 2.10, 2.4), bronze)
    _box(house, "TalkingBoarKitchenPartition", Vector3(-8.0, 2.35, 7.8),
        Vector3(5.0, 2.6, 0.24), Color(0.46, 0.40, 0.35), true)
    _caption(house, "THE TALKING BOAR / ORDER OF THE CRESCENT HALO",
        Vector3(0, 6.53, 0))
    _box(self, "TalkingBoarPublicEntryWalk", Vector3(-9.2, 0.65, GUILD_Z),
        Vector3(22.0, 0.12, 4.0), Color(0.78, 0.73, 0.66), true)
    _caption(house, "PUBLIC GUILD HALL / GAME-ONLY 3D ADDRESS",
        Vector3(0, 4.95, -10.2))

func _actor_palette(record: Dictionary) -> Dictionary:
    var id: String = str(record.get("id", ""))
    match id:
        "william_lockhart":
            return {"body": Color(0.89, 0.90, 0.88), "accent": Color(0.86, 0.72, 0.32),
                "head": Color(0.64, 0.48, 0.38), "hair": Color(0.77, 0.69, 0.54)}
        "hanami":
            return {"body": Color(0.57, 0.44, 0.33), "accent": Color(0.72, 0.35, 0.25),
                "head": Color(0.70, 0.53, 0.38), "hair": Color(0.26, 0.22, 0.21)}
        "ven":
            return {"body": Color(0.22, 0.26, 0.29), "accent": Color(0.43, 0.55, 0.56),
                "head": Color(0.22, 0.23, 0.27), "hair": Color(0.12, 0.13, 0.17)}
        "kai_xander":
            return {"body": Color(0.63, 0.46, 0.28), "accent": Color(0.77, 0.64, 0.32),
                "head": Color(0.62, 0.48, 0.36), "hair": Color(0.22, 0.18, 0.16)}
        "aria_flamehart":
            return {"body": Color(0.28, 0.38, 0.49), "accent": Color(0.76, 0.70, 0.32),
                "head": Color(0.72, 0.55, 0.44), "hair": Color(0.93, 0.85, 0.60)}
        "lila_butters":
            return {"body": Color(0.32, 0.63, 0.74), "accent": Color(0.65, 0.85, 0.90),
                "head": Color(0.61, 0.44, 0.34), "hair": Color(0.26, 0.21, 0.21)}
    var variant: int = int(record.get("appearance_variant", 0))
    var shades: Array[Color] = [
        Color(0.45, 0.56, 0.61), Color(0.63, 0.48, 0.38),
        Color(0.49, 0.59, 0.46), Color(0.59, 0.50, 0.67),
        Color(0.72, 0.64, 0.46), Color(0.43, 0.56, 0.58),
        Color(0.63, 0.51, 0.55), Color(0.47, 0.50, 0.41)
    ]
    return {"body": shades[posmod(variant, shades.size())],
        "accent": Color(0.75, 0.67, 0.49),
        "head": Color(0.58 + float(variant % 3) * 0.07, 0.46, 0.36),
        "hair": Color(0.23 + float(variant % 4) * 0.10, 0.22, 0.20)}

func _make_actor(record: Dictionary) -> void:
    var id: String = str(record.get("id", ""))
    var actor := Node3D.new()
    actor.name = "NPCV065_" + id
    actor.position = Vector3(0, 0, 0)
    add_child(actor)
    var colors: Dictionary = _actor_palette(record)
    _box(actor, "NPCV065Torso", Vector3(0, 1.16, 0),
        Vector3(0.63, 0.92, 0.36), colors["body"])
    _box(actor, "NPCV065Accent", Vector3(0, 1.49, 0.22),
        Vector3(0.69, 0.17, 0.08), colors["accent"])
    _box(actor, "NPCV065Head", Vector3(0, 1.89, 0),
        Vector3(0.40, 0.43, 0.37), colors["head"])
    _box(actor, "NPCV065Hair", Vector3(0, 2.17, -0.02),
        Vector3(0.45, 0.17, 0.42), colors["hair"])
    for side in [-1.0, 1.0]:
        _box(actor, "NPCV065Arm", Vector3(side * 0.41, 1.15, 0),
            Vector3(0.20, 0.74, 0.28), colors["body"])
        _box(actor, "NPCV065Leg", Vector3(side * 0.18, 0.40, 0),
            Vector3(0.20, 0.74, 0.27), Color(0.33, 0.34, 0.36))
    if id == "ven":
        for side in [-1.0, 1.0]:
            _box(actor, "NPCV065TherianEar", Vector3(side * 0.16, 2.30, -0.04),
                Vector3(0.17, 0.30, 0.17), colors["hair"])
    if id == "kai_xander":
        _box(actor, "NPCV065StaffSunProxy", Vector3(0.55, 1.05, -0.22),
            Vector3(0.10, 2.0, 0.10), Color(0.47, 0.32, 0.18))
    if id == "william_lockhart":
        _box(actor, "NPCV065LightCoatHem", Vector3(0, 0.66, -0.08),
            Vector3(0.79, 0.71, 0.45), colors["body"])
        _box(actor, "NPCV065WeaponScabbard", Vector3(-0.45, 0.78, -0.20),
            Vector3(0.12, 1.25, 0.17), Color(0.38, 0.37, 0.37))
    _caption(actor, str(record.get("name", id)), Vector3(0, 2.68, 0))
    actor.visible = false
    actors[id] = actor
    spawned[id] = record
    hub.call("_add_location", "npc_v065_" + id, str(record.get("name", id)),
        actor.global_position, actor)

func _make_population() -> void:
    for npc in registry.get("civilian_roster", []):
        _make_actor(npc)
    for actor in registry.get("canon_cast", []):
        if Rules.can_ambient_spawn(actor):
            _make_actor(actor)

func _tick() -> void:
    if not initialized:
        return
    var minutes: float = float(hub.get("world_minutes"))
    for id in actors.keys():
        var actor: Node3D = actors[id]
        var record: Dictionary = spawned[id]
        var status: Dictionary = Rules.state_for(record, minutes)
        var point: Vector3 = Rules.at_anchor(str(status.get("anchor", "")))
        if bool(status.get("moving", false)):
            point = status.get("position", point)
        # A few canonical guests can share a symbolic hall but get different
        # standing positions for individual conversations; no crowd overlap.
        if str(record.get("kind", "")) == "canon" and str(status.get("anchor", "")) == "guild_hall":
            var index: int = ["william_lockhart","hanami","ven","kai_xander","aria_flamehart","lila_butters"].find(str(id))
            point += Vector3(float(index % 3) * 2.9 - 2.7, 0, float(index / 3) * 3.2 - 1.6)
        var onstage: bool = bool(status.get("visible", false))
        actor.position = point
        actor.visible = onstage and player.global_position.distance_to(point) <= CULL_METERS
        actor.set_meta("activity", str(status.get("activity", "unknown")))

func _process(delta: float) -> void:
    tick_clock += delta
    if tick_clock > 0.48:
        tick_clock = 0.0
        _tick()

func current_actor_state(id: String) -> Dictionary:
    if not spawned.has(id):
        return {}
    return Rules.state_for(spawned[id], float(hub.get("world_minutes")))

func _profile_memory() -> Dictionary:
    var profile: Dictionary = codex.get("profile")
    return Rules.sanitize_relationships(profile.get("population_v065", {}))

func _make_panel() -> void:
    var canvas := CanvasLayer.new()
    canvas.layer = 23
    canvas.name = "PopulationConversationCanvasV065"
    get_parent().add_child(canvas)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(root)
    panel = PanelContainer.new()
    panel.anchor_left = 0.10
    panel.anchor_right = 0.90
    panel.anchor_top = 0.07
    panel.anchor_bottom = 0.93
    panel.visible = false
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(0.055, 0.075, 0.115, 0.98)
    skin.border_color = Color(0.54, 0.62, 0.68)
    skin.set_border_width_all(2)
    skin.set_corner_radius_all(10)
    panel.add_theme_stylebox_override("panel", skin)
    root.add_child(panel)
    var border := MarginContainer.new()
    border.add_theme_constant_override("margin_left", 16)
    border.add_theme_constant_override("margin_right", 16)
    border.add_theme_constant_override("margin_top", 16)
    border.add_theme_constant_override("margin_bottom", 16)
    panel.add_child(border)
    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 9)
    border.add_child(layout)
    title_label = Label.new()
    title_label.add_theme_font_size_override("font_size", 23)
    layout.add_child(title_label)
    details = Label.new()
    details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    layout.add_child(details)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_child(scroll)
    options = VBoxContainer.new()
    options.add_theme_constant_override("separation", 10)
    scroll.add_child(options)
    feedback = Label.new()
    feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    layout.add_child(feedback)
    var close := Button.new()
    close.text = "RETURN TO THE STREET"
    close.custom_minimum_size.y = 50
    close.pressed.connect(_close)
    layout.add_child(close)

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()

func _button(text: String, key: String, enabled: bool) -> void:
    var option := Button.new()
    option.text = text
    option.custom_minimum_size.y = 52
    option.disabled = not enabled
    option.pressed.connect(_choose.bind(key))
    options.add_child(option)

func interact(key: String) -> void:
    if not initialized or not key.begins_with("npc_v065_"):
        return
    var id: String = key.trim_prefix("npc_v065_")
    if not actors.has(id):
        return
    var actor: Node3D = actors[id]
    if not actor.visible or player.global_position.distance_to(actor.global_position) > float(hub.get("interact_range")):
        return
    if str(spawned[id].get("public_visibility", "public")) != "public":
        return
    selected_id = id
    feedback.text = ""
    _refresh()
    panel.show()

func _refresh() -> void:
    for option in options.get_children():
        options.remove_child(option)
        option.queue_free()
    if selected_id.is_empty() or not spawned.has(selected_id):
        return
    var record: Dictionary = spawned[selected_id]
    var today: int = Rules.day(float(hub.get("world_minutes")))
    var relation: Dictionary = _profile_memory()
    var relations: Dictionary = relation["actors"]
    var saved: Dictionary = relations.get(selected_id, {})
    var day_map: Dictionary = saved.get("days", {})
    var already: bool = day_map.has("day:%d" % today)
    var activity: String = str(current_actor_state(selected_id).get("activity", "offstage"))
    var affinity: int = Rules.rapport(relation, selected_id)
    title_label.text = str(record.get("name", selected_id)).to_upper()
    var role: String = str(record.get("role", record.get("lifestyle", "resident"))).replace("_", " ")
    details.text = "Role: %s\n%s\nRelationship: %d / Date: Day %d" % [
        role, Rules.dialogue(record, activity, affinity), affinity, today]
    if str(record.get("kind", "")) == "canon":
        details.text += "\nCanon record: %s / %s" % [
            str(record.get("squad_id", "not assigned")), str(record.get("guild_id", "not assigned"))]
        # Only ordinary public gear here: no sealed Bloodmark/rare Eye reveals.
        var carried: Array = record.get("equipment", [])
        if carried.size() > 0:
            details.text += "\nKnown gear: " + ", ".join(PackedStringArray(carried))
    if bool(codex.get("save_blocked")):
        details.text += "\nPersonal Codex storage is currently protected; no new decisions can be saved."
    _button("LISTEN AND LEARN ABOUT THEIR DAY", "listen", not already and not bool(codex.get("save_blocked")))
    _button("OFFER PRACTICAL HELP", "help", not already and not bool(codex.get("save_blocked")))
    _button("DISMISS THEIR CONCERNS", "dismiss", not already and not bool(codex.get("save_blocked")))

func _save_memory(next: Dictionary) -> bool:
    if bool(codex.get("save_blocked")):
        return false
    var old_profile: Dictionary = codex.get("profile")
    var updated: Dictionary = old_profile.duplicate(true)
    updated["population_v065"] = next
    codex.set("profile", updated)
    codex.call("_save_profile")
    var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
    if file == null:
        codex.set("profile", old_profile)
        return false
    var decoder := JSON.new()
    var status: int = decoder.parse(file.get_as_text())
    file.close()
    var good: bool = status == OK and typeof(decoder.data) == TYPE_DICTIONARY
    if good:
        var disk: Dictionary = decoder.data
        good = Rules.sanitize_relationships(disk.get("population_v065", {})) == Rules.sanitize_relationships(next)
    if not good:
        codex.set("profile", old_profile)
    return good

func _choose(choice: String) -> void:
    if not initialized or selected_id.is_empty() or not Rules.DAILY_CHOICES.has(choice):
        return
    var record: Dictionary = spawned.get(selected_id, {})
    if record.is_empty():
        return
    var today: int = Rules.day(float(hub.get("world_minutes")))
    var previous: Dictionary = _profile_memory()
    var next: Dictionary = Rules.apply_choice(previous, selected_id, choice, today)
    if next.is_empty() or not _save_memory(next):
        feedback.text = "This day's choice is already made, or storage verification failed."
        _refresh()
        return
    if codex.has_method("record_event"):
        codex.call("record_event", "v065:%s:day:%d" % [selected_id, today],
            "public_encounter", "Met " + str(record.get("name", "a resident")),
            "Game-only encounter and daily %s choice; canonical plot remains unchanged." % choice)
    feedback.text = "%s remembers your %s. Their recorded attitude is now %d." % [
        str(record.get("name", "")), choice, Rules.rapport(next, selected_id)]
    _refresh()
