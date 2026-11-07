extends Node3D
# Provisional game-only cart and delivery route. Forge bread appears in the published Janoah chapter.
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const Freight = preload("res://systems/magnara_local_logistics_rules_v073.gd")
const Art = preload("res://systems/magnara_published_city_visual_rules_v076.gd")
const Rig = preload("res://characters/procedural_seeker.gd")
const COURT_TILE := Vector2i(2, 6)
const SUPPLIER := Freight.INLAND_DEPOT_AT + Vector3(-7.0, -0.25, 0.0)
const COUNTER_ID := "commons_v081_cart"
const SUPPLIER_ID := "commons_v081_supplier"
const FOOD := "Forge Bread"
const PRICE := 4
const CAPACITY := 12
const CRATE_UNITS := 4
const PAY := 12
const DRAW_DISTANCE := 65.0

var hub: Node
var player: CharacterBody3D
var court: Vector3
var enabled := false
var cart: Node3D
var vendor: Rig
var counter: Node3D
var supplier: Node3D
var panel: PanelContainer
var entries: VBoxContainer
var site: String

static func clean(raw: Variant) -> Dictionary:
    var data: Dictionary = raw if raw is Dictionary else {}
    var stock: Variant = data.get("stock", 4)
    var day: Variant = data.get("paid_day", -1)
    return {
        "stock": clampi(int(stock), 0, CAPACITY) if stock is int or stock is float else 4,
        "carrying": data.get("carrying", false) == true,
        "paid_day": maxi(-1, int(day)) if day is int or day is float else -1,
    }

func configure(hero: CharacterBody3D, city_hub: Node) -> void:
    player = hero
    hub = city_hub
    var courts: Array = Art.tile_art(COURT_TILE)["court_centers"]
    if courts.is_empty() or not is_instance_valid(hub):
        return
    court = Geo.tile_center(COURT_TILE) + (courts[0] as Vector3)
    enabled = true
    add_to_group("magnara_commons_cart_v081")
    supplier = Node3D.new()
    supplier.name = "CommonsSupplyPickup"
    add_child(supplier)
    supplier.global_position = SUPPLIER
    _piece(supplier, Vector3(-0.9, 0.32, 0), Vector3(0.7, 0.65, 0.65), Color(0.62, 0.42, 0.23))
    _sign(supplier, "COMMONS SUPPLY PICKUP", Vector3.UP * 1.8).visibility_range_end = 28.0
    supplier.hide()

func _hour() -> float:
    return fposmod(float(hub.get("world_minutes")), 1440.0) / 60.0

func _day() -> int:
    return floori(float(hub.get("world_minutes")) / 1440.0)

func _open_hours() -> bool:
    var hour := _hour()
    return hour >= 10.0 and hour < 20.5

func _sign(parent: Node3D, caption: String, at: Vector3) -> Label3D:
    var label := Label3D.new()
    label.text = caption
    label.position = at
    label.font_size = 34
    label.pixel_size = 0.007
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    parent.add_child(label)
    return label

func _piece(parent: Node3D, at: Vector3, size: Vector3, tint: Color) -> void:
    var piece := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    piece.mesh = mesh
    piece.position = at
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    piece.material_override = material
    piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(piece)

func _build_cart() -> void:
    cart = Node3D.new()
    cart.name = "CommonsForgeBreadCart"
    cart.set_meta("canon_status", "game_only")
    add_child(cart)
    cart.global_position = court
    counter = Node3D.new()
    counter.name = "Counter"
    counter.position = Vector3(-4.4, 0.73, -2.5)
    cart.add_child(counter)
    var base := Vector3(-6.1, 0.73, -2.5)
    _piece(cart, base + Vector3.UP * 0.55, Vector3(1.1, 1.1, 2.0), Color(0.51, 0.30, 0.19))
    _piece(cart, base + Vector3.UP * 1.15, Vector3(1.35, 0.16, 2.2), Color(0.73, 0.55, 0.30))
    _piece(cart, base + Vector3.UP * 2.05, Vector3(1.65, 0.14, 2.4), Color(0.67, 0.25, 0.22))
    for side in [-1.0, 1.0]:
        _piece(cart, base + Vector3(0, 1.6, side * 0.95), Vector3(0.13, 0.9, 0.13), Color(0.40, 0.27, 0.19))
    _sign(cart, "FORGE BREAD CART", base + Vector3.UP * 2.55)
    vendor = Rig.new()
    vendor.name = "CommonsBaker"
    vendor.scale = Vector3.ONE * 0.76
    cart.add_child(vendor)
    vendor.configure_civilian(Color(0.63, 0.43, 0.24), Color(0.55, 0.38, 0.27))

func refresh(tiles: Dictionary) -> void:
    if not enabled:
        return
    supplier.visible = player.global_position.distance_to(SUPPLIER) <= DRAW_DISTANCE
    var nearby: bool = tiles.has(Geo.cell_id(COURT_TILE)) and player.global_position.distance_to(court) <= DRAW_DISTANCE
    if nearby and cart == null:
        _build_cart()
    if cart != null:
        cart.visible = nearby
    set_process(nearby)

func _process(delta: float) -> void:
    var hour := _hour()
    var traveling := (hour >= 9.95 and hour < 10.0) or (hour >= 20.5 and hour < 20.55)
    vendor.visible = traveling or _open_hours()
    if not vendor.visible:
        return
    var approach := Vector3(0, 0.72, -13.5)
    var stop := Vector3(-5.1, 0.72, -3.3)
    var fraction := clampf((hour - 9.95) * 20.0, 0.0, 1.0)
    if hour >= 20.5:
        fraction = clampf((20.55 - hour) * 20.0, 0.0, 1.0)
    vendor.position = approach.lerp(stop, fraction)
    vendor.rotation.y = -PI * 0.5
    if traveling:
        var direction := stop - approach
        if hour >= 20.5:
            direction = -direction
        vendor.rotation.y = atan2(-direction.x, -direction.z)
    vendor.animate_state(delta, 1.1 if traveling else 0.0)

