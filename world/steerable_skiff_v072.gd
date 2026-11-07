extends Node3D
# V0.72 one physically boarded, user-steerable public coastal skiff.
# Control via mobile helm buttons or keyboard ARROWS (when at helm).
# AnimatableBody3D body stays on the physics server and player remains an
# independent CharacterBody3D with a freely walkable deck.
const Helm = preload("res://systems/ocean_helm_rules_v072.gd")
const Waves = preload("res://systems/ocean_hydrodynamics_v071.gd")
var player: CharacterBody3D
var hub: Node
var ocean: Node
var body: AnimatableBody3D
var wake_visual: MultiMeshInstance3D
var wake_mesh: MultiMesh
var helm_panel: PanelContainer
var label: Label
var state: Dictionary = {}
var throttle: float = 0.0
var steering: float = 0.0
var active_helm: bool = false
var cruise_time: float = 0.0
var wake_clock: float = 0.0
var wake_items: Array[Dictionary] = []
var initialized: bool = false
var helm_engagements: int = 0
var boundary_stops: int = 0

func _ready() -> void:
    add_to_group("v072_steerable_skiff")
    set_physics_process(false)

func setup(the_player: CharacterBody3D, the_hub: Node, ocean_service: Node) -> void:
    player = the_player
    hub = the_hub
    ocean = ocean_service
    state = Helm.default_state()
    if not is_instance_valid(player) or not is_instance_valid(hub) \
            or not is_instance_valid(ocean):
        return
    _make_boat()
    _make_wake()
    _make_helm_ui()
    initialized = true
    _place_initial()
    set_physics_process(true)

func _mat(tint: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    material.roughness = 0.86
    return material

func _box(root: Node3D, name: String, at: Vector3, size: Vector3,
        color: Color) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    mesh.name = name
    var block := BoxMesh.new()
    block.size = size
    mesh.mesh = block
    mesh.material_override = _mat(color)
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    mesh.position = at
    root.add_child(mesh)
    return mesh

func _make_boat() -> void:
    body = AnimatableBody3D.new()
    body.name = "V072RealSteerableSkiff"
    body.add_to_group("v072_public_boat_platform")
    body.sync_to_physics = false
    body.collision_layer = 1
    body.collision_mask = 1
    add_child(body)
    var collider := CollisionShape3D.new()
    collider.name = "V072WalkableSteeringDeckCollider"
    var shape := BoxShape3D.new()
    shape.size = Vector3(Helm.LENGTH_M*0.84,0.33,Helm.BEAM_M*0.84)
    collider.shape = shape
    body.add_child(collider)
    _box(body,"V072RealWoodenDeck",Vector3.ZERO,shape.size,
        Color(0.58,0.44,0.30))
    _box(body,"V072Hull",Vector3(0,-0.80,0),
        Vector3(Helm.LENGTH_M,1.8,Helm.BEAM_M),Color(0.24,0.35,0.38))
    for side in [-1.0,1.0]:
        _box(body,"V072WaterRail",
            Vector3(0,0.37,side*Helm.BEAM_M*0.45),
            Vector3(Helm.LENGTH_M*0.92,0.52,0.20),Color(0.38,0.42,0.42))
        for deck_end in [-1.0,1.0]:
            _box(body,"V072DeckCleat",
                Vector3(deck_end*4.7,0.34,side*1.15),
                Vector3(0.45,0.39,0.44),Color(0.55,0.49,0.39))
    _box(body,"V072HelmColumn",Vector3(-2.1,0.96,0),
        Vector3(0.39,1.7,0.43),Color(0.46,0.35,0.27))
    _box(body,"V072ControlWheel",Vector3(-1.8,1.78,0),
        Vector3(0.18,0.64,0.65),Color(0.60,0.48,0.30))
    var sign := Label3D.new()
    sign.name = "V072PublicSkiffHelmSign"
    sign.position = Vector3(-1.8,2.70,0)
    sign.text = "PUBLIC SKIFF / TALK TO STEER / GAME-ONLY"
    sign.font_size = 24
    sign.pixel_size = 0.004
    sign.no_depth_test = true
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    body.add_child(sign)

func _make_wake() -> void:
    wake_visual = MultiMeshInstance3D.new()
    wake_visual.name = "V072FoamAndWaveWakeGPU"
    wake_mesh = MultiMesh.new()
    wake_mesh.transform_format = MultiMesh.TRANSFORM_3D
    wake_mesh.use_colors = true
    var foam := PlaneMesh.new()
    foam.size = Vector2(1.6,2.3)
    wake_mesh.mesh = foam
    wake_mesh.instance_count = Helm.WAKE_LIMIT
    wake_mesh.visible_instance_count = 0
    wake_visual.multimesh = wake_mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.80,0.92,0.92,0.42)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.vertex_color_use_as_albedo = true
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    wake_visual.material_override = material
    wake_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(wake_visual)

