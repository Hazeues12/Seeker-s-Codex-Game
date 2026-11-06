extends Node
const Integrity = preload("res://systems/game_save_integrity_v063.gd")
const LIVE: String = "user://v063_test_live.json"
const STAGED: String = "user://v063_test_staged.json"
const PREVIOUS: String = "user://v063_test_backup.json"

func _ready() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("V0.63 SAVE INTEGRITY FAILED: " + reason)
    get_tree().call_deferred("quit", 1)

func _put(path: String, value: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file != null:
        file.store_string(value)
        file.close()

func _run() -> void:
    for path in [LIVE, STAGED, PREVIOUS]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    var first: Dictionary = {"version": 1, "tola": 100, "inventory": {"Travel Rations": 2}, "market_stock_v062": {"day:1:provisions": 2}, "rank": "Stray"}
    var second: Dictionary = first.duplicate(true)
    second["tola"] = 92
    second["inventory"] = {"Travel Rations": 3}
    second["market_stock_v062"] = {"day:1:provisions": 3}
    if not Integrity.write_verified(first, LIVE, STAGED, PREVIOUS):
        _fail("first save was rejected")
        return
    if not Integrity.write_verified(second, LIVE, STAGED, PREVIOUS):
        _fail("next save was not committed safely")
        return
    var current: Dictionary = Integrity.load_best(LIVE, PREVIOUS)
    if current.get("source", "") != "primary" or int(current["data"].get("tola", -1)) != 92:
        _fail("latest verified save is not the visible game")
        return
    var snapshot: Dictionary = Integrity._read(PREVIOUS)
    if int(snapshot.get("tola", -1)) != 100 or int(snapshot.get("inventory", {}).get("Travel Rations", -1)) != 2:
        _fail("previous generation did not preserve money and inventory together")
        return
    _put(STAGED, "{interrupted_write")
    if int(Integrity.load_best(LIVE, PREVIOUS)["data"].get("tola", -1)) != 92:
        _fail("interrupted pending writes leaked into the live game")
        return
    var bad_payload: Dictionary = {"version": 2, "tola": -500, "inventory": "invalid"}
    if Integrity.write_verified(bad_payload, LIVE, STAGED, PREVIOUS):
        _fail("malformed payload was accepted")
        return
    if int(Integrity._read(LIVE).get("tola", -1)) != 92:
        _fail("bad save damaged the previously committed game")
        return
    _put(LIVE, "{corrupted_primary")
    var fallback: Dictionary = Integrity.load_best(LIVE, PREVIOUS)
    if fallback.get("source", "") != "backup" or int(fallback["data"].get("tola", -1)) != 100:
        _fail("valid previous save cannot be loaded after an interrupted live file")
        return
    if Integrity.write_verified(second, LIVE, STAGED, PREVIOUS):
        _fail("write silently overwrote corrupt source instead of protecting recovery")
        return
    if not Integrity.restore_backup(LIVE, STAGED, PREVIOUS):
        _fail("protected backup could not be restored")
        return
    if int(Integrity._read(LIVE).get("tola", -1)) != 100:
        _fail("recovered game money does not match previous generation")
        return
    if Integrity.restore_backup(LIVE, STAGED, PREVIOUS):
        _fail("restoration replaced an already valid current game")
        return
    if not Integrity.write_verified(second, LIVE, STAGED, PREVIOUS):
        _fail("ordinary saving is blocked even after successful recovery")
        return
    if int(Integrity._read(LIVE).get("inventory", {}).get("Travel Rations", 0)) != 3:
        _fail("normal trading inventory cannot resume after save recovery")
        return
    for path in [LIVE, STAGED, PREVIOUS]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("V0.63 VERIFIED BACKUP ATOMIC GAME SAVE AND INTERRUPTED-WRITE RECOVERY PASS")
    get_tree().call_deferred("quit", 0)
