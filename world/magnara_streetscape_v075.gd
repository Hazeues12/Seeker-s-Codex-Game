extends Node3D
# V0.75 add localized street-life structure to all seven already built
# V0.74 zones, without inventing story canon: roads, façades, rooflines,
# wayfinding and actual 84 radial-ring junctions across a 26km envelope.
# The old Ring II city, public canals, shops and all save data survive.
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const City = preload("res://systems/magnara_seven_ring_rules_v074.gd")
const Detail = preload("res://systems/magnara_streetscape_rules_v075.gd")
var player: CharacterBody3D
var framework: Node3D
var initialized: bool = false
var styled_tiles: Dictionary = {}
var junction_nodes: Dictionary = {}
var render_clock: float = 0.0
var last_near_count: int = 0
var local_street_segments: int = 0
var roof_variants: int = 0
var window_courses: int = 0
var active_junctions: int = 0
var street_material: StandardMaterial3D
var roof_material: StandardMaterial3D
var window_material: StandardMaterial3D
var lot_cube: BoxMesh

func _ready() -> void:
    add_to_group("magnara_connected_streets_v075")
    set_process(false)
    call_deferred("_setup")

func _setup() -> void:
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    framework = get_tree().get_first_node_in_group("magnara_seven_ring_foundation_v074") as Node3D
    if not is_instance_valid(player) or not is_instance_valid(framework):
        return
    if not bool(framework.get("initialized")):
        call_deferred("_setup")
        return
    street_material = StandardMaterial3D.new()
    street_material.vertex_color_use_as_albedo = true
    street_material.albedo_color = Color.WHITE
    street_material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    street_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    street_material.cull_mode = BaseMaterial3D.CULL_DISABLED
    street_material.roughness = 0.93
    roof_material = framework.get("city_material") as StandardMaterial3D
    window_material = framework.get("facade_material") as StandardMaterial3D
    lot_cube = framework.get("city_lots") as BoxMesh
    initialized = true
    _refresh_tiles()
    _refresh_junctions()
    set_process(true)

func get_manifest() -> Dictionary:
    var report: Dictionary = Detail.manifest()
    report["initialized"] = initialized
    report["physically_loaded_near_tiles"] = styled_tiles.size()
    report["local_street_segments_visible"] = local_street_segments
    report["roof_crown_variants_visible"] = roof_variants
    report["facade_variants_visible"] = window_courses
    report["active_road_intersections"] = active_junctions
    report["parent_city_loaded_near_tiles"] = last_near_count
    report["published_ring_two_objects_changed"] = false
    report["decorative_street_meshes_are_static_ground_overlays"] = true
    report["uses_original_physical_geography_ground"] = true
    report["new_canon_landmarks"] = 0
    return report

func _quad(tool: SurfaceTool, x0: float, z0: float,
        x1: float, z1: float, height: float, shade: Color) -> void:
    var a := Vector3(x0,height,z0)
    var b := Vector3(x1,height,z0)
    var c := Vector3(x1,height,z1)
    var d := Vector3(x0,height,z1)
    for point in [a,b,c,a,c,d]:
        tool.set_normal(Vector3.UP)
        tool.set_color(shade)
        tool.add_vertex(point)

func _street_mesh(parent: Node3D,tile: Vector2i) -> int:
    var specs: Array[Dictionary] = Detail.street_specs(tile)
    if specs.is_empty():
        return 0
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for spec in specs:
        var at: Vector3 = spec["local_pos"]
        var dims: Vector3 = spec["dims"]
        var tint: Color = spec["tint"]
        var road_y: float = Detail.ROAD_RENDER_Y if spec["axis"] == "north_south" \
            else Detail.ROAD_ACCENT_Y
        _quad(tool,at.x-dims.x*0.5,at.z-dims.z*0.5,
            at.x+dims.x*0.5,at.z+dims.z*0.5,road_y,tint)
        # Light pedestrian shoulder lines follow each local road. Their
        # physics is the same 256m-wide V0.54 solid ground, not false
        # double-thickness colliders that block jumping or running.
        if spec["axis"] == "north_south":
            for side in [-1.0,1.0]:
                var x: float = at.x+side*(dims.x*0.5+Detail.FOOTPATH_WIDTH_M*0.5)
                _quad(tool,x-Detail.FOOTPATH_WIDTH_M*0.5,
                    at.z-dims.z*0.5,x+Detail.FOOTPATH_WIDTH_M*0.5,
                    at.z+dims.z*0.5,Detail.ROAD_ACCENT_Y+0.008,
                    Detail.PEDESTRIAN_COLOR)
        else:
            for side in [-1.0,1.0]:
                var z: float = at.z+side*(dims.z*0.5+Detail.FOOTPATH_WIDTH_M*0.5)
                _quad(tool,at.x-dims.x*0.5,
                    z-Detail.FOOTPATH_WIDTH_M*0.5,at.x+dims.x*0.5,
                    z+Detail.FOOTPATH_WIDTH_M*0.5,
                    Detail.ROAD_ACCENT_Y+0.008,Detail.PEDESTRIAN_COLOR)
    var mesh := MeshInstance3D.new()
    mesh.name = "V075ContinuousInterBuildingStreetsGPU"
    mesh.mesh = tool.commit()
    mesh.material_override = street_material
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(mesh)
    return specs.size()

