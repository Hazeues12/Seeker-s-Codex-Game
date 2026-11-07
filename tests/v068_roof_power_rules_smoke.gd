extends Node3D
const Roof = preload("res://systems/magnara_roof_rules_v068.gd")
const Streets = preload("res://systems/magnara_stream_rules_v067.gd")
const Power = preload("res://systems/seeker_power_rules_v068.gd")
const OldTraining = preload("res://systems/seven_spokes_training.gd")

func _ready() -> void:
    call_deferred("_test")

func _fail(message: String) -> void:
    push_error("V0.68 ROOF AND POWER RULES FAILED: " + message)
    get_tree().call_deferred("quit", 1)

func _test() -> void:
    var count: int = 0
    var per_chunk_max: int = 0
    var all_routes: Dictionary = {}
    for x in range(Streets.MIN_COL, Streets.MAX_COL + 1):
        for row in range(Streets.MIN_ROW, Streets.MAX_ROW + 1):
            var cell := Vector2i(x, row)
            var pieces: Array[Dictionary] = Roof.roof_routes(cell)
            count += 1
            per_chunk_max = maxi(per_chunk_max, pieces.size())
            if pieces.size() < 25 or pieces.size() > Roof.MAX_PARKOUR_PIECES_PER_CHUNK:
                _fail("physical parkour count not bounded or insufficient: " + Streets.key(cell))
                return
            if not Roof.height_differences_safe(cell):
                _fail("jump height gaps aren't possible on actual entrance stairs/roof-to-roof platforms")
                return
            var roof_count: int = 0
            var staircase_count: int = 0
            var bridge_count: int = 0
            for p in pieces:
                var id: String = str(p.get("id", ""))
                if id.is_empty() or all_routes.has(id) or str(p.get("canon_status", "")) != "game_only":
                    _fail("parkour piece ID unstable, duplicated, or falsely published")
                    return
                all_routes[id] = true
                var pos: Vector3 = p.get("local_position", Vector3.ZERO)
                var dims: Vector3 = p.get("size", Vector3.ZERO)
                if dims.x <= 1.5 or dims.z <= 1.5 or pos.y < 0.5:
                    _fail("rooftop step too small to be physically landable")
                    return
                match str(p.get("kind", "")):
                    "roof":
                        roof_count += 1
                    "stair":
                        staircase_count += 1
                    "bridge":
                        bridge_count += 1
                    _:
                        _fail("no material for unknown roof module")
                        return
            if roof_count != Streets.PARCELS_PER_CHUNK or staircase_count < 8 or bridge_count < 8:
                _fail("roof decks, street-to-roof access, or interbuilding hop route missing")
                return
            if Roof.roof_routes(cell) != pieces:
                _fail("parkour layout changes after unload/reload")
                return
    if count != 15 or per_chunk_max > Roof.MAX_PARKOUR_PIECES_PER_CHUNK:
        _fail("full but bounded 15-cell rooftop plan lost")
        return
    if not Roof.roof_routes(Vector2i(9,9)).is_empty():
        _fail("unauthorized city/world gets procedural parkour")
        return
    if not Roof.jump_hint(Vector2i.ZERO, 0).to_lower().contains("double-jump"):
        _fail("mobile controls guidance for roof hops missing")
        return

    var catalog: Dictionary = Power.load_catalog()
    if not Power.valid_catalog(catalog):
        _fail("invalid Soul/Aura/Muti/Technique metadata or sealed ability cast permissions")
        return
    var technique: Dictionary = Power.technique_by_id(catalog, "martial_pulse_v034")
    var soul: Dictionary = Power.create_model("local_seeker_alpha")
    if soul.is_empty() or soul.get("soul", {}).get("essence_id", "") != "local_seeker_alpha":
        _fail("Soul component didn't preserve irreducible game-only identity")
        return
    if soul.get("aura", {}).get("current", -1) != 100.0 or soul.get("aura", {}).get("output", -1) != 24.0:
        _fail("Bucket and Tap aren't independent values")
        return
    if Power.required_cost(technique, 1.0) != 12 or Power.required_cost(technique, 0.8) != 15:
        _fail("Aura control/purity doesn't alter waste in a deterministic model")
        return
    var allowed: Dictionary = Power.attempt(soul, technique)
    if not bool(allowed.get("allowed", false)) or int(allowed.get("cost", -1)) != 12:
        _fail("ordinary Martial prototype no longer casts for original 12 Aura")
        return
    var result: Dictionary = Power.commit_cast(soul, allowed)
    if result.get("aura", {}).get("current", 0) != 88.0 or soul.get("aura", {}).get("current", 0) != 100.0:
        _fail("casting Aura isn't deducted from copy or mutated original")
        return
    result = Power.recover(result, 2.0)
    if result.get("aura", {}).get("current", 0) != 97.0:
        _fail("separate Bucket recovery doesn't obey recovery per second")
        return
    if not Power.create_model("",100).is_empty():
        _fail("soul without identity was accepted")
        return
    var too_weak: Dictionary = Power.create_model("local", 10.0)
    if str(Power.attempt(too_weak, technique).get("reason", "")) != "aura_low":
        _fail("low Aura actor can cast expensive skills")
        return
    var blocked: Dictionary = Power.create_model("local", 100, 100, 6.0)
    if str(Power.attempt(blocked, technique).get("reason", "")) != "output_low":
        _fail("Tap limit didn't stop excessive technique output")
        return
    blocked = Power.create_model("local",100,100,24,4.5,1.0,["Elemental"])
    if str(Power.attempt(blocked, technique).get("reason", "")) != "spoke_missing":
        _fail("Muti proficiency isn't checked by basic Martial technique")
        return
    for index in range(Power.TRAINING_ORDER.size()):
        var spoke: String = Power.TRAINING_ORDER[index]
        var metadata: Dictionary = Power.technique_by_id(catalog, Power.training_technique_for(spoke))
        var old: Dictionary = OldTraining.specification(index)
        if metadata.is_empty() or str(metadata.get("cast_policy", "")) != "supervised_only":
            _fail("supervised training metadata missing Seven Spoke: " + spoke)
            return
        if int(metadata.get("aura_cost", 0)) != int(old.get("cost", -2)):
            _fail("V0.46 cost differs from new Aura metadata")
            return
        if bool(Power.attempt(soul, metadata, false).get("allowed", false)):
            _fail("supervised-only Spoke can be permanently mastered outside yard")
            return
        if not bool(Power.attempt(soul, metadata, true).get("allowed", false)):
            _fail("public Seven Spokes practice was blocked for Spoke: " + spoke)
            return
    var bodhi: Dictionary = Power.technique_by_id(catalog, "bodhi_palm")
    if bodhi.is_empty() or bool(Power.attempt(soul, bodhi, true).get("allowed", false)):
        _fail("Kai's canonical Bodhi Palm leaked as beginner playable Art")
        return
    var ocular: Dictionary = Power.technique_by_id(catalog, "viatra_stage_ii")
    if bool(Power.attempt(soul, ocular, true).get("allowed", false)):
        _fail("Rin's ocular stage can be unlocked at the public sparring yard")
        return
    if bool(Power.authored_eye_preview(technique,"player","Migeika",true).get("authorized", false)):
        _fail("unauthorized Migeika user could copy techniques")
        return
    if bool(Power.authored_eye_preview(ocular,"rin_kairo","Viatra_II",true).get("authorized", false)):
        _fail("private ocular technique could be parsed as public enemy attack")
        return
    if not bool(Power.authored_eye_preview(technique,"rin_kairo","Viatra_II",true).get("authorized", false)):
        _fail("scripted Rin eye observation lacks public attack telemetry")
        return
    var exercise: Dictionary = Power.supervised_domain(catalog,"training_output_field")
    if exercise.is_empty() or not Power.supervised_domain(catalog,"pale_desert").is_empty():
        _fail("authored domain leaked or practice sub-frame unavailable")
        return
    var active_output: float = Power.aura_output_at(soul,exercise,Vector3.ZERO,Vector3(3,0,0),true)
    var ordinary: float = Power.aura_output_at(soul,exercise,Vector3.ZERO,Vector3(20,0,0),true)
    if not is_equal_approx(active_output, 18.0) or not is_equal_approx(ordinary, 24.0):
        _fail("Ryōiki-like practice override spread outside local 8m zone")
        return
    if Power.aura_output_at(soul,exercise,Vector3.ZERO,Vector3.ZERO,false) != 24.0:
        _fail("unlicensed world physics overridden outside training")
        return
    var day_pulse: Dictionary = Power.public_local_pulse(480.0, {"day:1:lebells":2,"day:1:avicci":1,"day:2:lebells":7})
    if int(day_pulse.get("observed_shop_units_today", -1)) != 3 or str(day_pulse.get("tola_exchange_rate", "")) != "unverified_not_simulated":
        _fail("public world pulse fabricated currency rates or doesn't read local trade ledger")
        return
    if str(day_pulse.get("red_order_influence", "")) != "not_publicly_reported":
        _fail("private antagonist influence exposed through city bulletin")
        return

    print("V0.68 FIFTEEN PHYSICAL ROOF ROUTES SOUL AURA MUTI TECHNIQUE SEVEN SPOKES PRIVATE STORY GATES PASS")
    get_tree().call_deferred("quit", 0)
