extends Node3D
# V0.76 geographically correct published Ring III/IV/V/VII visualization.
# Mounted on existing V0.74 physical 26km city streamer: NO additional
# authored map, physical harbor, NPC faction war or canon shop locations.
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const Rules = preload("res://systems/magnara_published_city_visual_rules_v076.gd")
const CommonsLife = preload("res://world/magnara_commons_life_v080.gd")
const CommonsCart = preload("res://world/magnara_commons_cart_v081.gd")
const MAX_COMMONS_LIGHTS: int = 4
const COMMONS_LIGHT_DISTANCE: float = 24.0
const LANTERN_COLOR := Color(1.0, 0.78, 0.43)
var city: Node3D
var hub: Node
var commons_life: CommonsLife
var commons_cart: CommonsCart
var commons_lights: Array[OmniLight3D] = []
var material_lantern: StandardMaterial3D
var player: CharacterBody3D
var initialized: bool = false
var decorated: Dictionary = {}
var refresh_seconds: float = 0.0
var total_park_patches: int = 0
var total_commons_courts: int = 0
var total_canopies: int = 0
var total_academy_domes: int = 0
var total_market_awnings: int = 0
var total_port_skylines: int = 0
var batch_instances: int = 0
var wall_mesh: BoxMesh
var dome_mesh: SphereMesh
var material_masonry: StandardMaterial3D
var material_glass: StandardMaterial3D
var material_ground: StandardMaterial3D

func _ready() -> void:
    add_to_group("magnara_published_ring_visuals_v076")
    set_process(false)
    call_deferred("_setup")

func _setup() -> void:
    city = get_tree().get_first_node_in_group(
        "magnara_seven_ring_foundation_v074") as Node3D
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(city) or not is_instance_valid(player):
        return
    if not bool(city.get("initialized")):
        call_deferred("_setup")
        return
    if not Rules.correct_source_registry(Rules.audit_registry()):
        push_error("V0.76 needs published-ring canonical audit before city decoration")
        return
    wall_mesh = BoxMesh.new()
    wall_mesh.size = Vector3.ONE
    dome_mesh = SphereMesh.new()
    dome_mesh.radius = 0.5
    dome_mesh.height = 1.0
    dome_mesh.radial_segments = 10
    dome_mesh.rings = 4
    material_masonry = _material(0.88,0.04)
    material_glass = _material(0.31,0.15)
    material_ground = _material(0.97,0.0)
    hub = get_tree().get_first_node_in_group("hub_manager")
    commons_life = CommonsLife.new()
    commons_life.name = "CommonsLifeV080"
    add_child(commons_life)
    commons_life.configure(player, hub)
    commons_cart = CommonsCart.new()
    commons_cart.name = "CommonsCartV081"
    add_child(commons_cart)
    commons_cart.configure(player, hub)
    material_lantern = _material(0.55, 0.0)
    material_lantern.emission_enabled = true
    material_lantern.emission = LANTERN_COLOR
    for index in range(MAX_COMMONS_LIGHTS):
        var light := OmniLight3D.new()
        light.name = "CommonsLanternLight%d" % index
        light.light_color = LANTERN_COLOR
        light.omni_range = 8.0
        light.shadow_enabled = false
        light.hide()
        add_child(light)
        commons_lights.append(light)
    initialized = true
    _refresh_tiles()
    set_process(true)

