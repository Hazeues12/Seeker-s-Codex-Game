extends Node3D
const Main = preload("res://scenes/main.tscn")
const Seals = preload("res://systems/alchemic_seal_rules_v069.gd")
const Guild = preload("res://systems/guild_public_director_v069.gd")
const Posture = preload("res://combat/triad_posture_rules_v069.gd")
const Integrity = preload("res://systems/game_save_integrity_v063.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("V0.69 REAL WORLD WILL SEALS ROOFTOPS FAILED: " + message)
    get_tree().call_deferred("quit",1)

func _run() -> void:
    var game: Node3D = Main.instantiate() as Node3D
    add_child(game)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    var rooftops: Node3D = game.get_node_or_null("MagnaraLegacyRoofwaysV069") as Node3D
    var workbench: Node = game.get_node_or_null("SealTrainingBenchV069")
    var guild: Node = game.get_node_or_null("PublicGuildDirectorV069")
    var player: CharacterBody3D = game.get_node_or_null("Player") as CharacterBody3D
    var arena: Node = game.get_node_or_null("CombatArena")
    var hub: Node = game.get_node_or_null("HubManager")
    var codex: Node = game.get_node_or_null("PersonalCodex")
    if not is_instance_valid(rooftops) or not is_instance_valid(workbench) or not is_instance_valid(guild) or not is_instance_valid(player) or not is_instance_valid(arena) or not is_instance_valid(hub) or not is_instance_valid(codex):
        _fail("scene failed to mount all three V0.69 modules in original 3D game")
        return
    if not bool(workbench.get("initialized")) or not bool(guild.get("initialized")) or not bool(rooftops.get("built")):
        _fail("game scene module initialization didn't produce usable content")
        return
    for old in ["MagnaraStreamedBlocksV067","MagnaraPopulationV065","MagnaraBusinessesV066","MagnaraPublicPulseV068","MagnaraCivicV064","MagnaraMarketsV062"]:
        if game.get_node_or_null(old) == null:
            _fail("previous city and canon models were removed: "+old)
            return
    var parts: Dictionary = rooftops.get_manifest()
    if int(parts.get("legacy_venues_with_roof_access",0)) != 4 or int(parts.get("real_colliders",0)) != 48:
        _fail("four established buildings need real roof access/catwalk physics")
        return
    for name in ["talking_boar","lebells","avicci","vernal_divongcci"]:
        for n in range(8):
            var block: Node = rooftops.get_node_or_null("V069Access_%s_%d" % [name,n])
            if block == null or block.get_node_or_null("V069LegacyRoofCollision") == null:
                _fail("old building cannot be climbed on a real step: "+name)
                return
            if float(block.get_meta("rise_from_previous",-1)) > 1.05:
                _fail("rooftop stair rise exceeds physical jump affordance")
                return
    for n in range(16):
        if rooftops.get_node_or_null("V069PublicRoofCatwalk_%02d" % n) == null:
            _fail("Le'Bell's to Vernal overhead connection is not solid")
            return
    # Physics-backed landing at the Talking Boar, no fake roof mesh.
    player.global_position = Vector3(-30.0,7.0,555.0)
    await get_tree().physics_frame
    var ray := PhysicsRayQueryParameters3D.create(Vector3(-30,8,555),Vector3(-30,4,555))
    ray.exclude = [player.get_rid()]
    if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
        _fail("Crescent Halo real public roof has no landing collider")
        return
    var catwalk: Node3D = rooftops.get_node("V069PublicRoofCatwalk_07")
    player.global_position = catwalk.global_position + Vector3(0,1.5,0)
    await get_tree().physics_frame
    ray = PhysicsRayQueryParameters3D.create(catwalk.global_position + Vector3(0,2.0,0),
        catwalk.global_position - Vector3(0,2.0,0))
    ray.exclude = [player.get_rid()]
    var rayhit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray)
    if rayhit.is_empty() or not (rayhit.get("collider") as Node).is_in_group("v069_public_roof_parkour"):
        _fail("new intershop roof catwalk not physically landable")
        return

    # Physical timing and pressure run through existing live sparring AI.
    var enemies: Array = arena.get("enemies")
    if enemies.size() < 2:
        _fail("old training constructs disappeared")
        return
    var defender: CharacterBody3D = enemies[0]
    var previous_posture: float = float(defender.get("posture"))
    player.global_position = defender.global_position + Vector3(0,0.5,1.4)
    player.set("dodge_time",0.0)
    player.set("guard_active",true)
    player.set("parry_age",0.04)
    arena.set("hurt_grace",0.0)
    var hp: int = int(arena.get("player_health"))
    arena.call("_receive_enemy_attack",14)
    if int(arena.get("player_health")) != hp or int(arena.get("perfect_parry_count")) < 1:
        _fail("timed GUARD didn't parry real construct hit")
        return
    if float(defender.get("posture")) >= previous_posture:
        _fail("perfect parry didn't destabilize the near sparring opponent")
        return
    player.set("parry_age",99.0)
    arena.set("hurt_grace",0.0)
    var previous_balance: float = float(arena.get("player_posture"))
    arena.call("_receive_enemy_attack",14)
    if float(arena.get("player_posture")) >= previous_balance or int(arena.get("player_health")) >= hp:
        _fail("ordinary sustained guard has neither posture nor damage consequence")
        return
    if not is_instance_valid(arena.get("posture_notice")):
        _fail("player cannot see posture and parry timing in mobile HUD")
        return
    player.set("guard_active",false)
    arena.set("hurt_grace",0.0)
    defender.call("receive_posture_damage",300.0,player.global_position)
    if float(defender.get("posture")) != 0.0 or float(defender.get("posture_break_time")) <= 0.0:
        _fail("enemy guard cannot be broken by repeated physical pressure")
        return

    # Build, arm and fire a strict 3-rune training ward into REAL combat.
    player.global_position = Vector3(11.7,0.8,-24.2)
    if str(hub.call("_nearest_location").get("id","")) != "seal_v069_practice":
        _fail("rune table not reachable by mobile TALK / USE")
        return
    hub.call("_interact")
    if not bool(workbench.call("is_open")) or not bool(hub.call("_any_panel_open")):
        _fail("touchscreen seal editor did not open")
        return
    workbench.call("_choose","impact")
    workbench.call("_choose","ward")
    workbench.call("_choose","arm")
    if not bool(Seals.sanitize(codex.get("profile").get("seals_v069",{}).get("recipe",{})).get("armed",false)):
        _fail("encoded rune formula not saved as armed to real Personal Codex")
        return
    workbench.call("_close")
    if bool(hub.call("_any_panel_open")):
        _fail("closing seal editor left movement locked")
        return
    hub.set("aura",80.0)
    player.set("parry_age",999.0)
    player.set("guard_active",false)
    arena.set("alchemy_shield_time",0.0)
    arena.set("hurt_grace",0.0)
    var before_hit: int = int(arena.get("player_health"))
    arena.call("_receive_enemy_attack",14)
    if int(arena.get("player_health")) != before_hit or not is_equal_approx(float(hub.get("aura")),62.0):
        _fail("live programmed one-hit ward didn't spend 18 Aura to stop real damage")
        return
    if not (Seals.ledger(codex.get("profile").get("seals_v069",{}).get("receipts",{}))).has("day:1"):
        _fail("on-impact seal receipt wasn't recorded and verified")
        return
    if int(arena.get("player_health")) != before_hit or workbench.call("on_impact",14):
        _fail("same-day seal ward could be fired twice without paying")
        return
    arena.set("hurt_grace",0.0)
    arena.call("_receive_enemy_attack",14)
    if int(arena.get("player_health")) >= before_hit:
        _fail("used seal still absorbed damage when it should have expired")
        return
    codex.call("_load_profile")
    var persisted: Dictionary = codex.get("profile")
    if not Seals.ledger(persisted.get("seals_v069",{}).get("receipts",{})).has("day:1"):
        _fail("aura ward is not persisted after relaunch")
        return

    # Real local public Association contracts: Stray can take only civic
    # observer route. Paid reward must be one-time in verified world save.
    player.global_position = Vector3(12.5,0.82,8.0)
    if str(hub.call("_nearest_location").get("id","")) != "guild_v069_board":
        _fail("actual Association public duty kiosk not on walking route")
        return
    hub.call("_interact")
    if not bool(guild.call("is_open")):
        _fail("public duty panel not playable on mobile")
        return
    if not Guild.rank_allows(GameState.seeker_rank,"shop_watch"):
        _fail("Stray cannot accept even public civic observation")
        return
    var starting_cash: int = GameState.tola
    var initial_rep: int = int(hub.get("guild_rep"))
    var payment: int = int(Guild.description("shop_watch",1,hub.get("shop_stock_v066")).get("reward_tola",0))
    guild.call("_accept","shop_watch")
    guild.call("_close")
    if str(Guild.sanitize(hub.get("guild_director_v069")).get("active","")) != "shop_watch":
        _fail("accepted public report didn't save to hub")
        return
    player.global_position = Guild.LOCATIONS[0]
    var nearest: Dictionary = hub.call("_nearest_location")
    if str(nearest.get("id","")) != "guild_v069_target_shop_watch":
        _fail("public assignment destination is not a real world interaction marker")
        return
    hub.call("_interact")
    if GameState.tola != starting_cash + payment or int(hub.get("guild_rep")) != initial_rep+1:
        _fail("verified public job didn't pay promised Tola and reputation once")
        return
    guild.call("_complete","shop_watch")
    if GameState.tola != starting_cash+payment:
        _fail("duplicate quest payout exploit")
        return
    var saved: Dictionary = Integrity.load_best().get("data",{})
    if int(saved.get("tola",-1)) != GameState.tola or not Guild.sanitize(saved.get("guild_director_v069",{})).get("receipts",{}).has("day:1:shop_watch"):
        _fail("public duty payout and receipt weren't atomic in verified save")
        return
    hub.set("guild_director_v069",{})
    hub.call("_load_game",false)
    if not Guild.sanitize(hub.get("guild_director_v069")).get("receipts",{}).has("day:1:shop_watch"):
        _fail("public Seeker Association ledger vanished after save reload")
        return
    if game.get_node_or_null("MagnaraStreamedBlocksV067") == null:
        _fail("older modular city was damaged by new four-layer world simulation")
        return
    print("V0.69 REAL GUARD PARRY PHYSICAL ROOFWAYS PROGRAMMABLE WARD AND VERIFIED GUILD PAYOUT PASS")
    game.queue_free()
    get_tree().call_deferred("quit",0)
