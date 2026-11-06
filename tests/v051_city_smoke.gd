extends Node
const Rules = preload("res://systems/city_routines_v051.gd")
func _ready() -> void:
    call_deferred("_test")
func _fail(msg: String) -> void:
    push_error("V0.51 test failed: " + msg)
    get_tree().call_deferred("quit", 1)
func _test() -> void:
    if not bool(Rules.assignment("npc_ring2_noodles", 480.0)["present"]):
        _fail("vendor should work at 8AM")
        return
    if bool(Rules.assignment("npc_ring2_noodles", 1380.0)["present"]):
        _fail("vendor should close at 11PM")
        return
    if not bool(Rules.assignment("npc_ring2_medic", 1390.0)["present"]):
        _fail("medical watch must have night coverage")
        return
    if str(Rules.assignment("npc_ring2_register", 800.0)["duty"]).is_empty():
        _fail("registration duty missing")
        return
    if Rules.bulletin_context(2, true, false) != "canal" or Rules.bulletin_context(3, false, true) != "expedition":
        _fail("prior events did not affect daily bulletin")
        return
    var empty: Dictionary = {}
    if not Rules.response(empty, 1, "routine", "report", false).is_empty():
        _fail("unearned professional report allowed")
        return
    var first: Dictionary = Rules.response(empty, 1, "routine", "assist", false)
    var after: Dictionary = first.get("state", {})
    if first.is_empty() or int(first["reputation"].get("local_respect", 0)) != 2:
        _fail("civic effort consequence missing")
        return
    if not Rules.response(after, 1, "routine", "shortcut", true).is_empty():
        _fail("same-day reward or conflicting decision bypass")
        return
    var second: Dictionary = Rules.response(after, 2, "canal", "shortcut", true)
    var state: Dictionary = second.get("state", {})
    if state.is_empty() or int(second["reputation"].get("association_trust", 0)) != -2:
        _fail("misconduct must have a reputation cost")
        return
    if not Rules.already_answered(state, 1) or not Rules.already_answered(state, 2):
        _fail("per-day choice history missing")
        return
    var roundtrip: Variant = JSON.parse_string(JSON.stringify(state))
    if typeof(roundtrip) != TYPE_DICTIONARY:
        _fail("daily choices did not deserialize into a Dictionary")
        return
    if not Rules.already_answered(roundtrip, 1) or not Rules.already_answered(roundtrip, 2):
        _fail("day identifiers missing after save and reload")
        return
    var restored_days: Dictionary = roundtrip.get("days", {})
    var restored_day1: Dictionary = restored_days.get("day_1", {})
    var restored_day2: Dictionary = restored_days.get("day_2", {})
    if str(restored_day1.get("choice", "")) != "assist" or str(restored_day2.get("choice", "")) != "shortcut" or str(restored_day2.get("context", "")) != "canal":
        _fail("saved choice or event context changed after reload")
        return
    if Rules.response(state, 2, "canal", "report", true) != {}:
        _fail("resuming a day permitted extra report")
        return
    var third: Dictionary = Rules.response(state, 3, "expedition", "report", true)
    if third.is_empty():
        _fail("next-day verified report blocked")
        return
    print("V0.51 DAILY CITY MEMORY SMOKE PASS")
    get_tree().call_deferred("quit", 0)
