extends Node3D
# V0.71 accessible scenic preview of Janoah's *known* public maritime
# trading culture. Exact Iron Cothon coastline/city coordinates are UNKNOWN:
# remote scene coordinates, docks, crew, ship schedules and trade-lane
# pairings are explicit GAME-ONLY examples. Restricted military basin sealed.
const Waves = preload("res://systems/ocean_hydrodynamics_v071.gd")
const Trade = preload("res://systems/margerina_commerce_rules_v071.gd")
const SkiffScriptV072 = preload("res://world/steerable_skiff_v072.gd")
const WATER_SHADER = preload("res://shaders/margerina_coastal_waves_v071.gdshader")
const ANCHOR: Vector3 = Vector3(25000.0,0.0,4000.0)
const PUBLIC_ENTRY: Vector3 = Vector3(28.5,0.84,26.0)
const QUAY_SPAWN: Vector3 = ANCHOR + Vector3(-353.0,2.15,-42.0)
const MAX_WORKERS: int = 18
var player: CharacterBody3D
var hub: Node
var codex: Node
var initialized: bool = false
var active: bool = false
var harbor: Node3D
var sea_mesh: MeshInstance3D
var sea_material: ShaderMaterial
var ship_bodies: Array[AnimatableBody3D] = []
var skiff_controller: Node3D
var crew: Array[Node3D] = []
var route_catalog: Dictionary = {}
var return_position: Vector3 = PUBLIC_ENTRY
var seconds: float = 0.0
var weather_state: Dictionary = {}
var info_panel: PanelContainer
var details: Label
var action_button: Button
var return_button: Button
var status_clock: float = 0.0

func _ready() -> void:
    add_to_group("v071_public_ocean")
    set_process(false)
    set_physics_process(false)
    call_deferred("_setup")

func _setup() -> void:
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    route_catalog = Trade.registry()
    if not is_instance_valid(player) or not is_instance_valid(hub) or not Trade.valid_registry(route_catalog):
        push_error("V0.71 sea survey: missing original world or invalid water atlas")
        return
    _make_city_embarkation()
    _make_ui()
    initialized = true
    set_process(true)
    weather_state = Waves.weather(float(hub.get("world_minutes")))

func _mat(tint: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = tint
    m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    m.roughness = 0.84
    return m

func _block(parent: Node3D, name: String, at: Vector3, dims: Vector3,
        color: Color, collides: bool = false) -> MeshInstance3D:
    var box := MeshInstance3D.new()
    box.name = name
    var mesh := BoxMesh.new()
    mesh.size = dims
    box.mesh = mesh
    box.material_override = _mat(color)
    box.position = at
    box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(box)
    if collides:
        var solid := StaticBody3D.new()
        solid.name = name+"Physical"
        box.add_child(solid)
        var hit := CollisionShape3D.new()
        hit.name = "V071DockCollision"
        var shape := BoxShape3D.new()
        shape.size = dims
        hit.shape = shape
        solid.add_child(hit)
    return box

func _sign(parent: Node3D, text_value: String, at: Vector3, font_size: int = 24) -> void:
    var label := Label3D.new()
    label.name = "V071PublicQuaySign"
    label.text = text_value
    label.font_size = font_size
    label.pixel_size = 0.0046
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    label.position = at
    parent.add_child(label)

func _make_city_embarkation() -> void:
    var marker := Node3D.new()
    marker.name = "V071PublicHarborRouteSurvey"
    marker.position = PUBLIC_ENTRY - Vector3(0,0.84,0)
    add_child(marker)
    _block(marker,"V071SurveyCounter",Vector3(0,1.17,0),
        Vector3(1.0,1.0,2.4),Color(0.42,0.37,0.28),true)
    _sign(marker,"IRON COTHON / CIVIL SHIPPING SURVEY (GAME-ONLY LOCATION)",
        Vector3(0,3.4,0),23)
    var approach := Node3D.new()
    approach.name = "V071PublicHarborApproach"
    approach.position = Vector3(-2.4,0.84,0)
    marker.add_child(approach)
    hub.call("_add_location","ocean_v071_board","Iron Cothon / Civil Commerce Survey",
        approach.global_position,approach)

func _make_ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.layer = 36
    canvas.name = "V071OceanTradeLayer"
    get_parent().add_child(canvas)
    var screen := Control.new()
    screen.set_anchors_preset(Control.PRESET_FULL_RECT)
    screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(screen)
    info_panel = PanelContainer.new()
    info_panel.anchor_left = 0.08
    info_panel.anchor_right = 0.92
    info_panel.anchor_top = 0.075
    info_panel.anchor_bottom = 0.925
    info_panel.visible = false
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.032,0.09,0.14,0.985)
    style.border_color = Color(0.50,0.72,0.81)
    style.set_border_width_all(2)
    style.set_corner_radius_all(9)
    info_panel.add_theme_stylebox_override("panel",style)
    screen.add_child(info_panel)
    var margin := MarginContainer.new()
    for side in ["left","right","top","bottom"]:
        margin.add_theme_constant_override("margin_"+side,16)
    info_panel.add_child(margin)
    var scrolling := ScrollContainer.new()
    scrolling.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scrolling.size_flags_vertical = Control.SIZE_EXPAND_FILL
    margin.add_child(scrolling)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation",12)
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scrolling.add_child(stack)
    var title := Label.new()
    title.text = "IRON COTHON / PUBLIC MARITIME TRADE SURVEY"
    title.add_theme_font_size_override("font_size",22)
    title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(title)
    details = Label.new()
    details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    details.custom_minimum_size.y = 270
    stack.add_child(details)
    action_button = Button.new()
    action_button.text = "VISIT PUBLIC HARBOR SURVEY / SCENIC PREVIEW"
    action_button.custom_minimum_size.y = 52
    action_button.pressed.connect(_enter)
    stack.add_child(action_button)
    return_button = Button.new()
    return_button.text = "RETURN TO MAGNARA"
    return_button.custom_minimum_size.y = 52
    return_button.pressed.connect(_leave)
    stack.add_child(return_button)
    var close := Button.new()
    close.text = "CLOSE"
    close.custom_minimum_size.y = 50
    close.pressed.connect(_close)
    stack.add_child(close)

