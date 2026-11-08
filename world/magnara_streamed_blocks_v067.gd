extends Node3D
# V0.67 - reusable architectural modules, 128m streamed city blocks,
# MultiMesh GPU instancing, distance-based pedestrian LOD and mobile dialogue.
# Builds *game-only scenic housing* in Ring II's northern survey extension.
# Canon interiors, published businesses and the original browser game are
# protected. No claim of an entire 26 km completed city.
const Rules = preload("res://systems/magnara_stream_rules_v067.gd")
const Roof = preload("res://systems/magnara_roof_rules_v068.gd")
const MAT_COLORS: Array[Color] = [
    Color(0.64, 0.60, 0.55), Color(0.60, 0.63, 0.64),
    Color(0.53, 0.56, 0.59), Color(0.65, 0.59, 0.53),
    Color(0.56, 0.55, 0.52)
]
const MID_PALETTE: Array[Color] = [
    Color(0.48, 0.58, 0.63), Color(0.72, 0.57, 0.43),
    Color(0.59, 0.63, 0.49), Color(0.61, 0.53, 0.67),
    Color(0.55, 0.59, 0.64)
]
var player: CharacterBody3D
var hub: Node
var codex: Node
var initialized: bool = false
var active_chunks: Dictionary = {}
var near_models: Dictionary = {}
var resident_records: Dictionary = {}
var building_mesh: BoxMesh
var instanced_material: StandardMaterial3D
var close_materials: Dictionary = {}
var world_tick: float = 0.0
var panel: PanelContainer
var panel_title: Label
var panel_details: Label
var panel_response: Label
var current_speaker: String = ""
var crowd_stats: Dictionary = {"near": 0, "mid": 0, "far": 0, "physically_active_colliders": 0}

func _ready() -> void:
    add_to_group("magnara_streamed_blocks_v067")
    set_process(false)
    call_deferred("_initialize")

func _initialize() -> void:
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(player):
        push_warning("V0.67 chunk streaming requires the existing Ring II player, hub and Codex")
        return
    building_mesh = BoxMesh.new()
    building_mesh.size = Vector3.ONE
    instanced_material = StandardMaterial3D.new()
    instanced_material.albedo_color = Color.WHITE
    instanced_material.vertex_color_use_as_albedo = true
    instanced_material.roughness = 0.88
    instanced_material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    instanced_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    _link_old_avenue()
    _make_conversation_ui()
    initialized = true
    _refresh_chunks()
    _refresh_crowds()
    set_process(true)

func get_manifest() -> Dictionary:
    return {
        "version": 67, "era": "1500 A.S.", "city": "Magnara", "district": "Ring II / game-only northern blocks",
        "chunk_size_m": Rules.TILE_M, "max_loaded_chunks": Rules.ACTIVE_CAP,
        "active_chunk_count": active_chunks.size(),
        "maximum_authored_chunks": (Rules.MAX_COL - Rules.MIN_COL + 1) * (Rules.MAX_ROW - Rules.MIN_ROW + 1),
        "procedural_parcels_per_chunk": Rules.PARCELS_PER_CHUNK,
        "total_available_scaffold_buildings": 15 * Rules.PARCELS_PER_CHUNK,
        "active_close_npcs": near_models.size(),
        "new_individual_citizens_per_chunk": Rules.RESIDENTS_PER_CHUNK,
        "population_lod_close_m": Rules.CLOSE_M,
        "population_lod_mid_m": Rules.MID_M,
        "lod_strategy": "close multi-part collision, mid MultiMesh sidewalk rail, far unrendered",
        "renderer_strategy": "chunk-batched MultiMesh, renderer frustum and distance checks",
        "v068_roof_parkour": true,
        "v068_roof_route_count_per_chunk": Roof.ACCESS_PER_CHUNK,
        "v068_physics_roof_decks": true,
        "v068_toon_lighting": "Godot 4.4 built-in StandardMaterial3D Toon diffuse",
        "cpu_occlusion_baked": false,
        "why_no_cpu_occlusion": "Godot Compatibility Web and iPhone CPU cost; enable and benchmark later where renderer supports it",
        "new_module_kit": Rules.MODULE_TYPES,
        "streaming_deletes_out_of_range_nodes": true,
        "canon_story_population": "separate author-gated V0.65 and V0.66 registries",
        "original_buildings_and_story_untouched": true
    }

