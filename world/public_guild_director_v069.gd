extends Node3D
# V0.69 - real public-operations board; local simulation contracts only.
# Official Seeker rank gates are preserved. Undercover Red Order, The Family,
# Phantom Tola, and high-rank raids stay story-authorized, never procedural.
const Director = preload("res://systems/guild_public_director_v069.gd")
const SaveIntegrity = preload("res://systems/game_save_integrity_v063.gd")
var hub: Node
var player: CharacterBody3D
var codex: Node
var panel: PanelContainer
var heading: Label
var status: Label
var list_box: VBoxContainer
var result_text: Label
var initialized: bool = false
var check_seconds: float = 0.0

func _ready() -> void:
    add_to_group("v069_public_director")
    set_process(false)
    call_deferred("_setup")

func _setup() -> void:
    hub = get_tree().get_first_node_in_group("hub_manager")
    codex = get_tree().get_first_node_in_group("personal_codex")
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(player):
        push_warning("V0.69 civic director needs original player, hub and codex")
        return
    _make_board()
    _ui()
    initialized = true
    set_process(true)

func _block(parent: Node3D, name: String, position: Vector3, size: Vector3,
        color: Color, solid: bool = false) -> Node3D:
    var visual := MeshInstance3D.new()
    visual.name = name
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    visual.material_override = mat
    visual.position = position
    parent.add_child(visual)
    if solid:
        var body := StaticBody3D.new()
        visual.add_child(body)
        var hit := CollisionShape3D.new()
        hit.name = "V069CivicBoardCollision"
        var box := BoxShape3D.new()
        box.size = size
        hit.shape = box
        body.add_child(hit)
    return visual

func _sign(parent: Node3D, label: String, at: Vector3) -> void:
    var tag := Label3D.new()
    tag.name = "V069PublicDistrictSign"
    tag.text = label
    tag.position = at
    tag.font_size = 26
    tag.pixel_size = 0.0043
    tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    tag.no_depth_test = true
    parent.add_child(tag)

func _make_board() -> void:
    var station := Node3D.new()
    station.name = "V069PublicCivicAssociationBoard"
    station.position = Vector3(16.0,0.0,8.0)
    add_child(station)
    _block(station,"V069DailyBoard",Vector3(0,2.20,0),Vector3(0.42,2.9,3.5),
        Color(0.43,0.36,0.29),true)
    _block(station,"V069BoardPaper",Vector3(-0.25,2.25,0),Vector3(0.07,2.3,2.9),
        Color(0.77,0.71,0.56))
    _sign(station,"PUBLIC ASSIGNMENTS / NO PROMOTION",Vector3(0,4.35,0))
    var use := Node3D.new()
    use.name = "V069PublicBoardApproach"
    use.position = Vector3(-3.5,0.82,0)
    station.add_child(use)
    hub.call("_add_location","guild_v069_board","Association Public Operations Board",
        use.global_position,use)
    for i in range(Director.JOBS.size()):
        var task: String = Director.JOBS[i]
        var at: Vector3 = Director.LOCATIONS[i]
        var marker := Node3D.new()
        marker.name = "V069PublicDestination_" + task
        marker.position = at
        add_child(marker)
        _block(marker,"V069DestinationStand",Vector3(0,0.80,0),
            Vector3(0.20,0.28,0.20),Color(0.64,0.57,0.39))
        _sign(marker,"PUBLIC TASK: "+task.replace("_"," ").to_upper(),Vector3(0,3.2,0))
        hub.call("_add_location","guild_v069_target_"+task,task.replace("_"," ").capitalize(),
            marker.global_position,marker)

func get_manifest() -> Dictionary:
    return {"version":69,"physical_public_board":initialized,
        "daily_public_jobs":Director.JOBS.size(),
        "uses_existing_save":true,"rank_gated":true,
        "secret_antagonist_simulation":false,
        "canon_status":"game_only_civic"}
func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible
func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()
func _record() -> Dictionary:
    return Director.sanitize(hub.get("guild_director_v069"))
func _day() -> int:
    return Director.day(float(hub.get("world_minutes")))

func _ui() -> void:
    var canvas := CanvasLayer.new()
    canvas.layer = 32
    canvas.name = "V069PublicOperationsCanvas"
    get_parent().add_child(canvas)
    var base := Control.new()
    base.set_anchors_preset(Control.PRESET_FULL_RECT)
    base.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(base)
    panel = PanelContainer.new()
    panel.anchor_left = 0.08
    panel.anchor_right = 0.92
    panel.anchor_top = 0.07
    panel.anchor_bottom = 0.93
    panel.visible = false
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.07,0.09,0.12,0.99)
    style.border_color = Color(0.63,0.56,0.37)
    style.set_border_width_all(2)
    style.set_corner_radius_all(10)
    panel.add_theme_stylebox_override("panel",style)
    base.add_child(panel)
    var margin := MarginContainer.new()
    for side in ["left","right","top","bottom"]:
        margin.add_theme_constant_override("margin_"+side,14)
    panel.add_child(margin)
    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    margin.add_child(scroll)
    var stack := VBoxContainer.new()
    stack.add_theme_constant_override("separation",9)
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(stack)
    heading = Label.new()
    heading.add_theme_font_size_override("font_size",22)
    heading.text = "SEEKER ASSOCIATION / PUBLIC OPERATIONS"
    stack.add_child(heading)
    status = Label.new()
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(status)
    list_box = VBoxContainer.new()
    list_box.add_theme_constant_override("separation",8)
    stack.add_child(list_box)
    result_text = Label.new()
    result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stack.add_child(result_text)
    var close := Button.new()
    close.text = "RETURN TO MAGNARA"
    close.custom_minimum_size.y = 50
    close.pressed.connect(_close)
    stack.add_child(close)

