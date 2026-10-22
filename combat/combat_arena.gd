extends Node3D

# V0.35 first combat sandbox: real enemy HP, cone/range hits, visible windups,
# chase/patrol AI, player HP, dodge avoidance, combo practice and safe respawn.
const ConstructScript = preload("res://combat/sparring_construct.gd")
const AmbientLifeScript = preload("res://world/ambient_life.gd")
const PLAYER_MAX_HEALTH: int = 100
const PLAYER_HIT_GRACE: float = 0.75
const ENEMY_RESPAWN_SECONDS: float = 6.0

var player: CharacterBody3D
var player_health: int = PLAYER_MAX_HEALTH
var hurt_grace: float = 0.0
var ko_timer: float = 0.0
var last_strike_time: float = -100.0
var combo: int = 0
var enemies: Array[CharacterBody3D] = []
var respawn_timers: Array[float] = []
var player_health_bar: ProgressBar
var player_health_text: Label
var combat_notice: Label
var combat_notice_timer: float = 0.0
var damage_flash: ColorRect

func _ready() -> void:
    add_to_group("combat_arena")
    call_deferred("_finish_setup")

func _finish_setup() -> void:
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    if not is_instance_valid(player):
        push_warning("V0.35 arena requires the Player scene")
        return
    _create_yard()
    var ambience_node: Node3D = AmbientLifeScript.new()
    ambience_node.name = "SeekerQuarterResidents"
    add_child(ambience_node)
    _create_hud()
    var coordinates := [Vector3(-5.5, 0.56, -22.5), Vector3(5.6, 0.56, -24.0)]
    for i in range(coordinates.size()):
        var enemy: CharacterBody3D = ConstructScript.new()
        enemy.name = "SparringConstruct_%d" % (i + 1)
        add_child(enemy)
        enemy.call("configure", player, "IRON GUARD" if i == 0 else "SWIFT SHADE", coordinates[i], float(i) * 2.3)
        enemy.connect("attack_connected", _receive_enemy_attack)
        enemy.connect("knocked_out", _enemy_defeated)
        enemies.append(enemy)
        respawn_timers.append(0.0)
    _refresh_hud()

func _process(delta: float) -> void:
    hurt_grace = maxf(0.0, hurt_grace - delta)
    combat_notice_timer = maxf(0.0, combat_notice_timer - delta)
    if ko_timer > 0.0:
        ko_timer -= delta
        if ko_timer <= 0.0:
            _recover_player()
    for i in range(enemies.size()):
        if not is_instance_valid(enemies[i]):
            continue
        if not bool(enemies[i].call("is_active")):
            respawn_timers[i] += delta
            if respawn_timers[i] >= ENEMY_RESPAWN_SECONDS:
                enemies[i].call("reset_construct")
                respawn_timers[i] = 0.0
        else:
            respawn_timers[i] = 0.0
    _refresh_hud()

func player_strike(facing: Vector3) -> void:
    if not is_instance_valid(player) or ko_timer > 0.0:
        return
    var now: float = Time.get_ticks_msec() / 1000.0
    if now - last_strike_time > 1.3:
        combo = 0
    last_strike_time = now
    var forward := facing
    forward.y = 0.0
    forward = forward.normalized()
    if forward.length_squared() < 0.001:
        return
    var chosen: CharacterBody3D = null
    var nearest: float = 3.05
    for enemy in enemies:
        if not is_instance_valid(enemy) or not bool(enemy.call("is_active")):
            continue
        var offset: Vector3 = enemy.global_position - player.global_position
        offset.y = 0.0
        var distance: float = offset.length()
        if distance <= nearest and distance > 0.01 and forward.dot(offset.normalized()) >= 0.28:
            chosen = enemy
            nearest = distance
    if not is_instance_valid(chosen):
        combo = 0
        _announce("Strike missed. Face the purple construct and move closer.", 1.5)
        return
    var damage: int = 18 + mini(combo, 2) * 6
    if bool(chosen.call("take_strike", damage, player.global_position)):
        _spawn_hit_sparks(chosen.global_position + Vector3(0.0, 1.35, 0.0))
        combo = mini(combo + 1, 3)
        _announce("HIT  -%d enemy HP  |  Martial combo %d/3" % [damage, combo], 1.35)

func _receive_enemy_attack(amount: int) -> void:
    if ko_timer > 0.0 or not is_instance_valid(player):
        return
    # A successful ground dodge briefly avoids the telegraphed hit.
    if float(player.get("dodge_time")) > 0.0:
        _announce("DODGED! Counterattack with STRIKE.", 1.4)
        return
    if hurt_grace > 0.0:
        return
    var guarded: bool = false
    if bool(player.get("guard_active")):
        var hub: Node = get_tree().get_first_node_in_group("hub_manager")
        if is_instance_valid(hub) and hub.has_method("spend_guard_stamina"):
            guarded = bool(hub.call("spend_guard_stamina"))
    var final_damage: int = maxi(1, int(round(float(amount) * 0.30))) if guarded else amount
    player_health = maxi(0, player_health - final_damage)
    _flash_damage()
    hurt_grace = PLAYER_HIT_GRACE
    combo = 0
    if player_health <= 0:
        ko_timer = 2.2
        _announce("KNOCKED OUT - returning to the Seeker entry point.", 2.3)
    else:
        if guarded:
            _announce("GUARD! -%d HP, -15 Stamina. Press GUARD to lower defense." % final_damage, 1.7)
        else:
            _announce("You took %d damage. DODGE when the enemy flashes gold!" % final_damage, 1.7)
    _refresh_hud()

