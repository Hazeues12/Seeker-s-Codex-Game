extends Node3D
# V0.56 physically verifies that river is carved into the heightfield, that
# both bridge decks are solid, and that water sections stream without leaks.
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const Region = preload("res://world/janoah_approach_v055.gd")
const Hydro = preload("res://world/janoah_waterways_v056.gd")
const Kit = preload("res://world/janoah_environment_kit_v056.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("V0.56 REGIONAL WATERWAY FAILED: " + reason)
    get_tree().call_deferred("quit", 1)

func _run() -> void:
    var water_file := FileAccess.open("res://data/janoah_waterways_v056.json", FileAccess.READ)
    if water_file == null:
        _fail("missing watercourse registry")
        return
    var parsed: Variant = JSON.parse_string(water_file.get_as_text())
    water_file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        _fail("invalid water registry")
        return
    var data: Dictionary = parsed
    if str(data.get("canon_status", "")) != "game_only_local_preview":
        _fail("proposed river was declared as novel canon")
        return
    var river: Dictionary = data.get("river", {})
    if int(river.get("tile_column_x", -1)) != 60 or int(river.get("river_center_x_m_at_route", -1)) != 15360:
        _fail("physical river position differs from atlas")
        return
    var crossings: Array = data.get("crossings", [])
    if crossings.size() != 2 or not bool(crossings[0].get("deck_collision", false)) or not bool(crossings[1].get("deck_collision", false)):
        _fail("both physical crossings must exist")
        return
    if bool(data.get("runtime", {}).get("legacy_saves_schema_changed", true)):
        _fail("new terrain cannot rewrite player save format")
        return
    for phase in ["industrial_outskirts", "farmed_countryside", "rolling_interior_route"]:
        if not Kit.valid_stage(phase) or Kit.ground_color(phase) == Color.BLACK:
            _fail("regional material kit stage missing")
            return
    if Kit.ground_color("industrial_outskirts") == Kit.ground_color("farmed_countryside"):
        _fail("land use stages must remain visually different")
        return
    if not Hydro.has_water_tile(60) or Hydro.has_water_tile(59) or Hydro.has_water_tile(61):
        _fail("streamed river cells have incorrect x footprint")
        return
    if absf(Hydro.river_center_x(70.0) - 15360.0) > 0.01:
        _fail("river centerline disagrees with atlas")
        return
    for z in [-184.0, -58.0, 70.0, 198.0, 326.0]:
        var center: float = Hydro.river_center_x(z)
        var submerged: float = Region.height_at(center, z)
        var dry: float = Region.height_at(center + 60.0, z)
        if submerged > -2.85 or dry < -2.0:
            _fail("heightfield riverbed or bank not truly carved at " + str(z))
            return
    if not Region.safe_approach_save(Vector3(15363.0, -3.0, 70.0)):
        _fail("players cannot save inside low riverbank terrain")
        return
    var world := Node3D.new()
    world.name = "JanoahRiverWorldTest"
    add_child(world)
    var visitor := Node3D.new()
    visitor.name = "Player"
    visitor.position = Vector3(15360.0, 1.0, 70.0)
    world.add_child(visitor)
    var region: Node3D = Region.new()
    world.add_child(region)
    await get_tree().process_frame
    await get_tree().physics_frame
    var active: Dictionary = region.get("cells")
    for row in [-1, 0, 1]:
        var key: String = "60:%d" % row
        if not active.has(key):
            _fail("streamed water tile absent " + key)
            return
        var cell: Node3D = active[key]
        for part in [
            "JanoahRiverWaterSurface", "JanoahRoadBridgeDeck",
            "FreightTrestleBridgeDeck", "RoadBridgeSafetyRail",
            "FreightBridgeGuard", "JanoahTerrainCollision", "JanoahThroughRoadBank"
        ]:
            if cell.find_child(part, true, false) == null:
                _fail("missing actual terrain or bridge structure " + key + ":" + part)
                return
        var water: MeshInstance3D = cell.find_child("JanoahRiverWaterSurface", true, false) as MeshInstance3D
        if not is_instance_valid(water) or water.mesh.get_surface_count() < 1 or not water.get_children().is_empty():
            _fail("water surface is incorrectly collidable or lacks mesh faces")
            return
        var terrain: StaticBody3D = cell.find_child("JanoahTerrainCollision", true, false) as StaticBody3D
        if terrain == null or terrain.get_node_or_null("JanoahTerrainTriangleShape") == null:
            _fail("floodplain lacks collision-backed triangle terrain")
            return
        var bridge: MeshInstance3D = cell.find_child("JanoahRoadBridgeDeck", true, false) as MeshInstance3D
        var deck_collider: Node = bridge.find_child("CollisionShape3D", true, false)
        if deck_collider == null:
            _fail("main river bridge is only a visual facade")
            return
    await get_tree().physics_frame
    # A standing player can cross on the bridge's physically solid deck.
    var road_probe := PhysicsRayQueryParameters3D.create(
        Vector3(15363.3, 4.0, 74.2), Vector3(15363.3, -5.0, 74.2))
    var road_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(road_probe)
    if road_hit.is_empty() or str(road_hit.get("collider").name).find("JanoahRoadBridgeDeckSolid") < 0:
        _fail("bridge road does not have physical walking collision")
        return
    # Below the non-collidable water visual is the carved physical riverbed.
    var bed_probe := PhysicsRayQueryParameters3D.create(
        Vector3(15363.3, -2.15, 74.2), Vector3(15363.3, -4.8, 74.2))
    var bed_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(bed_probe)
    if bed_hit.is_empty() or str(bed_hit.get("collider").name) != "JanoahTerrainCollision":
        _fail("carved riverbed has no physical floor")
        return
    var center_cell: Node3D = active["60:0"]
    var freight: MeshInstance3D = center_cell.find_child("FreightTrestleBridgeDeck", true, false) as MeshInstance3D
    if freight.find_child("CollisionShape3D", true, false) == null:
        _fail("rail trestle deck has no collision")
        return
    # Crossings are interrupted nowhere by decorative guard rails.
    var passage := PhysicsRayQueryParameters3D.create(
        Vector3(15303.0, 1.70, 70.0), Vector3(15417.0, 1.70, 70.0))
    if not get_world_3d().direct_space_state.intersect_ray(passage).is_empty():
        _fail("bridge rail blocks the center road line")
        return
    visitor.position = Geo.tile_center(Vector2i(53, 0)) + Vector3.UP
    region.call("_refresh_cells")
    await get_tree().physics_frame
    active = region.get("cells")
    if active.has("60:0") or not active.has("53:0") or active.size() > 9:
        _fail("the river cells fail to unload after travel")
        return
    var farmland: Node3D = active["53:0"]
    if farmland.find_child("JanoahRiverWaterSurface", true, false) != null:
        _fail("river was duplicated in a non-river farm tile")
        return
    world.queue_free()
    print("V0.56 JANOAH CARVED RIVER AND TWO WALKABLE BRIDGES PASS")
    get_tree().call_deferred("quit", 0)
