extends Node3D

# Lightweight, non-colliding NPC stand-ins for the Margerina Seeker Quarters.
# These are ambient prototypes, not additions to published story canon.
var residents: Array[Node3D] = []
var origins: Array[Vector3] = []
var time_elapsed: float = 0.0

func _ready() -> void:
    var data := [
        {"name": "COURIER", "at": Vector3(-8.0, 0.55, 2.0), "robe": Color(0.55, 0.36, 0.24)},
        {"name": "SEEKER TRAINEE", "at": Vector3(8.2, 0.55, -11.0), "robe": Color(0.28, 0.46, 0.58)},
        {"name": "QUARTER MEDIC", "at": Vector3(-7.5, 0.55, -2.0), "robe": Color(0.59, 0.63, 0.55)}
    ]
    for entry in data:
        var npc := Node3D.new()
        npc.name = str(entry["name"]).replace(" ", "_")
        npc.position = entry["at"]
        add_child(npc)
        _add_body(npc, entry["robe"])
        var label := Label3D.new()
        label.text = str(entry["name"])
        label.position = Vector3(0.0, 2.45, 0.0)
        label.font_size = 31
        label.pixel_size = 0.005
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.no_depth_test = true
        npc.add_child(label)
        residents.append(npc)
        origins.append(npc.position)

func _add_body(npc: Node3D, robe_color: Color) -> void:
    var torso := MeshInstance3D.new()
    torso.name = "Tunic"
    var tunic_mesh := CylinderMesh.new()
    tunic_mesh.top_radius = 0.31
    tunic_mesh.bottom_radius = 0.46
    tunic_mesh.height = 1.30
    torso.mesh = tunic_mesh
    torso.position.y = 0.90
    torso.material_override = _material(robe_color)
    npc.add_child(torso)
    var head := MeshInstance3D.new()
    head.name = "Face"
    var sphere := SphereMesh.new()
    sphere.radius = 0.26
    sphere.height = 0.52
    head.mesh = sphere
    head.position.y = 1.80
    head.material_override = _material(Color(0.64, 0.46, 0.34))
    npc.add_child(head)
    for side in [-1.0, 1.0]:
        var sleeve := MeshInstance3D.new()
        sleeve.name = "Sleeve"
        var sleeve_mesh := CapsuleMesh.new()
        sleeve_mesh.radius = 0.13
        sleeve_mesh.height = 0.76
        sleeve.mesh = sleeve_mesh
        sleeve.position = Vector3(side * 0.43, 1.17, 0.0)
        sleeve.rotation.z = side * 0.22
        sleeve.material_override = _material(robe_color.darkened(0.18))
        npc.add_child(sleeve)

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.85
    return mat

func _process(delta: float) -> void:
    time_elapsed += delta
    for i in range(residents.size()):
        var npc: Node3D = residents[i]
        var phase: float = time_elapsed * 0.8 + float(i) * 2.4
        # Short pacing routes never obstruct quests or create extra physics load.
        npc.position = origins[i] + Vector3(sin(phase) * 0.65, 0.0, cos(phase) * 0.28)
        npc.rotation.y = sin(phase) * 0.30
