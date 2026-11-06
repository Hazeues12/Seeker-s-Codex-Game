extends RefCounted
# Young Blood -> 3D Margerina: small, deterministic life-road kernel.
# Source: author's v385 Young Blood feature summary, not the absent JSX source.
const ROAD_EXAM: String = "exam"
const ROAD_SWORN: String = "sworn"
const ROAD_TRADE: String = "trade"
const ROADS: Array[String] = [ROAD_EXAM, ROAD_SWORN, ROAD_TRADE]
const NATIONS: Array[String] = [
    "Janoah", "Rajistan", "Chun", "Vinlan", "Britannia",
    "Germania", "Tsar Empire", "Zirael", "Africanus", "Americana"
]
const COURIER_PAY_TOLA: int = 8
const STAGES: Array[String] = ["idle", "accepted", "carrying"]

static func empty_record() -> Dictionary:
    return {}

static func sanitize(value: Variant) -> Dictionary:
    if typeof(value) != TYPE_DICTIONARY:
        return {}
    var record: Dictionary = value
    var road: String = str(record.get("road", ""))
    var nation: String = str(record.get("nation", ""))
    if not ROADS.has(road) or not NATIONS.has(nation):
        return {}
    var work: Dictionary = record.get("work", {}) if typeof(record.get("work", {})) == TYPE_DICTIONARY else {}
    var stage: String = str(work.get("stage", "idle"))
    if not STAGES.has(stage):
        stage = "idle"
    var clean: Dictionary = {
        "version": 1, "road": road, "nation": nation,
        "origin_status": "player_choice_game_only",
        "entry_day": clampi(int(record.get("entry_day", 1)), 1, 999999),
        "license": "prior_exam_game_only" if road == ROAD_SWORN else "unlicensed",
        "work": {
            "stage": stage if road == ROAD_TRADE else "idle",
            "active_day": clampi(int(work.get("active_day", -1)), -1, 999999),
            "paid_day": clampi(int(work.get("paid_day", -1)), -1, 999999),
            "completed": clampi(int(work.get("completed", 0)), 0, 100000),
        }
    }
    return clean

static func choose_path(previous: Variant, road: String, nation: String, day: int) -> Dictionary:
    if not sanitize(previous).is_empty() or not ROADS.has(road) or not NATIONS.has(nation) or day < 1:
        return {}
    return sanitize({
        "road": road, "nation": nation, "entry_day": day,
        "work": {"stage": "idle", "active_day": -1, "paid_day": -1, "completed": 0}
    })

static func can_take_seeker_contract(record: Variant) -> bool:
    var saved: Dictionary = sanitize(record)
    # Legacy Seeker profiles remain playable; choosing a trade disables
    # licensed Seeker contracts until official certification is implemented.
    return saved.is_empty() or str(saved.get("road", "")) != ROAD_TRADE

static func has_iron_license(record: Variant) -> bool:
    var saved: Dictionary = sanitize(record)
    return not saved.is_empty() and str(saved.get("road", "")) == ROAD_SWORN and str(saved.get("license", "")) == "prior_exam_game_only"

static func accept_courier_shift(value: Variant, day: int) -> Dictionary:
    var record: Dictionary = sanitize(value)
    if str(record.get("road", "")) != ROAD_TRADE:
        return {}
    var job: Dictionary = record["work"]
    if day < 1 or str(job["stage"]) != "idle" or int(job["paid_day"]) >= day:
        return {}
    job["stage"] = "accepted"
    job["active_day"] = day
    record["work"] = job
    return record

static func collect_parcel(value: Variant) -> Dictionary:
    var record: Dictionary = sanitize(value)
    if str(record.get("road", "")) != ROAD_TRADE:
        return {}
    var job: Dictionary = record["work"]
    if str(job["stage"]) != "accepted":
        return {}
    job["stage"] = "carrying"
    record["work"] = job
    return record

static func deliver_parcel(value: Variant, day: int) -> Dictionary:
    var record: Dictionary = sanitize(value)
    if str(record.get("road", "")) != ROAD_TRADE:
        return {}
    var job: Dictionary = record["work"]
    if day < int(job["active_day"]) or str(job["stage"]) != "carrying" or int(job["paid_day"]) >= day:
        return {}
    job["stage"] = "idle"
    job["paid_day"] = day
    job["completed"] = mini(100000, int(job["completed"]) + 1)
    record["work"] = job
    return record

static func path_label(road: String) -> String:
    match road:
        ROAD_EXAM: return "Take the Seeker Exam"
        ROAD_SWORN: return "Already Sworn (existing Iron licence)"
        ROAD_TRADE: return "Live a Trade (civilian)"
        _: return "Road not selected"

static func next_step(value: Variant) -> String:
    var record: Dictionary = sanitize(value)
    if record.is_empty():
        return "Visit the Magnara public life registrar to choose a road."
    match str(record["road"]):
        ROAD_EXAM: return "Seek training and the future examination chapters."
        ROAD_SWORN: return "Your backstory includes an existing Iron licence. Find honest contracts and build your record."
        ROAD_TRADE:
            var status: String = str(record["work"]["stage"])
            if status == "accepted":
                return "Pick up the civic courier parcel at the Public Quarter pickup."
            if status == "carrying":
                return "Deliver the parcel to the professional service counter."
            return "Visit the public life registrar for a civic courier shift."
    return "Your road continues."