func active_chunk_count() -> int:
    return active_chunks.size()

func active_chunk_keys() -> Array:
    var keys: Array = active_chunks.keys()
    keys.sort()
    return keys

func close_count() -> int:
    return near_models.size()

func loaded_building_count() -> int:
    var count: int = 0
    for info in active_chunks.values():
        count += (info["parcels"] as Array).size()
    return count

func _shade(color: Color) -> StandardMaterial3D:
    var key: String = str(color)
    if close_materials.has(key):
        return close_materials[key]
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.84
    material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    close_materials[key] = material
    return material

func _mesh_piece(parent: Node3D, name: String, at: Vector3, size: Vector3,
        tint: Color, physical: bool = false) -> MeshInstance3D:
    var visual := MeshInstance3D.new()
    visual.name = name
    var cuboid := BoxMesh.new()
    cuboid.size = size
    visual.mesh = cuboid
    visual.material_override = _shade(tint)
    visual.position = at
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(visual)
    if physical:
        var body := StaticBody3D.new()
        visual.add_child(body)
        var collider := CollisionShape3D.new()
        collider.name = "V067StreetCollision"
        var bounds := BoxShape3D.new()
        bounds.size = size
        collider.shape = bounds
        body.add_child(collider)
    return visual

func _link_old_avenue() -> void:
    # Shops from V0.66 finish at 707 m. Preserve their original streets and
    # bridge into the first V0.67 east/west cross street at z=720.
    var link := Node3D.new()
    link.name = "V067StableOldCityStreetConnector"
    add_child(link)
    for x in [-62.0, 0.0, 62.0]:
        _mesh_piece(link, "V067SouthernRoadConnector", Vector3(x, 0.67, 711.0),
            Vector3(10.4, 0.11, 27.0), Color(0.66, 0.65, 0.61), true)
    _mesh_piece(link, "V067NorthCrossStreet", Vector3(0, 0.68, 720.0),
        Vector3(256.0, 0.13, 10.0), Color(0.66, 0.65, 0.61), true)
    var title := Label3D.new()
    title.name = "V067ModularStreetSign"
    title.position = Vector3(0, 6.2, 727)
    title.text = "MAGNARA / RING TWO / LIVING NORTHERN BLOCKS"
    title.font_size = 28
    title.pixel_size = 0.005
    title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    title.no_depth_test = true
    link.add_child(title)

func _add_kit_piece(storage: Dictionary, part_type: String, center: Vector3,
        size: Vector3, tint: Color) -> void:
    var group: Array = storage.get(part_type, [])
    group.append({"center": center, "size": size, "color": tint})
    storage[part_type] = group

