extends Node3D
# Real main-scene integration: authored street, functional workshop interiors,
# 3-step employment, persistent wage receipt and legacy world collision safety.
const World = preload("res://scenes/main.tscn")
const Rules = preload("res://systems/magnara_workshop_rules_v061.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(why: String) -> void:
    push_error("V0.61 FULL WORLD FAILED: " + why)
    get_tree().call_deferred("quit", 1)

func _visit(hub: Node, player: CharacterBody3D, location_id: String, expected_station: String) -> bool:
    var places: Array = hub.get("locations")
    var target: Dictionary = {}
    for item in places:
        if str(item.get("id", "")) == location_id:
            target = item
            break
    if target.is_empty():
        return false
    var place: Vector3 = target["position"]
    player.global_position = place + Vector3(0, 0.47, 0)
    var nearest: Dictionary = hub.call("_nearest_location")
    if str(nearest.get("id", "")) != location_id:
        return false
    hub.call("_interact")
    var work: Node = get_tree().get_first_node_in_group("magnara_workshops_v061")
    return bool(work.call("is_open")) and str(work.get("current_station")) == expected_station

func _run() -> void:
    var world: Node3D = World.instantiate() as Node3D
    add_child(world)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    var work: Node = world.get_node_or_null("MagnaraWorkshopsV061")
    var hub: Node = world.get_node_or_null("HubManager")
    var codex: Node = world.get_node_or_null("PersonalCodex")
    var player: CharacterBody3D = world.get_node_or_null("Player") as CharacterBody3D
    var life: Node = world.get_node_or_null("YoungBloodLifeV057")
    var homes: Node = world.get_node_or_null("MagnaraResidentialV060")
    var geo: Node = world.get_node_or_null("MagnaraGeographyV054")
    if not is_instance_valid(work) or not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(player) or not is_instance_valid(life) or not is_instance_valid(homes) or not is_instance_valid(geo):
        _fail("workshop district replaced an existing world system")
        return
    if not bool(work.get("initialized")):
        _fail("working quarter didn't initialize inside the real world")
        return
    var manifest: Dictionary = work.call("get_manifest")
    if str(manifest.get("status", "")) != "game_only" or int(manifest.get("physical_workshops", 0)) != 3:
        _fail("three enterable local workshops are not documented")
        return
    if not bool(manifest.get("canon_ring_v_unchanged", false)) or bool(manifest.get("trains_operational", true)):
        _fail("v061 relocated a canon shop or claimed unimplemented rail service")
        return
    var locations: Dictionary = {}
    for spot in hub.get("locations"):
        var id: String = str(spot.get("id", ""))
        if id.begins_with("work_v061_") or id.begins_with("npc_v061_"):
            locations[id] = spot
    if locations.size() != 8:
        _fail("expected board, depot, three jobs and three worker talks in TALK / USE; got " + str(locations.size()))
        return
    var road: Node = work.find_child("NorthWorkingStreet", true, false)
    var crossing: Node = work.find_child("InterQuarterConnectorAvenue", true, false)
    var join: Node = work.find_child("ResidentialRoadNorthernJoin", true, false)
    if road == null or crossing == null or join == null:
        _fail("street doesn't physically link older city and living homes")
        return
    for path in [road, crossing, join]:
        if path.find_child("WorkingDistrictCollision", true, false) == null:
            _fail("street or cross-avenue has no collision surface")
            return
    for id in Rules.JOBS:
        var workshop: Node3D = work.get_node_or_null("OpenWorkshop_" + id) as Node3D
        if not is_instance_valid(workshop):
            _fail("missing physical open workshop " + id)
            return
        for child in ["InteriorStoneFloor", "DoorwayWing", "DoorLintel", "WorkshopWorkBench", "WorkshopRoofDeck"]:
            var part: Node = workshop.find_child(child, true, false)
            if part == null or part.find_child("WorkingDistrictCollision", true, false) == null:
                _fail("fake workshop furniture/doorway/floor: " + id + "/" + child)
                return
        var spur: Node = work.find_child("WorkshopDoorPath_" + id, true, false)
        if spur == null or spur.find_child("WorkingDistrictCollision", true, false) == null:
            _fail("the building entrance is disconnected " + id)
            return
        var actual_worker: Node = work.find_child("WorkshopWorker_" + id, true, false)
        if actual_worker == null or actual_worker.find_child("WorkmanTorso", true, false) == null:
            _fail("physical worker missing " + id)
            return
    var quarter_lantern: MeshInstance3D = work.find_child("WorkshopSafetySignal", true, false) as MeshInstance3D
    if not is_instance_valid(quarter_lantern):
        _fail("worker trust lacks a physical signal")
        return
    var tiles: Dictionary = geo.get("cells")
    var northern: Node3D = tiles.get("0:1") as Node3D
    if not is_instance_valid(northern):
        _fail("city's 1:1 geography isn't supplying northern street terrain")
        return
    if northern.find_child("ProvisionalUrbanMass*", true, false) != null:
        _fail("legacy massing generated solid buildings directly over the authored workshop or homes")
        return
    await get_tree().physics_frame
    var crossing_query := PhysicsRayQueryParameters3D.create(
        Vector3(0.0, 5.0, 207.0), Vector3(0.0, -2.0, 207.0))
    var crossing_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(crossing_query)
    if crossing_hit.is_empty():
        _fail("public cross avenue is visually painted and has no solid floor")
        return
    # Work can only be done by the original Seeker's Live a Trade road.
    if not _visit(hub, player, "work_v061_board", "board"):
        _fail("working offer board isn't accessible with TALK / USE")
        return
    if not (work.call("_state") as Dictionary)["active"].is_empty():
        _fail("legacy save shouldn't create an automatic paid shift")
        return
    work.call("_choose", "accept:forge_service")
    if not (work.call("_state") as Dictionary)["active"].is_empty():
        _fail("unregistered civilian was paid or offered a contract")
        return
    work.call("_close")
    life.call("_choose_path", "trade")
    if not bool(work.call("_civilian_eligible")):
        _fail("the existing live-a-trade creator isn't connected to workshops")
        return
    var initial_cash: int = GameState.tola
    if not _visit(hub, player, "work_v061_board", "board"):
        _fail("work board inaccessible after registration")
        return
    work.call("_choose", "accept:forge_service")
    if str((work.call("_state") as Dictionary)["active"].get("stage", "")) != "accepted":
        _fail("physically accepting a job didn't save the labor contract")
        return
    work.call("_close")
    if not _visit(hub, player, "work_v061_depot", "depot"):
        _fail("freight material pickup is not physically accessible")
        return
    work.call("_choose", "collect")
    if str((work.call("_state") as Dictionary)["active"].get("stage", "")) != "carrying":
        _fail("physical depot did not issue assigned materials")
        return
    work.call("_close")
    if not _visit(hub, player, "work_v061_finish_forge_service", "finish_forge_service"):
        _fail("the forge's open workbench cannot be interacted with")
        return
    work.call("_choose", "careful")
    if int((work.call("_state") as Dictionary).get("completed", 0)) != 0:
        _fail("invalid action bypassed workbench outcomes")
        return
    work.call("_choose", "finish:careful")
    var after: Dictionary = work.call("_state")
    if int(after.get("completed", 0)) != 1 or int(after.get("worker_trust", 0)) != 2:
        _fail("careful 3-stage work didn't leave a saved ethical consequence")
        return
    if GameState.tola - initial_cash != 14:
        _fail("civilian daily wage differs from the recorded base pay")
        return
    work.call("_choose", "finish:careful")
    if GameState.tola - initial_cash != 14:
        _fail("same-day replay grants duplicate wages")
        return
    work.call("_close")
    # Two further in-game days of rushed work lower trust enough to change
    # the visible safety signal without requiring a live iPhone input test.
    for day in [2, 3]:
        hub.set("world_minutes", float(day - 1) * 1440.0 + 480.0)
        var next_job: String = Rules.JOBS[day - 1]
        if not _visit(hub, player, "work_v061_board", "board"):
            _fail("work offers unavailable on a new in-game day")
            return
        work.call("_choose", "accept:" + next_job)
        work.call("_close")
        if not _visit(hub, player, "work_v061_depot", "depot"):
            _fail("freight pickup vanished during the following day")
            return
        work.call("_choose", "collect")
        work.call("_close")
        if not _visit(hub, player, "work_v061_finish_" + next_job, "finish_" + next_job):
            _fail("next shift's correct workplace was inaccessible")
            return
        work.call("_choose", "finish:rush")
        work.call("_close")
    var shifted: Dictionary = work.call("_state")
    if int(shifted.get("completed", 0)) != 3 or int(shifted.get("worker_trust", 99)) != -4:
        _fail("workers forgot the consequences of dangerous rushed shifts")
        return
    var safety_material: StandardMaterial3D = quarter_lantern.material_override as StandardMaterial3D
    if safety_material == null or safety_material.albedo_color.r <= safety_material.albedo_color.g:
        _fail("worker safety signal isn't changing to red after harmful decisions")
        return
    var disk := FileAccess.open("user://seeker_profile_v1.json", FileAccess.READ)
    if disk == null:
        _fail("real Personal Codex file cannot be read")
        return
    var raw: Variant = JSON.parse_string(disk.get_as_text())
    disk.close()
    if typeof(raw) != TYPE_DICTIONARY:
        _fail("stored work profile invalid")
        return
    if Rules.sanitize(raw.get("workshops_v061", {})) != shifted:
        _fail("workshop choices or receipts didn't survive actual disk storage")
        return
    if not world.get_node_or_null("MagnaraCityV052") or not world.get_node_or_null("MagnaraResidentialV060"):
        _fail("the new working street replaced prior city streets or homes")
        return
    print("V0.61 PHYSICAL WORKING STREETS SAFE EMPLOYMENT AND PERSISTENT WAGES PASS")
    world.queue_free()
    get_tree().call_deferred("quit", 0)
