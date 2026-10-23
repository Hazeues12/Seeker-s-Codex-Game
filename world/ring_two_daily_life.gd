extends Node3D

# V0.41 — Public/professional life, based on the published Chapter 90 geography.
# All employee identities, schedules and orientation tasks are GAME-ONLY prototypes.
# This is not a canonical examination or rank-promotion process.
const SAVE_FILE: String = "user://margerina_ringtwo_orientation_v041.json"
const ROLES = [
    {"id": "npc_ring2_noodles", "name": "NOODLE VENDOR", "at": Vector3(6.0, 0.55, 52.0), "coat": Color(0.63, 0.37, 0.25)},
    {"id": "npc_ring2_canal", "name": "CANAL RESIDENT", "at": Vector3(-6.5, 0.55, 43.0), "coat": Color(0.32, 0.48, 0.55)},
    {"id": "npc_ring2_register", "name": "REGISTRATION CLERK", "at": Vector3(6.4, 0.55, 77.0), "coat": Color(0.34, 0.49, 0.68)},
    {"id": "npc_ring2_medic", "name": "MEDICAL INSTRUCTOR", "at": Vector3(20.2, 0.55, 80.0), "coat": Color(0.69, 0.69, 0.62)},
    {"id": "npc_ring2_trainer", "name": "SILVER TEAM INSTRUCTOR", "at": Vector3(-10.5, 0.55, 87.0), "coat": Color(0.29, 0.43, 0.62)},
    {"id": "npc_ring2_soulwright", "name": "SOULWRIGHT OFFICER", "at": Vector3(6.5, 0.55, 98.0), "coat": Color(0.39, 0.52, 0.49)},
    {"id": "npc_ring2_sentry", "name": "CITADEL PATROL SENTRY", "at": Vector3(17.0, 0.55, 111.0), "coat": Color(0.26, 0.29, 0.40)}
]

var player: CharacterBody3D
var hub: Node
var people: Array[Node3D] = []
var locations: Array[Vector3] = []
var silver_team: Array[Node3D] = []
var silver_origins: Array[Vector3] = []
var stage: int = 0
var time_elapsed: float = 0.0
var refresh_clock: float = 0.0
var hud_layer: CanvasLayer
var panel: PanelContainer
var journal_text: Label
var journal_button: Button

func _ready() -> void:
    add_to_group("ring_two_life")
    call_deferred("_setup")

func _setup() -> void:
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    hub = get_tree().get_first_node_in_group("hub_manager")
    if not is_instance_valid(player) or not is_instance_valid(hub):
        push_warning("V0.41 Ring Two life requires the existing Seeker hub and player")
        return
    _load_progress()
    for item in ROLES:
        var resident := Node3D.new()
        resident.name = str(item["id"])
        resident.position = item["at"]
        add_child(resident)
        _build_person(resident, item["coat"])
        _tag(resident, str(item["name"]), Vector3(0.0, 2.45, 0.0), 30)
        people.append(resident)
        locations.append(resident.position)
        if hub.has_method("_add_location"):
            hub.call("_add_location", str(item["id"]), str(item["name"]), resident.global_position, resident)
    _make_workstations()
    _make_silver_team()
    _make_journal()
    _refresh_visibility()

func _process(delta: float) -> void:
    if not is_instance_valid(player):
        return
    time_elapsed += delta
    refresh_clock += delta
    if refresh_clock < 0.12:
        return
    refresh_clock = 0.0
    for i in range(people.size()):
        var npc := people[i]
        var home: Vector3 = locations[i]
        var distance: float = player.global_position.distance_to(home)
        npc.visible = distance < 56.0 and _on_shift(i)
        if not npc.visible:
            continue
        var phase: float = time_elapsed * (0.43 + float(i % 3) * 0.08) + float(i) * 1.6
        npc.position = home + Vector3(sin(phase) * 0.48, 0.0, cos(phase) * 0.32)
        npc.rotation.y = sin(phase) * 0.22
    for i in range(silver_team.size()):
        var teammate := silver_team[i]
        teammate.visible = player.global_position.distance_to(silver_origins[i]) < 50.0
        if teammate.visible:
            var phase: float = time_elapsed * 2.4 + float(i) * 2.1
            teammate.position = silver_origins[i] + Vector3(sin(phase) * 0.68, 0.0, cos(phase) * 0.46)
            teammate.rotation.y = phase * 0.40

func _on_shift(index: int) -> bool:
    if not is_instance_valid(hub):
        return true
    var minute: int = int(float(hub.get("world_minutes"))) % 1440
    # Only civic vendors run regular hours. Seeker night staffing is maintained.
    if index == 0:
        return minute >= 360 and minute < 1320
    if index == 1:
        return minute >= 420 and minute < 1260
    return true

func _refresh_visibility() -> void:
    for person in people:
        person.visible = false
    for member in silver_team:
        member.visible = false

