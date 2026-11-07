extends Node3D
# V0.69 licensed public Seeker Quarter practice table, NOT the Hollow Thread Atelier.
# 3 finite safe runes: trigger -> Aura condition -> effect. Crafting NEVER
# grants Ice Muti, Spatial teleports, Soul tampering, or rare Alchemy mastery.
const Seals = preload("res://systems/alchemic_seal_rules_v069.gd")
const PROFILE_PATH = "user://seeker_profile_v1.json"
var hub: Node
var codex: Node
var player: CharacterBody3D
var initialized: bool = false
var panel: PanelContainer
var details: Label
var reply: Label
var active_trigger: String = "impact"
var active_effect: String = "ward"
var status_tick: float = 0.0

func _ready() -> void:
    add_to_group("v069_public_seals")
    set_process(false)
    call_deferred("_setup")

func _setup() -> void:
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(player):
        push_warning("V0.69 Seal practice table needs the existing player, hub and Personal Codex")
        return
    _workbench()
    _ui()
    initialized = true
    set_process(true)

func _mat(shade: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = shade
    mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    return mat

func _cube(parent: Node3D, name: String, at: Vector3, size: Vector3, tint: Color,
        collides: bool = false) -> Node3D:
    var visual := MeshInstance3D.new()
    visual.name = name
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    visual.material_override = _mat(tint)
    visual.position = at
    visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(visual)
    if collides:
        var body := StaticBody3D.new()
        visual.add_child(body)
        var collision := CollisionShape3D.new()
        collision.name = "V069RuneBenchCollider"
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
    return visual

func _workbench() -> void:
    var root := Node3D.new()
    root.name = "V069PublicTrainingSealTable"
    root.position = Vector3(14.8, 0.0, -24.2)
    add_child(root)
    _cube(root, "V069RunePracticeTable", Vector3(0, 1.20, 0),
        Vector3(1.5,0.22,2.8), Color(0.39,0.30,0.24),true)
    for side in [-1.0,1.0]:
        _cube(root, "V069RuneTableLeg", Vector3(0,0.74,side*0.95),
            Vector3(1.12,0.75,0.18),Color(0.26,0.27,0.30),true)
    for j in range(3):
        _cube(root, "V069VisualRuneSlot",Vector3(0,1.38,(float(j)-1.0)*0.82),
            Vector3(0.72,0.11,0.56),
            Color(0.29 + float(j)*0.13,0.53,0.76-float(j)*0.14))
    var sign := Label3D.new()
    sign.name = "V069TrainingOnlySign"
    sign.text = "SUPERVISED ALCHEMIC SEAL PRACTICE"
    sign.position = Vector3(0,3.1,0)
    sign.font_size = 24
    sign.pixel_size = 0.0042
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.no_depth_test = true
    root.add_child(sign)
    var use_point := Node3D.new()
    use_point.name = "V069SealApproach"
    use_point.position = Vector3(-3.1,0.80,0)
    root.add_child(use_point)
    hub.call("_add_location","seal_v069_practice","Supervised Alchemy Seal Table",
        use_point.global_position,use_point)

func _ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "V069SealWorkshopCanvas"
    layer.layer = 31
    get_parent().add_child(layer)
    var ctrl := Control.new()
    ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
    ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(ctrl)
    panel = PanelContainer.new()
    panel.anchor_left = 0.08
    panel.anchor_right = 0.92
    panel.anchor_top = 0.08
    panel.anchor_bottom = 0.92
    panel.visible = false
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.065,0.085,0.13,0.99)
    style.border_color = Color(0.74,0.61,0.36)
    style.set_border_width_all(2)
    style.set_corner_radius_all(10)
    panel.add_theme_stylebox_override("panel",style)
    ctrl.add_child(panel)
    var margins := MarginContainer.new()
    margins.add_theme_constant_override("margin_left",15)
    margins.add_theme_constant_override("margin_right",15)
    margins.add_theme_constant_override("margin_top",15)
    margins.add_theme_constant_override("margin_bottom",15)
    panel.add_child(margins)
    var scroll := ScrollContainer.new()
    margins.add_child(scroll)
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation",9)
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(stack)
    var head := Label.new()
    head.text = "ALCHEMIC SEAL GRAMMAR / TRAINING"
    head.add_theme_font_size_override("font_size",23)
    stack.add_child(head)
    details = Label.new()
    details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(details)
    for pair in [
        ["1. SET TRIGGER: ON IMPACT","impact"],
        ["1. SET TRIGGER: AURA READY","aura_ready"],
        ["2. SET EFFECT: ONE-HIT WARD (18 AURA)","ward"],
        ["2. SET EFFECT: REPORT SIGNAL (8 AURA)","signal"],
        ["3. ENCODE & ARM THREE-RUNE SEAL","arm"]
    ]:
        var btn := Button.new()
        btn.text = str(pair[0])
        btn.custom_minimum_size.y = 48
        btn.pressed.connect(_choose.bind(str(pair[1])))
        stack.add_child(btn)
    reply = Label.new()
    reply.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(reply)
    var close := Button.new()
    close.text = "RETURN TO THE TRAINING YARD"
    close.custom_minimum_size.y = 48
    close.pressed.connect(_close)
    stack.add_child(close)

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()

func _memory() -> Dictionary:
    if not is_instance_valid(codex):
        return {}
    var profile: Dictionary = codex.get("profile")
    return profile.get("seals_v069", {}) if typeof(profile.get("seals_v069", null)) == TYPE_DICTIONARY else {}

