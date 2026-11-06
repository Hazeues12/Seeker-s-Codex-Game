extends Node3D
# V0.62 physical mixed-income Ring II streets and three public market stalls.
# Buildings, names, bearings and market quotes are GAME ONLY. Not Ring IV's
# canonical Merchant Quarter or Ring V's artisan houses.
const Rules = preload("res://systems/magnara_market_rules_v062.gd")
const Residential = preload("res://systems/residential_life_v060.gd")
const WEST_X: float = -62.0
const EAST_X: float = 62.0
const CENTER_X: float = 0.0
const HOME_IDS: Array[String] = [
    "west_worker_one", "west_worker_two", "east_townhouse_one",
    "east_townhouse_two", "market_lodging_one", "market_lodging_two"
]
const HOME_X: Array[float] = [-99.0, -99.0, 99.0, 99.0, -32.0, 32.0]
const HOME_Z: Array[float] = [274.0, 340.0, 274.0, 340.0, 357.0, 357.0]
const STALL_X: Array[float] = [-28.0, 28.0, -28.0]
const STALL_Z: Array[float] = [284.0, 284.0, 319.0]
const HOME_TYPES: Array[String] = [
    "worker_rowhouse", "worker_rowhouse", "comfortable_townhouse",
    "comfortable_townhouse", "market_lodging", "market_lodging"
]

var initialized: bool = false
var hub: Node
var codex: Node
var player: CharacterBody3D
var panel: PanelContainer
var title_label: Label
var details: Label
var feedback: Label
var choices: VBoxContainer
var selected_shop: String = ""
var vendors: Dictionary = {}
var stock_signs: Dictionary = {}
var tick: float = 0.0
var materials: Dictionary = {}
var meshes: Dictionary = {}

func _ready() -> void:
    add_to_group("magnara_markets_v062")
    set_process(false)
    call_deferred("_setup")

func _setup() -> void:
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(player):
        push_warning("V0.62 public market needs existing player, hub and Codex")
        return
    _make_streets()
    _make_homes()
    _make_market()
    _make_panel()
    initialized = true
    _update_vendors()
    set_process(true)

func get_manifest() -> Dictionary:
    return {
        "era": "1500 A.S.", "city": "Magnara", "ring": 2,
        "source_status": "game_only", "home_count": HOME_IDS.size(),
        "distinct_home_classes": 3, "public_market_stalls": Rules.IDS.size(),
        "vendor_schedule": true, "individual_vendor_relationships": true,
        "actual_trade_ledger": "hub market_stock_v062 and inventory / same game save",
        "three_road_spines": [-62, 0, 62],
        "market_square_z": 301.0, "northern_extent_z": 376.0,
        "merchant_quarter_ring_iv_unmodified": true,
        "ring_v_artisans_unmodified": true
    }

func _mat(shade: Color) -> StandardMaterial3D:
    var key: String = str(shade)
    if materials.has(key):
        return materials[key]
    var result := StandardMaterial3D.new()
    result.albedo_color = shade
    result.roughness = 0.83
    materials[key] = result
    return result

func _part(parent: Node3D, name: String, at: Vector3, size: Vector3,
        shade: Color, solid: bool = false) -> MeshInstance3D:
    var object := MeshInstance3D.new()
    object.name = name
    object.position = at
    var key: String = str(size)
    var shape: BoxMesh
    if meshes.has(key):
        shape = meshes[key]
    else:
        shape = BoxMesh.new()
        shape.size = size
        meshes[key] = shape
    object.mesh = shape
    object.material_override = _mat(shade)
    object.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(object)
    if solid:
        var body := StaticBody3D.new()
        body.name = name + "Solid"
        object.add_child(body)
        var collider := CollisionShape3D.new()
        collider.name = "MarketWorldCollision"
        var block := BoxShape3D.new()
        block.size = size
        collider.shape = block
        body.add_child(collider)
    return object

func _tag(parent: Node3D, label: String, at: Vector3) -> void:
    var sign := Label3D.new()
    sign.name = "MarketStreetWayfinding"
    sign.text = label
    sign.position = at
    sign.font_size = 29
    sign.pixel_size = 0.006
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.no_depth_test = true
    parent.add_child(sign)

