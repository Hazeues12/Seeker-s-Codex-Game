extends RefCounted
# Story-safe visitor trialboard: a public *simulation* only.
# It does NOT teach Spatial Muti or instantiate any authored Ryōiki,
# Chronofault, pocket world, Demigod domain or sealed boss encounter.
const ENTRY: Vector3 = Vector3(24.0,0.87,-9.0)
const ARENA: Vector3 = Vector3(440.0,40.0,-100.0)
const SPAWN: Vector3 = ARENA + Vector3(0.0,1.25,-7.0)
const EXIT: Vector3 = ARENA + Vector3(3.0,1.05,-7.0)
const FLOOR_SIZE: Vector3 = Vector3(23.0,0.70,23.0)
const MAX_ACTIVE_ROOMS: int = 1
const ARENA_TIME_LIMIT: float = 360.0
const SAFE_STORY_RANKS: Array[String] = ["Stray","Iron","Bronze","Silver","Gold","Grand","Sage"]

static func valid_entry(player_rank: String, near_gateway: bool,
        expedition_busy: bool, already_inside: bool) -> Dictionary:
    if not SAFE_STORY_RANKS.has(player_rank):
        return {"allowed":false,"reason":"Unknown Seeker status."}
    if not near_gateway:
        return {"allowed":false,"reason":"Approach the practice gate."}
    if expedition_busy or already_inside:
        return {"allowed":false,"reason":"Finish current travel before opening the trialboard."}
    return {"allowed":true,"supervised_public":true,
        "grants_spatial_muti":false,"grants_ryoiki":false,
        "canon_status":"game_only"}

static func safe_return(origin: Vector3) -> bool:
    return is_finite(origin.x) and is_finite(origin.y) and is_finite(origin.z) \
        and origin.distance_to(ENTRY) < 8.0 and absf(origin.x) < 36.0

static func trial_step(time_elapsed: float, lateral: float) -> Dictionary:
    if not is_finite(time_elapsed) or time_elapsed < 0.0 or not is_finite(lateral):
        return {}
    return {"phase":"orientation","elapsed_seconds":minf(time_elapsed,ARENA_TIME_LIMIT),
        "obstacle_offset":sin(time_elapsed * 0.65) * 0.25 + clampf(lateral,-1.0,1.0)*0.0,
        "has_boss":false,"has_spatial_spoke_grant":false,
        "expired":time_elapsed >= ARENA_TIME_LIMIT}
