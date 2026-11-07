extends RefCounted
# V0.64 / Ring II game-only public life. No Seeker licenses or canon titles.
const SERVICES: Array[String] = ["inn", "records", "clinic"]
const ACTIONS: Array[String] = ["checkin", "sleep", "treatment", "assist"]
const NIGHT_COST: int = 18
const CLINIC_COST: int = 7
const CIVIC_HELP_PAY: int = 5
const KINDS: Array[String] = ["nights", "slept", "treatments", "helped"]
const MAX_DAYS: int = 1200

static func day_at(minutes: float) -> int:
    return maxi(1, int(floorf(maxf(0.0, minutes) / 1440.0)) + 1)

static func local_minute(minutes: float) -> int:
    return posmod(int(floorf(maxf(0.0, minutes))), 1440)

static func open_for(service: String, minutes: float) -> bool:
    var minute: int = local_minute(minutes)
    match service:
        "inn":
            return true
        "records":
            return minute >= 540 and minute < 1020
        "clinic":
            return minute >= 420 and minute < 1200
    return false

static func next_morning(minutes: float) -> float:
    var day_start: float = floorf(maxf(0.0, minutes) / 1440.0) * 1440.0
    return day_start + 1800.0

static func empty_book() -> Dictionary:
    return {"version": 1, "nights": {}, "slept": {}, "treatments": {}, "helped": {}}

static func sanitize(value: Variant) -> Dictionary:
    var result: Dictionary = empty_book()
    if typeof(value) != TYPE_DICTIONARY:
        return result
    var raw: Dictionary = value
    for kind in KINDS:
        var entries: Variant = raw.get(kind, {})
        if typeof(entries) != TYPE_DICTIONARY:
            continue
        var candidates: Array = entries.keys()
        candidates.sort()
        var clean: Dictionary = {}
        for key in candidates:
            var stamp: String = str(key)
            if not stamp.begins_with("day:"):
                continue
            var suffix: String = stamp.trim_prefix("day:")
            if not suffix.is_valid_int() or int(suffix) < 1 or int(suffix) > 1000000:
                continue
            if typeof(entries[key]) != TYPE_BOOL:
                continue
            if not bool(entries[key]):
                continue
            clean[stamp] = true
            if clean.size() >= MAX_DAYS:
                break
        result[kind] = clean
    return result

static func has_receipt(value: Variant, kind: String, day: int) -> bool:
    if not KINDS.has(kind) or day < 1:
        return false
    var safe: Dictionary = sanitize(value)
    var marks: Dictionary = safe[kind]
    return marks.has("day:%d" % day)

static func mark(value: Variant, kind: String, day: int) -> Dictionary:
    if not KINDS.has(kind) or day < 1 or day > 1000000:
        return {}
    var safe: Dictionary = sanitize(value)
    if has_receipt(safe, kind, day):
        return {}
    if kind == "slept" and not has_receipt(safe, "nights", day):
        return {}
    var marks: Dictionary = safe[kind]
    marks["day:%d" % day] = true
    safe[kind] = marks
    return safe

static func can(action: String, minutes: float, value: Variant, money: int) -> bool:
    var day: int = day_at(minutes)
    match action:
        "checkin":
            return open_for("inn", minutes) and money >= NIGHT_COST and not has_receipt(value, "nights", day)
        "sleep":
            return has_receipt(value, "nights", day) and not has_receipt(value, "slept", day)
        "treatment":
            return open_for("clinic", minutes) and money >= CLINIC_COST and not has_receipt(value, "treatments", day)
        "assist":
            return open_for("records", minutes) and not has_receipt(value, "helped", day)
    return false
