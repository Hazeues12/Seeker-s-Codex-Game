extends RefCounted
# V0.71 observable PUBLIC logistics; country pairings are HYPOTHETICAL
# gameplay lane labels, not confirmed geographic/cultural commercial treaties.
# No phantom currencies, hidden Order shipments, or Abyssal shipping.
const REGISTRY: String = "res://data/margerina_water_commerce_registry_v071.json"
const SHIP_COUNT: int = 6
const WAGON_COUNT: int = 3
const DOCK_CYCLE_SEC: float = 160.0
const SHIP_DEPART_X: float = -225.0
const SHIP_HORIZON_X: float = 460.0
const LAND_Z0: float = 732.0
const LAND_Z1: float = 1400.0
const SAFE_CARGO: Array[String] = [
    "sealed dry-goods","machine parts","cloth rolls","bulk grain","household metalwork","general provisions"
]

static func registry() -> Dictionary:
    var file := FileAccess.open(REGISTRY,FileAccess.READ)
    if file == null:
        return {}
    var data: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    return data if typeof(data) == TYPE_DICTIONARY else {}

static func valid_registry(data: Dictionary) -> bool:
    if str(data.get("era","")) != "1500 A.S." or str(data.get("scope","")) != "known_world_only":
        return false
    var names: Dictionary = {}
    for w in data.get("waters",[]):
        var id: String = str(w.get("id",""))
        if id.is_empty() or names.has(id) or not ["sea","gulf","strait","ocean","lake","river"].has(str(w.get("class",""))):
            return false
        names[id] = true
        if str(w.get("class","")) in ["lake","river"] and not w.has("physical_map_status"):
            return false
    var lake: Dictionary = {}
    for w in data.get("waters",[]):
        if str(w.get("id","")) == "lake_lukka":
            lake = w
    if lake.get("nation","") != "Africanus":
        return false
    if data.get("harbors",[]).size() != 2:
        return false
    var sea: Array = data.get("maritime_simulation",[])
    if sea.size() != SHIP_COUNT:
        return false
    for route in sea:
        if route.get("origin","") != "Janoah" or not str(route.get("status","")).begins_with("game_only") \
                or not ["small","medium","large"].has(str(route.get("ship_class",""))):
            return false
        if route.get("destination","") in ["Terragigantus","Zuba","Abyssal Ocean"]:
            return false
        if not names.has(str(route.get("known_water_reference",""))):
            return false
    for route in data.get("land_simulation",[]):
        if not str(route.get("status","")).begins_with("game_only"):
            return false
    return true

static func ship_manifest(index: int, day: int, data: Dictionary) -> Dictionary:
    if index < 0 or index >= SHIP_COUNT or day < 1 or not valid_registry(data):
        return {}
    var route: Dictionary = data["maritime_simulation"][index]
    return {"id":"ship_v071_%d" % index,
        "label":"Public Cargo Vessel %02d" % (index+1),
        "destination":route["destination"],"origin":route["origin"],
        "sea":route["known_water_reference"],"size":route["ship_class"],
        "cargo":SAFE_CARGO[posmod(day+index*2,SAFE_CARGO.size())],
        "cargo_units":(index+2+posmod(day,5))*3,
        "status":"game_only_trade_preview",
        "arrives_at_nation":false,"military":false}

static func ship_state(index: int, seconds: float, day: int,
        data: Dictionary) -> Dictionary:
    var manifest: Dictionary = ship_manifest(index,day,data)
    if manifest.is_empty() or not is_finite(seconds):
        return {}
    var ship_size: String = str(manifest["size"])
    var pace: float = [0.80,1.0,1.23][["small","medium","large"].find(ship_size)]
    var cycle: float = DOCK_CYCLE_SEC * pace
    var offset: float = fposmod(seconds + float(index)*17.0,cycle)/cycle
    var travel: float = 0.0
    var action: String = "docked"
    if offset < 0.10:
        travel = 0.0
        action = "loading"
    elif offset < 0.47:
        travel = (offset-0.10)/0.37
        action = "outbound"
    elif offset < 0.55:
        travel = 1.0
        action = "beyond_scenic_horizon"
    elif offset < 0.94:
        travel = 1.0-(offset-0.55)/0.39
        action = "inbound"
    else:
        travel = 0.0
        action = "unloading"
    var z: float = -250.0 + float(index)*100.0
    return {"id":manifest["id"],"pos":Vector3(lerpf(SHIP_DEPART_X,SHIP_HORIZON_X,travel),0,z),
        "direction":-1.0 if action == "inbound" else 1.0,
        "activity":action,"offscreen":action == "beyond_scenic_horizon",
        "load_fraction":travel,"manifest":manifest}

static func wagon_state(index: int, seconds: float, day: int,
        data: Dictionary) -> Dictionary:
    if index < 0 or index >= WAGON_COUNT or day < 1 or not valid_registry(data):
        return {}
    var route: Dictionary = data["land_simulation"][index]
    var period: float = 225.0 + float(index)*37.0
    var motion: float = fposmod(seconds + float(index)*48.0,period)/period
    var forward: bool = motion <= 0.50
    var progress: float = motion*2.0 if forward else (1.0-motion)*2.0
    var x: float = [-2.2,0.0,2.2][index]
    return {"id":"wagon_v071_%d" % index,
        "pos":Vector3(x,1.05,lerpf(LAND_Z0,LAND_Z1,progress)),
        "activity":"city_bound" if forward else "returning_to_trade_route",
        "destination":route["destination"],"origin":route["origin"],
        "cargo":SAFE_CARGO[posmod(day+index,SAFE_CARGO.size())],
        "game_only":true,"real_foreign_border_crossing":false}

static func public_summary(day: int, seconds: float, data: Dictionary) -> Dictionary:
    if day < 1 or not valid_registry(data):
        return {}
    var arrivals: int = 0
    var loading: int = 0
    var underway: int = 0
    for i in range(SHIP_COUNT):
        var current: Dictionary = ship_state(i,seconds,day,data)
        match str(current.get("activity","")):
            "loading","unloading":
                loading += 1
            "inbound":
                arrivals += 1
            "outbound":
                underway += 1
    return {"day":day,"ships_simulated":SHIP_COUNT,"wagons_simulated":WAGON_COUNT,
        "loading_berths":loading,"inbound":arrivals,"outbound":underway,
        "trade_data":"local_visual_preview_not_true_arrival_or_country_cargo_records",
        "unlocked_beyond_abyssal":false}
