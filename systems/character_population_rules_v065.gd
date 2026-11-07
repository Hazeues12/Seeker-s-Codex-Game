extends RefCounted
# V0.65: deterministic time-of-day NPC behaviors. Canon biographies belong in
# seeker_character_registry_v065.json; these schedules are GAME-ONLY staging.
const REGISTRY: String = "res://data/seeker_character_registry_v065.json"
const PHASE: String = "trial_week_open_world_parallel"
const MAX_EVENTS_PER_ACTOR: int = 128
const MAX_ACTORS: int = 256
const PUBLIC_SPAWN_POLICIES: Array[String] = ["boar_staff", "trial_week_boar"]
const DAILY_CHOICES: Array[String] = ["listen", "help", "dismiss"]
const ROAD_X: Array[float] = [-62.0, 0.0, 62.0]
const CROSS_Z: Array[float] = [301.0, 344.0, 423.0, 480.0, 548.0, 618.0, 658.0, 692.0]
const POINTS: Dictionary = {
    "market_square": Vector3(0.0, 0.83, 305.0),
    "market_provisions": Vector3(-26.0, 0.83, 293.0),
    "market_textiles": Vector3(26.0, 0.83, 293.0),
    "market_hardware": Vector3(-26.0, 0.83, 325.0),
    "market_lodging": Vector3(0.0, 0.83, 346.0),
    "worker_row": Vector3(-62.0, 0.83, 274.0),
    "townhouse_row": Vector3(62.0, 0.83, 340.0),
    "inn_public": Vector3(-62.0, 0.83, 423.0),
    "civic_records": Vector3(62.0, 0.83, 423.0),
    "clinic_public": Vector3(62.0, 0.83, 480.0),
    "guild_entry": Vector3(0.0, 0.83, 551.0),
    "guild_hall": Vector3(-30.0, 0.83, 553.0),
    "workshops_west": Vector3(-62.0, 0.83, 224.0),
    "civic_square": Vector3(0.0, 0.83, 480.0),
    "south_canal": Vector3(62.0, 0.83, 224.0),
    "shop_lebells": Vector3(-62.0, 0.83, 620.0),
    "shop_avicci": Vector3(62.0, 0.83, 650.0),
    "shop_vernal": Vector3(-62.0, 0.83, 686.0)
}

static func load_registry() -> Dictionary:
    var file := FileAccess.open(REGISTRY, FileAccess.READ)
    if file == null:
        return {}
    var decoder := JSON.new()
    var code: int = decoder.parse(file.get_as_text())
    file.close()
    if code != OK or typeof(decoder.data) != TYPE_DICTIONARY:
        return {}
    var data: Dictionary = decoder.data
    if int(data.get("schema_version", 0)) != 1:
        return {}
    return data

static func at_anchor(key: String) -> Vector3:
    return POINTS.get(key, Vector3.ZERO)

static func valid_roster(data: Variant) -> bool:
    if typeof(data) != TYPE_DICTIONARY:
        return false
    var root: Dictionary = data
    if int(root.get("schema_version", 0)) != 1:
        return false
    var names: Variant = root.get("canon_cast", [])
    var civilians: Variant = root.get("civilian_roster", [])
    if typeof(names) != TYPE_ARRAY or typeof(civilians) != TYPE_ARRAY:
        return false
    var seen: Dictionary = {}
    for actor in names + civilians:
        if typeof(actor) != TYPE_DICTIONARY:
            return false
        var id: String = str(actor.get("id", ""))
        if id.is_empty() or seen.has(id) or id.length() > 64:
            return false
        seen[id] = true
        if str(actor.get("kind", "")) == "canon":
            if not ["registry_only", "boar_staff", "trial_week_boar", "scripted_only", "never_ambient"].has(str(actor.get("spawn_policy", ""))):
                return false
            if typeof(actor.get("personality", [])) != TYPE_ARRAY or typeof(actor.get("equipment", [])) != TYPE_ARRAY:
                return false
        elif str(actor.get("kind", "")) == "game_only":
            for key in ["home_anchor", "work_anchor", "leisure_anchor"]:
                if not POINTS.has(str(actor.get(key, ""))):
                    return false
            if actor.has("rank") or actor.has("ocular_power") or actor.has("rare_muti"):
                return false
        else:
            return false
    if seen.size() > MAX_ACTORS:
        return false
    return true