func is_open() -> bool:
    return is_instance_valid(info_panel) and info_panel.visible

func is_active() -> bool:
    return active

func get_safe_save_position() -> Vector3:
    return return_position if active else PUBLIC_ENTRY

func get_manifest() -> Dictionary:
    return {"version":71,"built":initialized,"active":active,
        "loaded_visual_ocean":active and is_instance_valid(sea_mesh),
        "shader_vertex_waves":true,"cpu_gpu_wave_formula_mirrored":true,
        "offshore_wind_swell":true,"buoyancy_sample_points":4,
        "ship_classes":["small","medium","large"],
        "ships":ship_bodies.size(),"public_dock_workers":crew.size(),
        "v072_helm_enabled":true,"v072_skiff":is_instance_valid(skiff_controller),
        "trade_route_status":"game_only_hypothetical_visualization",
        "atlas_waters":route_catalog.get("waters",[]).size(),
        "canon_harbor_military_basin_access":false,
        "actual_country_arrival_navigation":false,
        "real_live_weather_api":false}

func _close() -> void:
    if is_instance_valid(info_panel):
        info_panel.hide()

func _info() -> void:
    if not is_instance_valid(details):
        return
    var day: int = 1+floori(maxf(0.0,float(hub.get("world_minutes")))/1440.0)
    var trade: Dictionary = Trade.public_summary(day,seconds,route_catalog)
    var weather: Dictionary = weather_state
    details.text = "Janoah Sea / coastal scene survey\n"
    details.text += "Weather: %s | Wind %.0f%% | Wind waves respond offshore\n" % [
        str(weather.get("sky","calm")).replace("_"," "),
        float(weather.get("wind_strength",0.0))*100.0]
    details.text += "Civil vessels visible: %d | Incoming: %d | Outbound: %d\n" % [
        ship_bodies.size(),int(trade.get("inbound",0)),int(trade.get("outbound",0))]
    details.text += "3 classes: small boats, coastal cargo, large merchant vessels.\n"
    details.text += "V0.72: One extra player-steerable public skiff and animated foam wake.\n"
    details.text += "Ship decks bob and pitch on CPU-sampled waves; the sea is animated on the GPU.\n"
    details.text += "Known sea names and Lake Lukka appear in the atlas; their borders are NOT invented.\n"
    details.text += "This is a provisional public commercial basin with no military-basin access.\n"
    details.text += "Destination labels are GAME-ONLY trade simulations, not confirmed international routes.\n"
    for i in range(Trade.SHIP_COUNT):
        var report: Dictionary = Trade.ship_state(i,seconds,day,route_catalog)
        var manifest: Dictionary = report.get("manifest",{})
        details.text += "%s / %s / %s / %s\n" % [
            str(manifest.get("label","Vessel")),
            str(manifest.get("size","small")),
            str(manifest.get("destination","unknown")),
            str(report.get("activity","loading"))]
    action_button.disabled = active
    return_button.disabled = not active

