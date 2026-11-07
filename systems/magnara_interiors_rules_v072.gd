extends RefCounted
# V0.72: one GAME-ONLY, ground-floor public venue in each of the thirty
# new V0.71 wards. These aren't named series establishments, owners or
# finished architectural plans. The storefronts remain public/non-secret.
const Wards = preload("res://systems/magnara_expansion_rules_v071.gd")
const VENUE_SLOT: int = 2
const STAFF_INDEX: int = 11
const VENUES_TOTAL: int = 30
const STAFF_START_MINUTES: float = 550.0
const STAFF_END_MINUTES: float = 1050.0
const MAX_LOADED: int = 9
const FIRST_FLOOR_HEIGHT: float = 3.20
const PUBLIC_DOOR_WIDTH: float = 2.40
const DOOR_HEIGHT: float = 2.30
const VENUES: Array[String] = [
    "Public Tailoring Workroom", "Merchant Ledger Annex",
    "Neighborhood Common Room", "Wagonwright Workroom",
    "Public Print Shop", "Supply Sorting Studio"
]
const PUBLIC_TASKS: Array[String] = [
    "folding textiles", "checking receipts", "hosting neighbors",
    "assembling cart fittings", "setting public notices", "sorting supplies"
]

static func site(cell: Vector2i) -> Dictionary:
    if not Wards.allowed(cell):
        return {}
    var parcel: Dictionary = Wards.parcel(cell, VENUE_SLOT)
    if parcel.is_empty():
        return {}
    var c: Vector3 = parcel["center"]
    var width: float = float(parcel["width"])
    var depth: float = float(parcel["depth"])
    var inward: float = 1.0 if c.x < 0.0 else -1.0
    var kind: int = Wards.stable(cell,170,VENUES.size())
    var origin: Vector3 = Wards.origin(cell)
    var door_local: Vector3 = Vector3(c.x+inward*width*0.5,0.84,c.z)
    var staff_local: Vector3 = c+Vector3(-inward*2.8,0.0,depth*0.19)
    staff_local.y = 0.82
    return {"id":"site_v072_"+Wards.key(cell),
        "label":VENUES[kind], "work":PUBLIC_TASKS[kind],
        "kind":kind, "cell":cell,"parcel":parcel, "center_local":c,
        "door_world":origin+door_local, "staff_world":origin+staff_local,
        "inward":inward,"width":width,"depth":depth,
        "open_ground_floor":true,"owner":"game_only_unassigned",
        "real_furnishings":true,"canon_status":"game_only"}

static func staff_schedule(cell: Vector2i, minutes: float) -> Dictionary:
    if not Wards.allowed(cell) or not is_finite(minutes):
        return {}
    var citizen: Dictionary = Wards.resident(cell,STAFF_INDEX)
    var clock: float = fposmod(maxf(0.0,minutes),1440.0)
    var available: bool = clock >= STAFF_START_MINUTES and clock < STAFF_END_MINUTES
    var activity: String = "at_home"
    if available:
        if clock < 740.0:
            activity = "morning_shift"
        elif clock < 800.0:
            activity = "midday_break"
        elif clock < 980.0:
            activity = "afternoon_shift"
        else:
            activity = "closing_up"
    return {"id":citizen["id"],"name":citizen["name"],"role":citizen["role"],
        "household":citizen["household"],"worksite":site(cell)["id"],
        "on_shift":available, "activity":activity,
        "allowed_public_dialogue":true, "hidden_canon":false}

static func allowed_distance(point: Vector3, cell: Vector2i) -> bool:
    var record: Dictionary = site(cell)
    return not record.is_empty() and point.distance_to(record["door_world"]) <= 4.0

static func inventory_note(cell: Vector2i, day: int) -> Dictionary:
    if not Wards.allowed(cell) or day < 1:
        return {}
    var item: Dictionary = site(cell)
    return {"site":item["id"], "day":day,
        "public_stock_category":item["work"], "game_only":true,
        "tola_payout":0,"phantom_tola":false,
        "personal_trading_ledger":false}
