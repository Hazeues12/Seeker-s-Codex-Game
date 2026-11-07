extends RefCounted
# V0.75: Ring-first streets and civic scale; zero new named landmarks.
# Corridors are hypothetical 1:1 city-planning connections, never
# approved compass bearings, public character roles or shipping routes.
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const City = preload("res://systems/magnara_seven_ring_rules_v074.gd")
const PATH_WIDTH_M: float = 6.75
const MAIN_TILE_PATH_WIDTH_M: float = 10.0
const FOOTPATH_WIDTH_M: float = 1.18
const STREET_SEGMENT_M: float = 32.0
const STREET_LINES: Array[float] = [
    -128.0,-112.0,-84.0,-56.0,-28.0,0.0,28.0,
    56.0,84.0,112.0,128.0
]
const ROAD_RENDER_Y: float = 0.592
const ROAD_ACCENT_Y: float = 0.600
const MAX_NEAR_STREET_CHUNKS: int = 9
const MAX_JUNCTION_MARKERS: int = 5
const JUNCTION_REACH_M: float = 820.0
const JUNCTION_APPROACH_GAP_M: float = 24.0
const MAX_ROOF_CROWN_PER_TILE: int = 64
const MAX_WINDOW_BAYS_PER_TILE: int = 128
const FAR_SILHOUETTE_BONUS: float = 0.0
const STREET_COLOR: Color = Color(0.43,0.46,0.48)
const PEDESTRIAN_COLOR: Color = Color(0.66,0.65,0.60)
const SCALE_TICK_M: float = 1000.0
const STYLES: Array[String] = [
    "plaster parapet", "stacked masonry", "sloped rooflet",
    "upper arcade", "smaller pitched canopy", "industrial skylight"
]

static func street_width(line: float) -> float:
    return MAIN_TILE_PATH_WIDTH_M if absf(line) >= 127.99 or absf(line) < 0.01 \
        else PATH_WIDTH_M

static func allowed_segment(world_at: Vector3) -> bool:
    var ring: int = City.ring_at(world_at)
    return ring > 0 and not City.protected_existing_ward(world_at) \
        and Geo.radial_m(world_at) < City.CITY_RADIUS_M - 1.0

static func street_specs(tile: Vector2i) -> Array[Dictionary]:
    # Slice streets in 32m runs. The exclusion prevents laying a false
    # grid over V0.33→V0.73 physically authored Ring II quarters.
    # Each boundary lane matches its next 256m neighbor; no dead end.
    var results: Array[Dictionary] = []
    var center: Vector3 = Geo.tile_center(tile)
    for line in STREET_LINES:
        var width: float = street_width(line)
        for i in range(8):
            var walking: float = -112.0+float(i)*STREET_SEGMENT_M
            var ns: Vector3 = center+Vector3(line,0,walking)
            var ew: Vector3 = center+Vector3(walking,0,line)
            if allowed_segment(ns):
                results.append({"world_pos":ns,"local_pos":Vector3(line,0,walking),
                    "half":STREET_SEGMENT_M*0.5,
                    "dims":Vector3(width,0.0,STREET_SEGMENT_M),
                    "axis":"north_south","tint":STREET_COLOR,
                    "major_crossroad":width > 7.0})
            if allowed_segment(ew):
                results.append({"world_pos":ew,"local_pos":Vector3(walking,0,line),
                    "half":STREET_SEGMENT_M*0.5,
                    "dims":Vector3(STREET_SEGMENT_M,0.0,width),
                    "axis":"east_west","tint":STREET_COLOR,
                    "major_crossroad":width > 7.0})
    return results

static func local_road_to_grid(world_at: Vector3) -> Dictionary:
    # Local walking axes are 28m apart between 8x8 V0.74 parcels.
    # These positions are game-only survey corridors; no fantasy
    # country-wide travel or invented canals.
    var tile: Vector2i = Geo.tile_index(world_at)
    var center: Vector3 = Geo.tile_center(tile)
    var dx: float = world_at.x-center.x
    var dz: float = world_at.z-center.z
    var nearest_x: float = 999.0
    var nearest_z: float = 999.0
    for line in STREET_LINES:
        nearest_x = minf(nearest_x,absf(dx-line))
        nearest_z = minf(nearest_z,absf(dz-line))
    return {"tile":tile,"near_north_south_lane":nearest_x,
        "near_east_west_lane":nearest_z,
        "walkable_base_terrain":City.ring_at(world_at)>0,
        "excluded_published_ward":City.protected_existing_ward(world_at)}

static func facade_type(tile: Vector2i,slot: int,ring: int) -> int:
    return City.stable(tile,slot+ring*307,STYLES.size())

