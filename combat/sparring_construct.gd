extends CharacterBody3D

# V0.36 procedural sparring AI. Keeps the V0.35 arena signal/API contract.
signal attack_connected(damage: int)
signal knocked_out

const MAX_HEALTH: int = 64
const AGGRO_RANGE: float = 9.0
const LEASH_RANGE: float = 12.0
const STRIKE_RANGE: float = 2.15

var target_player: CharacterBody3D
var spawn_point: Vector3
var display_name: String = "Sparring Construct"
var style: String = "guardian"
var health: int = MAX_HEALTH
var active: bool = true
var state: String = "patrol"
var state_timer: float = 0.0
var life_time: float = 0.0
var patrol_phase: float = 0.0
var guard_cooldown: float = 0.0
var flank_cooldown: float = 1.4
var model: MeshInstance3D
var model_mat: StandardMaterial3D
var status_tag: Label3D
var aura_core: MeshInstance3D

func _ready() -> void:
    var shape := CapsuleShape3D.new()
    shape.radius = 0.40
    shape.height = 1.8
    var collision := CollisionShape3D.new()
    collision.name = "CombatCollider"
    collision.shape = shape
    collision.position = Vector3(0.0, 0.90, 0.0)
    add_child(collision)

    model = MeshInstance3D.new()
    model.name = "ConstructModel"
    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.39
    body_mesh.height = 1.75
    model.mesh = body_mesh
    model.position.y = 0.90
    model_mat = StandardMaterial3D.new()
    model_mat.albedo_color = Color(0.59, 0.37, 0.76)
    model_mat.roughness = 0.72
    model.material_override = model_mat
    add_child(model)

    aura_core = MeshInstance3D.new()
    aura_core.name = "AuraCore"
    var core := SphereMesh.new()
    core.radius = 0.16
    core.height = 0.32
    aura_core.mesh = core
    aura_core.position = Vector3(0.0, 1.28, -0.37)
    var core_mat := StandardMaterial3D.new()
    core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    core_mat.albedo_color = Color(0.55, 0.94, 1.0)
    aura_core.material_override = core_mat
    add_child(aura_core)

    # Three-dimensional identifying silhouettes without a skeleton or asset downloads.
    var head := MeshInstance3D.new()
    head.name = "Mask"
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.25
    head_mesh.height = 0.50
    head.mesh = head_mesh
    head.position = Vector3(0.0, 1.92, 0.0)
    var mask_mat := StandardMaterial3D.new()
    mask_mat.albedo_color = Color(0.23, 0.29, 0.43)
    head.material_override = mask_mat
    add_child(head)

    status_tag = Label3D.new()
    status_tag.name = "EnemyHealthTag"
    status_tag.position = Vector3(0.0, 2.53, 0.0)
    status_tag.font_size = 31
    status_tag.pixel_size = 0.0055
    status_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    status_tag.no_depth_test = true
    add_child(status_tag)
    _update_label()

func configure(player: CharacterBody3D, label_text: String, where: Vector3, phase: float) -> void:
    target_player = player
    display_name = label_text
    spawn_point = where
    global_position = where
    patrol_phase = phase
    style = "skirmisher" if phase > 1.0 else "guardian"
    if is_instance_valid(model_mat):
        model_mat.albedo_color = _base_color()
    _update_label()

func is_active() -> bool:
    return active