func _mat(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.83
    return mat

func _box(parent: Node3D, title: String, at: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    mesh.name = title
    var geo := BoxMesh.new()
    geo.size = dimensions
    mesh.mesh = geo
    mesh.position = at
    mesh.material_override = _mat(color)
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(mesh)
    return mesh

func _tag(parent: Node3D, value: String, at: Vector3, point_size: int = 31) -> void:
    var tag := Label3D.new()
    tag.text = value
    tag.position = at
    tag.font_size = point_size
    tag.pixel_size = 0.0055
    tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    tag.no_depth_test = true
    parent.add_child(tag)

func _build_person(parent: Node3D, coat: Color) -> void:
    _box(parent, "SeekerTunic", Vector3(0.0, 1.28, 0.0), Vector3(0.73, 0.94, 0.44), coat)
    _box(parent, "Face", Vector3(0.0, 1.97, 0.0), Vector3(0.47, 0.49, 0.41), Color(0.65, 0.44, 0.33))
    _box(parent, "HairOrHeadgear", Vector3(0.0, 2.25, 0.0), Vector3(0.51, 0.16, 0.47), coat.darkened(0.58))
    for side in [-1.0, 1.0]:
        _box(parent, "Sleeve", Vector3(side * 0.50, 1.29, 0.0), Vector3(0.21, 0.69, 0.29), coat.darkened(0.14))
        _box(parent, "Boot", Vector3(side * 0.21, 0.46, 0.0), Vector3(0.30, 0.84, 0.37), Color(0.19, 0.22, 0.28))

func _make_workstations() -> void:
    # Open-air interactive props beside V0.40 SOLID building exteriors.
    # No undocumented official academy interiors or fixed city compass asserted.
    _box(self, "RegistrationCounter", Vector3(5.7, 1.19, 80.0), Vector3(2.0, 1.24, 1.4), Color(0.37, 0.29, 0.23))
    _box(self, "RegistrationLedger", Vector3(5.7, 1.86, 80.0), Vector3(0.73, 0.07, 0.59), Color(0.86, 0.79, 0.61))
    _box(self, "MedicalPracticeTable", Vector3(19.2, 1.13, 83.5), Vector3(2.5, 1.18, 1.3), Color(0.54, 0.56, 0.53))
    for j in range(3):
        _box(self, "MedicalPracticeVial", Vector3(18.5 + float(j) * 0.62, 1.83, 83.5), Vector3(0.20, 0.39, 0.20), Color(0.35, 0.77, 0.83))
    _box(self, "SoulwrightFieldDesk", Vector3(6.6, 1.15, 101.1), Vector3(2.3, 1.20, 1.25), Color(0.32, 0.48, 0.46))
    _box(self, "EssenceObservationMarker", Vector3(6.6, 1.98, 101.1), Vector3(0.38, 0.47, 0.38), Color(0.43, 0.84, 0.84))
    for k in range(3):
        _box(self, "AvenuePatrolPost", Vector3(18.2, 1.11, 71.0 + float(k) * 18.0), Vector3(0.27, 1.2, 0.27), Color(0.45, 0.36, 0.23))
    _tag(self, "PUBLIC LIFE / RESIDENCES & WATERWAYS", Vector3(11.0, 3.4, 51.0), 28)
    _tag(self, "SILVER SQUAD / COORDINATED TRAINING", Vector3(-19.0, 3.4, 88.0), 26)
    _tag(self, "MEDICAL & AURA EXHAUSTION INSTRUCTION", Vector3(19.5, 3.5, 85.0), 25)

func _make_silver_team() -> void:
    for i in range(3):
        var member := Node3D.new()
        member.name = "SilverTeam_%d" % (i + 1)
        add_child(member)
        _build_person(member, Color(0.29, 0.42, 0.64) if i < 2 else Color(0.47, 0.55, 0.62))
        var base := Vector3(-22.0 + float(i) * 2.8, 0.55, 84.0 + float(i % 2) * 4.5)
        member.position = base
        silver_team.append(member)
        silver_origins.append(base)
    # Target is a training construct, not a canonical enemy or named summon.
    var target := Node3D.new()
    target.name = "SilverTeamSpiritConstruct"
    target.position = Vector3(-19.2, 0.55, 88.0)
    add_child(target)
    _box(target, "PracticeSpiritCore", Vector3(0.0, 1.27, 0.0), Vector3(0.75, 1.55, 0.75), Color(0.41, 0.75, 0.80))
    _tag(target, "SPIRIT CONSTRUCT / TRAINING", Vector3(0, 2.50, 0), 25)

func _make_journal() -> void:
    hud_layer = CanvasLayer.new()
    hud_layer.name = "RingTwoLifeHud"
    hud_layer.layer = 11
    get_parent().add_child(hud_layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_layer.add_child(root)
    journal_button = Button.new()
    journal_button.text = "RING TWO"
    journal_button.add_theme_font_size_override("font_size", 18)
    journal_button.offset_left = 555.0
    journal_button.offset_top = 12.0
    journal_button.offset_right = 760.0
    journal_button.offset_bottom = 65.0
    journal_button.pressed.connect(_toggle_journal)
    root.add_child(journal_button)
    panel = PanelContainer.new()
    panel.anchor_left = 0.19
    panel.anchor_top = 0.14
    panel.anchor_right = 0.81
    panel.anchor_bottom = 0.86
    panel.visible = false
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.055, 0.09, 0.15, 0.96)
    panel_style.border_color = Color(0.30, 0.69, 0.80)
    panel_style.set_border_width_all(3)
    panel.add_theme_stylebox_override("panel", panel_style)
    root.add_child(panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_top", 17)
    margin.add_theme_constant_override("margin_bottom", 15)
    panel.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation", 10)
    margin.add_child(stack)
    var heading := Label.new()
    heading.text = "RING TWO — FIELD JOURNAL"
    heading.add_theme_font_size_override("font_size", 26)
    stack.add_child(heading)
    journal_text = Label.new()
    journal_text.add_theme_font_size_override("font_size", 20)
    journal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    journal_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_child(journal_text)
    var close := Button.new()
    close.text = "RETURN TO THE CITY"
    close.custom_minimum_size = Vector2(0.0, 50.0)
    close.pressed.connect(_close_journal)
    stack.add_child(close)
    _refresh_journal()

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _toggle_journal() -> void:
    if not is_instance_valid(panel):
        return
    panel.visible = not panel.visible
    if panel.visible:
        _refresh_journal()

func _close_journal() -> void:
    if is_instance_valid(panel):
        panel.hide()

func _refresh_journal() -> void:
    if not is_instance_valid(journal_text):
        return
    var chapters := [
        "1. Speak to the Registration Clerk (professional precinct, z~77)",
        "2. Visit the Medical Instructor (medical hall exterior, z~80)",
        "3. Observe the Silver Team Instructor (training court, z~87)",
        "4. Consult the Soulwright Officer (field desk, z~98)",
        "5. Report to the Citadel Patrol Sentry (outside secured approach, z~111)"
    ]
    var content: String = "Orientation visits recorded: %d / 5\n\n" % stage
    for i in range(chapters.size()):
        content += ("[DONE]  " if i < stage else "[NEXT]  " if i == stage else "[LATER]  ") + str(chapters[i]) + "\n"
    content += "\nThese are provisional game orientation visits, NOT canon Seeker examination requirements.\nRin's Chapter 90 box location stays undisclosed."
    journal_text.text = content

func _load_progress() -> void:
    if not FileAccess.file_exists(SAVE_FILE):
        return
    var f := FileAccess.open(SAVE_FILE, FileAccess.READ)
    if f == null:
        return
    var parsed: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    if typeof(parsed) == TYPE_DICTIONARY:
        stage = clampi(int(parsed.get("stage", 0)), 0, 5)

func _save_progress() -> void:
    var f := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    if f != null:
        f.store_string(JSON.stringify({"version": 1, "stage": stage}))
        f.close()

func interact(kind: String) -> void:
    if not is_instance_valid(hub):
        return
    var message: String = ""
    match kind:
        "npc_ring2_noodles":
            message = "Vendor: 'Even the Silver squads stop to eat. The public quarter never sleeps.'"
        "npc_ring2_canal":
            message = "Resident: 'These blue-resonance waterways belong to the Seeker Quarters, not the Citadel.'"
        "npc_ring2_register":
            if stage == 0:
                stage = 1
                message = "Registration Clerk: 'Your visitor orientation is recorded. Visit medical instruction next.'"
            else:
                message = "Registration Clerk: 'This desk records certifications. Seeker rank is earned through official channels.'"
        "npc_ring2_medic":
            if stage == 1:
                stage = 2
                message = "Medical Instructor: 'Aura exhaustion requires assessment and recovery. Next observe a coordinated Silver squad.'"
            else:
                message = "Medical Instructor: 'Training medics prioritize exhaustion, injuries, and safe recovery.'"
        "npc_ring2_trainer":
            if stage == 2:
                stage = 3
                message = "Silver Team Instructor: 'Study their spacing and synchronized strikes. Consult the Soulwright field desk next.'"
            else:
                message = "Silver Team Instructor: 'Watch the team work together against a practice Spirit construct.'"
        "npc_ring2_soulwright":
            if stage == 3:
                stage = 4
                message = "Soulwright Officer: 'Essence, Will and Flame demand careful study. Finish with the outer sentry.'"
            else:
                message = "Soulwright Officer: 'We study the Soul Law Codex. These field notes grant no rank or authority.'"
        "npc_ring2_sentry":
            if stage == 4:
                stage = 5
                message = "Patrol Sentry: 'Orientation complete. The Citadel remains restricted. Continue learning in Ring Two.'"
            else:
                message = "Patrol Sentry: 'These approaches are secured. No entry without authorization.'"
        _:
            message = "There is no dialogue available for this visitor."
    if stage > 0:
        _save_progress()
    _refresh_journal()
    if hub.has_method("_announce"):
        hub.call("_announce", message)
