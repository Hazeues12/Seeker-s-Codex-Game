extends Node3D
const Rules = preload("res://systems/residential_life_v060.gd")
const TEMP_FILE: String = "user://v060_neighborhood_rules_smoke.json"

func _ready() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("V0.60 NEIGHBORHOOD RULES FAILED: " + message)
    get_tree().call_deferred("quit", 1)

func _run() -> void:
    if Rules.IDS.size() != 3 or Rules.LABELS.size() != 3:
        _fail("three distinct named game-only residents are required")
        return
    var state: Dictionary = Rules.sanitize({})
    if not state.get("households", {}).is_empty():
        _fail("legacy saves should start with an unmodified neighborhood")
        return
    if Rules.total_community_trust(state) != 0:
        _fail("legacy profile gained unearned favors")
        return
    if not Rules.decide(state, "invented_noble", "help", 1).is_empty():
        _fail("unregistered neighborhood citizen gained a real reward")
        return
    if not Rules.decide(state, Rules.IDS[0], "rob", 1).is_empty() or not Rules.decide(state, Rules.IDS[0], "help", 0).is_empty():
        _fail("arbitrary action or invalid day accepted")
        return
    var aided: Dictionary = Rules.decide(state, Rules.IDS[0], "help", 1)
    if aided.is_empty() or Rules.rapport(aided, Rules.IDS[0]) != 2:
        _fail("household assistance did not improve relationship")
        return
    if not Rules.decide(aided, Rules.IDS[0], "help", 1).is_empty() or not Rules.decide(aided, Rules.IDS[0], "pressure", 1).is_empty():
        _fail("daily choices can be replayed for infinite reputation")
        return
    var listened: Dictionary = Rules.decide(aided, Rules.IDS[1], "listen", 1)
    var pressured: Dictionary = Rules.decide(listened, Rules.IDS[2], "pressure", 1)
    if Rules.total_community_trust(pressured) != 1:
        _fail("three households do not retain independent social outcomes")
        return
    if Rules.rapport(pressured, Rules.IDS[2]) != -2 or Rules.rapport(pressured, Rules.IDS[1]) != 1:
        _fail("pressure and listening choices have identical results")
        return
    var future: Dictionary = pressured
    for day in range(2, 20):
        var key: String = "pressure" if day < 7 else "help"
        future = Rules.decide(future, Rules.IDS[0], key, day)
        if future.is_empty():
            _fail("future-day neighborhood choice was lost")
            return
    if Rules.rapport(future, Rules.IDS[0]) > 6 or Rules.rapport(future, Rules.IDS[0]) < -6:
        _fail("social rapport cap was bypassed")
        return
    var suspicious: Dictionary = Rules.sanitize({
        "households": {
            "canal_weaver": {"rapport": 500, "helped": 200000, "pressured": -19, "days": {"bad": "help", "d:1": "steal", "d:2": "listen"}},
            "unknowable_pillar": {"rapport": 100, "days": {"d:1": "help"}}
        }
    })
    if Rules.rapport(suspicious, Rules.IDS[0]) != 6 or suspicious["households"].has("unknowable_pillar"):
        _fail("forged or unknown social status was accepted")
        return
    if Rules.can_choose(suspicious, Rules.IDS[0], 2) or not Rules.can_choose(suspicious, Rules.IDS[0], 1):
        _fail("invalid activity days were not sanitized")
        return
    for id in Rules.IDS:
        if Rules.phase_at(id, 100.0) != "home" or Rules.phase_at(id, 700.0) != "working":
            _fail("daily schedules do not return home and work " + id)
            return
        if Rules.phase_at(id, 1160.0) != "community_time":
            _fail("residents do not return to public social life " + id)
            return
        var sleep_position: Vector3 = Rules.position_at(id, 100.0)
        var work_position: Vector3 = Rules.position_at(id, 700.0)
        if sleep_position.distance_to(work_position) < 8.0:
            _fail("schedule changes text but leaves the character stationary " + id)
            return
        if absf(work_position.y - 0.56) > 0.01:
            _fail("resident is not on real street elevation " + id)
            return
        var shift_1: Vector3 = Rules.position_at(id, 540.0)
        var shift_2: Vector3 = Rules.position_at(id, 540.0 + 1440.0)
        if shift_1.distance_to(shift_2) > 0.001:
            _fail("residents don't repeat a predictable daily schedule " + id)
            return
    var public_claim: Dictionary = {"family_id": "kairo_black_clan_claim", "disclosure": "public"}
    var hidden_claim: Dictionary = {"family_id": "kairo_black_clan_claim", "disclosure": "private"}
    if Rules.neighborhood_reaction(state, Rules.IDS[0], public_claim).find("verified") < 0:
        _fail("public unverified family claim has no social consequence")
        return
    if Rules.neighborhood_reaction(state, Rules.IDS[0], hidden_claim).find("clan") >= 0:
        _fail("private family history leaked to unrelated household")
        return
    if Rules.neighborhood_reaction(pressured, Rules.IDS[2], {}).find("cautious") < 0:
        _fail("residents forgot pressure the next time they speak")
        return
    var f := FileAccess.open(TEMP_FILE, FileAccess.WRITE)
    if f == null:
        _fail("isolated neighborhood save unavailable")
        return
    f.store_string(JSON.stringify(future))
    f.close()
    f = FileAccess.open(TEMP_FILE, FileAccess.READ)
    if f == null:
        _fail("neighborhood save could not be read")
        return
    var loaded: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_FILE))
    if Rules.sanitize(loaded) != future or Rules.can_choose(loaded, Rules.IDS[0], 19):
        _fail("day-specific history did not survive persistent storage")
        return
    print("V0.60 NEIGHBORHOOD SCHEDULES HOUSEHOLD CONSEQUENCES AND SAVE RULES PASS")
    get_tree().call_deferred("quit", 0)
