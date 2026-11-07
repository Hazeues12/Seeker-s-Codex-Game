extends Node3D
# V0.66 published businesses: distinct collision-true interiors, doorways,
# daily staff and purchases. Shop addresses, items, staff and prices are
# deliberately GAME ONLY. Le'Bell's / Avicci / Vernal Divongcci are published.
const Rules = preload("res://systems/magnara_business_rules_v066.gd")
const SaveIntegrity = preload("res://systems/game_save_integrity_v063.gd")
const SHOPS: Array[String] = ["lebells", "avicci", "vernal_divongcci"]
const SITES: Array[Vector3] = [
    Vector3(-94.0, 0.0, 620.0),
    Vector3(94.0, 0.0, 650.0),
    Vector3(-94.0, 0.0, 686.0)
]
const STAFF: Array[String] = ["Miri Penn", "Orin Vell", "Celia Marr"]
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
var staff_models: Dictionary = {}
var materials: Dictionary = {}
var meshes: Dictionary = {}
var seconds: float = 0.0

func _ready() -> void:
    add_to_group("magnara_businesses_v066")
    set_process(false)
    call_deferred("_initialize")

func _initialize() -> void:
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(player):
        push_warning("V0.66 public businesses require original hub, player, and Personal Codex")
        return
    var regions: Dictionary = Rules.read_region_registry()
    if not Rules.valid_regions(regions):
        push_error("V0.66 regional spawn gates failed validation")
        return
    _make_avenues()
    for i in range(SHOPS.size()):
        _make_store(SHOPS[i], i)
    _make_panel()
    initialized = true
    _update_workers()
    set_process(true)

func get_manifest() -> Dictionary:
    return {
        "version": 66,
        "city": "Magnara", "ring": 2, "canon_names": SHOPS.size(),
        "actual_physical_businesses": SHOPS.size(),
        "region_registry": Rules.read_region_registry().get("regions", []).size(),
        "published_shop_names": true, "staff_owners_prices_and_coordinates": "game_only",
        "shop_purchases_verified_in_existing_world_save": true,
        "next_unbuilt_ring_iv_merchant_quarter": "unchanged",
        "new_north_street_extent_z": 707.0,
        "realm_and_canon_gate": "no NPCs teleported to unbuilt cities"
    }

func _material(shade: Color) -> StandardMaterial3D:
    var key: String = str(shade)
    if materials.has(key):
        return materials[key]
    var mat := StandardMaterial3D.new()
    mat.albedo_color = shade
    mat.roughness = 0.83
    materials[key] = mat
    return mat

func _part(parent: Node3D, key: String, position: Vector3, size: Vector3,
        shade: Color, solid: bool = false) -> MeshInstance3D:
    var thing := MeshInstance3D.new()
    thing.name = key
    thing.position = position
    var mesh_key: String = str(size)
    var shape: BoxMesh
    if meshes.has(mesh_key):
        shape = meshes[mesh_key]
    else:
        shape = BoxMesh.new()
        shape.size = size
        meshes[mesh_key] = shape
    thing.mesh = shape
    thing.material_override = _material(shade)
    thing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(thing)
    if solid:
        var body := StaticBody3D.new()
        body.name = key + "Solid"
        thing.add_child(body)
        var collider := CollisionShape3D.new()
        collider.name = "BusinessV066Collision"
        var box := BoxShape3D.new()
        box.size = size
        collider.shape = box
        body.add_child(collider)
    return thing

func _label(parent: Node3D, caption: String, pos: Vector3) -> void:
    var tag := Label3D.new()
    tag.name = "BusinessV066Wayfinding"
    tag.text = caption
    tag.position = pos
    tag.font_size = 28
    tag.pixel_size = 0.0055
    tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    tag.no_depth_test = true
    parent.add_child(tag)

