extends RefCounted
# V0.60 / provisional household simulation for Magnara's Ring Two.
# 1 Godot unit = 1 meter. All three residents and building positions are GAME ONLY.
# No official Seeker ranks, clan membership or inherited techniques are granted.
const IDS: Array[String] = ["canal_weaver", "freight_technician", "civic_tutor"]
const LABELS: Array[String] = ["Canal Weaver", "Freight Yard Technician", "Quarter Tutor"]
const DECISIONS: Array[String] = ["help", "listen", "pressure"]
const HOME_Z: Array[float] = [132.0, 155.0, 181.0]
const WORK_Z: Array[float] = [116.0, 109.0, 125.0]
const OFFSETS: Array[int] = [0, 20, -15]
const HOME_X: float = 83.0
const PATH_X: float = 62.0

static func name_for(id: String) -> String:
    var i: int = IDS.find(id)
    return LABELS[i] if i >= 0 else "Unknown resident"

static func empty_state() -> Dictionary:
    return {"version": 1, "households": {}}

static func sanitize(raw: Variant) -> Dictionary:
    var result: Dictionary = empty_state()
    if typeof(raw) != TYPE_DICTIONARY:
        return result
    var source: Dictionary = raw
    var households: Variant = source.get("households", {})
    if typeof(households) != TYPE_DICTIONARY:
        return result
    for id in IDS:
        var original: Variant = households.get(id, {})
        if typeof(original) != TYPE_DICTIONARY:
            continue
        var item: Dictionary = original
        var old_days: Variant = item.get("days", {})
        var clean_days: Dictionary = {}
        if typeof(old_days) == TYPE_DICTIONARY:
            var counted: int = 0
            for key in old_days:
                var day_key: String = str(key)
                var decision: String = str(old_days[key])
                if day_key.begins_with("d:") and day_key.substr(2).is_valid_int() and int(day_key.substr(2)) >= 1 and DECISIONS.has(decision):
                    clean_days[day_key] = decision
                    counted += 1
                    if counted >= 2000:
                        break
        result["households"][id] = {
            "rapport": clampi(int(item.get("rapport", 0)), -6, 6),
            "helped": clampi(int(item.get("helped", 0)), 0, 2000),
            "listened": clampi(int(item.get("listened", 0)), 0, 2000),
            "pressured": clampi(int(item.get("pressured", 0)), 0, 2000),
            "days": clean_days
        }
    return result

static func day_key(day: int) -> String:
    return "d:%d" % day

static func can_choose(value: Variant, id: String, day: int) -> bool:
    if not IDS.has(id) or day < 1:
        return false
    var state: Dictionary = sanitize(value)
    var person: Dictionary = state["households"].get(id, {})
    var days: Dictionary = person.get("days", {})
    return not days.has(day_key(day))

static func decide(value: Variant, id: String, choice: String, day: int) -> Dictionary:
    if not DECISIONS.has(choice) or not can_choose(value, id, day):
        return {}
    var current: Dictionary = sanitize(value)
    var resident: Dictionary = current["households"].get(id, {
        "rapport": 0, "helped": 0, "listened": 0, "pressured": 0, "days": {}
    })
    var change: int = 0
    match choice:
        "help":
            change = 2
            resident["helped"] = mini(2000, int(resident["helped"]) + 1)
        "listen":
            change = 1
            resident["listened"] = mini(2000, int(resident["listened"]) + 1)
        "pressure":
            change = -2
            resident["pressured"] = mini(2000, int(resident["pressured"]) + 1)
    resident["rapport"] = clampi(int(resident["rapport"]) + change, -6, 6)
    var choices: Dictionary = resident.get("days", {})
    choices[day_key(day)] = choice
    resident["days"] = choices
    current["households"][id] = resident
    return current

static func rapport(value: Variant, id: String) -> int:
    var current: Dictionary = sanitize(value)
    return int(current["households"].get(id, {}).get("rapport", 0))

static func total_community_trust(value: Variant) -> int:
    var sum: int = 0
    for id in IDS:
        sum += rapport(value, id)
    return sum

static func neighborhood_reaction(value: Variant, id: String, family: Variant) -> String:
    var current: Dictionary = sanitize(value)
    var item: Dictionary = current["households"].get(id, {})
    var value_rapport: int = int(item.get("rapport", 0))
    if value_rapport >= 3:
        return "The household recognizes your repeated help and welcomes you as a trusted neighbor."
    if value_rapport <= -3:
        return "The resident remembers the pressure you applied and keeps their distance."
    if value_rapport > 0:
        return "They remember your attention to neighborhood concerns."
    if value_rapport < 0:
        return "They remain cautious after your earlier conduct."
    if typeof(family) == TYPE_DICTIONARY:
        var record: Dictionary = family
        if str(record.get("disclosure", "private")) == "public" and str(record.get("family_id", "")) == "kairo_black_clan_claim":
            return "A public clan story attracts questions, but nobody here has verified your ancestry."
    return "The resident is occupied with work and family routines."

static func phase_at(id: String, world_minutes: float) -> String:
    var i: int = IDS.find(id)
    if i < 0:
        return "unknown"
    var minute: float = fposmod(world_minutes + float(OFFSETS[i]), 1440.0)
    if minute < 480.0 or minute >= 1290.0:
        return "home"
    if minute < 540.0:
        return "commute_to_work"
    if minute < 1020.0:
        return "working"
    if minute < 1100.0:
        return "commute_to_square"
    if minute < 1230.0:
        return "community_time"
    return "returning_home"

static func _mix(a: Vector3, b: Vector3, t: float) -> Vector3:
    return a.lerp(b, clampf(t, 0.0, 1.0))

static func position_at(id: String, world_minutes: float) -> Vector3:
    var i: int = IDS.find(id)
    if i < 0:
        return Vector3.ZERO
    var minute: float = fposmod(world_minutes + float(OFFSETS[i]), 1440.0)
    var home := Vector3(HOME_X, 0.56, HOME_Z[i])
    var sidewalk := Vector3(PATH_X, 0.56, HOME_Z[i])
    var work := Vector3(PATH_X, 0.56, WORK_Z[i])
    var gathering := Vector3(PATH_X, 0.56, 151.0 + float(i) * 4.0)
    if minute < 480.0 or minute >= 1290.0:
        return home
    if minute < 500.0:
        return _mix(home, sidewalk, (minute - 480.0) / 20.0)
    if minute < 540.0:
        return _mix(sidewalk, work, (minute - 500.0) / 40.0)
    if minute < 1020.0:
        return work
    if minute < 1100.0:
        return _mix(work, gathering, (minute - 1020.0) / 80.0)
    if minute < 1230.0:
        return gathering
    if minute < 1260.0:
        return _mix(gathering, sidewalk, (minute - 1230.0) / 30.0)
    return _mix(sidewalk, home, (minute - 1260.0) / 30.0)

static func social_facts(id: String) -> String:
    match id:
        "canal_weaver":
            return "The weaver repairs everyday work cloth for canal households."
        "freight_technician":
            return "The technician works around freight logistics and worries about safe shifts."
        "civic_tutor":
            return "The tutor helps local households study and keep public records."
    return "Their work is not recorded."
