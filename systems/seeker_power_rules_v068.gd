extends RefCounted
# V0.68 lore-conscious combat component layer.
# Soul -> Aura (Bucket and Tap) -> Muti -> Technique. GDScript is deliberate:
# Godot 4.4 owns deterministic 3D physics and existing Web/iPhone gameplay.
# The Archwheel's true function must NOT be encoded in public client logic.
const FILE: String = "res://data/seeker_power_components_v068.json"
const SPOKES: Array[String] = [
    "Elemental", "Martial", "Spirit", "Alchemy", "Psychic", "Spatial", "Abyssal"
]
const TRAINING_COSTS: Array[int] = [14, 20, 18, 22, 21, 24, 28]
const TRAINING_ORDER: Array[String] = [
    "Martial", "Elemental", "Spirit", "Alchemy", "Psychic", "Spatial", "Abyssal"
]
const MAX_AURA: float = 1000.0
const MAX_OUTPUT: float = 1000.0
const MAX_WILL: float = 100.0
const MAX_HISTORY: int = 128

static func load_catalog() -> Dictionary:
    var file := FileAccess.open(FILE, FileAccess.READ)
    if file == null:
        return {}
    var json := JSON.new()
    var error: int = json.parse(file.get_as_text())
    file.close()
    if error != OK or typeof(json.data) != TYPE_DICTIONARY:
        return {}
    return json.data

static func valid_catalog(value: Variant) -> bool:
    if typeof(value) != TYPE_DICTIONARY:
        return false
    var data: Dictionary = value
    if int(data.get("schema_version", 0)) != 1 or str(data.get("era", "")) != "1500 A.S.":
        return false
    if data.get("concepts", {}).get("power_chain", []) != ["Soul","Aura","Muti","Technique"]:
        return false
    var rows: Variant = data.get("techniques", [])
    if typeof(rows) != TYPE_ARRAY:
        return false
    var names: Dictionary = {}
    for technique in rows:
        if typeof(technique) != TYPE_DICTIONARY:
            return false
        var id: String = str(technique.get("id", ""))
        var policy: String = str(technique.get("cast_policy", ""))
        if id.is_empty() or names.has(id) or not ["public_basic","supervised_only","story_only"].has(policy):
            return false
        names[id] = true
        if typeof(technique.get("spokes", [])) != TYPE_ARRAY:
            return false
        for spoke in technique.get("spokes", []):
            if not SPOKES.has(str(spoke)):
                return false
        if policy == "story_only":
            if bool(technique.get("usable", true)) or technique.get("aura_cost", 0) != null:
                return false
        else:
            if not bool(technique.get("usable", false)) or typeof(technique.get("aura_cost", null)) != TYPE_INT:
                return false
            if int(technique.get("aura_cost", 0)) <= 0:
                return false
    if names.size() < 10:
        return false
    var items: Variant = data.get("items", [])
    if typeof(items) != TYPE_ARRAY:
        return false
    for relic in items:
        if typeof(relic) != TYPE_DICTIONARY or str(relic.get("gameplay_access", "")) != "story_only":
            return false
        if (relic.get("secret_tags", []) as Array).size() > 0:
            return false
    for entry in data.get("authored_domain_catalog", []):
        if str(entry.get("cast_policy", "")) != "story_only":
            return false
    return true

static func technique_by_id(catalog: Dictionary, id: String) -> Dictionary:
    for item in catalog.get("techniques", []):
        if str(item.get("id", "")) == id:
            return item
    return {}

static func training_technique_for(spoke: String) -> String:
    return "training_" + spoke.to_lower() if SPOKES.has(spoke) else ""