func _make_city_kit(root: Node3D, parcel_specs: Array) -> Dictionary:
    var pieces: Dictionary = {}
    for type in Rules.MODULE_TYPES:
        pieces[type] = []
    for parcel_data in parcel_specs:
        var parcel: Dictionary = parcel_data
        var base: Vector3 = parcel["center"]
        var width: float = float(parcel["width"])
        var depth: float = float(parcel["depth"])
        var floors: int = int(parcel["floors"])
        var shade: Color = MAT_COLORS[int(parcel["palette"])]
        var face: float = 1.0 if base.x < 0.0 else -1.0
        var ground_height: float = 3.20
        var building_top: float = 0.56 + ground_height + float(floors) * 2.75
        _add_kit_piece(pieces, "ground", base + Vector3(0, 0.56 + 1.60, 0),
            Vector3(width, ground_height, depth), shade)
        for f in range(floors):
            var elevation: float = 0.56 + ground_height + float(f) * 2.75 + 1.37
            _add_kit_piece(pieces, "middle", base + Vector3(0, elevation, 0),
                Vector3(width * 0.985, 2.73, depth * 0.985),
                shade.darkened(0.024 * float(f % 3)))
            for j in [-1.0, 1.0]:
                _add_kit_piece(pieces, "window",
                    base + Vector3(face * (width * 0.5 + 0.06), elevation + 0.02,
                        j * depth * 0.23),
                    Vector3(0.13, 1.31, 1.50),
                    Color(0.25, 0.48 + float((f + int(parcel["palette"])) % 3) * 0.06, 0.59))
        var roof_color: Color = Color(0.26, 0.29, 0.31) if int(parcel["roof_style"]) != 2 else Color(0.39, 0.31, 0.27)
        _add_kit_piece(pieces, "roof", base + Vector3(0, building_top + 0.18, 0),
            Vector3(width + 1.05, 0.37, depth + 1.05), roof_color)
        if bool(parcel["awnings"]):
            _add_kit_piece(pieces, "awning",
                base + Vector3(face * (width * 0.50 + 1.0), 3.11, 0),
                Vector3(2.2, 0.14, depth * 0.55),
                Color(0.53, 0.35, 0.25) if int(parcel["roof_style"]) == 0 else Color(0.28, 0.43, 0.49))
        if bool(parcel["balconies"]):
            _add_kit_piece(pieces, "balcony",
                base + Vector3(face * (width * 0.50 + 0.68), 5.74, 0),
                Vector3(1.49, 0.16, depth * 0.39), Color(0.48, 0.42, 0.34))
    var groups: Dictionary = {}
    for type in Rules.MODULE_TYPES:
        var instances: Array = pieces[type]
        if instances.is_empty():
            continue
        var geometry := MultiMesh.new()
        geometry.transform_format = MultiMesh.TRANSFORM_3D
        geometry.use_colors = true
        geometry.mesh = building_mesh
        geometry.instance_count = instances.size()
        for i in range(instances.size()):
            var spec: Dictionary = instances[i]
            var transform := Transform3D(Basis.IDENTITY.scaled(spec["size"]), spec["center"])
            geometry.set_instance_transform(i, transform)
            geometry.set_instance_color(i, spec["color"])
        var visual := MultiMeshInstance3D.new()
        visual.name = "V067ModularKit_" + str(type)
        visual.multimesh = geometry
        visual.material_override = instanced_material
        visual.visibility_range_end = 325.0
        visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        root.add_child(visual)
        groups[type] = visual
    return groups

func _add_building_colliders(root: Node3D, parcels: Array) -> Array:
    var blockers: Array = []
    for spec_data in parcels:
        var spec: Dictionary = spec_data
        var body := StaticBody3D.new()
        body.name = "V067NearBuildingCollider_" + str(spec["id"]).replace(":", "_")
        var anchor: Vector3 = spec["center"]
        var height: float = float(spec["height"])
        body.position = anchor + Vector3(0, 0.56 + height * 0.5, 0)
        root.add_child(body)
        var collision := CollisionShape3D.new()
        collision.name = "V067DistanceGatedCollision"
        var geometry := BoxShape3D.new()
        geometry.size = Vector3(float(spec["width"]), height, float(spec["depth"]))
        collision.shape = geometry
        collision.disabled = true
        body.add_child(collision)
        blockers.append({"body": body, "shape": collision})
    return blockers

