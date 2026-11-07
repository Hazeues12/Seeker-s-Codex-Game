extends Node3D
const Parkour = preload("res://systems/aura_parkour_rules_v070.gd")
const Carrier = preload("res://systems/magnara_carrier_rules_v070.gd")
const Trial = preload("res://systems/spatial_practice_rules_v070.gd")
const Power = preload("res://systems/seeker_power_rules_v068.gd")
const Guild = preload("res://systems/guild_public_director_v069.gd")

func _ready() -> void:
    call_deferred("_run")
func _fail(message: String) -> void:
    push_error("V0.70 AURA TRANSPORT TRIALBOARD RULES FAILED: "+message)
    get_tree().call_deferred("quit",1)

func _run() -> void:
    if Parkour.BURST_AURA != 16 or Parkour.BURST_STAMINA != 8.0:
        _fail("physical Aura drill cost changed")
        return
    if not is_equal_approx(Parkour.valid_direction(Vector3(3,4,4)).length(),1.0):
        _fail("dash must be normalized to horizontal physical displacement")
        return
    if not is_zero_approx(Parkour.valid_direction(Vector3.ZERO).length()):
        _fail("zero-movement dash is permitted")
        return
    var good: Dictionary = Parkour.may_burst(Vector3(4,0,3),0.0,100,100,false,false,false)
    if not bool(good.get("allowed",false)) or good.get("game_only",false) != true:
        _fail("valid game-only novice Aura burst blocked")
        return
    if Parkour.may_burst(Vector3.ZERO,0.0,100,100,false,false,false).get("allowed",true):
        _fail("empty direction can waste Aura")
        return
    for blocked in [
        Parkour.may_burst(Vector3.FORWARD,0.2,100,100,false,false,false),
        Parkour.may_burst(Vector3.FORWARD,0.0,15.0,100,false,false,false),
        Parkour.may_burst(Vector3.FORWARD,0.0,100,7.0,false,false,false),
        Parkour.may_burst(Vector3.FORWARD,0.0,100,100,true,false,false),
        Parkour.may_burst(Vector3.FORWARD,0.0,100,100,false,true,false),
        Parkour.may_burst(Vector3.FORWARD,0.0,100,100,false,false,true),
        Parkour.may_burst(Vector3.FORWARD,0.0,100,100,false,false,false,false)
    ]:
        if bool(blocked.get("allowed",true)):
            _fail("Aura momentum bypasses stamina/cooldown/panels/guard/script gate")
            return
    if Parkour.jump_available(false,0,0.05,0.10) != "first" \
            or Parkour.jump_available(false,1,0,0.10) != "second" \
            or Parkour.jump_available(false,2,0,0.10) != "none":
        _fail("coyote/buffered/double jump order is incorrect")
        return
    if Parkour.FLOOR_SNAP <= 0.0 or Parkour.MAX_DASH_DISTANCE > 6.0:
        _fail("burst crosses walls or falls through moving platform")
        return
    var catalog: Dictionary = Power.load_catalog()
    if not Power.valid_catalog(catalog):
        _fail("V0.68 four-layer Soul Aura Muti catalog is no longer valid")
        return
    var art: Dictionary = Power.technique_by_id(catalog,"aura_momentum_v070")
    if art.is_empty() or str(art.get("owner","")) != "game_only_player" \
            or str(art.get("cast_policy","")) != "public_basic":
        _fail("novice burst isn't tagged public game-only")
        return
    if not bool(Power.attempt(Power.create_model("seeker_test",100),art).get("allowed",false)):
        _fail("burst is not authorized via actual Soul Aura Muti Technique chain")
        return
    if bool(Power.attempt(Power.create_model("seeker_test",100,100,24,4.5,1.0,["Elemental"]),art).get("allowed",false)):
        _fail("untrained Martial spoke can cast burst")
        return

    var begin: Dictionary = Carrier.state_at(0.0)
    var middle: Dictionary = Carrier.state_at(Carrier.DOCK_SECONDS + Carrier.ONE_WAY_SECONDS/2.0)
    var north: Dictionary = Carrier.state_at(Carrier.DOCK_SECONDS+Carrier.ONE_WAY_SECONDS)
    var southbound: Dictionary = Carrier.state_at(Carrier.DOCK_SECONDS*2.0+Carrier.ONE_WAY_SECONDS*1.5)
    if str(begin.get("state","")) != "south_stop" or not bool(begin.get("docked",false)):
        _fail("public carrier misses physical south station stop")
        return
    if absf(float((middle["position"] as Vector3).z)-649.0) > 0.1 \
            or float((middle["velocity"] as Vector3).z) <= 0.0:
        _fail("3D carrier doesn't move smoothly northward on spline")
        return
    if str(north.get("state","")) != "north_stop" \
            or str(southbound.get("state","")) != "southbound":
        _fail("return cycle or station dwell miscalculated")
        return
    if not is_equal_approx(float((Carrier.state_at(Carrier.CYCLE_SECONDS)["position"] as Vector3).z),608.0):
        _fail("carrier movement isn't repeatable over daily routes")
        return
    if not Carrier.state_at(-4.0).is_empty() or Carrier.safe_visitor(Vector3(0,0,900)):
        _fail("invalid trip time or distant location admitted")
        return

    var permitted: Dictionary = Trial.valid_entry("Stray",true,false,false)
    if not bool(permitted.get("allowed",false)) or bool(permitted.get("grants_spatial_muti",true)):
        _fail("public orientation requires rare mastery or grants unauthorized Spatial powers")
        return
    for denied in [
        Trial.valid_entry("Abyssal Sage",true,false,false),
        Trial.valid_entry("Iron",false,false,false),
        Trial.valid_entry("Iron",true,true,false),
        Trial.valid_entry("Iron",true,false,true)
    ]:
        if bool(denied.get("allowed",true)):
            _fail("private chamber gate ignores rank/travel/active state")
            return
    if not Trial.safe_return(Trial.ENTRY+Vector3(0,0,-2)) or Trial.safe_return(Trial.ARENA):
        _fail("temporary spatial room may be saved as a permanent public location")
        return
    var scene_state: Dictionary = Trial.trial_step(5.0,0.4)
    if scene_state.get("has_boss",true) or scene_state.get("has_spatial_spoke_grant",true) \
            or Trial.MAX_ACTIVE_ROOMS != 1:
        _fail("pre-story board accidentally spawns a boss or rare powers")
        return
    if not Trial.trial_step(-1,0).is_empty() \
            or not Trial.trial_step(Trial.ARENA_TIME_LIMIT,0).get("expired",false):
        _fail("unbounded temporary room lifetime")
        return
    if Guild.rank_allows("Stray","rooftop_report"):
        _fail("V0.69 protected Seeker public mission rank was downgraded")
        return
    print("V0.70 SAFE AURA BURST FOUR-LAYER MASTERY CARRIER SPLINE SPATIAL TRIAL GATES PASS")
    get_tree().call_deferred("quit",0)
