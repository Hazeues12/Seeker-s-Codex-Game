extends RefCounted
# V0.67 deterministic, mobile-budgeted urban world partition for the KNOWN
# Magnara 1500 A.S. Ring Two prototype. No generated buildings become canon.
const TILE_M: float = 128.0
const Z_START: float = 720.0
const MIN_COL: int = -1
const MAX_COL: int = 1
const MIN_ROW: int = 0
const MAX_ROW: int = 4
const STREAM_RADIUS: int = 1
const ACTIVE_CAP: int = 9
const LOAD_BUDGET: int = 2
const RESIDENTS_PER_CHUNK: int = 5
const PARCELS_PER_CHUNK: int = 6
const CLOSE_M: float = 20.0
const MID_M: float = 100.0
const COLLIDER_M: float = 78.0
const TICK_SECONDS: float = 0.38
const PROTOTYPE_SEED: int = 150067
const ROLES: Array[String] = [
    "factory apprentice", "bakery courier", "tram runner", "market porter",
    "street maintenance", "press delivery", "canal technician", "sewing apprentice",
    "night watch", "office clerk", "street vendor", "rail porter"
]
const TRAITS: Array[String] = [
    "patient and exacting", "curious and bright", "quiet and protective",
    "sociable and mischievous", "methodical and determined", "generous and alert",
    "wary and observant", "warm and deliberate", "restless and independent"
]
const FIRST: Array[String] = [
    "Mira","Tolan","Esha","Kellan","Neri","Pavi","Sol","Rumi","Asha","Brenn",
    "Ilan","Faye","Nolan","Dara","Cori","Aven","Suri","Rafi"
]
const LAST: Array[String] = [
    "West","Venn","Kory","Bell","Rosen","Nash","Stone","Dove","Marr",
    "Kell","Thorn","Ash","Brass","Wey","Vale"
]
const MODULE_TYPES: Array[String] = ["ground","middle","roof","awning","balcony","window"]

static func allowed(cell: Vector2i) -> bool:
    return cell.x >= MIN_COL and cell.x <= MAX_COL and cell.y >= MIN_ROW and cell.y <= MAX_ROW

static func key(cell: Vector2i) -> String:
    return "%d:%d" % [cell.x, cell.y]

static func chunk_for(point: Vector3) -> Vector2i:
    return Vector2i(floori((point.x + TILE_M * 0.5) / TILE_M),
        floori((point.z - Z_START) / TILE_M))

static func origin(cell: Vector2i) -> Vector3:
    return Vector3(float(cell.x) * TILE_M, 0.0, Z_START + float(cell.y) * TILE_M)

static func center(cell: Vector2i) -> Vector3:
    return origin(cell) + Vector3(0, 0, TILE_M * 0.5)

static func preferred_cells(point: Vector3) -> Array[Vector2i]:
    var current: Vector2i = chunk_for(point)
    var found: Array[Vector2i] = []
    for dx in range(-STREAM_RADIUS, STREAM_RADIUS + 1):
        for dy in range(-STREAM_RADIUS, STREAM_RADIUS + 1):
            var cell := current + Vector2i(dx, dy)
            if allowed(cell):
                found.append(cell)
    found.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        var ca: Vector3 = center(a)
        var cb: Vector3 = center(b)
        var da: float = (ca.x - point.x) * (ca.x - point.x) + (ca.z - point.z) * (ca.z - point.z)
        var db: float = (cb.x - point.x) * (cb.x - point.x) + (cb.z - point.z) * (cb.z - point.z)
        if is_equal_approx(da, db):
            return key(a) < key(b)
        return da < db
    )
    return found

static func stable_mod(cell: Vector2i, salt: int, count: int) -> int:
    if count <= 0:
        return 0
    var hash: int = PROTOTYPE_SEED + (cell.x + 21) * 92821 + (cell.y + 37) * 68917 + salt * 31531
    return posmod(hash, count)

