extends RefCounted
# V0.69: posture is ordinary balance/guard for everyone, NOT Steel (Kōshin).
# Sight (Kyōmei-shi) requires a trained, author-allowed license; Steel only
# Gold+; Ōi only Grand+. All early gameplay is supervised physical practice.
const MAX_POSTURE: float = 100.0
const BASE_PARRY_WINDOW: float = 0.13
const SIGHT_PARRY_WINDOW: float = 0.19
const BASE_RECOVERY: float = 11.0
const STEEL_RECOVERY: float = 20.0
const RANKS: Array[String] = ["Stray","Iron","Bronze","Silver","Gold","Grand","Sage"]
const CRITICAL_MULTIPLIER: float = 1.45

static func rank_at_least(rank: String, threshold: String) -> bool:
    return RANKS.has(rank) and RANKS.has(threshold) and RANKS.find(rank) >= RANKS.find(threshold)

static func legal_will(rank: String, kind: String, trained: bool, creator_gate: bool = false) -> bool:
    if not trained:
        return false
    match kind:
        "sight":
            return creator_gate
        "steel":
            return rank_at_least(rank, "Gold") and creator_gate
        "oi":
            return rank_at_least(rank, "Grand") and creator_gate
    return false

static func window_seconds(rank: String, trained_sight: bool, creator_gate: bool = false) -> float:
    return SIGHT_PARRY_WINDOW if legal_will(rank, "sight", trained_sight, creator_gate) else BASE_PARRY_WINDOW

static func parry(age: float, guard_active: bool, rank: String = "Stray",
        sight_trained: bool = false, creator_gate: bool = false) -> bool:
    return guard_active and is_finite(age) and age >= 0.0 and age <= window_seconds(rank, sight_trained, creator_gate)

static func posture_hit(current: float, incoming: float, guarded: bool,
        authorized_steel: bool = false) -> Dictionary:
    if not is_finite(current) or not is_finite(incoming) or incoming < 0.0:
        return {"valid": false}
    var base: float = incoming * (0.45 if guarded else 1.25)
    if authorized_steel:
        base *= 0.65
    var remaining: float = maxf(0.0, clampf(current,0.0,MAX_POSTURE) - base)
    return {"valid":true, "remaining":remaining, "break": remaining <= 0.01,
        "impact":base, "steel_active":authorized_steel}

static func recover(current: float, seconds: float, authorized_steel: bool = false) -> float:
    if not is_finite(current) or not is_finite(seconds) or seconds < 0.0:
        return clampf(current,0.0,MAX_POSTURE) if is_finite(current) else 0.0
    return minf(MAX_POSTURE, maxf(0.0,current) +
        (STEEL_RECOVERY if authorized_steel else BASE_RECOVERY) * seconds)

static func oi_pressure(source_rank: String, target_rank: String, source_trained: bool,
        creator_gate: bool, distance: float, radius: float = 7.0) -> Dictionary:
    # **No automatic Sovereignty** from reaching Grand. It is an
    # individually authored, plot-verified Will technique, not a player aura.
    if not legal_will(source_rank, "oi", source_trained, creator_gate):
        return {"allowed":false,"effect":"none"}
    if not is_finite(distance) or distance < 0.0 or distance > radius or not rank_at_least(source_rank, target_rank):
        return {"allowed":false,"effect":"none"}
    return {"allowed":true,"effect":"scripted_pressure_only",
        "does_not_spawn_boss":true,"does_not_target_civilians":true}

static func warning_for_break(posture: float) -> String:
    if posture <= 0.01:
        return "POSTURE BROKEN — retreat and recover!"
    if posture < 30.0:
        return "POSTURE LOW — stop blocking every hit."
    return "Posture stable"