static func can_ambient_spawn(actor: Variant, scenario: String = PHASE) -> bool:
    if typeof(actor) != TYPE_DICTIONARY:
        return false
    if str(actor.get("kind", "")) == "game_only":
        return true
    if str(actor.get("kind", "")) != "canon" or scenario != PHASE:
        return false
    if str(actor.get("public_visibility", "")) != "public":
        return false
    return PUBLIC_SPAWN_POLICIES.has(str(actor.get("spawn_policy", ""))) and str(actor.get("scene_venue", "")) == "talking_boar"

static func find_actor(root: Dictionary, id: String) -> Dictionary:
    for key in ["canon_cast", "civilian_roster"]:
        for data in root.get(key, []):
            if str(data.get("id", "")) == id:
                return data
    return {}

static func day(minutes: float) -> int:
    return maxi(1, floori(maxf(0.0, minutes) / 1440.0) + 1)

static func local_minutes(minutes: float) -> float:
    return fposmod(maxf(0.0, minutes), 1440.0)

static func _road_x(point: Vector3) -> float:
    var best: float = ROAD_X[0]
    for x in ROAD_X:
        if absf(point.x - x) < absf(point.x - best):
            best = x
    return best

static func _cross_at(a: Vector3, b: Vector3) -> float:
    var mid: float = (a.z + b.z) * 0.5
    var best: float = CROSS_Z[0]
    for z in CROSS_Z:
        if absf(z - mid) < absf(best - mid):
            best = z
    return best

static func street_path(a_key: String, b_key: String) -> Array[Vector3]:
    var start: Vector3 = at_anchor(a_key)
    var target: Vector3 = at_anchor(b_key)
    if start == target:
        return [start]
    var ax: float = _road_x(start)
    var bx: float = _road_x(target)
    var cross: float = _cross_at(start, target)
    # Follow public road spines + east-west avenues. No arbitrary movement
    # through closed canonical landmarks or invisible long-range teleport.
    return [
        start,
        Vector3(ax, start.y, start.z),
        Vector3(ax, start.y, cross),
        Vector3(bx, target.y, cross),
        Vector3(bx, target.y, target.z),
        target
    ]

static func path_position(a_key: String, b_key: String, progress: float) -> Vector3:
    var path: Array[Vector3] = street_path(a_key, b_key)
    if path.is_empty():
        return Vector3.ZERO
    if path.size() == 1:
        return path[0]
    var lengths: Array[float] = []
    var total: float = 0.0
    for i in range(1, path.size()):
        var segment: float = path[i - 1].distance_to(path[i])
        lengths.append(segment)
        total += segment
    if total < 0.001:
        return path[path.size() - 1]
    var traveled: float = clampf(progress, 0.0, 1.0) * total
    for i in range(lengths.size()):
        if traveled <= lengths[i] or i == lengths.size() - 1:
            return path[i].lerp(path[i + 1], clampf(traveled / maxf(0.0001, lengths[i]), 0.0, 1.0))
        traveled -= lengths[i]
    return path[path.size() - 1]

static func _phase(activity: String, point: String, visible: bool = true) -> Dictionary:
    return {"activity": activity, "anchor": point, "visible": visible, "moving": false}

static func _commute(label: String, from_point: String, to_point: String, amount: float) -> Dictionary:
    return {"activity": label, "anchor": to_point, "from": from_point, "progress": amount,
        "position": path_position(from_point, to_point, amount), "moving": true, "visible": true}

