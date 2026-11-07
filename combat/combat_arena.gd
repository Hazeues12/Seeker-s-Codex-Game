extends Node3D

# V0.35 first combat sandbox: real enemy HP, cone/range hits, visible windups,
# chase/patrol AI, player HP, dodge avoidance, combo practice and safe respawn.
const ConstructScript = preload("res://combat/sparring_construct.gd")
const Posture = preload("res://combat/triad_posture_rules_v069.gd")
const AmbientLifeScript = preload("res://world/ambient_life.gd")
const PLAYER_MAX_HEALTH: int = 100
const PLAYER_HIT_GRACE: float = 0.75
const ENEMY_RESPAWN_SECONDS: float = 6.0

var player: CharacterBody3D
var player_health: int = PLAYER_MAX_HEALTH
var player_posture: float = Posture.MAX_POSTURE
var player_posture_break_time: float = 0.0
var perfect_parry_count: int = 0
var posture_notice: Label
var hurt_grace: float = 0.0
var ko_timer: float = 0.0
var alchemy_shield_time: float = 0.0
var last_strike_time: float = -100.0
var combo: int = 0
var enemies: Array[CharacterBody3D] = []
var field_enemies: Array[CharacterBody3D] = []
var respawn_timers: Array[float] = []
var player_health_bar: ProgressBar
var player_health_text: Label
var combat_notice: Label
var combat_notice_timer: float = 0.0
var damage_flash: ColorRect
var strike_burst_mesh: ArrayMesh

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
    alchemy_shield_time = maxf(0.0, alchemy_shield_time - delta)
    combat_notice_timer = maxf(0.0, combat_notice_timer - delta)
    player_posture_break_time = maxf(0.0, player_posture_break_time - delta)
    if player_posture_break_time <= 0.0:
        player_posture = Posture.recover(player_posture,delta)
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

# External field encounters use the same real hit detection without arena respawns.
func register_field_enemy(fighter: CharacterBody3D) -> void:
    if is_instance_valid(fighter) and not field_enemies.has(fighter):
        field_enemies.append(fighter)
        fighter.connect("attack_connected", _receive_field_enemy_attack)

func _receive_field_enemy_attack(amount: int) -> void:
    var mission: Node = get_tree().get_first_node_in_group("field_mission_v048")
    if is_instance_valid(mission) and mission.has_method("intercept_field_attack"):
        if bool(mission.call("intercept_field_attack", amount)):
            _announce("Your volunteer partner intercepted an attack.", 1.6)
            return
    _receive_enemy_attack(amount)

func unregister_field_enemy(fighter: CharacterBody3D) -> void:
    field_enemies.erase(fighter)

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
    for enemy in enemies + field_enemies:
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
    var defender := chosen as ConstructScript
    var guarded: bool = defender != null and defender.state == "guard"
    if bool(chosen.call("take_strike", damage, player.global_position)):
        var impact_ticks: int = 3 if guarded else (6 if combo >= 2 else 4)
        if defender != null:
            defender.hold_strike_impact(impact_ticks)
        player.call("show_strike_impact", impact_ticks, forward)
        var point: Vector3 = chosen.global_position - forward * 0.45 + Vector3.UP * 1.36
        _spawn_strike_burst(point, impact_ticks)
        combo = mini(combo + 1, 3)
        _announce("HIT  -%d enemy HP  |  Martial combo %d/3" % [damage, combo], 1.35)

# Supervised basic-Spoke practice: this never grants permanent character powers.
# Each practice technique has its own real combat/defensive effect.
func _training_target(forward: Vector3, max_range: float) -> CharacterBody3D:
    if not is_instance_valid(player):
        return null
    var selected: CharacterBody3D = null
    var nearest: float = max_range
    for fighter in enemies:
        if not is_instance_valid(fighter) or not bool(fighter.call("is_active")):
            continue
        var offset: Vector3 = fighter.global_position - player.global_position
        offset.y = 0.0
        var range_now: float = offset.length()
        if range_now > 0.01 and range_now < nearest and forward.dot(offset.normalized()) >= 0.20:
            selected = fighter
            nearest = range_now
    return selected