func _make_rooftop_network(root: Node3D, cell: Vector2i) -> Array:
    # Real, individually physics-backed parkour boards, with one GPU batch for
    # stair platforms and another for roof-to-roof maintenance decks.
    # Collision is enabled only while the player is nearby in _refresh_crowds.
    var network := Node3D.new()
    network.name = "V068PhysicalRooftopRoutes"
    network.add_to_group("v068_rooftop_parkour")
    root.add_child(network)
    var colliders: Array = []
    var geometry: Dictionary = {"stair": [], "bridge": []}
    var entries: Array[Dictionary] = Roof.roof_routes(cell)
    for entry in entries:
        var kind: String = str(entry["kind"])
        var body := StaticBody3D.new()
        body.name = "V068RoofSolid_" + str(entry["id"]).replace(":", "_")
        body.position = entry["local_position"]
        body.add_to_group("v068_roof_physical")
        network.add_child(body)
        var hitbox := CollisionShape3D.new()
        hitbox.name = "V068RoofCollision"
        var block := BoxShape3D.new()
        block.size = entry["size"]
        hitbox.shape = block
        hitbox.disabled = true
        body.add_child(hitbox)
        colliders.append({"body": body, "shape": hitbox, "kind": kind, "id": str(entry["id"])})
        if kind != "roof":
            var drawn: Array = geometry[kind]
            drawn.append(entry)
            geometry[kind] = drawn
    for kind in ["stair", "bridge"]:
        var specs: Array = geometry[kind]
        if specs.is_empty():
            continue
        var mm := MultiMesh.new()
        mm.transform_format = MultiMesh.TRANSFORM_3D
        mm.use_colors = true
        mm.mesh = building_mesh
        mm.instance_count = specs.size()
        var tint: Color = Color(0.78, 0.59, 0.38) if kind == "stair" else Color(0.48, 0.65, 0.70)
        for n in range(specs.size()):
            var record: Dictionary = specs[n]
            mm.set_instance_transform(n, Transform3D(
                Basis.IDENTITY.scaled(record["size"]), record["local_position"]))
            mm.set_instance_color(n, tint)
        var visual := MultiMeshInstance3D.new()
        visual.name = "V068RooftopGPU_" + kind
        visual.multimesh = mm
        visual.material_override = instanced_material
        visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        network.add_child(visual)
    for side in [-1.0, 1.0]:
        var sign := Label3D.new()
        sign.name = "V068RoofJumpHint"
        sign.text = "ROOF ROUTE / RUN + JUMP / DOUBLE JUMP ACROSS"
        sign.position = Vector3(side * 13.0, 3.5, 27.0)
        sign.font_size = 21
        sign.pixel_size = 0.0043
        sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        sign.no_depth_test = true
        network.add_child(sign)
    return colliders

func _crowd_geometry(root: Node3D) -> MultiMeshInstance3D:
    var people := MultiMesh.new()
    people.transform_format = MultiMesh.TRANSFORM_3D
    people.use_colors = true
    people.mesh = TownspersonVisual.mid_mesh()
    people.instance_count = Rules.RESIDENTS_PER_CHUNK
    for i in range(Rules.RESIDENTS_PER_CHUNK):
        people.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(0.001,0.001,0.001)),
            Vector3.ZERO))
        people.set_instance_color(i, MID_PALETTE[i % MID_PALETTE.size()])
    people.visible_instance_count = 0
    var visual := MultiMeshInstance3D.new()
    visual.name = "V067MediumCrowdInstanced"
    visual.multimesh = people
    visual.material_override = instanced_material
    visual.visibility_range_end = 165.0
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(visual)
    return visual

func _build_chunk(cell: Vector2i) -> void:
    var id: String = Rules.key(cell)
    if not Rules.allowed(cell) or active_chunks.has(id):
        return
    var chunk := Node3D.new()
    chunk.name = "V067StreamChunk_" + id.replace(":", "_").replace("-", "m")
    chunk.add_to_group("magnara_stream_chunk_v067")
    chunk.position = Rules.origin(cell)
    add_child(chunk)
    var streets := Node3D.new()
    streets.name = "V067ChunkStreets"
    chunk.add_child(streets)
    # One contiguous spine and three transverse pieces per 128m block.
    _mesh_piece(streets, "V067ChunkMainStreet", Vector3(0, 0.64, 64.0),
        Vector3(10.3, 0.14, 128.0), Color(0.65, 0.64, 0.59), true)
    _mesh_piece(streets, "V067ChunkCrossAvenueSouth", Vector3(0, 0.66, 0),
        Vector3(128.0, 0.13, 9.8), Color(0.65, 0.64, 0.59), true)
    _mesh_piece(streets, "V067ChunkCrossAvenueNorth", Vector3(0, 0.66, 128.0),
        Vector3(128.0, 0.13, 9.8), Color(0.65, 0.64, 0.59), true)
    for side in [-1.0, 1.0]:
        _mesh_piece(streets, "V067ChunkSidewalk", Vector3(side * 8.7, 0.66, 64.0),
            Vector3(2.6, 0.12, 127.8), Color(0.77, 0.74, 0.67), true)
    var specs: Array = []
    for i in range(Rules.PARCELS_PER_CHUNK):
        specs.append(Rules.parcel(cell, i))
    var kit: Dictionary = _make_city_kit(chunk, specs)
    var blockers: Array = _add_building_colliders(chunk, specs)
    var rooftop: Array = _make_rooftop_network(chunk, cell)
    var crowd: MultiMeshInstance3D = _crowd_geometry(chunk)
    active_chunks[id] = {
        "cell": cell, "node": chunk, "kit": kit, "parcels": specs,
        "colliders": blockers, "roof_shapes": rooftop, "crowd": crowd, "citizens": Rules.residents(cell)
    }
    for person in active_chunks[id]["citizens"]:
        resident_records[str(person["id"])] = person

