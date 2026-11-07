extends RefCounted
# V0.70 public game-only cart, not a claimed canonical Magnara train route.
# All positions/transport timing are prototype city coordinates.
const STATION_SOUTH: Vector3 = Vector3(0.0, 0.62, 608.0)
const STATION_NORTH: Vector3 = Vector3(0.0, 0.62, 690.0)
const SPEED: float = 5.0
const DOCK_SECONDS: float = 2.0
const STATION_DISTANCE: float = 82.0
const ONE_WAY_SECONDS: float = STATION_DISTANCE / SPEED
const CYCLE_SECONDS: float = (ONE_WAY_SECONDS + DOCK_SECONDS) * 2.0
const DECK_HALF_WIDTH: float = 1.8
const DECK_TOP_Y: float = 1.64

static func state_at(seconds: float) -> Dictionary:
    if not is_finite(seconds) or seconds < 0.0:
        return {}
    var time: float = fposmod(seconds, CYCLE_SECONDS)
    var t: float = 0.0
    var status: String = ""
    var velocity: float = 0.0
    if time < DOCK_SECONDS:
        status = "south_stop"
        t = 0.0
    elif time < DOCK_SECONDS + ONE_WAY_SECONDS:
        status = "northbound"
        t = (time - DOCK_SECONDS) / ONE_WAY_SECONDS
        velocity = SPEED
    elif time < DOCK_SECONDS * 2.0 + ONE_WAY_SECONDS:
        status = "north_stop"
        t = 1.0
    else:
        status = "southbound"
        t = 1.0 - (time - DOCK_SECONDS * 2.0 - ONE_WAY_SECONDS) / ONE_WAY_SECONDS
        velocity = -SPEED
    return {"fraction":clampf(t,0.0,1.0), "state":status,
        "position":STATION_SOUTH.lerp(STATION_NORTH,clampf(t,0.0,1.0)),
        "velocity":Vector3(0,0,velocity),"docked":status.ends_with("_stop"),
        "cycle_seconds":CYCLE_SECONDS}

static func safe_visitor(point: Vector3) -> bool:
    return is_finite(point.x) and is_finite(point.y) and is_finite(point.z) \
        and absf(point.x) <= 140.0 and point.z >= 575.0 and point.z <= 730.0
