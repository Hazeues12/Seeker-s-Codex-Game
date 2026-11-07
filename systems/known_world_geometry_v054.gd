extends RefCounted
# V0.54: deterministic 1:1 geography. Ring radii are author planning figures
# rather than canonical measurements; origin is a temporary technical offset.
const CELL_SIZE: float = 256.0
const CITY_CENTER: Vector2 = Vector2(-1700.0, 70.0)
const CITY_RADIUS_M: float = 13000.0
const OUTER_BOUNDS_M: Array[float] = [
    1000.0, 2600.0, 4700.0, 6500.0, 8700.0, 10700.0, 13000.0
]
# Zone titles follow confirmed placement rules, not an invented final plan.
# Ring II = Seeker Quarters; IV trade; V foundry; VII seaport.
# Ring VI had an incorrect 'harbor' title in V0.54, now corrected.
const RING_NAMES: Array[String] = [
    "INNER CORE / PROVISIONAL", "SEEKER QUARTERS", "UNASSIGNED URBAN ZONE",
    "TRADE / MERCHANT DISTRICTS", "FORGE / MANUFACTURING ZONE",
    "OUTER INFRASTRUCTURE / UNASSIGNED", "OUTERMOST SEAPORT / IRON COTHON RESERVE"
]

static func radial_m(point: Vector3) -> float:
    return Vector2(point.x - CITY_CENTER.x, point.z - CITY_CENTER.y).length()

static func ring_for_radius_m(distance_m: float) -> int:
    if distance_m < 0.0 or not is_finite(distance_m):
        return 0
    for i in range(OUTER_BOUNDS_M.size()):
        if distance_m < OUTER_BOUNDS_M[i]:
            return i + 1
    return 0

static func ring_for_position(point: Vector3) -> int:
    return ring_for_radius_m(radial_m(point))

static func tile_index(point: Vector3) -> Vector2i:
    return Vector2i(
        floori((point.x + CELL_SIZE * 0.5) / CELL_SIZE),
        floori((point.z - CITY_CENTER.y + CELL_SIZE * 0.5) / CELL_SIZE)
    )

static func tile_center(tile: Vector2i) -> Vector3:
    return Vector3(float(tile.x) * CELL_SIZE, 0.0,
        CITY_CENTER.y + float(tile.y) * CELL_SIZE)

static func cell_id(tile: Vector2i) -> String:
    return "%d:%d" % [tile.x, tile.y]

static func safe_city_save(point: Vector3) -> bool:
    # Restrict to actual city-planning envelope and plausible pedestrian height.
    # The original hub's legacy save rules remain separately valid.
    return is_finite(point.x) and is_finite(point.y) and is_finite(point.z) \
        and point.y >= -2.0 and point.y <= 90.0 \
        and ring_for_position(point) > 0

static func circular_envelope_area_km2(diameter_km: float) -> float:
    if diameter_km <= 0.0 or not is_finite(diameter_km):
        return 0.0
    var radius: float = diameter_km * 0.5
    return PI * radius * radius

static func ring_area_km2(ring: int) -> float:
    if ring < 1 or ring > OUTER_BOUNDS_M.size():
        return 0.0
    var outer: float = OUTER_BOUNDS_M[ring - 1]
    var inner: float = 0.0 if ring == 1 else OUTER_BOUNDS_M[ring - 2]
    return PI * (outer * outer - inner * inner) / 1000000.0

static func ring_label(ring: int) -> String:
    if ring < 1 or ring > RING_NAMES.size():
        return "OUTSIDE PROPOSED CITY"
    return "RING %d / %s" % [ring, RING_NAMES[ring - 1]]
