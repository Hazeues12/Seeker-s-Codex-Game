extends RefCounted
# Original public *training-grade* Aura momentum drill, not Kai's Hanuman
# Step, Aria's Spark Rush, William's Lumen Step or any rare story art.
const BURST_AURA: int = 16
const BURST_STAMINA: float = 8.0
const BURST_SPEED: float = 16.0
const BURST_DURATION: float = 0.36
const BURST_COOLDOWN: float = 1.60
const COYOTE_SECONDS: float = 0.11
const JUMP_BUFFER_SECONDS: float = 0.13
const FLOOR_SNAP: float = 0.20
const MAX_DASH_DISTANCE: float = BURST_SPEED * BURST_DURATION

static func valid_direction(input: Vector3) -> Vector3:
    var planar := Vector3(input.x, 0.0, input.z)
    if not is_finite(planar.x) or not is_finite(planar.z):
        return Vector3.ZERO
    if planar.length_squared() <= 0.07:
        return Vector3.ZERO
    return planar.normalized()

static func may_burst(direction: Vector3, cooldown: float, aura: float,
        stamina: float, panels_open: bool, guarding: bool, dodging: bool,
        available_martial: bool = true) -> Dictionary:
    if valid_direction(direction).is_zero_approx():
        return {"allowed":false, "reason":"Choose a direction."}
    if not is_finite(cooldown) or cooldown > 0.0:
        return {"allowed":false, "reason":"Momentum recovers between bursts."}
    if panels_open or guarding or dodging:
        return {"allowed":false, "reason":"Return to movement before bursting."}
    if not available_martial:
        return {"allowed":false, "reason":"Train basic Martial control first."}
    if not is_finite(aura) or aura < float(BURST_AURA):
        return {"allowed":false, "reason":"Need 16 Aura."}
    if not is_finite(stamina) or stamina < BURST_STAMINA:
        return {"allowed":false, "reason":"Need 8 Stamina."}
    return {"allowed":true, "aura_cost":BURST_AURA,
        "stamina_cost":BURST_STAMINA, "time":BURST_DURATION,
        "cooldown":BURST_COOLDOWN, "speed":BURST_SPEED,
        "direction":valid_direction(direction), "game_only":true}

static func jump_available(on_floor: bool, jumps_used: int, coyote: float,
        buffered: float) -> String:
    if buffered <= 0.0:
        return "none"
    if on_floor or (coyote > 0.0 and jumps_used == 0):
        return "first"
    if jumps_used < 2:
        return "second"
    return "none"