func _enemy_defeated() -> void:
    _announce("Sparring construct defeated! Respawns in 6 seconds.", 2.0)

func _recover_player() -> void:
    if not is_instance_valid(player):
        return
    player_health = PLAYER_MAX_HEALTH
    player.global_position = Vector3(0.0, 1.0, 2.0)
    player.velocity = Vector3.ZERO
    combo = 0
    _announce("Recovered at the Seeker Quarters. No Tola or contracts lost.", 3.0)
    _refresh_hud()

func _announce(message: String, seconds: float = 1.5) -> void:
    combat_notice_timer = seconds
    if is_instance_valid(combat_notice):
        combat_notice.text = message

func _create_yard() -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.39, 0.38, 0.40)
    var floor_tile := MeshInstance3D.new()
    floor_tile.name = "TrainingYardSurface"
    var box_mesh := BoxMesh.new()
    box_mesh.size = Vector3(19.0, 0.07, 12.0)
    floor_tile.mesh = box_mesh
    floor_tile.material_override = mat
    floor_tile.position = Vector3(0.0, 0.56, -22.5)
    add_child(floor_tile)
    for x in [-9.0, 9.0]:
        for z in [-27.4, -17.5]:
            var marker := MeshInstance3D.new()
            marker.name = "YardCornerMarker"
            var pillar := CylinderMesh.new()
            pillar.top_radius = 0.24
            pillar.bottom_radius = 0.35
            pillar.height = 1.55
            marker.mesh = pillar
            marker.position = Vector3(x, 1.28, z)
            var marker_mat := StandardMaterial3D.new()
            marker_mat.albedo_color = Color(0.24, 0.34, 0.48)
            marker.material_override = marker_mat
            add_child(marker)
    var sign := Label3D.new()
    sign.text = "MARTIAL SPARRING YARD"
    sign.font_size = 54
    sign.pixel_size = 0.007
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.no_depth_test = true
    sign.position = Vector3(0.0, 3.0, -20.0)
    add_child(sign)

func _create_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "CombatHudLayer"
    layer.layer = 9
    get_parent().add_child(layer)
    var root := Control.new()
    root.name = "CombatHud"
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)
    damage_flash = ColorRect.new()
    damage_flash.name = "DamageFeedback"
    damage_flash.color = Color(0.85, 0.06, 0.12, 0.0)
    damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
    damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(damage_flash)
    player_health_text = Label.new()
    player_health_text.text = "HP 100/100"
    player_health_text.add_theme_font_size_override("font_size", 21)
    player_health_text.offset_left = 22.0
    player_health_text.offset_top = 132.0
    player_health_text.offset_right = 410.0
    player_health_text.offset_bottom = 165.0
    player_health_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(player_health_text)
    player_health_bar = ProgressBar.new()
    player_health_bar.min_value = 0
    player_health_bar.max_value = PLAYER_MAX_HEALTH
    player_health_bar.value = PLAYER_MAX_HEALTH
    player_health_bar.show_percentage = false
    player_health_bar.offset_left = 22.0
    player_health_bar.offset_top = 162.0
    player_health_bar.offset_right = 365.0
    player_health_bar.offset_bottom = 180.0
    player_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.86, 0.22, 0.32)
    player_health_bar.add_theme_stylebox_override("fill", style)
    root.add_child(player_health_bar)
    combat_notice = Label.new()
    combat_notice.add_theme_font_size_override("font_size", 21)
    combat_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    combat_notice.anchor_left = 0.20
    combat_notice.anchor_right = 0.80
    combat_notice.anchor_top = 0.0
    combat_notice.anchor_bottom = 0.0
    combat_notice.offset_top = 187.0
    combat_notice.offset_bottom = 225.0
    combat_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(combat_notice)

func _flash_damage() -> void:
    if not is_instance_valid(damage_flash):
        return
    damage_flash.color = Color(0.85, 0.06, 0.12, 0.19)
    var fade := create_tween()
    fade.tween_property(damage_flash, "color", Color(0.85, 0.06, 0.12, 0.0), 0.32)

func _spawn_hit_sparks(at_position: Vector3) -> void:
    # Short-lived, unlit primitive effects: cheap enough for mobile WebGL.
    for i in range(5):
        var spark := MeshInstance3D.new()
        spark.name = "MartialImpact"
        var mesh := SphereMesh.new()
        mesh.radius = 0.085
        mesh.height = 0.17
        spark.mesh = mesh
        var mat := StandardMaterial3D.new()
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        mat.albedo_color = Color(0.28, 0.88, 1.0) if i % 2 == 0 else Color(1.0, 0.85, 0.31)
        spark.material_override = mat
        spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(spark)
        spark.global_position = at_position
        var theta: float = TAU * float(i) / 5.0
        var displacement := Vector3(cos(theta) * 0.85, 0.3 + sin(theta) * 0.40, sin(theta) * 0.50)
        var t := create_tween()
        t.tween_property(spark, "global_position", at_position + displacement, 0.21)
        t.tween_callback(spark.queue_free)

func _refresh_hud() -> void:
    if is_instance_valid(player_health_bar):
        player_health_bar.value = player_health
    if is_instance_valid(player_health_text):
        player_health_text.text = "HEALTH  %d / %d   |   V0.36 COMBAT" % [player_health, PLAYER_MAX_HEALTH]
    if is_instance_valid(combat_notice) and combat_notice_timer <= 0.0:
        combat_notice.text = ""
