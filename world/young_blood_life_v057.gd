extends Node3D
# V0.57 - Young Blood's life roads in actual Magnara Ring Two.
# Game-only starting history and paid courier trial. The longer 36-step exam,
# nine trades, nation origin scenes, traits, and family lineages follow later.
const Rules = preload("res://systems/young_blood_life_rules_v057.gd")
const Origins = preload("res://systems/young_blood_origins_v058.gd")
const REGISTRAR: Vector3 = Vector3(-8.5, 0.56, 69.0)
const PICKUP: Vector3 = Vector3(11.5, 0.56, 60.0)
const DELIVERY: Vector3 = Vector3(-18.0, 0.56, 90.0)

var player: CharacterBody3D
var hub: Node
var codex: Node
var panel: PanelContainer
var notice: Label
var current_road: Label
var nation_option: OptionButton
var road_buttons: Array[Button] = []
var shift_button: Button
var background_option: OptionButton
var temperament_option: OptionButton
var trait_option: OptionButton
var origin_checks: Array[CheckBox] = []
var perk_checks: Array[CheckBox] = []
var origins_feedback: Label
var origins_confirm: Button
var initialized: bool = false

func _ready() -> void:
    add_to_group("young_blood_life_v057")
    call_deferred("_setup")

func _setup() -> void:
    if not is_inside_tree():
        return
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    if not is_instance_valid(player) or not is_instance_valid(hub) or not is_instance_valid(codex):
        push_warning("Young Blood life roads require an initialized player, hub and Personal Codex")
        return
    _make_world()
    _make_ui()
    initialized = true
    _apply_home_clothing()

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func may_accept_seeker_contracts() -> bool:
    return Rules.can_take_seeker_contract(_current_life())

func _material(color: Color) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.roughness = 0.76
    return result

func _box(parent: Node3D, name: String, at: Vector3, size: Vector3, color: Color, collide: bool = false) -> void:
    var shape := MeshInstance3D.new()
    shape.name = name
    var mesh := BoxMesh.new()
    mesh.size = size
    shape.mesh = mesh
    shape.material_override = _material(color)
    shape.position = at
    parent.add_child(shape)
    if collide:
        var body := StaticBody3D.new()
        body.name = name + "_Solid"
        shape.add_child(body)
        var collision := CollisionShape3D.new()
        collision.name = "LifeRoadStaticCollider"
        var volume := BoxShape3D.new()
        volume.size = size
        collision.shape = volume
        body.add_child(collision)

func _sign(parent: Node3D, title: String, at: Vector3) -> void:
    var marker := Label3D.new()
    marker.name = "LifeRoadWayfinding"
    marker.text = title
    marker.position = at
    marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    marker.no_depth_test = true
    marker.font_size = 28
    marker.pixel_size = 0.007
    parent.add_child(marker)

func _make_marker(name: String, position: Vector3, sign: String, accent: Color) -> Node3D:
    var marker := Node3D.new()
    marker.name = name
    marker.position = position
    add_child(marker)
    _box(marker, "StoneBase", Vector3(0, 0.12, 0), Vector3(2.1, 0.24, 1.5), Color(0.58, 0.57, 0.54), true)
    _box(marker, "BronzePost", Vector3(0, 1.36, 0), Vector3(0.17, 2.1, 0.17), Color(0.48, 0.35, 0.23))
    _box(marker, "StoneHeading", Vector3(0, 2.38, 0), Vector3(1.85, 0.58, 0.35), accent)
    _sign(marker, sign, Vector3(0, 3.15, 0))
    return marker