func _make_avenues() -> void:
    # V0.65 roads finish at z=580; extend all three connected spines to 707.
    for x in [-62.0, 0.0, 62.0]:
        _part(self, "V066ConnectedShopStreet", Vector3(x, 0.59, 643.0),
            Vector3(10.5, 0.14, 128.0), Color(0.68, 0.65, 0.59), true)
        for side in [-1.0, 1.0]:
            _part(self, "V066PublicPavement", Vector3(x + side * 7.2, 0.63, 643.0),
                Vector3(2.8, 0.13, 128.0), Color(0.77, 0.73, 0.65), true)
    for z in [618.0, 658.0, 692.0]:
        _part(self, "V066CrossAvenue", Vector3(0.0, 0.65, z),
            Vector3(130.0, 0.12, 9.3), Color(0.69, 0.67, 0.62), true)
    _label(self, "MAGNARA / OUTER SEEKER QUARTERS / LOCAL SHOPFRONTS",
        Vector3(0.0, 5.7, 589.0))
    for x in [-62.0, 62.0]:
        for z in [598.0, 640.0, 684.0]:
            _part(self, "V066StreetLanternPost", Vector3(x + 9.0, 2.1, z),
                Vector3(0.19, 3.1, 0.19), Color(0.42, 0.37, 0.31), true)
            _part(self, "V066ResonanceLantern", Vector3(x + 9.0, 3.84, z),
                Vector3(0.61, 0.70, 0.61), Color(0.32, 0.65, 0.78))

