extends Node3D
const Ward = preload("res://systems/magnara_expansion_rules_v071.gd")
const Older = preload("res://systems/magnara_stream_rules_v067.gd")
const Waves = preload("res://systems/ocean_hydrodynamics_v071.gd")
const Commerce = preload("res://systems/margerina_commerce_rules_v071.gd")
const Hydro = preload("res://world/janoah_waterways_v056.gd")

func _ready() -> void:
    call_deferred("_validate")

func _fail(s: String) -> void:
    push_error("V0.71 CITY OCEAN COMMERCE RULES FAILED: "+s)
    get_tree().call_deferred("quit",1)

func _validate() -> void:
    var cells: Array[Vector2i] = Ward.all_cells()
    if cells.size() != 30 or Ward.totals()["new_buildings"] != 180 \
            or Ward.totals()["new_named_game_only_civilians"] != 360:
        _fail("expanded thirty cell massing population budget not met")
        return
    var people: Dictionary = {}
    var buildings: Dictionary = {}
    var household_count: Dictionary = {}
    var rooftop_count: int = 0
    for cell in cells:
        if not Ward.allowed(cell) or Older.allowed(cell):
            _fail("new ward overwrites established old Ring II tile")
            return
        if Ward.nearby(Ward.center(cell)).size() > Ward.MAX_ACTIVE:
            _fail("more than nine active iPhone chunk candidates")
            return
        for slot in range(Ward.PARCELS):
            var p: Dictionary = Ward.parcel(cell,slot)
            if p.is_empty() or buildings.has(p["id"]) or p.get("canon_status","") != "game_only_massing":
                _fail("building parcels don't keep reproducible unique IDs and noncanon status")
                return
            buildings[p["id"]] = true
            if p != Ward.parcel(cell,slot) or float(p["height"]) < 5.0:
                _fail("building shape unstable across chunk unload")
                return
            rooftop_count += 1
        for i in range(Ward.PEOPLE):
            var citizen: Dictionary = Ward.resident(cell,i)
            if citizen.is_empty() or people.has(citizen["id"]) \
                    or citizen.get("kind","") != "game_only" or not citizen.get("secret_powers",[]).is_empty():
                _fail("duplicate or hidden named canon figures generated among public NPCs")
                return
            people[citizen["id"]] = true
            household_count[str(citizen["household"])] = true
            var state: Dictionary = Ward.resident_state(cell,i,590.0)
            if str(state.get("household","")) != str(citizen["household"]):
                _fail("scheduled worker discarded their family identity")
                return
            if state != Ward.resident_state(cell,i,590.0):
                _fail("NPC positions change on reload despite fixed world clock")
                return
            if Ward.lod(19.0,true) != "close" or Ward.lod(62.0,true) != "mid" \
                    or Ward.lod(102.0,true) != "far":
                _fail("original 20/100 meter crowd budget changed")
                return
    if buildings.size() != 180 or people.size() != 360 \
            or household_count.size() != 120 or rooftop_count != 180:
        _fail("180 urban shells, 360 civilians or 120 households incomplete")
        return
    if Ward.allowed(Vector2i(2,9)) or Ward.allowed(Vector2i(-3,3)):
        _fail("expansion leaked into unapproved ward/country")
        return
    if Ward.origin(Vector2i(0,5)).z != 1360.0 or Ward.origin(Vector2i(2,2)).x != 256.0:
        _fail("new streets don't connect to old northern Ring II")
        return
    if Older.MAX_COL != 1 or Older.MAX_ROW != 4 or Older.PARCELS_PER_CHUNK != 6:
        _fail("V0.67 original residential streaming geometry changed")
        return

    var registry: Dictionary = Commerce.registry()
    if not Commerce.valid_registry(registry):
        _fail("creator-known water atlas or public trade constraints invalid")
        return
    var water_names: Dictionary = {}
    for w in registry.get("waters",[]):
        water_names[str(w["id"])] = w
    if not water_names.has("lake_lukka") or water_names["lake_lukka"].get("nation","") != "Africanus" \
            or not water_names.has("emerald_river") or not water_names.has("janoah_sea"):
        _fail("water atlas lost Lake Lukka, an unplaced river, or Janoah Sea")
        return
    if water_names["emerald_river"].get("nation","unplaced") != null:
        _fail("unassigned Emerald River was fabricated into a country's river")
        return
    if water_names["abyssal_ocean"].get("physical_map_status","") != "not_in_known_world_playable":
        _fail("Abyssal Ocean made playable before authorized story")
        return
    if registry.get("harbors",[])[0]["military_access"] != "never_ambient_civilians":
        _fail("Iron Cothon protected military basin leaked to civilian shipping")
        return
    for i in range(Commerce.SHIP_COUNT):
        var manifest: Dictionary = Commerce.ship_manifest(i,1,registry)
        if manifest.get("status","") != "game_only_trade_preview" \
                or bool(manifest.get("arrives_at_nation",true)):
            _fail("hypothetical shipping declared canonical foreign-country arrivals")
            return
        if Waves.ship_class(str(manifest["size"])).is_empty():
            _fail("small/medium/large vessel hydrodynamic hull missing")
            return
        var day_state: Dictionary = Commerce.ship_state(i,70.0,1,registry)
        if day_state.is_empty() or not day_state.has("pos"):
            _fail("merchant vessel has no stable public cargo schedule")
            return
        if day_state != Commerce.ship_state(i,70.0,1,registry):
            _fail("shipping manifests differ between scene reloads")
            return
    for i in range(Commerce.WAGON_COUNT):
        if Commerce.wagon_state(i,50,1,registry).get("real_foreign_border_crossing",true):
            _fail("freight convoy traverses nonexistent established national border")
            return

    var mild: Dictionary = Waves.weather(300.0)
    var rough: Dictionary = Waves.weather(3000.0)
    if mild.is_empty() or rough.is_empty() or mild.get("game_only_weather",false) != true:
        _fail("daytime game-only weather isn't deterministic")
        return
    if Waves.wave_strength(470.0,0.75) <= Waves.wave_strength(-320.0,0.75)*2.0:
        _fail("offshore sea waves do not increase beyond coastal sheltered water")
        return
    if Waves.wave_strength(350.0,0.90) <= Waves.wave_strength(350.0,0.20):
        _fail("storm strength does not alter ocean wave amplitude")
        return
    var before: float = Waves.surface_height(70,55,1.0,0.7)
    var after: float = Waves.surface_height(70,55,4.0,0.7)
    if is_equal_approx(before,after):
        _fail("the 3 harmonic wave field isn't time animated")
        return
    if not is_equal_approx(Waves.surface_normal(0,0,5,0.5).length(),1.0):
        _fail("waves do not generate physical tilt normals")
        return
    var float_data: Dictionary = Waves.buoyancy(15,16,12,0.62,6.5,25)
    if int(float_data.get("samples",0)) != 4 or absf(float(float_data.get("pitch_rad",100))) > 0.23 \
            or absf(float(float_data.get("roll_rad",100))) > 0.27:
        _fail("buoyancy lacks bounded four-point vessel pitch/roll")
        return
    if not Waves.in_ocean_tile(0,0) or Waves.in_ocean_tile(850,0):
        _fail("wave simulation leaks outside 1 km scenic tile")
        return
    if not is_equal_approx(Waves.river_surface_y(0,0,0), Hydro.WATER_SURFACE_Y_M):
        _fail("river water surface not aligned with established V0.56 bridge heights")
        return
    if is_equal_approx(Waves.river_surface_y(10,20,0),Waves.river_surface_y(10,20,8)):
        _fail("river has no directional flow animation")
        return
    if absf(Waves.river_surface_y(11,17,4)+1.75) > 0.055:
        _fail("river ripple exceeds existing bridge safety clearance")
        return
    if Commerce.public_summary(1,18,registry).get("unlocked_beyond_abyssal",true):
        _fail("trade simulation unlocked forbidden beyond-line travel")
        return
    print("V0.71 THIRTY NEW STREAMED MAGNARA BLOCKS 360 NPC HOUSEHOLDS WEATHER OCEAN RIVER LAKE REGISTRY PUBLIC TRADE RULES PASS")
    get_tree().call_deferred("quit",0)
