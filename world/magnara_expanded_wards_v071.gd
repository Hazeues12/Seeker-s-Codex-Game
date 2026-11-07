extends Node3D
# V0.71 second streamed ward system, adjacent to (never overlapping) V0.67.
# 30 new 128m cells; only nine adjacent cells loaded at once on iPhone.
# NPC identities/households are game-only, not main-series canon characters.
const Rules = preload("res://systems/magnara_expansion_rules_v071.gd")
var player: CharacterBody3D
var hub: Node
var codex: Node
var initialized: bool = false
var active_chunks: Dictionary = {}
var close_models: Dictionary = {}
var actors: Dictionary = {}
var update_clock: float = 0.0
var unit_cube: BoxMesh
var instance_material: StandardMaterial3D
var person_material: StandardMaterial3D
var panel: PanelContainer
var panel_title: Label
var panel_body: Label
var current_speaker: String = ""
var stats: Dictionary = {"close":0,"mid":0,"far":0,"active_building_colliders":0}

func _ready() -> void:
    add_to_group("v071_expanded_magnara")
    set_process(false)
    call_deferred("_initialize")

func _initialize() -> void:
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    if not is_instance_valid(player) or not is_instance_valid(hub) or not is_instance_valid(codex):
        return
    unit_cube = BoxMesh.new()
    unit_cube.size = Vector3.ONE
    instance_material = StandardMaterial3D.new()
    instance_material.vertex_color_use_as_albedo = true
    instance_material.albedo_color = Color.WHITE
    instance_material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    instance_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    person_material = StandardMaterial3D.new()
    person_material.vertex_color_use_as_albedo = true
    person_material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    _create_panel()
    initialized = true
    _refresh_chunks()
    _refresh_crowds()
    set_process(true)

func get_manifest() -> Dictionary:
    var totals: Dictionary = Rules.totals()
    return {"version":71,"canon_status":"game_only_public_massing","active_chunks":active_chunks.size(),
        "active_cap":Rules.MAX_ACTIVE,"new_cells":totals["new_cells"],
        "new_building_shells":totals["new_buildings"],
        "new_original_civilians":totals["new_named_game_only_civilians"],
        "combined_public_building_shells":totals["combined_v067_buildings"],
        "combined_original_civilians":totals["combined_v067_game_only_civilians"],
        "active_close_characters":close_models.size(),
        "walls_and_roofs_physically_collidable":true,
        "roof_access":true,
        "full_interior_production_complete":false,
        "original_v067_cells_untouched":true,
        "spawns_hidden_canon":false}

func active_chunk_count() -> int:
    return active_chunks.size()

func active_building_count() -> int:
    return active_chunks.size() * Rules.PARCELS

