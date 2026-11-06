extends Node3D
# Verifies the life-road nodes exist IN THE REAL MAIN GAME, not just a data test.
const GameScene = preload("res://scenes/main.tscn")

func _ready() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("V0.57 3D WORLD INTEGRATION FAILED: " + message)
    get_tree().call_deferred("quit", 1)

func _run() -> void:
    var main: Node3D = GameScene.instantiate() as Node3D
    add_child(main)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    var player: Node = main.get_node_or_null("Player")
    var hub: Node = main.get_node_or_null("HubManager")
    var codex: Node = main.get_node_or_null("PersonalCodex")
    var life: Node = main.get_node_or_null("YoungBloodLifeV057")
    if not is_instance_valid(player) or not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(life):
        _fail("missing old player/hub/codex or new life node")
        return
    if not bool(life.get("initialized")):
        _fail("life registrar did not initialize in the main world")
        return
    if get_tree().get_first_node_in_group("young_blood_life_v057") != life:
        _fail("life system not registered for TALK / USE")
        return
    var locations: Array = hub.get("locations")
    var found: Dictionary = {}
    for item in locations:
        if str(item.get("id", "")).begins_with("yb_v057_"):
            var node: Node = item.get("node")
            if not is_instance_valid(node) or not node is Node3D:
                _fail("3D life-road interaction has no physical marker")
                return
            found[str(item["id"])] = node
    for id in ["yb_v057_registrar", "yb_v057_pickup", "yb_v057_delivery"]:
        if not found.has(id):
            _fail("missing physical place: " + id)
            return
        var part: Node = (found[id] as Node3D).find_child("StoneBase", true, false)
        if part == null or part.find_child("LifeRoadStaticCollider", true, false) == null:
            _fail("life-route marker is only a UI label: " + id)
            return
    if bool(life.call("is_open")):
        _fail("in-world life panel should start closed")
        return
    life.call("interact", "yb_v057_registrar")
    if not bool(life.call("is_open")) or not bool(hub.call("_any_panel_open")):
        _fail("registrar interaction does not open modal and block movement")
        return
    life.call("_close_panel")
    if bool(life.call("is_open")):
        _fail("cannot close life-path panel")
        return
    main.queue_free()
    print("V0.57 PHYSICAL LIFE REGISTRAR AND 3D ROUTE INTEGRATION PASS")
    get_tree().call_deferred("quit", 0)
