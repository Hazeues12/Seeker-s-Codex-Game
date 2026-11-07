extends Node3D
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const City = preload("res://systems/magnara_seven_ring_rules_v074.gd")
const Visual = preload("res://systems/magnara_published_city_visual_rules_v076.gd")
const Port = preload("res://systems/magnara_port_geography_v0731.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("V0.76 LIVE SOURCE CANON VISUAL RULES FAILED: "+message)
    get_tree().call_deferred("quit",1)

func _json(path: String) -> Dictionary:
    var f := FileAccess.open(path,FileAccess.READ)
    if f == null:
        return {}
    var value: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    return value if typeof(value)==TYPE_DICTIONARY else {}

func _run() -> void:
    var canon: Dictionary = Visual.audit_registry()
    var atlas: Dictionary = _json("res://data/magnara_atlas_v052.json")
    var world: Dictionary = _json("res://data/known_world_v054.json")
    if not Visual.correct_source_registry(canon) or atlas.is_empty() \
            or world.is_empty():
        _fail("published serial and project lore references not audited before building")
        return
    if not str(canon["sources"][0]["url"]).contains("royalroad.com") \
            or not str(canon["sources"][1]["url"]).contains("royalroad.com"):
        _fail("the Magnara zoning does not link directly to published chapters")
        return
    var names: Array[String] = ["CENTRAL CORE","SEEKER QUARTERS",
        "THE COMMONS","THE ACADEMIES","THE MARKETS",
        "UNASSIGNED","IRON COTHON"]
    for index in range(7):
        var a: Dictionary = atlas["rings"][index]
        var row: Dictionary = world["magnara"]["ring_specs"][index]
        if int(row["ring"]) != index+1 \
                or Visual.role(index+1) != Visual.REGION_ROLES[index]:
            _fail("ring schema mismatch with new source audit")
            return
        if index in [2,3,4,6] and not str(a["name"]).to_upper().contains(names[index]):
            _fail("older incorrectly-named Ring %d survived the published source audit" % (index+1))
            return
        if index==5 and (str(a["name"])!="<null>" and a["name"]!=null):
            _fail("Ring VI was given an invented published role")
            return
    if not Geo.RING_NAMES[2].contains("COMMONS") \
            or not Geo.RING_NAMES[3].contains("ACADEMIES") \
            or not Geo.RING_NAMES[4].contains("MARKETS") \
            or not City.ring_title(3).contains("COMMONS") \
            or not City.ring_title(4).contains("ACADEMIES") \
            or not City.ring_title(5).contains("MARKETS") \
            or Port.MAJOR_SEAPORT_RING != 7:
        _fail("runtime city map still incorrectly calls IV merchant or V purely foundry")
        return

    var regions: Dictionary = {}
    var urban_shapes: int = 0
    var parks: int = 0
    var domes: int = 0
    var awnings: int = 0
    var gantries: int = 0
    var radii: Array[float] = [560.0,1700.0,3550.0,
        5500.0,7570.0,9610.0,11780.0]
    for i in range(7):
        var ring: int = i+1
        var angle: float = 1.30 if ring==2 else 0.0
        var distance: float = radii[i]
        var center: Vector3 = Vector3(Geo.CITY_CENTER.x+distance*cos(angle),
            0.0,Geo.CITY_CENTER.y+distance*sin(angle))
        if City.ring_at(center) != ring:
            _fail("sample outside actual 26km ring footprint")
            return
        var tile: Vector2i = Geo.tile_index(center)
        var ring_lawn: int = 0
        var ring_dome: int = 0
        var ring_awning: int = 0
        var ring_port: int = 0
        for x in range(-1,2):
            for z in range(-1,2):
                var cell := tile+Vector2i(x,z)
                var info: Dictionary = Visual.tile_art(cell)
                if info!=Visual.tile_art(cell):
                    _fail("a ring changed its neighborhoods between two visits")
                    return
                var total: int = Visual.visible_count(cell)
                if total > Visual.MAX_ART_PER_TILE:
                    _fail("newly-authored generic art exceeds phone tile GPU budget")
                    return
                for part in ["boxes","domes","parks"]:
                    for item in info[part]:
                        if (item["size"] as Vector3).length() <= 0.1:
                            _fail("invalid decorative building or park geometry")
                            return
                var st: Dictionary = info["stats"]
                ring_lawn += int(st["commons_lawns"])
                ring_dome += int(st["academy_glass"])
                ring_awning += int(st["market_awnings"])
                ring_port += int(st["outer_ring_gantries"])
                urban_shapes += total
        regions[ring] = {"lawns":ring_lawn,"domes":ring_dome,
            "awnings":ring_awning,"port_silhouette":ring_port}
        parks += ring_lawn
        domes += ring_dome
        awnings += ring_awning
        gantries += ring_port
        if ring==3 and ring_lawn < 3:
            _fail("Ring III Commons doesn't show open green spaces")
            return
        if ring==4 and ring_dome < 6:
            _fail("Ring IV Academies don't contain glass dome rooflines")
            return
        if ring==5 and ring_awning < 50:
            _fail("Ring V Markets don't show dense street commerce awnings")
            return
        if ring==7 and ring_port < 4:
            _fail("Ring VII Iron Cothon lacks an outer-port industrial silhouette")
            return
        if ring in [1,2,6] and (ring_lawn>0 or ring_dome>0 \
                or ring_awning>0 or ring_port>0):
            _fail("the visual renderer invented published identities in unassigned or preserved rings")
            return
    if regions.size()!=7 or urban_shapes < 180 or parks < 3 \
            or domes < 6 or awnings < 50 or gantries < 4:
        _fail("city still appears as identical basic boxes across seven rings")
        return
    var old_tile: Vector2i = Geo.tile_index(Vector3(0,0,70))
    if Visual.visible_count(old_tile)>0:
        _fail("new art overwrote the original physical Seeker Quarter")
        return
    if City.geometry_report()["deepwater_main_port_ring"] != 7 \
            or Visual.style_for_ring(7).get("has_actual_coastline",true) \
            or Visual.style_for_ring(7).get("authored_named_sites_placed",1)!=0:
        _fail("false deepwater port or unapproved author coordinates invented")
        return
    for pending in canon.get("future_ideas_review",[]):
        if pending.get("decision","") == "implemented":
            _fail("unverified NPC faction wars, aura debuffs, Tola batches or Rin stances were activated")
            return
    print("V0.76 PUBLISHED MAGNARA CHAPTER CANON RING III COMMONS IV ACADEMIES V MARKETS VII COTHON 26KM LOD VISUALS PASS")
    get_tree().call_deferred("quit",0)
