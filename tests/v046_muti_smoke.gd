extends Node
const Training = preload("res://systems/seven_spokes_training.gd")
func _ready() -> void:
    call_deferred("_check")
func _check() -> void:
    if Training.SPOKES.size() != 7 or Training.SPOKES.has("Celestial"):
        push_error("V0.46: incorrect Seven Spokes list")
        get_tree().quit(1)
        return
    for i in range(7):
        var spec: Dictionary = Training.specification(i)
        if not bool(spec.get("training_only", false)) or int(spec.get("cost", 0)) <= 0:
            push_error("V0.46: unsafe Spoke spec")
            get_tree().quit(1)
            return
        if Training.can_cast(i, float(spec["cost"]) - 1.0, 0.0, true):
            push_error("V0.46: cost bypass")
            get_tree().quit(1)
            return
        if Training.can_cast(i, float(spec["cost"]), 0.0, false):
            push_error("V0.46: world training restriction bypass")
            get_tree().quit(1)
            return
        if Training.can_cast(i, float(spec["cost"]), 0.4, true):
            push_error("V0.46: cooldown bypass")
            get_tree().quit(1)
            return
        if not Training.can_cast(i, float(spec["cost"]), 0.0, true):
            push_error("V0.46: valid technique rejected")
            get_tree().quit(1)
            return
    if not Training.specification(7).is_empty() or not Training.specification(-1).is_empty():
        push_error("V0.46: unknown Spoke incorrectly supported")
        get_tree().quit(1)
        return
    print("V0.46 SEVEN SPOKES SAFETY SMOKE PASS")
    get_tree().call_deferred("quit", 0)
