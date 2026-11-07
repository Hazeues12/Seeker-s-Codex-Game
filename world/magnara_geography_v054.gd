extends Node3D
# V0.54 - streamed geographic foundation for the proposed 26 km Magnara.
# All generic blocks are structural massing, NOT finished neighborhoods.
# One Godot unit represents one meter. The old Ring Two hub occupies tile 0:0.
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const ATLAS_PATH: String = "res://data/known_world_v054.json"
const ACTIVE_TILE_RADIUS: int = 1
const MAX_ACTIVE_CELLS: int = 9

var player: Node3D
var cells: Dictionary = {}
var atlas: Dictionary = {}
var mesh_cache: Dictionary = {}
var material_cache: Dictionary = {}
var update_clock: float = 0.0

func _ready() -> void:
    add_to_group("magnara_geography_v054")
    set_process(false)
    call_deferred("_initialize")

func _initialize() -> void:
    if not is_inside_tree():
        return
    player = get_parent().get_node_or_null("Player") as Node3D
    var handle := FileAccess.open(ATLAS_PATH, FileAccess.READ)
    if handle == null:
        push_error("V0.54 geography: known-world registry is missing")
        return
    var raw: Variant = JSON.parse_string(handle.get_as_text())
    handle.close()
    if typeof(raw) != TYPE_DICTIONARY:
        push_error("V0.54 geography: malformed known-world registry")
        return
    atlas = raw
    if not is_instance_valid(player):
        push_warning("V0.54 geography waiting for existing world Player")
        return
    _refresh_cells()
    set_process(true)

func get_manifest() -> Dictionary:
    return {
        "engine_unit": "meter",
        "city": "Magnara",
        "local_tile_width_m": Geo.CELL_SIZE,
        "city_diameter_m_proposed": 26000,
        "city_center_game_only": Geo.CITY_CENTER,
        "ring_count": 7,
        "active_cell_cap": MAX_ACTIVE_CELLS,
        "legacy_scene_preserved": true,
        "generated_blocks_are_complete_city": false,
        "scope": "known world only",
    }

func get_ring_at(point: Vector3) -> int:
    return Geo.ring_for_position(point)

func get_atlas() -> Dictionary:
    return atlas.duplicate(true)

func active_cell_count() -> int:
    return cells.size()

func _process(delta: float) -> void:
    update_clock += delta
    if update_clock >= 0.55:
        update_clock = 0.0
        _refresh_cells()

func _refresh_cells() -> void:
    if not is_instance_valid(player):
        return
    var tile: Vector2i = Geo.tile_index(player.global_position)
    var wanted: Dictionary = {}
    for ix in range(-ACTIVE_TILE_RADIUS, ACTIVE_TILE_RADIUS + 1):
        for iz in range(-ACTIVE_TILE_RADIUS, ACTIVE_TILE_RADIUS + 1):
            var target := tile + Vector2i(ix, iz)
            var center: Vector3 = Geo.tile_center(target)
            if Geo.ring_for_position(center) == 0:
                continue
            var key: String = Geo.cell_id(target)
            wanted[key] = true
            if not cells.has(key):
                var cell := Node3D.new()
                cell.name = "GeographicCell_" + key.replace(":", "_").replace("-", "m")
                cell.add_to_group("known_world_stream_cell")
                add_child(cell)
                _build_tile(cell, target)
                cells[key] = cell
    # Bounded memory: at most 3x3 near the player, regardless of city diameter.
    for key in cells.keys():
        if not wanted.has(key):
            var existing: Node = cells[key]
            cells.erase(key)
            if is_instance_valid(existing):
                existing.queue_free()

func _mat(color: Color) -> StandardMaterial3D:
    var key: String = str(color)
    if material_cache.has(key):
        return material_cache[key]
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.83
    material_cache[key] = m
    return m

func _block(parent: Node3D, label: String, center: Vector3,
        dims: Vector3, shade: Color, solid: bool = false) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var key: String = str(dims)
    var geometry: BoxMesh
    if mesh_cache.has(key):
        geometry = mesh_cache[key]
    else:
        geometry = BoxMesh.new()
        geometry.size = dims
        mesh_cache[key] = geometry
    node.mesh = geometry
    node.position = center
    node.material_override = _mat(shade)
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(node)
    if solid:
        var body := StaticBody3D.new()
        body.name = label + "_Static"
        node.add_child(body)
        var collider := CollisionShape3D.new()
        var bounds := BoxShape3D.new()
        bounds.size = dims
        collider.shape = bounds
        body.add_child(collider)
    return node

func _tone(ring: int) -> Color:
    match ring:
        1: return Color(0.68, 0.66, 0.62)
        2: return Color(0.56, 0.58, 0.59)
        3: return Color(0.63, 0.59, 0.54)
        4: return Color(0.61, 0.57, 0.52)
        5: return Color(0.46, 0.47, 0.48)
        6: return Color(0.43, 0.47, 0.51)
        7: return Color(0.44, 0.43, 0.41)
    return Color(0.45, 0.47, 0.44)

