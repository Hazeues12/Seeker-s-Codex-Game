extends Node3D
const Rules = preload("res://systems/magnara_stream_rules_v067.gd")
const OldRegistry = preload("res://systems/character_population_rules_v065.gd")

func _ready() -> void:
    call_deferred("_verify")

func _fail(message: String) -> void:
    push_error("V0.67 MODULAR CITY RULES FAILED: " + message)
    get_tree().call_deferred("quit", 1)

func _verify() -> void:
    var count: int = 0
    var identities: Dictionary = {}
    var buildings: Dictionary = {}
    for x in range(Rules.MIN_COL, Rules.MAX_COL + 1):
        for z in range(Rules.MIN_ROW, Rules.MAX_ROW + 1):
            var cell := Vector2i(x, z)
            if not Rules.allowed(cell):
                _fail("valid cell rejected")
                return
            count += 1
            var c: Vector3 = Rules.center(cell)
            if Rules.chunk_for(c) != cell:
                _fail("tile->world coordinate inverse missing")
                return
            for n in range(Rules.PARCELS_PER_CHUNK):
                var b: Dictionary = Rules.parcel(cell, n)
                if b.is_empty() or b != Rules.parcel(cell, n):
                    _fail("city kit generated inconsistent building after unload/reload")
                    return
                if str(b.get("canon_status", "")) != "game_only_massing":
                    _fail("procedural residential cuboid promoted to published canon")
                    return
                if float(b["width"]) <= 15.0 or float(b["depth"]) <= 15.0 or int(b["floors"]) < 1 or int(b["floors"]) > 4:
                    _fail("invalid modular block geometry or floor variation")
                    return
                # Cross avenues at z=0 and z=128 remain clear of footprints.
                var zc: float = (b["center"] as Vector3).z
                if zc - float(b["depth"]) * 0.5 < 12.0 or zc + float(b["depth"]) * 0.5 > 116.0:
                    _fail("modular house obstructs cross street")
                    return
                buildings[str(b["id"])] = true
            var people: Array[Dictionary] = Rules.residents(cell)
            if people.size() != Rules.RESIDENTS_PER_CHUNK:
                _fail("per-block population count invalid")
                return
            for i in range(people.size()):
                var actor: Dictionary = people[i]
                if not Rules.can_render_canonical(actor):
                    _fail("procedural civilian isn't marked game-only")
                    return
                if actor.has("spoke") or actor.has("rank") or actor.has("ocular_lineage") or not actor.get("secret_powers", []).is_empty():
                    _fail("random unapproved rank / power given to civilian")
                    return
                var id: String = str(actor.get("id", ""))
                if identities.has(id) or id.is_empty() or actor != Rules.person(cell, i):
                    _fail("NPC ID/identity changed with same region/time seed")
                    return
                identities[id] = true
                var noon: Dictionary = Rules.person_state(cell, i, 790.0)
                var later: Dictionary = Rules.person_state(cell, i, 1030.0)
                if noon.is_empty() or later.is_empty() or str(noon.get("activity", "")) == "unknown":
                    _fail("person didn't get independent day schedule")
                    return
                if noon != Rules.person_state(cell, i, 790.0):
                    _fail("NPC schedule not deterministic across unloading")
                    return
                var loc: Vector3 = noon.get("world_position", Vector3.ZERO)
                var chunk_start: Vector3 = Rules.origin(cell)
                if loc.x < chunk_start.x - 15.0 or loc.x > chunk_start.x + 15.0 or loc.z < chunk_start.z or loc.z > chunk_start.z + Rules.TILE_M:
                    _fail("person leaves their assigned road/sidewalk")
                    return
    if count != 15 or buildings.size() != 90 or identities.size() != 75:
        _fail("expected bounded 15-chunk 90-building 75-resident plan missing")
        return
    var own: Array[Vector2i] = Rules.preferred_cells(Vector3(0.0, 1.0, 992.0))
    if own.size() > Rules.ACTIVE_CAP or own.size() != 9:
        _fail("3x3 city world partition isn't bounded to at most 9 chunks")
        return
    for tile in own:
        if not Rules.allowed(tile):
            _fail("wanted list includes out-of-range city tile")
            return
    if not Rules.preferred_cells(Vector3(0,1,1700)).is_empty() or not Rules.preferred_cells(Vector3(0,1,0)).is_empty():
        _fail("distant city remains allocated despite player leaving partition")
        return
    for invalid in [Vector2i(0, -2), Vector2i(0, 5), Vector2i(2, 0), Vector2i(-2, 0)]:
        if Rules.allowed(invalid) or not Rules.parcel(invalid, 0).is_empty():
            _fail("world allocated outside approved geographic prototype")
            return
    if Rules.lod(19.999) != "close" or Rules.lod(20.001) != "mid" or Rules.lod(100.0) != "mid" or Rules.lod(100.1) != "far":
        _fail("close/mid/far thresholds drifted from requested crowd LOD")
        return
    if Rules.lod(0.0, false) != "far" or Rules.lod(INF) != "far":
        _fail("dormant actors don't de-spawn or bad distances aren't guarded")
        return
    if Rules.MODULE_TYPES.size() != 6 or not Rules.MODULE_TYPES.has("balcony") or not Rules.MODULE_TYPES.has("awning"):
        _fail("ground/middle/roof/awning/balcony/window Lego set missing")
        return
    var roster: Dictionary = OldRegistry.load_registry()
    if not OldRegistry.valid_roster(roster):
        _fail("published character and 31-civilian registry damaged")
        return
    if Rules.can_render_canonical(OldRegistry.find_actor(roster, "rin_kairo")) or Rules.can_render_canonical(OldRegistry.find_actor(roster, "seizen_kairo")):
        _fail("Rin and Seizen cannot be procedural ambient people")
        return
    print("V0.67 FIFTEEN STABLE STREAM CHUNKS NINETY MODULAR BUILDINGS SEVENTY-FIVE SCHEDULED CIVILIANS LOD RULES PASS")
    get_tree().call_deferred("quit", 0)
