extends RefCounted
# V0.49 — game-only volunteer field partner. Not a canonical character.
# Deterministic state for bounded loyalty, injury and once-per-day recovery.
const MAX_INJURY: int = 100
const MAX_INTERCEPTIONS: int = 3
const FIELD_OUTCOMES: Array[String] = ["protect_civilians", "secure_evidence"]

static func fresh() -> Dictionary:
    return {"version": 1, "loyalty": 0, "injury": 0, "interventions": 0, "last_rest_day": -1, "outcome": ""}

static func sanitize(value: Variant) -> Dictionary:
    var clean: Dictionary = fresh()
    if typeof(value) != TYPE_DICTIONARY:
        return clean
    clean["loyalty"] = clampi(int(value.get("loyalty", 0)), -3, 3)
    clean["injury"] = clampi(int(value.get("injury", 0)), 0, MAX_INJURY)
    clean["interventions"] = clampi(int(value.get("interventions", 0)), 0, MAX_INTERCEPTIONS)
    clean["last_rest_day"] = clampi(int(value.get("last_rest_day", -1)), -1, 999999)
    var outcome: String = str(value.get("outcome", ""))
    clean["outcome"] = outcome if FIELD_OUTCOMES.has(outcome) else ""
    return clean

static func absorb_field_hit(value: Dictionary, damage: int) -> Dictionary:
    var data: Dictionary = sanitize(value)
    if damage <= 0 or int(data["injury"]) >= 65 or int(data["interventions"]) >= MAX_INTERCEPTIONS or int(data["loyalty"]) <= -3:
        return {}
    data["interventions"] = int(data["interventions"]) + 1
    data["injury"] = mini(MAX_INJURY, int(data["injury"]) + maxi(9, int(ceil(float(damage) * 1.4))))
    return data

static func recover_once(value: Dictionary, game_day: int) -> Dictionary:
    var data: Dictionary = sanitize(value)
    if game_day < 1 or int(data["injury"]) <= 0 or game_day <= int(data["last_rest_day"]):
        return {}
    data["injury"] = maxi(0, int(data["injury"]) - 24)
    data["last_rest_day"] = game_day
    return data

static func resolve_outcome(value: Dictionary, outcome: String) -> Dictionary:
    var data: Dictionary = sanitize(value)
    if not FIELD_OUTCOMES.has(outcome) or not str(data["outcome"]).is_empty():
        return {}
    data["outcome"] = outcome
    if outcome == "protect_civilians":
        data["loyalty"] = clampi(int(data["loyalty"]) + 2, -3, 3)
    else:
        data["loyalty"] = clampi(int(data["loyalty"]) + 1, -3, 3)
    return data