func _refresh() -> void:
    for child in list_box.get_children():
        list_box.remove_child(child)
        child.queue_free()
    var state: Dictionary = _record()
    var active: String = str(state["active"])
    status.text = "Day %d / Current rank: %s / Active civic duty: %s\n" % [
        _day(),GameState.seeker_rank, active if not active.is_empty() else "none"]
    status.text += "Local public trade observed: %d units.\n" % Director.observed_units(
        hub.get("shop_stock_v066"),_day())
    status.text += "These are prototype public assignments, never official promotions or secret raids."
    for entry in Director.catalog_status(state,_day(),GameState.seeker_rank,hub.get("shop_stock_v066")):
        var button := Button.new()
        button.custom_minimum_size.y = 71
        button.text = "%s / %s+ / %d Tola\n%s" % [
            str(entry["title"]),str(entry["rank"]),int(entry["reward_tola"]),
            str(entry["description"])]
        button.disabled = not bool(entry["eligible"]) or bool(entry["finished"]) or not active.is_empty()
        if bool(entry["finished"]):
            button.text = "REPORTED TODAY — " + button.text
        if bool(entry["active"]):
            button.text = "ON YOUR ROUTE — " + button.text
        button.pressed.connect(_accept.bind(str(entry["id"])))
        list_box.add_child(button)
    if not active.is_empty():
        var cancel := Button.new()
        cancel.text = "ABANDON UNFINISHED PUBLIC ASSIGNMENT"
        cancel.custom_minimum_size.y = 54
        cancel.pressed.connect(_abandon)
        list_box.add_child(cancel)

func _save_change(next: Dictionary, previous: Dictionary, pay: int = 0) -> bool:
    var old_cash: int = GameState.tola
    var old_rep: int = int(hub.get("guild_rep"))
    hub.set("guild_director_v069",next)
    if pay > 0:
        GameState.earn_tola(pay)
        hub.set("guild_rep",old_rep + 1)
    var saved: bool = bool(hub.call("_save_game"))
    if saved:
        var checked: Dictionary = SaveIntegrity.load_best()
        var data: Dictionary = checked.get("data",{})
        saved = str(checked.get("source","none")) == "primary" and \
            Director.sanitize(data.get("guild_director_v069",{})) == Director.sanitize(next) \
            and int(data.get("tola",-1)) == GameState.tola
    if not saved:
        hub.set("guild_director_v069",previous)
        GameState.tola = old_cash
        GameState.tola_changed.emit(old_cash)
        hub.set("guild_rep",old_rep)
        hub.call("_save_game")
    return saved

func _accept(job: String) -> void:
    var old: Dictionary = _record()
    var accepted: Dictionary = Director.accept(old,job,_day(),GameState.seeker_rank)
    if accepted.is_empty() or not _save_change(accepted,old):
        result_text.text = "Assignment unavailable; no progress changed."
        return
    result_text.text = "Accepted. Travel to the PUBLIC TASK marker, then tap TALK / USE."
    _refresh()

func _abandon() -> void:
    var old: Dictionary = _record()
    if str(old["active"]).is_empty():
        return
    var next: Dictionary = old.duplicate(true)
    next["active"] = ""
    next["accepted_day"] = 0
    if _save_change(next,old):
        result_text.text = "Unfinished civic duty abandoned. No reward granted."
    _refresh()

func _complete(job: String) -> void:
    var previous: Dictionary = _record()
    var today: int = _day()
    var next: Dictionary = Director.finish(previous,job,today,player.global_position)
    if next.is_empty():
        hub.call("_announce","This public task is not currently assigned to you.")
        return
    var entry: Dictionary = Director.description(job,today,hub.get("shop_stock_v066"))
    var payout: int = int(entry.get("reward_tola",0))
    if payout <= 0 or not _save_change(next,previous,payout):
        hub.call("_announce","Could not verify civic report; payout was not granted.")
        return
    hub.call("_announce","PUBLIC ASSIGNMENT COMPLETE +%d Tola, +1 game-only guild reputation." % payout)
    if codex.has_method("record_event"):
        codex.call("record_event","v069:public:%s:day:%d" % [job,today],
            "public_civic_duty","Completed " + str(entry["title"]),
            "Reported a public Magnara prototype duty for %d Tola; no canon quest or rank change." % payout)

func interact(key: String) -> void:
    if not initialized:
        return
    if key == "guild_v069_board":
        if player.global_position.distance_to(Vector3(12.5,0.82,8.0)) > float(hub.get("interact_range")):
            return
        result_text.text = "See public work, the destination marker, and today's locally observed activity."
        _refresh()
        panel.show()
    elif key.begins_with("guild_v069_target_"):
        _complete(key.trim_prefix("guild_v069_target_"))

func _process(delta: float) -> void:
    check_seconds += delta
    if check_seconds >= 0.80:
        check_seconds = 0.0
        var old: Dictionary = _record()
        if not str(old["active"]).is_empty() and int(old["accepted_day"]) < _day():
            var next: Dictionary = old.duplicate(true)
            next["active"] = ""
            next["accepted_day"] = 0
            _save_change(next,old)
        if is_open():
            _refresh()