func _make_world() -> void:
    var registrar: Node3D = _make_marker("PublicLifeRegistrarV057", REGISTRAR,
        "LIFE REGISTRY / 1500 A.S.", Color(0.36, 0.58, 0.66))
    var parcel: Node3D = _make_marker("CivicCourierPickupV057", PICKUP,
        "COURIER PICKUP / GAME ONLY", Color(0.61, 0.45, 0.28))
    var dropoff: Node3D = _make_marker("ProfessionalServiceReceiptV057", DELIVERY,
        "COURIER DELIVERY / GAME ONLY", Color(0.39, 0.54, 0.43))
    _box(registrar, "LifeRegistrationTable", Vector3(0.0, 0.42, 1.15),
        Vector3(1.7, 0.8, 0.85), Color(0.40, 0.32, 0.25), true)
    _box(parcel, "SealedParcelCase", Vector3(0.0, 0.50, 1.10),
        Vector3(1.05, 0.66, 0.8), Color(0.49, 0.39, 0.26), true)
    _box(dropoff, "StampedReceiptStone", Vector3(0.0, 0.45, 1.1),
        Vector3(1.32, 0.64, 0.80), Color(0.40, 0.46, 0.46), true)
    hub.call("_add_location", "yb_v057_registrar", "Life Road Registrar", REGISTRAR, registrar)
    hub.call("_add_location", "yb_v057_pickup", "Civic Parcel Pickup", PICKUP, parcel)
    hub.call("_add_location", "yb_v057_delivery", "Civic Courier Delivery", DELIVERY, dropoff)

func _text(parent: Node, message: String, font_size: int = 18) -> Label:
    var lbl := Label.new()
    lbl.text = message
    lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    lbl.add_theme_font_size_override("font_size", font_size)
    lbl.add_theme_color_override("font_color", Color(0.91, 0.95, 0.97))
    parent.add_child(lbl)
    return lbl