func interact(key: String) -> void:
    if not initialized:
        return
    if key == "ocean_v071_board":
        if player.global_position.distance_to(PUBLIC_ENTRY-Vector3(2.4,0,0)) > float(hub.get("interact_range")):
            return
    elif key == "ocean_v071_return":
        if not active:
            return
    elif key.begins_with("ocean_v071_ship_"):
        if not active:
            return
    elif key.begins_with("skiff_v072_"):
        if active and is_instance_valid(skiff_controller):
            skiff_controller.call("interact",key)
        return
    else:
        return
    _info()
    info_panel.show()

func get_nearest_skiff_interaction(point: Vector3, reach: float) -> Dictionary:
    if active and is_instance_valid(skiff_controller) \
            and skiff_controller.has_method("get_nearest_interaction"):
        return skiff_controller.call("get_nearest_interaction",point,reach)
    return {}

func _make_harbor() -> void:
    harbor = Node3D.new()
    harbor.name = "V071PhysicalCivilHarborPreview"
    harbor.add_to_group("v071_streamed_ocean_tile")
    add_child(harbor)
    # A global transform may only be applied AFTER a Node3D enters tree.
    # Earlier placement emitted Godot's !is_inside_tree() warning and could
    # desynchronize the ship physics hulls from the ocean survey geometry.
    harbor.global_position = ANCHOR
    var patch := PlaneMesh.new()
    patch.size = Vector2(Waves.TILE_WIDTH,Waves.TILE_WIDTH)
    patch.subdivide_width = 96
    patch.subdivide_depth = 96
    sea_material = ShaderMaterial.new()
    sea_material.shader = WATER_SHADER
    sea_material.set_shader_parameter("sea_wind",float(weather_state.get("wind_strength",0.45)))
    sea_material.set_shader_parameter("sea_seconds",seconds)
    sea_mesh = MeshInstance3D.new()
    sea_mesh.name = "V071WeatherResponsiveOceanMesh"
    sea_mesh.mesh = patch
    sea_mesh.material_override = sea_material
    sea_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    sea_mesh.custom_aabb = AABB(Vector3(-500,-3,-500),Vector3(1000,6,1000))
    harbor.add_child(sea_mesh)
    # West shore is deliberately scenic planning massing, not a mapped
    # Janoah coastline. Quay and finger piers are actually walkable solids.
    _block(harbor,"V071PublicQuaysideLand",Vector3(-416,0.65,0),
        Vector3(168,1.25,700),Color(0.49,0.48,0.42),true)
    _block(harbor,"V071PrimaryQuay",Vector3(-334,1.16,0),
        Vector3(27,0.36,570),Color(0.62,0.60,0.54),true)
    for index in range(Trade.SHIP_COUNT):
        var lane_z: float = -250.0+float(index)*100.0
        var manifest: Dictionary = Trade.ship_manifest(index,
            1+floori(float(hub.get("world_minutes"))/1440.0),route_catalog)
        var hull: Dictionary = Waves.ship_class(str(manifest["size"]))
        # Finger piers run alongside the port gunwale. Never overlap the
        # ship's *actual deck* at its center; overlapping static pier collision
        # steals platform physics and prevents ordinary movement onboard.
        var pier_z: float = lane_z-(float(hull["beam"])*0.45+2.7)
        _block(harbor,"V071FingerPier_%d" % index,
            Vector3(-266,1.18,pier_z),Vector3(137,0.30,7.2),
            Color(0.52,0.50,0.42),true)
        for n in range(3):
            _block(harbor,"V071PierBollard",Vector3(-315+float(n)*39,1.55,pier_z-3.1),
                Vector3(1.3,0.52,1.3),Color(0.22,0.24,0.27),true)
        _sign(harbor,"PUBLIC CARGO BERTH %d" % (index+1),
            Vector3(-312,3.70,pier_z),22)
    # This dedicated public berth sits south of the commercial lanes.
    # Its slim pier touches the main quay yet stays outside the skiff deck,
    # leaving a real jumpable gap without overlapping physics colliders.
    _block(harbor,"V072SkiffQuayConnector",Vector3(-329,1.18,-293.0),
        Vector3(7.5,0.30,23.0),Color(0.58,0.53,0.44),true)
    _block(harbor,"V072SkiffPublicFingerPier",Vector3(-266,1.18,-304.0),
        Vector3(137,0.30,4.6),Color(0.57,0.52,0.44),true)
    _sign(harbor,"PUBLIC HELM TRAINING / BOARD ON FOOT / GAME-ONLY",
        Vector3(-310,4.4,-304.0),19)
    for i in range(15):
        var z: float = -273.0+float(i)*39.0
        _block(harbor,"V071WarehouseCargoStack",Vector3(-390,1.60,z),
            Vector3(7.2,1.20,5.5),Color(0.50,0.39,0.26),true)
        if i % 3 == 0:
            _block(harbor,"V071PublicWarehouse",Vector3(-435,3.4,z),
                Vector3(30.0,5.4,22.0),Color(0.43,0.40,0.37),true)
    _sign(harbor,"IRON COTHON / PUBLIC TRADE SIMULATION / MILITARY BASIN RESTRICTED",
        Vector3(-348,8.2,-32),30)
    _make_workers()
    _make_ships()
    skiff_controller = SkiffScriptV072.new()
    skiff_controller.name = "V072PublicSteerableHarborSkiff"
    harbor.add_child(skiff_controller)
    skiff_controller.call("setup",player,hub,self)
    var marker := Node3D.new()
    marker.name = "V071ReturnToCity"
    marker.position = Vector3(-346,2.1,-44)
    harbor.add_child(marker)
    _sign(marker,"RETURN TO MAGNARA / TALK + USE",Vector3(0,3.0,0))
    hub.call("_add_location","ocean_v071_return",
        "Return from the Public Maritime Survey",marker.global_position,marker)

