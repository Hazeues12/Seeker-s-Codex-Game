extends Node3D

const Main = preload("res://scenes/main.tscn")
const Trade = preload("res://world/magnara_commons_cart_v081.gd")
const Integrity = preload("res://systems/game_save_integrity_v063.gd")
const Geo = preload("res://systems/known_world_geometry_v054.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("V0.81 COMMONS TRADE: " + reason)
    get_tree().call_deferred("quit", 1)

func _stream(game: Node3D, visuals: Node3D) -> void:
    for tick in range(5):
        game.get_node("MagnaraGeographyV054").call("_refresh_cells")
        game.get_node("MagnaraSevenRingFoundationV074").call("_refresh_near")
    visuals.call("_refresh_tiles")

func _button(root: Node, prefix: String) -> Button:
    for node in root.get_children():
        if node is Button and node.text.begins_with(prefix):
            return node
    return null

func _run() -> void:
    var game := Main.instantiate() as Node3D
    add_child(game)
    for frame in range(8):
        await get_tree().process_frame
    var hero := game.get_node("Player") as CharacterBody3D
    var hub := game.get_node("HubManager")
    var visuals := game.get_node("MagnaraPublishedRingVisualsV076") as Node3D
    var trade := visuals.get_node("CommonsCartV081") as Trade
    var talk := _button(hub.get("ui"), "TALK / USE")
    var start_tola: int = GameState.tola
    if talk == null or Geo.ring_for_position(trade.court) != 3 or Geo.ring_for_position(Trade.SUPPLIER) != 2:
        _fail("public supplier or cart is in the wrong district")
        return

    hero.global_position = Trade.SUPPLIER
    _stream(game, visuals)
    talk.pressed.emit()
    var pickup := _button(trade.entries, "COLLECT BREAD CRATE") if trade.is_open() else null
    if pickup == null or pickup.disabled:
        _fail("Talk / Use did not open the Ring II pickup")
        return
    pickup.pressed.emit()
    trade.panel.hide()
    hub.set("commons_trade_v081", Trade.clean({}))
    hub.call("_load_game", false)
    if not hub.get("commons_trade_v081")["carrying"] or trade.delivery_hint().is_empty() or GameState.tola != start_tola:
        _fail("pickup did not survive reload or paid before delivery")
        return

    hero.global_position = trade.court + Vector3(-4.4, 0.73, -2.5)
    hub.set("world_minutes", 598.0)
    _stream(game, visuals)
    trade._process(0.016)
    if not trade.vendor.visible:
        _fail("vendor did not walk toward the cart before opening")
        return
    var arriving: Vector3 = trade.vendor.position
    hub.set("world_minutes", 600.0)
    trade._process(0.016)
    if trade.vendor.position.is_equal_approx(arriving):
        _fail("vendor did not reach the counter")
        return
    hub.set("world_minutes", 1300.0)
    trade._process(0.016)
    talk.pressed.emit()
    var closed_buy := _button(trade.entries, "BUY FORGE BREAD")
    if trade.vendor.visible or closed_buy == null or not closed_buy.disabled:
        _fail("after-hours cart allowed a purchase")
        return
    trade.panel.hide()
    hub.set("world_minutes", 720.0)
    talk.pressed.emit()
    var buy := _button(trade.entries, "BUY FORGE BREAD")
    if buy == null or buy.disabled:
        _fail("cart did not open for business")
        return
    buy.pressed.emit()
    if GameState.tola != start_tola - Trade.PRICE or hub.get("inventory").get(Trade.FOOD, 0) != 1 \
            or hub.get("commons_trade_v081")["stock"] != 3:
        _fail("purchase did not exchange Tola, bag contents and stock together")
        return
    var deliver := _button(trade.entries, "DELIVER CRATE")
    if deliver == null or deliver.disabled:
        _fail("cart did not accept a valid restock delivery")
        return
    var pending := ProjectSettings.globalize_path(Integrity.PENDING)
    if DirAccess.make_dir_absolute(pending) != OK:
        _fail("could not simulate unavailable storage")
        return
    deliver.pressed.emit()
    DirAccess.remove_absolute(pending)
    if GameState.tola != start_tola - Trade.PRICE or not hub.get("commons_trade_v081")["carrying"] \
            or hub.get("commons_trade_v081")["stock"] != 3:
        _fail("failed save did not roll back stock, crate and payout")
        return
    deliver = _button(trade.entries, "DELIVER CRATE")
    deliver.pressed.emit()
    trade._transact("deliver")
    trade.panel.hide()
    hub.set("commons_trade_v081", Trade.clean({}))
    hub.call("_load_game", false)
    var state: Dictionary = hub.get("commons_trade_v081")
    if state["carrying"] or state["stock"] != 7 or state["paid_day"] != 0 \
            or GameState.tola != start_tola - Trade.PRICE + Trade.PAY:
        _fail("restock or payout was duplicated or lost after reload")
        return

    hub.set("stamina", 50.0)
    hub.call("_open_bag", false)
    var eat := _button(hub.get("bag_list"), "EAT FORGE BREAD")
    if eat == null:
        _fail("purchased food was not usable through the bag")
        return
    eat.pressed.emit()
    if not is_equal_approx(float(hub.get("stamina")), 65.0) or hub.get("inventory").get(Trade.FOOD, 0) != 0:
        _fail("eating did not consume one portion and restore stamina")
        return

    hero.global_position = Trade.SUPPLIER
    _stream(game, visuals)
    talk.pressed.emit()
    if not _button(trade.entries, "COLLECT BREAD CRATE").disabled:
        _fail("same-day delivery can be repeated")
        return
    trade.panel.hide()
    hub.set("world_minutes", 1440.0 + 720.0)
    talk.pressed.emit()
    if _button(trade.entries, "COLLECT BREAD CRATE").disabled:
        _fail("next-day delivery did not reopen")
        return
    print("V0.81 COMMONS VENDOR FOOD PURCHASE STAMINA DELIVERY AND RELOAD PASS")
    game.queue_free()
    get_tree().call_deferred("quit", 0)