func _drop_chunk(key: String) -> void:
    if not active_chunks.has(key):
        return
    var chunk: Dictionary = active_chunks[key]
    for resident in chunk["citizens"]:
        var id: String = str(resident["id"])
        _remove_close_model(id)
        resident_records.erase(id)
    active_chunks.erase(key)
    var node: Node3D = chunk["node"]
    if is_instance_valid(node):
        node.queue_free()

func _refresh_chunks() -> void:
    if not initialized or not is_instance_valid(player):
        return
    var ordered: Array[Vector2i] = Rules.preferred_cells(player.global_position)
    var wanted: Dictionary = {}
    for cell in ordered:
        wanted[Rules.key(cell)] = true
    for key in active_chunks.keys():
        if not wanted.has(key):
            _drop_chunk(key)
    var fresh: int = 0
    for cell in ordered:
        var key: String = Rules.key(cell)
        if not active_chunks.has(key):
            _build_chunk(cell)
            fresh += 1
            if fresh >= Rules.LOAD_BUDGET:
                break
    if active_chunks.size() > Rules.ACTIVE_CAP:
        push_error("V0.67 tile budget exceeded maximum nine active chunks")

func _close_actor(parent: Node3D, resident: Dictionary) -> Node3D:
    var model := Node3D.new()
    model.name = "V067CloseNPC_" + str(resident["id"])
    parent.add_child(model)
    var choice: int = posmod(str(resident["id"]).hash(), MID_PALETTE.size())
    var coat: Color = MID_PALETTE[choice]
    TownspersonVisual.add_to(model, str(resident["id"]), -1, coat).set_motion(0.65)
    var label := Label3D.new()
    label.name = "V067CitizenName"
    label.text = str(resident["name"])
    label.position = Vector3(0, 2.49, 0)
    label.font_size = 22
    label.pixel_size = 0.005
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    model.add_child(label)
    var body := StaticBody3D.new()
    body.name = "V067ClosePhysicalCitizen"
    model.add_child(body)
    var collider := CollisionShape3D.new()
    collider.name = "V067CitizenPhysicalCollision"
    var shape := CapsuleShape3D.new()
    shape.radius = 0.31
    shape.height = 1.60
    collider.shape = shape
    collider.position = Vector3(0, 1.05, 0)
    body.add_child(collider)
    model.set_meta("resident_id", str(resident["id"]))
    near_models[str(resident["id"])] = model
    return model

func _remove_close_model(id: String) -> void:
    if near_models.has(id):
        var node: Node3D = near_models[id]
        near_models.erase(id)
        if is_instance_valid(node):
            node.queue_free()

