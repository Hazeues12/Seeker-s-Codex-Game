extends Node3D
const Rules = preload("res://systems/magnara_workshop_rules_v061.gd")
const OUTFILE: String = "user://v061_workshop_rules_test.json"

func _ready() -> void:
    call_deferred("_run")

func _fail(why: String) -> void:
    push_error("V0.61 WORKSHOP RULES FAILED: " + why)
    get_tree().call_deferred("quit", 1)

func _run() -> void:
    if Rules.JOBS.size() != 3 or Rules.LABELS.size() != 3 or Rules.ZONES.size() != 3:
        _fail("three jobs are required")
        return
    var base: Dictionary = Rules.sanitize({})
    if not base["active"].is_empty() or not base["days"].is_empty() or int(base["worker_trust"]) != 0:
        _fail("legacy save is no longer neutral")
        return
    if Rules.pays("refuse", 10) != 0 or Rules.pays("unknown", 10) != 0:
        _fail("refusing dangerous work generated a salary")
        return
    if Rules.pays("careful", 0) != 14 or Rules.pays("rush", 0) != 17:
        _fail("wages do not match proposed economic registry")
        return
    if Rules.pays("careful", 4) != 16 or Rules.pays("rush", -4) != 15:
        _fail("residential trust cannot influence workshop opportunities")
        return
    if not Rules.accept(base, "unknown_guild", 1).is_empty() or not Rules.accept(base, Rules.JOBS[0], 0).is_empty():
        _fail("invalid job or day was accepted")
        return
    if not Rules.collect(base).is_empty() or not Rules.complete(base, "careful", 1).is_empty():
        _fail("a worker can complete an unassigned job")
        return
    for id in Rules.JOBS:
        var shift: Dictionary = Rules.accept({}, id, 1)
        if shift.is_empty() or str(shift.get("active", {}).get("job", "")) != id:
            _fail("employer has no independently selectable work: " + id)
            return
        if not Rules.accept(shift, Rules.JOBS[0], 1).is_empty():
            _fail("multiple employers could reserve the same day")
            return
        if not Rules.complete(shift, "rush", 1).is_empty():
            _fail("work can be billed without materials")
            return
        var carrying: Dictionary = Rules.collect(shift)
        if str(carrying["active"].get("stage", "")) != "carrying":
            _fail("assigned materials did not become carried")
            return
        if not Rules.collect(carrying).is_empty():
            _fail("same materials can be collected repeatedly")
            return
        if not Rules.complete(carrying, "invented", 1).is_empty():
            _fail("arbitrary final outcome was accepted")
            return
        var finished: Dictionary = Rules.complete(carrying, "careful", 1)
        if int(finished["worker_trust"]) != 2 or int(finished["completed"]) != 1 or int(finished["safe_jobs"]) != 1:
            _fail("fair work was not registered")
            return
        if not Rules.complete(finished, "careful", 1).is_empty() or not Rules.accept(finished, id, 1).is_empty():
            _fail("same-day wage receipt can be exploited")
            return
        if str(finished["days"]["day:1"]["job"]) != id:
            _fail("shift employment history lacks employer details")
            return
        var day_two: Dictionary = Rules.accept(finished, id, 2)
        if day_two.is_empty():
            _fail("a different day does not unlock new work")
            return
        var rushed: Dictionary = Rules.complete(Rules.collect(day_two), "rush", 2)
        if int(rushed["rushed_jobs"]) != 1 or int(rushed["worker_trust"]) != -1:
            _fail("rushing work has no dangerous reputation consequence")
            return
        var day_three: Dictionary = Rules.accept(rushed, id, 3)
        var refused: Dictionary = Rules.complete(Rules.collect(day_three), "refuse", 3)
        if int(refused["refused_jobs"]) != 1 or int(refused["worker_trust"]) != 0 or int(refused["completed"]) != 3:
            _fail("refusing unsafe work wasn't recorded distinctly")
            return
    var late: Dictionary = Rules.accept({}, Rules.JOBS[2], 4)
    var pending: Dictionary = Rules.collect(late)
    if not Rules.complete(pending, "careful", 3).is_empty():
        _fail("old date was used to complete a newer contract")
        return
    var next_day: Dictionary = Rules.complete(pending, "careful", 5)
    if str(next_day["days"]["day:5"]["outcome"]) != "careful":
        _fail("multi-day ongoing work cannot be completed")
        return
    if not Rules.accept(next_day, Rules.JOBS[1], 5).is_empty():
        _fail("same-day wage limits don't apply to jobs accepted on a previous day")
        return
    var forged: Dictionary = Rules.sanitize({
        "active": {"job": "black_clan_eye_unlock", "day": 1, "stage": "carrying"},
        "worker_trust": 9000,
        "days": {"day:4": {"job": "forge_service", "outcome": "careful"},
                 "day:-2": {"job": "cloth_repair", "outcome": "careful"},
                 "day:6": {"job": "Viatra", "outcome": "rush"}},
        "completed": -120, "rushed_jobs": 99999
    })
    if not forged["active"].is_empty() or int(forged["worker_trust"]) != 12 or int(forged["completed"]) != 0:
        _fail("forged employment history can create unearned status")
        return
    if forged["days"].size() != 1 or int(forged["rushed_jobs"]) != 2000:
        _fail("out-of-scope or exaggerated worker history wasn't sanitized")
        return
    var saved_file := FileAccess.open(OUTFILE, FileAccess.WRITE)
    if saved_file == null:
        _fail("isolated workshop storage unavailable")
        return
    saved_file.store_string(JSON.stringify(next_day))
    saved_file.close()
    saved_file = FileAccess.open(OUTFILE, FileAccess.READ)
    if saved_file == null:
        _fail("isolated stored work record cannot be read")
        return
    var loaded: Variant = JSON.parse_string(saved_file.get_as_text())
    saved_file.close()
    DirAccess.remove_absolute(ProjectSettings.globalize_path(OUTFILE))
    if Rules.sanitize(loaded) != next_day:
        _fail("worker outcomes didn't persist")
        return
    print("V0.61 WORKSHOP ECONOMY CHOICE CONSEQUENCES AND SAVE RULES PASS")
    get_tree().call_deferred("quit", 0)