func _make_store(shop: String, index: int) -> void:
    var house := Node3D.new()
    house.name = "V066Shop_" + shop
    house.position = SITES[index]
    add_child(house)
    var facing: float = 1.0 if index != 1 else -1.0
    var wall: Color = Color(0.55, 0.47, 0.38) if index == 0 else (
        Color(0.55, 0.58, 0.61) if index == 1 else Color(0.56, 0.57, 0.59))
    var roof: Color = Color(0.39, 0.31, 0.26) if index == 0 else (
        Color(0.32, 0.34, 0.42) if index == 1 else Color(0.32, 0.29, 0.38))
    var accent: Color = Color(0.79, 0.61, 0.36) if index == 0 else (
        Color(0.39, 0.70, 0.86) if index == 1 else Color(0.70, 0.50, 0.70))
    _part(house, "V066StoreActualFloor", Vector3(0, 0.53, 0),
        Vector3(18.0, 0.15, 18.0), Color(0.73, 0.67, 0.60), true)
    _part(house, "V066StoreRearWall", Vector3(-facing * 9.0, 3.0, 0),
        Vector3(0.42, 5.0, 18.3), wall, true)
    for side in [-1.0, 1.0]:
        _part(house, "V066StoreSideWall", Vector3(0.0, 3.0, side * 9.0),
            Vector3(18.3, 5.0, 0.42), wall, true)
        _part(house, "V066StoreOpenDoorWing", Vector3(facing * 9.0, 3.0, side * 5.75),
            Vector3(0.42, 5.0, 6.5), wall, true)
    _part(house, "V066StoreOpenDoorLintel", Vector3(facing * 9.0, 4.82, 0),
        Vector3(0.43, 1.35, 5.0), wall, true)
    _part(house, "V066StoreSolidRoof", Vector3(0, 5.59, 0),
        Vector3(18.6, 0.28, 18.6), roof, true)
    _part(house, "V066ShopCounter", Vector3(-facing * 2.3, 1.18, 0),
        Vector3(1.7, 1.1, 6.0), Color(0.42, 0.34, 0.29), true)
    if index == 0:
        # Published diner atmosphere: forge-bread and late-night service.
        for j in range(3):
            _part(house, "V066BreadTray", Vector3(-facing * 0.2, 1.81, -2.7 + j * 2.7),
                Vector3(1.3, 0.25, 0.95), Color(0.77, 0.52, 0.26))
        _part(house, "V066Oven", Vector3(-facing * 6.5, 1.6, -4.4),
            Vector3(1.7, 2.0, 2.4), Color(0.32, 0.29, 0.28), true)
        for side in [-1.0, 1.0]:
            _part(house, "V066DinerTable", Vector3(facing * 4.0, 1.0, side * 4.2),
                Vector3(2.4, 0.85, 1.8), Color(0.42, 0.36, 0.29), true)
    elif index == 1:
        # Published Water/Earth-Muti jewelry, prototype noncanonical stock.
        for side in [-1.0, 1.0]:
            _part(house, "V066JewelryGlassCase", Vector3(-facing * 4.0, 1.35, side * 4.5),
                Vector3(2.5, 1.35, 1.55), Color(0.47, 0.63, 0.73), true)
            _part(house, "V066JewelryDisplay", Vector3(-facing * 4.0, 2.13, side * 4.5),
                Vector3(0.84, 0.15, 0.85), Color(0.37, 0.72, 0.89))
    else:
        # Published perfumery: fragrant bottles and interior display shelves.
        for side in [-1.0, 1.0]:
            _part(house, "V066PerfumeShelf", Vector3(-facing * 5.6, 1.6, side * 5.1),
                Vector3(1.15, 2.4, 2.6), Color(0.46, 0.40, 0.45), true)
            for j in range(3):
                _part(house, "V066PerfumeBottle", Vector3(-facing * 4.9, 1.9, side * 5.1 + (j - 1) * 0.68),
                    Vector3(0.26, 0.58, 0.27), accent)
    _part(house, "V066ShopFrontSign", Vector3(facing * 9.3, 4.3, 0),
        Vector3(0.19, 1.4, 8.0), accent)
    _label(house, Rules.name_for(shop).to_upper() + " / CANON STOREFRONT",
        Vector3(0, 6.4, 0))
    var road: float = -62.0 if index != 1 else 62.0
    var entrance: float = SITES[index].x + facing * 9.0
    _part(self, "V066ShopApproach_" + shop, Vector3((road + entrance) * 0.5, 0.66, SITES[index].z),
        Vector3(absf(entrance - road) + 1.6, 0.14, 3.4),
        Color(0.78, 0.73, 0.66), true)
    var use_point := Node3D.new()
    use_point.name = "V066StoreInteractionPoint"
    use_point.position = Vector3(facing * 10.85, 0.7, 0)
    house.add_child(use_point)
    hub.call("_add_location", "shop_v066_" + shop, Rules.name_for(shop), use_point.global_position, use_point)
    var worker := Node3D.new()
    worker.name = "V066StoreStaff_" + shop
    worker.position = Vector3(-facing * 3.3, 0, 0)
    house.add_child(worker)
    _part(worker, "V066StaffTorso", Vector3(0, 1.15, 0),
        Vector3(0.59, 0.90, 0.38), accent)
    _part(worker, "V066StaffHead", Vector3(0, 1.89, 0),
        Vector3(0.40, 0.42, 0.39), Color(0.63, 0.49, 0.36))
    for side in [-1.0, 1.0]:
        _part(worker, "V066StaffArm", Vector3(side * 0.37, 1.12, 0),
            Vector3(0.17, 0.71, 0.25), accent)
        _part(worker, "V066StaffLeg", Vector3(side * 0.16, 0.42, 0),
            Vector3(0.19, 0.74, 0.26), Color(0.27, 0.31, 0.37))
    staff_models[shop] = worker

