extends Node3D
const Rules = preload("res://systems/character_population_rules_v065.gd")

func _ready() -> void:
    call_deferred("_check")

func _fail(reason: String) -> void:
    push_error("V0.65 CANON POPULATION RULES FAILED: " + reason)
    get_tree().call_deferred("quit", 1)

func _check() -> void:
    var all: Dictionary = Rules.load_registry()
    if not Rules.valid_roster(all):
        _fail("invalid public roster or unsafe civilian fields")
        return
    if (all.get("canon_cast", []) as Array).size() < 64 or (all.get("civilian_roster", []) as Array).size() < 22:
        _fail("characters or distinct civilian schedules missing")
        return
    var groups: Dictionary = {}
    for actor in all.get("canon_cast", []):
        groups[str(actor.get("squad_id", "none"))] = int(groups.get(str(actor.get("squad_id", "none")), 0)) + 1
        if str(actor.get("public_visibility", "public")) != "public" and Rules.can_ambient_spawn(actor):
            _fail("restricted or sealed character eligible for ambient street spawn")
            return
        if ["seizen_kairo", "yobokari_morningstar", "rin_kairo", "chief_inspector_nezubunta", "onzu_squad"].has(str(actor.get("id", ""))) and Rules.can_ambient_spawn(actor):
            _fail("high-level antagonist or covert summons leaked into city traffic")
            return
    if int(groups.get("squad_three", 0)) != 4 or int(groups.get("squad_one", 0)) != 4 or int(groups.get("squad_two", 0)) != 4 or int(groups.get("squad_four", 0)) != 4:
        _fail("published exam squad membership changed")
        return
    var aria: Dictionary = Rules.find_actor(all, "aria_flamehart")
    if str(aria.get("appearance", {}).get("hair", "")) != "light blonde":
        _fail("Aria canonical blonde hair lost")
        return
    if str(Rules.find_actor(all, "rin_kairo").get("spawn_policy", "")) != "scripted_only":
        _fail("Rin's active investigation became an ambient encounter")
        return
    var william: Dictionary = Rules.find_actor(all, "william_lockhart")
    if str(william.get("guild_id", "")) != "order_crescent_halo" or not (william.get("equipment", []) as Array).has("Juzuri Tsunegen"):
        _fail("William's actual guild or signature equipment changed")
        return
    if not Rules.can_ambient_spawn(william) or Rules.can_ambient_spawn(william, "historical_1486"):
        _fail("William is spawning outside his correct mainline scenario")
        return
    var venue_ids: Dictionary = {}
    for place in all.get("known_venues", []):
        venue_ids[str(place.get("id", ""))] = place
    for name in ["talking_boar","forgehouse","lebells","avicci","vernal_divongcci","flama_magnara","blade_magnara","terra_firma_magnara"]:
        if not venue_ids.has(name):
            _fail("online published named business or guild absent: " + name)
            return
    if str(venue_ids["avicci"].get("physical_prototype", "")) != "not_authored":
        _fail("unbuilt luxury shop falsely marked as built")
        return
    for civ in all.get("civilian_roster", []):
        if civ.has("rank") or civ.has("ocular_power") or civ.has("rare_muti"):
            _fail("random citizen inherited an unapproved special power")
            return
        if not Rules.can_ambient_spawn(civ):
            _fail("game-only resident cannot join the public street")
            return
        for t in [65.0, 480.0, 650.0, 880.0, 1180.0, 1350.0]:
            var state: Dictionary = Rules.state_for(civ, t)
            if state.is_empty() or str(state.get("activity", "")).is_empty():
                _fail("civilian schedule has unassigned hour")
                return
            if not Rules.POINTS.has(str(state.get("anchor", ""))):
                _fail("civilian schedule destination points outside known streets")
                return
    var current: Dictionary = Rules.state_for(william, 600.0)
    if str(current.get("activity", "")) != "guild_dispatch" or not bool(current.get("visible", false)):
        _fail("William's public mentor/guildmaster work loop missing")
        return
    var ven: Dictionary = Rules.find_actor(all, "ven")
    if bool(Rules.state_for(ven, 750.0).get("visible", true)):
        _fail("Ven should be offsite during Forgehouse hours; no phantom duplicate")
        return
    var civilians: Array = all.get("civilian_roster", [])
    var sample: Dictionary = civilians[0]
    var original: Dictionary = Rules.empty_relationships()
    var listen: Dictionary = Rules.apply_choice(original, str(sample.get("id", "")), "listen", 1)
    if Rules.rapport(listen, str(sample.get("id", ""))) != 1:
        _fail("social choice isn't attributed to correct person")
        return
    if not Rules.apply_choice(listen, str(sample.get("id", "")), "help", 1).is_empty():
        _fail("daily NPC rapport can be endlessly farmed")
        return
    var next: Dictionary = Rules.apply_choice(listen, str(sample.get("id", "")), "dismiss", 2)
    if Rules.rapport(next, str(sample.get("id", ""))) != -1:
        _fail("negative social interaction isn't remembered")
        return
    var source: Dictionary = Rules.sanitize_relationships({
        "actors":{"citizen_v065_01":{"rapport":555,"days":{"day:1":"help","day:-1":"listen","day:2":"mind_control"}},
            "seizen_kairo":{"rapport":10000, "days":{"day:1":"help"}}}
    })
    if Rules.rapport(source, "citizen_v065_01") != 10 or (source.get("actors", {}) as Dictionary).has("seizen_kairo"):
        _fail("forged hidden-actor reputation or impossible score was accepted")
        return
    var path: Array[Vector3] = Rules.street_path("worker_row", "clinic_public")
    if path.size() < 4 or not Rules.path_position("worker_row", "clinic_public", 0.0).is_equal_approx(Rules.at_anchor("worker_row")) or not Rules.path_position("worker_row", "clinic_public", 1.0).is_equal_approx(Rules.at_anchor("clinic_public")):
        _fail("public pedestrian routing cannot follow authored road spines")
        return
    if str(Rules.find_actor(all, "sir_edward_lancaster").get("timeframe", "")) == "1500 A.S. mainline":
        _fail("historical Sagas knight placed alive on current street")
        return
    print("V0.65 64 CANON CHARACTERS 22 CIVILIANS VERIFIED SQUADS GUILDS SCHEDULES SPOILER LOCKS PASS")
    get_tree().call_deferred("quit", 0)