func training_spoke_effect(spoke: String, facing: Vector3) -> Dictionary:
    if not is_instance_valid(player) or ko_timer > 0.0:
        return {"ok": false, "message": "Recover before practicing another Art."}
    var forward: Vector3 = facing
    forward.y = 0.0
    forward = forward.normalized()
    if forward.length_squared() < 0.01:
        return {"ok": false, "message": "Choose a direction first."}
    if spoke == "Spirit":
        if player_health >= PLAYER_MAX_HEALTH:
            return {"ok": false, "message": "HP already full; no healing needed."}
        player_health = mini(PLAYER_MAX_HEALTH, player_health + 16)
        _training_flash(player.global_position + Vector3.UP * 1.3, Color(0.40, 0.90, 0.61))
        _refresh_hud()
        return {"ok": true, "message": "Restorative practice restored 16 HP."}
    if spoke == "Alchemy":
        alchemy_shield_time = 4.5
        _training_flash(player.global_position + Vector3.UP * 1.3, Color(0.92, 0.76, 0.40))
        return {"ok": true, "message": "Temporary ward ready to absorb one hit."}
    if spoke == "Spatial":
        var start: Vector3 = player.global_position + Vector3.UP * 1.1
        var target: Vector3 = player.global_position + forward * 3.0
        if absf(target.x) >= 9.3 or target.z < -28.0 or target.z > -17.0:
            return {"ok": false, "message": "Shift stays within the supervised training court."}
        var ray := PhysicsRayQueryParameters3D.create(start, target + Vector3.UP * 1.1)
        ray.exclude = [player.get_rid()]
        var obstacle: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
        if not obstacle.is_empty():
            return {"ok": false, "message": "A solid obstacle blocks the shift."}
        _training_flash(player.global_position + Vector3.UP, Color(0.62, 0.75, 1.0))
        player.global_position = target
        player.velocity.x = 0.0
        player.velocity.z = 0.0
        _training_flash(player.global_position + Vector3.UP, Color(0.62, 0.75, 1.0))
        return {"ok": true, "message": "Moved 3 m within the courtyard."}
    var range_now: float = 3.2
    if spoke == "Elemental":
        range_now = 8.0
    elif spoke == "Psychic":
        range_now = 7.0
    elif spoke == "Abyssal":
        range_now = 3.6
    var target_fighter: CharacterBody3D = _training_target(forward, range_now)
    if not is_instance_valid(target_fighter):
        return {"ok": false, "message": "Face a live sparring construct in range."}
    if spoke == "Psychic":
        target_fighter.call("apply_psychic_disruption", 2.5)
        _training_flash(target_fighter.global_position + Vector3.UP * 1.4, Color(0.76, 0.52, 1.0))
        return {"ok": true, "message": "Interrupted a construct for 2.5 s."}
    var damage: int = 22
    var color: Color = Color(0.34, 0.77, 1.0)
    if spoke == "Elemental":
        damage = 16
        color = Color(1.0, 0.47, 0.22)
    elif spoke == "Abyssal":
        damage = 30
        color = Color(0.42, 0.20, 0.60)
    elif spoke != "Martial":
        return {"ok": false, "message": "Unknown training technique."}
    var connected: bool = bool(target_fighter.call("take_strike", damage, player.global_position))
    if not connected:
        return {"ok": false, "message": "Construct could not be hit."}
    _training_flash(target_fighter.global_position + Vector3.UP * 1.3, color)
    if spoke == "Abyssal":
        player_health = maxi(1, player_health - 7)
        _refresh_hud()
        return {"ok": true, "message": "Heavy impact, 7 HP strain."}
    return {"ok": true, "message": "Hit the construct for up to %d damage." % damage}

func _training_flash(at: Vector3, color: Color) -> void:
    var marker := MeshInstance3D.new()
    marker.name = "SpokePracticeFlash"
    var sphere := SphereMesh.new()
    sphere.radius = 0.30
    sphere.height = 0.60
    marker.mesh = sphere
    var glow := StandardMaterial3D.new()
    glow.albedo_color = color
    glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    marker.material_override = glow
    marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(marker)
    marker.global_position = at
    marker.scale = Vector3(0.3, 0.3, 0.3)
    var pulse := create_tween()
    pulse.tween_property(marker, "scale", Vector3(2.1, 2.1, 2.1), 0.24)
    pulse.tween_callback(marker.queue_free)


