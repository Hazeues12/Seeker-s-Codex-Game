extends Node3D
# This test instantiates the actual Godot 3D world, never a UI-only mock.
const GameScene = preload("res://scenes/main.tscn")
const RigScript = preload("res://characters/procedural_seeker.gd")
const RoadRules = preload("res://systems/young_blood_life_rules_v057.gd")
const OriginRules = preload("res://systems/young_blood_origins_v058.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("V0.58 IN-GAME ORIGIN INTEGRATION FAILED: " + message)
    get_tree().call_deferred("quit", 1)

func _run() -> void:
    var world: Node3D = GameScene.instantiate() as Node3D
    add_child(world)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    var player: Node = world.get_node_or_null("Player")
    var hub: Node = world.get_node_or_null("HubManager")
    var codex: Node = world.get_node_or_null("PersonalCodex")
    var life: Node = world.get_node_or_null("YoungBloodLifeV057")
    if not is_instance_valid(player) or not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(life):
        _fail("V0.57 3D world or life registrar missing")
        return
    if not bool(life.get("initialized")):
        _fail("in-world life registrar failed to initialize")
        return
    for ui in ["background_option", "temperament_option", "trait_option", "origins_confirm"]:
        if not is_instance_valid(life.get(ui)):
            _fail("new in-world creator UI is missing " + ui)
            return
    var burdens: Array = life.get("origin_checks")
    var perks: Array = life.get("perk_checks")
    if burdens.size() != 4 or perks.size() != 5:
        _fail("origin trade-offs missing from mobile creator")
        return
    # Test national outfits for every supported Young Blood origin in a fresh
    # model so old scenes and appearance choices stay untouched.
    for nation in RoadRules.NATIONS:
        var model: Node3D = RigScript.new()
        add_child(model)
        model.call("configure", "seeker")
        model.call("apply_national_outfit", nation)
        var costume: Node = model.find_child("NationalClothing", true, false)
        if costume == null or costume.find_children("*", "MeshInstance3D", true, false).size() < 2:
            _fail("no unique physical outfit accessories for " + nation)
            return
        if str(model.get("national_nation")) != nation:
            _fail("stored national costume did not match " + nation)
            return
        model.queue_free()
        await get_tree().process_frame
    if not life.call("_current_origin").is_empty():
        _fail("origin cannot start pre-registered in clean CI environment")
        return
    if str(GameState.seeker_rank) != "Stray":
        _fail("clean starting rank changed without an official trial")
        return
    # Walk-in registrar's original road stays as precondition for origin
    # selection, avoiding secret powers or unofficial rank awards.
    life.call("_choose_path", RoadRules.ROAD_TRADE)
    var selected_road: Dictionary = life.call("_current_life")
    if str(selected_road.get("road", "")) != RoadRules.ROAD_TRADE:
        _fail("new civilian life road could not be registered")
        return
    if bool(life.call("may_accept_seeker_contracts")):
        _fail("civilian was issued an unauthorized Seeker license")
        return
    var avatar: Node = player.get_node_or_null("AnimatedSeeker")
    if not is_instance_valid(avatar) or str(avatar.get("national_nation")) != "Janoah":
        _fail("3D player's nation outfit not applied when selecting road")
        return
    var backgrounds: OptionButton = life.get("background_option")
    var temperaments: OptionButton = life.get("temperament_option")
    var traits: OptionButton = life.get("trait_option")
    backgrounds.select(2) # dockworker household
    temperaments.select(1) # bold
    traits.select(5) # reliable worker
    (burdens[0] as CheckBox).button_pressed = true # debt
    (burdens[1] as CheckBox).button_pressed = true # restless sleep
    (perks[0] as CheckBox).button_pressed = true # roadwise
    (perks[2] as CheckBox).button_pressed = true # market familiar
    (perks[4] as CheckBox).button_pressed = true # courier training
    life.call("_refresh_origin_controls")
    var seal_button: Button = life.get("origins_confirm")
    if seal_button.disabled:
        _fail("earned origin perks were rejected by the actual creator")
        return
    life.call("_register_origin")
    var created: Dictionary = life.call("_current_origin")
    if str(created.get("background", "")) != "dockworker_household":
        _fail("origin wasn't recorded in actual Personal Codex")
        return
    if int(created.get("debt_tola", -1)) != 40:
        _fail("game did not assign a real debt burden")
        return
    var modifier: Dictionary = life.call("get_origin_effects")
    if int(modifier.get("tonic_price", 0)) != 10 or float(modifier.get("sprint_mult", 1.0)) <= 1.0:
        _fail("saved origin effects are not exposed to live combat/economy")
        return
    if bool(hub.call("_any_panel_open")):
        _fail("creator incorrectly opened itself without a physical interaction")
        return
    life.call("interact", "yb_v057_registrar")
    if not bool(life.call("is_open")) or not bool(hub.call("_any_panel_open")):
        _fail("actual registrar and movement modal no longer work")
        return
    life.call("_close_panel")
    var old_coins: int = GameState.tola
    life.call("_accept_shift")
    life.call("_pickup")
    life.call("_deliver")
    var completed: Dictionary = life.call("_current_life")
    var reduced: Dictionary = life.call("_current_origin")
    if int(completed.get("work", {}).get("completed", -1)) != 1:
        _fail("3D courier shift did not finalize")
        return
    if int(reduced.get("debt_tola", -1)) != 36 or GameState.tola - old_coins != 7:
        _fail("earned coin / debt withholding not applied in actual 3D gameplay")
        return
    life.call("_deliver")
    if GameState.tola - old_coins != 7:
        _fail("replayed courier delivery double-paid")
        return
    var disk := FileAccess.open("user://seeker_profile_v1.json", FileAccess.READ)
    if disk == null:
        _fail("saved profile missing from disk")
        return
    var stored: Variant = JSON.parse_string(disk.get_as_text())
    disk.close()
    if typeof(stored) != TYPE_DICTIONARY or
        OriginRules.sanitize(stored.get("origin_v058", {})) != reduced:
        _fail("origin consequences did not survive real save")
        return
    print("V0.58 PHYSICAL CREATOR CLOTHING AND CIVILIAN CONSEQUENCES PASS")
    world.queue_free()
    get_tree().call_deferred("quit", 0)
