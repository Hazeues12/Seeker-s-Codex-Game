extends Node3D
const Main = preload("res://scenes/main.tscn")
const Mobility = preload("res://systems/aura_parkour_rules_v070.gd")
const CarrierRules = preload("res://systems/magnara_carrier_rules_v070.gd")
const TrialRules = preload("res://systems/spatial_practice_rules_v070.gd")
const Integrity = preload("res://systems/game_save_integrity_v063.gd")

func _ready() -> void:
    call_deferred("_test")

func _fail(message: String) -> void:
    push_error("V0.70 REAL AURA CARRIER TRIALBOARD WORLD FAILED: " + message)
    get_tree().call_deferred("quit",1)

func _test() -> void:
    var game: Node3D = Main.instantiate() as Node3D
    add_child(game)
    for n in range(5):
        await get_tree().process_frame
    var hub: Node = game.get_node_or_null("HubManager")
    var player: CharacterBody3D = game.get_node_or_null("Player") as CharacterBody3D
    var mobile: Control = game.get_node_or_null("MobileUI/MobileControls") as Control
    var carrier: Node3D = game.get_node_or_null("MagnaraMovingCarrierV070") as Node3D
    var trial: Node3D = game.get_node_or_null("SpatialPracticeTrialboardV070") as Node3D
    if hub == null or player == null or mobile == null or carrier == null or trial == null:
        _fail("Godot main scene didn't instantiate all V0.70 3D and mobile nodes")
        return
    for legacy in ["MagnaraPopulationV065","MagnaraBusinessesV066","MagnaraStreamedBlocksV067",
        "SealTrainingBenchV069","PublicGuildDirectorV069","MagnaraLegacyRoofwaysV069"]:
        if game.get_node_or_null(legacy) == null:
            _fail("existing world lost node "+legacy)
            return
    if not bool(carrier.get("initialized")) or not bool(trial.get("initialized")):
        _fail("public carrier or trialboard wasn't initialized")
        return
    var manifest: Dictionary = carrier.get_manifest()
    if int(manifest.get("stations",0)) != 2 or str(manifest.get("platform_type","")) != "AnimatableBody3D" \
            or not bool(manifest.get("free_movement_on_deck",false)):
        _fail("no actual two-stop physical car / free player movement")
        return
    var follow: PathFollow3D = carrier.get_node_or_null("V070ActualCarrierSpline/V070RailPathFollow") as PathFollow3D
    var path: Path3D = carrier.get_node_or_null("V070ActualCarrierSpline") as Path3D
    var vehicle: AnimatableBody3D = carrier.get("deck_body")
    if path == null or follow == null or vehicle == null or not vehicle.sync_to_physics:
        _fail("3D trolley does not use synced physics PathFollow3D")
        return
    if path.curve.get_point_count() != 3 or path.curve.get_baked_length() < 81.0:
        _fail("real spline doesn't cross the shopping streets")
        return
    if vehicle.get_node_or_null("V070CarrierFloorCollision") == null:
        _fail("vehicle deck lacks collision for jumping on it")
        return
    if game.get_node_or_null("Player").get_parent() != game:
        _fail("player was parented to a train, losing free motion and camera state")
        return
    if mobile.get_node_or_null("BurstButton") == null or not mobile.has_method("consume_burst"):
        _fail("iPhone touch interface lacks the promised Burst press")
        return
    if not is_equal_approx(player.floor_snap_length,Mobility.FLOOR_SNAP):
        _fail("moving-platform floor snapping not configured")
        return
    # Burst is a real movement button: never reduce other combat costs or
    # grant story techniques. One press = one resource charge.
    player.global_position = Vector3(0,1.0,0)
    mobile.call("release_controls")
    mobile.set("movement",Vector2(0,-1))
    hub.set("aura",80.0)
    hub.set("stamina",80.0)
    mobile.call("request_burst")
    player.call("_physics_process",0.016)
    if int(player.get("burst_count")) != 1 or float(player.get("burst_remaining")) <= 0.0:
        _fail("touchscreen press never triggered Aura burst momentum")
        return
    if not is_equal_approx(float(hub.get("aura")),64.0) \
            or not is_equal_approx(float(hub.get("stamina")),72.0):
        _fail("public Aura momentum charged incorrect 16 Aura / 8 Stamina")
        return
    if Vector2(player.velocity.x,player.velocity.z).length() < 10.0:
        _fail("burst had no meaningful horizontal impulse in live CharacterBody3D")
        return
    mobile.call("request_burst")
    player.call("_physics_process",0.016)
    if int(player.get("burst_count")) != 1 or not is_equal_approx(float(hub.get("aura")),64.0):
        _fail("holding or repeatedly tapping BURST bypasses cooldown")
        return
    player.set("burst_remaining",0.0)
    mobile.call("release_controls")
    # Real mobile TALK/USE can inspect stations without freezing movement
    # unless a menu is intentionally open.
    player.global_position = Vector3(6.3,0.82,606.6)
    var station: Dictionary = hub.call("_nearest_location")
    if str(station.get("id","")) != "carrier_v070_south":
        _fail("public station isn't discoverable by nearest TALK / USE")
        return
    hub.call("_interact")
    if not bool(carrier.call("is_open")) or not bool(hub.call("_any_panel_open")):
        _fail("carrier's stop timetable UI is missing from iPhone controls")
        return
    carrier.call("_close")
    if bool(hub.call("_any_panel_open")):
        _fail("timetable closing didn't restore player freedom")
        return

    # Test real 3D carrier movement and physical deck collision. The player
    # remains a world-relative CharacterBody3D: motion comes from Godot
    # moving-platform velocity, never direct player position scripting.
    carrier.set("journey_seconds",CarrierRules.DOCK_SECONDS + CarrierRules.ONE_WAY_SECONDS*0.35)
    carrier.call("_physics_process",0.016)
    if absf(float(vehicle.global_position.z) - (608.0+CarrierRules.STATION_DISTANCE*0.35)) > 0.80:
        _fail("spline-driven platform isn't moving at public route coordinates")
        return
    var probe := PhysicsRayQueryParameters3D.create(
        vehicle.global_position + Vector3(0,2.5,0),
        vehicle.global_position + Vector3(0,-2.5,0))
    probe.exclude = [player.get_rid()]
    await get_tree().physics_frame
    var found: Dictionary = get_world_3d().direct_space_state.intersect_ray(probe)
    if found.is_empty() or found.get("collider") != vehicle:
        var collider: Node = found.get("collider") as Node
        _fail("the trolley is not a landable moving platform on the shop street / car=" \
            + str(vehicle.global_position) + " collider=" \
            + (str(collider.name) if is_instance_valid(collider) else "none") \
            + " intersection=" + str(found.get("position",Vector3.ZERO)))
        return
    mobile.call("release_controls")
    player.global_position = vehicle.global_position + Vector3(0,0.16,0)
    player.velocity = Vector3.ZERO
    for step in range(15):
        await get_tree().physics_frame
    if not player.is_on_floor():
        _fail("real player doesn't settle on the trolley deck")
        return
    var rider_z: float = player.global_position.z
    var vehicle_z: float = vehicle.global_position.z
    for step in range(36):
        await get_tree().physics_frame
    if vehicle.global_position.z <= vehicle_z + 1.4:
        _fail("trolley body isn't physically moving during active world simulation")
        return
    if player.global_position.z <= rider_z + 0.8 \
            or absf(player.global_position.z - vehicle.global_position.z) > 4.0:
        _fail("rider isn't carried by actual AnimatableBody3D floor velocity")
        return

    # Physical public Spatial orientation: load only after authorized entry.
    if bool(trial.get_manifest().get("secret_ryoiki_or_archwheel",true)) \
            or int(trial.get_manifest().get("active_room_count",-1)) != 0:
        _fail("client start loaded a private world or secret Soul law")
        return
    player.global_position = TrialRules.ENTRY + Vector3(0,0,-2.1)
    player.velocity = Vector3.ZERO
    var origin: Vector3 = player.global_position
    var nearest: Dictionary = hub.call("_nearest_location")
    if str(nearest.get("id","")) != "trial_v070_gate":
        _fail("supervised trialboard gate isn't reachable in city")
        return
    hub.call("_interact")
    if not bool(trial.call("is_open")):
        _fail("player can't access supervised trialboard UI via TALK / USE")
        return
    trial.call("_enter")
    if not bool(trial.call("is_active")) or bool(trial.call("is_open")):
        _fail("trialroom couldn't enter independently of existing UI panels")
        return
    if int(trial.get_manifest().get("active_room_count",0)) != 1 \
            or player.global_position.distance_to(TrialRules.SPAWN) > 0.01:
        _fail("safe isolated practice room wasn't instantiated around player")
        return
    var arena_root: Node3D = trial.get_node_or_null("V070LoadedTrialArena") as Node3D
    if arena_root == null or arena_root.get_node_or_null("V070TrialFloor") == null \
            or arena_root.get_node_or_null("V070ThirdJumpPlatform") == null:
        _fail("trialroom doesn't contain real physics-backed movement geometry")
        return
    await get_tree().physics_frame
    var room_probe := PhysicsRayQueryParameters3D.create(
        TrialRules.ARENA+Vector3(0,3,0),TrialRules.ARENA-Vector3(0,3,0))
    room_probe.exclude = [player.get_rid()]
    var room_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(room_probe)
    if room_hit.is_empty():
        _fail("separate trialroom has no physical floor")
        return
    if bool(trial.get_manifest().get("grants_spatial_technique",true)):
        _fail("supervised visitor was awarded an unearned rare Spoke")
        return
    # Saving inside ephemeral geometry must serialize the safe Magnara
    # origin, not distant loaded sandbox coordinates or permanent secret data.
    if not bool(hub.call("_save_game")):
        _fail("saved game failed verification inside active training room")
        return
    var save: Dictionary = Integrity.load_best()
    var saved_pos: Array = save.get("data",{}).get("position",[])
    if saved_pos.size() != 3 or float(saved_pos[0]) > 40.0 or float(saved_pos[2]) < -30.0:
        _fail("saving inside temporary arena serializes an unreloadable location")
        return
    if player.global_position.x < 400.0:
        _fail("save incorrectly ejected player from running orientation")
        return
    trial.call("_leave")
    await get_tree().process_frame
    if bool(trial.call("is_active")) or int(trial.get_manifest().get("active_room_count",-1)) != 0 \
            or trial.get_node_or_null("V070LoadedTrialArena") != null:
        _fail("leaving trial didn't actually free isolated room")
        return
    if player.global_position.distance_to(origin) > 0.01:
        _fail("supervised portal didn't return player to exact entry location")
        return
    if not (game.get_node_or_null("MagnaraBusinessesV066") != null and \
            game.get_node_or_null("MagnaraPopulationV065") != null):
        _fail("moving transport or trialroom destroyed earlier business and NPCs")
        return

    print("V0.70 LIVE AURA BURST IPHONE PLATFORM CARRY REAL RAIL PHYSICS AND SAFE TRIALBOARD SAVE PASS")
    game.queue_free()
    get_tree().call_deferred("quit",0)
