extends Node3D

# V0.38 small NPC conversations and simulated daily movement in Magnara Ring Two.
# All merchant inventories/dialogue and roles are provisional gameplay stand-ins.
var people: Array[Node3D] = []
var home_positions: Array[Vector3] = []
var time_elapsed: float = 0.0
var hub: Node
const ROLES: Array[String] = ["npc_canal", "npc_vendor", "npc_scout"]
const LABELS: Array[String] = ["CANAL GUIDE", "MARKET SELLER", "SEEKER SCOUT"]

func _ready() -> void:
    call_deferred("_build_quarter")

func _build_quarter() -> void:
    hub = get_tree().get_first_node_in_group("hub_manager")
    _make_market()
    var positions: Array[Vector3] = [
        Vector3(-13.0, 0.55, 10.5),
        Vector3(11.0, 0.55, 13.0),
        Vector3(9.4, 0.55, 3.7)
    ]
    for i in range(ROLES.size()):
        var npc := Node3D.new()
        npc.name = ROLES[i]
        npc.position = positions[i]
        add_child(npc)
        _body(npc, i)
        var tag := Label3D.new()
        tag.text = LABELS[i]
        tag.position = Vector3(0, 2.65, 0)
        tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        tag.no_depth_test = true
        tag.font_size = 35
        tag.pixel_size = 0.006
        npc.add_child(tag)
        people.append(npc)
        home_positions.append(positions[i])
        if is_instance_valid(hub) and hub.has_method("_add_location"):
            hub.call("_add_location", ROLES[i], LABELS[i], npc.global_position, npc)

func _process(delta: float) -> void:
    if people.is_empty():
        return
    time_elapsed += delta
    var minute_of_day: int = 480
    if is_instance_valid(hub):
        minute_of_day = int(float(hub.get("world_minutes"))) % 1440
    for i in range(people.size()):
        var npc: Node3D = people[i]
        if not is_instance_valid(npc):
            continue
        # The seller keeps daytime hours; the scout patrols all day; the canal guide rests late.
        var is_present: bool = true
        if i == 1:
            is_present = minute_of_day >= 420 and minute_of_day < 1200
        elif i == 0:
            is_present = minute_of_day >= 360 and minute_of_day < 1320
        npc.visible = is_present
        if not is_present:
            continue
        var phase: float = time_elapsed * (0.36 + float(i) * 0.06) + float(i) * 1.8
        npc.position = home_positions[i] + Vector3(sin(phase) * 0.95, 0.0, cos(phase) * 0.55)
        npc.rotation.y = sin(phase) * 0.35

func _body(npc: Node3D, role: int) -> void:
    var coat: Array[Color] = [Color(0.24, 0.58, 0.64), Color(0.67, 0.39, 0.25), Color(0.22, 0.36, 0.53)]
    _block(npc, "Tunic", Vector3(0, 1.23, 0), Vector3(0.73, 0.91, 0.45), coat[role])
    _block(npc, "LegL", Vector3(-0.20, 0.45, 0), Vector3(0.27, 0.72, 0.34), Color(0.18, 0.20, 0.28))
    _block(npc, "LegR", Vector3(0.20, 0.45, 0), Vector3(0.27, 0.72, 0.34), Color(0.18, 0.20, 0.28))
    _block(npc, "LeftArm", Vector3(-0.51, 1.35, 0), Vector3(0.22, 0.74, 0.29), coat[role])
    _block(npc, "RightArm", Vector3(0.51, 1.35, 0), Vector3(0.22, 0.74, 0.29), coat[role])
    _block(npc, "Head", Vector3(0, 1.98, 0), Vector3(0.47, 0.50, 0.43), Color(0.55, 0.37, 0.27))
    _block(npc, "Hair", Vector3(0, 2.26, 0), Vector3(0.48, 0.13, 0.45), Color(0.17, 0.14, 0.14))

func _make_market() -> void:
    # Decoration only, above the ground plane. No added collision or path blockers.
    _block(self, "MarketWalk", Vector3(12.0, 0.565, 15.0), Vector3(14.0, 0.075, 17.0), Color(0.62, 0.56, 0.49))
    for i in range(4):
        var xx: float = 6.7 if i % 2 == 0 else 17.4
        var zz: float = 10.0 + floorf(float(i) / 2.0) * 8.0
        var color: Color = Color(0.26, 0.54, 0.62) if i % 2 == 0 else Color(0.68, 0.37, 0.35)
        _block(self, "StallTable", Vector3(xx, 1.35, zz), Vector3(2.6, 0.19, 1.65), Color(0.35, 0.25, 0.18))
        _block(self, "StallShade", Vector3(xx, 3.15, zz), Vector3(3.15, 0.18, 2.35), color)
        for s in [-1.15, 1.15]:
            _block(self, "StallPole", Vector3(xx + s, 2.0, zz), Vector3(0.10, 2.45, 0.10), Color(0.33, 0.25, 0.19))
    var sign := Label3D.new()
    sign.text = "SEEKER QUARTERS | MARKET WALK"
    sign.position = Vector3(11.9, 3.0, 21.0)
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.no_depth_test = true
    sign.font_size = 40
    sign.pixel_size = 0.006
    add_child(sign)

func _block(parent: Node3D, node_name: String, at: Vector3, dimensions: Vector3, color: Color) -> void:
    var node := MeshInstance3D.new()
    node.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    node.mesh = mesh
    node.position = at
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.8
    node.material_override = mat
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(node)
