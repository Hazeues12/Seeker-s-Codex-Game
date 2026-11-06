extends Node
const Incident = preload("res://world/canal_incident.gd")
func _ready() -> void:
    call_deferred("_check")
func _check() -> void:
    if not Incident.can_start("unstarted") or Incident.can_start("active") or Incident.can_start("resolved"):
        push_error("V0.47 start-state guard failed")
        get_tree().quit(1)
        return
    for result in Incident.OUTCOMES:
        if not Incident.can_resolve("active", result):
            push_error("V0.47 valid outcome rejected")
            get_tree().quit(1)
            return
        if Incident.can_resolve("resolved", result) or Incident.can_resolve("unstarted", result):
            push_error("V0.47 duplicate/unaccepted outcome permitted")
            get_tree().quit(1)
            return
        if Incident.consequences(result).is_empty():
            push_error("V0.47 outcome missing consequences")
            get_tree().quit(1)
            return
    if Incident.can_resolve("active", "bribe_citadel") or not Incident.consequences("made_up").is_empty():
        push_error("V0.47 invalid response accepted")
        get_tree().quit(1)
        return
    print("V0.47 CIVIC CONSEQUENCES SMOKE PASS")
    get_tree().call_deferred("quit", 0)