func _make_streets() -> void:
    # V0.61 western street ends z~250, V0.60 eastern at z~211.
    # V0.61's cross-avenue joins the two at z~207. All three extend north.
    for x in [WEST_X, CENTER_X, EAST_X]:
        _part(self, "NorthMarketConnectedStreet", Vector3(x, 0.59, 304.0),
            Vector3(10.5, 0.14, 144.0), Color(0.64, 0.63, 0.58), true)
        for side in [-1.0, 1.0]:
            _part(self, "NorthMarketPavement", Vector3(x + side * 7.2, 0.60, 304.0),
                Vector3(2.7, 0.14, 144.0), Color(0.75, 0.72, 0.64), true)
    # V0.60's eastern residential road ends near z=211; span the gap to
    # the new eastern market road so its geometry is actually connected.
    _part(self, "EastMarketSouthConnector", Vector3(EAST_X, 0.58, 219.0),
        Vector3(10.5, 0.14, 35.0), Color(0.69, 0.65, 0.59), true)
    # Link x=0's main new north road to V0.61's real east-west route at z=207.
    _part(self, "CommercialRoadSouthConnector", Vector3(0.0, 0.57, 222.5),
        Vector3(10.4, 0.14, 35.0), Color(0.66, 0.65, 0.61), true)
    for z in [301.0, 344.0]:
        _part(self, "MarketCrossAvenue", Vector3(0, 0.62, z),
            Vector3(130.0, 0.14, 9.2), Color(0.69, 0.68, 0.63), true)
    _part(self, "CivicMarketplacePaving", Vector3(0, 0.55, 300.0),
        Vector3(94.0, 0.12, 71.0), Color(0.72, 0.69, 0.61), true)
    _part(self, "PublicArcadeWell", Vector3(16.0, 1.15, 325.0),
        Vector3(3.0, 1.2, 3.0), Color(0.52, 0.58, 0.57), true)
    _part(self, "PublicArcadeWellRoof", Vector3(16.0, 3.14, 325.0),
        Vector3(3.8, 0.19, 3.1), Color(0.32, 0.39, 0.42))
    for x in [WEST_X, EAST_X]:
        for i in range(6):
            var z: float = 254.0 + float(i) * 21.0
            _part(self, "StreetBronzeLightPost", Vector3(x + 9.5, 2.03, z),
                Vector3(0.16, 3.1, 0.16), Color(0.43, 0.35, 0.25))
            _part(self, "StreetBlueResonanceLamp", Vector3(x + 9.5, 3.70, z),
                Vector3(0.50, 0.62, 0.50), Color(0.27, 0.67, 0.78))
    _tag(self, "MAGNARA / PUBLIC MIXED-INCOME LANE / GAME ONLY",
        Vector3(0, 5.4, 249.0))