func _refresh_crowds() -> void:
    if not initialized or not is_instance_valid(player):
        return
    var world_time: float = float(hub.get("world_minutes"))
    var sums: Dictionary = {"near": 0, "mid": 0, "far": 0, "physically_active_colliders": 0}
    for key in active_chunks.keys():
        var info: Dictionary = active_chunks[key]
        var cell: Vector2i = info["cell"]
        var chunk: Node3D = info["node"]
        var people: MultiMeshInstance3D = info["crowd"]
        var midmesh: MultiMesh = people.multimesh
        var visible_mid: int = 0
        for i in range(Rules.RESIDENTS_PER_CHUNK):
            var resident: Dictionary = info["citizens"][i]
            var id: String = str(resident["id"])
            var state: Dictionary = Rules.person_state(cell, i, world_time)
            var world_pos: Vector3 = state.get("world_position", Vector3.ZERO)
            var distance: float = player.global_position.distance_to(world_pos)
            var tier: String = Rules.lod(distance, bool(state.get("visible", false)))
            var travel_yaw: float = state["travel_yaw"]
            state["lod"] = tier
            if tier == "close":
                if not near_models.has(id):
                    _close_actor(chunk, resident)
                var model: Node3D = near_models[id]
                model.position = world_pos - chunk.global_position
                model.set_meta("activity", str(state.get("activity", "walking")))
                model.rotation.y = travel_yaw
                if id == current_speaker and distance < 6.0 and is_open():
                    var toward: Vector3 = player.global_position - world_pos
                    model.rotation.y = atan2(-toward.x, -toward.z)
                sums["near"] = int(sums["near"]) + 1
            else:
                _remove_close_model(id)
                if tier == "mid":
                    var offset: Vector3 = world_pos - chunk.global_position
                    var body_scale := TownspersonVisual.mid_scale(id)
                    midmesh.set_instance_transform(visible_mid,
                        Transform3D(Basis(Vector3.UP, travel_yaw).scaled(body_scale), offset))
                    midmesh.set_instance_color(visible_mid, MID_PALETTE[posmod(id.hash(), MID_PALETTE.size())])
                    visible_mid += 1
                    sums["mid"] = int(sums["mid"]) + 1
                else:
                    sums["far"] = int(sums["far"]) + 1
        midmesh.visible_instance_count = visible_mid
        people.visible = visible_mid > 0
        # Only nearby solid building walls participate in collision. Chunk
        # scenery and the whole GPU batch are discarded when out of range.
        for shape_record in info["colliders"]:
            var body: StaticBody3D = shape_record["body"]
            var shape: CollisionShape3D = shape_record["shape"]
            var near: bool = player.global_position.distance_to(body.global_position) <= Rules.COLLIDER_M
            shape.set_deferred("disabled", not near)
            if near:
                sums["physically_active_colliders"] = int(sums["physically_active_colliders"]) + 1
        # V0.68 shares the same bounded physics activation envelope.
        # The roof deck and bridge are *actual* platforms, not painted ones.
        for roof_record in info["roof_shapes"]:
            var roof_body: StaticBody3D = roof_record["body"]
            var roof_shape: CollisionShape3D = roof_record["shape"]
            var roof_near: bool = player.global_position.distance_to(roof_body.global_position) <= Rules.COLLIDER_M
            roof_shape.set_deferred("disabled", not roof_near)
            if roof_near:
                sums["physically_active_colliders"] = int(sums["physically_active_colliders"]) + 1
    crowd_stats = sums

func _process(delta: float) -> void:
    world_tick += delta
    if world_tick >= Rules.TICK_SECONDS:
        world_tick = 0.0
        _refresh_chunks()
        _refresh_crowds()

func get_nearest_interaction(point: Vector3, limit: float) -> Dictionary:
    var best: float = minf(limit, 3.3)
    var answer: Dictionary = {}
    for id in near_models.keys():
        var node: Node3D = near_models[id]
        if not is_instance_valid(node):
            continue
        var distance: float = node.global_position.distance_to(point)
        if distance < best:
            best = distance
            var resident: Dictionary = resident_records.get(id, {})
            answer = {"id": "street_v067_" + str(id),
                "position": node.global_position, "node": node,
                "name": str(resident.get("name", id)),
                "title": str(resident.get("name", id))}
    return answer

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()

