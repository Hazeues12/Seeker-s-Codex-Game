extends Node3D
const Origins = preload("res://systems/young_blood_origins_v058.gd")
const FILE_NAME: String = "user://v058_origins_smoke_only.json"

func _ready() -> void:
    call_deferred("_check")

func _fail(message: String) -> void:
    push_error("V0.58 ORIGIN RULES FAILED: " + message)
    get_tree().call_deferred("quit", 1)

func _check() -> void:
    if Origins.BACKGROUNDS.size() != 9 or Origins.TEMPERAMENTS.size() != 5 or Origins.TRAITS.size() != 8:
        _fail("Young Blood social origin / temperament / trait counts wrong")
        return
    if Origins.DISADVANTAGES.size() != 4 or Origins.PERKS.size() != 5:
        _fail("burden and perk roster missing")
        return
    if not Origins.sanitize({}).is_empty() or Origins.effects({})["tonic_price"] != 12:
        _fail("legacy saves no longer preserve original gameplay")
        return
    for origin in Origins.BACKGROUNDS:
        var possible: Dictionary = Origins.choose_once({}, origin, "patient", "quick_footed", [], [])
        if possible.is_empty() or not Origins.sanitize(possible) == possible:
            _fail("invalid social origin: " + origin)
            return
    for mood in Origins.TEMPERAMENTS:
        if Origins.choose_once({}, "rural_household", mood, "deep_reserves", [], []).is_empty():
            _fail("invalid temperament: " + mood)
            return
    for talent in Origins.TRAITS:
        if Origins.choose_once({}, "caravan_raised", "bold", talent, [], []).is_empty():
            _fail("trait is unavailable: " + talent)
            return
    if not Origins.choose_once({}, "fictitious_family", "patient", "quick_footed", [], []).is_empty():
        _fail("invented background accepted")
        return
    if not Origins.choose_once({}, "monastery_ward", "patient", "quick_footed", ["debt", "debt"], []).is_empty():
        _fail("duplicate disadvantage was accepted")
        return
    if not Origins.choose_once({}, "monastery_ward", "patient", "quick_footed", ["debt", "old_injury", "estranged"], []).is_empty():
        _fail("three disadvantages allowed")
        return
    if not Origins.choose_once({}, "monastery_ward", "patient", "quick_footed", [], ["roadwise", "strong_lungs"]).is_empty():
        _fail("unearned perk point allowed")
        return
    if not Origins.choose_once({}, "monastery_ward", "patient", "quick_footed", ["debt"], ["roadwise", "roadwise"]).is_empty():
        _fail("duplicate perk allowed")
        return
    var chosen: Dictionary = Origins.choose_once({},
        "dockworker_household", "bold", "reliable_worker",
        ["debt", "restless_sleep"], ["roadwise", "market_familiar", "courier_training"])
    if chosen.is_empty() or int(chosen["debt_tola"]) != 40:
        _fail("earned perks, debt and two burdens were not saved")
        return
    if not Origins.choose_once(chosen, "noble_dependent", "patient", "quiet_mind", [], []).is_empty():
        _fail("sealed original Seeker history was modified")
        return
    var effects: Dictionary = Origins.effects(chosen)
    if float(effects["stamina_regen_mult"]) >= 1.0 or float(effects["sprint_mult"]) <= 1.0:
        _fail("restless sleep and roadwise sprint have no practical effects")
        return
    if int(effects["tonic_price"]) != 10 or int(effects["courier_bonus"]) != 3:
        _fail("shop and courier modifiers are not tied to origin")
        return
    var payment: Dictionary = Origins.courier_payment(chosen, 8)
    if int(payment["gross"]) != 11 or int(payment["withheld"]) != 4 or int(payment["net"]) != 7:
        _fail("debt withholding or bonus payout calculation wrong")
        return
    if int(payment["origin"]["debt_tola"]) != 36:
        _fail("debt was not reduced after work")
        return
    var f := FileAccess.open(FILE_NAME, FileAccess.WRITE)
    if f == null:
        _fail("isolated origin storage unavailable")
        return
    f.store_string(JSON.stringify(payment["origin"]))
    f.close()
    f = FileAccess.open(FILE_NAME, FileAccess.READ)
    if f == null:
        _fail("origin JSON reload unavailable")
        return
    var loaded: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE_NAME))
    if Origins.sanitize(loaded) != payment["origin"]:
        _fail("debt or sealed origin lost on reload")
        return
    if int(Origins.effects(loaded)["tonic_price"]) != 10:
        _fail("loaded origin modifiers are inconsistent")
        return
    var body: Dictionary = Origins.choose_once({},
        "frontier_survivor", "steadfast", "deep_reserves", ["old_injury"], ["strong_lungs"])
    var stats: Dictionary = Origins.effects(body)
    if float(stats["stamina_limit"]) <= 100.0 or float(stats["stamina_limit"]) > 125.0:
        _fail("injury, strength and body stamina ceiling do not balance")
        return
    var perks: Dictionary = Origins.choose_once({},
        "merchant_household", "practical", "trade_sense", [], ["market_familiar"])
    if int(Origins.effects(perks)["tonic_price"]) != 7:
        _fail("merchant perks do not reach expected discount floor")
        return
    print("V0.58 YOUNG BLOOD ORIGINS CONSEQUENCES AND SAVE VALIDATION PASS")
    get_tree().call_deferred("quit", 0)
