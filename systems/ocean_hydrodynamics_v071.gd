extends RefCounted
# V0.71 CPU mirror of the GLSL coastal wave model; weather is IN-GAME,
# no live real-world forecasts or invented national weather observations.
# World x/z are given relative to a 1 km scenic-only ocean tile.
const WATER_Y: float = 0.0
const COAST_LOCAL_X: float = -320.0
const TILE_WIDTH: float = 1000.0
const WIND_MIN: float = 0.20
const WIND_MAX: float = 0.95
const PERIOD_SECONDS: float = 440.0
const WAVE_RATE: float = 0.48
const MAX_WAVE_Y: float = 2.10
const COUNTRY_LAKE_AFFILIATION: String = "Lake Lukka / Africanus (unplaced; not spawned)"
const RIVER_FLOW_MPS: float = 1.6

static func weather(minutes: float) -> Dictionary:
    if not is_finite(minutes) or minutes < 0.0:
        return {}
    var day: int = 1 + floori(minutes / 1440.0)
    var cycle: float = minutes / 1440.0
    var envelope: float = 0.47 + 0.26 * sin(cycle * 1.77 + 0.8) + 0.16 * sin(cycle * 0.79 + 2.1)
    var wind: float = clampf(envelope, WIND_MIN, WIND_MAX)
    var direction: float = 0.24 + 0.44 * sin(cycle * 0.37)
    var sky: String = "rough_weather" if wind > 0.72 else ("breezy" if wind > 0.46 else "calm")
    return {"day":day, "wind_strength":wind, "wind_direction_rad":direction,
        "sky":sky, "wave_field":"local_Janoah_sea_preview",
        "global_forecast_accurate":false, "game_only_weather":true}

static func offshore_factor(local_x: float) -> float:
    return clampf((local_x - COAST_LOCAL_X) / 490.0, 0.0, 1.0)

static func wave_strength(local_x: float, wind: float) -> float:
    var attenuation: float = 0.22 + 0.78 * offshore_factor(local_x)
    return (0.18 + 1.25 * clampf(wind,WIND_MIN,WIND_MAX)) * attenuation

static func tide(seconds: float) -> float:
    return sin(seconds * TAU / PERIOD_SECONDS) * 0.14

static func surface_height(local_x: float, local_z: float, seconds: float, wind: float) -> float:
    if not is_finite(local_x) or not is_finite(local_z) or not is_finite(seconds) or not is_finite(wind):
        return WATER_Y
    var strength: float = wave_strength(local_x, wind)
    var t: float = seconds * (0.72 + clampf(wind, WIND_MIN, WIND_MAX) * 0.9)
    var primary: float = 0.54 * sin(local_x * 0.095 + local_z * 0.034 + t * 1.08)
    var secondary: float = 0.29 * sin(-local_x * 0.061 + local_z * 0.129 + t * 0.79)
    var tertiary: float = 0.17 * sin(local_x * 0.16 - local_z * 0.084 + t * 1.42)
    return WATER_Y + tide(seconds) + strength * (primary + secondary + tertiary)

static func surface_normal(local_x: float, local_z: float, seconds: float, wind: float) -> Vector3:
    var epsilon: float = 0.35
    var dx: float = (surface_height(local_x+epsilon,local_z,seconds,wind) -
        surface_height(local_x-epsilon,local_z,seconds,wind)) / (epsilon * 2.0)
    var dz: float = (surface_height(local_x,local_z+epsilon,seconds,wind) -
        surface_height(local_x,local_z-epsilon,seconds,wind)) / (epsilon * 2.0)
    return Vector3(-dx,1.0,-dz).normalized()

static func buoyancy(local_x: float, local_z: float, seconds: float, wind: float,
        beam: float, length: float) -> Dictionary:
    # Four independent water samples: center heave, pitch and roll.
    var half_length: float = maxf(1.0,length * 0.40)
    var half_beam: float = maxf(0.5,beam * 0.42)
    var bow: float = surface_height(local_x+half_length,local_z,seconds,wind)
    var stern: float = surface_height(local_x-half_length,local_z,seconds,wind)
    var starboard: float = surface_height(local_x,local_z+half_beam,seconds,wind)
    var port: float = surface_height(local_x,local_z-half_beam,seconds,wind)
    var center: float = surface_height(local_x,local_z,seconds,wind)
    return {"waterline":(bow+stern+starboard+port+center*2.0)/6.0,
        "pitch_rad":clampf(atan2(bow-stern,half_length*2.0),-0.22,0.22),
        "roll_rad":clampf(atan2(starboard-port,half_beam*2.0),-0.26,0.26),
        "samples":4, "water_is_solid":false}

static func water_drag(speed: float, fraction_submerged: float) -> float:
    return maxf(0.0,speed) * (1.0 - clampf(fraction_submerged,0.0,1.0)*0.19)

static func river_surface_y(local_x: float, local_z: float, seconds: float) -> float:
    # The V0.56 Janoah floodplain is an unconfirmed GAME-ONLY river. River
    # ripples are smaller, directional and shallower than open ocean swells.
    return -1.75 + 0.035 * sin(local_z * 0.27 - seconds * RIVER_FLOW_MPS) + \
        0.018 * sin(local_x * 0.43 + local_z * 0.14 - seconds * 0.70)

static func in_ocean_tile(local_x: float, local_z: float) -> bool:
    return local_x >= -TILE_WIDTH * 0.5 and local_x <= TILE_WIDTH * 0.5 \
        and absf(local_z) <= TILE_WIDTH * 0.5

static func ship_class(kind: String) -> Dictionary:
    match kind:
        "small":
            return {"beam":4.2, "length":13.0, "speed":8.0, "cargo_units":6, "draft":0.8}
        "medium":
            return {"beam":8.8, "length":27.0, "speed":6.5, "cargo_units":26, "draft":1.5}
        "large":
            return {"beam":15.0, "length":49.0, "speed":5.0, "cargo_units":72, "draft":2.1}
    return {}
