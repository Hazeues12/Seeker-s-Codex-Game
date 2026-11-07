extends Node3D
const Main = preload("res://scenes/main.tscn")
const Rules = preload("res://systems/magnara_stream_rules_v067.gd")

func _ready() -> void:
    call_deferred("_test")

func _fail(message: String) -> void:
    push_error("V0.67 REAL STREAMED WORLD FAILED: " + message)
    get_tree().call_deferred("quit", 1)

func _test() -> void:
    var world: Node3D = Main.instantiate() as Node3D
    add_child(world)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    var stream: Node = world.get_node_or_null("MagnaraStreamedBlocksV067")
    var population: Node = world.get_node_or_null("MagnaraPopulationV065")
    var market: Node = world.get_node_or_null("MagnaraBusinessesV066")
    var geography: Node = world.get_node_or_null("MagnaraGeographyV054")
    var hub: Node = world.get_node_or_null("HubManager")
    var codex: Node = world.get_node_or_null("PersonalCodex")
    var player: CharacterBody3D = world.get_node_or_null("Player") as CharacterBody3D
    if stream == null or population == null or market == null or geography == null or hub == null or codex == null or player == null:
        _fail("new city world damaged previous actual Godot scenes")
        return
    if not bool(stream.get("initialized")) or not bool(market.get("initialized")):
        _fail("modular city didn't initialize on live hub")
        return
    if int(stream.call("active_chunk_count")) != 0:
        _fail("far city is preloaded at initial game spawn instead of partitioned")
        return
    var manifest: Dictionary = stream.call("get_manifest")
    if int(manifest.get("max_loaded_chunks", 0)) != 9 or int(manifest.get("total_available_scaffold_buildings",0)) != 90:
        _fail("world cannot claim 9 chunk budget/90 deterministic building shells")
        return
    if bool(manifest.get("cpu_occlusion_baked", true)):
        _fail("CPU occlusion incorrectly asserted active in Web Compatibility renderer")
        return
    if not world.get_node_or_null("MagnaraMarketsV062") or not world.get_node_or_null("MagnaraCivicV064") or not world.get_node_or_null("MagnaraWorkshopsV061"):
        _fail("streamed street expansion deleted established market/clinic/workshop")
        return
    if stream.get_node_or_null("V067StableOldCityStreetConnector") == null:
        _fail("old commercial streets don't physically connect to the streaming district")
        return

    var first: Vector3 = Vector3(0, 1.0, 992.0)
    player.global_position = first
    for n in range(6):
        stream.call("_refresh_chunks")
    stream.call("_refresh_crowds")
    if int(stream.call("active_chunk_count")) != 9 or int(stream.call("loaded_building_count")) != 54:
        _fail("3x3 live radius didn't load exactly nine bounded chunks with six buildings each")
        return
    var tiles: Dictionary = stream.get("active_chunks")
    if not tiles.has("0:2"):
        _fail("active center block isn't keyed by stable 128m coordinates")
        return
    var center: Dictionary = tiles["0:2"]
    var root: Node3D = center["node"]
    if root.get_node_or_null("V067ChunkStreets") == null:
        _fail("actual 128m block has no navigable streets")
        return
    for module in Rules.MODULE_TYPES:
        var group: MultiMeshInstance3D = root.get_node_or_null("V067ModularKit_" + str(module)) as MultiMeshInstance3D
        if group == null or group.multimesh == null or group.multimesh.instance_count < 1:
            _fail("architectural Lego module not GPU-instanced: " + str(module))
            return
        if not group.multimesh.use_colors or not group.multimesh.mesh is BoxMesh:
            _fail("per-instance architecture colors or reusable mesh were lost")
            return
        if group.visibility_range_end <= 100.0:
            _fail("modular housing visibility range wasn't configured")
            return
    if (root.get_node_or_null("V067ChunkStreets/V067ChunkMainStreet") as Node).find_child("V067StreetCollision", true, false) == null:
        _fail("visible chunk roads have no traversable physics surfaces")
        return
    if (center["parcels"] as Array).size() != Rules.PARCELS_PER_CHUNK:
        _fail("wrong building floor kit count")
        return
    var colliders: Array = center["colliders"]
    if colliders.size() != Rules.PARCELS_PER_CHUNK:
        _fail("near houses lack colliders")
        return
    await get_tree().physics_frame
    var enabled: int = 0
    for spec in colliders:
        var collision: CollisionShape3D = spec["shape"]
        if not collision.disabled:
            enabled += 1
    if enabled < 1:
        _fail("near walls remain ghost geometry even when player is nearby")
        return

    # Old canonical NPCs also gain a real near/mid/far visual/collider budget.
    hub.set("world_minutes", 600.0)
    var william: Node3D = population.get("actors")["william_lockhart"]
    player.global_position = Vector3(-30, 1, 555)
    population.call("_tick")
    await get_tree().physics_frame
    var first_range: MeshInstance3D = william.get_node_or_null("V067MidBody") as MeshInstance3D
    var original: MeshInstance3D = william.get_node_or_null("NPCV065Torso") as MeshInstance3D
    var body: CollisionShape3D = william.get_node_or_null("V067NearNPCSolid/V067NearNPCShape") as CollisionShape3D
    if not william.visible or not original.visible or first_range.visible or body.disabled:
        _fail("canon guildmaster isn't detailed + physical at close range")
        return
    player.global_position = william.global_position + Vector3(0,0,65)
    population.call("_tick")
    await get_tree().physics_frame
    if not william.visible or original.visible or not first_range.visible or not body.disabled:
        _fail("canon NPC didn't switch to simplified, no-collision midrange")
        return
    player.global_position = william.global_position + Vector3(0,0,145)
    population.call("_tick")
    if william.visible:
        _fail("distant full-detail canonical NPC still being rendered")
        return

    # Approaching a streamed resident creates a multi-part talking actor.
    player.global_position = first
    for n in range(6):
        stream.call("_refresh_chunks")
    var cell := Vector2i(0, 2)
    var time: float = 600.0
    hub.set("world_minutes", time)
    var resident: Dictionary = Rules.person(cell, 0)
    var id: String = str(resident["id"])
    var at: Vector3 = Rules.person_state(cell, 0, time)["world_position"]
    player.global_position = at + Vector3(0,0.6,0)
    stream.call("_refresh_chunks")
    stream.call("_refresh_crowds")
    var near: Dictionary = stream.get("near_models")
    if not near.has(id) or (stream.get("crowd_stats") as Dictionary).get("near", 0) < 1:
        _fail("close resident did not spawn its physical 3D proxy")
        return
    var human: Node3D = near[id]
    if human.get_node_or_null("V067ClosePhysicalCitizen/V067CitizenPhysicalCollision") == null:
        _fail("close person has no independent collision physics")
        return
    var nearest: Dictionary = hub.call("_nearest_location")
    if str(nearest.get("id", "")) != "street_v067_" + id:
        _fail("mobile TALK/USE can't find streamed resident without stale hub entries")
        return
    hub.call("_interact")
    if not bool(stream.call("is_open")) or not bool(hub.call("_any_panel_open")):
        _fail("streamed resident mobile-safe conversation doesn't open")
        return
    stream.call("_ask", "work")
    if not (codex.get("profile").get("history", []) as Array).any(func(entry: Dictionary) -> bool:
        return str(entry.get("id", "")) == "v067:conversation:%s:day:1:work" % id
    ):
        _fail("individual work discussion wasn't recorded in Personal Codex")
        return
    stream.call("_close")
    codex.call("_load_profile")
    if not (codex.get("profile").get("history", []) as Array).any(func(entry: Dictionary) -> bool:
        return str(entry.get("id", "")) == "v067:conversation:%s:day:1:work" % id
    ):
        _fail("streamed NPC encounter does not survive actual profile disk reload")
        return

    player.global_position = at + Vector3(65.0, 0.5, 0)
    stream.call("_refresh_chunks")
    stream.call("_refresh_crowds")
    if stream.get("near_models").has(id):
        _fail("mid-range population kept near-range collider and seven detailed parts")
        return
    var mid_count: int = int(stream.get("crowd_stats").get("mid", 0))
    if mid_count < 1:
        _fail("20-100m midrange has no instanced rail-following pedestrians")
        return
    var instance_mesh: MultiMesh = (center["crowd"] as MultiMeshInstance3D).multimesh
    if instance_mesh.instance_count != Rules.RESIDENTS_PER_CHUNK:
        _fail("per-cell crowd instancing exceeds bounded resident count")
        return

    # Exit the geography: all fifteen possible chunks are not kept alive.
    player.global_position = Vector3(0,1,1710)
    stream.call("_refresh_chunks")
    stream.call("_refresh_crowds")
    await get_tree().process_frame
    if int(stream.call("active_chunk_count")) != 0 or int(stream.call("close_count")) != 0:
        _fail("leaving the area didn't unload obsolete chunks and all their NPCs")
        return
    if (stream.get("resident_records") as Dictionary).size() != 0:
        _fail("unloaded neighborhood retained live people in RAM")
        return
    if world.get_node_or_null("MagnaraBusinessesV066/V066Shop_lebells") == null:
        _fail("unloading scenic region deleted earlier authored shops")
        return

    # Revisit: same six building specs and individual citizen identities.
    player.global_position = first
    for n in range(6):
        stream.call("_refresh_chunks")
    stream.call("_refresh_crowds")
    var restarted: Dictionary = stream.get("active_chunks")
    if not restarted.has("0:2") or restarted["0:2"]["parcels"] != center["parcels"]:
        _fail("identical district address recreated unrelated buildings")
        return
    if str(restarted["0:2"]["citizens"][0]["name"]) != str(resident["name"]):
        _fail("individual resident identity changed when chunk reloaded")
        return
    if int(stream.call("active_chunk_count")) > Rules.ACTIVE_CAP:
        _fail("streaming exceeded nine chunk GPU/CPU budget")
        return

    print("V0.67 STREAMING CHUNK UNLOAD RELOAD MODULAR MULTIMESH NPC LOD COLLISION CHAT PERSISTENCE PASS")
    world.queue_free()
    get_tree().call_deferred("quit", 0)
