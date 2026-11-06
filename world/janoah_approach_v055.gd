extends Node3D

# V0.55 — physical Janoah approaches, connected to Magnara's provisional
# eastward game axis. This direction does NOT establish canonical compass
# geography or a road to any named non-Janoan settlement.
# Terrain is height-field mesh + actual triangle collision, not a flat picture.
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const FIRST_TILE_X: int = 45
const LAST_TILE_X: int = 68
const MAX_SIDE_TILE: int = 1
const ACTIVE_RADIUS: int = 1
const MAX_ACTIVE_CELLS: int = 9
const SAMPLES_PER_SIDE: int = 16
const ROUTE_Z: float = 70.0
const EAST_EDGE_CITY_M: float = 11392.0
const REGION_LIMIT_M: float = 17536.0

var player: Node3D
var cells: Dictionary = {}
var tick_clock: float = 0.0
var materials: Dictionary = {}
var box_meshes: Dictionary = {}
var cylinder_mesh: CylinderMesh
var foliage_mesh: SphereMesh

func _ready() -> void:
    add_to_group("janoah_approach_v055")
    set_process(false)
    call_deferred("_initialize")

func _initialize() -> void:
    player = get_parent().get_node_or_null("Player") as Node3D
    if not is_instance_valid(player):
        push_warning("V0.55 regional terrain requires the existing main-scene Player")
        return
    _refresh_cells()
    set_process(true)

func get_manifest() -> Dictionary:
    return {
        "region": "Janoah / Magnara approach",
        "status": "game_only_local_alignment",
        "physical_heightfield": true,
        "tile_width_m": Geo.CELL_SIZE,
        "first_tile": FIRST_TILE_X,
        "last_tile": LAST_TILE_X,
        "corridor_start_m": EAST_EDGE_CITY_M,
        "corridor_end_m": REGION_LIMIT_M,
        "corridor_length_m": REGION_LIMIT_M - EAST_EDGE_CITY_M,
        "physical_terrain_wide_m": 768,
        "nearby_cell_cap": MAX_ACTIVE_CELLS,
        "vehicle_rails": "unboardable route infrastructure",
        "named_country_borders": false,
        "regional_settlement_coordinates": false,
        "citadel_and_original_hub_unchanged": true,
    }

static func eligible_tile(tile: Vector2i) -> bool:
    return tile.x >= FIRST_TILE_X and tile.x <= LAST_TILE_X and absi(tile.y) <= MAX_SIDE_TILE

static func safe_approach_save(point: Vector3) -> bool:
    return is_finite(point.x) and is_finite(point.y) and is_finite(point.z) \
        and point.x >= EAST_EDGE_CITY_M and point.x < REGION_LIMIT_M \
        and absf(point.z - ROUTE_Z) < 384.0 \
        and point.y >= -2.0 and point.y < 35.0

static func height_at(world_x: float, world_z: float) -> float:
    # Continuous at tile seams; the first city-border edge stays at y=0.5.
    var from_gate: float = clampf((world_x - EAST_EDGE_CITY_M) / 100.0, 0.0, 1.0)
    var road_distance: float = minf(absf(world_z - ROUTE_Z), absf(world_z - (ROUTE_Z + 27.0)))
    var away_from_transport: float = clampf((road_distance - 15.0) / 60.0, 0.0, 1.0)
    var contour: float = 3.4 + sin(world_x * 0.007) * 1.5 \
        + cos(world_z * 0.010) * 1.4 + sin((world_x + world_z) * 0.004) * 1.3
    return 0.50 + maxf(0.0, contour) * away_from_transport * from_gate

static func phase_for_tile(tile: Vector2i) -> String:
    if tile.x < 49:
        return "industrial_outskirts"
    if tile.x < 57:
        return "farmed_countryside"
    return "rolling_interior_route"

func _process(delta: float) -> void:
    tick_clock += delta
    if tick_clock > 0.6:
        tick_clock = 0.0
        _refresh_cells()

func _refresh_cells() -> void:
    if not is_instance_valid(player):
        return
    var focus: Vector2i = Geo.tile_index(player.global_position)
    var wanted: Dictionary = {}
    for xstep in range(-ACTIVE_RADIUS, ACTIVE_RADIUS + 1):
        for zstep in range(-ACTIVE_RADIUS, ACTIVE_RADIUS + 1):
            var tile: Vector2i = focus + Vector2i(xstep, zstep)
            if not eligible_tile(tile):
                continue
            var key: String = Geo.cell_id(tile)
            wanted[key] = true
            if not cells.has(key):
                var cell := Node3D.new()
                cell.name = "JanoahRegionalCell_" + key.replace(":", "_")
                cell.add_to_group("janoah_terrain_stream_cell")
                cell.position = Geo.tile_center(tile)
                add_child(cell)
                _build_cell(cell, tile)
                cells[key] = cell
    for old_key in cells.keys():
        if not wanted.has(old_key):
            var old_cell: Node = cells[old_key]
            cells.erase(old_key)
            if is_instance_valid(old_cell):
                old_cell.queue_free()

