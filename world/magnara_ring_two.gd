extends Node3D

# V0.40: Canon-aware Ring Two expansion and distance-based modular districts.
# Local map bearings are a game prototype, NOT locked compass geography.
# Chapter 90 source priority: public quarter -> professional band -> secured Citadel.
const LOAD_DISTANCE: float = 66.0
const UNLOAD_DISTANCE: float = 84.0
const REGIONS = {
    "public": 46.0,
    "professional": 82.0,
    "citadel_approach": 116.0,
}
var player: Node3D
var ticks: float = 0.0
var active_regions: Dictionary = {}
var material_cache: Dictionary = {}

func _ready() -> void:
    call_deferred("_initialize")

func _initialize() -> void:
    player = get_parent().get_node_or_null("Player") as Node3D
    # One connected collision floor instead of an endless fully-loaded world.
    var ground := StaticBody3D.new()
    ground.name = "ConnectedRingTwoGround"
    add_child(ground)
    _part(ground, "Ground", Vector3(0.0, 0.0, 85.0), Vector3(68.0, 1.0, 111.0), Color(0.55, 0.54, 0.50), true)
    _refresh_regions()

func _process(delta: float) -> void:
    ticks += delta
    if ticks >= 0.55:
        ticks = 0.0
        _refresh_regions()

func _refresh_regions() -> void:
    if not is_instance_valid(player):
        return
    for id in REGIONS:
        var target_z: float = float(REGIONS[id])
        var distance: float = absf(player.global_position.z - target_z)
        if not active_regions.has(id) and distance < LOAD_DISTANCE:
            var section := Node3D.new()
            section.name = "Region_" + str(id)
            section.add_to_group("margerina_streamed_region")
            add_child(section)
            match str(id):
                "public": _public_quarter(section)
                "professional": _professional_quarter(section)
                "citadel_approach": _citadel_approach(section)
            active_regions[id] = section
        elif active_regions.has(id) and distance > UNLOAD_DISTANCE:
            var old: Node3D = active_regions[id]
            active_regions.erase(id)
            old.queue_free()

func _mat(color: Color) -> StandardMaterial3D:
    var key: String = str(color)
    if material_cache.has(key):
        return material_cache[key]
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.roughness = 0.77
    material_cache[key] = result
    return result

func _part(parent: Node3D, label: String, center: Vector3, dimensions: Vector3, color: Color, solid: bool = false, wall: bool = false) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = label
    var shape := BoxMesh.new()
    shape.size = dimensions
    mesh.mesh = shape
    mesh.position = center
    mesh.material_override = _mat(color)
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(mesh)
    if solid:
        var body := StaticBody3D.new()
        body.name = label + "Collision"
        if wall:
            body.add_to_group("traversal_wall")
        mesh.add_child(body)
        var collider := CollisionShape3D.new()
        var volume := BoxShape3D.new()
        volume.size = dimensions
        collider.shape = volume
        body.add_child(collider)

func _tag(parent: Node3D, message: String, center: Vector3, scale: int = 38) -> void:
    var label := Label3D.new()
    label.text = message
    label.font_size = scale
    label.pixel_size = 0.006
    label.position = center
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    parent.add_child(label)

func _road(parent: Node3D, start: float, length: float) -> void:
    _part(parent, "FourCarriagePaleStoneAvenue", Vector3(12.0, 0.535, start + length * 0.5), Vector3(12.5, 0.065, length), Color(0.72, 0.68, 0.61))
    for n in range(int(length / 8.0)):
        var zz: float = start + float(n) * 8.0 + 4.0
        _part(parent, "AvenuePavingJoint", Vector3(12.0, 0.579, zz), Vector3(12.2, 0.02, 0.08), Color(0.60, 0.59, 0.55))

func _sigil_lamp(parent: Node3D, x: float, z: float) -> void:
    var bronze := Color(0.48, 0.33, 0.19)
    _part(parent, "BronzeResonanceLamp", Vector3(x, 1.55, z), Vector3(0.17, 2.0, 0.17), bronze)
    _part(parent, "SealedGlassLantern", Vector3(x, 2.62, z), Vector3(0.52, 0.63, 0.52), Color(0.42, 0.78, 0.92))
    _part(parent, "SigilBronzeCrown", Vector3(x, 2.98, z), Vector3(0.65, 0.13, 0.65), bronze)