static func rooftops(tile: Vector2i) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for parcel in City.tile_slots(tile):
        var id: String = str(parcel["id"])
        var segments: PackedStringArray = id.split(":")
        var slot: int = int(segments[3]) if segments.size()==4 else 0
        var style: int = facade_type(tile,slot,int(parcel["ring"]))
        var pos: Vector3 = parcel["local_pos"]
        var width: float = float(parcel["width"])
        var depth: float = float(parcel["depth"])
        var h: float = float(parcel["height"])
        var rise: float = 0.85+float(style%3)*0.55
        var shade: Color = (parcel["palette"] as Color).darkened(0.18)
        if int(parcel["ring"]) >= 5:
            rise *= 1.6
        var addon_size: Vector3 = Vector3(
            width*0.74 if style % 2 == 0 else width*0.38,
            rise,
            depth*0.74 if style % 2 == 0 else depth*0.66)
        result.append({"at":pos+Vector3(0,0.58+h+rise*0.5,0),
            "size":addon_size,"color":shade,
            "style":STYLES[style],"id":id,"ring":parcel["ring"]})
    return result

static func street_facades(tile: Vector2i) -> Array[Dictionary]:
    # Different bands and optional street-facing awnings break the
    # previous identical cube rhythm. All pieces are GPU exterior art,
    # not extra physics blocking local streets.
    var result: Array[Dictionary] = []
    for parcel in City.tile_slots(tile):
        var pos: Vector3 = parcel["local_pos"]
        var h: float = float(parcel["height"])
        var depth: float = float(parcel["depth"])
        var width: float = float(parcel["width"])
        var base: Color = parcel["palette"]
        var type_id: int = facade_type(tile,int(str(parcel["id"]).split(":")[3]),
            int(parcel["ring"]))
        var sill: float = minf(h-1.5,6.0+float(type_id%3)*2.2)
        result.append({"at":pos+Vector3(0,sill,depth*0.5+0.15),
            "size":Vector3(width*0.84,0.32,0.32),
            "color":(base as Color).darkened(0.23)})
        result.append({"at":pos+Vector3(0,3.35,depth*0.5+0.62),
            "size":Vector3(width*0.70,0.34,1.03),
            "color":(base as Color).lightened(0.11)})
    return result

static func junction(ring: int, spoke: int) -> Dictionary:
    if ring < 1 or ring > 7 or spoke < 0 or spoke >= City.RADIAL_COUNT:
        return {}
    var radius: float = Geo.OUTER_BOUNDS_M[ring-1]-36.0
    var a: float = City.radial_angle(spoke)
    var axis: Vector3 = Vector3(cos(a),0.0,sin(a))
    var center: Vector3 = Vector3(Geo.CITY_CENTER.x,0.0,Geo.CITY_CENTER.y)
    return {"id":"street_v075_junction_%d_%02d" % [ring,spoke],
        "ring":ring,"spoke":spoke,
        "world_pos":center+axis*radius,
        "sign_world":center+axis*radius+
            Vector3(-axis.z,0,axis.x)*JUNCTION_APPROACH_GAP_M,
        "public_title":"RING %d / AVENUE %02d" % [ring,spoke+1],
        "map_scale_m":radius,
        "port_reserve_only":ring==7,
        "no_canon_address":true,"physical_ocean_dock":false}

static func junction_near(point: Vector3) -> Array[Dictionary]:
    var found: Array[Dictionary] = []
    for ring in range(1,8):
        for spoke in range(City.RADIAL_COUNT):
            var spec: Dictionary = junction(ring,spoke)
            if (spec["world_pos"] as Vector3).distance_to(point) <= JUNCTION_REACH_M:
                found.append(spec)
    found.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
        return (a["world_pos"] as Vector3).distance_squared_to(point) <
            (b["world_pos"] as Vector3).distance_squared_to(point))
    return found.slice(0,MAX_JUNCTION_MARKERS)

static func manifest() -> Dictionary:
    return {"version":75,"city":"Magnara",
        "seven_city_rings":7,"radial_avenues":City.RADIAL_COUNT,
        "radial_ring_crossings":7*City.RADIAL_COUNT,
        "near_tile_street_segments_max":STREET_LINES.size()*8*2,
        "local_street_lane_width_m":PATH_WIDTH_M,
        "additional_rooftop_shapes_per_tile_cap":MAX_ROOF_CROWN_PER_TILE,
        "physical_landmarks_placed":0,"physical_port_docks_placed":0,
        "no_author_coordinates_inferred":true,
        "map_exploration_development_phase":"city_first"}
