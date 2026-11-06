extends RefCounted
# V0.58 - author-inspired original-Seeker background rules.
# Labels/bonuses are game-only proposals until the Young Blood JSX is audited.
# All costs and choices are deterministic; no canon lineage/power unlocks.
const BACKGROUNDS: Array[String] = [
    "monastery_ward", "guild_apprentice", "dockworker_household",
    "caravan_raised", "rural_household", "merchant_household",
    "noble_dependent", "frontier_survivor", "displaced_civilian"
]
const BACKGROUND_NAMES: Array[String] = [
    "Monastery Ward", "Guild Apprentice", "Dockworker Household",
    "Caravan Raised", "Rural Household", "Merchant Household",
    "Noble Dependent", "Frontier Survivor", "Displaced Civilian"
]
const TEMPERAMENTS: Array[String] = [
    "patient", "bold", "curious", "practical", "steadfast"
]
const TRAITS: Array[String] = [
    "quick_footed", "deep_reserves", "quiet_mind", "trade_sense",
    "steady_grip", "reliable_worker", "long_stride", "aura_listener"
]
const DISADVANTAGES: Array[String] = [
    "debt", "restless_sleep", "old_injury", "estranged"
]
const PERKS: Array[String] = [
    "roadwise", "steady_breath", "market_familiar", "strong_lungs",
    "courier_training"
]
const DEBT_INITIAL: int = 40
const MAX_DISADVANTAGES: int = 2

static func label(id: String) -> String:
    return id.replace("_", " ").capitalize()

static func build(background: String, temperament: String, trait: String,
        burdens: Array, perks: Array) -> Dictionary:
    if not BACKGROUNDS.has(background) or not TEMPERAMENTS.has(temperament) or not TRAITS.has(trait):
        return {}
    if burdens.size() > MAX_DISADVANTAGES or perks.size() > 3:
        return {}
    var burden_list: Array[String] = []
    var perk_list: Array[String] = []
    for value in burdens:
        var key: String = str(value)
        if not DISADVANTAGES.has(key) or burden_list.has(key):
            return {}
        burden_list.append(key)
    for value in perks:
        var key: String = str(value)
        if not PERKS.has(key) or perk_list.has(key):
            return {}
        perk_list.append(key)
    # One free perk point, plus one for each accepted disadvantage.
    if perk_list.size() > 1 + burden_list.size():
        return {}
    return {
        "version": 1,
        "status": "player_original_game_only",
        "background": background,
        "temperament": temperament,
        "trait": trait,
        "burdens": burden_list,
        "perks": perk_list,
        "debt_tola": DEBT_INITIAL if burden_list.has("debt") else 0
    }

static func sanitize(value: Variant) -> Dictionary:
    if typeof(value) != TYPE_DICTIONARY:
        return {}
    var d: Dictionary = value
    var burdens: Variant = d.get("burdens", [])
    var perks: Variant = d.get("perks", [])
    if typeof(burdens) != TYPE_ARRAY or typeof(perks) != TYPE_ARRAY:
        return {}
    var clean: Dictionary = build(str(d.get("background", "")),
        str(d.get("temperament", "")), str(d.get("trait", "")), burdens, perks)
    if clean.is_empty():
        return {}
    if clean["burdens"].has("debt"):
        clean["debt_tola"] = clampi(int(d.get("debt_tola", DEBT_INITIAL)), 0, DEBT_INITIAL)
    return clean

static func choose_once(previous: Variant, background: String, temperament: String,
        trait: String, burdens: Array, perks: Array) -> Dictionary:
    if not sanitize(previous).is_empty():
        return {}
    return build(background, temperament, trait, burdens, perks)

