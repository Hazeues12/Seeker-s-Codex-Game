extends Node3D
# V0.74 first: build Magnara's full seven-ring urban FRAMEWORK before any
# further named canon landmark placement. 1 unit = 1 m, 26km proposed
# planning diameter. Existing detailed Ring II Seeker quarters remain intact.
# Exterior-only GPU city shells + real near-wall collision + 2km horizon;
# no claim of completed businesses, finished interiors or actual port docks.
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const Rules = preload("res://systems/magnara_seven_ring_rules_v074.gd")
const MapScript = preload("res://ui/magnara_ring_map_v074.gd")
var player: CharacterBody3D
var initialized: bool = false
var near_tiles: Dictionary = {}
var update_clock: float = 0.0
var horizon_center: Vector2i = Vector2i(999999,999999)
var skyline_specs: int = 0
var skyline_tiles: int = 0
var skyline_mesh: MultiMeshInstance3D
var ring_roads: MeshInstance3D
var city_lots: BoxMesh
var city_material: StandardMaterial3D
var roof_material: StandardMaterial3D
var facade_material: StandardMaterial3D
var road_material: StandardMaterial3D
var map_layer: CanvasLayer
var map_panel: PanelContainer
var map_label: Label
var map_control: Control
var status_label: Label
var near_colliders: int = 0
var nearby_exterior_shells: int = 0
var last_ring: int = 0

func _ready() -> void:
    add_to_group("magnara_seven_ring_foundation_v074")
    set_process(false)
    call_deferred("_setup")

func _setup() -> void:
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(player):
        push_error("V0.74 seven-ring foundation cannot locate existing Player")
        return
    city_lots = BoxMesh.new()
    city_lots.size = Vector3.ONE
    city_material = StandardMaterial3D.new()
    city_material.albedo_color = Color.WHITE
    city_material.vertex_color_use_as_albedo = true
    city_material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    city_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    city_material.roughness = 0.91
    roof_material = StandardMaterial3D.new()
    roof_material.albedo_color = Color.WHITE
    roof_material.vertex_color_use_as_albedo = true
    roof_material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    roof_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    facade_material = StandardMaterial3D.new()
    facade_material.albedo_color = Color.WHITE
    facade_material.vertex_color_use_as_albedo = true
    facade_material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    facade_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    road_material = StandardMaterial3D.new()
    road_material.vertex_color_use_as_albedo = true
    road_material.albedo_color = Color.WHITE
    road_material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    road_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    road_material.roughness = 0.93
    _build_citywide_road_frame()
    _make_skyline()
    _make_chart()
    initialized = true
    _refresh_near()
    _refresh_collision()
    _refresh_skyline(true)
    _status()
    set_process(true)

func get_manifest() -> Dictionary:
    var report: Dictionary = Rules.geometry_report()
    report["version"] = 74
    report["initialized"] = initialized
    report["rendered_ring_road_frame"] = is_instance_valid(ring_roads)
    report["ring_road_segments"] = 7*Rules.CIRCUMFERENCE_SEGMENTS
    report["radial_highway_spokes"] = Rules.RADIAL_COUNT
    report["near_tiles_loaded"] = near_tiles.size()
    report["near_tiles_budget"] = Rules.MAX_NEAR_CELLS
    report["near_exterior_buildings"] = nearby_exterior_shells
    report["physically_active_near_walls"] = near_colliders
    report["far_skyline_gpu_buildings"] = skyline_specs
    report["far_skyline_macro_tiles"] = skyline_tiles
    report["far_proxies_are_physical"] = false
    report["city_map_available"] = true
    report["ring_seven_ocean_port_is_reserved_only"] = true
    report["current_ring"] = last_ring
    return report

func is_map_open() -> bool:
    return is_instance_valid(map_panel) and map_panel.visible

func _street_quad(surface: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3,color: Color) -> void:
    for point in [a,b,c,a,c,d]:
        surface.set_normal(Vector3.UP)
        surface.set_color(color)
        surface.add_vertex(point)