func _home(index: int) -> void:
    var id: String = HOME_IDS[index]
    var x: float = HOME_X[index]
    var z: float = HOME_Z[index]
    var kind: String = HOME_TYPES[index]
    var home := Node3D.new()
    home.name = "OpenHome_" + id
    home.position = Vector3(x, 0.0, z)
    add_child(home)
    var wall_color := Color(0.54, 0.51, 0.46) if index < 2 else (
        Color(0.68, 0.68, 0.63) if index < 4 else Color(0.59, 0.57, 0.54))
    var roof_color := Color(0.34, 0.34, 0.33) if index < 2 else Color(0.29, 0.35, 0.38)
    var edge: float = 7.5 if index >= 2 else 7.0
    # Each modest/comfortable/lodging home has a usable open doorway,
    # a collidable floor, interior furniture and a separately collidable roof.
    _part(home, "ActualHomeFloor", Vector3(0, 0.53, 0),
        Vector3(edge * 2.0, 0.14, edge * 2.0), Color(0.72, 0.64, 0.53), true)
    if index < 4:
        var facing: float = 1.0 if index < 2 else -1.0
        _part(home, "RearResidenceWall", Vector3(-facing * edge, 2.75, 0),
            Vector3(0.38, 4.4, edge * 2.0 + 0.3), wall_color, true)
        for side in [-1.0, 1.0]:
            _part(home, "ResidenceSideWall", Vector3(0, 2.75, side * edge),
                Vector3(edge * 2.0 + 0.3, 4.4, 0.38), wall_color, true)
            _part(home, "DoorwingWall", Vector3(facing * edge, 2.75, side * (edge + 2.0) * 0.5),
                Vector3(0.38, 4.4, edge - 2.0), wall_color, true)
        _part(home, "ResidenceOpenDoorLintel", Vector3(facing * edge, 4.2, 0),
            Vector3(0.44, 1.50, 4.0), wall_color, true)
        var door_x: float = x + facing * edge
        var road_x: float = WEST_X if index < 2 else EAST_X
        _part(self, "HouseholdSidewalkSpur_" + id,
            Vector3((door_x + road_x) * 0.5, 0.63, z),
            Vector3(absf(door_x - road_x) + 0.8, 0.13, 3.3),
            Color(0.74, 0.70, 0.63), true)
    else:
        _part(home, "RearLodgingWall", Vector3(0, 2.75, edge),
            Vector3(edge * 2.0 + 0.3, 4.4, 0.38), wall_color, true)
        for side in [-1.0, 1.0]:
            _part(home, "LodgingSideWall", Vector3(side * edge, 2.75, 0),
                Vector3(0.38, 4.4, edge * 2.0 + 0.3), wall_color, true)
            _part(home, "LodgingDoorWing", Vector3(side * (edge + 2.0) * 0.5, 2.75, -edge),
                Vector3(edge - 2.0, 4.4, 0.38), wall_color, true)
        _part(home, "ResidenceOpenDoorLintel", Vector3(0, 4.2, -edge),
            Vector3(4.0, 1.50, 0.44), wall_color, true)
        _part(self, "MarketLodgingSpur_" + id,
            Vector3(x, 0.63, 346.0), Vector3(3.4, 0.13, 8.0),
            Color(0.73, 0.70, 0.65), true)
    _part(home, "TrueSolidHomeRoof", Vector3(0, 5.14, 0),
        Vector3(edge * 2.0 + 0.6, 0.28, edge * 2.0 + 0.6), roof_color, true)
    _part(home, "HomeInteriorTable", Vector3(-2.0, 1.06, -2.4),
        Vector3(2.9, 0.90, 1.6), Color(0.41, 0.33, 0.25), true)
    _part(home, "HomeInteriorBench", Vector3(2.6, 0.91, 3.4),
        Vector3(2.9, 0.61, 0.78), Color(0.46, 0.37, 0.31), true)
    _part(home, "HomeInteriorShelving", Vector3(-3.5, 1.28, 3.6),
        Vector3(0.7, 1.50, 2.5), Color(0.50, 0.43, 0.32), true)
    if index >= 2 and index < 4:
        _part(home, "ComfortableWindowFrame", Vector3(0, 3.25, -edge),
            Vector3(3.0, 1.25, 0.12), Color(0.34, 0.65, 0.74))
        _part(home, "HouseholdDecorativeWallTrim", Vector3(0, 4.62, -edge),
            Vector3(edge * 1.65, 0.20, 0.14), Color(0.75, 0.68, 0.45))
    elif index < 2:
        _part(home, "WorkerRoofVent", Vector3(-2.0, 5.80, -2.0),
            Vector3(0.91, 1.2, 0.91), Color(0.32, 0.33, 0.34))
    _tag(home, kind.to_upper().replace("_", " ") + " / LOCAL RESIDENCE",
        Vector3(0, 5.8, 0))

func _make_homes() -> void:
    for i in range(HOME_IDS.size()):
        _home(i)

