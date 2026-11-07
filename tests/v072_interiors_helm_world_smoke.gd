extends Node3D
const Main = preload("res://scenes/main.tscn")
const Ward = preload("res://systems/magnara_expansion_rules_v071.gd")
const Interior = preload("res://systems/magnara_interiors_rules_v072.gd")
const SkiffRules = preload("res://systems/ocean_helm_rules_v072.gd")
const OceanWorld = preload("res://world/margerina_ocean_commerce_v071.gd")
const Integrity = preload("res://systems/game_save_integrity_v063.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("V0.72 LIVE DOOR WORKERS AND STEERABLE BOAT FAILED: "+message)
    get_tree().call_deferred("quit",1)

func _run() -> void:
    var game: Node3D = Main.instantiate() as Node3D
    add_child(game)
    for n in range(6):
        await get_tree().process_frame
    var player: CharacterBody3D = game.get_node_or_null("Player") as CharacterBody3D
    var hub: Node = game.get_node_or_null("HubManager")
    var city: Node = game.get_node_or_null("MagnaraExpandedWardsV071")
    var interiors: Node = game.get_node_or_null("MagnaraWardInteriorsV072")
    var ocean: Node = game.get_node_or_null("MargerinaOceanCommerceV071")
    var codex: Node = game.get_node_or_null("PersonalCodex")
    if player == null or hub == null or city == null or interiors == null \
            or ocean == null or codex == null:
        _fail("full 3D game lacks V0.72 public interiors, skiff ocean or original city")
        return
    for name in ["MargerinaLandCommerceV071","MagnaraMovingCarrierV070",
        "MagnaraLegacyRoofwaysV069","MagnaraBusinessesV066","MagnaraPopulationV065",
        "SpatialPracticeTrialboardV070","PublicGuildDirectorV069"]:
        if game.get_node_or_null(name) == null:
            _fail("older Ring II structures lost: "+name)
            return
    if not bool(interiors.get("initialized")) or not bool(city.get("initialized")):
        _fail("public venue service didn't initialize after main city streamer")
        return
    if int(interiors.get_manifest().get("physical_public_interiors_available",0)) != 30:
        _fail("30 authentic physical game-only venue locations not registered")
        return

    # Each new ward has a real open doorway and one roster citizen INSIDE
    # during their work shift; they are absent from the external walking LOD.
    var cell := Vector2i(2,2)
    hub.set("world_minutes",620.0)
    player.global_position = Ward.center(cell)+Vector3(0,0.8,0)
    for i in range(5):
        city.call("_refresh_chunks")
    city.call("_refresh_crowds")
    interiors.call("_refresh")
    if not city.get("active_chunks").has("2:2") \
            or not interiors.get("sites").has("2:2"):
        _fail("entry venue isn't truly attached to the dynamically streamed ward")
        return
    var spec: Dictionary = Interior.site(cell)
    var room_data: Dictionary = interiors.get("sites")["2:2"]
    var room: Node3D = room_data["root"]
    var floor: MeshInstance3D = room.get_node_or_null("V072RealPublicFloor") as MeshInstance3D
    var side: MeshInstance3D = room.get_node_or_null("V072OpenDoorFacade") as MeshInstance3D
    var worker: Node3D = room_data["staff"]
    if room == null or floor == null or side == null or worker == null:
        _fail("new site is a painted solid building without interior floor, door or worker")
        return
    if floor.get_node_or_null("V072RealPublicFloor_Physics/V072RealWalkableInteriorCollision") == null:
        _fail("public interior floor isn't a real landing collider")
        return
    for n in range(2):
        await get_tree().physics_frame
    var center_world: Vector3 = Ward.origin(cell)+(spec["center_local"] as Vector3)
    var ray := PhysicsRayQueryParameters3D.create(
        center_world+Vector3(0,3.30,0),
        center_world+Vector3(0,-0.30,0))
    ray.exclude = [player.get_rid()]
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
    if hit.is_empty() or (hit.get("collider") as Node).name != "V072RealPublicFloor_Physics":
        _fail("3D venue floor isn't walkable in the actual Godot physics world")
        return
    var doorway: Vector3 = spec["door_world"]
    var inward: float = float(spec["inward"])
    var mouth := PhysicsRayQueryParameters3D.create(
        doorway+Vector3(inward*1.30,1.10,0),
        doorway+Vector3(-inward*1.30,1.10,0))
    mouth.exclude = [player.get_rid()]
    var blocked: Dictionary = get_world_3d().direct_space_state.intersect_ray(mouth)
    if not blocked.is_empty():
        var collider: Node = blocked.get("collider") as Node
        _fail("public building door is only painted; ray blocked by " \
            + (str(collider.name) if is_instance_valid(collider) else "unknown"))
        return
    var worker_state: Dictionary = Interior.staff_schedule(cell,620.0)
    if not worker.visible or not bool(worker_state.get("on_shift",false)) \
            or bool(Ward.resident_state(cell,Interior.STAFF_INDEX,620.0).get("visible",true)):
        _fail("worker can't appear in venue without duplicating an outdoor NPC")
        return
    player.global_position = doorway+Vector3(inward*0.8,0.0,0)
    var nearest: Dictionary = hub.call("_nearest_location")
    if str(nearest.get("id","")) != "interior_v072_entry_2:2":
        _fail("real open door isn't discoverable with existing phone TALK / USE")
        return
    hub.call("_interact")
    if not bool(interiors.call("is_open")) or not bool(hub.call("_any_panel_open")):
        _fail("original Touch/Talk interaction doesn't open public workroom")
        return
    interiors.call("_topic","Household")
    if not str(interiors.get("story").text).contains(str(worker_state["household"])):
        _fail("indoor staff is not linked to existing scheduled household")
        return
    interiors.call("_close")
    if bool(hub.call("_any_panel_open")):
        _fail("closed workroom panel still blocks normal open-world movement")
        return
    player.global_position = (room_data["staff"] as Node3D).global_position+Vector3(0,0,0.70)
    var worker_nearest: Dictionary = hub.call("_nearest_location")
    if str(worker_nearest.get("id","")) != "interior_v072_staff_2:2":
        _fail("on-shift employee cannot be addressed as a physical NPC")
        return
    hub.set("world_minutes",1120.0)
    interiors.call("_refresh")
    if worker.visible:
        _fail("in-room resident doesn't leave the public shift at night")
        return
    if Interior.staff_schedule(cell,620.0)["id"] != Interior.staff_schedule(cell,1120.0)["id"]:
        _fail("work shift schedules unexpectedly change the worker's identity")
        return

    # Actual streamed interiors must unload when the player leaves Ring II.
    player.global_position = Vector3(0,1.0,0)
    city.call("_refresh_chunks")
    city.call("_refresh_crowds")
    interiors.call("_refresh")
    if int(interiors.call("active_count")) != 0 \
            or int(city.call("active_chunk_count")) != 0:
        _fail("public workrooms stay loaded at the original Magnara hub")
        return

    # Take an existing full-game Harbor survey. It should add exactly ONE
    # freely steerable skiff beyond the six canonical-status-safe merchants.
    player.global_position = OceanWorld.PUBLIC_ENTRY-Vector3(2.4,0,0)
    ocean.call("_enter")
    if not bool(ocean.call("is_active")):
        _fail("public visitor can't access the approved game-only sea survey")
        return
    var controller: Node3D = ocean.get("skiff_controller") as Node3D
    if controller == null or not bool(controller.get("initialized")):
        _fail("real public steerable skiff not spawned in existing harbor")
        return
    var skiff: AnimatableBody3D = controller.get("body") as AnimatableBody3D
    if skiff == null or skiff.get_node_or_null("V072WalkableSteeringDeckCollider") == null:
        _fail("boat has no true moving 3D deck collider")
        return
    if not bool(controller.get_manifest().get("player_parenting",true)) == false:
        _fail("steering vehicle wrongfully parents the player and removes free parkour")
        return
    if int(ocean.get_manifest().get("ships",0)) != 6:
        _fail("V0.72 boat destroyed the original six sea-commerce vessels")
        return
    # Raycast onto the new boat, never onto a finger pier or cosmetic mesh.
    var boat_ray := PhysicsRayQueryParameters3D.create(
        skiff.global_position+Vector3(0,3.0,0),
        skiff.global_position+Vector3(0,-3.0,0))
    boat_ray.exclude = [player.get_rid()]
    await get_tree().physics_frame
    var boat_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(boat_ray)
    if boat_hit.is_empty() or boat_hit.get("collider") != skiff:
        var coll: Node = boat_hit.get("collider") as Node
        _fail("steerable boat can't be physically boarded / hit=" \
            + (str(coll.name) if is_instance_valid(coll) else "none"))
        return

    player.global_position = skiff.global_position+Vector3(-1.8,0.16,0)
    player.velocity = Vector3.ZERO
    for n in range(8):
        await get_tree().physics_frame
    var skiff_approach: Dictionary = hub.call("_nearest_location")
    if str(skiff_approach.get("id","")) != "skiff_v072_helm":
        _fail("the player can't take boat helm using the existing TALK / USE action")
        return
    hub.call("_interact")
    if not bool(controller.call("is_helming")):
        _fail("the iPhone helm control wasn't activated on the real boat")
        return
    controller.call("_change_throttle",1.0)
    var start_x: float = skiff.global_position.x
    var rider_x: float = player.global_position.x
    for n in range(103):
        await get_tree().physics_frame
    var skiff_state: Dictionary = controller.get("state")
    if float(skiff_state.get("speed",0.0)) <= 0.7 \
            or skiff.global_position.x <= start_x+0.9:
        _fail("helming fails to physically accelerate the public craft through ocean waves")
        return
    if controller.get("wake_mesh").visible_instance_count < 2:
        _fail("underway small vessel lacks the promised animated sea wake")
        return
    if player.global_position.x <= rider_x+0.55 \
            or player.global_position.distance_to(skiff.global_position) > 6.0:
        _fail("player is not carried by a moving skiff while free on physical deck")
        return
    if float(skiff_state.get("wave_samples",0)) != 4:
        _fail("skiff wave physics fails the same four-point samples as large ships")
        return

    controller.call("release_helm")
    var before_return: Vector3 = player.global_position
    if bool(controller.call("is_helming")) or skiff.global_position.distance_to(before_return) > 6.0:
        _fail("releasing helm changes or loses real player world location")
        return
    if not bool(hub.call("_save_game")):
        _fail("cannot save safely while riding skiff in temporary port tile")
        return
    var saved: Dictionary = Integrity.load_best().get("data",{})
    var pos: Array = saved.get("position",[])
    if pos.size() != 3 or absf(float(pos[0])) > 80.0:
        _fail("save stored temporary, false real-world ocean coordinates")
        return
    ocean.call("_leave")
    await get_tree().process_frame
    if bool(ocean.call("is_active")) or is_instance_valid(ocean.get("skiff_controller")):
        _fail("skiff isn't unloaded when leaving temporary public sea survey")
        return
    if player.global_position.distance_to(
        OceanWorld.PUBLIC_ENTRY-Vector3(2.4,0,0)) > 0.1:
        _fail("skiff voyage didn't safely return to the actual city gate")
        return

    print("V0.72 REAL ENTERABLE THIRTY WARD WORKROOMS HOUSEHOLD SHIFT OPEN DOOR HELM AND PLAYER-CARRIED OCEAN WAKE SAVE PASS")
    game.queue_free()
    get_tree().call_deferred("quit",0)