func _build_citywide_road_frame() -> void:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Annular highways form all seven continuous physical-scale rings.
    # At present their painted surface sits above V0.54 streamed solid
    # terrain. They are framework roads, not bridge/landmark placement.
    for ring in range(1,8):
        var outer: float = Geo.OUTER_BOUNDS_M[ring-1]
        var radius: float = outer-36.0
        var inner: float = radius-Rules.RING_ROAD_WIDTH_M*0.5
        var outside: float = radius+Rules.RING_ROAD_WIDTH_M*0.5
        var color: Color = Color(0.49,0.53,0.57) if ring in [2,4,7] else Color(0.53,0.52,0.49)
        for segment in range(Rules.CIRCUMFERENCE_SEGMENTS):
            var a: float = TAU*float(segment)/float(Rules.CIRCUMFERENCE_SEGMENTS)
            var b: float = TAU*float(segment+1)/float(Rules.CIRCUMFERENCE_SEGMENTS)
            var vector_a := Vector2(cos(a),sin(a))
            var vector_b := Vector2(cos(b),sin(b))
            _street_quad(surface,
                _world_polar(vector_a,inner,0.615),
                _world_polar(vector_b,inner,0.615),
                _world_polar(vector_b,outside,0.615),
                _world_polar(vector_a,outside,0.615),color)
    # 12 wide radial routes connect all seven annuli without invented
    # shortcuts, teleportation, locked port connections, or coastline.
    for n in range(Rules.RADIAL_COUNT):
        var a: float = Rules.radial_angle(n)
        var outward := Vector2(cos(a),sin(a))
        var sideways := Vector2(-sin(a),cos(a))
        var half: float = Rules.RADIAL_ROAD_WIDTH_M*0.5
        var near: Vector2 = Geo.CITY_CENTER+outward*Rules.INNER_CITY_START
        var far: Vector2 = Geo.CITY_CENTER+outward*(Rules.CITY_RADIUS_M-42.0)
        _street_quad(surface,Vector3(near.x+sideways.x*half,0.620,near.y+sideways.y*half),
            Vector3(far.x+sideways.x*half,0.620,far.y+sideways.y*half),
            Vector3(far.x-sideways.x*half,0.620,far.y-sideways.y*half),
            Vector3(near.x-sideways.x*half,0.620,near.y-sideways.y*half),
            Color(0.48,0.51,0.54))
    var result: ArrayMesh = surface.commit()
    ring_roads = MeshInstance3D.new()
    ring_roads.name = "V074AllSevenRingsAndTwelveRadialAvenues"
    ring_roads.mesh = result
    ring_roads.material_override = road_material
    ring_roads.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(ring_roads)

func _world_polar(axis: Vector2,radius: float,height: float) -> Vector3:
    return Vector3(Geo.CITY_CENTER.x+axis.x*radius,
        height,Geo.CITY_CENTER.y+axis.y*radius)

func _make_skyline() -> void:
    skyline_mesh = MultiMeshInstance3D.new()
    skyline_mesh.name = "V074TwoKilometerLongRangeCitySkylineGPU"
    skyline_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    skyline_mesh.material_override = city_material
    skyline_mesh.custom_aabb = AABB(
        Vector3(-14000,-4,-14000),Vector3(28000,180,28000))
    add_child(skyline_mesh)

func _gpu(parent: Node3D,label: String, specs: Array,
        style: StandardMaterial3D) -> MultiMeshInstance3D:
    var batch := MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.use_colors = true
    batch.mesh = city_lots
    batch.instance_count = specs.size()
    for n in range(specs.size()):
        var item: Dictionary = specs[n]
        batch.set_instance_transform(n,
            Transform3D(Basis.IDENTITY.scaled(item["size"]),item["at"]))
        batch.set_instance_color(n,item["color"])
    var mesh := MultiMeshInstance3D.new()
    mesh.name = label
    mesh.multimesh = batch
    mesh.material_override = style
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(mesh)
    return mesh

func _near_tile(tile: Vector2i) -> void:
    var key: String = Geo.cell_id(tile)
    if near_tiles.has(key):
        return
    var specs: Array[Dictionary] = Rules.tile_slots(tile)
    var chunk := Node3D.new()
    chunk.name = "V074UrbanBlock_"+key.replace(":","_").replace("-","m")
    chunk.position = Geo.tile_center(tile)
    chunk.add_to_group("v074_ring_neighborhood_chunk")
    add_child(chunk)
    var walls: Array = []
    var roofs: Array = []
    var windows: Array = []
    var ledges: Array = []
    for spec in specs:
        var at: Vector3 = spec["local_pos"]
        var height: float = float(spec["height"])
        var width: float = float(spec["width"])
        var depth: float = float(spec["depth"])
        var shade: Color = spec["palette"]
        walls.append({"at":at+Vector3(0,0.52+height*0.5,0),
            "size":Vector3(width,height,depth),
            "color":shade.darkened(0.04*float(int(height)%3))})
        roofs.append({"at":at+Vector3(0,0.52+height+0.14,0),
            "size":Vector3(width+0.65,0.28,depth+0.65),
            "color":Color(0.25,0.29,0.31) if int(spec["ring"]) <= 4 \
                else Color(0.33,0.32,0.29)})
        for bay in range(2):
            windows.append({"at":at+Vector3(
                -width*0.21+float(bay)*width*0.42,3.4,depth*0.5+0.11),
                "size":Vector3(2.4,1.70,0.19),
                "color":Color(0.37,0.59,0.64)})
        ledges.append({"at":at+Vector3(0,3.2,0),
            "size":Vector3(width+0.12,0.20,depth+0.12),
            "color":shade.darkened(0.27)})
    _gpu(chunk,"V074RingWallsGPU",walls,city_material)
    _gpu(chunk,"V074RingRoofsGPU",roofs,roof_material)
    _gpu(chunk,"V074RingCasementsGPU",windows,facade_material)
    _gpu(chunk,"V074RingHorizontalCoursesGPU",ledges,city_material)
    near_tiles[key]={"node":chunk,"cell":tile,"sites":specs,"colliders":{}}