func _make_workers() -> void:
    for i in range(MAX_WORKERS):
        var person := Node3D.new()
        person.name = "V071DockWorker_%02d" % i
        person.add_to_group("v071_game_only_dock_worker")
        harbor.add_child(person)
        var color: Color = Color(0.31+0.08*float(i%4),0.39,0.49)
        _block(person,"V071WorkerCoat",Vector3(0,1.08,0),
            Vector3(0.59,1.05,0.41),color)
        _block(person,"V071WorkerHead",Vector3(0,1.80,0),
            Vector3(0.38,0.39,0.35),Color(0.69,0.50,0.37))
        _block(person,"V071WorkerBoots",Vector3(0,0.45,0),
            Vector3(0.47,0.58,0.42),Color(0.20,0.22,0.25))
        crew.append(person)

func _make_ships() -> void:
    for i in range(Trade.SHIP_COUNT):
        var day: int = 1+floori(float(hub.get("world_minutes"))/1440.0)
        var manifest: Dictionary = Trade.ship_manifest(i,day,route_catalog)
        var specs: Dictionary = Waves.ship_class(str(manifest["size"]))
        var width: float = float(specs["beam"])
        var length: float = float(specs["length"])
        var vessel := AnimatableBody3D.new()
        vessel.name = "V071MerchantVessel_%02d" % i
        vessel.sync_to_physics = false
        vessel.add_to_group("v071_physical_merchant_ship")
        harbor.add_child(vessel)
        vessel.collision_layer = 1
        vessel.collision_mask = 1
        var deck := CollisionShape3D.new()
        deck.name = "V071ShipWalkableDeckCollision"
        var box := BoxShape3D.new()
        box.size = Vector3(length*0.80,0.34,width*0.75)
        deck.shape = box
        vessel.add_child(deck)
        _block(vessel,"V071DeckMesh",Vector3.ZERO,box.size,
            Color(0.55,0.43,0.29))
        _block(vessel,"V071Hull",Vector3(0,-0.91,0),
            Vector3(length,1.85,width),Color(0.22+0.06*float(i%3),0.28,0.35))
        _block(vessel,"V071RaisedBridge",Vector3(-length*0.22,1.30,0),
            Vector3(length*0.20,2.55,width*0.56),Color(0.48,0.47,0.42))
        for side in [-1.0,1.0]:
            _block(vessel,"V071Gunwale",Vector3(0,0.38,side*width*0.43),
                Vector3(length*0.90,0.60,0.23),Color(0.34,0.36,0.39))
        for cargo in range(3 if str(manifest["size"])=="small" else 6):
            var x: float = -length*0.12+float(cargo%3)*length*0.13
            var z: float = (float(int(cargo/3))-0.5)*width*0.28
            _block(vessel,"V071OnboardCargo",Vector3(x,0.68,z),
                Vector3(length*0.09,1.08,width*0.19),Color(0.55,0.40,0.23))
        _sign(vessel,"CARGO / "+str(manifest["destination"]).to_upper(),
            Vector3(-length*0.32,4.1,0),18)
        ship_bodies.append(vessel)

