extends RefCounted
# V0.73 local public goods, 3 existing actual wagons -> up to 12
# north ward sites over 4 days. No imaginary international arrival,
# unseen canonical factions, player money or fabricated prices.
const Ward = preload("res://systems/magnara_expansion_rules_v071.gd")
const Interiors = preload("res://systems/magnara_interiors_rules_v072.gd")
const WAGON_COUNT: int = 3
const FIRST_ROW: int = 5
const LAST_ROW: int = 8
const INITIAL_STOCK: int = 2
const DELIVERY_UNITS: int = 4
const STOCK_LIMIT: int = 18
const DELIVERY_SPEED_MPS: float = 6.5
# Legacy DOCK_AT name kept for existing saved scripts/tests only:
# this point is a LAND FREIGHT DEPOT, nowhere near the maritime harbor.
const INLAND_DEPOT_AT: Vector3 = Vector3(14.0,0.84,1382.0)
const DOCK_AT: Vector3 = INLAND_DEPOT_AT
const RECEIPT_LIMIT: int = 120
const MAX_PENDING: int = 3
const MAX_ELAPSED: float = 500.0
const MAX_DAY: int = 100000
const INLAND_FREIGHT_ARRIVAL_Z: float = 1395.0
const DOCK_TRIGGER_Z: float = INLAND_FREIGHT_ARRIVAL_Z
const SCENE_REACH_M: float = 170.0
const VISITOR_INDEX: int = 10
const VISIT_START: float = 1060.0
const VISIT_END: float = 1220.0

static func clean(raw: Variant) -> Dictionary:
    var safe: Dictionary = {"stock":{},"receipts":{},"pending":{}}
    if typeof(raw) != TYPE_DICTIONARY:
        return safe
    if typeof(raw.get("stock",null)) == TYPE_DICTIONARY:
        for key in raw["stock"].keys():
            var cell: Vector2i = parse_cell(str(key))
            var count: Variant = raw["stock"][key]
            if Ward.allowed(cell) and typeof(count) in [TYPE_INT,TYPE_FLOAT] \
                    and is_finite(float(count)) and float(count) >= 0.0 \
                    and float(count) <= STOCK_LIMIT:
                safe["stock"][str(key)] = clampi(int(count),0,STOCK_LIMIT)
    if typeof(raw.get("receipts",null)) == TYPE_DICTIONARY:
        var keys: Array = raw["receipts"].keys()
        keys.sort()
        for key in keys.slice(-RECEIPT_LIMIT):
            var identity: Dictionary = receipt_parse(str(key))
            if not identity.is_empty() and raw["receipts"][key] == true:
                safe["receipts"][str(key)] = true
    if typeof(raw.get("pending",null)) == TYPE_DICTIONARY:
        for key in raw["pending"].keys():
            var identity: Dictionary = receipt_parse(str(key))
            if identity.is_empty() or safe["pending"].size() >= MAX_PENDING \
                    or safe["receipts"].has(str(key)):
                continue
            var packet: Variant = raw["pending"][key]
            if typeof(packet) != TYPE_DICTIONARY:
                continue
            var elapsed: Variant = packet.get("elapsed",-1)
            if typeof(elapsed) not in [TYPE_INT,TYPE_FLOAT] \
                    or not is_finite(float(elapsed)) or float(elapsed) < 0.0 \
                    or float(elapsed) > MAX_ELAPSED:
                continue
            var manifest: Dictionary = delivery(int(identity["day"]),int(identity["wagon"]))
            if not manifest.is_empty() and str(packet.get("site","")) == str(manifest["site"]):
                safe["pending"][str(key)] = {
                    "site":str(manifest["site"]),"elapsed":float(elapsed)}
    return safe

static func parse_cell(id: String) -> Vector2i:
    var values: PackedStringArray = id.split(":")
    if values.size() != 2 or not values[0].is_valid_int() \
            or not values[1].is_valid_int():
        return Vector2i(999,999)
    return Vector2i(int(values[0]),int(values[1]))

static func receipt_key(day: int, wagon: int) -> String:
    return "v073_d%06d_w%d" % [day,wagon]

static func receipt_parse(token: String) -> Dictionary:
    if not token.begins_with("v073_d") or not token.contains("_w"):
        return {}
    var words: PackedStringArray = token.trim_prefix("v073_d").split("_w")
    if words.size() != 2 or not words[0].is_valid_int() \
            or not words[1].is_valid_int():
        return {}
    var day: int = int(words[0])
    var wagon: int = int(words[1])
    return {"day":day,"wagon":wagon} if day >= 1 and day <= MAX_DAY \
        and wagon >= 0 and wagon < WAGON_COUNT \
        and token == receipt_key(day,wagon) else {}

static func delivery(day: int, wagon: int) -> Dictionary:
    if day < 1 or day > MAX_DAY or wagon < 0 or wagon >= WAGON_COUNT:
        return {}
    var cell := Vector2i(wagon-1,FIRST_ROW+posmod(day-1,LAST_ROW-FIRST_ROW+1))
    var venue: Dictionary = Interiors.site(cell)
    if venue.is_empty():
        return {}
    return {"receipt":receipt_key(day,wagon),"day":day,
        "wagon":wagon,"cell":Ward.key(cell),"site":str(venue["id"]),
        "category":str(venue["work"]),"units":DELIVERY_UNITS,
        "target":venue["door_world"],"source":"public_ring_two_freight_depot",
        "origin":INLAND_DEPOT_AT,"canon_status":"game_only_local",
        "source_ring":2,"maritime_port":false,"outer_seaport_ring":7,
        "crosses_national_border":false,"money_transfer":0}

