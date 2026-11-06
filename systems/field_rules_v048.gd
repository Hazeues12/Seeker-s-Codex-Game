extends RefCounted

# Deterministic mission transitions. No side effects, rewards or official Seeker ranks.
const VALID_STAGES: Array[String] = ["available", "patrol", "engage", "response", "debrief", "complete"]
const CHOICES: Array[String] = ["protect_civilians", "secure_evidence"]

static func fresh() -> Dictionary:
    return {"version": 1, "stage": "available", "choice": "", "paid": false}

static func sanitize(value: Variant) -> Dictionary:
    if typeof(value) != TYPE_DICTIONARY:
        return fresh()
    var stage: String = str(value.get("stage", "available"))
    var choice: String = str(value.get("choice", ""))
    if not VALID_STAGES.has(stage):
        return fresh()
    if not choice.is_empty() and not CHOICES.has(choice):
        return fresh()
    if stage in ["debrief", "complete"] and choice.is_empty():
        return fresh()
    if stage in ["available", "patrol", "engage", "response"] and not choice.is_empty():
        return fresh()
    return {"version": 1, "stage": stage, "choice": choice, "paid": bool(value.get("paid", false)) if stage == "complete" else false}

static func advance(before: Dictionary, action: String) -> Dictionary:
    var state: Dictionary = sanitize(before)
    var stage: String = str(state["stage"])
    match action:
        "accept":
            if stage != "available": return {}
            state["stage"] = "patrol"
        "checkpoint":
            if stage != "patrol": return {}
            state["stage"] = "engage"
        "enemy_defeated":
            if stage != "engage": return {}
            state["stage"] = "response"
        "protect_civilians", "secure_evidence":
            if stage != "response": return {}
            state["stage"] = "debrief"
            state["choice"] = action
        "report":
            if stage != "debrief" or not CHOICES.has(str(state["choice"])): return {}
            state["stage"] = "complete"
        _:
            return {}
    return state
