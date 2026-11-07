extends Node3D
const Ward = preload("res://systems/magnara_expansion_rules_v071.gd")
const V072 = preload("res://systems/magnara_interiors_rules_v072.gd")
const Rules = preload("res://systems/magnara_local_logistics_rules_v073.gd")
const Trade = preload("res://systems/margerina_commerce_rules_v071.gd")

func _ready() -> void:
    call_deferred("_validate")

func _fail(message: String) -> void:
    push_error("V0.73 LOCAL FREIGHT HOUSEHOLD RULES FAILED: "+message)
    get_tree().call_deferred("quit",1)

func _validate() -> void:
    if Rules.WAGON_COUNT != Trade.WAGON_COUNT or Rules.STOCK_LIMIT > 20 \
            or Rules.DELIVERY_UNITS != 4 or Rules.MAX_PENDING > 3:
        _fail("game-only local freight cost/cap differs from three actual V0.71 wagons")
        return
    var targets: Dictionary = {}
    for day in range(1,5):
        for wagon in range(3):
            var manifest: Dictionary = Rules.delivery(day,wagon)
            if manifest.is_empty() or manifest.get("money_transfer",1) != 0 \
                    or manifest.get("crosses_national_border",true):
                _fail("fabricated foreign commercial route or public Tola payment")
                return
            if targets.has(manifest["cell"]) or manifest.get("canon_status","") != "game_only_local":
                _fail("first 4 days should serve 12 unique reachable Ring II public rooms")
                return
            targets[manifest["cell"]] = true
            var cell: Vector2i = Rules.parse_cell(str(manifest["cell"]))
            if not Ward.allowed(cell) or cell.y != Rules.FIRST_ROW+day-1:
                _fail("shipment mapped outside existing known Ring II")
                return
            var path: Array[Vector3] = Rules.path(day,wagon)
            if path.size() < 6 or path.front() != Rules.DOCK_AT:
                _fail("no physical street waypoint route for its package")
                return
            if path.back().distance_to(manifest["target"]) > 2.21 \
                    or path.back().distance_to(manifest["target"]) < 2.19:
                _fail("cargo carrier must finish outside the open front door")
                return
            if Rules.length(path) < 30.0:
                _fail("cargo route shortcuts directly through a building")
                return
            var at_station: Dictionary = Rules.courier_state(day,wagon,0.0)
            var after: Dictionary = Rules.courier_state(day,wagon,2.0)
            var arrived: Dictionary = Rules.courier_state(day,wagon,Rules.MAX_ELAPSED)
            if at_station.get("position",Vector3.ONE) != Rules.DOCK_AT \
                    or at_station.get("arrived",true) or after.get("arrived",true) \
                    or not bool(arrived.get("arrived",false)):
                _fail("courier starts outside depot, teleports, or never reaches the workroom")
                return
    if targets.size() != 12 or not Rules.delivery(0,0).is_empty() \
            or not Rules.delivery(1,3).is_empty():
        _fail("unbounded or unauthorised shipments generated")
        return
    if Rules.receipt_parse(Rules.receipt_key(1,2)).get("wagon",-1) != 2 \
            or not Rules.receipt_parse("v073_d-5_w0").is_empty() \
            or not Rules.receipt_parse("fake_v073_d000001_w0").is_empty():
        _fail("receipt identity can be forged or matches incorrect wagon")
        return

    var wallet: int = 500
    var original: Dictionary = Rules.clean({})
    var first: Dictionary = Rules.queue(original,1,1)
    if not bool(first.get("accepted",false)) or not Rules.clean(first["ledger"])["pending"].has(
            Rules.receipt_key(1,1)):
        _fail("physical wagon arrival didn't enqueue local public consignment")
        return
    var repeat: Dictionary = Rules.queue(first["ledger"],1,1)
    if bool(repeat.get("accepted",true)):
        _fail("one wagon can create duplicate cargo before its courier completes")
        return
    var cell: Vector2i = Rules.parse_cell(str(first["manifest"]["cell"]))
    if Rules.stock(first["ledger"],cell) != Rules.INITIAL_STOCK:
        _fail("warehouse inventory credited before actual courier delivery")
        return
    var partial: Dictionary = Rules.advance(first["ledger"],Rules.receipt_key(1,1),1.0)
    if bool(partial.get("completed",true)) or Rules.stock(partial["ledger"],cell) != Rules.INITIAL_STOCK:
        _fail("courier goods materialize before physical route completion")
        return
    var committed: Dictionary = Rules.advance(partial["ledger"],Rules.receipt_key(1,1),Rules.MAX_ELAPSED)
    if not bool(committed.get("completed",false)) \
            or Rules.stock(committed["ledger"],cell) != Rules.INITIAL_STOCK+Rules.DELIVERY_UNITS:
        _fail("arrival failed to apply one bounded local-stock receipt")
        return
    if committed["ledger"]["pending"].has(Rules.receipt_key(1,1)) \
            or not committed["ledger"]["receipts"].has(Rules.receipt_key(1,1)):
        _fail("committed shipment retained a pending/duplicate receipt")
        return
    if bool(Rules.queue(committed["ledger"],1,1).get("accepted",true)) \
            or bool(Rules.advance(committed["ledger"],Rules.receipt_key(1,1),50).get("completed",true)):
        _fail("reload or repeated callback doubles the same day's public goods")
        return
    if wallet != 500 or Rules.stock(Rules.clean(committed["ledger"]),cell) != 6:
        _fail("local stock alters player currency or fails to survive verification")
        return
    var invalid: Dictionary = Rules.clean({"stock":{"2:99":100000,"0:5":-500,
        "0:6":999999}, "receipts":{"forged":true},
        "pending":{"v073_d000001_w1":{"site":"garbage","elapsed":1}}})
    if invalid["stock"].size() > 0 or invalid["receipts"].size() > 0 \
            or invalid["pending"].size() > 0:
        _fail("tampered ledger can inject huge stocks, fake receipts, or wrong sites")
        return

    for ward in Ward.all_cells():
        var guest: Dictionary = Rules.visitor(ward,1100.0)
        var absent: Dictionary = Rules.visitor(ward,800.0)
        var citizen: Dictionary = Ward.resident(ward,Rules.VISITOR_INDEX)
        if guest.is_empty() or not bool(guest["present"]) or bool(absent["present"]) \
                or str(guest["resident"]) != str(citizen["id"]):
            _fail("an existing night visitor identity or actual schedule is missing")
            return
        var street: Dictionary = Ward.resident_state(ward,Rules.VISITOR_INDEX,1100.0)
        if bool(street.get("visible",true)) \
                or not bool(street.get("evening_household_visit",false)) \
                or street.get("id","") != citizen["id"]:
            _fail("visitor is duplicated in the outside and inside 3D populations")
            return
        if not bool(V072.staff_schedule(ward,800.0).get("on_shift",false)):
            _fail("existing daytime worker schedule was erased")
            return
    if Ward.totals()["new_buildings"] != 180 or Ward.totals()["new_named_game_only_civilians"] != 360:
        _fail("V0.71 expanded city changed its canonical-safety population cap")
        return
    print("V0.73 PHYSICAL PUBLIC WAGON COURIER STOCK ON ARRIVAL ONCE ONLY VERIFIED RECEIPTS TWELVE WARDS AND HOUSEHOLD NIGHT VISITS PASS")
    get_tree().call_deferred("quit",0)
