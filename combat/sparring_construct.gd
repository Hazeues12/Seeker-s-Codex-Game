extends CharacterBody3D

# V0.35: Lightweight physical sparring enemy. No pathfinding or lore-specific identity.
signal attack_connected(damage: int)
signal knocked_out

const MAX_HEALTH: int = 64
const PATROL_SPEED: float = 1.35
const CHASE_SPEED: float = 3.10
const AGGRO_RANGE: float = 9.0
const LEASH_RANGE: float = 12.0
const STRIKE_RANGE: float = 2.15

var target_player: CharacterBody3D
var spawn_point: Vector3
var display_name: String = "Sparring Construct"
var health: int = MAX_HEALTH
var active: bool = true
var state: String = "patrol"
var state_timer: float = 0.0
var life_time: float = 0.0
var patrol_phase: float = 0.0
var model: MeshInstance3D
var model_mat: StandardMaterial3D
var status_tag: Label3D

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
    model_mat.roughness = 0.75
    model.material_override = model_mat
    add_child(model)

    var chest := MeshInstance3D.new()
    chest.name = "AuraCore"
    var core := SphereMesh.new()
    core.radius = 0.15
    core.height = 0.30
    chest.mesh = core
    chest.position = Vector3(0.0, 1.24, -0.36)
    var core_mat := StandardMaterial3D.new()
    core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    core_mat.albedo_color = Color(0.54, 0.94, 1.0)
    chest.material_override = core_mat
    add_child(chest)

    status_tag = Label3D.new()
    status_tag.name = "EnemyHealthTag"
    status_tag.position = Vector3(0.0, 2.45, 0.0)
    status_tag.font_size = 32
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
    _update_label()

func is_active() -> bool:
    return active

func _physics_process(delta: float) -> void:
    if not active or not is_instance_valid(target_player):
        return
    life_time += delta
    state_timer = maxf(0.0, state_timer - delta)
    var toward: Vector3 = target_player.global_position - global_position
    toward.y = 0.0
    var distance: float = toward.length()
    match state:
        "patrol":
            if distance <= AGGRO_RANGE:
                state = "chase"
            else:
                var waypoint := spawn_point + Vector3(sin(life_time * 0.52 + patrol_phase) * 1.6, 0.0, cos(life_time * 0.52 + patrol_phase) * 1.1)
                _walk_toward(waypoint, PATROL_SPEED, delta)
        "chase":
            if distance > LEASH_RANGE:
                state = "patrol"
            elif distance <= STRIKE_RANGE:
                state = "windup"
                state_timer = 0.68
                velocity.x = 0.0
                velocity.z = 0.0
            else:
                _walk_toward(target_player.global_position, CHASE_SPEED, delta)
        "windup":
            velocity.x = 0.0
            velocity.z = 0.0
            if state_timer <= 0.0:
                # Evaluate distance after the telegraph, so retreating and dodging work.
                if distance <= STRIKE_RANGE + 0.30:
                    attack_connected.emit(12)
                state = "recovery"
                state_timer = 1.25
        "recovery":
            velocity.x = 0.0
            velocity.z = 0.0
            if state_timer <= 0.0:
                state = "chase"
        "stagger":
            velocity.x = move_toward(velocity.x, 0.0, 11.0 * delta)
            velocity.z = move_toward(velocity.z, 0.0, 11.0 * delta)
            if state_timer <= 0.0:
                state = "chase"
    if not is_on_floor():
        velocity.y -= 9.8 * delta
    else:
        velocity.y = 0.0
    move_and_slide()
    # Small bounded test yard: the original board and Hanami remain safe.
    global_position.x = clampf(global_position.x, -9.8, 9.8)
    global_position.z = clampf(global_position.z, -28.4, -16.5)
    if distance > 0.12:
        var look_point := Vector3(target_player.global_position.x, global_position.y, target_player.global_position.z)
        if global_position.distance_to(look_point) > 0.1:
            look_at(look_point, Vector3.UP)
    if state == "windup":
        model_mat.albedo_color = Color(1.0, 0.73, 0.17)
    elif state == "stagger":
        model_mat.albedo_color = Color(0.98, 0.95, 0.77)
    else:
        model_mat.albedo_color = Color(0.59, 0.37, 0.76)

func _walk_toward(destination: Vector3, speed: float, _delta: float) -> void:
    var vector: Vector3 = destination - global_position
    vector.y = 0.0
    if vector.length() < 0.25:
        velocity.x = 0.0
        velocity.z = 0.0
        return
    var step: Vector3 = vector.normalized() * speed
    velocity.x = step.x
    velocity.z = step.z

func take_strike(damage: int, attacker_position: Vector3) -> bool:
    if not active:
        return false
    health = maxi(0, health - damage)
    _update_label()
    if health <= 0:
        active = false
        state = "down"
        visible = false
        velocity = Vector3.ZERO
        knocked_out.emit()
    else:
        state = "stagger"
        state_timer = 0.32
        var push: Vector3 = global_position - attacker_position
        push.y = 0.0
        if push.length_squared() > 0.001:
            push = push.normalized() * 3.4
            velocity.x = push.x
            velocity.z = push.z
    return true

func reset_construct() -> void:
    health = MAX_HEALTH
    active = true
    state = "patrol"
    state_timer = 0.0
    velocity = Vector3.ZERO
    global_position = spawn_point
    visible = true
    _update_label()

func _update_label() -> void:
    if is_instance_valid(status_tag):
        status_tag.text = "%s   %d/%d HP" % [display_name, health, MAX_HEALTH]
