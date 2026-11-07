extends RefCounted
# V0.74 city-scale master plan, not detailed block-by-block lore.
# Seven concentric zones at existing 1:1 proposal (26 km diameter).
# The user explicitly requires complete seven-ring layout BEFORE placing
# further authored landmarks/docks. No coastline or seaport berths created.
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const Port = preload("res://systems/magnara_port_geography_v0731.gd")
const CITY_DIAMETER_M: float = 26000.0
const CITY_RADIUS_M: float = 13000.0
const RING_ROAD_WIDTH_M: float = 32.0
const RADIAL_ROAD_WIDTH_M: float = 28.0
const RADIAL_COUNT: int = 12
const CIRCUMFERENCE_SEGMENTS: int = 192
const LOCAL_GRID_M: float = 256.0
const BLOCK_GRID_M: float = 28.0
const INNER_CITY_START: float = 140.0
const CLOSE_COLLIDER_M: float = 88.0
const NEAR_CELL_RADIUS: int = 1
const MAX_NEAR_CELLS: int = 9
const LOAD_BUDGET: int = 3
const FAR_CELL_M: float = 512.0
const FAR_RADIUS: int = 3
const FAR_REFRESH_SECONDS: float = 0.92
const TICK_SECONDS: float = 0.45
const VIEWSHED_MIN: float = 440.0
const VIEWSHED_MAX: float = 1910.0
const PLOTS_PER_TILE: int = 64
const HOUSE_DIMENSION_MIN_M: float = 13.2
const HOUSE_DIMENSION_MAX_M: float = 20.5
const MAX_CLOSE_COLLIDERS: int = 34
const RING_COLORS: Array[Color] = [
    Color(0.70,0.67,0.60),Color(0.65,0.65,0.64),
    Color(0.64,0.59,0.53),Color(0.61,0.52,0.44),
    Color(0.53,0.52,0.50),Color(0.54,0.55,0.55),
    Color(0.52,0.51,0.47)
]
const PROPOSED_STYLE: Array[String] = [
    "UNASSIGNED CORE / GOVERNMENT SURVEY",
    "SEEKER QUARTERS / EXISTING PUBLIC WARDS",
    "RING III / UNASSIGNED CITY BLOCKS",
    "MERCHANT & BANKING DISTRICTS / BROAD ZONE ONLY",
    "FORGES & WORKSHOPS / BROAD ZONE ONLY",
    "RING VI / INFRASTRUCTURE RESERVE / UNASSIGNED",
    "OUTERMOST RING VII / IRON COTHON SEA PORT RESERVE"
]
const PHASE: String = "seven_ring_foundation_only_no_new_canon_places"

static func ring_at(point: Vector3) -> int:
    return Geo.ring_for_position(point)

static func ring_title(ring: int) -> String:
    if ring < 1 or ring > 7:
        return "OUTSIDE THE PROPOSED MAGNARA FOOTPRINT"
    return PROPOSED_STYLE[ring-1]

static func bounds(ring: int) -> Dictionary:
    if ring < 1 or ring > 7:
        return {}
    return {"ring":ring,
        "inner_m":0.0 if ring == 1 else Geo.OUTER_BOUNDS_M[ring-2],
        "outer_m":Geo.OUTER_BOUNDS_M[ring-1],
        "area_km2":Geo.ring_area_km2(ring),
        "status":"author_ring_seven_port_location_only" if ring == 7 \
            else "ring_two_local_published_area" if ring == 2 \
            else "unplaced_provisional_masterplan"}

static func radial_angle(n: int) -> float:
    return PI/float(RADIAL_COUNT) + TAU*float(n)/float(RADIAL_COUNT)

static func radial_distance_to_road(at: Vector3) -> float:
    var p := Vector2(at.x-Geo.CITY_CENTER.x,at.z-Geo.CITY_CENTER.y)
    var radius: float = p.length()
    if radius < INNER_CITY_START:
        return 999999.0
    var near: float = 999999.0
    for n in range(RADIAL_COUNT):
        var angle: float = radial_angle(n)
        var axis := Vector2(cos(angle),sin(angle))
        var projection: float = p.dot(axis)
        if projection >= INNER_CITY_START:
            near = minf(near,absf(p.cross(axis)))
    return near

static func ring_road_distance(at: Vector3) -> float:
    var r: float = Geo.radial_m(at)
    var closest: float = 999999.0
    for boundary in Geo.OUTER_BOUNDS_M:
        closest = minf(closest,absf(r-boundary))
    return closest

static func protected_existing_ward(at: Vector3) -> bool:
    # Already physically built hub/venue/ward strip is not overwritten.
    # V0.67 & V0.71 cells cover x +/- ~384, z=720..2000, and civic
    # originals extend to z~720. Some physically-authored plazas west/east.
    return absf(at.x) < 418.0 and at.z >= -135.0 and at.z < 2030.0

static func buildable(at: Vector3,building_halfwidth: float = 10.0) -> bool:
    var ring: int = ring_at(at)
    if ring == 0 or protected_existing_ward(at):
        return false
    var r: float = Geo.radial_m(at)
    if r < INNER_CITY_START+30.0 or r > CITY_RADIUS_M-35.0:
        return false
    if ring_road_distance(at) < RING_ROAD_WIDTH_M*0.5+building_halfwidth+2.0:
        return false
    if radial_distance_to_road(at) < RADIAL_ROAD_WIDTH_M*0.5+building_halfwidth+2.0:
        return false
    return true