func _refresh_near() -> void:
    if not initialized:
        return
    var current: Vector2i = Geo.tile_index(player.global_position)
    var wanted: Dictionary = {}
    var created: int = 0
    for x in range(-Rules.NEAR_CELL_RADIUS,Rules.NEAR_CELL_RADIUS+1):
        for z in range(-Rules.NEAR_CELL_RADIUS,Rules.NEAR_CELL_RADIUS+1):
            var tile := current+Vector2i(x,z)
            if Geo.ring_for_position(Geo.tile_center(tile)) == 0:
                continue
            var id: String = Geo.cell_id(tile)
            wanted[id] = true
            if not near_tiles.has(id) and created < Rules.LOAD_BUDGET:
                _near_tile(tile)
                created += 1
    for key in near_tiles.keys():
        if not wanted.has(key):
            var old: Node3D = near_tiles[key]["node"]
            near_tiles.erase(key)
            if is_instance_valid(old):
                old.queue_free()
    nearby_exterior_shells = 0
    for key in near_tiles.keys():
        nearby_exterior_shells += near_tiles[key]["sites"].size()

func _add_collider(chunk: Dictionary,spec: Dictionary) -> void:
    var body := StaticBody3D.new()
    body.name = "V074NearSolidLot_"+str(spec["id"]).replace(":","_")
    var at: Vector3 = spec["local_pos"]
    body.position = at+Vector3(0,0.52+float(spec["height"])*0.5,0)
    body.add_to_group("v074_physical_outer_ring_building")
    (chunk["node"] as Node3D).add_child(body)
    var hit := CollisionShape3D.new()
    hit.name = "V074CollisionForRealNearBuilding"
    var shape := BoxShape3D.new()
    shape.size = Vector3(float(spec["width"]),float(spec["height"]),
        float(spec["depth"]))
    hit.shape = shape
    body.add_child(hit)
    chunk["colliders"][str(spec["id"])] = body

func _refresh_collision() -> void:
    if not initialized:
        return
    var budget: int = Rules.MAX_CLOSE_COLLIDERS
    var count: int = 0
    for key in near_tiles.keys():
        var chunk: Dictionary = near_tiles[key]
        var existing: Dictionary = chunk["colliders"]
        var eligible: Dictionary = {}
        for spec in chunk["sites"]:
            var at: Vector3 = spec["world_pos"]
            if at.distance_to(player.global_position) < Rules.CLOSE_COLLIDER_M \
                    and count < budget:
                eligible[str(spec["id"])] = true
                if not existing.has(str(spec["id"])):
                    _add_collider(chunk,spec)
                count += 1
        for id in existing.keys():
            if not eligible.has(id):
                var old: StaticBody3D = existing[id]
                existing.erase(id)
                if is_instance_valid(old):
                    old.queue_free()
    near_colliders = count

func _refresh_skyline(force: bool = false) -> void:
    if not initialized:
        return
    var macro: Vector2i = Rules.far_cell(player.global_position)
    if not force and macro == horizon_center:
        return
    horizon_center = macro
    var wanted: Array[Vector2i] = Rules.far_wanted(player.global_position)
    var entries: Array = []
    for cell in wanted:
        var bunch: Array[Dictionary] = Rules.far_specs(cell)
        for entry in bunch:
            if (entry["world_pos"] as Vector3).distance_to(player.global_position) > 370.0:
                entries.append({"at":entry["world_pos"],
                    "size":entry["size"],"color":entry["color"]})
    skyline_tiles = wanted.size()
    skyline_specs = entries.size()
    # A SINGLE MultiMeshInstance3D for the entire 2km distant silhouette.
    var bundle := MultiMesh.new()
    bundle.transform_format = MultiMesh.TRANSFORM_3D
    bundle.use_colors = true
    bundle.mesh = city_lots
    bundle.instance_count = entries.size()
    for n in range(entries.size()):
        var entry: Dictionary = entries[n]
        bundle.set_instance_transform(n,
            Transform3D(Basis.IDENTITY.scaled(entry["size"]),entry["at"]))
        bundle.set_instance_color(n,entry["color"])
    skyline_mesh.multimesh = bundle

