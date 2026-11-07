extends Node
const Rules = preload("res://systems/magnara_civic_rules_v064.gd")

func _ready() -> void:
    call_deferred("_test")

func _fail(reason: String) -> void:
    push_error("V0.64 CIVIC RULES FAILED: " + reason)
    get_tree().call_deferred("quit", 1)

func _test() -> void:
    var book: Dictionary = Rules.sanitize({})
    if book.size() != 5 or Rules.day_at(480.0) != 1 or Rules.day_at(1920.0) != 2:
        _fail("a new civic ledger must preserve correct in-world day")
        return
    if Rules.open_for("records", 480.0) or not Rules.open_for("records", 600.0) or Rules.open_for("records", 1080.0):
        _fail("public records desk opening/closing time changed")
        return
    if Rules.open_for("clinic", 360.0) or not Rules.open_for("clinic", 540.0) or Rules.open_for("clinic", 1230.0):
        _fail("clinic hours not enforced")
        return
    if not Rules.open_for("inn", 0.0) or not Rules.open_for("inn", 1439.0):
        _fail("24-hour travel desk cannot be staffed")
        return
    if Rules.can("checkin", 480.0, book, 17) or not Rules.can("checkin", 480.0, book, 18):
        _fail("room price or affordability check wrong")
        return
    if Rules.can("sleep", 480.0, book, 0):
        _fail("free unbooked room allowed")
        return
    var booked: Dictionary = Rules.mark(book, "nights", 1)
    if booked.is_empty() or Rules.can("checkin", 480.0, booked, 100):
        _fail("a room can be double-booked on same day")
        return
    if not Rules.can("sleep", 480.0, booked, 0):
        _fail("paid room cannot be used")
        return
    var rested: Dictionary = Rules.mark(booked, "slept", 1)
    if rested.is_empty() or Rules.can("sleep", 480.0, rested, 999):
        _fail("same night's rest can be exploited repeatedly")
        return
    if absf(Rules.next_morning(480.0) - 1800.0) > 0.01:
        _fail("inn rest doesn't advance to next morning")
        return
    if absf(Rules.next_morning(1680.0) - 3240.0) > 0.01:
        _fail("later day morning clock incorrect")
        return
    if Rules.can("assist", 300.0, book, 0) or not Rules.can("assist", 600.0, book, 0):
        _fail("public desk daily assistance hours missing")
        return
    var assisted: Dictionary = Rules.mark(book, "helped", 1)
    if assisted.is_empty() or Rules.can("assist", 600.0, assisted, 0):
        _fail("civic paperwork can pay unlimited Tola per day")
        return
    if Rules.can("treatment", 600.0, book, 6) or not Rules.can("treatment", 600.0, book, 7):
        _fail("clinic visit affordability incorrect")
        return
    var treated: Dictionary = Rules.mark(book, "treatments", 1)
    if treated.is_empty() or Rules.can("treatment", 600.0, treated, 100):
        _fail("same-day clinic service is not limited")
        return
    var forged: Dictionary = Rules.sanitize({
        "nights": {"day:1": true, "day:-1": true, "day:1.2": true, "day:3": "yes"},
        "slept": {"day:1": false, "day:0": true},
        "helped": {"day:2": true},
        "treatments": {"day:9": true},
        "restricted_institution_authority": true
    })
    if forged.size() != 5 or not Rules.has_receipt(forged, "nights", 1) or Rules.has_receipt(forged, "nights", 3):
        _fail("forged or malformed civic entries bypass sanitize")
        return
    if Rules.mark(book, "slept", 1).size() != 0 or not Rules.mark(book, "seeker_promotion", 1).is_empty():
        _fail("unpaid or institution-only service receipt accepted")
        return
    print("V0.64 PUBLIC INN CLINIC CIVIC HOURS RECEIPTS AND DAILY LIMITS PASS")
    get_tree().call_deferred("quit", 0)