func _make_helm_ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.layer = 38
    canvas.name = "V072PublicSmallBoatHelm"
    add_child(canvas)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(root)
    helm_panel = PanelContainer.new()
    helm_panel.anchor_left = 0.56
    helm_panel.anchor_right = 0.98
    helm_panel.anchor_top = 0.07
    helm_panel.anchor_bottom = 0.35
    helm_panel.visible = false
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.03,0.11,0.16,0.96)
    style.border_color = Color(0.66,0.82,0.84)
    style.set_border_width_all(2)
    style.set_corner_radius_all(8)
    helm_panel.add_theme_stylebox_override("panel",style)
    root.add_child(helm_panel)
    var margin := MarginContainer.new()
    for side in ["left","top","right","bottom"]:
        margin.add_theme_constant_override("margin_"+side,9)
    helm_panel.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation",5)
    margin.add_child(stack)
    label = Label.new()
    label.text = "PUBLIC SKIFF / HELM READY"
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",15)
    stack.add_child(label)
    var controls := HBoxContainer.new()
    controls.add_theme_constant_override("separation",3)
    stack.add_child(controls)
    var port := Button.new()
    port.text = "LEFT"
    port.custom_minimum_size.y = 40
    port.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    port.button_down.connect(func(): steering = -1.0)
    port.button_up.connect(_stop_turn)
    controls.add_child(port)
    var faster := Button.new()
    faster.text = "FASTER"
    faster.custom_minimum_size.y = 40
    faster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    faster.pressed.connect(_change_throttle.bind(0.25))
    controls.add_child(faster)
    var slower := Button.new()
    slower.text = "SLOWER"
    slower.custom_minimum_size.y = 40
    slower.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    slower.pressed.connect(_change_throttle.bind(-0.25))
    controls.add_child(slower)
    var starboard := Button.new()
    starboard.text = "RIGHT"
    starboard.custom_minimum_size.y = 40
    starboard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    starboard.button_down.connect(func(): steering = 1.0)
    starboard.button_up.connect(_stop_turn)
    controls.add_child(starboard)
    var release := Button.new()
    release.text = "LEAVE HELM (WALK FREELY)"
    release.custom_minimum_size.y = 42
    release.pressed.connect(release_helm)
    stack.add_child(release)

func _stop_turn() -> void:
    steering = 0.0

func _change_throttle(amount: float) -> void:
    if active_helm:
        throttle = clampf(throttle+amount,0.0,1.0)

func _place_initial() -> void:
    var wind: float = float(ocean.get("weather_state").get("wind_strength",0.45))
    var point: Dictionary = Waves.buoyancy(Helm.START.x,Helm.START.z,0.0,
        wind,Helm.BEAM_M,Helm.LENGTH_M)
    body.position = Helm.START+Vector3(0,float(point["waterline"])+0.92,0)

func get_manifest() -> Dictionary:
    return {"version":72,"initialized":initialized,"physical_skiff":is_instance_valid(body),
        "deck_collidable":true,"helm_active":active_helm,
        "throttle":throttle,"speed_mps":float(state.get("speed",0.0)),
        "wake_samples_visible":wake_items.size(),
        "wake_mesh_max":Helm.WAKE_LIMIT,
        "player_parenting":false,"manual_animated_body_physics":true,
        "same_ocean_wave_samples_as_merchant_ships":true,
        "automatic_foreign_voyage":false,"game_only":true}

func get_nearest_interaction(at: Vector3, reach: float) -> Dictionary:
    if not initialized or not is_instance_valid(body):
        return {}
    var helm_at: Vector3 = body.global_position+Vector3(-1.8,1.42,0)
    if at.distance_to(helm_at) > minf(3.2,reach):
        return {}
    return {"id":"skiff_v072_helm","position":helm_at,
        "node":body,"name":"Public Steerable Skiff"}