func active_cell_count() -> int:
    return cells.size()

func _material(color: Color) -> StandardMaterial3D:
    var key: String = str(color)
    if material_cache_has(key):
        return materials[key]
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.92
    materials[key] = m
    return m

func material_cache_has(key: String) -> bool:
    return materials.has(key)

func _block(parent: Node3D, label: String, local_at: Vector3, size: Vector3, shade: Color,
        solid: bool = false) -> MeshInstance3D:
    var visual := MeshInstance3D.new()
    visual.name = label
    var key: String = str(size)
    var mesh: BoxMesh
    if box_meshes.has(key):
        mesh = box_meshes[key]
    else:
        mesh = BoxMesh.new()
        mesh.size = size
        box_meshes[key] = mesh
    visual.mesh = mesh
    visual.material_override = _material(shade)
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    visual.position = local_at
    parent.add_child(visual)
    if solid:
        var body := StaticBody3D.new()
        body.name = label + "Solid"
        visual.add_child(body)
        var collision := CollisionShape3D.new()
        var volume := BoxShape3D.new()
        volume.size = size
        collision.shape = volume
        body.add_child(collision)
    return visual

func _terrain(parent: Node3D, tile: Vector2i) -> void:
    var scene_center: Vector3 = Geo.tile_center(tile)
    var generator := SurfaceTool.new()
    generator.begin(Mesh.PRIMITIVE_TRIANGLES)
    var faces := PackedVector3Array()
    for ix in range(SAMPLES_PER_SIDE):
        for iz in range(SAMPLES_PER_SIDE):
            var dx: float = Geo.CELL_SIZE / float(SAMPLES_PER_SIDE)
            var xx: float = -Geo.CELL_SIZE * 0.5 + float(ix) * dx
            var zz: float = -Geo.CELL_SIZE * 0.5 + float(iz) * dx
            var a := Vector3(xx, height_at(scene_center.x + xx, scene_center.z + zz), zz)
            var b := Vector3(xx + dx, height_at(scene_center.x + xx + dx, scene_center.z + zz), zz)
            var c := Vector3(xx, height_at(scene_center.x + xx, scene_center.z + zz + dx), zz + dx)
            var d := Vector3(xx + dx, height_at(scene_center.x + xx + dx, scene_center.z + zz + dx), zz + dx)
            for vertex in [a, c, b, b, c, d]:
                generator.add_vertex(vertex)
                faces.append(vertex)
    generator.generate_normals()
    var mesh: ArrayMesh = generator.commit()
    var visual := MeshInstance3D.new()
    visual.name = "JanoahRegionalTerrainSurface"
    visual.mesh = mesh
    visual.material_override = _material(_terrain_tint(phase_for_tile(tile)))
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(visual)
    var physics := StaticBody3D.new()
    physics.name = "JanoahTerrainCollision"
    parent.add_child(physics)
    var collision := CollisionShape3D.new()
    var triangles := ConcavePolygonShape3D.new()
    triangles.set_faces(faces)
    collision.shape = triangles
    physics.add_child(collision)

func _terrain_tint(phase: String) -> Color:
    match phase:
        "industrial_outskirts": return Color(0.46, 0.47, 0.41)
        "farmed_countryside": return Color(0.42, 0.52, 0.35)
        _: return Color(0.40, 0.47, 0.39)

func _label(parent: Node3D, msg: String, at: Vector3) -> void:
    var display := Label3D.new()
    display.name = "RouteSign"
    display.text = msg
    display.position = at
    display.font_size = 37
    display.pixel_size = 0.005
    display.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    display.no_depth_test = true
    parent.add_child(display)

func _add_tree(parent: Node3D, local_x: float, local_z: float, center: Vector3) -> void:
    var stem_height: float = 4.0
    var ground_y: float = height_at(center.x + local_x, center.z + local_z)
    _block(parent, "CountryTreeTrunk", Vector3(local_x, ground_y + stem_height * 0.5, local_z),
        Vector3(0.72, stem_height, 0.72), Color(0.30, 0.24, 0.19), true)
    if foliage_mesh == null:
        foliage_mesh = SphereMesh.new()
        foliage_mesh.radius = 2.35
        foliage_mesh.height = 4.1
        foliage_mesh.radial_segments = 7
        foliage_mesh.rings = 4
    var leaves := MeshInstance3D.new()
    leaves.name = "CountryFoliage"
    leaves.mesh = foliage_mesh
    leaves.material_override = _material(Color(0.25, 0.40, 0.29))
    leaves.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    leaves.position = Vector3(local_x, ground_y + stem_height + 1.2, local_z)
    parent.add_child(leaves)