func _verify_memory(expected: Dictionary) -> bool:
    var f := FileAccess.open(PROFILE_PATH,FileAccess.READ)
    if f == null:
        return false
    var content: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    if typeof(content) != TYPE_DICTIONARY:
        return false
    var record: Dictionary = content
    if typeof(record.get("seals_v069", null)) != TYPE_DICTIONARY:
        return false
    var saved: Dictionary = record["seals_v069"]
    return Seals.sanitize(saved.get("recipe", {})) == Seals.sanitize(expected.get("recipe", {})) \
        and Seals.ledger(saved.get("receipts", {})) == Seals.ledger(expected.get("receipts", {}))

func _write_memory(next: Dictionary) -> bool:
    if bool(codex.get("save_blocked")):
        return false
    var original: Dictionary = codex.get("profile")
    var modified: Dictionary = original.duplicate(true)
    modified["seals_v069"] = next
    codex.set("profile",modified)
    codex.call("_save_profile")
    if not _verify_memory(next):
        codex.set("profile",original)
        return false
    return true

func _day() -> int:
    return maxi(1,floori(float(hub.get("world_minutes"))/1440.0)+1)

func _refresh() -> void:
    var memory: Dictionary = _memory()
    var recipe: Dictionary = Seals.sanitize(memory.get("recipe", {}))
    var ledger: Dictionary = Seals.ledger(memory.get("receipts", {}))
    details.text = "RUNES: Trigger [%s] -> Aura >= %d -> Effect [%s]" % [
        active_trigger, int(Seals.COSTS[active_effect]), active_effect]
    details.text += "\nYour Aura: %.1f / Uses today: %s" % [
        float(hub.get("aura")), "complete" if ledger.has("day:%d" % _day()) else "available"]
    details.text += "\nArmed: %s" % ("YES" if bool(recipe.get("armed",false)) else "NO")
    details.text += "\nOnly supervised impact ward or harmless signal effects are permitted."
    details.text += "\nThis is not Hollow Thread Atelier and grants no licensed advanced Alchemy."

func interact(key: String) -> void:
    if not initialized or key != "seal_v069_practice":
        return
    if player.global_position.distance_to(Vector3(11.7,0.8,-24.2)) > float(hub.get("interact_range")):
        return
    reply.text = "Choose a trigger, a bounded effect, then encode and arm the seal."
    _refresh()
    panel.show()

func _choose(option: String) -> void:
    if Seals.TRIGGERS.has(option):
        active_trigger = option
        reply.text = "Trigger selected: " + option.replace("_"," ")
    elif Seals.EFFECTS.has(option):
        active_effect = option
        reply.text = "Effect selected: " + option
    elif option == "arm":
        if active_trigger == "aura_ready" and active_effect != "signal":
            reply.text = "Aura-ready activation supports the harmless signal only."
            _refresh()
            return
        var recipe: Dictionary = Seals.arm(Seals.recipe(active_trigger,active_effect))
        if recipe.is_empty():
            reply.text = "This seal formula cannot be encoded."
            return
        var last: Dictionary = _memory()
        var next: Dictionary = {"recipe":recipe, "receipts":Seals.ledger(last.get("receipts",{}))}
        if not _write_memory(next):
            reply.text = "Storage was not verified; no active seal created."
            return
        reply.text = "A bounded three-rune prototype is armed; it triggers once per day."
        if codex.has_method("record_event"):
            codex.call("record_event","v069:seal:crafted:%s:%s" % [active_trigger,active_effect],
                "alchemy_training","Encoded a supervised rune recipe",
                "Trigger, Aura condition and %s; public test only." % active_effect)
    _refresh()

func _fire(trigger: String) -> Dictionary:
    var record: Dictionary = _memory()
    var recipe: Dictionary = Seals.sanitize(record.get("recipe", {}))
    var verdict: Dictionary = Seals.fire(recipe,record.get("receipts",{}),trigger,
        float(hub.get("aura")),_day())
    if not bool(verdict.get("fired",false)):
        return verdict
    var next: Dictionary = {"recipe":verdict["next_recipe"],"receipts":verdict["next_receipts"]}
    var prior_aura: float = float(hub.get("aura"))
    hub.set("aura", prior_aura - float(verdict["cost"]))
    if not _write_memory(next):
        hub.set("aura", prior_aura)
        return {"fired":false,"reason":"profile_save_failed"}
    if not bool(hub.call("_save_game")):
        hub.set("aura",prior_aura)
        _write_memory(record)
        return {"fired":false,"reason":"world_save_failed"}
    if codex.has_method("record_event"):
        codex.call("record_event", "v069:seal:fired:day:%d" % _day(),
            "alchemy_training", "A prepared training seal reacted",
            "Effect: %s. %d Aura, one use per day. No sealed Muti." % [
                str(verdict["effect"]),int(verdict["cost"])])
    if is_open():
        _refresh()
    return verdict

func on_impact(amount: int) -> bool:
    if amount <= 0 or not initialized:
        return false
    var result: Dictionary = _fire("impact")
    return bool(result.get("fired",false)) and bool(result.get("absorbed",false))

func _process(delta: float) -> void:
    status_tick += delta
    if status_tick >= 0.8:
        status_tick = 0.0
        if initialized:
            _fire("aura_ready")
        if is_open():
            _refresh()
