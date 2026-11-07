extends RefCounted
# V0.76 public-chapter-inspired city profiles. Only generic art here.
# Position of actual named parks, schools, bridges, workshops, naval
# berths, Steel Flame Tower and secret faction sites stays unassigned.
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const City = preload("res://systems/magnara_seven_ring_rules_v074.gd")
const AUDIT_PATH: String = "res://data/magnara_published_city_audit_v076.json"
const MAX_ART_PER_TILE: int = 180
const MAX_ACTIVE_ART_TILES: int = 9
const CANOPY_RADIUS_M: float = 5.5
const HAS_AUTHOR_COORDINATES: bool = false
const REGION_ROLES: Array[String] = [
    "core","seeker_quarters","commons","academies",
    "markets_and_workshops","unassigned","iron_cothon_outer_port"
]
const COMMONS_GRASS: Color = Color(0.40,0.58,0.39)
const COMMONS_CANOPY: Color = Color(0.28,0.50,0.33)
const ACADEMY_GLASS: Color = Color(0.44,0.75,0.83)
const MARKET_AWNINGS: Array[Color] = [
    Color(0.65,0.23,0.16),Color(0.33,0.45,0.63),
    Color(0.76,0.57,0.27),Color(0.51,0.34,0.55)
]
const PORT_INDUSTRY: Color = Color(0.41,0.49,0.50)

static func audit_registry() -> Dictionary:
    var raw := FileAccess.open(AUDIT_PATH,FileAccess.READ)
    if raw == null:
        return {}
    var payload: Variant = JSON.parse_string(raw.get_as_text())
    raw.close()
    return payload if typeof(payload) == TYPE_DICTIONARY else {}

static func correct_source_registry(data: Dictionary) -> bool:
    if str(data.get("checked_date","")) != "2026-11-07":
        return false
    if data.get("ring_identity",[]).size()!=7 or data.get("sources",[]).size()<3:
        return false
    for ring in range(1,8):
        var entry: Dictionary = data["ring_identity"][ring-1]
        if int(entry.get("ring",-1)) != ring:
            return false
    return str(data["ring_identity"][2].get("identity",""))=="THE COMMONS" \
        and str(data["ring_identity"][3].get("identity",""))=="THE ACADEMIES" \
        and str(data["ring_identity"][4].get("identity",""))=="THE MARKETS" \
        and str(data["ring_identity"][6].get("identity","")).contains("IRON COTHON") \
        and not HAS_AUTHOR_COORDINATES

static func role(ring: int) -> String:
    return REGION_ROLES[ring-1] if ring >= 1 and ring <= 7 else "outside_city"

static func style_for_ring(ring: int) -> Dictionary:
    return {"ring":ring,"role":role(ring),
        "exterior_type":"game_only_generic_massing",
        "authored_named_sites_placed":0,"project_planning_radius_only":true,
        "has_actual_coastline":false,"has_finished_npc_families":false}

static func _box(at: Vector3,size: Vector3,color: Color) -> Dictionary:
    return {"at":at,"size":size,"color":color}

# Ground beneath these pavers is the existing streamed walkable terrain.
static func _commons_court(at: Vector3, ground: Array[Dictionary],
        fixtures: Array[Dictionary]) -> void:
    var paving := Color(0.77, 0.70, 0.58)
    ground.append(_box(at + Vector3(0, 0.705, 0),
        Vector3(2.8, 0.02, City.BLOCK_GRID_M), paving))
    ground.append(_box(at + Vector3(0, 0.73, 0), Vector3(9.0, 0.02, 8.0), paving))
    for side in [-1.0, 1.0]:
        fixtures.append(_box(at + Vector3(side * 3.7, 0.88, 2.8),
            Vector3(0.5, 0.28, 1.7), Color(0.46, 0.30, 0.19)))
        fixtures.append(_box(at + Vector3(side * 3.7, 1.7, -2.8),
            Vector3(0.13, 2.35, 0.13), Color(0.43, 0.32, 0.22)))
        fixtures.append(_box(at + Vector3(side * 3.7, 3.0, -2.8),
            Vector3(0.42, 0.35, 0.42), Color(1.0, 0.84, 0.43)))