func _waystation(parent: Node3D, tile: Vector2i) -> void:
    # Empty roadside shelter, not a canon town, shop NPC, or instant transfer.
    var shade := Color(0.43, 0.36, 0.27)
    _block(parent, "PublicWaystationPlatform", Vector3(15.0, 0.63, -23.0),
        Vector3(14.0, 0.30, 9.0), Color(0.56, 0.55, 0.48), true)
    _block(parent, "ShelterRoof", Vector3(15.0, 3.25, -23.0),
        Vector3(13.5, 0.33, 8.0), shade, true)
    for sx in [-5.5, 5.5]:
        for sz in [-3.0, 3.0]:
            _block(parent, "ShelterPost", Vector3(15.0 + sx, 2.0, -23.0 + sz),
                Vector3(0.38, 2.9, 0.38), shade, true)
    _block(parent, "WaitingBench", Vector3(15.0, 1.13, -25.0),
        Vector3(4.2, 0.65, 1.0), Color(0.39, 0.29, 0.20), true)
    _label(parent, "JANOAH ROAD STAGE / GAME-ONLY",
        Vector3(15.0, 4.30, -23.0))

func _build_cell(parent: Node3D, tile: Vector2i) -> void:
    _terrain(parent, tile)
    var phase: String = phase_for_tile(tile)
    # A continuous road begins precisely where the dry outer city grid ends.
    _block(parent, "JanoahThroughRoad", Vector3(0.0, 0.55, 0.0),
        Vector3(Geo.CELL_SIZE, 0.09, 14.0), Color(0.61, 0.56, 0.47))
    for side in [-1.0, 1.0]:
        _block(parent, "JanoahRoadShoulder", Vector3(0.0, 0.54, side * 9.8),
            Vector3(Geo.CELL_SIZE, 0.06, 4.2), Color(0.56, 0.48, 0.38))
    # A rail/freight alignment without an operating train or promised station.
    _block(parent, "FreightBallast", Vector3(0.0, 0.55, 27.0),
        Vector3(Geo.CELL_SIZE, 0.08, 8.0), Color(0.43, 0.43, 0.43))
    for rail_side in [-1.0, 1.0]:
        _block(parent, "FreightRail", Vector3(0.0, 0.63, 27.0 + rail_side * 1.05),
            Vector3(Geo.CELL_SIZE, 0.14, 0.18), Color(0.43, 0.35, 0.25))
    for tie in range(16):
        _block(parent, "FreightSleeper", Vector3(-120.0 + float(tie) * 16.0, 0.61, 27.0),
            Vector3(0.50, 0.08, 4.20), Color(0.29, 0.28, 0.27))
    var center: Vector3 = Geo.tile_center(tile)
    for n in range(10):
        var lx: float = float(posmod(tile.x * 31 + n * 73, 202)) - 101.0
        var dz: float = 52.0 + float(posmod(tile.x * 17 + n * 41, 60))
        var lz: float = dz if n % 2 == 0 else -dz
        if absf(lx) < 12.0 and tile.x % 6 == 0:
            continue
        _add_tree(parent, lx, lz, center)
    if phase == "industrial_outskirts":
        # Lightweight retaining walls and cargo siding, no invented factory name.
        for n in range(4):
            _block(parent, "ApproachFreightStack", Vector3(-70.0 + float(n) * 32.0, 1.4, 43.0),
                Vector3(12.0, 1.8, 10.0), Color(0.42, 0.40, 0.37), true)
    elif phase == "farmed_countryside":
        # Irrigated beds reflect rural production; no invented crop taxonomy.
        for n in range(5):
            _block(parent, "CultivatedStrip", Vector3(-90.0 + float(n) * 37.0, 0.65, -39.0),
                Vector3(19.0, 0.25, 11.0), Color(0.37, 0.42, 0.30))
    else:
        # Rocky roadside outcrops in a gentle lowland hill area.
        for n in range(3):
            var outcrop_x: float = -64.0 + float(n) * 58.0
            var outcrop_z: float = -67.0
            var ground_y: float = height_at(center.x + outcrop_x, center.z + outcrop_z)
            _block(parent, "RoadsideStoneOutcrop",
                Vector3(outcrop_x, ground_y + 0.75, outcrop_z),
                Vector3(8.0, 1.50, 7.0), Color(0.52, 0.54, 0.52), true)
    if tile.y == 0 and tile.x in [48, 55, 63]:
        _waystation(parent, tile)
    if tile.y == 0 and tile.x % 4 == 0:
        _label(parent, "JANOAH APPROACH / %s / SURVEY" % phase.to_upper().replace("_", " "),
            Vector3(0.0, 5.5, -14.0))