func get_nearest_interaction(point: Vector3, reach: float) -> Dictionary:
    if not enabled:
        return {}
    if point.distance_to(SUPPLIER) < reach:
        return {"id": SUPPLIER_ID, "title": "Commons supply pickup", "position": SUPPLIER}
    if cart != null and cart.visible and point.distance_to(counter.global_position) < reach:
        return {"id": COUNTER_ID, "title": "Commons forge bread cart", "position": counter.global_position}
    return {}

func delivery_hint() -> String:
    if not enabled or not bool(hub.get("commons_trade_v081")["carrying"]):
        return ""
    var offset := court - player.global_position
    var bearing := posmod(roundi(atan2(offset.x, -offset.z) / (PI / 4.0)), 8)
    var directions := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    return "BREAD DELIVERY / RING III / %d m %s" % [roundi(Vector2(offset.x, offset.z).length()), directions[bearing]]

func is_open() -> bool:
    return panel != null and panel.visible

func interact(id: String) -> void:
    var near := get_nearest_interaction(player.global_position, float(hub.get("interact_range")))
    if near.get("id", "") != id:
        return
    if panel == null:
        panel = hub.call("_make_menu_panel", "COMMONS FOOD AND FREIGHT")
        entries = panel.get_node("Margin/VBox/Scroll/Entries") as VBoxContainer
    site = id
    _refresh_panel()
    panel.show()

func _button(caption: String, action: String, allowed: bool) -> void:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size.y = 48
    button.disabled = not allowed
    button.pressed.connect(func(): _transact(action))
    entries.add_child(button)

func _refresh_panel() -> void:
    hub.call("_clear_list", entries)
    var state: Dictionary = clean(hub.get("commons_trade_v081"))
    var room: bool = int(state["stock"]) <= CAPACITY - CRATE_UNITS
    if site == SUPPLIER_ID:
        hub.call("_label", entries, "Ring II inland depot. Carry one bread crate to the Ring III cart.", 19)
        hub.call("_label", entries, "Delivery pays %d Tola. The cart receives %d portions." % [PAY, CRATE_UNITS], 19)
        var ready: bool = not state["carrying"] and int(state["paid_day"]) != _day() and room
        if state["carrying"]:
            hub.call("_label", entries, "Crate collected. Follow the delivery direction on the HUD.", 19)
        elif not room:
            hub.call("_label", entries, "The cart has enough bread for now.", 19)
        elif int(state["paid_day"]) == _day():
            hub.call("_label", entries, "Today's delivery is complete.", 19)
        _button("COLLECT BREAD CRATE", "pickup", ready)
        return
    hub.call("_label", entries, "Open 10:00–20:30. Forge bread costs %d Tola." % PRICE, 19)
    hub.call("_label", entries, "Bread available  %d / %d" % [state["stock"], CAPACITY], 19)
    if not _open_hours():
        hub.call("_label", entries, "The vendor is away. Come back during opening hours.", 19)
    _button("BUY FORGE BREAD", "buy", _open_hours() and int(state["stock"]) > 0 and GameState.tola >= PRICE)
    if state["carrying"]:
        _button("DELIVER CRATE / EARN %d TOLA" % PAY, "deliver", _open_hours() and room)

func _transact(action: String) -> void:
    if not is_open():
        return
    var near := get_nearest_interaction(player.global_position, float(hub.get("interact_range")))
    if near.get("id", "") != site:
        panel.hide()
        return
    var old_state: Dictionary = clean(hub.get("commons_trade_v081"))
    var state := old_state.duplicate()
    var old_inventory: Dictionary = hub.get("inventory")
    var inventory := old_inventory.duplicate()
    var old_tola: int = GameState.tola
    var room: bool = int(state["stock"]) <= CAPACITY - CRATE_UNITS
    var notice: String
    match action:
        "pickup":
            if site != SUPPLIER_ID or state["carrying"] or int(state["paid_day"]) == _day() or not room:
                return
            state["carrying"] = true
            notice = "Bread crate collected. Follow the HUD to Ring III."
        "buy":
            if site != COUNTER_ID or not _open_hours() or int(state["stock"]) == 0 or not GameState.spend_tola(PRICE):
                return
            state["stock"] -= 1
            inventory[FOOD] = int(inventory.get(FOOD, 0)) + 1
            notice = "Bought forge bread. Open your bag to eat it."
        "deliver":
            if site != COUNTER_ID or not _open_hours() or not state["carrying"] or not room \
                    or int(state["paid_day"]) == _day():
                return
            state["carrying"] = false
            state["paid_day"] = _day()
            state["stock"] += CRATE_UNITS
            GameState.earn_tola(PAY)
            notice = "Bread delivered. Earned %d Tola." % PAY
        _:
            return
    hub.set("commons_trade_v081", state)
    hub.set("inventory", inventory)
    if not bool(hub.call("_save_game")):
        hub.set("commons_trade_v081", old_state)
        hub.set("inventory", old_inventory)
        GameState.tola = old_tola
        GameState.tola_changed.emit(old_tola)
        hub.call("_announce", "Storage could not save the trade. Your goods and Tola were restored.")
    else:
        hub.call("_announce", notice)
    _refresh_panel()