func interact(key: String) -> void:
    if key != "skiff_v072_helm" or not initialized:
        return
    if not Helm.can_helm(player.global_position,
            body.global_position+Vector3(-1.8,1.42,0),true,true):
        return
    if active_helm:
        release_helm()
    else:
        active_helm = true
        helm_engagements += 1
        helm_panel.show()
        _refresh_label()

func release_helm() -> void:
    active_helm = false
    throttle = 0.0
    steering = 0.0
    if is_instance_valid(helm_panel):
        helm_panel.hide()

func _refresh_label() -> void:
    if not is_instance_valid(label):
        return
    label.text = "PUBLIC SKIFF | %.1f m/s | engine %d%%\n" % [
        float(state.get("speed",0.0)),roundi(throttle*100.0)]
    label.text += "LEFT/RIGHT to steer. FASTER/SLOWER adjusts speed.\n"
    label.text += "Boat responds to wind and open-sea swell. Walk freely on deck."

func _update_wake() -> void:
    if wake_mesh == null:
        return
    for i in range(wake_items.size()-1,-1,-1):
        if Helm.wake_alpha(wake_items[i],cruise_time) <= 0.001:
            wake_items.remove_at(i)
    var wind: float = float(ocean.get("weather_state").get("wind_strength",0.45))
    wake_mesh.visible_instance_count = mini(wake_items.size(),Helm.WAKE_LIMIT)
    for index in range(wake_mesh.visible_instance_count):
        var item: Dictionary = wake_items[index]
        var trail: Vector3 = item["pos"]
        trail.y = Waves.surface_height(trail.x,trail.z,
            float(ocean.get("seconds")),wind)+0.06
        var fade: float = Helm.wake_alpha(item,cruise_time)
        var scale: float = 0.68+float(index)*0.065
        wake_mesh.set_instance_transform(index,
            Transform3D(Basis.IDENTITY.scaled(Vector3(scale,1.0,scale)),
                trail))
        wake_mesh.set_instance_color(index,Color(0.80,0.93,0.94,fade*0.55))
    wake_visual.visible = wake_mesh.visible_instance_count > 0

func _physics_process(delta: float) -> void:
    if not initialized or not is_instance_valid(ocean) \
            or not bool(ocean.call("is_active")):
        return
    cruise_time += delta
    var wind: Dictionary = ocean.get("weather_state")
    var real_wind: float = float(wind.get("wind_strength",0.42))
    var turn: float = steering
    if active_helm:
        if Input.is_key_pressed(KEY_LEFT):
            turn = -1.0
        elif Input.is_key_pressed(KEY_RIGHT):
            turn = 1.0
        if Input.is_key_pressed(KEY_UP):
            throttle = clampf(throttle+delta*0.45,0.0,1.0)
        elif Input.is_key_pressed(KEY_DOWN):
            throttle = clampf(throttle-delta*0.65,0.0,1.0)
        if player.global_position.distance_to(body.global_position) > \
                Helm.MAX_HELM_DISTANCE_M:
            release_helm()
    var step: Dictionary = Helm.advance(state,turn,throttle,delta,
        real_wind,float(wind.get("wind_direction_rad",0.0)),
        float(ocean.get("seconds")))
    if step.is_empty():
        return
    state = step
    if bool(step["boundary_reached"]):
        boundary_stops += 1
        throttle = 0.0
    var coords: Vector3 = step["pos"]
    body.position = coords+Vector3(0,float(step["wave_waterline"])+0.92,0)
    body.rotation = Vector3(float(step["roll_rad"]),
        float(step["heading"]),float(step["pitch_rad"]))
    if float(step["speed"]) >= 0.6:
        wake_clock += delta
        if wake_clock >= Helm.WAKE_INTERVAL_SECONDS:
            wake_clock = 0.0
            var point: Dictionary = Helm.wake_point(step,cruise_time)
            if not point.is_empty():
                wake_items.push_front(point)
                if wake_items.size() > Helm.WAKE_LIMIT:
                    wake_items.pop_back()
    _update_wake()
    if active_helm:
        _refresh_label()