func _building(parent: Node3D, label: String, x: float, z: float, floors: int, stone: Color) -> void:
    var height: float = 2.5 + float(floors) * 1.35
    _part(parent, label, Vector3(x, 0.5 + height * 0.5, z), Vector3(7.0, height, 6.4), stone, true, true)
    _part(parent, label + "Roof", Vector3(x, 0.58 + height, z), Vector3(7.45, 0.2, 6.9), Color(0.24, 0.31, 0.38), true)
    for level in range(floors):
        var window_y: float = 2.0 + float(level) * 1.35
        for ix in [-1.65, 1.65]:
            _part(parent, label + "Window", Vector3(x + ix, window_y, z - 3.23), Vector3(0.88, 0.77, 0.05), Color(0.32, 0.62, 0.75))
    _part(parent, label + "Door", Vector3(x, 1.4, z - 3.23), Vector3(1.25, 1.8, 0.06), Color(0.20, 0.25, 0.28))

func _public_quarter(parent: Node3D) -> void:
    _road(parent, 30.5, 39.0)
    var canal := Color(0.12, 0.44, 0.62)
    _part(parent, "BlueResonanceCanal", Vector3(-11.0, 0.578, 49.5), Vector3(3.8, 0.085, 38.0), canal)
    for bank in [-13.3, -8.7]:
        _part(parent, "StoneCanalEdge", Vector3(bank, 0.83, 49.5), Vector3(0.42, 0.46, 38.2), Color(0.63, 0.61, 0.60))
    for z in [41.5, 59.0]:
        _part(parent, "IronFootbridge", Vector3(-11.0, 0.93, z), Vector3(7.2, 0.27, 2.8), Color(0.30, 0.33, 0.38), true)
        for side in [-1.3, 1.3]:
            _part(parent, "IronBridgeRail", Vector3(-11.0, 1.43, z + side), Vector3(7.3, 0.86, 0.10), Color(0.26, 0.28, 0.30))
    for i in range(4):
        var z: float = 35.0 + float(i) * 9.0
        _building(parent, "CivicResidence_%d" % i, 25.0 if i % 2 == 0 else -23.0, z, 2 + i % 2, Color(0.57, 0.58, 0.61))
        _sigil_lamp(parent, 19.0, z + 1.8)
    _tag(parent, "RING TWO / PUBLIC QUARTER", Vector3(11.7, 4.2, 36.0), 46)
    _tag(parent, "INNS  |  NOODLES  |  LAUNDRY  |  RESIDENCES", Vector3(12.0, 3.35, 54.5), 29)
    _tag(parent, "BLUE RESONANCE CANAL", Vector3(-11.0, 3.2, 46.0), 33)
    _part(parent, "NoodleStallCounter", Vector3(3.1, 1.15, 53.5), Vector3(2.2, 1.25, 1.6), Color(0.48, 0.30, 0.18))
    _part(parent, "PublicLaundryRack", Vector3(2.7, 2.0, 62.0), Vector3(2.9, 0.12, 0.16), Color(0.68, 0.62, 0.48))