static func parcel(cell: Vector2i, slot: int) -> Dictionary:
    if not allowed(cell) or slot < 0 or slot >= PARCELS_PER_CHUNK:
        return {}
    var cx: float = -35.0 if slot % 2 == 0 else 35.0
    var zz: float = [27.0, 64.0, 101.0][int(slot / 2)]
    var floor_count: int = 1 + stable_mod(cell, slot * 5 + 8, 4)
    var width: float = 18.0 + float(stable_mod(cell, slot * 3, 5))
    var depth: float = 17.5 + float(stable_mod(cell, slot * 7 + 11, 5))
    var roof_style: int = stable_mod(cell, slot * 9 + 4, 3)
    var palette: int = stable_mod(cell, slot * 13 + 7, 5)
    return {
        "id": "urban:%s:%d" % [key(cell), slot],
        "center": Vector3(cx, 0, zz),
        "floors": floor_count,
        "width": width,
        "depth": depth,
        "height": 3.2 + float(floor_count) * 2.75,
        "palette": palette,
        "roof_style": roof_style,
        "awnings": stable_mod(cell, slot + 2, 3) != 0,
        "balconies": stable_mod(cell, slot + 6, 2) == 0,
        "canon_status": "game_only_massing"
    }

static func person(cell: Vector2i, ordinal: int) -> Dictionary:
    if not allowed(cell) or ordinal < 0 or ordinal >= RESIDENTS_PER_CHUNK:
        return {}
    var token: int = stable_mod(cell, 1000 + ordinal * 13, 1024)
    var first: String = FIRST[posmod(token + ordinal, FIRST.size())]
    var last: String = LAST[posmod(token / 7 + ordinal * 3, LAST.size())]
    return {
        "id": "district_v067_%d_%d_%d" % [cell.x, cell.y, ordinal],
        "name": first + " " + last,
        "role": ROLES[stable_mod(cell, ordinal * 7 + 2, ROLES.size())],
        "personality": TRAITS[stable_mod(cell, ordinal * 3 + 16, TRAITS.size())],
        "home": "household_v067_%d_%d_%d" % [cell.x, cell.y, int(ordinal / 2)],
        "district": "Magnara / Ring Two / provisional northern street",
        "kind": "game_only",
        "canon_status": "game_only",
        "origin_cell": key(cell),
        "schedule": "simulated_routine",
        "affiliations": ["civilian_workforce"],
        "secret_powers": []
    }

static func residents(cell: Vector2i) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if allowed(cell):
        for n in range(RESIDENTS_PER_CHUNK):
            result.append(person(cell, n))
    return result

static func local_minutes(minutes: float) -> float:
    return fposmod(maxf(0.0, minutes), 1440.0)

static func person_state(cell: Vector2i, ordinal: int, minutes: float) -> Dictionary:
    if not allowed(cell) or ordinal < 0 or ordinal >= RESIDENTS_PER_CHUNK:
        return {}
    var resident: Dictionary = person(cell, ordinal)
    var local_time: float = local_minutes(minutes)
    var late_shift: bool = str(resident["role"]) == "night watch" or str(resident["role"]) == "press delivery"
    var t: float = fposmod(local_time + float(stable_mod(cell, ordinal * 4, 120)) + (510.0 if late_shift else 0.0), 1440.0)
    var visible: bool = t >= 420.0 and t < 1280.0
    var action: String = "sleep_at_home"
    if visible:
        if t < 535.0:
            action = "walk_to_work"
        elif t < 780.0:
            action = "work_shift"
        elif t < 870.0:
            action = "meal_and_errands"
        elif t < 1090.0:
            action = "afternoon_shift"
        else:
            action = "walk_home_and_socialize"
    # A mirrored sidewalk rail: time drives each individual's position
    # deterministically, including while they are unloaded from memory.
    var u: float = fposmod(t * (0.018 + float(ordinal % 3) * 0.004) + float(ordinal) * 0.19, 2.0)
    var travel: float = 1.0 - absf(u - 1.0)
    var side: float = -1.0 if ordinal % 2 == 0 else 1.0
    var x: float = float(cell.x) * TILE_M + side * 9.6
    var z: float = Z_START + float(cell.y) * TILE_M + 19.0 + travel * 90.0
    return {"id": resident["id"], "visible": visible, "activity": action,
        "world_position": Vector3(x, 0.80, z), "lod": "offscreen",
        "household": resident["home"], "role": resident["role"]}

static func lod(distance: float, visible: bool = true) -> String:
    if not visible or not is_finite(distance) or distance > MID_M:
        return "far"
    if distance <= CLOSE_M:
        return "close"
    return "mid"

static func can_render_canonical(record: Dictionary) -> bool:
    # New street blocks are filled ONLY with original civilians. No canon
    # squad/elite spawn by random class or hair/outfit distribution.
    return str(record.get("kind", "")) == "game_only" and str(record.get("canon_status", "")) == "game_only"