static func civilian_state(actor: Dictionary, minutes: float) -> Dictionary:
    if str(actor.get("kind", "")) != "game_only":
        return {}
    var t: float = local_minutes(minutes)
    var role: String = str(actor.get("role", ""))
    var shift: int = int(actor.get("shift_offset", 0))
    var night: bool = ["safety_watch", "inn_guest", "food_runner", "night_diner", "night_supply_runner"].has(role)
    # Night-shift NPCs follow the same eight-activity graph, six hours later.
    t = fposmod(t + float(shift) + (540.0 if night else 0.0), 1440.0)
    var home: String = str(actor.get("home_anchor", "worker_row"))
    var work: String = str(actor.get("work_anchor", "market_square"))
    var social: String = str(actor.get("leisure_anchor", "civic_square"))
    if t < 330.0:
        return _phase("home_sleep", home, false)
    if t < 465.0:
        return _commute("commute_to_work", home, work, (t - 330.0) / 135.0)
    if t < 720.0:
        return _phase("working_" + role, work)
    if t < 795.0:
        return _commute("meal_break_walk", work, social, (t - 720.0) / 75.0)
    if t < 860.0:
        return _phase("meal_break", social)
    if t < 935.0:
        return _commute("return_to_shift", social, work, (t - 860.0) / 75.0)
    if t < 1070.0:
        return _phase("working_" + role, work)
    if t < 1170.0:
        return _commute("evening_walk", work, social, (t - 1070.0) / 100.0)
    if t < 1240.0:
        return _phase("leisure", social)
    if t < 1380.0:
        return _commute("homeward", social, home, (t - 1240.0) / 140.0)
    return _phase("home_sleep", home, false)

static func canon_state(actor: Dictionary, minutes: float) -> Dictionary:
    if not can_ambient_spawn(actor):
        return {"activity": "offstage", "anchor": "", "visible": false, "moving": false}
    var id: String = str(actor.get("id", ""))
    var t: float = local_minutes(minutes)
    match id:
        "william_lockhart":
            if t < 420.0 or t >= 1320.0:
                return _phase("private_rest", "guild_hall", false)
            if t < 720.0:
                return _phase("guild_dispatch", "guild_hall")
            if t < 850.0:
                return _phase("mentor_checks", "guild_entry")
            if t < 1080.0:
                return _phase("professional_field_duty", "guild_entry", false)
            return _phase("evening_guild_fellowship", "guild_hall")
        "hanami":
            if t < 390.0 or t >= 1380.0:
                return _phase("off_duty", "guild_hall", false)
            if t < 1020.0:
                return _phase("guild_logistics_and_food", "guild_hall")
            return _phase("evening_hospitality", "guild_hall")
        "ven":
            if t < 420.0:
                return _phase("off_duty", "guild_hall", false)
            if t < 600.0:
                return _phase("morning_guild_coffee", "guild_hall")
            if t < 1200.0:
                return _phase("forgehouse_offsite", "guild_hall", false)
            if t < 1380.0:
                return _phase("guild_evening", "guild_hall")
            return _phase("rest", "guild_hall", false)
        "kai_xander":
            if t < 450.0 or t >= 1260.0:
                return _phase("offstage_rest", "guild_hall", false)
            if t < 660.0:
                return _phase("training", "guild_entry")
            if t < 840.0:
                return _phase("meal_and_guild", "guild_hall")
            if t < 1110.0:
                return _phase("story_mission", "guild_entry", false)
            return _phase("guild_evening", "guild_hall")
        "aria_flamehart":
            if t < 480.0 or t >= 1320.0:
                return _phase("offstage_rest", "guild_hall", false)
            if t < 720.0:
                return _phase("lightning_and_martial_drills", "guild_entry")
            if t < 1110.0:
                return _phase("independent_training", "guild_entry", false)
            return _phase("guild_evening", "guild_hall")
        "lila_butters":
            if t < 660.0 or t >= 1200.0:
                return _phase("family_rest", "guild_hall", false)
            if t < 870.0:
                return _phase("training_and_family_visits", "guild_entry", false)
            if t < 1020.0:
                return _phase("team_checkin", "guild_hall")
            return _phase("independent_water_training", "guild_entry", false)
    return {"activity": "unverified_schedule", "anchor": "", "visible": false, "moving": false}

static func state_for(actor: Dictionary, minutes: float) -> Dictionary:
    if str(actor.get("kind", "")) == "canon":
        return canon_state(actor, minutes)
    return civilian_state(actor, minutes)

