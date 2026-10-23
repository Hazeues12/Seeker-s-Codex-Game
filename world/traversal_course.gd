extends Node3D

# V0.39 — training-grade parkour course in an otherwise empty part of Ring Two.
# Colliders belong only to these new rooftops and walls; existing hub remains unchanged.
const WATER_MIN_X: float = -21.1
const WATER_MAX_X: float = -17.2
const WATER_MIN_Z: float = 12.5
const WATER_MAX_Z: float = 27.5

var water_mat: StandardMaterial3D
var animation_time: float = 0.0

func _ready() -> void:
    add_to_group("traversal_course")
    call_deferred("_make_course")

func _process(delta: float) -> void:
    animation_time += delta
    if is_instance_valid(water_mat):
        water_mat.albedo_color = Color(0.12, 0.51 + sin(animation_time * 2.5) * 0.04, 0.75, 0.84)

func is_water_at(point: Vector3) -> bool:
    return (point.x >= WATER_MIN_X and point.x <= WATER_MAX_X
        and point.z >= WATER_MIN_Z and point.z <= WATER_MAX_Z
        and point.y < 2.2)

func _mat(color: Color, transparent: bool = false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.70
    if transparent:
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    return material

func _block(label: String, at: Vector3, dimensions: Vector3, material: Material,
        collides: bool = false, is_wall: bool = false) -> void:
    var root := Node3D.new()
    root.name = label
    root.position = at
    add_child(root)
    var visual := MeshInstance3D.new()
    visual.name = "Visual"
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    visual.mesh = mesh
    visual.material_override = material
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(visual)
    if collides:
        var body := StaticBody3D.new()
        body.name = "ParkourSolid"
        if is_wall:
            body.add_to_group("traversal_wall")
        root.add_child(body)
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = dimensions
        collision.shape = shape
        body.add_child(collision)

func _sign(text_value: String, at: Vector3) -> void:
    var sign := Label3D.new()
    sign.text = text_value
    sign.font_size = 42
    sign.pixel_size = 0.006
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.no_depth_test = true
    sign.position = at
    add_child(sign)

func _make_course() -> void:
    var stone := _mat(Color(0.51, 0.59, 0.64))
    var roof := _mat(Color(0.22, 0.35, 0.46))
    var trim := _mat(Color(0.90, 0.72, 0.34))
    water_mat = _mat(Color(0.12, 0.51, 0.75, 0.84), true)

    # A narrow channel shares the canal's visual language. Ground under it remains
    # solid in this mobile prototype, so failed sprints never trap a player.
    _block("AuraWaterLane", Vector3(-19.15, 0.585, 20.0), Vector3(3.9, 0.11, 15.0), water_mat)
    for edge in [-21.35, -16.95]:
        _block("StoneCanalRim", Vector3(edge, 0.74, 20.0), Vector3(0.20, 0.37, 15.3), stone)
    _sign("WATER RUN | HOLD RUN + MOVE", Vector3(-19.2, 2.9, 13.5))

    # Parallel true collidable walls: approach a side while in the air and RUN
    # along it to enter the short wall-running state.
    _block("WestWall", Vector3(-13.8, 2.55, 19.0), Vector3(0.65, 4.1, 10.8), stone, true, true)
    _block("EastWall", Vector3(-8.7, 2.55, 19.0), Vector3(0.65, 4.1, 10.8), stone, true, true)
    _block("WestCap", Vector3(-13.8, 4.70, 19.0), Vector3(1.0, 0.22, 11.0), roof, true)
    _block("EastCap", Vector3(-8.7, 4.70, 19.0), Vector3(1.0, 0.22, 11.0), roof, true)
    _sign("WALL RUN | RUN + JUMP BY THE WALL", Vector3(-11.1, 5.6, 13.0))

    # Three reachable solid rooftops (not just decorative meshes). Double-jump
    # up the terraces and land on the roofs to reset jump count.
    _block("FirstRoof", Vector3(-6.0, 1.76, 27.0), Vector3(4.1, 2.24, 4.0), stone, true)
    _block("FirstRoofTrim", Vector3(-6.0, 2.99, 27.0), Vector3(4.4, 0.20, 4.3), trim, true)
    _block("SecondRoof", Vector3(-0.5, 2.07, 27.0), Vector3(4.1, 2.86, 4.0), stone, true)
    _block("SecondRoofTrim", Vector3(-0.5, 3.60, 27.0), Vector3(4.4, 0.20, 4.3), roof, true)
    _block("ThirdRoof", Vector3(5.0, 2.37, 27.0), Vector3(4.1, 3.46, 4.0), stone, true)
    _block("ThirdRoofTrim", Vector3(5.0, 4.20, 27.0), Vector3(4.4, 0.20, 4.3), trim, true)
    _sign("DOUBLE JUMP | REACH THE ROOFTOPS", Vector3(-1.0, 5.7, 26.5))
