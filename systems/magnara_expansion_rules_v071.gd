extends RefCounted
# V0.71: independent, adjacent expansion to 15 V0.67 public blocks.
# 30 NEW physically streamable Ring II ward blocks: 180 new game-only
# building shells and 360 procedurally scheduled game-only residents.
const Previous = preload("res://systems/magnara_stream_rules_v067.gd")
const TILE_M: float = Previous.TILE_M
const Z_START: float = Previous.Z_START
const PARCELS: int = 6
const PEOPLE: int = 12
const MAX_ACTIVE: int = 9
const LOAD_BUDGET: int = 2
const CLOSE_M: float = 20.0
const MID_M: float = 100.0
const COLLIDER_M: float = 78.0
const TICK_SECONDS: float = 0.42
const SEED: int = 150071
const JOBS: Array[String] = [
    "warehouse sorter","wagon loader","tailor's assistant","street cook",
    "sailcloth stitcher","rail clerk","canal upkeep worker","carter",
    "public records clerk","courier","dock supply broker","baker",
    "joinery apprentice","night porter","repair worker","shop aide"
]
const PERSONALITIES: Array[String] = [
    "patient","inventive","observant","careful","cheerful","ambitious",
    "reserved","kind","skeptical","practical","talkative","thoughtful"
]
const FIRST: Array[String] = [
    "Anya","Borin","Cella","Daran","Eira","Faren","Galen","Hira",
    "Isen","Jori","Kasa","Lenn","Maro","Nalla","Orin","Pela",
    "Rian","Sela","Taran","Una","Viri","Wynn"
]
const LAST: Array[String] = [
    "Berr","Cald","Dael","East","Fenn","Grey","Hart","Iver",
    "Jas","Kell","Lark","Morn","Nash","Oll","Pike","Rell",
    "Stone","Vale","Wren"
]
const COLORS: Array[Color] = [
    Color(0.56,0.48,0.38),Color(0.45,0.49,0.52),Color(0.58,0.54,0.48),
    Color(0.40,0.45,0.44),Color(0.54,0.43,0.42),Color(0.47,0.40,0.49)
]
const MODULES: Array[String] = ["ground","middle","roof","window","awning","balcony"]

static func allowed(cell: Vector2i) -> bool:
    return (abs(cell.x) == 2 and cell.y >= 0 and cell.y <= 8) or \
        (abs(cell.x) <= 1 and cell.y >= 5 and cell.y <= 8)

static func all_cells() -> Array[Vector2i]:
    var out: Array[Vector2i] = []
    for y in range(9):
        for x in range(-2,3):
            var c := Vector2i(x,y)
            if allowed(c):
                out.append(c)
    return out

static func key(cell: Vector2i) -> String:
    return "%d:%d" % [cell.x,cell.y]

static func cell_for(point: Vector3) -> Vector2i:
    return Vector2i(floori((point.x + TILE_M*0.5)/TILE_M),
        floori((point.z-Z_START)/TILE_M))

static func origin(cell: Vector2i) -> Vector3:
    return Vector3(float(cell.x)*TILE_M,0.0,Z_START+float(cell.y)*TILE_M)

static func center(cell: Vector2i) -> Vector3:
    return origin(cell)+Vector3(0,0,TILE_M*0.5)

static func nearby(point: Vector3) -> Array[Vector2i]:
    var current: Vector2i = cell_for(point)
    var found: Array[Vector2i] = []
    for dx in range(-1,2):
        for dy in range(-1,2):
            var cell := current+Vector2i(dx,dy)
            if allowed(cell):
                found.append(cell)
    found.sort_custom(func(a: Vector2i,b: Vector2i) -> bool:
        var da: float = center(a).distance_squared_to(point)
        var db: float = center(b).distance_squared_to(point)
        return key(a) < key(b) if is_equal_approx(da,db) else da < db
    )
    return found

static func stable(cell: Vector2i, salt: int, size: int) -> int:
    if size <= 0:
        return 0
    return posmod(SEED+(cell.x+37)*92821+(cell.y+51)*68917+salt*31531,size)

static func parcel(cell: Vector2i, slot: int) -> Dictionary:
    if not allowed(cell) or slot < 0 or slot >= PARCELS:
        return {}
    var floors: int = 1+stable(cell,slot*5+8,5)
    var centre: Vector3 = Vector3(-35.0 if slot%2==0 else 35.0,0,
        [27.0,64.0,101.0][int(slot/2)])
    return {"id":"ward_v071_%s_%d" % [key(cell),slot],"slot":slot,
        "center":centre,"width":19.0+float(stable(cell,slot*3+4,6)),
        "depth":17.0+float(stable(cell,slot*7+9,7)),
        "height":3.2+float(floors)*2.75,"floors":floors,
        "palette":stable(cell,slot*11+2,COLORS.size()),
        "kind":["home","workshop","tenement","shop_shell","guild_tenancy","warehouse"][stable(cell,slot*4+3,6)],
        "canon_status":"game_only_massing"}

static func resident(cell: Vector2i, number: int) -> Dictionary:
    if not allowed(cell) or number < 0 or number >= PEOPLE:
        return {}
    var token: int = stable(cell,number*31+13,2048)
    var home_index: int = int(number/3)
    return {"id":"ward_v071_%d_%d_%d" % [cell.x,cell.y,number],
        "name":FIRST[posmod(token+number,FIRST.size())]+" "+
            LAST[posmod(int(token/9)+number*2,LAST.size())],
        "role":JOBS[stable(cell,number*17,JOBS.size())],
        "personality":PERSONALITIES[stable(cell,number*13+5,PERSONALITIES.size())],
        "household":"ward_household_v071_%d_%d_%d" % [cell.x,cell.y,home_index],
        "home_parcel":home_index % PARCELS,
        "work_parcel":(home_index+2+number%3)%PARCELS,
        "kind":"game_only","canon_status":"game_only",
        "secret_powers":[],"district":"Magnara Ring II / extended public ward"}

static func resident_state(cell: Vector2i, number: int, minutes: float) -> Dictionary:
    var identity: Dictionary = resident(cell,number)
    if identity.is_empty():
        return {}
    var t: float = fposmod(maxf(0.0,minutes)+float(stable(cell,number*3+7,80)),1440.0)
    var work: bool = t >= 360 and t < 1140
    var shift: String = "resting" if not work else ("commuting" if t < 520 else (
        "on_shift" if t < 890 else ("local_trade" if t < 1020 else "returning_home")))
    var u: float = fposmod(t*(0.016+float(number%4)*0.003)+float(number)*0.27,2.0)
    var along: float = 1.0-absf(u-1.0)
    var side: float = -1.0 if number%2 == 0 else 1.0
    return {"id":identity["id"],"visible":work,"activity":shift,
        "world_position":origin(cell)+Vector3(side*9.7,0.81,14.0+along*104.0),
        "household":identity["household"]}

static func lod(distance: float, visible: bool) -> String:
    if not visible or distance > MID_M:
        return "far"
    return "close" if distance <= CLOSE_M else "mid"

static func totals() -> Dictionary:
    var count: int = all_cells().size()
    return {"new_cells":count,"new_buildings":count*PARCELS,
        "new_named_game_only_civilians":count*PEOPLE,
        "combined_v067_cells":count+15,
        "combined_v067_buildings":count*PARCELS+90,
        "combined_v067_game_only_civilians":count*PEOPLE+75}
