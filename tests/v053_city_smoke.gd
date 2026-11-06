extends Node3D

# V0.53 tests physically navigable Ring Two architecture in isolation.
# Avoid using the main game scene: its player spawn and existing quest actors
# should never be altered just to validate a new district.
const City = preload("res://world/magnara_city_v052.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("V0.53 MAGNARA WALKABILITY FAILURE: " + reason)
    get_tree().call_deferred("quit", 1)

func _run() -> void:
    var world := Node3D.new()
    world.name = "PhysicalMagnaraGeometryTest"
    add_child(world)
    var visitor := Node3D.new()
    visitor.name = "Player"
    world.add_child(visitor)
    var city: Node3D = City.new()
    world.add_child(city)
    await get_tree().process_frame
    await get_tree().process_frame
    var plan: Dictionary = city.call("get_manifest")
    if str(plan.get("city", "")) != "Magnara" or (plan.get("enterable_interiors", []) as Array).size() != 6:
        _fail("city manifest must list six real interiors")
        return
    var centers: Dictionary = {
        "west_public": Vector2(-70.0, 50.0),
        "west_professional": Vector2(-70.0, 90.0),
        "east_public": Vector2(70.0, 50.0),
        "east_professional": Vector2(70.0, 90.0)
    }
    var entries: Dictionary = {
        "west_public": [
            {"room":"EnterableCanalServiceHouse", "a":Vector3(-53.0, 1.65, 57.5), "b":Vector3(-43.0, 1.65, 57.5)}],
        "west_professional": [
            {"room":"EnterableSeekerMedicalAnnex", "a":Vector3(-53.0, 1.65, 82.0), "b":Vector3(-43.0, 1.65, 82.0)},
            {"room":"EnterableSeekerRecordsHall", "a":Vector3(-79.0, 1.65, 101.0), "b":Vector3(-89.0, 1.65, 101.0)}],
        "east_public": [
            {"room":"EnterablePublicRestHouse", "a":Vector3(79.0, 1.65, 38.0), "b":Vector3(89.0, 1.65, 38.0)},
            {"room":"EnterableCivicDiningHall", "a":Vector3(53.0, 1.65, 57.5), "b":Vector3(43.0, 1.65, 57.5)}],
        "east_professional": [
            {"room":"EnterableSupplyInspectionHall", "a":Vector3(53.0, 1.65, 101.0), "b":Vector3(43.0, 1.65, 101.0)}]
    }
    var manifest_rooms: Array = plan.get("enterable_interiors", [])
    var count: int = 0
    for cell_id in entries:
        var target: Vector2 = centers[cell_id]
        visitor.position = Vector3(target.x, 1.10, target.y)
        city.call("_refresh_cells")
        await get_tree().physics_frame
        var live: Dictionary = city.get("active_cells")
        if not live.has(cell_id):
            _fail("missing loaded ward " + str(cell_id))
            return
        var ward: Node3D = live[cell_id]
        var shapes: Array[Node] = ward.find_children("*", "CollisionShape3D", true, false)
        var meshes: Array[Node] = ward.find_children("*", "MeshInstance3D", true, false)
        if shapes.size() < 19 or meshes.size() < 80:
            _fail("ward lacks completed urban geometry " + str(cell_id) + " (%d/%d)" % [shapes.size(), meshes.size()])
            return
        var promenade: Node = ward.find_child("ContinuousPedestrianPromenade", true, false)
        var arcade: Node = ward.find_child("ArcadeContinuousCanopy", true, false)
        if promenade == null or arcade == null:
            _fail("pedestrian promenade or covered arcade missing in " + str(cell_id))
            return
        for item in entries[cell_id]:
            var room_id: String = str(item["room"])
            if not manifest_rooms.has(room_id):
                _fail("interior missing from manifest " + room_id)
                return
            var room: Node = ward.find_child(room_id, true, false)
            if room == null:
                _fail("missing physical room " + room_id)
                return
            var roof: Node = room.find_child("RoofDeck", true, false)
            var access: Node = room.find_child("RooftopAccessStep_9", true, false)
            if roof == null or access == null:
                _fail("roof or actual stairs not present " + room_id)
                return
            var ray := PhysicsRayQueryParameters3D.create(item["a"], item["b"])
            var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
            if not hit.is_empty():
                _fail("door is blocked for " + room_id + " by " + str(hit.get("collider", "unknown")))
                return
            count += 1
    # The canal deck is a real bridge over the lower canal bed, and the west
    # quay railing must leave gaps for pedestrians at both bridge approaches.
    visitor.position = Vector3(-62.0, 1.0, 47.5)
    city.call("_refresh_cells")
    await get_tree().physics_frame
    var bridge_probe := PhysicsRayQueryParameters3D.create(
        Vector3(-62.0, 3.0, 47.5), Vector3(-62.0, -0.2, 47.5))
    var bridge_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(bridge_probe)
    if bridge_hit.is_empty():
        _fail("first canal bridge has no physical deck")
        return
    for crossing in [-62.0, -88.0]:
        var path_probe := PhysicsRayQueryParameters3D.create(
            Vector3(float(crossing), 1.60, 43.0),
            Vector3(float(crossing), 1.60, 53.0))
        var blocked: Dictionary = get_world_3d().direct_space_state.intersect_ray(path_probe)
        if not blocked.is_empty():
            _fail("rail blocks canal crossing " + str(crossing))
            return
    visitor.position = Vector3(250.0, 1.0, 250.0)
    city.call("_refresh_cells")
    var distant: Dictionary = city.get("active_cells")
    if distant.size() != 0:
        _fail("distant district streaming failed to unload all wards")
        return
    if count != 6:
        _fail("walkable interior count expected six, got " + str(count))
        return
    print("V0.53 SIX WALKABLE INTERIORS AND CONNECTED STREETS PASS")
    world.queue_free()
    get_tree().call_deferred("quit", 0)