func _make_chart() -> void:
    map_layer = CanvasLayer.new()
    map_layer.name = "V074SevenRingCityMapLayer"
    map_layer.layer = 41
    get_parent().add_child(map_layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    map_layer.add_child(root)
    var map_button := Button.new()
    map_button.name = "V074CityMapButton"
    map_button.text = "CITY MAP"
    map_button.anchor_left = 0.83
    map_button.anchor_right = 0.97
    map_button.anchor_top = 0.015
    map_button.anchor_bottom = 0.09
    map_button.custom_minimum_size = Vector2(104,40)
    map_button.pressed.connect(_toggle_map)
    root.add_child(map_button)

    status_label = Label.new()
    status_label.name = "V074CurrentCityScaleHUD"
    status_label.anchor_left = 0.42
    status_label.anchor_right = 0.82
    status_label.anchor_top = 0.025
    status_label.anchor_bottom = 0.09
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_font_size_override("font_size",16)
    status_label.text = "MAGNARA / SEVEN RINGS / 26 KM"
    root.add_child(status_label)

    map_panel = PanelContainer.new()
    map_panel.name = "V074ScaledSevenRingAtlas"
    map_panel.anchor_left = 0.05
    map_panel.anchor_right = 0.95
    map_panel.anchor_top = 0.08
    map_panel.anchor_bottom = 0.94
    map_panel.visible = false
    map_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.045,0.073,0.093,0.988)
    panel_style.border_color = Color(0.60,0.65,0.71)
    panel_style.set_border_width_all(2)
    panel_style.set_corner_radius_all(10)
    map_panel.add_theme_stylebox_override("panel",panel_style)
    root.add_child(map_panel)
    var margin := MarginContainer.new()
    for side in ["top","left","right","bottom"]:
        margin.add_theme_constant_override("margin_"+side,12)
    map_panel.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation",4)
    margin.add_child(stack)
    var heading := Label.new()
    heading.text = "MAGNARA / ALL SEVEN RINGS / 26 KM CITY PLAN"
    heading.add_theme_font_size_override("font_size",23)
    heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(heading)
    map_label = Label.new()
    map_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    map_label.add_theme_font_size_override("font_size",14)
    stack.add_child(map_label)
    var chart := MapScript.new()
    chart.name = "V074ToScaleCityRings"
    chart.player = player
    chart.custom_minimum_size = Vector2(200,220)
    chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
    chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stack.add_child(chart)
    map_control = chart
    var explanation := Label.new()
    explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    explanation.add_theme_font_size_override("font_size",13)
    explanation.text = "26 km diameter / 531 km² planning envelope. Streets and ring zones are playable foundation geometry. Ring VII has the MAIN SEA PORT reserve; Ring II only small canal landings. The coastline, landmarks and national routes are still unplaced."
    stack.add_child(explanation)
    var close := Button.new()
    close.name = "V074CloseCityMap"
    close.text = "RETURN TO MAGNARA"
    close.custom_minimum_size.y = 43
    close.pressed.connect(_close_map)
    stack.add_child(close)

func _toggle_map() -> void:
    if map_panel.visible:
        _close_map()
    else:
        _status()
        map_panel.show()

func _close_map() -> void:
    if is_instance_valid(map_panel):
        map_panel.hide()

func _status() -> void:
    last_ring = Rules.ring_at(player.global_position)
    if is_instance_valid(status_label):
        status_label.text = "MAGNARA • RING %d/7 • 26 KM" % last_ring \
            if last_ring > 0 else "BEYOND PROPOSED CITY / 26 KM"
    if is_instance_valid(map_label):
        var r: float = Geo.radial_m(player.global_position)
        map_label.text = "YOU: %s | %.2f km from survey center | %.1f km² total" % [
            Rules.ring_title(last_ring),r/1000.0,
            Geo.circular_envelope_area_km2(26.0)]

func _process(delta: float) -> void:
    update_clock += delta
    if update_clock >= Rules.TICK_SECONDS:
        update_clock = 0.0
        _refresh_near()
        _refresh_collision()
        _refresh_skyline()
        if is_map_open() or last_ring != Rules.ring_at(player.global_position):
            _status()
