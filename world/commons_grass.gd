extends RefCounted

const GRASS_SHADER = preload("res://shaders/commons_grass.gdshader")
const Rules = preload("res://systems/magnara_published_city_visual_rules_v076.gd")

static func tuft() -> ArrayMesh:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for blade in range(3):
        var angle: float = float(blade) * TAU / 3.0
        var lean := Vector3(cos(angle), 0.0, sin(angle))
        var edge := Vector3(-lean.z, 0.0, lean.x) * 0.043
        var root: Vector3 = lean * 0.05
        var bend: Vector3 = root + lean * 0.043 + Vector3.UP * 0.18
        var tip: Vector3 = root + lean * 0.14 + Vector3.UP * (0.30 + blade * 0.035)
        var points := [root - edge, root + edge, bend + edge * 0.55,
            root - edge, bend + edge * 0.55, bend - edge * 0.55,
            bend - edge * 0.55, bend + edge * 0.55, tip]
        var heights := [0.0, 0.0, 0.52, 0.0, 0.52, 0.52, 0.52, 0.52, 1.0]
        for i in range(points.size()):
            surface.set_uv(Vector2(0.0, heights[i]))
            surface.set_normal(Vector3.UP)
            surface.add_vertex(points[i])
    return surface.commit()


static func scatter(parent: Node3D, parks: Array, tile: Vector2i, mesh: Mesh, material: Material) -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = hash(tile)
    for lawn: Dictionary in parks:
        if lawn["color"] != Rules.COMMONS_GRASS:
            continue
        var center: Vector3 = lawn["at"]
        var size: Vector3 = lawn["size"]
        var placements: Array[Transform3D] = []
        for i in range(150):
            var point := center + Vector3(rng.randf_range(-0.47, 0.47) * size.x,
                size.y * 0.5 + 0.005, rng.randf_range(-0.47, 0.47) * size.z)
            if _paved(point, parks):
                continue
            var scale: float = rng.randf_range(0.65, 1.23)
            placements.append(Transform3D(Basis(Vector3.UP, rng.randf_range(0.0, TAU))
                .scaled(Vector3.ONE * scale), point - center))
        if placements.is_empty():
            continue
        var batch := MultiMesh.new()
        batch.transform_format = MultiMesh.TRANSFORM_3D
        batch.use_colors = true
        batch.mesh = mesh
        batch.instance_count = placements.size()
        batch.custom_aabb = AABB(Vector3(-size.x * 0.5, 0.0, -size.z * 0.5), Vector3(size.x, 0.7, size.z))
        for i in range(placements.size()):
            batch.set_instance_transform(i, placements[i])
            batch.set_instance_color(i, Color(rng.randf(), 1.0, 1.0))
        var grass := MultiMeshInstance3D.new()
        grass.name = "CommonsWindGrass"
        grass.position = center
        grass.multimesh = batch
        grass.material_override = material
        grass.visibility_range_end = 52.0
        grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        parent.add_child(grass, true)


static func _paved(point: Vector3, parks: Array) -> bool:
    for patch: Dictionary in parks:
        if patch["color"] == Rules.COMMONS_GRASS:
            continue
        var offset: Vector3 = point - patch["at"]
        var size: Vector3 = patch["size"]
        if absf(offset.x) < size.x * 0.5 + 0.25 and absf(offset.z) < size.z * 0.5 + 0.25:
            return true
    return false