func _make_ui() -> void:
    var overlay := CanvasLayer.new()
    overlay.name = "LifeRoadCanvasV057"
    overlay.layer = 16
    get_parent().add_child(overlay)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.add_child(root)
    panel = PanelContainer.new()
    panel.name = "LifeRoadRegistrationPanel"
    panel.anchor_left = 0.12
    panel.anchor_right = 0.88
    panel.anchor_top = 0.08
    panel.anchor_bottom = 0.92
    panel.visible = false
    var background := StyleBoxFlat.new()
    background.bg_color = Color(0.045, 0.075, 0.12, 0.97)
    background.border_color = Color(0.49, 0.62, 0.72)
    background.set_border_width_all(2)
    background.set_corner_radius_all(10)
    panel.add_theme_stylebox_override("panel", background)
    root.add_child(panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    panel.add_child(margin)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    margin.add_child(scroll)
    var column := VBoxContainer.new()
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    column.add_theme_constant_override("separation", 9)
    scroll.add_child(column)
    _text(column, "MARGERINA / YOUR ROAD", 24)
    _text(column, "Young Blood's life-path choices adapted into the 3D city. Your selection is permanent in this save.", 16)
    current_road = _text(column, "Road not chosen", 18)
    _text(column, "HOME NATION / original Young Blood creator selection", 16)
    nation_option = OptionButton.new()
    nation_option.custom_minimum_size.y = 45
    for place in Rules.NATIONS:
        nation_option.add_item(place)
    column.add_child(nation_option)
    _text(column, "CHOOSE YOUR LIFE PATH", 18)
    for road in Rules.ROADS:
        var button := Button.new()
        button.text = Rules.path_label(road)
        button.custom_minimum_size.y = 56
        button.pressed.connect(_choose_path.bind(road))
        column.add_child(button)
        road_buttons.append(button)
    shift_button = Button.new()
    shift_button.text = "ACCEPT CIVIC COURIER SHIFT"
    shift_button.custom_minimum_size.y = 53
    shift_button.pressed.connect(_accept_shift)
    column.add_child(shift_button)
    _text(column, "YOUR HISTORY / YOUNG BLOOD ORIGINS", 20)
    _text(column, "Choose after registering your road. These nine backgrounds and bonuses are provisional game-only adaptations.", 15)
    background_option = _origin_choice(column, "SOCIAL ORIGIN", Origins.BACKGROUND_NAMES)
    temperament_option = _origin_choice(column, "TEMPERAMENT", Origins.TEMPERAMENTS)
    trait_option = _origin_choice(column, "ONE TRAIT", Origins.TRAITS)
    _text(column, "DISADVANTAGES (UP TO 2; EACH GIVES 1 EXTRA PERK POINT)", 16)
    for id in Origins.DISADVANTAGES:
        var item := CheckBox.new()
        item.text = Origins.label(id)
        item.custom_minimum_size.y = 38
        item.toggled.connect(_refresh_origin_controls)
        column.add_child(item)
        origin_checks.append(item)
    _text(column, "PERKS (1 FREE POINT + 1 PER DISADVANTAGE)", 16)
    for id in Origins.PERKS:
        var perk := CheckBox.new()
        perk.text = Origins.label(id)
        perk.custom_minimum_size.y = 38
        perk.toggled.connect(_refresh_origin_controls)
        column.add_child(perk)
        perk_checks.append(perk)
    origins_feedback = _text(column, "Choose a starting road first.", 15)
    origins_confirm = Button.new()
    origins_confirm.text = "SEAL ORIGINAL SEEKER HISTORY"
    origins_confirm.custom_minimum_size.y = 52
    origins_confirm.pressed.connect(_register_origin)
    column.add_child(origins_confirm)
    notice = _text(column, "", 16)
    var close := Button.new()
    close.text = "RETURN TO MARGERINA"
    close.custom_minimum_size.y = 52
    close.pressed.connect(_close_panel)
    column.add_child(close)

func _origin_choice(parent: VBoxContainer, caption: String, choices: Array[String]) -> OptionButton:
    _text(parent, caption, 16)
    var option := OptionButton.new()
    option.custom_minimum_size.y = 46
    for entry in choices:
        option.add_item(Origins.label(entry))
    parent.add_child(option)
    return option

func _selected_keys(items: Array[CheckBox], keys: Array[String]) -> Array:
    var selected: Array = []
    for i in range(items.size()):
        if items[i].button_pressed:
            selected.append(keys[i])
    return selected

func _current_origin() -> Dictionary:
    if not is_instance_valid(codex):
        return {}
    var profile: Dictionary = codex.get("profile")
    return Origins.sanitize(profile.get("origin_v058", {}))

func get_origin_effects() -> Dictionary:
    return Origins.effects(_current_origin())

func _save_origin(data: Dictionary) -> bool:
    if not is_instance_valid(codex) or bool(codex.get("save_blocked")):
        return false
    var clean: Dictionary = Origins.sanitize(data)
    if clean.is_empty():
        return false
    var profile: Dictionary = codex.get("profile")
    profile["origin_v058"] = clean
    var identity: Dictionary = profile.get("identity", {})
    identity["background_id"] = str(clean["background"])
    profile["identity"] = identity
    codex.set("profile", profile)
    codex.call("_save_profile")
    var file := FileAccess.open("user://seeker_profile_v1.json", FileAccess.READ)
    if file == null:
        return false
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        return false
    return Origins.sanitize(parsed.get("origin_v058", {})) == clean

func _apply_home_clothing() -> void:
    if not is_instance_valid(player):
        return
    var record: Dictionary = _current_life()
    if record.is_empty():
        return
    var rig: Node = player.get_node_or_null("AnimatedSeeker")
    if is_instance_valid(rig) and rig.has_method("apply_national_outfit"):
        rig.call("apply_national_outfit", str(record.get("nation", "")))

func _refresh_origin_controls(_unused: Variant = null) -> void:
    if not is_instance_valid(origins_feedback):
        return
    var existing: Dictionary = _current_origin()
    var locked: bool = not existing.is_empty()
    var has_road: bool = not _current_life().is_empty()
    for option in [background_option, temperament_option, trait_option]:
        option.disabled = locked or not has_road
    for item in origin_checks:
        item.disabled = locked or not has_road
    for item in perk_checks:
        item.disabled = locked or not has_road
    var selected_burdens: Array = _selected_keys(origin_checks, Origins.DISADVANTAGES)
    var selected_perks: Array = _selected_keys(perk_checks, Origins.PERKS)
    var budget: int = 1 + selected_burdens.size()
    var can_register: bool = has_road and not locked and not bool(codex.get("save_blocked")) \
        and selected_burdens.size() <= Origins.MAX_DISADVANTAGES and selected_perks.size() <= budget
    origins_confirm.disabled = not can_register
    if locked:
        origins_feedback.text = Origins.summary(existing) + " | History sealed for this save."
    elif not has_road:
        origins_feedback.text = "Register a starting life road first."
    else:
        origins_feedback.text = "Perk points: %d/%d | Disadvantages: %d/2" % [
            selected_perks.size(), budget, selected_burdens.size()]
        if not can_register:
            origins_feedback.text += " | Resolve overspent points before saving."

func _register_origin() -> void:
    if not _current_origin().is_empty() or _current_life().is_empty():
        _refresh_origin_controls()
        return
    var background: String = Origins.BACKGROUNDS[background_option.selected]
    var temperament: String = Origins.TEMPERAMENTS[temperament_option.selected]
    var trait: String = Origins.TRAITS[trait_option.selected]
    var burdens: Array = _selected_keys(origin_checks, Origins.DISADVANTAGES)
    var perks: Array = _selected_keys(perk_checks, Origins.PERKS)
    var result: Dictionary = Origins.choose_once({}, background, temperament, trait, burdens, perks)
    if result.is_empty():
        origins_feedback.text = "Invalid or overspent origin; revise your choices."
        return
    if not _save_origin(result):
        origins_feedback.text = "Cannot verify saved background; no origin registered."
        return
    codex.call("record_event", "v058:origin", "original_seeker_history",
        "Sealed your original Seeker history",
        Origins.summary(result) + ". Game-only background, no canon secret or lineage unlocked.")
    _announce("Your temperament, trait and origin are recorded in the Personal Codex.")
    _refresh_origin_controls()

func _day() -> int:
    return maxi(1, int(floor(float(hub.get("world_minutes")) / 1440.0)) + 1)

func _current_life() -> Dictionary:
    if not is_instance_valid(codex):
        return {}
    var current_profile: Dictionary = codex.get("profile")
    return Rules.sanitize(current_profile.get("life_v057", {}))

func _save_life(record: Dictionary) -> bool:
    if not is_instance_valid(codex) or bool(codex.get("save_blocked")):
        return false
    var profile: Dictionary = codex.get("profile")
    var clean: Dictionary = Rules.sanitize(record)
    if clean.is_empty():
        return false
    profile["life_v057"] = clean
    codex.set("profile", profile)
    codex.call("_save_profile")
    # Do not announce successful registration/pickup or pay money unless
    # the actual on-disk Codex receipt can be read back.
    var verify := FileAccess.open("user://seeker_profile_v1.json", FileAccess.READ)
    if verify == null:
        return false
    var stored: Variant = JSON.parse_string(verify.get_as_text())
    verify.close()
    if typeof(stored) != TYPE_DICTIONARY:
        return false
    return Rules.sanitize(stored.get("life_v057", {})) == clean

func _announce(message: String) -> void:
    if is_instance_valid(hub):
        hub.call("_announce", message)

func _open_panel() -> void:
    if not initialized:
        return
    _refresh_ui()
    panel.show()
    player.velocity.x = 0.0
    player.velocity.z = 0.0

func _close_panel() -> void:
    if is_instance_valid(panel):
        panel.hide()

func _refresh_ui() -> void:
    var selected: Dictionary = _current_life()
    var chosen: bool = not selected.is_empty()
    current_road.text = Rules.next_step(selected) if chosen else "Your road has not yet been registered."
    nation_option.disabled = chosen
    if chosen:
        nation_option.select(maxi(0, Rules.NATIONS.find(str(selected.get("nation", "Janoah")))))
    for button in road_buttons:
        button.disabled = chosen or bool(codex.get("save_blocked"))
    shift_button.visible = chosen and str(selected.get("road", "")) == Rules.ROAD_TRADE
    if shift_button.visible:
        var info: Dictionary = selected["work"]
        shift_button.disabled = str(info["stage"]) != "idle" or int(info["paid_day"]) >= _day()
    if bool(codex.get("save_blocked")):
        notice.text = "Saved Codex cannot be read safely; registration is unavailable to protect the existing profile."
    elif chosen:
        notice.text = "%s | %s | %s" % [Rules.path_label(str(selected["road"])), str(selected["nation"]), Rules.next_step(selected)]
    else:
        notice.text = "Exam = candidate; Sworn = an existing Iron licence in your backstory; Trade = unlicensed civilian work."
    _refresh_origin_controls()

func interact(spot: String) -> void:
    if not initialized:
        return
    if spot == "yb_v057_registrar":
        _open_panel()
    elif spot == "yb_v057_pickup":
        _pickup()
    elif spot == "yb_v057_delivery":
        _deliver()

func _choose_path(path: String) -> void:
    if bool(codex.get("save_blocked")):
        notice.text = "Cannot write your saved record safely."
        return
    if not _current_life().is_empty():
        notice.text = "This save has already registered a road."
        return
    if GameState.seeker_rank != "Stray" and not (path == Rules.ROAD_SWORN and GameState.seeker_rank == "Iron"):
        notice.text = "Your existing Seeker rank is already established. This starter registration is for new road choices."
        return
    if path == Rules.ROAD_TRADE and int(hub.get("active_contract")) >= 0:
        notice.text = "Finish or resolve your currently active Seeker contract before entering civilian work."
        return
    var nation: String = Rules.NATIONS[nation_option.selected]
    var next: Dictionary = Rules.choose_path({}, path, nation, _day())
    if next.is_empty():
        notice.text = "This life road or nation is not available."
        return
    if not _save_life(next):
        notice.text = "Could not save your starting road."
        return
    var profile: Dictionary = codex.get("profile")
    var identity: Dictionary = profile.get("identity", {})
    identity["origin_id"] = nation
    profile["identity"] = identity
    if path == Rules.ROAD_SWORN:
        var career: Dictionary = profile.get("career", {})
        career["license_backstory"] = "Iron / existing prior qualification / game_only"
        profile["career"] = career
        if GameState.seeker_rank == "Stray":
            GameState.set_rank("Iron")
            hub.call("_save_game")
    codex.set("profile", profile)
    codex.call("_save_profile")
    codex.call("record_event", "v057:life_road", "life_road_chosen",
        "Registered a life road: " + Rules.path_label(path),
        "Home nation: %s. Starting road is a player-created backstory, not an alteration of published canon." % nation)
    _apply_home_clothing()
    _announce("Your road is registered in the Personal Codex.")
    _refresh_ui()

func _accept_shift() -> void:
    var next: Dictionary = Rules.accept_courier_shift(_current_life(), _day())
    if next.is_empty():
        notice.text = "No new shift available today. Existing shifts must be delivered first."
        return
    if not _save_life(next):
        notice.text = "Cannot save shift safely."
        return
    _announce("Shift accepted. Collect the parcel at the public pickup marker.")
    _refresh_ui()

func _pickup() -> void:
    var next: Dictionary = Rules.collect_parcel(_current_life())
    if next.is_empty():
        _announce("This parcel is assigned only to an active civilian courier.")
        return
    if _save_life(next):
        _announce("Parcel secured. Carry it to the professional service counter.")
    else:
        _announce("Unable to save the parcel pickup.")

func _deliver() -> void:
    var next: Dictionary = Rules.deliver_parcel(_current_life(), _day())
    if next.is_empty():
        _announce("No authorized courier parcel is ready for delivery.")
        return
    if not _save_life(next):
        _announce("Unable to save the delivery receipt. No payout issued.")
        return
    # Save the one-time receipt to the Codex before issuing money. The old
    # v033 hub save remains authoritative for Tola.
    GameState.earn_tola(Rules.COURIER_PAY_TOLA)
    hub.call("_save_game")
    codex.call("record_event", "v057:courier:day:%d" % _day(),
        "trade_shift_completed", "Completed a civic courier shift",
        "Delivered the parcel through Magnara Ring Two. Earned %d Tola." % Rules.COURIER_PAY_TOLA)
    _announce("Courier shift complete. +%d Tola. Your receipt is saved." % Rules.COURIER_PAY_TOLA)
