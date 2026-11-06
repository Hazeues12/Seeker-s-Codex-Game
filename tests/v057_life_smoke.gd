extends Node3D
# V0.57: validate the pure life-road rules independently of old player saves.
const Rules = preload("res://systems/young_blood_life_rules_v057.gd")
const SAMPLE_SAVE: String = "user://v057_life_smoke_only.json"

func _ready() -> void:
    call_deferred("_run")

func _fail(why: String) -> void:
    push_error("V0.57 LIFE-ROAD SMOKE FAILED: " + why)
    get_tree().call_deferred("quit", 1)

func _run() -> void:
    var empty: Dictionary = Rules.sanitize({})
    if not empty.is_empty() or not Rules.can_take_seeker_contract(empty):
        _fail("old player Codex cannot remain compatible")
        return
    if Rules.ROADS.size() != 3 or Rules.NATIONS.size() != 10:
        _fail("Young Blood starter paths or approved original nations changed")
        return
    if not Rules.choose_path({}, "forged_celestial", "Janoah", 1).is_empty():
        _fail("invented road was accepted")
        return
    if not Rules.choose_path({}, Rules.ROAD_EXAM, "unmapped_nation", 1).is_empty():
        _fail("unknown home nation was accepted")
        return
    var exam: Dictionary = Rules.choose_path({}, Rules.ROAD_EXAM, "Rajistan", 1)
    if str(exam.get("nation", "")) != "Rajistan" or Rules.has_iron_license(exam):
        _fail("candidate exam start inappropriately grants licence")
        return
    if not Rules.can_take_seeker_contract(exam):
        _fail("Stray candidate lost existing starter contracts")
        return
    var sworn: Dictionary = Rules.choose_path({}, Rules.ROAD_SWORN, "Britannia", 1)
    if not Rules.has_iron_license(sworn) or not Rules.can_take_seeker_contract(sworn):
        _fail("already-sworn road has no prior certification")
        return
    var trade: Dictionary = Rules.choose_path({}, Rules.ROAD_TRADE, "Janoah", 1)
    if trade.is_empty() or Rules.can_take_seeker_contract(trade) or Rules.has_iron_license(trade):
        _fail("unlicensed civilian incorrectly has Seeker powers or licence")
        return
    if not Rules.choose_path(trade, Rules.ROAD_SWORN, "Chun", 2).is_empty():
        _fail("permanent road selection can be overwritten")
        return
    if not Rules.collect_parcel(trade).is_empty() or not Rules.deliver_parcel(trade, 1).is_empty():
        _fail("courier parcel can be stolen or delivered without a shift")
        return
    var accepted: Dictionary = Rules.accept_courier_shift(trade, 1)
    if str(accepted.get("work", {}).get("stage", "")) != "accepted":
        _fail("shift did not begin")
        return
    if not Rules.accept_courier_shift(accepted, 1).is_empty() or not Rules.deliver_parcel(accepted, 1).is_empty():
        _fail("duplicated acceptance or delivery without pickup")
        return
    var carrying: Dictionary = Rules.collect_parcel(accepted)
    if str(carrying.get("work", {}).get("stage", "")) != "carrying":
        _fail("courier pickup did not change parcel state")
        return
    if not Rules.collect_parcel(carrying).is_empty() or not Rules.deliver_parcel(carrying, 0).is_empty():
        _fail("duplicate parcel or early-day reward")
        return
    var completed: Dictionary = Rules.deliver_parcel(carrying, 1)
    if str(completed.get("work", {}).get("stage", "")) != "idle":
        _fail("job not marked delivered")
        return
    if int(completed.get("work", {}).get("completed", -1)) != 1 or int(completed.get("work", {}).get("paid_day", -1)) != 1:
        _fail("courier completion ledger mismatch")
        return
    if not Rules.deliver_parcel(completed, 1).is_empty() or not Rules.accept_courier_shift(completed, 1).is_empty():
        _fail("same-day double payment guard failed")
        return
    var f := FileAccess.open(SAMPLE_SAVE, FileAccess.WRITE)
    if f == null:
        _fail("isolated test storage unavailable")
        return
    f.store_string(JSON.stringify(completed))
    f.close()
    f = FileAccess.open(SAMPLE_SAVE, FileAccess.READ)
    if f == null:
        _fail("isolated test profile cannot be reloaded")
        return
    var loaded: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    DirAccess.remove_absolute(ProjectSettings.globalize_path(SAMPLE_SAVE))
    if Rules.sanitize(loaded) != completed:
        _fail("courier work, origin or receipt did not survive disk reload")
        return
    if not Rules.accept_courier_shift(loaded, 1).is_empty():
        _fail("loaded save repeats same-day payment")
        return
    var second: Dictionary = Rules.accept_courier_shift(loaded, 2)
    if str(second.get("work", {}).get("stage", "")) != "accepted":
        _fail("future-day civic employment unavailable")
        return
    if int(second.get("work", {}).get("completed", -1)) != 1:
        _fail("shift history erased by next-day acceptance")
        return
    if str(Rules.next_step(second)).find("parcel") < 0:
        _fail("civilian player guidance is broken")
        return
    if Rules.COURIER_PAY_TOLA != 8:
        _fail("test payout no longer matches game contract")
        return
    print("V0.57 YOUNG BLOOD LIFE PATHS AND PERSISTENT COURIER GUARDS PASS")
    get_tree().call_deferred("quit", 0)
