extends RefCounted
# V0.56 regional hydrography: PROVISIONAL game-only river, no canon placement.
# Deterministic world-space profile keeps the same watercourse across 256m cells.
const RIVER_TILE_X: int = 60
const RIVER_X_M: float = 15360.0
const RIVER_COURSE_Z_M: float = 70.0
const MEANDER_AMPLITUDE_M: float = 14.0
const MEANDER_FREQUENCY: float = 0.0065
const INNER_HALF_WIDTH_M: float = 17.0
const OUTER_BANK_HALF_WIDTH_M: float = 43.0
const WATER_SURFACE_Y_M: float = -1.75
const RIVERBED_Y_M: float = -3.10
const ROAD_BRIDGE_SPAN_M: float = 112.0
const RAIL_BRIDGE_SPAN_M: float = 112.0

static func river_center_x(world_z: float) -> float:
    return RIVER_X_M + sin((world_z - RIVER_COURSE_Z_M) * MEANDER_FREQUENCY) * MEANDER_AMPLITUDE_M

static func distance_to_river(world_x: float, world_z: float) -> float:
    return absf(world_x - river_center_x(world_z))

static func carved_height(world_x: float, world_z: float, original_height: float) -> float:
    var distance: float = distance_to_river(world_x, world_z)
    if distance >= OUTER_BANK_HALF_WIDTH_M:
        return original_height
    if distance <= INNER_HALF_WIDTH_M:
        return RIVERBED_Y_M
    var u: float = (distance - INNER_HALF_WIDTH_M) / (OUTER_BANK_HALF_WIDTH_M - INNER_HALF_WIDTH_M)
    var smooth: float = u * u * (3.0 - 2.0 * u)
    return lerpf(RIVERBED_Y_M, original_height, smooth)

static func has_water_tile(tile_x: int) -> bool:
    return tile_x == RIVER_TILE_X

static func bridge_extent_for_local_x(local_x: float) -> bool:
    return absf(local_x) <= ROAD_BRIDGE_SPAN_M * 0.5

static func is_dry_bank(world_x: float, world_z: float) -> bool:
    return distance_to_river(world_x, world_z) >= OUTER_BANK_HALF_WIDTH_M

static func crossing_count_for_corridor(side_tile_count: int) -> int:
    # Each of three local road/rail corridors needs its own safe bridge.
    return maxi(0, side_tile_count)