static func create_model(essence_id: String, current: float = 100.0,
        reserve: float = 100.0, output: float = 24.0,
        recovery: float = 4.5, purity: float = 1.0,
        granted_spokes: Array = ["Martial"]) -> Dictionary:
    var id: String = essence_id.strip_edges().substr(0, 64)
    if id.is_empty() or not is_finite(current) or not is_finite(reserve) or not is_finite(output) or not is_finite(recovery) or not is_finite(purity):
        return {}
    var accepted: Array[String] = []
    for spoke in granted_spokes:
        if SPOKES.has(str(spoke)) and not accepted.has(str(spoke)):
            accepted.append(str(spoke))
    return {
        "soul": {"essence_id": id, "will": 50.0, "continuity": 100.0,
            "public_identity_only": true},
        "aura": {
            "max_reserve": clampf(reserve, 1.0, MAX_AURA),
            "current": clampf(current, 0.0, clampf(reserve, 1.0, MAX_AURA)),
            "output": clampf(output, 0.0, MAX_OUTPUT),
            "recovery": clampf(recovery, 0.0, MAX_OUTPUT),
            "purity": clampf(purity, 0.50, 1.0),
            "stage": "basic_game_only",
            "source": "bucket_and_tap"
        },
        "muti": {
            "granted_spokes": accepted,
            "hybrid_access": false,
            "celestial_access": false,
            "ocular_access": false,
            "mastery": "basic_training_only"
        },
        "technique_history": []
    }

static func required_cost(technique: Dictionary, purity: float) -> int:
    if technique.is_empty() or str(technique.get("cast_policy", "story_only")) == "story_only":
        return -1
    return maxi(1, ceili(float(technique.get("aura_cost", 0)) / clampf(purity, 0.5, 1.0)))

static func supervised_domain(catalog: Dictionary, requested: String) -> Dictionary:
    for field in catalog.get("sandbox_domains", []):
        if str(field.get("id", "")) == requested and str(field.get("allowed_scope", "")) == "supervised_training_only":
            return field
    return {}

static func aura_output_at(model: Dictionary, domain: Dictionary,
        origin: Vector3, actor_at: Vector3, supervised: bool) -> float:
    var aura: Dictionary = model.get("aura", {})
    var tap: float = maxf(0.0, float(aura.get("output", 0.0)))
    if not supervised or domain.is_empty() or str(domain.get("canon_status", "")) != "game_only":
        return tap
    var radius: float = clampf(float(domain.get("radius_m", 0)), 0.0, 25.0)
    if actor_at.distance_to(origin) > radius:
        return tap
    var factor: float = clampf(float(domain.get("output_multiplier", 1.0)), 0.25, 1.0)
    return tap * factor

static func attempt(model: Dictionary, technique: Dictionary, supervised: bool = false,
        domain: Dictionary = {}, origin: Vector3 = Vector3.ZERO,
        actor_at: Vector3 = Vector3.ZERO) -> Dictionary:
    if technique.is_empty() or not model.has("soul") or not model.has("aura") or not model.has("muti"):
        return {"allowed": false, "reason": "invalid_components"}
    var policy: String = str(technique.get("cast_policy", "story_only"))
    if policy == "story_only" or not bool(technique.get("usable", false)):
        return {"allowed": false, "reason": "story_locked"}
    if policy == "supervised_only" and not supervised:
        return {"allowed": false, "reason": "yard_only"}
    var aura: Dictionary = model["aura"]
    var rights: Dictionary = model["muti"]
    if bool(rights.get("celestial_access", false)) or bool(rights.get("ocular_access", false)):
        # Story-gated powers never appear in this unlicensed sandbox.
        return {"allowed": false, "reason": "unverified_special_access"}
    if policy == "public_basic":
        for spoke in technique.get("spokes", []):
            if not rights.get("granted_spokes", []).has(str(spoke)):
                return {"allowed": false, "reason": "spoke_missing"}
    var cost: int = required_cost(technique, float(aura.get("purity", 1.0)))
    if cost < 0 or float(aura.get("current", 0.0)) < float(cost):
        return {"allowed": false, "reason": "aura_low", "cost": cost}
    var tap: float = aura_output_at(model, domain, origin, actor_at, supervised)
    if tap < float(technique.get("output_required", 0.0)):
        return {"allowed": false, "reason": "output_low", "cost": cost}
    return {"allowed": true, "reason": "supervised_simulation" if policy == "supervised_only" else "basic_martial",
        "cost": cost, "output": tap, "spokes": technique.get("spokes", []),
        "technique_id": str(technique.get("id", "")), "training_only": true}