static func parcel_key(tile: Vector2i,slot: int) -> String:
    return "mag_v074:%d:%d:%d" % [tile.x,tile.y,slot]

static func stable(tile: Vector2i,salt: int,count: int) -> int:
    if count <= 0:
        return 0
    var num: int = (tile.x*73856093) ^ (tile.y*19349663) ^ (salt*83492791)
    return posmod(num,count)

static func tile_slots(tile: Vector2i) -> Array[Dictionary]:
    var sites: Array[Dictionary] = []
    var center: Vector3 = Geo.tile_center(tile)
    for ix in range(8):
        for iz in range(8):
            var slot: int = ix*8+iz
            var local_x: float = (float(ix)-3.5)*BLOCK_GRID_M
            var local_z: float = (float(iz)-3.5)*BLOCK_GRID_M
            var at: Vector3 = center+Vector3(local_x,0.0,local_z)
            if not buildable(at):
                continue
            var ring: int = ring_at(at)
            var lot_seed: int = stable(tile,slot+171,23)
            var width: float = HOUSE_DIMENSION_MIN_M + float(lot_seed%7)*1.07
            var depth: float = HOUSE_DIMENSION_MIN_M + float((lot_seed/7)%6)*1.18
            var height: float = 9.0+float(lot_seed%7)*3.0
            match ring:
                1: height += 21.0
                2: height += 7.0
                3: height += 11.0
                4: height += 20.0
                5: height += 4.0
                6: height += 2.0
                7: height += 1.0
            sites.append({"id":parcel_key(tile,slot),
                "ring":ring,"world_pos":at,
                "local_pos":Vector3(local_x,0.0,local_z),
                "width":width,"depth":depth,
                "height":height,
                "roof_height":0.55+height,
                "palette":RING_COLORS[ring-1],
                "purpose":"game_only_exterior_massing",
                "actual_interior":false,"actual_occupant":false})
    return sites

static func far_cell(world_at: Vector3) -> Vector2i:
    return Vector2i(floori((world_at.x+FAR_CELL_M*0.5)/FAR_CELL_M),
        floori((world_at.z-Geo.CITY_CENTER.y+FAR_CELL_M*0.5)/FAR_CELL_M))

static func far_cell_center(cell: Vector2i) -> Vector3:
    return Vector3(float(cell.x)*FAR_CELL_M,0.0,
        Geo.CITY_CENTER.y+float(cell.y)*FAR_CELL_M)

static func far_specs(cell: Vector2i) -> Array[Dictionary]:
    # GPU-only lower-detail block silhouettes for a long visible horizon.
    var found: Array[Dictionary] = []
    var center: Vector3 = far_cell_center(cell)
    for ix in range(8):
        for iz in range(8):
            var at: Vector3 = center+Vector3((float(ix)-3.5)*59.0,
                0.0,(float(iz)-3.5)*59.0)
            if not buildable(at,20.0):
                continue
            var ring: int = ring_at(at)
            var code: int = stable(cell,300+ix*8+iz,19)
            var h: float = 18.0+float(code%6)*6.5
            if ring == 4:
                h += 28.0
            elif ring == 1:
                h += 18.0
            found.append({"world_pos":at+Vector3(0,0.55+h*0.5,0),
                "height":h,"size":Vector3(27+float(code%3)*5,h,
                    25+float((code+2)%3)*5),
                "color":RING_COLORS[ring-1].darkened(0.09+float(code%3)*0.08),
                "ring":ring,"game_only":true})
    return found

static func far_wanted(at: Vector3) -> Array[Vector2i]:
    var center: Vector2i = far_cell(at)
    var allowed: Array[Vector2i] = []
    for ix in range(-FAR_RADIUS,FAR_RADIUS+1):
        for iz in range(-FAR_RADIUS,FAR_RADIUS+1):
            var cell := center+Vector2i(ix,iz)
            var middle: Vector3 = far_cell_center(cell)
            var d: float = at.distance_to(middle)
            if d < VIEWSHED_MIN or d > VIEWSHED_MAX:
                continue
            if Geo.ring_for_position(middle) == 0:
                continue
            allowed.append(cell)
    return allowed

static func geometry_report() -> Dictionary:
    var widths: Array[float] = []
    var areas: Array[float] = []
    for i in range(1,8):
        widths.append(Geo.OUTER_BOUNDS_M[i-1])
        areas.append(Geo.ring_area_km2(i))
    return {"city":"Magnara","ring_count":7,"diameter_m":CITY_DIAMETER_M,
        "radius_m":CITY_RADIUS_M,"area_km2":Geo.circular_envelope_area_km2(26.0),
        "ring_radii_m":widths,"ring_areas_km2":areas,
        "radial_avenues":RADIAL_COUNT,
        "circumferential_avenues":7,
        "near_tile_budget":MAX_NEAR_CELLS,"near_built_plot_slots_per_tile":PLOTS_PER_TILE,
        "near_lod_m":CLOSE_COLLIDER_M,
        "long_horizon_m":VIEWSHED_MAX,
        "deepwater_main_port_ring":Port.MAJOR_SEAPORT_RING,
        "physical_ocean_docks_built":false,
        "original_seeker_quarters_preserved":true,
        "masterplan_only":true}
