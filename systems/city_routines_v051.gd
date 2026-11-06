extends RefCounted
# V0.51: deterministic game-only NPC duties and civic bulletin rules.
# Stored player history is never interpreted as official Seeker promotions.
const HOURS: Dictionary = {
    "npc_ring2_noodles": Vector2i(360, 1320),
    "npc_ring2_canal": Vector2i(420, 1260),
    "npc_ring2_register": Vector2i(480, 1200),
    "npc_ring2_medic": Vector2i(0, 1440),
    "npc_ring2_trainer": Vector2i(420, 1200),
    "npc_ring2_soulwright": Vector2i(480, 1140),
    "npc_ring2_sentry": Vector2i(0, 1440),
    "npc_vendor": Vector2i(420, 1200),
    "npc_canal": Vector2i(360, 1320),
    "npc_scout": Vector2i(0, 1440)
}
const OFFSETS: Array[Vector3] = [
    Vector3(0.0, 0.0, 0.0),
    Vector3(0.8, 0.0, 1.1),
    Vector3(-0.9, 0.0, 0.9),
    Vector3(0.3, 0.0, -1.1)
]

static func assignment(role: String, world_minutes: float) -> Dictionary:
    var minute: int = posmod(int(world_minutes), 1440)
    var shifts: Vector2i = HOURS.get(role, Vector2i(0, 1440))
    var at_work: bool = minute >= shifts.x and minute < shifts.y
    # Six-hour blocks are predictable: offscreen NPCs need no expensive AI.
    var block: int = mini(3, int(minute / 360))
    var duty: String = "patrolling" if role in ["npc_ring2_sentry", "npc_scout"] else "on duty"
    if role in ["npc_ring2_noodles", "npc_vendor"]:
        duty = "serving customers" if block in [1, 2] else "closing the stall"
    elif role in ["npc_ring2_canal", "npc_canal"]:
        duty = "checking the canal" if block in [1, 2] else "returning from the waterway"
    elif role == "npc_ring2_register":
        duty = "processing visitor records" if block < 3 else "finishing the desk shift"
    elif role == "npc_ring2_medic":
        duty = "on the medical watch" if block in [0, 3] else "teaching field recovery"
    elif role == "npc_ring2_trainer":
        duty = "leading team drills" if block in [1, 2] else "reviewing training"
    elif role == "npc_ring2_soulwright":
        duty = "reviewing public field notes"
    if not at_work:
        duty = "off shift"
    var offset: Vector3 = OFFSETS[block] if at_work else Vector3.ZERO
    # Deterministically stagger residents so the street doesn't move in lockstep.
    if role in ["npc_ring2_canal", "npc_ring2_soulwright", "npc_canal"]:
        offset.x *= -1.0
    return {"present": at_work, "offset": offset, "duty": duty, "block": block}

static func bulletin_context(day: int, civic_resolved: bool, expedition_complete: bool) -> String:
    if day < 1:
        return "routine"
    if expedition_complete and day % 2 == 1:
        return "expedition"
    if civic_resolved:
        return "canal"
    if expedition_complete:
        return "expedition"
    return "routine"

static func day_key(day: int) -> String:
    return "day_%d" % day

static func already_answered(saved: Variant, day: int) -> bool:
    if typeof(saved) != TYPE_DICTIONARY:
        return false
    var data: Dictionary = saved
    var days: Dictionary = data.get("days", {})
    return days.has(day_key(day))

static func response(saved: Variant, day: int, context: String, choice: String, verified: bool) -> Dictionary:
    if day < 1 or day > 999999 or not ["routine", "canal", "expedition"].has(context):
        return {}
    if not ["assist", "report", "shortcut"].has(choice):
        return {}
    if choice == "report" and not verified:
        return {}
    var previous: Dictionary = saved if typeof(saved) == TYPE_DICTIONARY else {}
    var next: Dictionary = previous.duplicate(true)
    var days: Dictionary = next.get("days", {})
    if days.has(day_key(day)):
        return {}
    var reputation: Dictionary = {}
    match choice:
        "assist":
            reputation = {"local_respect": 2, "guild_reliability": 1}
        "report":
            reputation = {"association_trust": 1, "guild_reliability": 1}
        "shortcut":
            reputation = {"association_trust": -2, "local_respect": -1, "underworld_attention": 2}
    days[day_key(day)] = {"context": context, "choice": choice}
    # Keep the last 90 daily entries: the permanent chronicle holds the narrative.
    if days.size() > 90:
        while days.size() > 90:
            var oldest: String = ""
            var oldest_num: int = 1000000
            for raw_key in days.keys():
                var candidate: int = int(str(raw_key).trim_prefix("day_"))
                if candidate < oldest_num:
                    oldest = str(raw_key)
                    oldest_num = candidate
            if oldest.is_empty():
                break
            days.erase(oldest)
    next["days"] = days
    next["version"] = 1
    return {"state": next, "reputation": reputation}
