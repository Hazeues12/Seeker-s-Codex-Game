extends Node3D
const World = preload("res://scenes/main.tscn")
const Rules = preload("res://systems/residential_life_v060.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(why: String) -> void:
    push_error("V0.60 PHYSICAL NEIGHBORHOOD FAILED: " + why)
    get_tree().call_deferred("quit", 1)

func _run() -> void:
    var main: Node3D = World.instantiate() as Node3D
    add_child(main)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    var homes: Node = main.get_node_or_null("MagnaraResidentialV060")
    var hub: Node = main.get_node_or_null("HubManager")
    var codex: Node = main.get_node_or_null("PersonalCodex")
    var player: CharacterBody3D = main.get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(homes) or not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(player):
        _fail("base Margerina scene lost its player/hub/Codex/neighborhood")
        return
    if not bool(homes.get("initialized")):
        _fail("household district didn't load in the running game")
        return
    var manifest: Dictionary = homes.call("get_manifest")
    if int(manifest.get("physical_open_houses", -1)) != 3 or int(manifest.get("household_count", -1)) != 3:
        _fail("physical household district manifest incorrect")
        return
    var found_hub: Dictionary = {}
    for item in hub.get("locations"):
        var id: String = str(item.get("id", ""))
        if id.begins_with("npc_v060_"):
            found_hub[id.trim_prefix("npc_v060_")] = item.get("node")
    if found_hub.size() != 3:
        _fail("all residential NPCs are not registered in TALK / USE")
        return
    for id in Rules.IDS:
        var house: Node3D = homes.get_node_or_null("OpenHouse_" + id) as Node3D
        if not is_instance_valid(house):
            _fail("a game-only residence is missing " + id)
            return
        var real_floor: Node = house.find_child("RealInteriorFloor", true, false)
        var doorway: Node = house.find_child("DoorLintel", true, false)
        var home_spur: Node = homes.find_child("HomeSpur_" + id, true, false)
        if real_floor == null or real_floor.find_child("ResidentialCollision", true, false) == null or doorway == null:
            _fail("residence is only an unenterable facade " + id)
            return
        if home_spur == null or home_spur.find_child("ResidentialCollision", true, false) == null:
            _fail("house does not connect to the pedestrian street " + id)
            return
        var npc: Node3D = found_hub[id] as Node3D
        if not is_instance_valid(npc) or npc.find_child("ResidentBody", true, false) == null:
            _fail("resident has no real 3D character " + id)
            return
    var corridor: Node = homes.find_child("ResidentialStreetWalkable", true, false)
    if corridor == null or corridor.find_child("ResidentialCollision", true, false) == null:
        _fail("neighborhood walking street lacks collision")
        return
    var lantern: MeshInstance3D = homes.find_child("HouseholdTrustLantern", true, false) as MeshInstance3D
    if not is_instance_valid(lantern):
        _fail("neighborhood lacks a physical consequence lantern")
        return
    # We directly set the already-existing world clock to sample actual NPCs
    # at their morning, working-day and evening positions.
    for clock in [100.0, 700.0, 1150.0]:
        hub.set("world_minutes", clock)
        homes.call("_refresh_positions")
        for id in Rules.IDS:
            var npc_actual: Vector3 = homes.call("get_resident_position", id)
            var expected: Vector3 = Rules.position_at(id, clock)
            if npc_actual.distance_to(expected) > 0.01:
                _fail("visible resident did not move to scheduled place " + id)
                return
    hub.set("world_minutes", 700.0)
    homes.call("_refresh_positions")
    var first: String = Rules.IDS[0]
    var target: Vector3 = homes.call("get_resident_position", first)
    player.global_position = target + Vector3(0.0, 0.7, 0.0)
    var nearest: Dictionary = hub.call("_nearest_location")
    if str(nearest.get("id", "")) != "npc_v060_" + first:
        _fail("player cannot talk to the moving resident via existing TALK / USE")
        return
    hub.call("_interact")
    if not bool(homes.call("is_open")) or not bool(hub.call("_any_panel_open")):
        _fail("resident modal did not open or stop movement")
        return
    homes.call("_decide", "help")
    var record: Dictionary = homes.call("_state")
    if Rules.rapport(record, first) != 2:
        _fail("the real dialog decision did not update trust")
        return
    homes.call("_decide", "pressure")
    if Rules.rapport(homes.call("_state"), first) != 2:
        _fail("repeated same-day interaction can double-score trust")
        return
    homes.call("_close")
    if bool(homes.call("is_open")):
        _fail("resident panel cannot be closed")
        return
    for other in Rules.IDS.slice(1):
        homes.call("interact", "npc_v060_" + other)
        homes.call("_decide", "help")
        homes.call("_close")
    if Rules.total_community_trust(homes.call("_state")) != 6:
        _fail("helping three households did not build communal trust")
        return
    var positive_material: StandardMaterial3D = lantern.material_override as StandardMaterial3D
    if positive_material == null or positive_material.albedo_color.g <= positive_material.albedo_color.r:
        _fail("public lantern failed to reflect positive neighborhood trust")
        return
    # Move to another calendar day, then model consequences of misconduct.
    for day in range(2, 6):
        hub.set("world_minutes", float(day - 1) * 1440.0 + 700.0)
        for id in Rules.IDS:
            homes.call("interact", "npc_v060_" + id)
            homes.call("_decide", "pressure")
            homes.call("_close")
    if Rules.total_community_trust(homes.call("_state")) >= -3:
        _fail("repeated pressure does not damage community relations")
        return
    var negative_material: StandardMaterial3D = lantern.material_override as StandardMaterial3D
    if negative_material == null or negative_material.albedo_color.r <= negative_material.albedo_color.g:
        _fail("neighborhood's physical lantern fails to reflect misconduct")
        return
    var disk := FileAccess.open("user://seeker_profile_v1.json", FileAccess.READ)
    if disk == null:
        _fail("household record missing from real Personal Codex storage")
        return
    var saved: Variant = JSON.parse_string(disk.get_as_text())
    disk.close()
    if typeof(saved) != TYPE_DICTIONARY or Rules.sanitize(saved.get("residential_v060", {})) != homes.call("_state"):
        _fail("live neighborhood consequences did not survive disk reload")
        return
    if not main.get_node_or_null("MagnaraCityV052") or not main.get_node_or_null("JanoahRegionalApproachV055"):
        _fail("new families replaced existing world districts")
        return
    main.queue_free()
    print("V0.60 ENTERABLE HOMES MOVING NEIGHBORS AND SAVED CONSEQUENCES PASS")
    get_tree().call_deferred("quit", 0)