func _professional_quarter(parent: Node3D) -> void:
    _road(parent, 69.5, 35.5)
    var stone := Color(0.53, 0.58, 0.64)
    _building(parent, "RegistrationAndCertification", -1.0, 79.0, 3, stone)
    _building(parent, "SeekerMedicalHall", 26.0, 80.0, 3, Color(0.63, 0.62, 0.60))
    _building(parent, "SoulwrightOffices", -1.0, 98.0, 3, Color(0.46, 0.54, 0.59))
    _building(parent, "NightBarracks", 26.0, 99.0, 3, stone)
    _part(parent, "MartialTrainingCourt", Vector3(-19.0, 0.59, 86.0), Vector3(10.0, 0.16, 12.0), Color(0.47, 0.47, 0.46))
    for i in range(4):
        var x: float = -23.0 + float(i % 2) * 7.0
        var z: float = 83.0 + float(i / 2) * 6.0
        _part(parent, "TrainingSparringPost", Vector3(x, 1.55, z), Vector3(0.28, 2.0, 0.28), Color(0.53, 0.33, 0.20))
    for z in [75.0, 88.0, 100.0]:
        _sigil_lamp(parent, 19.0, z)
    _tag(parent, "RING TWO / SEEKER PROFESSIONAL PRECINCT", Vector3(11.0, 4.6, 76.0), 38)
    _tag(parent, "REGISTRATION / CERTIFICATION", Vector3(-1.0, 8.0, 79.0), 27)
    _tag(parent, "MEDICAL TRAINING", Vector3(26.0, 8.0, 80.0), 29)
    _tag(parent, "SOULWRIGHT DIVISION", Vector3(-1.0, 8.0, 98.0), 28)
    _tag(parent, "BARRACKS", Vector3(26.0, 8.0, 99.0), 29)

func _citadel_approach(parent: Node3D) -> void:
    _road(parent, 105.0, 24.0)
    for x in [4.0, 20.0]:
        _part(parent, "BasaltCitadelRampart", Vector3(x, 3.9, 119.0), Vector3(8.0, 6.7, 2.2), Color(0.13, 0.17, 0.20), true)
        _part(parent, "GoldRampartCap", Vector3(x, 7.4, 119.0), Vector3(8.2, 0.42, 2.5), Color(0.66, 0.52, 0.25))
    _part(parent, "WesternSecurePerimeter", Vector3(-16.0, 6.0, 119.0), Vector3(36.0, 11.0, 2.2), Color(0.13, 0.17, 0.20), true)
    _part(parent, "EasternSecurePerimeter", Vector3(40.0, 6.0, 119.0), Vector3(34.0, 11.0, 2.2), Color(0.13, 0.17, 0.20), true)
    # A gated silhouette marks the security boundary; access is not claimed as canon.
    _part(parent, "RestrictedCitadelGate", Vector3(12.0, 3.5, 119.0), Vector3(8.0, 5.6, 0.55), Color(0.20, 0.25, 0.29), true)
    _tag(parent, "SECURED CITADEL PRECINCT / AUTHORIZATION REQUIRED", Vector3(12.0, 8.3, 114.0), 34)
    # Hexagonal black-and-gold Citadel with thirteen distant towers.
    var center := Vector3(12.0, 0.0, 153.0)
    var mass := MeshInstance3D.new()
    mass.name = "CitadelHexagonalMass"
    var hex := CylinderMesh.new()
    hex.radial_segments = 6
    hex.top_radius = 11.0
    hex.bottom_radius = 13.0
    hex.height = 22.0
    mass.mesh = hex
    mass.material_override = _mat(Color(0.10, 0.13, 0.16))
    mass.position = center + Vector3(0.0, 11.0, 0.0)
    parent.add_child(mass)
    for i in range(13):
        var angle: float = TAU * float(i) / 13.0
        var radius: float = 16.0 + float(i % 2) * 1.5
        var tower := MeshInstance3D.new()
        tower.name = "CitadelTower_%02d" % (i + 1)
        var shaft := CylinderMesh.new()
        shaft.radial_segments = 6
        shaft.top_radius = 1.8
        shaft.bottom_radius = 2.5
        shaft.height = 19.0 + float(i % 3) * 4.0
        tower.mesh = shaft
        tower.position = center + Vector3(cos(angle) * radius, 13.0 + float(i % 3) * 2.0, sin(angle) * radius)
        tower.material_override = _mat(Color(0.10, 0.13, 0.18) if i % 2 == 0 else Color(0.28, 0.25, 0.20))
        parent.add_child(tower)
        _part(parent, "CitadelGoldFinial", tower.position + Vector3(0.0, 10.2 + float(i % 3) * 2.0, 0.0), Vector3(2.2, 0.9, 2.2), Color(0.73, 0.56, 0.22))
    _tag(parent, "SEEKER CITADEL / THIRTEEN TOWERS", center + Vector3(0.0, 36.0, -13.0), 39)
