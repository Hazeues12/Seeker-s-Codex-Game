extends Node3D
# V0.72 open public ground floors: real walk-through geometry and scheduled
# residents, attached only to the 30 streamed (game-only) V0.71 wards.
# No invented canonical shop owner, hidden faction or story-only Muti.
const Interior = preload("res://systems/magnara_interiors_rules_v072.gd")
const Ward = preload("res://systems/magnara_expansion_rules_v071.gd")
const LocalV073 = preload("res://systems/magnara_local_logistics_rules_v073.gd")
var player: CharacterBody3D
var hub: Node
var codex: Node
var city: Node
var initialized: bool = false
var sites: Dictionary = {}
var tick: float = 0.0
var panel: PanelContainer
var title: Label
var story: Label
var current_site: String = ""

func _ready() -> void:
    add_to_group("v072_enterable_wards")
    set_process(false)
    call_deferred("_initialize")

func _initialize() -> void:
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    city = get_tree().get_first_node_in_group("v071_expanded_magnara")
    if not is_instance_valid(player) or not is_instance_valid(hub) \
            or not is_instance_valid(city) or not is_instance_valid(codex):
        return
    _make_ui()
    initialized = true
    _refresh()
    set_process(true)

func _material(tint: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = tint
    m.roughness = 0.79
    m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
    return m

func _block(parent: Node3D, label: String, at: Vector3,
        dims: Vector3, tint: Color, solid: bool = true) -> MeshInstance3D:
    var display := MeshInstance3D.new()
    display.name = label
    var box := BoxMesh.new()
    box.size = dims
    display.mesh = box
    display.material_override = _material(tint)
    display.position = at
    display.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(display)
    if solid:
        var wall := StaticBody3D.new()
        wall.name = label + "_Physics"
        display.add_child(wall)
        var hit := CollisionShape3D.new()
        hit.name = "V072RealWalkableInteriorCollision"
        var shape := BoxShape3D.new()
        shape.size = dims
        hit.shape = shape
        wall.add_child(hit)
    return display

func _sign(parent: Node3D, text_value: String, at: Vector3) -> void:
    var sign := Label3D.new()
    sign.name = "V072PublicVenueSign"
    sign.text = text_value
    sign.position = at
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.no_depth_test = true
    sign.font_size = 22
    sign.pixel_size = 0.0043
    parent.add_child(sign)

func _site(key: String, chunk: Node3D, cell: Vector2i) -> void:
    var spec: Dictionary = Interior.site(cell)
    if spec.is_empty():
        return
    var c: Vector3 = spec["center_local"]
    var width: float = float(spec["width"])
    var depth: float = float(spec["depth"])
    var inward: float = float(spec["inward"])
    var building := Node3D.new()
    building.name = "V072EnterablePublicWorkroom"
    building.add_to_group("v072_physical_public_interior")
    chunk.add_child(building)
    var masonry := Color(0.55,0.52,0.48)
    var inner := Color(0.62,0.59,0.53)
    # Physical ground floor from y=.56 to y=3.76. Door opening at
    # front facade is 2.4m wide and >2.2m high; no invisible collider.
    _block(building,"V072RealPublicFloor",c+Vector3(0,0.73,0),
        Vector3(width-0.36,0.20,depth-0.36),Color(0.66,0.62,0.52))
    _block(building,"V072RearWall",
        c+Vector3(-inward*(width*0.5-0.13),2.16,0),
        Vector3(0.28,3.20,depth),masonry)
    for end in [-1.0,1.0]:
        _block(building,"V072EndMasonry",c+Vector3(0,2.16,end*(depth*0.5-0.14)),
            Vector3(width,3.20,0.28),masonry)
    var side_span: float = (depth-Interior.PUBLIC_DOOR_WIDTH)*0.5
    for front_side in [-1.0,1.0]:
        _block(building,"V072OpenDoorFacade",
            c+Vector3(inward*(width*0.5-0.14),2.16,
                front_side*(Interior.PUBLIC_DOOR_WIDTH*0.5+side_span*0.5)),
            Vector3(0.28,3.20,side_span),masonry)
    _block(building,"V072DoorLintel",
        c+Vector3(inward*(width*0.5-0.14),3.38,0),
        Vector3(0.28,0.72,Interior.PUBLIC_DOOR_WIDTH),masonry)
    _block(building,"V072PublicCeiling",
        c+Vector3(0,3.76,0),Vector3(width,0.20,depth),
        Color(0.43,0.39,0.36))
    # The doorway faces the Ring II pedestrian path, entirely free of
    # furniture. Shelves and worktables are behind the staff counter.
    for end in [-1.0,1.0]:
        _block(building,"V072ProductShelf",
            c+Vector3(-inward*3.5,1.30,end*depth*0.33),
            Vector3(2.35,1.15,2.75),Color(0.42,0.31,0.22))
        for level in range(3):
            _block(building,"V072ShelfGoods",
                c+Vector3(-inward*3.5,1.90+float(level)*0.25,end*depth*0.33),
                Vector3(1.67,0.21,1.70),Color(0.55,0.44,0.29),false)
    _block(building,"V072OccupiedWorkCounter",
        c+Vector3(-inward*1.2,1.22,depth*0.31),
        Vector3(3.1,0.70,1.1),Color(0.45,0.34,0.25))
    _block(building,"V072CommunalTable",
        c+Vector3(-inward*3.0,1.14,-depth*0.21),
        Vector3(3.0,0.28,2.20),inner)
    for seat_x in [-1.0,1.0]:
        _block(building,"V072Seat",c+Vector3(-inward*3.0+seat_x*2.15,0.98,-depth*0.21),
            Vector3(0.75,0.46,0.80),Color(0.40,0.35,0.29))
    _block(building,"V072InteriorLamplight",
        c+Vector3(0,3.39,0),Vector3(0.65,0.15,0.65),
        Color(0.93,0.79,0.50),false)
    _sign(building,str(spec["label"])+" / PUBLIC / GAME-ONLY",
        Vector3(c.x+inward*(width*0.5+0.55),3.32,c.z))
    var door := Node3D.new()
    door.name = "V072OpenPhysicalDoor"
    door.position = (spec["door_world"] as Vector3)-Ward.origin(cell)
    building.add_child(door)

    var staff := Node3D.new()
    staff.name = "V072SameResidentIndoorEmployee"
    staff.add_to_group("v072_game_only_employee")
    staff.position = (spec["staff_world"] as Vector3)-Ward.origin(cell)
    building.add_child(staff)
    _block(staff,"V072Uniform",Vector3(0,1.02,0),
        Vector3(0.55,0.87,0.35),Color(0.28,0.37,0.46),false)
    _block(staff,"V072Head",Vector3(0,1.69,0),
        Vector3(0.35,0.38,0.32),Color(0.65,0.50,0.40),false)
    _block(staff,"V072Shoes",Vector3(0,0.40,0),
        Vector3(0.47,0.55,0.39),Color(0.22,0.24,0.28),false)
    var employee_collision := StaticBody3D.new()
    employee_collision.name = "V072EmployeeBody"
    staff.add_child(employee_collision)
    var body_shape := CollisionShape3D.new()
    body_shape.name = "V072WorkerCollision"
    body_shape.position = Vector3(0,1.00,0)
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.26
    capsule.height = 1.58
    body_shape.shape = capsule
    employee_collision.add_child(body_shape)
    # V0.73: a second EXISTING civilian from the same city roster
    # visits after working hours. One person always has one world location.
    var guest := Node3D.new()
    guest.name = "V073SameExistingEveningHouseholdGuest"
    guest.add_to_group("v073_game_only_household_visitor")
    guest.position = c+Vector3(-inward*5.8,0.82,-depth*0.21-1.2)
    building.add_child(guest)
    _block(guest,"V073VisitorCoat",Vector3(0,1.00,0),
        Vector3(0.52,0.87,0.37),Color(0.54,0.41,0.46),false)
    _block(guest,"V073VisitorHead",Vector3(0,1.69,0),
        Vector3(0.35,0.37,0.32),Color(0.66,0.51,0.41),false)
    var guest_body := StaticBody3D.new()
    guest_body.name = "V073EveningGuestBody"
    guest.add_child(guest_body)
    var guest_hit := CollisionShape3D.new()
    guest_hit.name = "V073EveningGuestCollision"
    guest_hit.position = Vector3(0,1.0,0)
    var guest_capsule := CapsuleShape3D.new()
    guest_capsule.height = 1.60
    guest_capsule.radius = 0.26
    guest_hit.shape = guest_capsule
    guest_body.add_child(guest_hit)

    # Cargo visuals are attached to the physically loaded workroom ONLY.
    # The 6 bounded crates reflect the persisted ledger, but never stand
    # across a doorway or block the existing seating/walkways.
    var stock_crates: Array[MeshInstance3D] = []
    for crate_index in range(6):
        var at: Vector3 = c+Vector3(
            -inward*(width*0.5-1.75),
            1.02+float(int(crate_index/3))*0.72,
            float(crate_index%3-1)*1.38)
        var crate: MeshInstance3D = _block(building,"V073PublicStockCrate",
            at,Vector3(0.9,0.66,1.06),Color(0.59,0.43,0.26),true)
        stock_crates.append(crate)
    sites[key] = {"root":building,"cell":cell,"record":spec,
        "door":door,"staff":staff,"staff_collision":body_shape,
        "guest":guest,"guest_collision":guest_hit,"stock_crates":stock_crates}
    _update_shift(key)
    _update_stock_visuals(key)

func _refresh() -> void:
    if not initialized:
        return
    var chunks: Dictionary = city.get("active_chunks")
    for key in sites.keys():
        var site: Dictionary = sites[key]
        if not chunks.has(key) or not is_instance_valid(site["root"]):
            sites.erase(key)
            if current_site == key:
                _close()
    for key in chunks.keys():
        if not sites.has(key):
            var chunk: Dictionary = chunks[key]
            _site(str(key),chunk["node"],chunk["cell"])
    for key in sites.keys():
        _update_shift(str(key))
        _update_stock_visuals(str(key))

func _update_shift(key: String) -> void:
    if not sites.has(key):
        return
    var slot: Dictionary = sites[key]
    var state: Dictionary = Interior.staff_schedule(slot["cell"],
        float(hub.get("world_minutes")))
    var employee: Node3D = slot["staff"]
    if not is_instance_valid(employee):
        return
    employee.visible = bool(state.get("on_shift",false))
    (slot["staff_collision"] as CollisionShape3D).set_deferred(
        "disabled",not employee.visible)
    if employee.visible:
        var p: Vector3 = slot["record"]["staff_world"]
        var stride: float = sin(float(hub.get("world_minutes"))*0.035)*0.35
        employee.position = p-Ward.origin(slot["cell"])+Vector3(0,0,stride)
        employee.set_meta("public_shift",state["activity"])
    var guest: Node3D = slot["guest"]
    var guest_state: Dictionary = LocalV073.visitor(slot["cell"],
        float(hub.get("world_minutes")))
    guest.visible = bool(guest_state.get("present",false))
    (slot["guest_collision"] as CollisionShape3D).set_deferred(
        "disabled",not guest.visible)
    if guest.visible:
        guest.set_meta("household_visit",guest_state["household"])

func _update_stock_visuals(key: String) -> void:
    if not sites.has(key):
        return
    var slot: Dictionary = sites[key]
    var current: int = LocalV073.stock(LocalV073.clean(
        hub.get("local_trade_v073")),slot["cell"])
    var crates: Array = slot["stock_crates"]
    for index in range(crates.size()):
        var crate: MeshInstance3D = crates[index]
        if not is_instance_valid(crate):
            continue
        crate.visible = index < current
        var hit: CollisionShape3D = crate.get_node_or_null(
            "V073PublicStockCrate_Physics/V072RealWalkableInteriorCollision")
        if is_instance_valid(hit):
            hit.set_deferred("disabled",not crate.visible)

func active_count() -> int:
    return sites.size()

func get_manifest() -> Dictionary:
    return {"version":72,"physical_public_interiors_available":Interior.VENUES_TOTAL,
        "currently_loaded":sites.size(),"max_loaded":Interior.MAX_LOADED,
        "entry_method":"walk_through_true_open_ground_floor",
        "unique_attendant_per_venue":true,
        "same_street_resident":Interior.STAFF_INDEX,
        "furniture_collision":true,"public_only":true,
        "original_story_venues_unchanged":true,
        "v073_stock_physically_visible":true,
        "v073_evening_household_visitors":Interior.VENUES_TOTAL,
        "v073_ledger_persistent":true}

func get_nearest_interaction(at: Vector3, reach: float) -> Dictionary:
    var best: float = minf(reach,3.2)
    var answer: Dictionary = {}
    for key in sites.keys():
        var slot: Dictionary = sites[key]
        var door: Node3D = slot["door"]
        if is_instance_valid(door):
            var distance: float = at.distance_to(door.global_position)
            if distance < best:
                best = distance
                answer = {"id":"interior_v072_entry_"+str(key),
                    "position":door.global_position,"node":door,
                    "name":str(slot["record"]["label"]),
                    "title":str(slot["record"]["label"])}
        var guest: Node3D = slot["guest"]
        if is_instance_valid(guest) and guest.visible:
            var visitor_distance: float = at.distance_to(guest.global_position)
            if visitor_distance < best:
                best = visitor_distance
                var visitor_state: Dictionary = LocalV073.visitor(slot["cell"],
                    float(hub.get("world_minutes")))
                answer = {"id":"interior_v072_guest_"+str(key),
                    "position":guest.global_position,"node":guest,
                    "name":str(visitor_state["name"]),
                    "title":str(visitor_state["name"])}
        var employee: Node3D = slot["staff"]
        if is_instance_valid(employee) and employee.visible:
            var d: float = at.distance_to(employee.global_position)
            if d < best:
                best = d
                answer = {"id":"interior_v072_staff_"+str(key),
                    "position":employee.global_position,"node":employee,
                    "name":str(Interior.staff_schedule(slot["cell"],
                        float(hub.get("world_minutes")))["name"]),
                    "title":str(Interior.staff_schedule(slot["cell"],
                        float(hub.get("world_minutes")))["name"])}
    return answer

func _make_ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.layer = 37
    canvas.name = "V072PublicWardVenueUI"
    get_parent().add_child(canvas)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(root)
    panel = PanelContainer.new()
    panel.anchor_left = 0.10
    panel.anchor_right = 0.90
    panel.anchor_top = 0.11
    panel.anchor_bottom = 0.89
    panel.visible = false
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color(0.07,0.08,0.11,0.98)
    panel_style.border_color = Color(0.65,0.64,0.48)
    panel_style.set_border_width_all(2)
    panel_style.set_corner_radius_all(9)
    panel.add_theme_stylebox_override("panel",panel_style)
    root.add_child(panel)
    var margin := MarginContainer.new()
    for side in ["left","right","top","bottom"]:
        margin.add_theme_constant_override("margin_"+side,17)
    panel.add_child(margin)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation",12)
    margin.add_child(stack)
    title = Label.new()
    title.add_theme_font_size_override("font_size",23)
    title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(title)
    story = Label.new()
    story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    story.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_child(story)
    for topic in ["Work","Household","Local Commerce"]:
        var button := Button.new()
        button.text = "ASK: "+topic.to_upper()
        button.custom_minimum_size.y = 48
        button.pressed.connect(_topic.bind(topic))
        stack.add_child(button)
    var close := Button.new()
    close.text = "CONTINUE EXPLORING THE INTERIOR"
    close.custom_minimum_size.y = 49
    close.pressed.connect(_close)
    stack.add_child(close)

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()

func interact(identifier: String) -> void:
    if not initialized:
        return
    var employee: bool = identifier.begins_with("interior_v072_staff_")
    var is_guest: bool = identifier.begins_with("interior_v072_guest_")
    var prefix: String = "interior_v072_guest_" if is_guest else (
        "interior_v072_staff_" if employee else "interior_v072_entry_")
    var key: String = identifier.trim_prefix(prefix)
    if not sites.has(key):
        return
    var spot: Dictionary = sites[key]
    var anchor: Node3D = spot["guest"] if is_guest else (
        spot["staff"] if employee else spot["door"])
    if not is_instance_valid(anchor) or player.global_position.distance_to(anchor.global_position) > 3.4:
        return
    current_site = key
    title.text = str(spot["record"]["label"])+(
        " / EVENING NEIGHBOR" if is_guest else (
        " / ON-DUTY WORKER" if employee else " / PUBLIC INTERIOR"))
    _topic("Household" if is_guest else "Work")
    panel.show()

func _topic(topic: String) -> void:
    if not sites.has(current_site):
        return
    var spot: Dictionary = sites[current_site]
    var spec: Dictionary = spot["record"]
    var staff: Dictionary = Interior.staff_schedule(spot["cell"],
        float(hub.get("world_minutes")))
    var day: int = 1+floori(float(hub.get("world_minutes"))/1440.0)
    if topic == "Household":
        var visitor: Dictionary = LocalV073.visitor(spot["cell"],
            float(hub.get("world_minutes")))
        story.text = "%s belongs to household %s. An existing neighbor, %s, visits this common table during the evening (17:40–20:20 game time); both have one shared identity across the ward and venue. These residents are game-only civilians." % [
            str(staff["name"]),str(staff["household"]),str(visitor["name"])]
    elif topic == "Local Commerce":
        var note: Dictionary = Interior.inventory_note(spot["cell"],day)
        var ledger: Dictionary = LocalV073.clean(hub.get("local_trade_v073"))
        var units: int = LocalV073.stock(ledger,spot["cell"])
        story.text = "Today the local focus is %s. Physical stock here: %d public goods units (up to 6 represented by real crates). The original Ring II freight wagons send couriers along neighborhood roads; inventory is credited only when the courier actually reaches this room. No invented foreign exchange rate or secret cargo." % [
            str(note["public_stock_category"]),units]
    else:
        story.text = "%s serves this neighborhood through %s. Their current activity: %s. The front doorway is open, furnishings have collision, and you can step inside." % [
            str(spec["label"]),str(spec["work"]),str(staff["activity"])]
    story.text += "\n\nCreator-safe public district prototype. No original series secrets are revealed."
    if codex.has_method("record_event"):
        codex.call("record_event","v072:venue:%s:%s" % [current_site,topic.to_lower().replace(" ","_")],
            "public_ward_interior",str(spec["label"])+": "+topic,
            "Visited a genuinely enterable original game-only Magnara venue.")

func _process(delta: float) -> void:
    tick += delta
    if tick >= 0.43:
        tick = 0.0
        _refresh()