func _material(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    return m

func _box(root: Node3D, label: String, at: Vector3, size: Vector3,
        color: Color, solid: bool = false) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    mesh.name = label
    var shape := BoxMesh.new()
    shape.size = size
    mesh.mesh = shape
    mesh.material_override = _material(color)
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    mesh.position = at
    root.add_child(mesh)
    if solid:
        var body := StaticBody3D.new()
        mesh.add_child(body)
        var hit := CollisionShape3D.new()
        hit.name = "V071RoadCollision"
        var form := BoxShape3D.new()
        form.size = size
        hit.shape = form
        body.add_child(hit)
    return mesh

func _gpu_batch(root: Node3D, label: String, entries: Array) -> MultiMeshInstance3D:
    var gpu := MultiMesh.new()
    gpu.transform_format = MultiMesh.TRANSFORM_3D
    gpu.use_colors = true
    gpu.mesh = unit_cube
    gpu.instance_count = entries.size()
    for i in range(entries.size()):
        var spec: Dictionary = entries[i]
        gpu.set_instance_transform(i, Transform3D(
            Basis.IDENTITY.scaled(spec["size"]),spec["pos"]))
        gpu.set_instance_color(i,spec["color"])
    var rendered := MultiMeshInstance3D.new()
    rendered.name = label
    rendered.multimesh = gpu
    rendered.material_override = instance_material
    rendered.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    root.add_child(rendered)
    return rendered

func _add_piece(groups: Dictionary, kind: String, at: Vector3, size: Vector3,
        shade: Color) -> void:
    var collection: Array = groups.get(kind,[])
    collection.append({"pos":at,"size":size,"color":shade})
    groups[kind] = collection

func _kit(chunk: Node3D, parcels: Array) -> void:
    var parts: Dictionary = {}
    for data in parcels:
        var parcel: Dictionary = data
        var center: Vector3 = parcel["center"]
        var width: float = float(parcel["width"])
        var depth: float = float(parcel["depth"])
        var height: float = float(parcel["height"])
        var floors: int = int(parcel["floors"])
        var palette: Color = Rules.COLORS[int(parcel["palette"])]
        _add_piece(parts,"ground",center+Vector3(0,0.56+height*0.5,0),
            Vector3(width,height,depth),palette)
        _add_piece(parts,"roof",center+Vector3(0,0.56+height+0.15,0),
            Vector3(width+0.9,0.30,depth+0.9),Color(0.27,0.31,0.34))
        var inward: float = 1.0 if center.x < 0.0 else -1.0
        for level in range(floors):
            _add_piece(parts,"middle",center+Vector3(0,0.56+3.3+float(level)*2.75,0),
                Vector3(width+0.11,0.15,depth+0.11),palette.darkened(0.24))
            for bay in range(3):
                var z: float = center.z-depth*0.29+float(bay)*depth*0.29
                _add_piece(parts,"window",Vector3(center.x+inward*(width*0.5+0.08),
                    0.56+2.3+float(level)*2.75,z),
                    Vector3(0.22,1.05,1.28),Color(0.32,0.59,0.66))
        if int(parcel["slot"]) % 2 == 0:
            _add_piece(parts,"awning",Vector3(center.x+inward*(width*0.5+1.6),
                3.55,center.z),Vector3(3.1,0.20,depth*0.72),
                Color(0.50,0.38,0.30))
        else:
            _add_piece(parts,"balcony",Vector3(center.x+inward*(width*0.5+0.95),
                4.3,center.z+depth*0.24),Vector3(1.9,0.17,4.0),
                Color(0.42,0.41,0.39))
    for kind in Rules.MODULES:
        if parts.has(kind):
            _gpu_batch(chunk,"V071WardKit_"+kind,parts[kind])

func _platform(root: Node3D, label: String, pos: Vector3, size: Vector3,
        colliders: Array, visuals: Array) -> void:
    var body := StaticBody3D.new()
    body.name = label
    body.position = pos
    root.add_child(body)
    var hit := CollisionShape3D.new()
    hit.name = "V071ParkourShape"
    var shape := BoxShape3D.new()
    shape.size = size
    hit.shape = shape
    hit.disabled = true
    body.add_child(hit)
    colliders.append({"body":body,"shape":hit})
    visuals.append({"pos":pos,"size":size,"color":Color(0.48,0.63,0.68)})

func _make_access(root: Node3D, cell: Vector2i, parcels: Array) -> Array:
    var colliders: Array = []
    var visual_specs: Array = []
    for data in parcels:
        var parcel: Dictionary = data
        var local_center: Vector3 = parcel["center"]
        var top: float = 0.56 + float(parcel["height"]) + 0.32
        _platform(root,"V071Rooftop_"+str(parcel["slot"]),
            local_center+Vector3(0,top-0.11,0),
            Vector3(float(parcel["width"])+0.7,0.22,float(parcel["depth"])+0.7),
            colliders,visual_specs)
    for side in range(2):
        var starting: Dictionary = parcels[side]
        var roof_height: float = 0.56 + float(starting["height"]) + 0.32
        var count: int = maxi(7,ceili((roof_height-0.75)/1.15))
        var sign: float = -1.0 if side == 0 else 1.0
        var anchor_x: float = absf(float((starting["center"] as Vector3).x)) - float(starting["width"])*0.5
        for n in range(count):
            var t: float = float(n+1)/float(count)
            var up: float = lerpf(0.78,roof_height-0.44,t)
            var x: float = sign*lerpf(11.8,anchor_x-0.4,t)
            _platform(root,"V071PublicAccess_%d_%d" % [side,n],
                Vector3(x,up-0.11,float((starting["center"] as Vector3).z)),
                Vector3(3.15,0.22,3.12),colliders,visual_specs)
        for row in range(2):
            var a: Dictionary = parcels[side+row*2]
            var b: Dictionary = parcels[side+(row+1)*2]
            var a_top: float = 0.56 + float(a["height"]) + 0.30
            var b_top: float = 0.56 + float(b["height"]) + 0.30
            var z0: float = float((a["center"] as Vector3).z)+float(a["depth"])*0.5-1.0
            var z1: float = float((b["center"] as Vector3).z)-float(b["depth"])*0.5+1.0
            var link_count: int = maxi(6,maxi(ceili((z1-z0)/3.0),ceili(absf(b_top-a_top)/1.0)))
            for step in range(link_count):
                var link_t: float = float(step+1)/float(link_count+1)
                _platform(root,"V071RoofLink_%d_%d_%d" % [side,row,step],
                    Vector3(float((a["center"] as Vector3).x),
                        lerpf(a_top,b_top,link_t)-0.12,lerpf(z0,z1,link_t)),
                    Vector3(3.5,0.24,3.12),colliders,visual_specs)
    _gpu_batch(root,"V071RoofAccessGPU",visual_specs)
    return colliders

func _build(cell: Vector2i) -> void:
    var id: String = Rules.key(cell)
    if active_chunks.has(id) or not Rules.allowed(cell):
        return
    var chunk := Node3D.new()
    chunk.name = "V071WardChunk_"+id.replace(":","_").replace("-","m")
    chunk.position = Rules.origin(cell)
    chunk.add_to_group("v071_ward_chunk")
    add_child(chunk)
    var streets := Node3D.new()
    streets.name = "V071StreetPlazas"
    chunk.add_child(streets)
    _box(streets,"V071PrimaryStreet",Vector3(0,0.65,64),
        Vector3(10.3,0.15,128),Color(0.63,0.63,0.61),true)
    for z in [0.0,128.0]:
        _box(streets,"V071Crossroad",Vector3(0,0.65,z),
            Vector3(128,0.16,10.3),Color(0.64,0.63,0.59),true)
    for sign in [-1.0,1.0]:
        _box(streets,"V071Sidewalk",Vector3(sign*9.2,0.69,64),
            Vector3(3.2,0.17,128),Color(0.74,0.71,0.62),true)
    var parcels: Array = []
    var walls: Array = []
    for slot in range(Rules.PARCELS):
        var p: Dictionary = Rules.parcel(cell,slot)
        parcels.append(p)
        var body := StaticBody3D.new()
        body.name = "V071BuildingWall_"+str(slot)
        body.position = p["center"]+Vector3(0,0.56+float(p["height"])*0.5,0)
        chunk.add_child(body)
        var shape := CollisionShape3D.new()
        shape.name = "V071BuildingCollision"
        var box := BoxShape3D.new()
        box.size = Vector3(float(p["width"]),float(p["height"]),float(p["depth"]))
        shape.shape = box
        shape.disabled = true
        body.add_child(shape)
        walls.append({"body":body,"shape":shape})
    _kit(chunk,parcels)
    var rooftops: Array = _make_access(chunk,cell,parcels)
    var crowd: MultiMeshInstance3D = _gpu_batch(chunk,"V071MidCrowd",[])
    var residents: Array = []
    for i in range(Rules.PEOPLE):
        residents.append(Rules.resident(cell,i))
    var batch: MultiMesh = crowd.multimesh
    batch.instance_count = Rules.PEOPLE
    batch.visible_instance_count = 0
    active_chunks[id] = {"cell":cell,"node":chunk,"parcels":parcels,
        "walls":walls,"roof_shapes":rooftops,"crowd":crowd,"residents":residents}

func _remove_close(id: String) -> void:
    if close_models.has(id):
        var actor: Node3D = close_models[id]
        close_models.erase(id)
        actors.erase(id)
        if is_instance_valid(actor):
            actor.queue_free()

func _drop(id: String) -> void:
    if not active_chunks.has(id):
        return
    var chunk: Dictionary = active_chunks[id]
    for r in chunk["residents"]:
        _remove_close(str(r["id"]))
    active_chunks.erase(id)
    var root: Node3D = chunk["node"]
    if is_instance_valid(root):
        root.queue_free()

func _refresh_chunks() -> void:
    if not initialized:
        return
    var wanted: Array[Vector2i] = Rules.nearby(player.global_position)
    var keys: Dictionary = {}
    for cell in wanted:
        keys[Rules.key(cell)] = true
    for key in active_chunks.keys():
        if not keys.has(key):
            _drop(key)
    var new_count: int = 0
    for cell in wanted:
        var key: String = Rules.key(cell)
        if not active_chunks.has(key):
            _build(cell)
            new_count += 1
            if new_count >= Rules.LOAD_BUDGET:
                break

func _make_citizen(root: Node3D, record: Dictionary) -> Node3D:
    var id: String = str(record["id"])
    var person := Node3D.new()
    person.name = "V071Citizen_"+id
    person.add_to_group("v071_public_resident")
    root.add_child(person)
    var shade: Color = Rules.COLORS[posmod(id.hash(),Rules.COLORS.size())]
    _box(person,"V071CitizenTorso",Vector3(0,1.1,0),Vector3(0.57,0.87,0.38),shade)
    _box(person,"V071CitizenFace",Vector3(0,1.77,0),Vector3(0.34,0.35,0.32),Color(0.70,0.54,0.42))
    _box(person,"V071CitizenFeet",Vector3(0,0.41,0),Vector3(0.41,0.65,0.35),shade.darkened(0.36))
    var body := StaticBody3D.new()
    person.add_child(body)
    var collision := CollisionShape3D.new()
    collision.name = "V071NearCitizenCollision"
    collision.position = Vector3(0,1.1,0)
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.27
    capsule.height = 1.62
    collision.shape = capsule
    body.add_child(collision)
    close_models[id] = person
    actors[id] = record
    return person

func _refresh_crowds() -> void:
    if not initialized:
        return
    var current: float = float(hub.get("world_minutes"))
    var result: Dictionary = {"close":0,"mid":0,"far":0,"active_building_colliders":0}
    for key in active_chunks.keys():
        var info: Dictionary = active_chunks[key]
        var cell: Vector2i = info["cell"]
        var root: Node3D = info["node"]
        var multimesh: MultiMesh = (info["crowd"] as MultiMeshInstance3D).multimesh
        var visible_mid: int = 0
        for i in range(Rules.PEOPLE):
            var record: Dictionary = info["residents"][i]
            var id: String = str(record["id"])
            var state: Dictionary = Rules.resident_state(cell,i,current)
            var at: Vector3 = state["world_position"]
            var distance: float = player.global_position.distance_to(at)
            var tier: String = Rules.lod(distance,bool(state["visible"]))
            if tier == "close":
                if not close_models.has(id):
                    _make_citizen(root,record)
                var actor: Node3D = close_models[id]
                actor.position = at-root.global_position
                actor.set_meta("public_activity",str(state["activity"]))
                result["close"] = int(result["close"])+1
            else:
                _remove_close(id)
                if tier == "mid":
                    multimesh.set_instance_transform(visible_mid,Transform3D(
                        Basis.IDENTITY.scaled(Vector3(0.52,1.50,0.40)),
                        at-root.global_position+Vector3(0,1.04,0)))
                    multimesh.set_instance_color(visible_mid,
                        Rules.COLORS[posmod(i+cell.y,Rules.COLORS.size())])
                    visible_mid += 1
                    result["mid"] = int(result["mid"])+1
                else:
                    result["far"] = int(result["far"])+1
        multimesh.visible_instance_count = visible_mid
        (info["crowd"] as MultiMeshInstance3D).visible = visible_mid > 0
        for item in info["walls"] + info["roof_shapes"]:
            var solid: StaticBody3D = item["body"]
            var hit: CollisionShape3D = item["shape"]
            var near: bool = player.global_position.distance_to(solid.global_position) < Rules.COLLIDER_M
            hit.set_deferred("disabled",not near)
            if near:
                result["active_building_colliders"] = int(result["active_building_colliders"])+1
    stats = result

func get_nearest_interaction(at: Vector3, reach: float) -> Dictionary:
    var closest: float = minf(reach,3.2)
    var result: Dictionary = {}
    for id in close_models.keys():
        var actor: Node3D = close_models[id]
        if not is_instance_valid(actor):
            continue
        var dist: float = actor.global_position.distance_to(at)
        if dist < closest:
            closest = dist
            var person: Dictionary = actors.get(id,{})
            result = {"id":"ward_v071_"+id,"title":str(person.get("name","Resident")),
                "name":str(person.get("name","Resident")),
                "position":actor.global_position,"node":actor}
    return result

func _create_panel() -> void:
    var layer := CanvasLayer.new()
    layer.name = "V071WardCitizenLayer"
    layer.layer = 35
    get_parent().add_child(layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)
    panel = PanelContainer.new()
    panel.anchor_left = 0.10
    panel.anchor_right = 0.90
    panel.anchor_top = 0.08
    panel.anchor_bottom = 0.92
    panel.visible = false
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.075,0.085,0.13,0.98)
    panel_style.border_color = Color(0.68,0.58,0.40)
    panel_style.set_border_width_all(2)
    panel_style.set_corner_radius_all(9)
    panel.add_theme_stylebox_override("panel",panel_style)
    root.add_child(panel)
    var padding := MarginContainer.new()
    for side in ["left","top","right","bottom"]:
        padding.add_theme_constant_override("margin_"+side,16)
    panel.add_child(padding)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation",11)
    padding.add_child(stack)
    panel_title = Label.new()
    panel_title.add_theme_font_size_override("font_size",23)
    stack.add_child(panel_title)
    panel_body = Label.new()
    panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    panel_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_child(panel_body)
    for topic in ["Work","Household","Neighborhood"]:
        var button := Button.new()
        button.text = "ASK ABOUT "+topic.to_upper()
        button.custom_minimum_size.y = 47
        button.pressed.connect(_answer.bind(topic))
        stack.add_child(button)
    var close := Button.new()
    close.text = "RETURN TO THE STREET"
    close.custom_minimum_size.y = 48
    close.pressed.connect(_close)
    stack.add_child(close)

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()

