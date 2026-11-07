extends RefCounted
# V0.69 public TRAINING alchemical-seal interpreter, no eval, scripts,
# arbitrary API calls, forced mind effects, teleport or rare Ice Muti.
# Author's Hollow Thread Atelier is NOT placed outside its canonical Ring V.
const TRIGGERS: Array[String] = ["impact","aura_ready"]
const EFFECTS: Array[String] = ["ward","signal"]
const COSTS: Dictionary = {"ward":18, "signal":8}
const MAX_DAY: int = 1000000
const MAX_RECEIPTS: int = 1500
const MAX_STEPS: int = 3

static func recipe(trigger: String, effect: String) -> Dictionary:
    if not TRIGGERS.has(trigger) or not EFFECTS.has(effect):
        return {}
    return {
        "version": 1, "canon_status": "game_only_training",
        "trigger": trigger, "effect": effect,
        "steps": [
            {"op": "on_" + trigger},
            {"op": "aura_at_least", "value": int(COSTS[effect])},
            {"op": "emit_" + effect}
        ],
        "armed": false
    }

static func sanitize(source: Variant) -> Dictionary:
    if typeof(source) != TYPE_DICTIONARY:
        return {}
    var value: Dictionary = source
    if int(value.get("version", -1)) != 1:
        return {}
    if str(value.get("canon_status", "")) != "game_only_training":
        return {}
    var expected: Dictionary = recipe(str(value.get("trigger","")), str(value.get("effect","")))
    if expected.is_empty() or typeof(value.get("steps", null)) != TYPE_ARRAY:
        return {}
    var steps: Array = value["steps"]
    if steps.size() != MAX_STEPS or steps != expected["steps"]:
        return {}
    expected["armed"] = typeof(value.get("armed", false)) == TYPE_BOOL and bool(value.get("armed", false))
    return expected

static func arm(value: Variant) -> Dictionary:
    var cleaned: Dictionary = sanitize(value)
    if cleaned.is_empty():
        return {}
    cleaned["armed"] = true
    return cleaned

static func ledger(raw: Variant) -> Dictionary:
    var clean: Dictionary = {}
    if typeof(raw) != TYPE_DICTIONARY:
        return clean
    var original: Dictionary = raw
    var stamps: Array = original.keys()
    stamps.sort()
    for stamp in stamps:
        var key: String = str(stamp)
        var parts: PackedStringArray = key.split(":")
        if parts.size() != 2 or parts[0] != "day" or not parts[1].is_valid_int():
            continue
        var day: int = int(parts[1])
        if day < 1 or day > MAX_DAY or typeof(original[stamp]) != TYPE_BOOL or not bool(original[stamp]):
            continue
        clean[key] = true
        if clean.size() >= MAX_RECEIPTS:
            break
    return clean

static func fire(value: Variant, receipts: Variant, event: String, aura: float, day: int) -> Dictionary:
    var prepared: Dictionary = sanitize(value)
    if prepared.is_empty() or not bool(prepared["armed"]) or day < 1 or day > MAX_DAY:
        return {"fired":false,"reason":"not_armed"}
    if event != str(prepared["trigger"]):
        return {"fired":false,"reason":"event_mismatch"}
    var remembered: Dictionary = ledger(receipts)
    var stamp: String = "day:%d" % day
    if remembered.has(stamp):
        return {"fired":false,"reason":"used_today"}
    var cost: int = int(COSTS[prepared["effect"]])
    if not is_finite(aura) or aura < float(cost):
        return {"fired":false,"reason":"aura_low"}
    remembered[stamp] = true
    return {"fired":true, "cost":cost, "effect":str(prepared["effect"]),
        "absorbed":str(prepared["effect"]) == "ward",
        "next_receipts":remembered, "next_recipe":prepared,
        "receipt":stamp, "canon_status":"game_only_training"}

static func has_forbidden_operation(value: Variant) -> bool:
    var check: Dictionary = sanitize(value)
    return check.is_empty()
