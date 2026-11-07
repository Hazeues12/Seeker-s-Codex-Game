extends Node3D
const Main = preload("res://scenes/main.tscn")
const Rules = preload("res://systems/character_population_rules_v065.gd")

func _ready() -> void:
    call_deferred("_check")

func _fail(reason: String) -> void:
    push_error("V0.65 LIVING WORLD FAILED: " + reason)
    get_tree().call_deferred("quit", 1)

func _check() -> void:
    var world: Node3D = Main.instantiate() as Node3D
    add_child(world)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    var population: Node = world.get_node_or_null("MagnaraPopulationV065")
    var hub: Node = world.get_node_or_null("HubManager")
    var codex: Node = world.get_node_or_null("PersonalCodex")
    var player: CharacterBody3D = world.get_node_or_null("Player") as CharacterBody3D
    if population == null or hub == null or codex == null or player == null:
        _fail("full live project lacks player, hub, Personal Codex or population")
        return
    if not bool(population.get("initialized")):
        _fail("population didn't initialize from registry")
        return
    for prior in ["MagnaraCivicV064","MagnaraMarketsV062","MagnaraWorkshopsV061","MagnaraResidentialV060","MagnaraGeographyV054"]:
        if world.get_node_or_null(prior) == null:
            _fail("population removed existing world system " + prior)
            return
    var manifest: Dictionary = population.call("get_manifest")
    if int(manifest.get("canon_registry", 0)) < 64 or int(manifest.get("civilian_registry", 0)) < 22 or int(manifest.get("physical_npcs", 0)) < 28:
        _fail("real characters or resident agents not instantiated")
        return
    for key in ["V065LinkedGuildStreet","V065GuildCrossStreet","V065PedestrianWalk","TalkingBoarPublicEntryWalk"]:
        var street: Node = population.find_child(key, true, false)
        if street == null or street.find_child("PopulationV065Collision", true, false) == null:
            _fail("new streets aren't collidable and traversable: " + key)
            return
    var boar: Node = population.get_node_or_null("TalkingBoarV065")
    if boar == null:
        _fail("Crescent Halo public home was omitted from Magnara")
        return
    for name in ["TalkingBoarActualFloor","TalkingBoarOpenDoorLintel","TalkingBoarSolidRoof","TalkingBoarBarCounter","TalkingBoarDispatchDesk"]:
        var detail: Node = boar.find_child(name, true, false)
        if detail == null or detail.find_child("PopulationV065Collision", true, false) == null:
            _fail("Talking Boar has fake geometry or sealed entry: " + name)
            return
    await get_tree().physics_frame
    for at in [Vector3(0, 5, 505),Vector3(0, 5, 540),Vector3(-62, 5, 548),Vector3(62, 5, 559),Vector3(-30, 5, 555)]:
        var ray := PhysicsRayQueryParameters3D.create(at, at + Vector3(0, -8, 0))
        if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
            _fail("bridge to public guild hall has no collision at " + str(at))
            return
    var actors: Dictionary = population.get("actors")
    if actors.has("rin_kairo") or actors.has("seizen_kairo") or actors.has("chief_inspector_nezubunta") or actors.has("yobokari_morningstar"):
        _fail("covert and sealed characters became random pedestrians")
        return
    for named in ["william_lockhart","hanami","ven","kai_xander","aria_flamehart","lila_butters"]:
        if not actors.has(named):
            _fail("public cast not staged in legitimate trial-week city: " + named)
            return
    hub.set("world_minutes", 540.0)
    player.global_position = Vector3(-30, 1.0, 553.0)
    population.call("_tick")
    if not actors["william_lockhart"].visible or not actors["hanami"].visible or not actors["ven"].visible:
        _fail("guild hall doesn't actually staff itself at morning hours")
        return
    if actors["lila_butters"].visible:
        _fail("offstage family and training time is ignored")
        return
    var spots: Dictionary = {}
    for spot in hub.get("locations"):
        var id: String = str(spot.get("id", ""))
        if id.begins_with("npc_v065_"):
            spots[id] = spot
    if spots.size() != actors.size():
        _fail("all character models must have mobile TALK / USE interaction")
        return
    var npc: Node3D = actors["william_lockhart"]
    player.global_position = npc.global_position + Vector3(0, 0.7, 0)
    var closest: Dictionary = hub.call("_nearest_location")
    if str(closest.get("id", "")) != "npc_v065_william_lockhart":
        _fail("William's 3D model can't be approached as an individual")
        return
    hub.call("_interact")
    if not bool(population.call("is_open")) or not bool(hub.call("_any_panel_open")):
        _fail("direct NPC talk didn't open mobile-safe dialogue")
        return
    population.call("_choose", "listen")
    var profile: Dictionary = codex.get("profile")
    if Rules.rapport(profile.get("population_v065", {}), "william_lockhart") != 1:
        _fail("William's encounter isn't remembered")
        return
    population.call("_choose", "help")
    if Rules.rapport(codex.get("profile").get("population_v065", {}), "william_lockhart") != 1:
        _fail("same character can be farmed twice on one day")
        return
    population.call("_close")
    player.global_position = Vector3(-26, 1.0, 293.0)
    hub.set("world_minutes", 540.0)
    population.call("_tick")
    var sample: Node3D = actors["citizen_v065_01"]
    if not sample.visible:
        _fail("nearby civilian does not come out to work on a schedule")
        return
    player.global_position = sample.global_position + Vector3(0, 0.7, 0)
    population.call("_tick")
    closest = hub.call("_nearest_location")
    if str(closest.get("id", "")) != "npc_v065_citizen_v065_01":
        _fail("ordinary residents don't respond to their own proximity")
        return
    hub.call("_interact")
    if not bool(population.call("is_open")):
        _fail("civilian daily-life conversation fails")
        return
    population.call("_choose", "help")
    if Rules.rapport(codex.get("profile").get("population_v065", {}), "citizen_v065_01") != 2:
        _fail("regular civilian help is not a persistent event")
        return
    population.call("_close")
    codex.call("_load_profile")
    if Rules.rapport(codex.get("profile").get("population_v065", {}), "citizen_v065_01") != 2:
        _fail("individual NPC memory doesn't survive real disk reload")
        return
    hub.set("world_minutes", 1350.0)
    population.call("_tick")
    if actors["william_lockhart"].visible:
        _fail("William works all night instead of respecting his private rest")
        return
    player.global_position = Vector3(-30, 1, 555)
    hub.set("world_minutes", 570.0)
    population.call("_tick")
    if not actors["ven"].visible:
        _fail("Forgehouse associate missed actual morning guild presence")
        return
    hub.set("world_minutes", 720.0)
    population.call("_tick")
    if actors["ven"].visible:
        _fail("Ven is duplicated onstage while working elsewhere")
        return
    print("V0.65 PHYSICAL TALKING BOAR 28 MOVING NPCS PUBLIC SQUAD GUILD SCHEDULE MEMORY PASS")
    world.queue_free()
    get_tree().call_deferred("quit", 0)
