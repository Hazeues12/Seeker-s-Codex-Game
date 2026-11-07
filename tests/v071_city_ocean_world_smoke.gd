extends Node3D
const Main = preload("res://scenes/main.tscn")
const Wards = preload("res://systems/magnara_expansion_rules_v071.gd")
const Ocean = preload("res://systems/ocean_hydrodynamics_v071.gd")
const OceanWorld = preload("res://world/margerina_ocean_commerce_v071.gd")
const Trade = preload("res://systems/margerina_commerce_rules_v071.gd")
const Integrity = preload("res://systems/game_save_integrity_v063.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("V0.71 REAL CITY OCEAN COMMERCE SCENE FAILED: "+message)
    get_tree().call_deferred("quit",1)

func _run() -> void:
    var game: Node3D = Main.instantiate() as Node3D
    add_child(game)
    for n in range(5):
        await get_tree().process_frame
    var player: CharacterBody3D = game.get_node_or_null("Player") as CharacterBody3D
    var hub: Node = game.get_node_or_null("HubManager")
    var codex: Node = game.get_node_or_null("PersonalCodex")
    var wards: Node3D = game.get_node_or_null("MagnaraExpandedWardsV071") as Node3D
    var harbor: Node3D = game.get_node_or_null("MargerinaOceanCommerceV071") as Node3D
    var land: Node3D = game.get_node_or_null("MargerinaLandCommerceV071") as Node3D
    var region: Node3D = game.get_node_or_null("JanoahRegionalApproachV055") as Node3D
    if player == null or hub == null or codex == null or wards == null \
            or harbor == null or land == null or region == null:
        _fail("V0.71 nodes didn't mount in playable Magnara scene")
        return
    for legacy in ["MagnaraStreamedBlocksV067","MagnaraPopulationV065",
        "MagnaraBusinessesV066","MagnaraMovingCarrierV070",
        "PublicGuildDirectorV069","SpatialPracticeTrialboardV070"]:
        if game.get_node_or_null(legacy) == null:
            _fail("older active city/train/guild/canon system deleted: "+legacy)
            return
    var catalog: Dictionary = harbor.get("route_catalog")
    if not bool(wards.get("initialized")) or not bool(harbor.get("initialized")) \
            or not bool(land.get("initialized")) or not Trade.valid_registry(catalog):
        _fail("public city expansion or trade modules failed initial construction")
        return
    if harbor.get_manifest().get("active",true) or harbor.get_manifest().get("loaded_visual_ocean",true):
        _fail("remote 1 km ocean tile stays in memory while exploring old city")
        return
    if int(wards.get_manifest().get("new_building_shells",0)) != 180 \
            or int(wards.get_manifest().get("new_original_civilians",0)) != 360:
        _fail("180 building shells and 360 public citizens absent")
        return
    if land.get_manifest().get("road_vehicles",0) != 3:
        _fail("actual local street freight fleet missing")
        return
    var wagons: Array = land.get("wagons")
    if (wagons[0] as AnimatableBody3D).get_node_or_null("V071TradeCartBodyCollision") == null:
        _fail("road commerce exists only as text instead of real 3D freight")
        return

    # 30 brand-new cells, separate from 15 legacy V0.67 cells.
    player.global_position = Vector3(256.0,0.90,1012.0)
    hub.set("world_minutes",590.0)
    for i in range(6):
        wards.call("_refresh_chunks")
    wards.call("_refresh_crowds")
    var chunks: Dictionary = wards.get("active_chunks")
    # At the eastmost column only three eligible V0.71 cells border the
    # existing legacy V0.67 district; no phantom fourth tile is allowed.
    if int(wards.call("active_chunk_count")) < 3 \
            or int(wards.call("active_chunk_count")) > Wards.MAX_ACTIVE:
        _fail("new city didn't stream on demand or broke nine-chunk mobile cap")
        return
    if not chunks.has("2:2"):
        _fail("new eastern Ring II ward failed to build")
        return
    var center: Dictionary = chunks["2:2"]
    var chunk: Node3D = center["node"]
    for part in Wards.MODULES:
        var gpu: MultiMeshInstance3D = chunk.get_node_or_null("V071WardKit_"+str(part)) as MultiMeshInstance3D
        if gpu == null or gpu.multimesh.instance_count <= 0:
            _fail("buildings lack distinct modular render module: "+str(part))
            return
    if (center["parcels"] as Array).size() != Wards.PARCELS \
            or (center["residents"] as Array).size() != Wards.PEOPLE:
        _fail("new street didn't create six homes/shops and twelve residents")
        return
    if (center["roof_shapes"] as Array).size() < 20:
        _fail("new buildings lack physical roof access and interbuilding landings")
        return
    var roof_visual: MultiMeshInstance3D = chunk.get_node_or_null("V071RoofAccessGPU") as MultiMeshInstance3D
    if roof_visual == null or roof_visual.multimesh.instance_count < 20:
        _fail("roof step geometry not GPU batched")
        return
    var active_roof: Dictionary = (center["roof_shapes"] as Array)[0]
    var roof_body: StaticBody3D = active_roof["body"]
    player.global_position = roof_body.global_position+Vector3(0,1.15,0)
    wards.call("_refresh_crowds")
    await get_tree().physics_frame
    if (active_roof["shape"] as CollisionShape3D).disabled:
        _fail("nearby new rooftop has no enabled physical landing")
        return
    var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
        roof_body.global_position+Vector3(0,2.6,0),
        roof_body.global_position-Vector3(0,2.6,0))
    ray.exclude = [player.get_rid()]
    var roof_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
    if roof_hit.is_empty() or roof_hit.get("collider") != roof_body:
        _fail("new city rooftop deck is not actually landable")
        return
    var cell := Vector2i(2,2)
    var citizen: Dictionary = Wards.resident(cell,0)
    var location: Vector3 = Wards.resident_state(cell,0,590.0)["world_position"]
    player.global_position = location+Vector3(0,0,0.65)
    wards.call("_refresh_crowds")
    if not wards.get("close_models").has(str(citizen["id"])):
        _fail("new worker wasn't promoted from MultiMesh to full near NPC")
        return
    var nearest: Dictionary = hub.call("_nearest_location")
    if str(nearest.get("id","")) != "ward_v071_"+str(citizen["id"]):
        _fail("new original citizen isn't interactable by existing TALK / USE")
        return
    hub.call("_interact")
    if not bool(wards.call("is_open")) or not bool(hub.call("_any_panel_open")):
        _fail("resident family/job panel didn't open on phone")
        return
    wards.call("_answer","Household")
    if not str(wards.get("panel_body").text).contains(str(citizen["household"])):
        _fail("conversation didn't preserve game-only household continuity")
        return
    wards.call("_close")

    player.global_position = Vector3(0.0,1.0,0.0)
    wards.call("_refresh_chunks")
    wards.call("_refresh_crowds")
    if int(wards.call("active_chunk_count")) != 0:
        _fail("leaving expanded district doesn't release distant buildings/NPCs")
        return
    if int(game.get_node("MagnaraStreamedBlocksV067").call("active_chunk_count")) != 0:
        _fail("legacy old 3D streamer was corrupted by new cell system")
        return

    # Public harbor visit via actual Magnara counter and mobile panel.
    var sign: Vector3 = OceanWorld.PUBLIC_ENTRY-Vector3(2.4,0,0)
    player.global_position = sign
    var harbor_sign: Dictionary = hub.call("_nearest_location")
    if str(harbor_sign.get("id","")) != "ocean_v071_board":
        _fail("public commercial Iron Cothon survey isn't physically reachable")
        return
    hub.call("_interact")
    if not bool(harbor.call("is_open")):
        _fail("harbor survey touchscreen panel didn't open")
        return
    harbor.call("_enter")
    if not bool(harbor.call("is_active")) or bool(harbor.call("is_open")):
        _fail("player didn't enter physical sea preview from the public board")
        return
    if int(harbor.get_manifest().get("ships",0)) != 6 \
            or int(harbor.get_manifest().get("public_dock_workers",0)) != 18:
        _fail("harbor lacks six mixed-size ships or eighteen working civilians")
        return
    var water_visual: MeshInstance3D = (harbor.get("harbor") as Node3D).get_node_or_null(
        "V071WeatherResponsiveOceanMesh") as MeshInstance3D
    if water_visual == null or not (water_visual.material_override is ShaderMaterial):
        _fail("water rendering lacks actual GPU wave shader")
        return
    var water_mesh: PlaneMesh = water_visual.mesh as PlaneMesh
    if water_mesh == null or water_mesh.subdivide_width < 80 \
            or absf(water_mesh.size.x-1000.0) > 0.5:
        _fail("1 km offshore surface lacks enough vertices for animated waves")
        return
    var water_sample: Dictionary = harbor.call("surface_at",OceanWorld.ANCHOR+Vector3(0,0,0))
    if water_sample.is_empty() or not water_sample.get("moving_surface",false):
        _fail("CPU ocean physics doesn't match visual sea coordinate")
        return
    var stern: Dictionary = harbor.call("surface_at",OceanWorld.ANCHOR+Vector3(-320,0,0))
    var deep: Dictionary = harbor.call("surface_at",OceanWorld.ANCHOR+Vector3(460,0,0))
    if float(stern.get("offshore",1)) >= float(deep.get("offshore",0)):
        _fail("near-shore and open-ocean wave effects don't vary with distance")
        return

    var fleet: Array = harbor.get("ship_bodies")
    for i in range(fleet.size()):
        var vessel: AnimatableBody3D = fleet[i]
        if vessel.get_node_or_null("V071ShipWalkableDeckCollision") == null:
            _fail("ship hull exists without a walkable physics deck")
            return
    var vessel: AnimatableBody3D = fleet[1]
    harbor.call("_physics_process",0.016)
    await get_tree().physics_frame
    ray = PhysicsRayQueryParameters3D.create(
        vessel.global_position+Vector3(0,3,0),
        vessel.global_position-Vector3(0,3,0))
    ray.exclude = [player.get_rid()]
    var ship_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
    if ship_hit.is_empty() or ship_hit.get("collider") != vessel:
        var hit_collider: Node = ship_hit.get("collider") as Node
        _fail("merchant vessel cannot physically carry a walking player / ship=" \
            + str(vessel.global_position) + " sea=" + str(harbor.get("harbor").global_position) \
            + " actual-hit=" + (str(hit_collider.name) if is_instance_valid(hit_collider) else "none") \
            + " hit-at=" + str(ship_hit.get("position",Vector3.ZERO)))
        return
    # Test real water interaction away from docks and ship routes.
    player.global_position = OceanWorld.ANCHOR+Vector3(100,-0.22,30)
    player.velocity = Vector3(0,-1,0)
    player.call("_physics_process",0.016)
    if not bool(player.get("water_contact_v071")) or player.velocity.y < -1.6:
        _fail("the ocean is a visual texture only; swimming buoyancy missing")
        return
    if not bool(hub.call("_save_game")):
        _fail("cannot save from active public shipping survey")
        return
    var saved: Dictionary = Integrity.load_best().get("data",{})
    var coords: Array = saved.get("position",[])
    if coords.size() != 3 or float(coords[0]) > 80 or float(coords[0]) < -80:
        _fail("temporary harbor saved 25km of unapproved geography into permanent character position")
        return

    harbor.call("_leave")
    await get_tree().process_frame
    if bool(harbor.call("is_active")) or harbor.get_manifest().get("loaded_visual_ocean",true) \
            or (harbor.get("ship_bodies") as Array).size() != 0:
        _fail("far ocean ships and water stay loaded after return to Magnara")
        return
    if player.global_position.distance_to(sign) > 0.01:
        _fail("public harbor preview doesn't return to accurate safe street")
        return

    # At the old V0.56 Janoah river, the exact physical river
    # remains game-only and has moving ripples/current without changing roads.
    var approach: Vector3 = Vector3(15360,-1.25,70)
    player.global_position = approach
    region.call("_refresh_cells")
    var river: Dictionary = region.call("get_water_surface_at",approach)
    if river.is_empty() or river.get("canon_status","") != "game_only_provisional":
        _fail("existing Janoah floodplain or physical river crossing disappeared")
        return
    var water: MeshInstance3D = region.find_child("JanoahRiverWaterSurface",true,false) as MeshInstance3D
    if water == null or not (water.material_override is ShaderMaterial):
        _fail("river visually reverted to static blue material instead of current animation")
        return
    if region.get_manifest().get("waterbody_is_canonical",true):
        _fail("unverified rivercourse improperly promoted to official Janoah geography")
        return

    print("V0.71 LIVE 180 BUILDING EXTENSION 360 HOUSEHOLDS SWIMMABLE WEATHER OCEAN SIX BUOYANT SHIPS ROAD FREIGHT AND PROVISIONAL RIVER PASS")
    game.queue_free()
    get_tree().call_deferred("quit",0)
