extends Node3D
# V0.70 a game-only two-stop rail inspection trolley, NOT a published Janoah
# rail schedule, Skyport, or the separate V0.50 fixed passenger carriage.
# The player remains a CharacterBody3D, freely walking/jumping on a physically
# moving AnimatableBody3D. No parenting or scripting the player's location.
const Rules = preload("res://systems/magnara_carrier_rules_v070.gd")
var player: CharacterBody3D
var hub: Node
var initialized: bool = false
var path: Path3D
var follower: PathFollow3D
var deck_body: AnimatableBody3D
var journey_seconds: float = 0.0
var route_state: Dictionary = {}
var info_panel: PanelContainer
var status_label: Label
var stations: Array[Node3D] = []

func _ready() -> void:
    add_to_group("v070_public_carrier")
    set_physics_process(false)
    call_deferred("_setup")

func _mat(tint: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    material.metallic = 0.06
    material.roughness = 0.85
    return material

func _piece(parent: Node3D, name: String, offset: Vector3, dims: Vector3,
        tint: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = name
    var block := BoxMesh.new()
    block.size = dims
    node.mesh = block
    node.material_override = _mat(tint)
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    node.position = offset
    parent.add_child(node)
    return node

func _sign(parent: Node3D, caption: String, at: Vector3) -> void:
    var marker := Label3D.new()
    marker.name = "V070PublicCarrierSign"
    marker.text = caption
    marker.position = at
    marker.font_size = 22
    marker.pixel_size = 0.0048
    marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    marker.no_depth_test = true
    parent.add_child(marker)

func _setup() -> void:
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    hub = get_tree().get_first_node_in_group("hub_manager")
    if not is_instance_valid(player) or not is_instance_valid(hub):
        push_warning("V0.70 public carrier needs hub and Player")
        return
    _make_track()
    _make_vehicle()
    _make_stops()
    _make_ui()
    route_state = Rules.state_at(0.0)
    initialized = true
    set_physics_process(true)

func _make_track() -> void:
    path = Path3D.new()
    path.name = "V070ActualCarrierSpline"
    var curve := Curve3D.new()
    curve.bake_interval = 0.8
    curve.add_point(Vector3(0,0,0))
    curve.add_point(Vector3(0,0,41))
    curve.add_point(Vector3(0,0,82))
    path.curve = curve
    path.position = Rules.STATION_SOUTH
    add_child(path)
    follower = PathFollow3D.new()
    follower.name = "V070RailPathFollow"
    follower.loop = false
    follower.rotation_mode = PathFollow3D.ROTATION_NONE
    path.add_child(follower)
    for rail_x in [-1.30,1.30]:
        _piece(self,"V070SteelTrack",Vector3(rail_x,0.73,649.0),
            Vector3(0.16,0.14,83.0),Color(0.37,0.42,0.47))
    for i in range(19):
        _piece(self,"V070TrackTie",Vector3(0,0.69,609.0+float(i)*4.5),
            Vector3(3.15,0.13,0.32),Color(0.41,0.32,0.25))

func _make_vehicle() -> void:
    deck_body = AnimatableBody3D.new()
    deck_body.name = "V070RealMovingCarrier"
    # Manually moved in _physics_process; engine-driven physics synchronization
    # would overwrite a scripted transform with the previous server position.
    deck_body.sync_to_physics = false
    deck_body.collision_layer = 1
    deck_body.collision_mask = 1
    deck_body.add_to_group("v070_moving_platform")
    # Keep the *physics body* under world root. Moving only the parent
    # PathFollow can leave the synced broadphase collider behind its visual.
    add_child(deck_body)
    deck_body.global_position = follower.global_position + Vector3(0,0.90,0)
    # y=1.52 local rail world; deck top=1.64, accessible by ordinary jump.
    var floor_shape := CollisionShape3D.new()
    floor_shape.name = "V070CarrierFloorCollision"
    var floor_box := BoxShape3D.new()
    floor_box.size = Vector3(3.6,0.24,6.20)
    floor_shape.shape = floor_box
    deck_body.add_child(floor_shape)
    _piece(deck_body,"V070WalkableDeck",Vector3.ZERO, floor_box.size,
        Color(0.48,0.48,0.52))
    for side in [-1.0,1.0]:
        _piece(deck_body,"V070VehicleTrim",Vector3(side*1.76,0.24,0),
            Vector3(0.12,0.35,6.30),Color(0.55,0.39,0.24))
        for axis in [-1.0,1.0]:
            _piece(deck_body,"V070Wheel",Vector3(side*1.5,-0.54,axis*1.9),
                Vector3(0.43,0.72,0.77),Color(0.20,0.23,0.27))
    _sign(deck_body,"JUMP ABOARD / MOVE FREELY",Vector3(0,2.50,0))

func _make_stops() -> void:
    var ports: Array[Dictionary] = [
        {"id":"south","z":608.0,"label":"SOUTH MERCHANT ROAD"},
        {"id":"north","z":690.0,"label":"NORTH ROOFWAY ROAD"}
    ]
    for item in ports:
        var station := Node3D.new()
        station.name = "V070CarrierStop_" + str(item["id"])
        station.position = Vector3(8.2,0.0,float(item["z"]))
        add_child(station)
        stations.append(station)
        _piece(station,"V070PublicWaitingPlatform",Vector3(0,0.72,0),
            Vector3(3.1,0.19,6.8),Color(0.65,0.62,0.56))
        var post := StaticBody3D.new()
        post.name = "V070TimetablePhysicalPost"
        post.position = Vector3(1.1,1.65,2.1)
        station.add_child(post)
        _piece(post,"V070ScheduleBoard",Vector3.ZERO,
            Vector3(0.22,2.2,2.3),Color(0.41,0.35,0.26))
        var hit := CollisionShape3D.new()
        var block := BoxShape3D.new()
        block.size = Vector3(0.22,2.2,2.3)
        hit.shape = block
        post.add_child(hit)
        _sign(station, str(item["label"])+" / PUBLIC TROLLEY", Vector3(0,3.4,0))
        var approach := Node3D.new()
        approach.name = "V070StopApproach"
        approach.position = Vector3(-1.9,0.85,-1.4)
        station.add_child(approach)
        hub.call("_add_location","carrier_v070_"+str(item["id"]),
            "Public Inspection Trolley / "+str(item["label"]),
            approach.global_position,approach)

func _make_ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "V070CarrierTimetableLayer"
    canvas.layer = 33
    get_parent().add_child(canvas)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(root)
    info_panel = PanelContainer.new()
    info_panel.anchor_left = 0.10
    info_panel.anchor_right = 0.90
    info_panel.anchor_top = 0.14
    info_panel.anchor_bottom = 0.86
    info_panel.visible = false
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.075,0.09,0.13,0.98)
    style.border_color = Color(0.59,0.64,0.73)
    style.set_border_width_all(2)
    style.set_corner_radius_all(9)
    info_panel.add_theme_stylebox_override("panel",style)
    root.add_child(info_panel)
    var margin := MarginContainer.new()
    for side in ["left","right","top","bottom"]:
        margin.add_theme_constant_override("margin_"+side,16)
    info_panel.add_child(margin)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation",13)
    margin.add_child(content)
    var header := Label.new()
    header.text = "PUBLIC STREET INSPECTION TROLLEY / PROTOTYPE"
    header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    header.add_theme_font_size_override("font_size",22)
    content.add_child(header)
    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(status_label)
    var close := Button.new()
    close.text = "RETURN TO THE PLATFORM"
    close.custom_minimum_size.y = 54
    close.pressed.connect(_close)
    content.add_child(close)

func get_manifest() -> Dictionary:
    return {"version":70,"built":initialized,"stations":stations.size(),
        "track":"Curve3D/Path3D/PathFollow3D",
        "platform_type":"AnimatableBody3D",
        "character_parenting":false,"free_movement_on_deck":true,
        "range_m":Rules.STATION_DISTANCE,
        "real_physics":is_instance_valid(deck_body),
        "canon_status":"game_only_transport_prototype"}

func is_open() -> bool:
    return is_instance_valid(info_panel) and info_panel.visible

func _close() -> void:
    if is_instance_valid(info_panel):
        info_panel.hide()

func interact(key: String) -> void:
    if not initialized or not ["carrier_v070_south","carrier_v070_north"].has(key):
        return
    _update_info()
    info_panel.show()

func _update_info() -> void:
    var data: Dictionary = route_state
    if is_instance_valid(status_label) and not data.is_empty():
        status_label.text = "Service: %s / %.1f m of %.0f m track\n" % [
            str(data.get("state","unknown")).replace("_"," "),
            float(data.get("fraction",0.0))*Rules.STATION_DISTANCE,
            Rules.STATION_DISTANCE]
        status_label.text += "The car stops at both ends; jump onto its physical deck.\n"
        status_label.text += "Use the joystick to walk or jump on the moving car.\n"
        status_label.text += "This is a game-only local service trial, not an official Janoah rail route."

func _physics_process(delta: float) -> void:
    if not initialized:
        return
    journey_seconds += delta
    route_state = Rules.state_at(journey_seconds)
    var fraction: float = float(route_state.get("fraction",0.0))
    follower.progress_ratio = fraction
    # Sample curve coordinates then move the AnimatableBody3D itself,
    # in the physics tick (sync_to_physics is false for manual movement).
    deck_body.global_position = follower.global_position + Vector3(0,0.90,0)
    # CharacterBody3D inherits platform velocity via move_and_slide(),
    # without disabling, reparenting or scripting player motion.
    if is_open():
        _update_info()
