extends Node3D
# V0.73: physically observable local deliveries. Three V0.71 wagons
# actually reach the north freight station in Ring II (INLAND, NOT A SEAPORT).
# The main ocean-going docks belong to outermost Ring VII. No ocean-going
# ship unloads at this Ring II warehouse; minor canal piers are separate.
# Land carriers then follow
# public road nodes to eligible V0.72 workrooms. Inventories are credited
# ONLY when a courier completes its full path, once per wagon per day.
const Rules = preload("res://systems/magnara_local_logistics_rules_v073.gd")
const Interiors = preload("res://systems/magnara_interiors_rules_v072.gd")
const Ward = preload("res://systems/magnara_expansion_rules_v071.gd")
var hub: Node
var player: CharacterBody3D
var codex: Node
var land: Node
var initialized: bool = false
var couriers: Dictionary = {}
var stage: Node3D
var panel: PanelContainer
var details: Label
var drawn_second: float = 0.0

func _ready() -> void:
    add_to_group("v073_public_logistics")
    set_process(false)
    call_deferred("_setup")

func _setup() -> void:
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    land = get_tree().get_first_node_in_group("v071_land_commerce")
    if not is_instance_valid(player) or not is_instance_valid(hub) \
            or not is_instance_valid(land) or not is_instance_valid(codex):
        return
    _make_public_depot()
    _make_ui()
    initialized = true
    _sync_couriers()
    set_process(true)

func _mat(tint: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    material.roughness = 0.88
    return material

func _block(parent: Node3D,label: String,at: Vector3,dims: Vector3,
        color: Color,collides: bool = false) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    mesh.name = label
    var unit := BoxMesh.new()
    unit.size = dims
    mesh.mesh = unit
    mesh.material_override = _mat(color)
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    mesh.position = at
    parent.add_child(mesh)
    if collides:
        var physics := StaticBody3D.new()
        physics.name = label+"Collider"
        mesh.add_child(physics)
        var hit := CollisionShape3D.new()
        hit.name = "V073PhysicalCargoCollision"
        var box := BoxShape3D.new()
        box.size = dims
        hit.shape = box
        physics.add_child(hit)
    return mesh

func _make_public_depot() -> void:
    stage = Node3D.new()
    stage.name = "V073WorkingPublicFreightDepot"
    stage.position = Vector3(14,0,1375)
    add_child(stage)
    _block(stage,"V073CargoManifestDesk",
        Vector3(4.6,1.14,0),
        Vector3(2.2,1.2,1.8),Color(0.39,0.36,0.28),true)
    for n in range(5):
        _block(stage,"V073VisibleCrateStage",
            Vector3(4.2+float(n%2)*1.3,1.13,
                3.0+float(int(n/2))*1.5),
            Vector3(1.15,0.95,1.1),Color(0.56,0.44,0.28),true)
    var sign := Label3D.new()
    sign.name = "V073PublicGoodsBoard"
    sign.text = "RING II / INLAND GOODS DEPOT / NO SEA-GOING DOCK"
    sign.position = Vector3(2.2,3.60,-1.8)
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.no_depth_test = true
    sign.font_size = 27
    sign.pixel_size = 0.0044
    stage.add_child(sign)
    var marker := Node3D.new()
    marker.name = "V073CargoLedgerMarker"
    marker.position = Vector3(-3.2,0.84,0)
    stage.add_child(marker)
    hub.call("_add_location","logistics_v073_depot",
        "Ring II Inland Freight Ledger",marker.global_position,marker)

func _make_ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.name = "V073FreightNoticeBoardUI"
    canvas.layer = 39
    get_parent().add_child(canvas)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(root)
    panel = PanelContainer.new()
    panel.anchor_left = 0.08
    panel.anchor_right = 0.92
    panel.anchor_top = 0.09
    panel.anchor_bottom = 0.91
    panel.visible = false
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.075,0.074,0.10,0.975)
    style.border_color = Color(0.64,0.58,0.43)
    style.set_border_width_all(2)
    style.set_corner_radius_all(9)
    panel.add_theme_stylebox_override("panel",style)
    root.add_child(panel)
    var margin := MarginContainer.new()
    for side in ["left","right","top","bottom"]:
        margin.add_theme_constant_override("margin_"+side,16)
    panel.add_child(margin)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    margin.add_child(scroll)
    var stack := VBoxContainer.new()
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stack.add_theme_constant_override("separation",14)
    scroll.add_child(stack)
    var head := Label.new()
    head.text = "MAGNARA RING II / INLAND GOODS LEDGER"
    head.add_theme_font_size_override("font_size",22)
    head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(head)
    details = Label.new()
    details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    details.custom_minimum_size.y = 285
    stack.add_child(details)
    var close := Button.new()
    close.text = "RETURN TO PUBLIC STREETS"
    close.custom_minimum_size.y = 52
    close.pressed.connect(_close)
    stack.add_child(close)

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()