func _enter() -> void:
    if not initialized or active or player.global_position.distance_to(PUBLIC_ENTRY) > 7.0:
        return
    return_position = player.global_position
    if return_position.distance_to(PUBLIC_ENTRY) > 7.0:
        return_position = PUBLIC_ENTRY
    seconds = 0.0
    weather_state = Waves.weather(float(hub.get("world_minutes")))
    _make_harbor()
    active = true
    _close()
    player.velocity = Vector3.ZERO
    player.global_position = QUAY_SPAWN
    set_physics_process(true)
    if codex.has_method("record_event"):
        codex.call("record_event","v071:public_trade_survey",
            "public_navigation","Visited the scenic public maritime survey",
            "Observed civilian merchant vessels and weather-driven Janoah Sea waves, game-only coordinates.")

func _leave() -> void:
    if not active:
        _close()
        return
    var destination: Vector3 = get_safe_save_position()
    active = false
    set_physics_process(false)
    # A temporarily spawned return point must not remain as a stale
    # permanent location after its entire remote scene has been freed.
    var registered: Array = hub.get("locations")
    for i in range(registered.size()-1,-1,-1):
        if str(registered[i].get("id","")) == "ocean_v071_return":
            registered.remove_at(i)
    hub.set("locations",registered)
    if is_instance_valid(skiff_controller) and skiff_controller.has_method("release_helm"):
        skiff_controller.call("release_helm")
    skiff_controller = null
    ship_bodies.clear()
    crew.clear()
    sea_mesh = null
    sea_material = null
    if is_instance_valid(harbor):
        harbor.queue_free()
        harbor = null
    player.velocity = Vector3.ZERO
    player.global_position = destination
    _close()

func surface_at(world_at: Vector3) -> Dictionary:
    if not active:
        return {}
    var p: Vector3 = world_at-ANCHOR
    if not Waves.in_ocean_tile(p.x,p.z):
        return {}
    var wind: float = float(weather_state.get("wind_strength",0.45))
    return {"height":Waves.surface_height(p.x,p.z,seconds,wind),
        "normal":Waves.surface_normal(p.x,p.z,seconds,wind),
        "wind":wind,"offshore":Waves.offshore_factor(p.x),
        "moving_surface":true}

func is_water_here(world_at: Vector3) -> bool:
    return active and Waves.in_ocean_tile(world_at.x-ANCHOR.x,world_at.z-ANCHOR.z)

func _physics_process(delta: float) -> void:
    if not active:
        return
    seconds += delta
    var day: int = 1+floori(float(hub.get("world_minutes"))/1440.0)
    var wind: float = float(weather_state.get("wind_strength",0.45))
    for index in range(ship_bodies.size()):
        var body: AnimatableBody3D = ship_bodies[index]
        var route: Dictionary = Trade.ship_state(index,seconds,day,route_catalog)
        var local: Vector3 = route["pos"]
        var props: Dictionary = Waves.ship_class(str(route["manifest"]["size"]))
        var sample: Dictionary = Waves.buoyancy(local.x,local.z,seconds,wind,
            float(props["beam"]),float(props["length"]))
        body.global_position = ANCHOR + local + Vector3(0,float(sample["waterline"])+1.05,0)
        body.rotation = Vector3(float(sample["roll_rad"]),0,float(sample["pitch_rad"]))
        body.visible = not bool(route.get("offscreen",false))
        body.collision_layer = 0 if bool(route.get("offscreen",false)) else 1
    # Model 18 dockside residents in scheduled shifts, without ever spawning
    # as chapter-canon main cast or as military-dock personnel.
    var now: float = float(hub.get("world_minutes"))
    for i in range(crew.size()):
        var person: Node3D = crew[i]
        var time: float = fposmod(now+float(i*31),1440.0)
        var shift: bool = time >= 380.0 and time <= 1290.0
        person.visible = shift
        if shift:
            var move: float = sin(seconds*0.38+float(i)*0.73)*3.3
            person.position = Vector3(-345.0+float(i%3)*7.0,1.42,
                -245.0+float(i/3)*89.0+move)
    if player.global_position.y < ANCHOR.y-10.0 and is_water_here(player.global_position):
        # Rescue only from the bottom of the scenic test ocean; no player KO
        # or canonical Archwheel resurrection is inferred.
        player.global_position = QUAY_SPAWN
        player.velocity = Vector3.ZERO

func _process(delta: float) -> void:
    if not active:
        return
    status_clock += delta
    if status_clock >= 0.5:
        status_clock = 0.0
        weather_state = Waves.weather(float(hub.get("world_minutes")))
        if is_open():
            _info()
    if is_instance_valid(sea_material):
        sea_material.set_shader_parameter("sea_seconds",seconds)
        sea_material.set_shader_parameter("sea_wind",float(weather_state.get("wind_strength",0.45)))