func _material(roughness: float,metallic: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = Color.WHITE
    m.vertex_color_use_as_albedo = true
    m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    m.roughness = roughness
    m.metallic = metallic
    m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    return m

func _gpu(parent: Node3D,name: String,items: Array,
        shared_mesh: Mesh,material: StandardMaterial3D) -> void:
    if items.is_empty():
        return
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.use_colors = true
    mm.mesh = shared_mesh
    mm.instance_count = items.size()
    for i in range(items.size()):
        var item: Dictionary = items[i]
        mm.set_instance_transform(i,
            Transform3D(Basis.IDENTITY.scaled(item["size"]),item["at"]))
        mm.set_instance_color(i,item["color"])
    var visual := MultiMeshInstance3D.new()
    visual.name = name
    visual.multimesh = mm
    visual.material_override = material
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(visual)

func _attach_to_tile(key: String,chunk: Dictionary) -> void:
    var parent: Node3D = chunk["node"] as Node3D
    if not is_instance_valid(parent):
        return
    var tile: Vector2i = chunk["cell"]
    var art: Dictionary = Rules.tile_art(tile)
    var count: int = art["boxes"].size() + art["domes"].size() \
        + art["parks"].size() + art["lanterns"].size()
    if count == 0:
        return
    var layer := Node3D.new()
    layer.name = "V076PublishedZoneAppearanceNotCanonCoordinates"
    layer.add_to_group("v076_generic_city_zone")
    parent.add_child(layer)
    _gpu(layer,"V076GenericFacadeAndIndustrialSilhouettesGPU",
        art["boxes"],wall_mesh,material_masonry)
    _gpu(layer,"V076AcademyGlassAndCommonsTreesGPU",
        art["domes"],dome_mesh,material_glass)
    _gpu(layer,"V076CommonsParkGroundGPU",
        art["parks"],wall_mesh,material_ground)
    _gpu(layer, "CommonsLanternGlassGPU", art["lanterns"], wall_mesh, material_lantern)
    decorated[key] = {"root":layer,"tile":tile,"lanterns":art["lanterns"],
        "court_centers":art["court_centers"],"count":count,"stats":art["stats"]}

func _refresh_tiles() -> void:
    if not initialized:
        return
    var near: Dictionary = city.get("near_tiles")
    for key in decorated.keys():
        var entry: Dictionary = decorated[key]
        if not near.has(key) or not is_instance_valid(entry["root"]):
            decorated.erase(key)
    for key in near.keys():
        if not decorated.has(key):
            _attach_to_tile(str(key),near[key])
    total_park_patches = 0
    total_commons_courts = 0
    total_canopies = 0
    total_academy_domes = 0
    total_market_awnings = 0
    total_port_skylines = 0
    batch_instances = 0
    for key in decorated.keys():
        var stat: Dictionary = decorated[key]["stats"]
        total_park_patches += int(stat["commons_lawns"])
        total_commons_courts += int(stat["commons_courts"])
        total_canopies += int(stat["commons_canopies"])
        total_academy_domes += int(stat["academy_glass"])
        total_market_awnings += int(stat["market_awnings"])
        total_port_skylines += int(stat["outer_ring_gantries"])
        batch_instances += int(decorated[key]["count"])

    _refresh_commons_lights()
    commons_life.refresh(decorated)
    commons_cart.refresh(decorated)

func _refresh_commons_lights() -> void:
    for light in commons_lights:
        light.hide()
    if not is_instance_valid(hub):
        return
    var hour: float = fposmod(float(hub.get("world_minutes")), 1440.0) / 60.0
    # Fade in at dusk and out at dawn using the saved city clock.
    var night: float = maxf(smoothstep(18.0, 19.0, hour), 1.0 - smoothstep(5.0, 6.0, hour))
    material_lantern.emission_energy_multiplier = night * 1.6
    if night <= 0.0:
        return
    var candidates: Array[Dictionary] = []
    for entry in decorated.values():
        var layer: Node3D = entry["root"]
        for lantern in entry["lanterns"]:
            var at: Vector3 = layer.to_global(lantern["at"])
            var distance: float = player.global_position.distance_squared_to(at)
            if distance <= COMMONS_LIGHT_DISTANCE * COMMONS_LIGHT_DISTANCE:
                candidates.append({"at": at, "distance": distance})
    candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return a["distance"] < b["distance"])
    for index in range(mini(candidates.size(), commons_lights.size())):
        var light: OmniLight3D = commons_lights[index]
        light.global_position = candidates[index]["at"]
        light.light_energy = night * 1.2
        light.show()

func get_manifest() -> Dictionary:
    return {"version":76,"initialized":initialized,
        "actual_source_audited":Rules.correct_source_registry(
            Rules.audit_registry()),
        "render_tiles":decorated.size(),
        "max_render_tiles":Rules.MAX_ACTIVE_ART_TILES,
        "commons_park_patches":total_park_patches,
        "commons_courts":total_commons_courts,
        "commons_canopy_trees":total_canopies,
        "academy_glass_domes":total_academy_domes,
        "market_public_awnings":total_market_awnings,
        "ring_vii_industrial_gantries":total_port_skylines,
        "all_gpu_instances":batch_instances,
        "game_only_architecture_coordinates":true,
        "verified_ring_roles":[3,4,5,7],
        "new_named_canon_buildings":0,"new_named_npc_roster":0,
        "actual_ships_at_ring_two":0,
        "real_ring_vii_coastline_placed":false,
        "fake_god_tree_aura_nerf":false,
        "unverified_red_order_territory_events":false}

func _process(delta: float) -> void:
    if not initialized:
        return
    refresh_seconds += delta
    if refresh_seconds >= 0.70:
        refresh_seconds = 0.0
        _refresh_tiles()