func _stall(shop: String, index: int) -> void:
    var x: float = STALL_X[index]
    var z: float = STALL_Z[index]
    var stall := Node3D.new()
    stall.name = "PublicStall_" + shop
    stall.position = Vector3(x, 0.0, z)
    add_child(stall)
    var tint := Color(0.40, 0.61, 0.63) if index == 0 else (
        Color(0.72, 0.46, 0.38) if index == 1 else Color(0.48, 0.54, 0.43))
    _part(stall, "PhysicalTradeCounter", Vector3(0, 1.04, 0.60),
        Vector3(3.7, 0.86, 1.08), Color(0.47, 0.38, 0.29), true)
    _part(stall, "MarketCounterStock", Vector3(0, 1.59, 0.64),
        Vector3(1.8, 0.19, 0.61), tint)
    _part(stall, "MerchantMarketAwning", Vector3(0, 3.14, 0),
        Vector3(6.8, 0.20, 5.8), tint)
    for side in [-1.0, 1.0]:
        _part(stall, "WoodenAwningPost", Vector3(side * 2.8, 1.86, 2.2),
            Vector3(0.21, 2.60, 0.21), Color(0.44, 0.37, 0.25))
        _part(stall, "AwningRearPost", Vector3(side * 2.8, 1.86, -2.2),
            Vector3(0.21, 2.60, 0.21), Color(0.44, 0.37, 0.25))
    _part(stall, "TradeInventoryCrate", Vector3(-2.4, 0.88, -1.3),
        Vector3(1.3, 0.68, 1.2), Color(0.55, 0.44, 0.32), true)
    _part(stall, "TradeDisplayShelf", Vector3(2.1, 1.15, -1.4),
        Vector3(1.1, 1.22, 1.2), Color(0.46, 0.38, 0.29), true)
    _tag(stall, Rules.title_for(shop).to_upper(), Vector3(0, 3.93, 0))
    var marker := Node3D.new()
    marker.name = "MarketInteractionPoint"
    marker.position = Vector3(0, 0.62, 3.2)
    stall.add_child(marker)
    hub.call("_add_location", "market_v062_" + shop, Rules.title_for(shop), marker.global_position, marker)
    var worker := Node3D.new()
    worker.name = "MarketVendor_" + shop
    worker.position = Vector3(0, 0.0, -1.25)
    stall.add_child(worker)
    _part(worker, "VendorTorso", Vector3(0, 1.18, 0),
        Vector3(0.61, 0.89, 0.35), tint)
    _part(worker, "VendorHead", Vector3(0, 1.94, 0),
        Vector3(0.42, 0.44, 0.38), Color(0.59, 0.46, 0.34))
    for side in [-1.0, 1.0]:
        _part(worker, "VendorLeg", Vector3(side * 0.17, 0.43, 0),
            Vector3(0.18, 0.76, 0.26), Color(0.31, 0.33, 0.37))
        _part(worker, "VendorArm", Vector3(side * 0.36, 1.2, 0),
            Vector3(0.16, 0.7, 0.24), tint)
    vendors[shop] = worker

func _make_market() -> void:
    for i in range(Rules.IDS.size()):
        _stall(Rules.IDS[i], i)
    _tag(self, "PUBLIC MARKET / DAILY STOCK / RING II / GAME ONLY",
        Vector3(0.0, 5.7, 268.0))

func _make_panel() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "MarketCanvasV062"
    canvas.layer = 20
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
    style.bg_color = Color(0.055, 0.080, 0.12, 0.98)
    style.border_color = Color(0.63, 0.58, 0.42)
    style.set_border_width_all(2)
    style.set_corner_radius_all(10)
    panel.add_theme_stylebox_override("panel", style)
    root.add_child(panel)
    var margins := MarginContainer.new()
    margins.add_theme_constant_override("margin_left", 13)
    margins.add_theme_constant_override("margin_right", 13)
    margins.add_theme_constant_override("margin_top", 12)
    margins.add_theme_constant_override("margin_bottom", 12)
    panel.add_child(margins)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 9)
    margins.add_child(column)
    title_label = Label.new()
    title_label.add_theme_font_size_override("font_size", 24)
    column.add_child(title_label)
    details = Label.new()
    details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(details)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(scroll)
    choices = VBoxContainer.new()
    choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    choices.add_theme_constant_override("separation", 9)
    scroll.add_child(choices)
    feedback = Label.new()
    feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(feedback)
    var close := Button.new()
    close.text = "RETURN TO THE PUBLIC MARKET"
    close.custom_minimum_size.y = 52
    close.pressed.connect(_close)
    column.add_child(close)

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _day() -> int:
    return maxi(1, int(floor(float(hub.get("world_minutes")) / 1440.0)) + 1)