func _make_panel() -> void:
    var canvas := CanvasLayer.new()
    canvas.layer = 24
    canvas.name = "V066BusinessCanvas"
    get_parent().add_child(canvas)
    var base := Control.new()
    base.set_anchors_preset(Control.PRESET_FULL_RECT)
    base.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(base)
    panel = PanelContainer.new()
    panel.anchor_left = 0.10
    panel.anchor_right = 0.90
    panel.anchor_top = 0.07
    panel.anchor_bottom = 0.93
    panel.visible = false
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(0.065, 0.080, 0.12, 0.98)
    skin.border_color = Color(0.66, 0.56, 0.41)
    skin.set_border_width_all(2)
    skin.set_corner_radius_all(10)
    panel.add_theme_stylebox_override("panel", skin)
    base.add_child(panel)
    var margins := MarginContainer.new()
    for side in ["left", "right", "top", "bottom"]:
        margins.add_theme_constant_override("margin_" + side, 14)
    panel.add_child(margins)
    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 9)
    margins.add_child(layout)
    heading = Label.new()
    heading.add_theme_font_size_override("font_size", 24)
    layout.add_child(heading)
    details = Label.new()
    details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    layout.add_child(details)
    var scroller := ScrollContainer.new()
    scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_child(scroller)
    actions = VBoxContainer.new()
    actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroller.add_child(actions)
    feedback = Label.new()
    feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    layout.add_child(feedback)
    var close := Button.new()
    close.text = "RETURN TO MAGNARA"
    close.custom_minimum_size.y = 50
    close.pressed.connect(_close)
    layout.add_child(close)

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()

func _day() -> int:
    return maxi(1, int(floorf(float(hub.get("world_minutes")) / 1440.0)) + 1)

func _stock() -> Dictionary:
    return Rules.sanitize_stock(hub.get("shop_stock_v066"))

func _button(label: String, code: String, allowed: bool) -> void:
    var control := Button.new()
    control.text = label
    control.custom_minimum_size.y = 54
    control.disabled = not allowed
    control.pressed.connect(_choose.bind(code))
    actions.add_child(control)

func interact(id: String) -> void:
    if not initialized or not id.begins_with("shop_v066_"):
        return
    selected = id.trim_prefix("shop_v066_")
    if not SHOPS.has(selected):
        return
    feedback.text = ""
    _refresh()
    panel.show()

func _refresh() -> void:
    for child in actions.get_children():
        actions.remove_child(child)
        child.queue_free()
    var now: float = float(hub.get("world_minutes"))
    var day: int = _day()
    var remaining: int = Rules.stock_for(selected, day, _stock())
    var item: String = Rules.item_for(selected)
    var quote: int = Rules.quote(selected, day)
    var open: bool = Rules.open_for(selected, now)
    var hours: String = "11:00-02:00" if selected == "lebells" else (
        "10:00-20:00" if selected == "avicci" else "10:30-21:00")
    heading.text = Rules.name_for(selected).to_upper() + " / MAGNARA"
    details.text = "Day %d / %s / %s\nDaily merchandise remaining: %d\n%s / %d Tola\nYour Tola: %d" % [
        day, hours, "STAFFED" if open else "OFF SHIFT",
        remaining, item, quote, GameState.tola]
    details.text += "\nStaff: %s / local employee (game only)" % STAFF[SHOPS.find(selected)]
    if selected == "lebells":
        details.text += "\nWarm forge-bread and late-night dining, as seen in the published series."
    elif selected == "avicci":
        details.text += "\nWater/Earth-Muti stones and luxury ornaments; this particular stock is a prototype."
    else:
        details.text += "\nFragrance shelves and perfumery; individual perfumes and prices are prototypes."
    _button("BUY 1 / %d TOLA" % quote, "purchase", open and remaining > 0 and GameState.tola >= quote)
    _button("ASK ABOUT TODAY'S SERVICE", "ask", open)

func _inventory_counts(raw: Variant) -> Dictionary:
    var result: Dictionary = {}
    if typeof(raw) != TYPE_DICTIONARY:
        return result
    var bag: Dictionary = raw
    for key in bag:
        result[str(key)] = int(bag[key])
    return result

