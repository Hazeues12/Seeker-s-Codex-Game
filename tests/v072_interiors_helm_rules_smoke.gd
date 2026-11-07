extends Node3D
const Ward = preload("res://systems/magnara_expansion_rules_v071.gd")
const Older = preload("res://systems/magnara_stream_rules_v067.gd")
const Interior = preload("res://systems/magnara_interiors_rules_v072.gd")
const Skiff = preload("res://systems/ocean_helm_rules_v072.gd")
const Waves = preload("res://systems/ocean_hydrodynamics_v071.gd")
const Commerce = preload("res://systems/margerina_commerce_rules_v071.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("V0.72 INTERIORS HELM RULES FAILED: "+message)
    get_tree().call_deferred("quit",1)

func _run() -> void:
    var ids: Dictionary = {}
    var citizen_ids: Dictionary = {}
    if Interior.VENUE_SLOT != 2 or Interior.VENUES_TOTAL != Ward.all_cells().size():
        _fail("doorway quantity is inconsistent with thirty public ward cells")
        return
    for cell in Ward.all_cells():
        var site: Dictionary = Interior.site(cell)
        if site.is_empty() or ids.has(site["id"]):
            _fail("duplicate or missing workroom id")
            return
        ids[site["id"]] = true
        if Older.allowed(cell) or site.get("canon_status","") != "game_only":
            _fail("invented public venue overlaps original canon block")
            return
        var parcel: Dictionary = Ward.parcel(cell,Interior.VENUE_SLOT)
        if site["parcel"] != parcel or not bool(site.get("open_ground_floor",false)):
            _fail("interior doesn't physically match current 3D building parcel")
            return
        var door: Vector3 = site["door_world"]
        if not Interior.allowed_distance(door+Vector3(0,0,2),cell) \
                or Interior.allowed_distance(door+Vector3(0,0,9),cell):
            _fail("walkable public doorway has wrong physical interaction reach")
            return
        var on: Dictionary = Interior.staff_schedule(cell,600.0)
        var off: Dictionary = Interior.staff_schedule(cell,1100.0)
        if not bool(on.get("on_shift",false)) or bool(off.get("on_shift",true)):
            _fail("original resident is scheduled both on and off work")
            return
        if not str(on["worksite"]) == str(site["id"]):
            _fail("worker loses stable original household worksite")
            return
        if citizen_ids.has(on["id"]):
            _fail("same citizen assigned to multiple workrooms")
            return
        citizen_ids[on["id"]] = true
        var street: Dictionary = Ward.resident_state(cell,Interior.STAFF_INDEX,600.0)
        if bool(street.get("visible",true)) or not bool(street.get("inside_public_venue",false)):
            _fail("one resident appears outside and inside simultaneously")
            return
        if str(street["id"]) != str(on["id"]) \
                or str(street["household"]) != str(on["household"]):
            _fail("new workroom invented a duplicate instead of sharing existing citizen identity")
            return
        if Interior.inventory_note(cell,3).get("tola_payout",1) != 0 \
                or Interior.inventory_note(cell,3).get("phantom_tola",true):
            _fail("game-only interior activity grants unverified Tola or restricted commerce")
            return
        if site != Interior.site(cell) or on != Interior.staff_schedule(cell,600.0):
            _fail("site and resident schedules don't survive deterministic chunk reload")
            return
    if ids.size() != 30 or citizen_ids.size() != 30 \
            or not Interior.site(Vector2i(2,10)).is_empty():
        _fail("only the 30 public Ring II workrooms should be generated")
        return
    if Ward.totals()["new_buildings"] != 180 \
            or Ward.totals()["new_named_game_only_civilians"] != 360:
        _fail("v071 housing/population expansion was damaged")
        return

    var sea: Dictionary = Commerce.registry()
    if not Commerce.valid_registry(sea) or str(sea.get("scope","")) != "known_world_only":
        _fail("helm leaked outside approved public known-world sea")
        return
    if not Skiff.can_helm(Vector3.ZERO,Vector3(0,0,3.0),true,true) \
            or Skiff.can_helm(Vector3.ZERO,Vector3(0,0,15),true,true) \
            or Skiff.can_helm(Vector3.ZERO,Vector3.ZERO,false,true):
        _fail("helm control does not require proximity to an actual public boat")
        return
    var state: Dictionary = Skiff.default_state()
    if state["pos"] != Skiff.START or float(state["speed"]) != 0.0:
        _fail("a skiff appears underway before boarding")
        return
    var wind: Dictionary = Waves.weather(690.0)
    for n in range(62):
        var step: Dictionary = Skiff.advance(state,0.23,1.0,0.04,
            float(wind["wind_strength"]),float(wind["wind_direction_rad"]),
            float(n)*0.04)
        if step.is_empty():
            _fail("bounded weather-driven small-boat motion failed")
            return
        state = step
    if float(state["speed"]) < 1.0 or float(state["heading"]) <= 0.0 \
            or float((state["pos"] as Vector3).x) <= Skiff.START.x:
        _fail("wind skiff does not accelerate, turn and travel")
        return
    if int(state.get("wave_samples",0)) != 4 or not bool(state.get("free_player_movement",false)) \
            or str(state.get("canon_status","")) != "game_only_helm_trial":
        _fail("steering does not use four-point wave physics or permits secret cargo")
        return
    var calm: Dictionary = Skiff.advance(Skiff.default_state(),0,1,0.1,
        0.20,0.0,4.0)
    var rough: Dictionary = Skiff.advance(Skiff.default_state(),0,1,0.1,
        0.95,0.0,4.0)
    if calm.is_empty() or rough.is_empty() or \
            float(calm["offshore_strength"]) >= float(rough["offshore_strength"]):
        _fail("ocean wind does not change the actual hull's wave model")
        return
    var wake: Dictionary = Skiff.wake_point(state,3.0)
    if wake.is_empty() or Skiff.wake_alpha(wake,3.0) <= 0.0 \
            or Skiff.wake_alpha(wake,3.0+Skiff.WAKE_LIFE_SECONDS+0.1) > 0.0:
        _fail("moving skiff leaves no fading ocean wake")
        return
    var limit: Dictionary = Skiff.default_state()
    limit["pos"] = Vector3(456.5,0,0)
    limit["speed"] = Skiff.MAX_SPEED_MPS
    limit = Skiff.advance(limit,0,1,0.23,0.8,0.1,14.0)
    if limit.is_empty() or not bool(limit.get("boundary_reached",false)) \
            or absf(float((limit["pos"] as Vector3).x)) > Skiff.SAFE_INNER_BOUND \
            or float(limit["speed"]) != 0.0:
        _fail("the public game-only boat can sail into unloaded or forbidden ocean")
        return
    if not Skiff.advance(Skiff.default_state(),0,1,0.75,0.5,0,0).is_empty():
        _fail("unbounded time-step physics can tunnel through other vessels")
        return
    if Commerce.SHIP_COUNT != 6 or Commerce.WAGON_COUNT != 3 \
            or Waves.ship_class("small")["beam"] != Skiff.BEAM_M:
        _fail("previous protected commerce fleet's ship classes were corrupted")
        return
    print("V0.72 THIRTY ENTERABLE GROUND FLOORS SHARED NPC SHIFT STEERABLE WIND SKIFF FOUR POINT WATER WAKE AND SEA BOUNDS PASS")
    get_tree().call_deferred("quit",0)
