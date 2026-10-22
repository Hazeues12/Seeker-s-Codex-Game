extends Node3D

# V0.37: inexpensive cosmetic district dressing. No navigation/collision changes.
# Canal & facades are decorative; full Magnara city simulation is a later milestone.
var stone: StandardMaterial3D
var slate: StandardMaterial3D
var roof: StandardMaterial3D
var glass: StandardMaterial3D
var canal: StandardMaterial3D
var gold: StandardMaterial3D

func _ready() -> void:
    call_deferred("_make_district")

func _make_district() -> void:
    stone = _mat(Color(0.53, 0.55, 0.57))
    slate = _mat(Color(0.33, 0.39, 0.45))
    roof = _mat(Color(0.20, 0.29, 0.38))
    glass = _mat(Color(0.37, 0.65, 0.77))
    canal = _mat(Color(0.12, 0.44, 0.59))
    gold = _mat(Color(0.91, 0.71, 0.38))
    # Set beyond the busy central path: original guild board, herbs, Hanami and arena are untouched.
    _block("CanalBed", Vector3(-22, 0.59, -1), Vector3(3.2, 0.07, 47), canal)
    for bank in [-24.0, -20.0]:
        _block("CanalBank", Vector3(bank, 0.79, -1), Vector3(0.45, 0.43, 47), stone)
    for z in [-13.0, 7.0]:
        _block("StoneBridge", Vector3(-22, 0.91, z), Vector3(6.8, 0.25, 3.1), stone)
        for side in [-1.35, 1.35]:
            _block("BridgeRail", Vector3(-22, 1.29, z + side), Vector3(6.9, 0.34, 0.28), slate)
    for i in range(6):
        var z: float = -23.0 + float(i) * 9.0
        _block("CanalReflection_%d" % i, Vector3(-22, 0.64, z), Vector3(2.2, 0.025, 0.28), glass)
    # Two rows of facade variations, intentionally outside combat and quest interaction zones.
    for i in range(8):
        var xx: float = 23.0 if i % 2 == 0 else -27.0
        var zz: float = -24.0 + floorf(float(i) / 2.0) * 14.0
        _building(i, xx, zz, 4.1 + float(i % 3) * 0.72)
    for i in range(6):
        var z: float = -22.0 + float(i) * 8.0
        _lantern(Vector3(18.4, 0.5, z))
    var district_label := Label3D.new()
    district_label.text = "MAGNARA | RING TWO"
    district_label.font_size = 42
    district_label.pixel_size = 0.008
    district_label.position = Vector3(17.5, 3.6, 7.0)
    district_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    district_label.no_depth_test = true
    add_child(district_label)

func _mat(color: Color) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.roughness = 0.76
    return result

func _block(node_name: String, at: Vector3, dimensions: Vector3, material: Material) -> void:
    var instance := MeshInstance3D.new()
    instance.name = node_name
    var box := BoxMesh.new()
    box.size = dimensions
    instance.mesh = box
    instance.position = at
    instance.material_override = material
    instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(instance)

func _building(index: int, x: float, z: float, height: float) -> void:
    var ground_level: float = 0.55
    var wall_material: Material = stone if index % 2 == 0 else slate
    _block("SeekerResidence_%d" % index, Vector3(x, ground_level + height * 0.5, z), Vector3(5.2, height, 5.0), wall_material)
    _block("ResidenceRoof_%d" % index, Vector3(x, ground_level + height + 0.20, z), Vector3(5.8, 0.40, 5.55), roof)
    var facing: float = -1.0 if x > 0.0 else 1.0
    for floor_index in range(2):
        for column in range(2):
            _block("Window", Vector3(x + float(column) * 1.9 - 0.95, ground_level + 1.65 + float(floor_index) * 1.7, z + facing * 2.55), Vector3(0.85, 0.94, 0.10), glass)
            _block("WindowLintel", Vector3(x + float(column) * 1.9 - 0.95, ground_level + 2.17 + float(floor_index) * 1.7, z + facing * 2.60), Vector3(1.03, 0.12, 0.16), gold)
    _block("Door", Vector3(x, ground_level + 0.86, z + facing * 2.54), Vector3(1.22, 1.70, 0.12), roof)

func _lantern(at: Vector3) -> void:
    _block("LampPost", at + Vector3(0, 1.15, 0), Vector3(0.16, 2.3, 0.16), slate)
    _block("LampGlow", at + Vector3(0, 2.47, 0), Vector3(0.54, 0.63, 0.54), gold)
