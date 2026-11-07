extends Node3D

const Main = preload("res://scenes/main.tscn")
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const Commons = preload("res://world/magnara_commons_life_v080.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("V0.80 COMMONS LIFE FAILED: " + reason)
    get_tree().call_deferred("quit", 1)

func _stream(game: Node3D, visuals: Node3D) -> void:
    for tick in range(5):
        game.get_node("MagnaraGeographyV054").call("_refresh_cells")
        game.get_node("MagnaraSevenRingFoundationV074").call("_refresh_near")
    visuals.call("_refresh_tiles")

func _run() -> void:
    var game := Main.instantiate() as Node3D
    add_child(game)
    for frame in range(8):
        await get_tree().process_frame
    var player := game.get_node("Player") as CharacterBody3D
    var visuals := game.get_node("MagnaraPublishedRingVisualsV076") as Node3D
    var hub := game.get_node("HubManager")
    var codex := game.get_node("PersonalCodex")
    var commons := visuals.get_node("CommonsLifeV080") as Commons
    if commons.visible or commons.get_child_count() != 0:
        _fail("distant Commons actors were constructed at the Ring Two spawn")
        return

    player.global_position = Vector3(Geo.CITY_CENTER.x + 3560.0, 0.75, Geo.CITY_CENTER.y)
    hub.set("world_minutes", 479.0)
    _stream(game, visuals)
    var court := Vector3.ZERO
    var tiles: Dictionary = visuals.get("decorated")
    for tile in tiles.values():
        if not tile["court_centers"].is_empty():
            court = tile["root"].to_global(tile["court_centers"][0])
            break
    if court == Vector3.ZERO or Geo.ring_for_position(court) != 3:
        _fail("no suitable public courtyard streamed in Ring Three")
        return
    player.global_position = court + Vector3(0, 0.75, 5.5)
    _stream(game, visuals)
    if commons.visible:
        _fail("a gathering appeared before its schedule started")
        return

    hub.set("world_minutes", 480.0)
    visuals.call("_refresh_tiles")
    if not commons.visible or commons.picnic.visible or not commons.reading.visible:
        _fail("the morning reading did not appear at 08:00")
        return
    hub.set("world_minutes", 720.0)
    visuals.call("_refresh_tiles")
    if not commons.picnic.visible or commons.reading.visible or commons.family.size() != 3:
        _fail("midday should have a family picnic with three seated guests")
        return
    if commons.picnic.get_node_or_null("FoodBasket") == null:
        _fail("the picnic is missing its scene props")
        return

    hub.set("world_minutes", 18.75 * 60.0)
    visuals.call("_refresh_tiles")
    if not commons.picnic.visible or not commons.reading.visible:
        _fail("the evening reading and picnic do not overlap")
        return
    if not commons.get_nearest_interaction(player.global_position, 3.2).is_empty():
        _fail("the poet can be heard from outside interaction range")
        return

    # Reach the reading with the same stick and TALK / USE control as the game.
    var mobile := game.get_node("MobileUI/MobileControls")
    mobile.set("movement", Vector2.UP)
    for tick in range(88):
        await get_tree().physics_frame
    mobile.set("movement", Vector2.ZERO)
    var nearby: Dictionary = hub.call("_nearest_location")
    if nearby.get("id", "") != Commons.READING_ID:
        _fail("walking into the square did not expose the poet through the hub: " + str(player.global_position))
        return
    var talk: Button
    for control in hub.get("ui").get_children():
        if control is Button and control.text == "TALK / USE":
            talk = control
            break
    if talk == null:
        _fail("no normal TALK / USE button is available")
        return

    var purse: int = GameState.tola
    talk.pressed.emit()
    talk.pressed.emit()
    if not str(hub.get("last_notice")).contains(Commons.VERSES[0]) or GameState.tola != purse:
        _fail("listening did not show the original verse or changed the purse")
        return
    codex.call("_load_profile")
    var profile: Dictionary = codex.get("profile")
    var readings: Array = (profile.get("history", []) as Array).filter(
        func(entry: Dictionary) -> bool: return entry.get("kind") == "commons_reading")
    if readings.size() != 1 or readings[0]["place"] != Commons.PLACE \
            or readings[0]["canon_status"] != "game_only" or readings[0]["detail"] != Commons.VERSES[0]:
        _fail("the verse did not persist once with its Commons location and game-only status")
        return

    var saved_position: Vector3 = player.global_position
    var saved_minutes: float = float(hub.get("world_minutes"))
    if not hub.call("_save_game"):
        _fail("could not save while visiting a gathering")
        return
    hub.set("world_minutes", 479.0)
    player.global_position = Vector3.ZERO
    _stream(game, visuals)
    hub.call("_load_game", false)
    _stream(game, visuals)
    if not player.global_position.is_equal_approx(saved_position) \
            or not is_equal_approx(float(hub.get("world_minutes")), saved_minutes) \
            or not commons.visible or not commons.reading.visible:
        _fail("loading did not restore the square and its active evening reading")
        return

    hub.set("world_minutes", 1440.0 + 540.0)
    visuals.call("_refresh_tiles")
    talk.pressed.emit()
    if not str(hub.get("last_notice")).contains(Commons.VERSES[1]):
        _fail("returning the next day did not reveal the next verse")
        return

    hub.set("world_minutes", 1440.0 + 1290.0)
    if not commons.get_nearest_interaction(player.global_position, 3.2).is_empty():
        _fail("a reading stayed interactable after closing but before the next refresh")
        return
    visuals.call("_refresh_tiles")
    if commons.visible or not commons.get_nearest_interaction(player.global_position, 3.2).is_empty():
        _fail("the reading remained active at closing time")
        return
    hub.set("world_minutes", 1440.0 + 540.0)
    visuals.call("_refresh_tiles")
    player.global_position = Vector3(0, 0.75, 0)
    _stream(game, visuals)
    if commons.visible or commons.is_processing() or not commons.active_tile.is_empty():
        _fail("gathering and animation stayed active after leaving the Commons")
        return
    print("V0.80 COMMONS PICNIC CLOCK POETRY MOBILE INTERACTION AND PERSISTENT CODEX PASS")
    game.queue_free()
    get_tree().call_deferred("quit", 0)
