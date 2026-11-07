extends Node3D
const Main = preload("res://scenes/main.tscn")
const Player = preload("res://characters/player_controller.gd")
const Arena = preload("res://combat/combat_arena.gd")
const Construct = preload("res://combat/sparring_construct.gd")
const Rig = preload("res://characters/procedural_seeker.gd")
const STEP := 1.0 / 60.0
const PASS := "V0.86 REAL-TIME STRIKE HIT-STOP KNOCKBACK AND DODGE PASS"

func _ready() -> void:
    call_deferred("_run")

func _check(ok: bool, reason: String) -> bool:
    if not ok:
        push_error("V0.86 REAL-TIME IMPACT: " + reason)
        get_tree().call_deferred("quit", 1)
    return ok

func _run() -> void:
    var game := Main.instantiate() as Node3D
    add_child(game)
    for frame in range(8):
        await get_tree().process_frame
    var player := game.get_node("Player") as Player
    var arena := game.get_node("CombatArena") as Arena
    var foe := arena.enemies[0] as Construct
    var mobile := game.get_node("MobileUI/MobileControls")
    var strike := mobile.get_node("AttackButton") as Button
    var dodge := mobile.get_node("DodgeButton") as Button
    var hub := game.get_node("HubManager")
    player.set_physics_process(false)
    foe.set_physics_process(false)
    await get_tree().physics_frame

    strike.pressed.emit()
    player._physics_process(STEP)
    if not _check(player.hit_stop_ticks == 0 and arena.strike_burst_mesh == null,
            "a missed strike started the impact effect"):
        return

    foe.reset_construct()
    player.global_position = foe.global_position + Vector3(0.0, 0.0, 2.55)
    player.velocity = Vector3.ZERO
    player.attack_cooldown = 0.0
    hub.set("aura", 100.0)
    strike.pressed.emit()
    player._physics_process(STEP)
    var burst := arena.get_node_or_null("MartialImpact") as MeshInstance3D
    if not _check(foe.health == 46 and is_equal_approx(float(hub.get("aura")), 88.0)
            and player.hit_stop_ticks == 3 and foe.hit_stop_ticks == 4 and burst != null
            and burst.mesh is ArrayMesh and player.camera_node.h_offset > 0.0,
            "the mobile Strike input failed to spend once, deal damage or trigger the impact"):
        return
    var hero_position: Vector3 = player.global_position
    var foe_position: Vector3 = foe.global_position
    mobile.set("movement", Vector2.RIGHT)
    for tick in range(4):
        if tick < 3:
            player._physics_process(STEP)
        foe._physics_process(STEP)
    if not _check(player.global_position.is_equal_approx(hero_position)
            and foe.global_position.is_equal_approx(foe_position) and foe.health == 46,
            "the fighters moved or the hit registered twice during the held pose"):
        return
    player._physics_process(STEP)
    foe._physics_process(STEP)
    if not _check(player.global_position.x > hero_position.x and foe.global_position.z < foe_position.z,
            "the held movement and knockback did not resume after the impact"):
        return

    mobile.call("release_controls")
    player.global_position = foe.global_position + Vector3(0.0, 0.0, 1.60)
    player.velocity = Vector3.ZERO
    for frame in range(8):
        player._physics_process(STEP)
    foe.state = "windup"
    foe.state_timer = 0.5
    foe._physics_process(STEP)
    var rig := foe.visual_rig as Rig
    if not _check(rig.anime_style and is_equal_approx(rig.right_arm.rotation.x, -0.48)
            and foe.aura_material.albedo_color == Color("#FFC23A"),
            "the live construct did not show its gold windup pose"):
        return
    dodge.pressed.emit()
    player._physics_process(STEP)
    foe.state_timer = 0.001
    foe._physics_process(STEP)
    if not _check(player.dodge_time > 0.0 and arena.player_health == Arena.PLAYER_MAX_HEALTH
            and arena.combat_notice.text.begins_with("DODGED!"),
            "the mobile Dodge input did not evade the real-time strike"):
        return

    await get_tree().create_timer(0.45).timeout
    if not _check(not is_instance_valid(burst) and is_zero_approx(player.camera_node.h_offset),
            "the effect or camera offset lingered after the impact"):
        return
    print(PASS)
    get_tree().call_deferred("quit", 0)
