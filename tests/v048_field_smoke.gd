extends Node
const Rules = preload("res://systems/field_rules_v048.gd")
func _ready() -> void:
    call_deferred("_run")
func _run() -> void:
    var state: Dictionary = Rules.fresh()
    if not Rules.advance(state, "report").is_empty():
        push_error("Cannot report an unstarted mission")
        get_tree().call_deferred("quit", 1)
        return
    for action in ["accept", "checkpoint", "enemy_defeated", "protect_civilians", "report"]:
        var next: Dictionary = Rules.advance(state, action)
        if next.is_empty():
            push_error("Field transition unexpectedly rejected: " + action)
            get_tree().call_deferred("quit", 1)
            return
        state = next
    if str(state["stage"]) != "complete" or str(state["choice"]) != "protect_civilians":
        push_error("Field mission final state wrong")
        get_tree().call_deferred("quit", 1)
        return
    if not Rules.advance(state, "report").is_empty() or not Rules.advance(state, "secure_evidence").is_empty():
        push_error("Exclusive decision or report dedup failed")
        get_tree().call_deferred("quit", 1)
        return
    var restored: Dictionary = Rules.sanitize(JSON.parse_string(JSON.stringify(state)))
    if restored != state:
        push_error("Field mission JSON reload test failed")
        get_tree().call_deferred("quit", 1)
        return
    var other: Dictionary = Rules.fresh()
    for action in ["accept", "checkpoint", "enemy_defeated", "secure_evidence", "report"]:
        other = Rules.advance(other, action)
    if str(other.get("choice", "")) != "secure_evidence":
        push_error("Evidence branch inaccessible")
        get_tree().call_deferred("quit", 1)
        return
    print("V0.48 FIELD MISSION STATE SMOKE PASS")
    get_tree().call_deferred("quit", 0)