static func commit_cast(model: Dictionary, verdict: Dictionary) -> Dictionary:
    if not bool(verdict.get("allowed", false)) or not model.has("aura"):
        return {}
    var updated: Dictionary = model.duplicate(true)
    var aura: Dictionary = updated["aura"]
    var cost: float = float(verdict.get("cost", -1))
    if cost < 0.0 or float(aura.get("current", 0.0)) < cost:
        return {}
    aura["current"] = float(aura["current"]) - cost
    updated["aura"] = aura
    var events: Array = updated.get("technique_history", [])
    events.append(str(verdict.get("technique_id", "training")))
    if events.size() > MAX_HISTORY:
        events.pop_front()
    updated["technique_history"] = events
    return updated

static func recover(model: Dictionary, seconds: float) -> Dictionary:
    if model.is_empty() or not model.has("aura") or not is_finite(seconds) or seconds < 0.0:
        return {}
    var updated: Dictionary = model.duplicate(true)
    var aura: Dictionary = updated["aura"]
    aura["current"] = minf(float(aura.get("max_reserve", 100.0)),
        float(aura.get("current", 0.0)) + float(aura.get("recovery", 0.0)) * seconds)
    updated["aura"] = aura
    return updated

static func authored_eye_preview(technique: Dictionary, owner: String, eye: String,
        story_permission: bool) -> Dictionary:
    # Actual Viatra/Migeika eyesight and stage effects require a scripted
    # narrative battle. Only public attack telemetry can be previewed here.
    if not story_permission or owner != "rin_kairo" or eye != "Viatra_II":
        return {"authorized": false}
    if technique.is_empty() or str(technique.get("cast_policy", "")) == "story_only":
        return {"authorized": false}
    return {"authorized": true, "startup_seconds": technique.get("startup_seconds", null),
        "trajectory": technique.get("trajectory", "unknown"),
        "signature_type": technique.get("signature_type", "unknown"),
        "does_not_pause_time": true, "does_not_copy_technique": true}

static func public_local_pulse(world_minutes: float, shop_stock: Variant) -> Dictionary:
    # Bounded public economic *observation*, not speculative continent-wide
    # exchange rates or covert faction occupation. No shop price overrides.
    var day: int = maxi(1, floori(maxf(0.0, world_minutes) / 1440.0) + 1)
    var hour: int = posmod(int(floorf(world_minutes / 60.0)), 24)
    var activity: String = "morning deliveries" if hour >= 5 and hour < 10 else (
        "shop trade and civic work" if hour >= 10 and hour < 17 else (
        "evening hospitality" if hour >= 17 and hour < 23 else "night shifts and rest"))
    var purchases: int = 0
    if typeof(shop_stock) == TYPE_DICTIONARY:
        for key in (shop_stock as Dictionary).keys():
            if str(key).begins_with("day:%d:" % day):
                var volume: Variant = (shop_stock as Dictionary)[key]
                if typeof(volume) == TYPE_INT or typeof(volume) == TYPE_FLOAT:
                    purchases += clampi(int(volume), 0, 36)
    return {"day": day, "hour": hour, "district": "Magnara / Ring Two",
        "public_activity": activity, "observed_shop_units_today": mini(purchases, 128),
        "tola_exchange_rate": "unverified_not_simulated",
        "red_order_influence": "not_publicly_reported",
        "archwheel_truth": "not_in_public_game_data",
        "canon_status": "public_game_only"}