func _verify_purchase(new_inventory: Dictionary, new_stock: Dictionary) -> bool:
    var result: Dictionary = SaveIntegrity.load_best()
    if str(result.get("source", "none")) != "primary":
        return false
    var data: Dictionary = result.get("data", {})
    return int(data.get("tola", -1)) == GameState.tola \
        and _inventory_counts(data.get("inventory", {})) == _inventory_counts(new_inventory) \
        and Rules.sanitize_stock(data.get("shop_stock_v066", {})) == Rules.sanitize_stock(new_stock)

func _purchase() -> void:
    var shop: String = selected
    var now: float = float(hub.get("world_minutes"))
    var day: int = _day()
    var quote: int = Rules.quote(shop, day)
    if not Rules.open_for(shop, now) or Rules.stock_for(shop, day, _stock()) <= 0 or GameState.tola < quote:
        feedback.text = "The store is closed, has sold out, or you need more Tola."
        _refresh()
        return
    var previous_stock: Dictionary = _stock()
    var previous_bag: Dictionary = hub.get("inventory").duplicate(true)
    var previous_tola: int = GameState.tola
    var new_stock: Dictionary = Rules.record_buy(shop, day, previous_stock)
    if new_stock.is_empty() or not GameState.spend_tola(quote):
        feedback.text = "Purchase rejected with no charge."
        return
    var next_bag: Dictionary = _inventory_counts(previous_bag)
    var item: String = Rules.item_for(shop)
    next_bag[item] = int(next_bag.get(item, 0)) + 1
    hub.set("inventory", next_bag)
    hub.set("shop_stock_v066", new_stock)
    var success: bool = bool(hub.call("_save_game"))
    if success:
        success = _verify_purchase(next_bag, new_stock)
    if not success:
        hub.set("inventory", previous_bag)
        hub.set("shop_stock_v066", previous_stock)
        GameState.tola = previous_tola
        GameState.tola_changed.emit(previous_tola)
        # If an error occurs after the V0.63 write succeeded, save the old
        # values again rather than silently leaving a charged receipt.
        hub.call("_save_game")
        feedback.text = "Verified purchase failed; your Tola and bag were restored."
        _refresh()
        return
    var visit: int = int(new_stock.get("day:%d:%s" % [day, shop], 0))
    if is_instance_valid(codex) and codex.has_method("record_event"):
        codex.call("record_event", "v066:store:%s:day:%d:purchase:%d" % [shop, day, visit],
            "public_trade", "Bought goods at " + Rules.name_for(shop),
            "Prototype merchandise: %s / %d Tola. Recorded in verified world save." % [item, quote])
    feedback.text = "Purchased %s for %d Tola. Your bag, money, and remaining stock are saved." % [item, quote]
    _refresh()

func _choose(code: String) -> void:
    if code == "ask":
        var moods: Dictionary = {
            "lebells": "The kitchen is turning out forge-bread for diners coming off late shifts.",
            "avicci": "Staff explain that Water and Earth Muti shape these high-end stones. No rare powers are granted by a pendant.",
            "vernal_divongcci": "The perfumery describes its public fragrance display; none of the scents unlock a Muti technique."
        }
        feedback.text = str(moods.get(selected, "The attendant returns to their work."))
    elif code == "purchase":
        _purchase()

func _update_workers() -> void:
    var now: float = float(hub.get("world_minutes"))
    for shop in SHOPS:
        if staff_models.has(shop):
            var worker: Node3D = staff_models[shop]
            var active: bool = Rules.open_for(shop, now)
            worker.visible = active
            var index: int = SHOPS.find(shop)
            var facing: float = -1.0 if index == 1 else 1.0
            worker.position.x = -facing * 3.3
            worker.position.z = sin(now * 0.018 + float(index)) * 0.36 if active else 0.0
            worker.set_meta("routine", Rules.staff_activity(shop, now))

func _process(delta: float) -> void:
    seconds += delta
    if seconds >= 0.60:
        seconds = 0.0
        _update_workers()