func interact(identifier: String) -> void:
    if identifier != "logistics_v073_depot" or not initialized or not is_instance_valid(stage):
        return
    var center: Vector3 = stage.global_position+Vector3(-3.2,0.84,0)
    if player.global_position.distance_to(center) > float(hub.get("interact_range")):
        return
    _update_panel()
    panel.show()

func _update_panel() -> void:
    if not is_instance_valid(details):
        return
    var ledger: Dictionary = Rules.clean(hub.get("local_trade_v073"))
    var day: int = 1+floori(float(hub.get("world_minutes"))/1440.0)
    details.text = "Ring II inland distribution / Day %d\n" % day
    details.text += "These are LAND wagons, not harbor ships. Deepwater docks are in Ring VII.\n"
    details.text += "3 physical wagons; up to 3 public couriers active.\n"
    details.text += "Goods count at destinations ONLY after arrival. No automatic player Tola.\n"
    details.text += "Delivery records: %d complete; %d on foot.\n\n" % [
        ledger["receipts"].size(),ledger["pending"].size()]
    for i in range(Rules.WAGON_COUNT):
        var dispatch: Dictionary = Rules.delivery(day,i)
        var receipt: String = str(dispatch["receipt"])
        var status: String = "RECEIVED" if ledger["receipts"].has(receipt) else (
            "IN TRANSIT" if ledger["pending"].has(receipt) else "AWAITING WAGON")
        details.text += "Wagon %d | %s | %s | %d units on arrival\n" % [
            i+1,str(dispatch["cell"]),status,int(dispatch["units"])]
    details.text += "\nThese are public Janoah district deliveries. No unverified national customs routes, military shipments, or secret currencies."

func get_manifest() -> Dictionary:
    var ledger: Dictionary = Rules.clean(hub.get("local_trade_v073")) if is_instance_valid(hub) else Rules.clean({})
    return {"version":73,"initialized":initialized,
        "active_couriers":couriers.size(),
        "daily_wagon_unload_capacity":Rules.WAGON_COUNT,
        "public_delivery_targets":12,
        "physical_depot":is_instance_valid(stage),
        "inland_ring":2,
        "major_ocean_port_ring":7,
        "maritime_dock":false,
        "allows_minor_canal_transfer":true,
        "has_mapped_canal_to_outer_port":false,
        "persistent_receipts":ledger["receipts"].size(),
        "pending_receipts":ledger["pending"].size(),
        "no_player_tola_payout":true,
        "gated_public_trade_only":true,
        "shipping_abroad_simulated":false}

func _make_courier(receipt: String,manifest: Dictionary) -> void:
    if couriers.has(receipt):
        return
    var actor := AnimatableBody3D.new()
    actor.name = "V073LocalCourier_"+receipt
    actor.add_to_group("v073_physically_scheduled_courier")
    actor.sync_to_physics = false
    actor.collision_layer = 0
    actor.collision_mask = 1
    add_child(actor)
    var hit := CollisionShape3D.new()
    hit.name = "V073CourierRealCollision"
    hit.position = Vector3(0,1.0,0)
    var capsule := CapsuleShape3D.new()
    capsule.height = 1.65
    capsule.radius = 0.26
    hit.shape = capsule
    actor.add_child(hit)
    _block(actor,"V073CourierBody",Vector3(0,1.09,0),
        Vector3(0.53,0.83,0.39),Color(0.41,0.52,0.58))
    _block(actor,"V073CourierFace",Vector3(0,1.77,0),
        Vector3(0.34,0.36,0.33),Color(0.70,0.54,0.43))
    _block(actor,"V073CourierTrousers",Vector3(0,0.43,0),
        Vector3(0.42,0.59,0.35),Color(0.30,0.32,0.36))
    _block(actor,"V073PhysicalCarriedCargo",Vector3(0.43,1.04,0),
        Vector3(0.69,0.64,0.72),Color(0.58,0.42,0.24))
    couriers[receipt] = actor
    _position_courier(receipt)

