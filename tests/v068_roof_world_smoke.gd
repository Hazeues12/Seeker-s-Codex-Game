extends Node3D
const Main = preload("res://scenes/main.tscn")
const Roof = preload("res://systems/magnara_roof_rules_v068.gd")
const District = preload("res://systems/magnara_stream_rules_v067.gd")
const Power = preload("res://systems/seeker_power_rules_v068.gd")

func _ready() -> void:
    call_deferred("_verify")

func _fail(msg: String) -> void:
    push_error("V0.68 PHYSICAL ROOF / PUBLIC WORLD FAILED: " + msg)
    get_tree().call_deferred("quit", 1)

func _verify() -> void:
    var world: Node3D = Main.instantiate() as Node3D
    add_child(world)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    var roofs: Node3D = world.get_node_or_null("MagnaraStreamedBlocksV067") as Node3D
    var census: Node = world.get_node_or_null("MagnaraPopulationV065")
    var shops: Node = world.get_node_or_null("MagnaraBusinessesV066")
    var kiosk: Node = world.get_node_or_null("MagnaraPublicPulseV068")
    var hub: Node = world.get_node_or_null("HubManager")
    var codex: Node = world.get_node_or_null("PersonalCodex")
    var player: CharacterBody3D = world.get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(roofs) or not is_instance_valid(census) or not is_instance_valid(shops) or not is_instance_valid(kiosk) or not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(player):
        _fail("gameplay project scenes no longer load with original player and shops")
        return
    if not bool(roofs.get("initialized")) or not bool(kiosk.get("initialized")):
        _fail("Rooftop streamer or public daily pulse didn't initialize")
        return
    var data: Dictionary = roofs.call("get_manifest")
    if not bool(data.get("v068_roof_parkour", false)) or int(data.get("v068_roof_route_count_per_chunk", 0)) != 2:
        _fail("two public rooftop escape routes missing per chunk")
        return
    if str(data.get("v068_toon_lighting", "")).is_empty():
        _fail("anime-inspired hard lighting not enabled in compatibility material")
        return
    if (roofs.get("instanced_material") as StandardMaterial3D).diffuse_mode != BaseMaterial3D.DIFFUSE_TOON:
        _fail("actual rendered modules not using supported Toon shading")
        return
    if not bool(kiosk.call("get_manifest").get("all_public_game_only", false)):
        _fail("private economic fiction or hidden Archwheel truth reached public UI")
        return
    if roofs.call("active_chunk_count") != 0:
        _fail("far rooftops loaded while standing at original Seeker Quarters")
        return

    player.global_position = Vector3(0.0, 1.0, 992.0)
    for n in range(6):
        roofs.call("_refresh_chunks")
    roofs.call("_refresh_crowds")
    if int(roofs.call("active_chunk_count")) != 9:
        _fail("nine near chunks are not streamed after entering northern city")
        return
    var chunks: Dictionary = roofs.get("active_chunks")
    if not chunks.has("0:2"):
        _fail("centered roof cell didn't spawn")
        return
    var sample: Dictionary = chunks["0:2"]
    var chunk: Node3D = sample["node"]
    var roof_network: Node3D = chunk.get_node_or_null("V068PhysicalRooftopRoutes") as Node3D
    if not is_instance_valid(roof_network):
        _fail("no actual physical rooftop jump course inside procedurally generated buildings")
        return
    if (sample.get("roof_shapes", []) as Array).size() < 25:
        _fail("not enough physical landing decks for vertical and interbuilding travel")
        return
    for component in ["stair", "bridge"]:
        var gpu: MultiMeshInstance3D = roof_network.get_node_or_null("V068RooftopGPU_" + component) as MultiMeshInstance3D
        if gpu == null or gpu.multimesh.instance_count < 4 or not gpu.multimesh.use_colors:
            _fail("jump platforms aren't visible or instance-batched: " + component)
            return
    if roof_network.find_child("V068RoofJumpHint", true, false) == null:
        _fail("no phone-friendly climb and double-jump guidance in street")
        return
    if (sample.get("colliders", []) as Array).size() != District.PARCELS_PER_CHUNK:
        _fail("prior building collision behavior was overwritten by roof platforms")
        return

    # Rooftop landing: place the player's capsule above an actual generated
    # roof in an instantiated chunk, activate nearby collision, and raycast.
    var cell := Vector2i(0,2)
    var deck: Dictionary = Roof.roof_deck(cell, 0)
    var local: Vector3 = deck["local_position"]
    var roof_target: Vector3 = chunk.global_position + local
    player.global_position = roof_target + Vector3(0, 1.2, 0)
    roofs.call("_refresh_crowds")
    await get_tree().physics_frame
    var matching: Dictionary = {}
    for entry in sample["roof_shapes"]:
        if str(entry["id"]) == str(deck["id"]):
            matching = entry
            break
    if matching.is_empty():
        _fail("visible modular roof doesn't have a corresponding static physics deck")
        return
    if (matching["shape"] as CollisionShape3D).disabled:
        _fail("physical roof collider didn't activate when player landed nearby")
        return
    var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
        roof_target + Vector3(0, 3.0, 0), roof_target - Vector3(0, 2.5, 0))
    ray.exclude = [player.get_rid()]
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
    if hit.is_empty() or not (hit.get("collider") as Node).is_in_group("v068_roof_physical"):
        _fail("walking/jumping cannot land on a physical rooftop deck")
        return
    if absf(float(hit.get("position", Vector3.ZERO).y) - float(deck["top_y"])) > 0.12:
        _fail("rendered roof and rooftop physics mismatch")
        return

    var steps: Array[Dictionary] = Roof.entry_stairs(cell, 0)
    if steps.size() < 4:
        _fail("street approach to roof needs intermediate steps")
        return
    var first_step: Dictionary = steps[0]
    var step_pos: Vector3 = chunk.global_position + first_step["local_position"]
    player.global_position = step_pos + Vector3(0,1.2,0)
    roofs.call("_refresh_crowds")
    await get_tree().physics_frame
    matching = {}
    for entry in sample["roof_shapes"]:
        if str(entry["id"]) == str(first_step["id"]):
            matching = entry
            break
    if matching.is_empty() or (matching["shape"] as CollisionShape3D).disabled:
        _fail("first parkour step is not a physical landing surface")
        return
    ray = PhysicsRayQueryParameters3D.create(step_pos + Vector3(0, 2.6, 0),
        step_pos - Vector3(0, 2.6, 0))
    ray.exclude = [player.get_rid()]
    hit = get_world_3d().direct_space_state.intersect_ray(ray)
    if hit.is_empty() or not (hit.get("collider") as Node).is_in_group("v068_roof_physical"):
        _fail("actual staircase cannot receive jump landing collision")
        return
    var prev_top: float = 0.80
    for platform in steps:
        if absf(float(platform["top_y"]) - prev_top) > Roof.STEP_RISE_MAX + 0.02:
            _fail("physical platform jump exceeds verified vertical jump capability")
            return
        prev_top = float(platform["top_y"])
    if absf(float(deck["top_y"]) - prev_top) > Roof.STEP_RISE_MAX:
        _fail("stair landing is too far below roof for double jump")
        return

    # Move off the roof and unload the module along with all physical planks.
    player.global_position = Vector3(0,1,1710)
    roofs.call("_refresh_chunks")
    roofs.call("_refresh_crowds")
    await get_tree().process_frame
    if int(roofs.call("active_chunk_count")) != 0 or int(roofs.call("close_count")) != 0:
        _fail("unneeded roof colliders remain loaded after leaving neighborhood")
        return
    player.global_position = Vector3(0,1,992)
    for n in range(6):
        roofs.call("_refresh_chunks")
    if (roofs.get("active_chunks") as Dictionary)["0:2"]["roof_shapes"].size() != (sample["roof_shapes"] as Array).size():
        _fail("return to block does not reproduce original roof traversal geometry")
        return

    # Public city economy is visible only through a street-side kiosk.
    player.global_position = Vector3(9.9, 0.83, 712.0)
    var nearest: Dictionary = hub.call("_nearest_location")
    if str(nearest.get("id", "")) != "pulse_v068_public":
        _fail("public bulletin is not physically reachable by TALK / USE")
        return
    hub.call("_interact")
    if not bool(kiosk.call("is_open")) or not bool(hub.call("_any_panel_open")):
        _fail("public world pulse UI isn't available on iPhone")
        return
    var pulse: Dictionary = Power.public_local_pulse(float(hub.get("world_minutes")),hub.get("shop_stock_v066"))
    if not str(kiosk.get("text_body").text).contains("Soul") or not str(kiosk.get("text_body").text).contains("Aura"):
        _fail("visible power component explanation missing from public bulletin")
        return
    if pulse.get("red_order_influence", "") != "not_publicly_reported":
        _fail("private antagonists became public fake simulation reports")
        return
    kiosk.call("_close")
    if bool(hub.call("_any_panel_open")):
        _fail("closing kiosk didn't restore movement controls")
        return

    # The original active Martial strike still costs exactly 12 Aura and 4
    # Stamina, but must pass the same four-layer metadata authorization.
    hub.set("aura", 60.0)
    hub.set("stamina", 70.0)
    if not bool(hub.call("try_martial_strike")):
        _fail("existing player Martial strike broken by power data layer")
        return
    if not is_equal_approx(float(hub.get("aura")),48.0) or not is_equal_approx(float(hub.get("stamina")),66.0):
        _fail("basic player strike changed real original game cost or stamina")
        return
    print("V0.68 PHYSICAL ROOF HOPS MODULAR CHUNK UNLOAD TOON HUD AURA VALIDATION PASS")
    world.queue_free()
    get_tree().call_deferred("quit", 0)