func _social() -> Dictionary:
    var profile: Dictionary = codex.get("profile")
    return Rules.sanitize_social(profile.get("market_v062", {}))

func _community() -> int:
    var profile: Dictionary = codex.get("profile")
    return Residential.total_community_trust(profile.get("residential_v060", {}))

func _workshop_trust() -> int:
    var profile: Dictionary = codex.get("profile")
    var work: Dictionary = profile.get("workshops_v061", {})
    return clampi(int(work.get("worker_trust", 0)), -12, 12)

func _quote(shop: String) -> int:
    return Rules.price(shop, _day(), _social(), _community(), _workshop_trust())

func _stock() -> Dictionary:
    return Rules.sanitize_stock(hub.get("market_stock_v062"))

func _button(label: String, action: String, enabled: bool) -> void:
    var control := Button.new()
    control.text = label
    control.custom_minimum_size.y = 51
    control.disabled = not enabled
    control.pressed.connect(_choose.bind(action))
    choices.add_child(control)

func interact(id: String) -> void:
    if not initialized or not id.begins_with("market_v062_"):
        return
    if bool(codex.get("save_blocked")):
        hub.call("_announce", "The Personal Codex isn't available; trading paused for record safety.")
        return
    selected_shop = id.trim_prefix("market_v062_")
    if not Rules.IDS.has(selected_shop):
        return
    feedback.text = ""
    _refresh()
    panel.show()

func _refresh() -> void:
    for item in choices.get_children():
        choices.remove_child(item)
        item.queue_free()
    var shop: String = selected_shop
    var open: bool = Rules.is_open(float(hub.get("world_minutes")))
    var count: int = Rules.remaining_stock(shop, _day(), _stock())
    var sell_quote: int = Rules.sell_price(shop, _day(), _social(), _community(), _workshop_trust())
    var item: String = Rules.item_for(shop)
    var available: int = int(hub.get("inventory").get(item, 0))
    title_label.text = "MAGNARA / " + Rules.title_for(shop).to_upper()
    details.text = "%s\n%s\nDay %d / %s / public quote %d Tola\nAvailable %d / Your pack %d / Buyback %d Tola\nYour money: %d Tola" % [
        Rules.vendor_response(_social(), shop),
        "OPEN 08:00–18:00" if open else "CLOSED 18:00–08:00",
        _day(), item, _quote(shop), count, available, sell_quote, GameState.tola]
    _button("BUY 1 " + item + " / %d TOLA" % _quote(shop), "buy", open and count > 0 and GameState.tola >= _quote(shop))
    _button("SELL 1 " + item + " / %d TOLA" % sell_quote, "sell", open and available > 0)
    var can_choose: bool = open and Rules.can_socialize(_social(), shop, _day())
    _button("LISTEN TO THE MERCHANT / +1 RAPPORT", "social:listen", can_choose)
    _button("HELP WITH TODAY'S DELIVERIES / +2 RAPPORT", "social:assist", can_choose)
    _button("PRESSURE THE MERCHANT / -2 RAPPORT", "social:pressure", can_choose)

func _save_social(next: Dictionary) -> bool:
    if bool(codex.get("save_blocked")):
        return false
    var original: Dictionary = codex.get("profile")
    var updated: Dictionary = original.duplicate(true)
    updated["market_v062"] = Rules.sanitize_social(next)
    codex.set("profile", updated)
    codex.call("_save_profile")
    var disk := FileAccess.open("user://seeker_profile_v1.json", FileAccess.READ)
    if disk == null:
        codex.set("profile", original)
        return false
    var stored: Variant = JSON.parse_string(disk.get_as_text())
    disk.close()
    var good: bool = typeof(stored) == TYPE_DICTIONARY and Rules.sanitize_social(stored.get("market_v062", {})) == Rules.sanitize_social(next)
    if not good:
        codex.set("profile", original)
    return good

