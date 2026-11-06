extends RefCounted
# Game-only public waystation assignment. Deterministic transitions, no payouts here.
const STAGES: Array[String] = ["available", "planning", "ready", "outbound", "waystation", "rested", "engage", "response", "return_ready", "return_trip", "debrief", "complete"]
const PREPARATIONS: Array[String] = ["medicine", "survey"]
const OUTCOMES: Array[String] = ["protect_civilians", "secure_evidence"]

static func fresh() -> Dictionary:
    return {"version": 1, "stage": "available", "preparation": "", "outcome": "", "departure_day": 0, "rest_day": 0, "paid": false}

static func sanitize(value: Variant) -> Dictionary:
    if typeof(value) != TYPE_DICTIONARY:
        return fresh()
    var stage: String = str(value.get("stage", "available"))
    var prep: String = str(value.get("preparation", ""))
    var outcome: String = str(value.get("outcome", ""))
    var depart: int = clampi(int(value.get("departure_day", 0)), 0, 999999)
    var rest: int = clampi(int(value.get("rest_day", 0)), 0, 999999)
    if not STAGES.has(stage) or (not prep.is_empty() and not PREPARATIONS.has(prep)) or (not outcome.is_empty() and not OUTCOMES.has(outcome)):
        return fresh()
    if stage in ["available", "planning"] and (not prep.is_empty() or not outcome.is_empty() or depart != 0 or rest != 0):
        return fresh()
    if stage == "ready" and (prep.is_empty() or depart != 0 or not outcome.is_empty()):
        return fresh()
    if stage in ["outbound", "waystation", "rested", "engage", "response", "return_ready", "return_trip", "debrief", "complete"] and (prep.is_empty() or depart < 1):
        return fresh()
    if stage in ["outbound", "waystation"] and (rest != 0 or not outcome.is_empty()):
        return fresh()
    if stage in ["rested", "engage", "response", "return_ready", "return_trip", "debrief", "complete"] and rest <= depart:
        return fresh()
    if stage in ["rested", "engage", "response"] and not outcome.is_empty():
        return fresh()
    if stage in ["return_ready", "return_trip", "debrief", "complete"] and outcome.is_empty():
        return fresh()
    return {"version": 1, "stage": stage, "preparation": prep, "outcome": outcome,
        "departure_day": depart, "rest_day": rest, "paid": bool(value.get("paid", false)) if stage == "complete" else false}

static func advance(before: Dictionary, action: String, game_day: int) -> Dictionary:
    var state: Dictionary = sanitize(before)
    var stage: String = str(state["stage"])
    match action:
        "accept":
            if stage != "available": return {}
            state["stage"] = "planning"
        "equip_medicine", "equip_survey":
            if stage != "planning": return {}
            state["preparation"] = "medicine" if action == "equip_medicine" else "survey"
            state["stage"] = "ready"
        "depart":
            if stage != "ready" or game_day < 1: return {}
            state["departure_day"] = game_day
            state["stage"] = "outbound"
        "arrive_outbound":
            if stage != "outbound": return {}
            state["stage"] = "waystation"
        "rest":
            if stage != "waystation" or game_day <= int(state["departure_day"]): return {}
            state["rest_day"] = game_day
            state["stage"] = "rested"
        "investigate":
            if stage != "rested": return {}
            state["stage"] = "engage"
        "enemy_defeated":
            if stage != "engage": return {}
            state["stage"] = "response"
        "protect_civilians", "secure_evidence":
            if stage != "response": return {}
            state["outcome"] = action
            state["stage"] = "return_ready"
        "board_return":
            if stage != "return_ready": return {}
            state["stage"] = "return_trip"
        "arrive_return":
            if stage != "return_trip": return {}
            state["stage"] = "debrief"
        "file_report":
            if stage != "debrief": return {}
            state["stage"] = "complete"
        _:
            return {}
    return state
