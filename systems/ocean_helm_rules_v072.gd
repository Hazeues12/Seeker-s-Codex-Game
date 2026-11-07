extends RefCounted
# V0.72 public small craft, within the known-world Janoah Sea's scenic
# survey tile. Explicitly NOT a canonical real port lane, national voyage,
# magical Muti drive or fully dynamic fluid simulation.
const Waves = preload("res://systems/ocean_hydrodynamics_v071.gd")
const START: Vector3 = Vector3(-230.0,0.0,-299.0)
const START_HEADING: float = 0.0
const BEAM_M: float = 4.2
const LENGTH_M: float = 13.0
const MAX_SPEED_MPS: float = 7.0
const ACCELERATION_MPS2: float = 1.25
const BRAKE_MPS2: float = 2.10
const STEER_RADIANS_PER_SECOND: float = 0.68
const MAX_HELM_DISTANCE_M: float = 7.5
const SAFE_INNER_BOUND: float = 457.0
const WAKE_LIMIT: int = 18
const WAKE_LIFE_SECONDS: float = 4.5
const WAKE_INTERVAL_SECONDS: float = 0.19

static func advance(state: Dictionary, steer: float, throttle: float, delta: float,
        wind: float, wind_direction: float, seconds: float) -> Dictionary:
    if typeof(state.get("pos",null)) != TYPE_VECTOR3 or not is_finite(delta) \
            or delta < 0.0 or delta > 0.25 or not is_finite(steer) \
            or not is_finite(throttle) or not is_finite(wind) \
            or not is_finite(wind_direction) or not is_finite(seconds):
        return {}
    var pos: Vector3 = state["pos"]
    if absf(pos.x) > Waves.TILE_WIDTH*0.5 or absf(pos.z) > Waves.TILE_WIDTH*0.5:
        return {}
    var speed: float = clampf(float(state.get("speed",0.0)),0.0,MAX_SPEED_MPS)
    var heading: float = float(state.get("heading",START_HEADING))
    var target: float = clampf(throttle,0.0,1.0)*MAX_SPEED_MPS
    var roughness: float = clampf(wind,0.20,0.95)
    var high_sea_penalty: float = lerpf(1.0,0.78,
        (roughness-0.20)/(0.95-0.20))
    target *= high_sea_penalty
    speed = move_toward(speed,target,
        (ACCELERATION_MPS2 if target > speed else BRAKE_MPS2)*delta)
    var turn_scale: float = 0.22+0.78*clampf(speed/MAX_SPEED_MPS,0.0,1.0)
    heading = wrapf(heading+clampf(steer,-1.0,1.0)*
        STEER_RADIANS_PER_SECOND*turn_scale*delta,-PI,PI)
    var forward: Vector3 = Vector3(cos(heading),0.0,sin(heading))
    var crosswind: Vector3 = Vector3(cos(wind_direction),0.0,sin(wind_direction))
    var drift: Vector3 = crosswind*(roughness*0.19*speed*delta)
    var wanted: Vector3 = pos+forward*speed*delta+drift
    var hit_boundary: bool = absf(wanted.x) > SAFE_INNER_BOUND \
        or absf(wanted.z) > SAFE_INNER_BOUND
    if hit_boundary:
        wanted.x = clampf(wanted.x,-SAFE_INNER_BOUND,SAFE_INNER_BOUND)
        wanted.z = clampf(wanted.z,-SAFE_INNER_BOUND,SAFE_INNER_BOUND)
        speed = 0.0
        target = 0.0
    var float_state: Dictionary = Waves.buoyancy(wanted.x,wanted.z,seconds,
        roughness,BEAM_M,LENGTH_M)
    return {"pos":wanted,"speed":speed,"heading":heading,
        "wave_waterline":float(float_state["waterline"]),
        "pitch_rad":float(float_state["pitch_rad"]),
        "roll_rad":float(float_state["roll_rad"]),
        "wave_samples":int(float_state["samples"]),
        "offshore_strength":Waves.wave_strength(wanted.x,roughness),
        "wake_intensity":clampf(speed/MAX_SPEED_MPS,0.0,1.0),
        "boundary_reached":hit_boundary, "free_player_movement":true,
        "canon_status":"game_only_helm_trial"}

static func default_state() -> Dictionary:
    return {"pos":START,"speed":0.0,"heading":START_HEADING,
        "wake_intensity":0.0,"boundary_reached":false}

static func can_helm(player_pos: Vector3, ship_pos: Vector3,
        present: bool, active: bool) -> bool:
    return present and active and player_pos.distance_to(ship_pos) <= \
        MAX_HELM_DISTANCE_M

static func wake_point(state: Dictionary, seconds: float) -> Dictionary:
    if state.is_empty() or float(state.get("speed",0.0)) < 0.6:
        return {}
    var pos: Vector3 = state["pos"]
    var heading: float = float(state.get("heading",0.0))
    return {"pos":pos-Vector3(cos(heading),0,sin(heading))*LENGTH_M*0.60,
        "birth":seconds,"strength":clampf(float(state.get("wake_intensity",0.0)),0.0,1.0)}

static func wake_alpha(item: Dictionary, seconds: float) -> float:
    var age: float = maxf(0.0,seconds-float(item.get("birth",-100.0)))
    return clampf((1.0-age/WAKE_LIFE_SECONDS)*float(item.get("strength",0.0)),
        0.0,1.0)