func _position_courier(receipt: String) -> void:
    if not couriers.has(receipt):
        return
    var ledger: Dictionary = Rules.clean(hub.get("local_trade_v073"))
    var packet: Dictionary = ledger["pending"].get(receipt,{})
    var decoded: Dictionary = Rules.receipt_parse(receipt)
    if packet.is_empty() or decoded.is_empty():
        return
    var state: Dictionary = Rules.courier_state(
        int(decoded["day"]),int(decoded["wagon"]),float(packet["elapsed"]))
    var actor: AnimatableBody3D = couriers[receipt]
    if not is_instance_valid(actor) or state.is_empty():
        return
    actor.global_position = state["position"]
    var near: bool = actor.global_position.distance_to(player.global_position) < Rules.SCENE_REACH_M
    actor.visible = near
    actor.collision_layer = 1 if near else 0

func _sync_couriers() -> void:
    if not initialized:
        return
    var ledger: Dictionary = Rules.clean(hub.get("local_trade_v073"))
    for key in couriers.keys():
        if not ledger["pending"].has(key):
            var actor: AnimatableBody3D = couriers[key]
            couriers.erase(key)
            if is_instance_valid(actor):
                actor.queue_free()
    for key in ledger["pending"].keys():
        if not couriers.has(key):
            var id: Dictionary = Rules.receipt_parse(str(key))
            if not id.is_empty():
                _make_courier(str(key),Rules.delivery(int(id["day"]),int(id["wagon"])))
        _position_courier(str(key))

func _register_wagon_dock(wagon: int,day: int) -> bool:
    if not initialized:
        return false
    var previous: Dictionary = Rules.clean(hub.get("local_trade_v073"))
    var queued: Dictionary = Rules.queue(previous,day,wagon)
    if not bool(queued.get("accepted",false)):
        return false
    hub.set("local_trade_v073",queued["ledger"])
    var manifest: Dictionary = queued["manifest"]
    _make_courier(str(manifest["receipt"]),manifest)
    if player.global_position.distance_to(Rules.DOCK_AT) < 140.0:
        hub.call("_announce","Public freight wagon unloaded: courier heading to %s." % str(manifest["cell"]))
    return true

func _process(delta: float) -> void:
    if not initialized:
        return
    drawn_second += delta
    if drawn_second > 0.34:
        drawn_second = 0.0
        _sync_couriers()
        if is_open():
            _update_panel()
    # Advance only existing manifest packets. The original wagon road cycle
    # is authoritative for starting a consignment; this service never
    # manufactures a shipment when loading from a save.
    var ledger: Dictionary = hub.get("local_trade_v073")
    if typeof(ledger) != TYPE_DICTIONARY:
        return
    var pending: Dictionary = ledger.get("pending",{})
    for key in pending.keys():
        var result: Dictionary = Rules.advance(ledger,str(key),delta)
        ledger = result.get("ledger",ledger)
        hub.set("local_trade_v073",ledger)
        if bool(result.get("completed",false)):
            _sync_couriers()
            var manifest: Dictionary = result["manifest"]
            if is_instance_valid(codex) and codex.has_method("record_event"):
                codex.call("record_event","v073:delivered:"+str(key),
                    "public_local_delivery","Local freight reached workroom",
                    "Observed shipment to %s: %d units. No player payout." % [
                    str(manifest["cell"]),int(manifest["units"])])
            # Existing verified save protects stock, receipts and character.
            hub.call("_save_game")
            if player.global_position.distance_to(manifest["target"]) < 120.0:
                hub.call("_announce","Public workroom received a local freight crate.")
        else:
            _position_courier(str(key))
