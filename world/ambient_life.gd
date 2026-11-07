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
    for index in range(data.size()):
        var entry: Dictionary = data[index]
        var npc := Node3D.new()
        npc.name = str(entry["name"]).replace(" ", "_")
        npc.position = entry["at"]
        add_child(npc)
        TownspersonVisual.add_to(npc, str(entry["name"]), index % 2, entry["robe"]).set_motion(0.42)
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

func _process(delta: float) -> void:
    time_elapsed += delta
    for i in range(residents.size()):
        var npc: Node3D = residents[i]
        var phase: float = time_elapsed * 0.8 + float(i) * 2.4
        # Short pacing routes never obstruct quests or create extra physics load.
        npc.position = origins[i] + Vector3(sin(phase) * 0.65, 0.0, cos(phase) * 0.28)
        npc.rotation.y = atan2(-cos(phase) * 0.65, sin(phase) * 0.28)
