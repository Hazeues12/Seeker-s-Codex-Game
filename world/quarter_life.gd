extends Node3D

const CityRoutines = preload("res://systems/city_routines_v051.gd")

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
    var clock: float = 480.0
    if is_instance_valid(hub):
        clock = float(hub.get("world_minutes"))
    for i in range(people.size()):
        var npc: Node3D = people[i]
        if not is_instance_valid(npc):
            continue
        var plan: Dictionary = CityRoutines.assignment(ROLES[i], clock)
        npc.visible = bool(plan["present"])
        if not npc.visible:
            npc.position = home_positions[i] + (plan["offset"] as Vector3)
            continue
        var destination: Vector3 = home_positions[i] + (plan["offset"] as Vector3)
        var previous: Vector3 = npc.position
        npc.position = previous.move_toward(destination, 1.7 * delta)
        var step: Vector3 = destination - previous
        if step.length_squared() > 0.03:
            npc.rotation.y = atan2(-step.x, -step.z)
        (npc.get_node("Townsperson") as TownspersonVisual).set_motion(0.8 if step.length_squared() > 0.03 else 0.0)

func _body(npc: Node3D, role: int) -> void:
    var coat: Array[Color] = [Color(0.24, 0.58, 0.64), Color(0.67, 0.39, 0.25), Color(0.22, 0.36, 0.53)]
    TownspersonVisual.add_to(npc, ROLES[role], role % 2, coat[role])

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
