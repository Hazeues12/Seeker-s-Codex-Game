extends RefCounted
# V0.61 / public Ring Two workshop corridor, not the canon Ring V forges.
# All employer names, workshops, street bearings and wage rates are GAME ONLY.
const JOBS: Array[String] = ["forge_service", "cloth_repair", "freight_tally"]
const LABELS: Array[String] = ["Forge Service", "Cloth Repair", "Freight Tally"]
const ZONES: Array[float] = [142.0, 178.0, 216.0]
const OUTCOMES: Array[String] = ["careful", "rush", "refuse"]
const BASE_PAY: int = 14
const RUSH_BONUS: int = 3

static func job_label(id: String) -> String:
    var index: int = JOBS.find(id)
    return LABELS[index] if index >= 0 else "Unregistered workplace"

static func empty_state() -> Dictionary:
    return {
        "version": 1, "active": {}, "days": {},
        "completed": 0, "worker_trust": 0,
        "safe_jobs": 0, "rushed_jobs": 0, "refused_jobs": 0
    }

static func sanitize(value: Variant) -> Dictionary:
    var clean: Dictionary = empty_state()
    if typeof(value) != TYPE_DICTIONARY:
        return clean
    var raw: Dictionary = value
    var old_days: Variant = raw.get("days", {})
    if typeof(old_days) == TYPE_DICTIONARY:
        var dates: Dictionary = {}
        var counted: int = 0
        for key in old_days:
            var stamp: String = str(key)
            var entry: Variant = old_days[key]
            if not stamp.begins_with("day:") or not stamp.substr(4).is_valid_int() or int(stamp.substr(4)) < 1:
                continue
            if typeof(entry) != TYPE_DICTIONARY:
                continue
            var result: Dictionary = entry
            if not JOBS.has(str(result.get("job", ""))) or not OUTCOMES.has(str(result.get("outcome", ""))):
                continue
            dates[stamp] = {"job": str(result["job"]), "outcome": str(result["outcome"])}
            counted += 1
            if counted >= 2000:
                break
        clean["days"] = dates
    var active_value: Variant = raw.get("active", {})
    if typeof(active_value) == TYPE_DICTIONARY:
        var a: Dictionary = active_value
        var job: String = str(a.get("job", ""))
        var stage: String = str(a.get("stage", ""))
        var assigned_day: int = int(a.get("day", 0))
        if JOBS.has(job) and ["accepted", "carrying"].has(stage) and assigned_day >= 1 and not clean["days"].has("day:%d" % assigned_day):
            clean["active"] = {"job": job, "stage": stage, "day": assigned_day}
    clean["completed"] = clampi(int(raw.get("completed", 0)), 0, 2000)
    clean["worker_trust"] = clampi(int(raw.get("worker_trust", 0)), -12, 12)
    clean["safe_jobs"] = clampi(int(raw.get("safe_jobs", 0)), 0, 2000)
    clean["rushed_jobs"] = clampi(int(raw.get("rushed_jobs", 0)), 0, 2000)
    clean["refused_jobs"] = clampi(int(raw.get("refused_jobs", 0)), 0, 2000)
    return clean

static func accept(value: Variant, job: String, day: int) -> Dictionary:
    var record: Dictionary = sanitize(value)
    if not JOBS.has(job) or day < 1 or not record["active"].is_empty() or record["days"].has("day:%d" % day):
        return {}
    record["active"] = {"job": job, "day": day, "stage": "accepted"}
    return record

static func collect(value: Variant) -> Dictionary:
    var record: Dictionary = sanitize(value)
    var assignment: Dictionary = record["active"]
    if str(assignment.get("stage", "")) != "accepted":
        return {}
    assignment["stage"] = "carrying"
    record["active"] = assignment
    return record

static func complete(value: Variant, outcome: String, day: int) -> Dictionary:
    var record: Dictionary = sanitize(value)
    var active: Dictionary = record["active"]
    if not OUTCOMES.has(outcome) or str(active.get("stage", "")) != "carrying":
        return {}
    if day < int(active.get("day", 1)) or record["days"].has("day:%d" % day):
        return {}
    var id: String = str(active.get("job", ""))
    if not JOBS.has(id):
        return {}
    record["days"]["day:%d" % day] = {"job": id, "outcome": outcome}
    record["active"] = {}
    record["completed"] = mini(2000, int(record["completed"]) + 1)
    match outcome:
        "careful":
            record["safe_jobs"] = mini(2000, int(record["safe_jobs"]) + 1)
            record["worker_trust"] = clampi(int(record["worker_trust"]) + 2, -12, 12)
        "rush":
            record["rushed_jobs"] = mini(2000, int(record["rushed_jobs"]) + 1)
            record["worker_trust"] = clampi(int(record["worker_trust"]) - 3, -12, 12)
        "refuse":
            record["refused_jobs"] = mini(2000, int(record["refused_jobs"]) + 1)
            record["worker_trust"] = clampi(int(record["worker_trust"]) + 1, -12, 12)
    return record

static func pays(outcome: String, neighborhood_trust: int) -> int:
    if outcome == "refuse" or not OUTCOMES.has(outcome):
        return 0
    var neighborhood_delta: int = 2 if neighborhood_trust >= 3 else (-2 if neighborhood_trust <= -3 else 0)
    return maxi(0, BASE_PAY + (RUSH_BONUS if outcome == "rush" else 0) + neighborhood_delta)

static func neighborhood_reply(value: Variant) -> String:
    var record: Dictionary = sanitize(value)
    var trust: int = int(record["worker_trust"])
    if trust >= 4:
        return "Workshop foremen remember that your careful service protects their crews."
    if trust <= -4:
        return "The crews remember dangerous shortcuts. They don't trust your promises."
    if trust > 0:
        return "Workers have noticed some of your responsible choices."
    if trust < 0:
        return "The local workshops are becoming wary of your reputation."
    return "These crews are still learning what sort of worker you are."

static func stage_label(value: Variant) -> String:
    var active: Dictionary = sanitize(value)["active"]
    if active.is_empty():
        return "No active workshop shift"
    return "%s / %s / assigned on day %d" % [
        job_label(str(active["job"])), str(active["stage"]), int(active["day"])]
