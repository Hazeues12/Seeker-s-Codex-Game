extends Node
const Rules = preload("res://systems/companion_state_v049.gd")
func _ready() -> void:
    call_deferred("_run")
func _reject(reason: String) -> void:
    push_error("V0.49 COMPANION TEST FAILED: " + reason)
    get_tree().call_deferred("quit", 1)
func _run() -> void:
    var state: Dictionary = Rules.fresh()
    if not Rules.recover_once(state, 1).is_empty():
        _reject("cannot recover without an injury")
        return
    for i in range(3):
        var next: Dictionary = Rules.absorb_field_hit(state, 14)
        if next.is_empty():
            _reject("valid interception rejected")
            return
        state = next
    if int(state["interventions"]) != 3 or int(state["injury"]) != 60:
        _reject("interception cost or count")
        return
    if not Rules.absorb_field_hit(state, 14).is_empty():
        _reject("interception limit bypass")
        return
    var recovered: Dictionary = Rules.recover_once(state, 1)
    if int(recovered.get("injury", -1)) != 36 or not Rules.recover_once(recovered, 1).is_empty():
        _reject("recovery cap or same-day duplication")
        return
    recovered = Rules.recover_once(recovered, 2)
    if int(recovered.get("injury", -1)) != 12:
        _reject("next-day recovery")
        return
    var loyal: Dictionary = Rules.resolve_outcome(recovered, "protect_civilians")
    if int(loyal.get("loyalty", -1)) != 2:
        _reject("loyalty consequence")
        return
    if not Rules.resolve_outcome(loyal, "secure_evidence").is_empty():
        _reject("exclusive mission outcome bypass")
        return
    var saved: Dictionary = Rules.sanitize(JSON.parse_string(JSON.stringify(loyal)))
    if saved != loyal:
        _reject("persistent JSON round trip")
        return
    var bad: Dictionary = Rules.sanitize({"loyalty": 100, "injury": -10, "interventions": 99, "outcome": "forbidden"})
    if int(bad["loyalty"]) != 3 or int(bad["injury"]) != 0 or int(bad["interventions"]) != 3 or str(bad["outcome"]) != "":
        _reject("untrusted save bounds")
        return
    var no_hit: Dictionary = Rules.absorb_field_hit(Rules.fresh(), -1)
    if not no_hit.is_empty():
        _reject("negative damage")
        return
    print("V0.49 COMPANION STATE SMOKE PASS")
    get_tree().call_deferred("quit", 0)