static func path(day: int, wagon: int) -> Array[Vector3]:
    var descriptor: Dictionary = delivery(day,wagon)
    var points: Array[Vector3] = []
    if descriptor.is_empty():
        return points
    var cell: Vector2i = parse_cell(str(descriptor["cell"]))
    var city_x: float = float(cell.x)*Ward.TILE_M
    var door: Vector3 = descriptor["target"]
    var road_z: float = Ward.origin(cell).z+64.0
    points.append(DOCK_AT)
    points.append(Vector3(0,0.84,1382))
    points.append(Vector3(0,0.84,1360))
    points.append(Vector3(city_x,0.84,1360))
    points.append(Vector3(city_x,0.84,road_z))
    points.append(door+Vector3(float(Interiors.site(cell)["inward"])*2.2,0,0))
    # The last point is outside the official workroom, keeping its public
    # open doorway and existing employee unobstructed.
    return points

static func length(points: Array[Vector3]) -> float:
    var total: float = 0.0
    for i in range(1,points.size()):
        total += points[i].distance_to(points[i-1])
    return total

static func courier_state(day: int,wagon: int,elapsed: float) -> Dictionary:
    var points: Array[Vector3] = path(day,wagon)
    if points.size() < 2 or not is_finite(elapsed) or elapsed < 0:
        return {}
    var covered: float = minf(MAX_ELAPSED,elapsed)*DELIVERY_SPEED_MPS
    var dist: float = length(points)
    for i in range(1,points.size()):
        var span: float = points[i-1].distance_to(points[i])
        if covered <= span:
            var weight: float = 1.0 if span < 0.001 else covered/span
            return {"position":points[i-1].lerp(points[i],weight),
                "activity":"carrying_public_crate", "segment":i,
                "arrived":false,"progress":clampf(elapsed*DELIVERY_SPEED_MPS/dist,0,1),
                "game_only":true}
        covered -= span
    return {"position":points.back(),"activity":"received_at_venue",
        "segment":points.size()-1,"arrived":true,"progress":1.0,"game_only":true}

static func stock(state: Dictionary,cell: Vector2i) -> int:
    if not Ward.allowed(cell):
        return 0
    return clampi(int(state.get("stock",{}).get(Ward.key(cell),INITIAL_STOCK)),
        0,STOCK_LIMIT)

static func queue(state: Dictionary,day: int,wagon: int) -> Dictionary:
    var result: Dictionary = clean(state)
    var d: Dictionary = delivery(day,wagon)
    if d.is_empty() or result["receipts"].has(d["receipt"]) \
            or result["pending"].has(d["receipt"]) \
            or result["pending"].size() >= MAX_PENDING:
        return {"accepted":false,"ledger":result}
    result["pending"][d["receipt"]]={"site":d["site"],"elapsed":0.0}
    return {"accepted":true,"ledger":result,"manifest":d}

static func advance(state: Dictionary,receipt: String,elapsed: float) -> Dictionary:
    var result: Dictionary = clean(state)
    if not result["pending"].has(receipt):
        return {"completed":false,"ledger":result}
    var info: Dictionary = receipt_parse(receipt)
    var packet: Dictionary = result["pending"][receipt]
    if info.is_empty() or not is_finite(elapsed) or elapsed < 0.0:
        return {"completed":false,"ledger":result}
    var moved: float = clampf(float(packet["elapsed"])+elapsed,0,MAX_ELAPSED)
    var courier: Dictionary = courier_state(int(info["day"]),int(info["wagon"]),moved)
    if courier.is_empty():
        return {"completed":false,"ledger":result}
    packet["elapsed"] = moved
    result["pending"][receipt] = packet
    if not bool(courier["arrived"]):
        return {"completed":false,"ledger":result,"courier":courier}
    var manifest: Dictionary = delivery(int(info["day"]),int(info["wagon"]))
    var cell: Vector2i = parse_cell(str(manifest["cell"]))
    result["stock"][str(manifest["cell"])] = mini(
        STOCK_LIMIT, stock(result,cell)+int(manifest["units"]))
    result["receipts"][receipt] = true
    result["pending"].erase(receipt)
    return {"completed":true,"ledger":clean(result),"manifest":manifest,"courier":courier}

static func visitor(cell: Vector2i,minutes: float) -> Dictionary:
    if not Ward.allowed(cell) or not is_finite(minutes) or minutes < 0.0:
        return {}
    var t: float = fposmod(minutes,1440.0)
    var present: bool = t >= VISIT_START and t < VISIT_END
    var resident: Dictionary = Ward.resident(cell,VISITOR_INDEX)
    return {"resident":resident["id"],"name":resident["name"],
        "household":resident["household"],"present":present,
        "activity":"visiting_neighborhood_common_table" if present else "normal_daily_schedule",
        "canon_status":"game_only"}