func _gpu(parent: Node3D,label: String,entries: Array,
        material: StandardMaterial3D) -> void:
    var mesh := MultiMesh.new()
    mesh.transform_format = MultiMesh.TRANSFORM_3D
    mesh.use_colors = true
    mesh.mesh = lot_cube
    mesh.instance_count = entries.size()
    for i in range(entries.size()):
        var item: Dictionary = entries[i]
        mesh.set_instance_transform(i,Transform3D(
            Basis.IDENTITY.scaled(item["size"]),item["at"]))
        mesh.set_instance_color(i,item["color"])
    var graphics := MultiMeshInstance3D.new()
    graphics.name = label
    graphics.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    graphics.material_override = material
    graphics.multimesh = mesh
    parent.add_child(graphics)

func _decorate(key: String,chunk: Dictionary) -> void:
    if styled_tiles.has(key):
        return
    var original: Node3D = chunk["node"] as Node3D
    if not is_instance_valid(original):
        return
    var tile: Vector2i = chunk["cell"]
    var root := Node3D.new()
    root.name = "V075StreetAndSkylineArchitecture"
    root.add_to_group("v075_game_only_streetscape")
    original.add_child(root)
    var strips: int = _street_mesh(root,tile)
    var crowns: Array[Dictionary] = Detail.rooftops(tile)
    var facades: Array[Dictionary] = Detail.street_facades(tile)
    _gpu(root,"V075ProvisionalRoofCrownShapesGPU",crowns,roof_material)
    _gpu(root,"V075ProvisionalFacadeReliefGPU",facades,window_material)
    styled_tiles[key] = {"root":root,"tile":tile,
        "streets":strips,"rooflines":crowns.size(),"facades":facades.size()}

func _refresh_tiles() -> void:
    if not initialized:
        return
    var tiles: Dictionary = framework.get("near_tiles")
    last_near_count = tiles.size()
    for key in styled_tiles.keys():
        var item: Dictionary = styled_tiles[key]
        if not tiles.has(key) or not is_instance_valid(item["root"]):
            styled_tiles.erase(key)
    for key in tiles.keys():
        if not styled_tiles.has(key):
            _decorate(str(key),tiles[key])
    local_street_segments = 0
    roof_variants = 0
    window_courses = 0
    for key in styled_tiles.keys():
        var current: Dictionary = styled_tiles[key]
        local_street_segments += int(current["streets"])
        roof_variants += int(current["rooflines"])
        window_courses += int(current["facades"])

func _mat(tint: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = tint
    m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    m.roughness = 0.90
    m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    return m

func _sign(spec: Dictionary) -> Node3D:
    var pole := Node3D.new()
    pole.name = "V075RealRingRadialJunction_"+str(spec["id"])
    pole.global_position = spec["sign_world"]
    pole.add_to_group("v075_real_ring_junction_marker")
    add_child(pole)
    # No collision: signs sit beside avenues, not across parkour lanes.
    var shaft := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(0.22,3.7,0.26)
    shaft.mesh = box
    shaft.position.y = 2.10
    shaft.material_override = _mat(Color(0.39,0.43,0.43))
    pole.add_child(shaft)
    var placard := MeshInstance3D.new()
    var slab := BoxMesh.new()
    slab.size = Vector3(2.6,0.84,0.24)
    placard.mesh = slab
    placard.position = Vector3(0.9,3.60,0)
    placard.material_override = _mat(Color(0.39,0.44,0.49))
    pole.add_child(placard)
    var label := Label3D.new()
    label.name = "V075LocalRoadJunctionSurveySign"
    label.text = str(spec["public_title"])+" / MASTERPLAN"
    label.position = Vector3(0.95,3.66,0.20)
    label.font_size = 32
    label.pixel_size = 0.004
    label.no_depth_test = false
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    pole.add_child(label)
    return pole

func _refresh_junctions() -> void:
    if not initialized:
        return
    var wanted: Dictionary = {}
    var list: Array[Dictionary] = Detail.junction_near(player.global_position)
    for spec in list:
        var id: String = str(spec["id"])
        wanted[id] = true
        if not junction_nodes.has(id):
            junction_nodes[id] = _sign(spec)
    for key in junction_nodes.keys():
        if not wanted.has(key):
            var node: Node3D = junction_nodes[key]
            junction_nodes.erase(key)
            if is_instance_valid(node):
                node.queue_free()
    active_junctions = junction_nodes.size()

func _process(delta: float) -> void:
    if not initialized:
        return
    render_clock += delta
    if render_clock > 0.68:
        render_clock = 0.0
        _refresh_tiles()
        _refresh_junctions()