static func empty_relationships() -> Dictionary:
    return {"version": 1, "actors": {}}

static func sanitize_relationships(raw: Variant) -> Dictionary:
    var cleaned: Dictionary = empty_relationships()
    if typeof(raw) != TYPE_DICTIONARY:
        return cleaned
    var source: Variant = raw.get("actors", {})
    if typeof(source) != TYPE_DICTIONARY:
        return cleaned
    for id in source.keys():
        var key: String = str(id)
        if not (key.begins_with("citizen_v065_") or ["kai_xander","aria_flamehart","lila_butters","william_lockhart","hanami","ven"].has(key)):
            continue
        var entry: Variant = source[id]
        if typeof(entry) != TYPE_DICTIONARY:
            continue
        var days: Dictionary = {}
        var choices: Variant = entry.get("days", {})
        if typeof(choices) == TYPE_DICTIONARY:
            var keys: Array = choices.keys()
            keys.sort()
            for stamp in keys:
                var name: String = str(stamp)
                if not name.begins_with("day:") or not name.trim_prefix("day:").is_valid_int():
                    continue
                if int(name.trim_prefix("day:")) < 1 or int(name.trim_prefix("day:")) > 1000000:
                    continue
                if not DAILY_CHOICES.has(str(choices[stamp])):
                    continue
                days[name] = str(choices[stamp])
                if days.size() >= MAX_EVENTS_PER_ACTOR:
                    break
        cleaned["actors"][key] = {"rapport": clampi(int(entry.get("rapport", 0)), -10, 10), "days": days}
        if cleaned["actors"].size() >= MAX_ACTORS:
            break
    return cleaned

static func rapport(value: Variant, id: String) -> int:
    var clean: Dictionary = sanitize_relationships(value)
    var actors: Dictionary = clean["actors"]
    return int(actors.get(id, {}).get("rapport", 0))

static func apply_choice(value: Variant, id: String, choice: String, target_day: int) -> Dictionary:
    if target_day < 1 or target_day > 1000000 or not DAILY_CHOICES.has(choice):
        return {}
    if not (id.begins_with("citizen_v065_") or ["kai_xander","aria_flamehart","lila_butters","william_lockhart","hanami","ven"].has(id)):
        return {}
    var clean: Dictionary = sanitize_relationships(value)
    var actors: Dictionary = clean["actors"]
    var npc: Dictionary = actors.get(id, {"rapport": 0, "days": {}})
    var memories: Dictionary = npc.get("days", {})
    var key: String = "day:%d" % target_day
    if memories.has(key):
        return {}
    npc["rapport"] = clampi(int(npc.get("rapport", 0)) + (2 if choice == "help" else (1 if choice == "listen" else -2)), -10, 10)
    memories[key] = choice
    npc["days"] = memories
    actors[id] = npc
    clean["actors"] = actors
    return clean

static func dialogue(actor: Dictionary, activity: String, relationship: int) -> String:
    var id: String = str(actor.get("id", ""))
    var opener: String = ""
    match id:
        "william_lockhart":
            opener = "There's always another duty, but the people in this city deserve some peace between them."
        "hanami":
            opener = "A full ledger, a hot meal, and rookies who actually listen. Two out of three would be wonderful."
        "ven":
            opener = "The workshop runs on tools and patience. We can usually find more tools."
        "kai_xander":
            opener = "Magnara keeps surprising me. The roads feel different every time I walk them."
        "aria_flamehart":
            opener = "If your stance is sloppy, no amount of lightning will hide it."
        "lila_butters":
            opener = "People think water is easy until they try to hold it still."
        _:
            var role: String = str(actor.get("role", "local worker")).replace("_", " ")
            var persona: Array = actor.get("personality", [])
            var vibe: String = str(persona[0]) if not persona.is_empty() else "focused"
            opener = "I'm on my %s rounds. This city keeps a %s person busy." % [role, vibe]
    if relationship >= 3:
        return opener + "\nThey recognize you and speak more openly."
    if relationship <= -3:
        return opener + "\nThey remember your earlier disrespect and keep their distance."
    return opener + "\nCurrent routine: " + activity.replace("_", " ") + "."