static func effects(value: Variant) -> Dictionary:
    var output: Dictionary = {
        "stamina_regen_mult": 1.0, "aura_regen_mult": 1.0,
        "stamina_limit": 100.0, "sprint_mult": 1.0,
        "tonic_price": 12, "courier_bonus": 0,
        "guard_discount": 0
    }
    var record: Dictionary = sanitize(value)
    if record.is_empty():
        return output
    match str(record["background"]):
        "monastery_ward": output["aura_regen_mult"] += 0.10
        "guild_apprentice": output["courier_bonus"] += 1
        "dockworker_household": output["stamina_regen_mult"] += 0.08
        "caravan_raised": output["sprint_mult"] += 0.035
        "rural_household": output["stamina_limit"] += 5.0
        "merchant_household": output["tonic_price"] -= 1
        "noble_dependent": output["guard_discount"] += 1
        "frontier_survivor": output["stamina_limit"] += 4.0
        "displaced_civilian": output["courier_bonus"] += 1
    match str(record["temperament"]):
        "patient": output["stamina_regen_mult"] += 0.05
        "bold": output["sprint_mult"] += 0.025
        "curious": output["aura_regen_mult"] += 0.05
        "practical": output["tonic_price"] -= 1
        "steadfast": output["stamina_limit"] += 3.0
    match str(record["trait"]):
        "quick_footed": output["sprint_mult"] += 0.065
        "deep_reserves": output["stamina_limit"] += 10.0
        "quiet_mind": output["aura_regen_mult"] += 0.17
        "trade_sense": output["tonic_price"] -= 1
        "steady_grip": output["guard_discount"] += 2
        "reliable_worker": output["courier_bonus"] += 2
        "long_stride": output["sprint_mult"] += 0.045
        "aura_listener": output["aura_regen_mult"] += 0.12
    var burdens: Array = record["burdens"]
    if burdens.has("restless_sleep"):
        output["stamina_regen_mult"] -= 0.17
    if burdens.has("old_injury"):
        output["stamina_limit"] -= 12.0
    if burdens.has("estranged"):
        output["tonic_price"] += 2
    if burdens.has("debt") and int(record["debt_tola"]) > 0:
        output["courier_bonus"] -= 1
    var perks: Array = record["perks"]
    if perks.has("roadwise"):
        output["sprint_mult"] += 0.045
    if perks.has("steady_breath"):
        output["stamina_regen_mult"] += 0.11
    if perks.has("market_familiar"):
        output["tonic_price"] -= 2
    if perks.has("strong_lungs"):
        output["stamina_limit"] += 7.0
    if perks.has("courier_training"):
        output["courier_bonus"] += 2
    output["stamina_regen_mult"] = clampf(float(output["stamina_regen_mult"]), 0.55, 1.5)
    output["aura_regen_mult"] = clampf(float(output["aura_regen_mult"]), 0.7, 1.5)
    output["stamina_limit"] = clampf(float(output["stamina_limit"]), 75.0, 125.0)
    output["sprint_mult"] = clampf(float(output["sprint_mult"]), 0.9, 1.20)
    output["tonic_price"] = clampi(int(output["tonic_price"]), 7, 17)
    output["courier_bonus"] = clampi(int(output["courier_bonus"]), -2, 5)
    output["guard_discount"] = clampi(int(output["guard_discount"]), 0, 4)
    return output

static func courier_payment(value: Variant, base_pay: int) -> Dictionary:
    var origin: Dictionary = sanitize(value)
    var bonus: int = int(effects(origin)["courier_bonus"])
    var gross: int = maxi(0, base_pay + bonus)
    var withheld: int = 0
    if not origin.is_empty() and (origin["burdens"] as Array).has("debt"):
        withheld = mini(int(origin["debt_tola"]), mini(4, gross))
        origin["debt_tola"] = int(origin["debt_tola"]) - withheld
    return {"net": gross - withheld, "gross": gross, "withheld": withheld,
            "origin": origin}

static func summary(value: Variant) -> String:
    var d: Dictionary = sanitize(value)
    if d.is_empty():
        return "Origin not registered"
    var descriptions: Array[String] = []
    for burden in d["burdens"]:
        descriptions.append(label(str(burden)))
    var penalties: String = "none" if descriptions.is_empty() else ", ".join(descriptions)
    return "%s / %s / %s | Burdens: %s | Debt %d Tola" % [
        label(str(d["background"])), label(str(d["temperament"])),
        label(str(d["trait"])), penalties, int(d["debt_tola"])
    ]
