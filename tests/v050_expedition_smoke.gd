extends Node
const Rules = preload("res://systems/expedition_rules_v050.gd")
func _ready() -> void:
    call_deferred("_run")
func _fail(message: String) -> void:
    push_error("V0.50 EXPEDITION FAILED: " + message)
    get_tree().call_deferred("quit", 1)
func _run() -> void:
    var s: Dictionary = Rules.fresh()
    if not Rules.advance(s, "file_report", 1).is_empty():
        _fail("unstarted report was accepted"); return
    for action in ["accept", "equip_medicine", "depart", "arrive_outbound"]:
        var next: Dictionary = Rules.advance(s, action, 3)
        if next.is_empty(): _fail("rejected valid action: " + action); return
        s = next
    if not Rules.advance(s, "rest", 3).is_empty():
        _fail("same-day rest accepted"); return
    s = Rules.advance(s, "rest", 4)
    if str(s.get("stage", "")) != "rested" or int(s.get("rest_day", 0)) != 4:
        _fail("overnight camp not recorded"); return
    for action in ["investigate", "enemy_defeated", "protect_civilians", "board_return", "arrive_return", "file_report"]:
        var next: Dictionary = Rules.advance(s, action, 4)
        if next.is_empty(): _fail("rejected valid action: " + action); return
        s = next
    if str(s.get("stage", "")) != "complete" or str(s.get("outcome", "")) != "protect_civilians":
        _fail("final report state incorrect"); return
    if not Rules.advance(s, "file_report", 4).is_empty() or not Rules.advance(s, "secure_evidence", 4).is_empty():
        _fail("duplicate report or mutually exclusive choice allowed"); return
    var saved: Dictionary = Rules.sanitize(JSON.parse_string(JSON.stringify(s)))
    if saved != s: _fail("JSON save/reload changed state"); return
    var t: Dictionary = Rules.fresh()
    for action in ["accept", "equip_survey", "depart", "arrive_outbound", "rest", "investigate", "enemy_defeated", "secure_evidence", "board_return", "arrive_return", "file_report"]:
        var game_day: int = 2 if action in ["rest", "investigate", "enemy_defeated", "secure_evidence", "board_return", "arrive_return", "file_report"] else 1
        t = Rules.advance(t, action, game_day)
        if t.is_empty(): _fail("alternate route rejected: " + action); return
    if str(t["outcome"]) != "secure_evidence" or str(t["preparation"]) != "survey":
        _fail("alternate route not persisted"); return
    if Rules.sanitize({"stage": "complete", "preparation": "survey", "outcome": "secure_evidence", "departure_day": 2, "rest_day": 0}) != Rules.fresh():
        _fail("invalid save accepted"); return
    if not Rules.advance(Rules.fresh(), "rest", 999).is_empty():
        _fail("rest without assignment accepted"); return
    print("V0.50 MULTI-DAY EXPEDITION SMOKE PASS")
    get_tree().call_deferred("quit", 0)
