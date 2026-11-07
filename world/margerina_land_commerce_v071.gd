extends Node3D
# V0.71 physical wagons on existing public roads, but "Janoah to X"
# manifests represent proposed gameplay cargo networks ONLY; routes don't
# physically jump national borders or claim canonical foreign cargo volume.
const Trade = preload("res://systems/margerina_commerce_rules_v071.gd")
const LocalFreightV073 = preload("res://systems/magnara_local_logistics_rules_v073.gd")
var hub: Node
var player: CharacterBody3D
var data: Dictionary = {}
var wagons: Array[AnimatableBody3D] = []
var initialized: bool = false
var seconds: float = 0.0
var previous_wagon_z: Array[float] = []

func _ready() -> void:
    add_to_group("v071_land_commerce")
    set_physics_process(false)
    call_deferred("_setup")

func _mat(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    m.roughness = 0.91
    return m

func _block(parent: Node3D, title: String, at: Vector3,
        dims: Vector3, shade: Color, physical: bool = false) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = title
    var geom := BoxMesh.new()
    geom.size = dims
    node.mesh = geom
    node.material_override = _mat(shade)
    node.position = at
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(node)
    if physical:
        var body := StaticBody3D.new()
        node.add_child(body)
        var collider := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = dims
        collider.shape = box
        body.add_child(collider)
    return node

func _setup() -> void:
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    hub = get_tree().get_first_node_in_group("hub_manager")
    data = Trade.registry()
    if not is_instance_valid(player) or not is_instance_valid(hub) or not Trade.valid_registry(data):
        return
    _build_waypoints()
    _build_wagons()
    initialized = true
    set_physics_process(true)

func _build_waypoints() -> void:
    for z in [746.0,1382.0]:
        _block(self,"V071PublicFreightLoadPad",Vector3(14.0,0.75,z),
            Vector3(5.0,0.15,13.0),Color(0.62,0.59,0.52),true)
        _block(self,"V071LocalCargoStock",Vector3(15.0,1.44,z+2.2),
            Vector3(2.5,1.05,2.3),Color(0.54,0.41,0.30),true)
        var sign := Label3D.new()
        sign.name = "V071LandFreightMarker"
        sign.text = "PUBLIC FREIGHT / LOCAL TRANSFER / GAME-ONLY ROUTES"
        sign.position = Vector3(13.0,3.45,z)
        sign.font_size = 24
        sign.pixel_size = 0.0042
        sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        sign.no_depth_test = true
        add_child(sign)

func _build_wagons() -> void:
    for i in range(Trade.WAGON_COUNT):
        var wagon := AnimatableBody3D.new()
        wagon.name = "V071WorkingTradeWagon_%d" % i
        wagon.sync_to_physics = false
        wagon.add_to_group("v071_physical_land_wagon")
        wagon.collision_layer = 1
        wagon.collision_mask = 1
        add_child(wagon)
        var shape := CollisionShape3D.new()
        shape.name = "V071TradeCartBodyCollision"
        var box := BoxShape3D.new()
        box.size = Vector3(1.95,1.35,4.8)
        shape.shape = box
        shape.position = Vector3(0,0.7,0)
        wagon.add_child(shape)
        _block(wagon,"V071CartBed",Vector3(0,0.55,0),
            Vector3(1.95,0.45,4.8),Color(0.44,0.34,0.22))
        _block(wagon,"V071CratedCargo",Vector3(0,1.26,0),
            Vector3(1.50,1.15,2.8),
            Color(0.53,0.41,0.29))
        for x in [-1.13,1.13]:
            for z in [-1.7,1.7]:
                _block(wagon,"V071CartWheel",Vector3(x,0.29,z),
                    Vector3(0.25,0.93,0.91),Color(0.24,0.23,0.21))
        wagons.append(wagon)
        previous_wagon_z.append(-9999.0)

func get_manifest() -> Dictionary:
    return {"version":71,"road_vehicles":wagons.size(),
        "active_road_routes":Trade.WAGON_COUNT,
        "real_world_shipment_across_borders":false,
        "country_labels_game_only":true,
        "real_physical_vehicle_colliders":true,
        "preserves_original_rail_trolley":true}

func _physics_process(delta: float) -> void:
    if not initialized:
        return
    seconds += delta
    var day: int = 1+floori(float(hub.get("world_minutes"))/1440.0)
    for i in range(wagons.size()):
        var body: AnimatableBody3D = wagons[i]
        var state: Dictionary = Trade.wagon_state(i,seconds,day,data)
        body.global_position = state["pos"]
        body.rotation.y = PI if str(state["activity"]) == "city_bound" else 0.0
        # The existing physical wagon route triggers a consignment only
        # after actually crossing the end-of-road northern freight depot.
        # No shipment is invented by loading the game, by opening a menu,
        # or by visually hiding the wagon with mobile LOD.
        var now_z: float = float((state["pos"] as Vector3).z)
        var prior_z: float = previous_wagon_z[i]
        if prior_z >= Trade.LAND_Z0 and prior_z < LocalFreightV073.DOCK_TRIGGER_Z \
                and now_z >= LocalFreightV073.DOCK_TRIGGER_Z \
                and str(state["activity"]) == "city_bound":
            var work: Node = get_tree().get_first_node_in_group("v073_public_logistics")
            if is_instance_valid(work) and work.has_method("_register_wagon_dock"):
                work.call("_register_wagon_dock",i,day)
        previous_wagon_z[i] = now_z
        # Distant wagons remain represented by their deterministic route
        # state but do not consume mobile rendering/physics budget.
        var near: bool = body.global_position.distance_to(player.global_position) < 185.0
        body.visible = near
        body.collision_layer = 1 if near else 0