func interact(key: String) -> void:
    if not key.begins_with("ward_v071_"):
        return
    var id: String = key.trim_prefix("ward_v071_")
    if not actors.has(id) or not close_models.has(id):
        return
    if player.global_position.distance_to((close_models[id] as Node3D).global_position) > float(hub.get("interact_range")):
        return
    current_speaker = id
    var person: Dictionary = actors[id]
    panel_title.text = str(person["name"])+" / PUBLIC WARD"
    _answer("Work")
    panel.show()
    if codex.has_method("record_interaction"):
        codex.call("record_interaction","npc_ward_v071_"+id,str(person["name"]))

func _answer(topic: String) -> void:
    if not actors.has(current_speaker):
        return
    var record: Dictionary = actors[current_speaker]
    var position: Vector3 = (close_models[current_speaker] as Node3D).global_position
    var cell: Vector2i = Rules.cell_for(position)
    var index: int = int(str(record["id"]).get_slice("_",4))
    var activity: String = str(Rules.resident_state(cell,index,float(hub.get("world_minutes"))).get("activity","on the street"))
    if topic == "Work":
        panel_body.text = "I work as a %s. My shift today is %s. I try to keep this quarter running." % [
            str(record["role"]),activity]
    elif topic == "Household":
        panel_body.text = "I share a home with household %s. I'm %s; I look after my neighbors." % [
            str(record["household"]),str(record["personality"])]
    else:
        panel_body.text = "These public streets connect homes, work and trade. I only know what people can see here."
    panel_body.text += "\n\nThis character and address are original game-only civilian content. They do not reveal Seeker secrets."
    if codex.has_method("record_event"):
        codex.call("record_event","ward:v071:%s:%s" % [current_speaker,topic.to_lower()],
            "civilian_conversation",str(record["name"])+": "+topic,
            "Public neighborhood conversation about "+topic.to_lower())

func _process(delta: float) -> void:
    update_clock += delta
    if update_clock >= Rules.TICK_SECONDS:
        update_clock = 0.0
        _refresh_chunks()
        _refresh_crowds()