func _make_conversation_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "V067StreetConversationCanvas"
    layer.layer = 25
    get_parent().add_child(layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)
    panel = PanelContainer.new()
    panel.anchor_left = 0.09
    panel.anchor_right = 0.91
    panel.anchor_top = 0.08
    panel.anchor_bottom = 0.90
    panel.visible = false
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.064, 0.076, 0.11, 0.98)
    style.border_color = Color(0.68, 0.58, 0.42)
    style.set_border_width_all(2)
    style.set_corner_radius_all(10)
    panel.add_theme_stylebox_override("panel", style)
    root.add_child(panel)
    var margins := MarginContainer.new()
    margins.add_theme_constant_override("margin_left", 15)
    margins.add_theme_constant_override("margin_right", 15)
    margins.add_theme_constant_override("margin_top", 15)
    margins.add_theme_constant_override("margin_bottom", 15)
    panel.add_child(margins)
    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 10)
    margins.add_child(layout)
    panel_title = Label.new()
    panel_title.add_theme_font_size_override("font_size", 23)
    layout.add_child(panel_title)
    panel_details = Label.new()
    panel_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    layout.add_child(panel_details)
    var space := Control.new()
    space.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_child(space)
    panel_response = Label.new()
    panel_response.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    layout.add_child(panel_response)
    for tuple in [
        ["ASK ABOUT THEIR WORK", "work"],
        ["ASK ABOUT THEIR HOUSEHOLD", "home"],
        ["HEAR ABOUT TODAY'S ROUTINE", "day"]
    ]:
        var button := Button.new()
        button.text = str(tuple[0])
        button.custom_minimum_size.y = 50
        button.pressed.connect(_ask.bind(str(tuple[1])))
        layout.add_child(button)
    var leave := Button.new()
    leave.text = "CONTINUE EXPLORING"
    leave.custom_minimum_size.y = 50
    leave.pressed.connect(_close)
    layout.add_child(leave)

func interact(key: String) -> void:
    if not initialized or not key.begins_with("street_v067_"):
        return
    var id: String = key.trim_prefix("street_v067_")
    if not near_models.has(id) or not resident_records.has(id):
        return
    var visible_model: Node3D = near_models[id]
    if player.global_position.distance_to(visible_model.global_position) > float(hub.get("interact_range")):
        return
    current_speaker = id
    var person: Dictionary = resident_records[id]
    panel_title.text = str(person["name"]).to_upper()
    var tile_tokens: PackedStringArray = str(person["origin_cell"]).split(":")
    var cell := Vector2i(int(tile_tokens[0]), int(tile_tokens[1]))
    var ordinal: int = int(id.split("_")[-1])
    var status: Dictionary = Rules.person_state(cell, ordinal, float(hub.get("world_minutes")))
    panel_details.text = "Occupation: %s\nDisposition: %s\nCurrent activity: %s\n" % [
        str(person["role"]), str(person["personality"]), str(status.get("activity", "")).replace("_", " ")]
    panel_details.text += "Local civilian / game-only character. Individual life continues while this block is unloaded."
    panel_response.text = "It's a busy stretch of Magnara. What would you like to know?"
    panel.show()

func _ask(topic: String) -> void:
    if not is_open() or not resident_records.has(current_speaker):
        return
    var person: Dictionary = resident_records[current_speaker]
    match topic:
        "work":
            panel_response.text = "There's always another %s shift. Our household plans around the factory whistles and tram traffic." % str(person["role"])
        "home":
            panel_response.text = "I share the %s address with the people in my household. We keep our own schedules." % str(person["home"])
        "day":
            panel_response.text = "We start early, work, stop for food, then get back through the crowds before night."
        _:
            return
    if is_instance_valid(codex) and codex.has_method("record_event"):
        var stamp: int = maxi(1, floori(float(hub.get("world_minutes")) / 1440.0) + 1)
        codex.call("record_event", "v067:conversation:%s:day:%d:%s" % [current_speaker, stamp, topic],
            "public_encounter", "Talked with " + str(person["name"]),
            "Game-only Magnara citizen, %s; asked about %s. Canon not altered." % [person["role"], topic])