func _trade(mode: String) -> void:
    if not Rules.is_open(float(hub.get("world_minutes"))):
        feedback.text = "The stall is closed. The day market has regular hours."
        return
    var shop: String = selected_shop
    var item: String = Rules.item_for(shop)
    var price: int = _quote(shop) if mode == "buy" else Rules.sell_price(shop, _day(), _social(), _community(), _workshop_trust())
    var old_inventory: Dictionary = hub.get("inventory").duplicate(true)
    var old_ledger: Dictionary = _stock()
    var previous_cash: int = GameState.tola
    var next_inventory: Dictionary = old_inventory.duplicate(true)
    var next_stock: Dictionary = old_ledger.duplicate(true)
    if mode == "buy":
        if Rules.remaining_stock(shop, _day(), old_ledger) < 1 or GameState.tola < price:
            feedback.text = "There is insufficient supply or money for this purchase."
            return
        next_stock = Rules.record_purchase(old_ledger, shop, _day())
        if next_stock.is_empty() or not GameState.spend_tola(price):
            feedback.text = "Purchase rejected; your money is unchanged."
            return
        next_inventory[item] = int(next_inventory.get(item, 0)) + 1
    elif mode == "sell":
        if int(next_inventory.get(item, 0)) < 1:
            feedback.text = "You do not possess that item."
            return
        next_inventory[item] = int(next_inventory.get(item, 0)) - 1
        GameState.earn_tola(price)
    else:
        return
    # Money, bought stock and actual inventory are all saved in ONE hub
    # file; the social Codex file is deliberately not part of this trade.
    hub.set("inventory", next_inventory)
    hub.set("market_stock_v062", next_stock)
    hub.call("_save_game")
    var disk := FileAccess.open("user://margerina_v033.json", FileAccess.READ)
    var good: bool = false
    if disk != null:
        var raw: Variant = JSON.parse_string(disk.get_as_text())
        disk.close()
        good = typeof(raw) == TYPE_DICTIONARY and int(raw.get("tola", -1)) == GameState.tola and raw.get("inventory", {}) == next_inventory and Rules.sanitize_stock(raw.get("market_stock_v062", {})) == next_stock
    if not good:
        GameState.tola = previous_cash
        hub.set("inventory", old_inventory)
        hub.set("market_stock_v062", old_ledger)
        feedback.text = "The trade could not be verified in storage; local changes were reversed."
        _refresh()
        return
    feedback.text = "%s 1 %s for %d Tola. Your bag and coin are saved together." % [
        "Bought" if mode == "buy" else "Sold", item, price]
    _refresh()

func _choose(key: String) -> void:
    if key == "buy" or key == "sell":
        _trade(key)
        return
    if key.begins_with("social:"):
        if not Rules.is_open(float(hub.get("world_minutes"))):
            feedback.text = "The merchant has gone home for the day."
            return
        var action: String = key.trim_prefix("social:")
        var next: Dictionary = Rules.apply_social(_social(), selected_shop, action, _day())
        if next.is_empty() or not _save_social(next):
            feedback.text = "Today's social choice has already been made, or its record couldn't be saved."
            return
        codex.call("record_event", "v062:market:%s:day:%d" % [selected_shop, _day()],
            "merchant_relation", "Met a Ring Two public merchant",
            "%s / %s. Reputation now %d. Original game-only neighborhood." % [
                Rules.title_for(selected_shop), action, Rules.rapport(next, selected_shop)])
        feedback.text = "The vendor remembers your %s. Today's relationship choice is recorded." % action
        _refresh()

func _update_vendors() -> void:
    var active: bool = Rules.is_open(float(hub.get("world_minutes")))
    var minute: float = fposmod(float(hub.get("world_minutes")), 1440.0)
    for shop in Rules.IDS:
        if vendors.has(shop):
            var vendor: Node3D = vendors[shop]
            vendor.visible = active
            vendor.position.z = -1.25 + (sin(minute * 0.025 + float(Rules.IDS.find(shop))) * 0.18 if active else 0.0)

func _process(delta: float) -> void:
    tick += delta
    if tick >= 0.55:
        tick = 0.0
        _update_vendors()

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()