static func tile_art(tile: Vector2i) -> Dictionary:
    var boxes: Array[Dictionary] = []
    var domes: Array[Dictionary] = []
    var parks: Array[Dictionary] = []
    var stats: Dictionary = {"commons_lawns":0,"commons_canopies":0,"commons_courts":0,
        "academy_glass":0,"market_awnings":0,
        "outer_ring_gantries":0,"neutral_core_lots":0,
        "skipped_authored_ring_two":0}
    var center: Vector3 = Geo.tile_center(tile)
    # The intentionally unbuilt Commons plots become green courtyard
    # foundations. These are not real city-named parks or private estates.
    for ix in range(8):
        for iz in range(8):
            var slot: int = ix*8+iz
            var local := Vector3((float(ix)-3.5)*City.BLOCK_GRID_M,
                0.0,(float(iz)-3.5)*City.BLOCK_GRID_M)
            var world_at: Vector3 = center+local
            if City.ring_at(world_at) != 3 or not City.buildable(world_at):
                continue
            if City.stable(tile,slot+503,7) != 0:
                continue
            parks.append(_box(local+Vector3(0,0.615,0),
                Vector3(17.0,0.14,16.4),COMMONS_GRASS))
            stats["commons_lawns"] = int(stats["commons_lawns"])+1
            if City.stable(tile,slot+821,3) == 0:
                _commons_court(local, parks, boxes)
                stats["commons_courts"] += 1
            if City.stable(tile,slot+730,2) == 0:
                domes.append(_box(local+Vector3(-6.3,4.9,2.0),
                    Vector3(CANOPY_RADIUS_M*2.0,6.1,
                        CANOPY_RADIUS_M*2.0),COMMONS_CANOPY))
                boxes.append(_box(local+Vector3(-6.3,1.8,2.0),
                    Vector3(0.65,3.2,0.65),Color(0.44,0.38,0.27)))
                stats["commons_canopies"] = int(stats["commons_canopies"])+1
    # Keep actual archived public streets/shops completely untouched.
    for parcel in City.tile_slots(tile):
        var ring: int = int(parcel["ring"])
        var at: Vector3 = parcel["local_pos"]
        var height: float = float(parcel["height"])
        var width: float = float(parcel["width"])
        var depth: float = float(parcel["depth"])
        var id: String = str(parcel["id"])
        var key: PackedStringArray = id.split(":")
        var slot: int = int(key[3]) if key.size()==4 else 0
        if ring == 2:
            stats["skipped_authored_ring_two"] = int(stats["skipped_authored_ring_two"])+1
        elif ring == 4:
            # Authentic source: Ring IV academies have illuminated glass
            # domes. Their positions are provisional generic rooftops.
            if City.stable(tile,slot+900,4) == 0:
                var radius: float = minf(width,depth)*0.38
                domes.append(_box(at+Vector3(0,0.55+height+radius*0.19,0),
                    Vector3(radius*2.0,radius*1.45,radius*2.0),
                    ACADEMY_GLASS))
                stats["academy_glass"] = int(stats["academy_glass"])+1
        elif ring == 5:
            # Ring V publishes crowded markets AND forges. Painted
            # awnings imply street scale without inventing shop identities.
            var tint: Color = MARKET_AWNINGS[
                City.stable(tile,slot+577,MARKET_AWNINGS.size())]
            boxes.append(_box(at+Vector3(0,3.20,depth*0.5+1.0),
                Vector3(width*0.77,0.24,2.20),tint))
            stats["market_awnings"] = int(stats["market_awnings"])+1
        elif ring == 7:
            # Outer-port industrial silhouettes only. NO ship dock,
            # pier, customs office or military naval basin placed here.
            if City.stable(tile,slot+911,5) == 0:
                var column_height: float = 9.0+float(slot%3)*2.0
                boxes.append(_box(at+Vector3(0,0.55+height+column_height*0.5,0),
                    Vector3(0.85,column_height,0.85),PORT_INDUSTRY))
                boxes.append(_box(at+Vector3(3.2,0.55+height+column_height,0),
                    Vector3(7.2,0.75,0.90),PORT_INDUSTRY))
                stats["outer_ring_gantries"] = int(stats["outer_ring_gantries"])+1
        elif ring == 1 or ring == 6:
            stats["neutral_core_lots"] = int(stats["neutral_core_lots"])+1
    return {"tile":tile,"boxes":boxes,"domes":domes,"parks":parks,
        "stats":stats,"canon_status":"published_zone_game_only_parcel_positions",
        "named_landmarks_placed":0,"actual_harbor_docks":0,
        "source":AUDIT_PATH}

static func visible_count(tile: Vector2i) -> int:
    var art: Dictionary = tile_art(tile)
    return art["boxes"].size()+art["domes"].size()+art["parks"].size()