func _physics_process(delta: float) -> void:
    if not active or not is_instance_valid(target_player):
        return
    life_time += delta
    state_timer = maxf(0.0, state_timer - delta)
    guard_cooldown = maxf(0.0, guard_cooldown - delta)
    flank_cooldown = maxf(0.0, flank_cooldown - delta)
    var toward: Vector3 = target_player.global_position - global_position
    toward.y = 0.0
    var distance: float = toward.length()

    match state:
        "patrol":
            if distance <= AGGRO_RANGE:
                state = "chase"
            else:
                var waypoint := spawn_point + Vector3(sin(life_time * 0.52 + patrol_phase) * 1.5, 0.0, cos(life_time * 0.52 + patrol_phase) * 1.0)
                _walk_toward(waypoint, 1.25)
        "chase":
            if distance > LEASH_RANGE:
                state = "patrol"
            elif style == "guardian" and guard_cooldown <= 0.0 and health < 42 and distance < 3.6:
                state = "guard"
                state_timer = 0.78
                guard_cooldown = 4.0
                velocity.x = 0.0
                velocity.z = 0.0
            elif style == "skirmisher" and flank_cooldown <= 0.0 and distance < 6.5 and distance > 2.0:
                state = "flank"
                state_timer = 0.83
                flank_cooldown = 4.1
            elif distance <= STRIKE_RANGE:
                state = "windup"
                state_timer = 0.78 if style == "guardian" else 0.51
                velocity.x = 0.0
                velocity.z = 0.0
            else:
                _walk_toward(target_player.global_position, 2.65 if style == "guardian" else 3.65)
        "flank":
            var side := Vector3(-toward.z, 0.0, toward.x).normalized()
            var side_goal: Vector3 = target_player.global_position + side * 2.6 - toward.normalized() * 0.8
            _walk_toward(side_goal, 3.3)
            if state_timer <= 0.0 or distance < 1.7:
                state = "chase"
        "guard":
            velocity.x = 0.0
            velocity.z = 0.0
            if state_timer <= 0.0:
                state = "chase"
        "windup":
            velocity.x = 0.0
            velocity.z = 0.0
            if state_timer <= 0.0:
                # Distance is checked at impact time, making retreat and dodges meaningful.
                if distance <= STRIKE_RANGE + 0.25:
                    attack_connected.emit(14 if style == "guardian" else 9)
                state = "recovery"
                state_timer = 1.35 if style == "guardian" else 0.95
        "recovery":
            velocity.x = 0.0
            velocity.z = 0.0
            if state_timer <= 0.0:
                state = "chase"
        "stagger":
            velocity.x = move_toward(velocity.x, 0.0, 10.5 * delta)
            velocity.z = move_toward(velocity.z, 0.0, 10.5 * delta)
            if state_timer <= 0.0:
                state = "chase"
    if not is_on_floor():
        velocity.y -= 9.8 * delta
    else:
        velocity.y = 0.0
    move_and_slide()
    # Keep the fight away from the original guild board, merchants and herbs.
    global_position.x = clampf(global_position.x, -9.8, 9.8)
    global_position.z = clampf(global_position.z, -28.4, -16.5)
    if distance > 0.12:
        var look_point := Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z)
        if global_position.distance_to(look_point) > 0.1:
            look_at(look_point, Vector3.UP)
    _animate_pose()

func _animate_pose() -> void:
    if not is_instance_valid(model):
        return
    var bob: float = sin(life_time * 8.0) * 0.025
    model.position.y = 0.90 + bob
    model.rotation.z = sin(life_time * 2.5) * 0.035
    if state == "windup":
        model.rotation.x = -0.25
        model_mat.albedo_color = Color(1.0, 0.64, 0.15)
    elif state == "guard":
        model.rotation.x = 0.10
        model_mat.albedo_color = Color(0.25, 0.87, 1.0)
    elif state == "stagger":
        model.rotation.x = 0.27
        model_mat.albedo_color = Color(1.0, 0.96, 0.73)
    else:
        model.rotation.x = 0.0
        model_mat.albedo_color = _base_color()
    aura_core.scale = Vector3.ONE * (1.0 + sin(life_time * 5.5) * 0.13)

func _base_color() -> Color:
    return Color(0.67, 0.36, 0.47) if style == "guardian" else Color(0.46, 0.36, 0.80)

func _walk_toward(destination: Vector3, speed: float) -> void:
    var vector: Vector3 = destination - global_position
    vector.y = 0.0
    if vector.length() < 0.24:
        velocity.x = 0.0
        velocity.z = 0.0
        return
    var step: Vector3 = vector.normalized() * speed
    velocity.x = step.x
    velocity.z = step.z

func take_strike(damage: int, attacker_position: Vector3) -> bool:
    if not active:
        return false
    var blocked: bool = state == "guard"
    var actual_damage: int = maxi(1, int(round(float(damage) * 0.35))) if blocked else damage
    health = maxi(0, health - actual_damage)
    _update_label()
    _damage_number(actual_damage, blocked)
    if health <= 0:
        active = false
        state = "down"
        visible = false
        velocity = Vector3.ZERO
        knocked_out.emit()
    else:
        state = "stagger"
        state_timer = 0.20 if blocked else 0.38
        var push: Vector3 = global_position - attacker_position
        push.y = 0.0
        if push.length_squared() > 0.001:
            push = push.normalized() * (1.4 if blocked else 4.2)
            velocity.x = push.x
            velocity.z = push.z
    return true

func _damage_number(amount: int, guarded: bool) -> void:
    var number := Label3D.new()
    number.text = "GUARD -%d" % amount if guarded else "-%d" % amount
    number.font_size = 56
    number.pixel_size = 0.006
    number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    number.no_depth_test = true
    number.modulate = Color(0.35, 0.94, 1.0) if guarded else Color(1.0, 0.82, 0.25)
    number.position = Vector3(0.0, 1.9, 0.0)
    add_child(number)
    var t := create_tween()
    t.tween_property(number, "position", Vector3(0.0, 2.75, 0.0), 0.43)
    t.tween_callback(number.queue_free)

func reset_construct() -> void:
    health = MAX_HEALTH
    active = true
    state = "patrol"
    state_timer = 0.0
    guard_cooldown = 1.2
    flank_cooldown = 1.4
    velocity = Vector3.ZERO
    global_position = spawn_point
    visible = true
    _update_label()

func _update_label() -> void:
    if is_instance_valid(status_tag):
        status_tag.text = "%s   %d/%d HP" % [display_name, health, MAX_HEALTH]