func _building(parent: Node3D, ring: int, at: Vector3, index: int) -> void:
    # These are generic massing volumes, not a claim that all 531 km2 are done.
    var width: float = 22.0 if ring <= 4 else 30.0
    var depth: float = 25.0 if ring <= 4 else 32.0
    var height: float = 9.0 + float((index + ring) % 3) * 3.5
    if ring == 1:
        height += 8.0
    elif ring == 5 or ring == 6:
        height += 5.0
    var shade := _tone(ring).darkened(0.05 * float(index % 3))
    var crown := Color(0.22, 0.29, 0.34) if ring <= 4 else Color(0.26, 0.28, 0.29)
    _block(parent, "ProvisionalUrbanMass_%d" % index,
        at + Vector3(0.0, 0.50 + height * 0.5, 0.0),
        Vector3(width, height, depth), shade, true)
    _block(parent, "ProvisionalRoof_%d" % index,
        at + Vector3(0.0, 0.60 + height, 0.0),
        Vector3(width + 0.5, 0.20, depth + 0.5), crown)
    # Window rhythm gives each ring visual structure while loading cheaply.
    if ring < 6:
        for window in range(3):
            _block(parent, "Casement_%d_%d" % [index, window],
                at + Vector3(-width * 0.28 + float(window) * width * 0.28,
                    4.1, depth * 0.5 + 0.05),
                Vector3(2.1, 1.4, 0.10), Color(0.29, 0.58, 0.66))
    else:
        _block(parent, "IndustrialLoadingBay_%d" % index,
            at + Vector3(0.0, 3.1, depth * 0.5 + 0.06),
            Vector3(9.0, 5.1, 0.12), Color(0.25, 0.29, 0.30))

func _build_tile(parent: Node3D, tile: Vector2i) -> void:
    var center: Vector3 = Geo.tile_center(tile)
    var ring: int = Geo.ring_for_position(center)
    var color: Color = _tone(ring)
    # The legacy V0.33-V0.53 3D city owns its own visible surfaces near x=0.
    # This tile supplies unseen supporting terrain beneath old geometry, but
    # the terrain mesh is hidden so no duplicate floor causes visual z-fight.
    var legacy_tile: bool = tile == Vector2i.ZERO
    var ground := _block(parent, "OneToOneGround256m", center,
        Vector3(Geo.CELL_SIZE, 1.0, Geo.CELL_SIZE),
        color, true)
    if legacy_tile:
        ground.visible = false
        # Street link between V0.53's east-west avenue (x +/- 106) and
        # the new 256 m grid whose adjacent tile begins at x +/- 128.
        for side in [-1.0, 1.0]:
            _block(parent, "OldCityToGeographyStreetConnector",
                Vector3(side * 114.0, 0.545, 70.0),
                Vector3(33.0, 0.075, 8.0),
                Color(0.69, 0.65, 0.59))
        return
    var road := Color(0.70, 0.68, 0.62) if ring < 5 else Color(0.55, 0.55, 0.54)
    _block(parent, "OneToOneEastWestStreet", center + Vector3(0, 0.55, 0),
        Vector3(Geo.CELL_SIZE, 0.09, 10.0), road)
    _block(parent, "OneToOneNorthSouthStreet", center + Vector3(0, 0.55, 0),
        Vector3(10.0, 0.09, Geo.CELL_SIZE), road)
    var paving := color.lightened(0.16)
    for side in [-1.0, 1.0]:
        _block(parent, "NorthSouthPedestrianStrip",
            center + Vector3(side * 8.0, 0.55, 0.0),
            Vector3(2.35, 0.09, Geo.CELL_SIZE), paving)
        _block(parent, "EastWestPedestrianStrip",
            center + Vector3(0.0, 0.55, side * 8.0),
            Vector3(Geo.CELL_SIZE, 0.09, 2.35), paving)
    # Four light-weight urban parcels with street space between them.
    # Ring VI remains DRY: the unapproved coastline is not fabricated here.
    var positions: Array[Vector2] = [
        Vector2(-61.0, -65.0), Vector2(61.0, -65.0),
        Vector2(-61.0, 65.0), Vector2(61.0, 65.0)
    ]
    # V0.60/V0.61 have actual authored homes, workshops and streets in
    # the first northern survey tile (0:1). Do not spawn generic *solid*
    # massing over these hand-built accessible spaces.
    if tile == Vector2i(0, 1) or tile == Vector2i(0, 2):
        # V0.64 hand-built connected civic buildings extend into tile 0:2.
        # Suppress procedural solid massing here to keep doorways and street
        # continuations accessible; other tiles still generate survey blocks.
        return
    for n in range(positions.size()):
        var offset: Vector2 = positions[n]
        _building(parent, ring, center + Vector3(offset.x, 0.0, offset.y), n)
    # A low-cost wayfinding mark. Unapproved dimensions remain explicit.
    var marker := Label3D.new()
    marker.name = "SurveyRingMarker"
    marker.text = Geo.ring_label(ring) + " / SURVEY"
    marker.position = center + Vector3(17.0, 4.8, 14.0)
    marker.font_size = 35
    marker.pixel_size = 0.005
    marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    marker.no_depth_test = true
    parent.add_child(marker)