func _receive_enemy_attack(amount: int) -> void:
    if ko_timer > 0.0 or not is_instance_valid(player):
        return
    # A successful ground dodge briefly avoids the telegraphed hit.
    if float(player.get("dodge_time")) > 0.0:
        _announce("DODGED! Counterattack with STRIKE.", 1.4)
        return
    if hurt_grace > 0.0:
        return
    if alchemy_shield_time > 0.0:
        alchemy_shield_time = 0.0
        _announce("ALCHEMY: your temporary ward absorbed a sparring hit.", 2.0)
        return
    # Newly raised guard grants a short physical reflex-parry. This is
    # not player Kyōmei-shi mastery: Sight requires mentor/story permission.
    if player_posture_break_time <= 0.0 and Posture.parry(float(player.get("parry_age")),
            bool(player.get("guard_active"))):
        var hub_parry: Node = get_tree().get_first_node_in_group("hub_manager")
        if is_instance_valid(hub_parry) and float(hub_parry.get("stamina")) >= 5.0:
            hub_parry.set("stamina", maxf(0.0, float(hub_parry.get("stamina")) - 5.0))
            player.set("parry_age", 999.0)
            player_posture = minf(Posture.MAX_POSTURE, player_posture + 14.0)
            perfect_parry_count += 1
            var source: CharacterBody3D = null
            var nearest: float = 3.6
            for enemy in enemies + field_enemies:
                if not is_instance_valid(enemy) or not bool(enemy.call("is_active")):
                    continue
                var distance: float = enemy.global_position.distance_to(player.global_position)
                if distance < nearest:
                    nearest = distance
                    source = enemy
            if is_instance_valid(source) and source.has_method("receive_posture_damage"):
                source.call("receive_posture_damage", 33.0, player.global_position)
            _announce("PERFECT PARRY! +14 posture; enemy guard pressured.", 1.7)
            _refresh_hud()
            return
    var seal_table: Node = get_tree().get_first_node_in_group("v069_public_seals")
    if is_instance_valid(seal_table) and seal_table.has_method("on_impact"):
        if bool(seal_table.call("on_impact", amount)):
            _announce("ALCHEMIC SEAL: your encoded ward absorbed one hit.", 2.0)
            return
    var guarded: bool = false
    if player_posture_break_time <= 0.0 and bool(player.get("guard_active")):
        var hub: Node = get_tree().get_first_node_in_group("hub_manager")
        if is_instance_valid(hub) and hub.has_method("spend_guard_stamina"):
            guarded = bool(hub.call("spend_guard_stamina"))
    var final_damage: int = maxi(1, int(round(float(amount) * 0.30))) if guarded else amount
    var pressure: Dictionary = Posture.posture_hit(player_posture, float(amount) * 1.65, guarded)
    if bool(pressure.get("valid", false)):
        player_posture = float(pressure.get("remaining", player_posture))
        if bool(pressure.get("break", false)):
            player_posture_break_time = 1.5
            guarded = false
            final_damage = amount
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
    player_posture = Posture.MAX_POSTURE
    player_posture_break_time = 0.0
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
    posture_notice = Label.new()
    posture_notice.name = "V069PhysicalPostureHud"
    posture_notice.add_theme_font_size_override("font_size", 17)
    posture_notice.offset_left = 22.0
    posture_notice.offset_top = 181.0
    posture_notice.offset_right = 470.0
    posture_notice.offset_bottom = 206.0
    posture_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(posture_notice)
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

func _spawn_strike_burst(at_position: Vector3, impact_ticks: int) -> void:
    if strike_burst_mesh == null:
        strike_burst_mesh = _build_strike_burst_mesh()
    var burst := MeshInstance3D.new()
    burst.name = "MartialImpact"
    burst.mesh = strike_burst_mesh
    burst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(burst)
    burst.global_position = at_position
    burst.scale = Vector3.ONE * (0.70 + 0.07 * impact_ticks)
    var effect := burst.create_tween()
    effect.tween_interval(float(impact_ticks) / Engine.physics_ticks_per_second)
    effect.tween_property(burst, "scale", burst.scale * 1.4, 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    effect.tween_property(burst, "scale", Vector3.ZERO, 0.075)
    effect.tween_callback(burst.queue_free)


func _build_strike_burst_mesh() -> ArrayMesh:
    # One unlit, camera-facing drawing for every connected strike.
    var lines := SurfaceTool.new()
    lines.begin(Mesh.PRIMITIVE_TRIANGLES)
    for index in range(9):
        var angle: float = index * TAU / 9.0 + 0.24
        var ray := Vector3(cos(angle), sin(angle), 0.0)
        var edge := Vector3(-ray.y, ray.x, 0.0) * (0.11 if index % 2 == 0 else 0.075)
        var tip: Vector3 = ray * (0.94 if index % 2 == 0 else 0.62)
        var root: Vector3 = ray * 0.075
        var joint: Vector3 = ray * 0.27
        for point in [root, joint + edge, tip, root, tip, joint - edge]:
            lines.set_color(Color("#3F294A"))
            lines.add_vertex(point)
        for point in [root, joint + edge * 0.66, tip * 0.91, root, tip * 0.91, joint - edge * 0.66]:
            lines.set_color(Color("#FFF0C8") if index % 2 == 0 else Color("#FFE0A0"))
            lines.add_vertex(point + Vector3.BACK * 0.004)
    var material := StandardMaterial3D.new()
    material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    material.billboard_keep_scale = true
    material.vertex_color_use_as_albedo = true
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    lines.set_material(material)
    return lines.commit()

func _refresh_hud() -> void:
    if is_instance_valid(player_health_bar):
        player_health_bar.value = player_health
    if is_instance_valid(player_health_text):
        player_health_text.text = "HEALTH  %d / %d   |   V0.69 GUARD" % [player_health, PLAYER_MAX_HEALTH]
    if is_instance_valid(posture_notice):
        posture_notice.text = "POSTURE %d/100 | PARRY: raise GUARD near impact" % int(player_posture)
        if player_posture_break_time > 0.0:
            posture_notice.text = "POSTURE BROKEN | recover %.1fs" % player_posture_break_time
    if is_instance_valid(combat_notice) and combat_notice_timer <= 0.0:
        combat_notice.text = ""
