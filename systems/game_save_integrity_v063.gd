extends RefCounted
# V0.63 resilient game-save writes. The existing save filename/schema never change.
# A new save is written and verified before replacing the valid prior save.
const PRIMARY: String = "user://margerina_v033.json"
const PENDING: String = "user://margerina_v033.pending.json"
const BACKUP: String = "user://margerina_v033.backup.json"

static func _valid(value: Variant) -> bool:
    if typeof(value) != TYPE_DICTIONARY:
        return false
    var data: Dictionary = value
    if int(data.get("version", -1)) != 1:
        return false
    if not data.has("tola") or not data.has("inventory"):
        return false
    if typeof(data["tola"]) != TYPE_INT and typeof(data["tola"]) != TYPE_FLOAT:
        return false
    if float(data["tola"]) < 0.0 or float(data["tola"]) > 1000000000000.0:
        return false
    if typeof(data["inventory"]) != TYPE_DICTIONARY:
        return false
    var items: Dictionary = data["inventory"]
    if items.size() > 500:
        return false
    for key in items.keys():
        var number: Variant = items[key]
        if typeof(number) != TYPE_INT and typeof(number) != TYPE_FLOAT:
            return false
        if float(number) < 0.0 or float(number) > 1000000.0:
            return false
    if data.has("market_stock_v062") and typeof(data["market_stock_v062"]) != TYPE_DICTIONARY:
        return false
    return true

static func _read(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    return parsed if _valid(parsed) else {}

static func load_best(primary: String = PRIMARY, backup: String = BACKUP) -> Dictionary:
    var live: Dictionary = _read(primary)
    if not live.is_empty():
        return {"source": "primary", "data": live}
    var previous: Dictionary = _read(backup)
    if not previous.is_empty():
        return {"source": "backup", "data": previous}
    return {"source": "none", "data": {}}

static func write_verified(data: Dictionary, primary: String = PRIMARY, pending: String = PENDING, backup: String = BACKUP) -> bool:
    if not _valid(data):
        return false
    var previous_exists: bool = FileAccess.file_exists(primary)
    # Never overwrite an unreadable or corrupted user save. Recovery is separate.
    if previous_exists and _read(primary).is_empty():
        return false
    var serialized: String = JSON.stringify(data)
    var file := FileAccess.open(pending, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(serialized)
    file.flush()
    file.close()
    var disk := FileAccess.open(pending, FileAccess.READ)
    if disk == null:
        return false
    var verified_text: String = disk.get_as_text()
    disk.close()
    if verified_text != serialized or _read(pending).is_empty():
        return false
    # Maintain a separately validated previous generation before replacing live.
    if previous_exists:
        if DirAccess.copy_absolute(ProjectSettings.globalize_path(primary), ProjectSettings.globalize_path(backup)) != OK:
            return false
        if _read(backup).is_empty():
            return false
    # Same-directory rename protects against truncated direct writes on supported FS.
    if DirAccess.rename_absolute(ProjectSettings.globalize_path(pending), ProjectSettings.globalize_path(primary)) != OK:
        return false
    return not _read(primary).is_empty()

static func restore_backup(primary: String = PRIMARY, pending: String = PENDING, backup: String = BACKUP) -> bool:
    # Only recover a missing/invalid primary; never replace a valid current game.
    if not _read(primary).is_empty():
        return false
    var older: Dictionary = _read(backup)
    if older.is_empty():
        return false
    var source := FileAccess.open(backup, FileAccess.READ)
    if source == null:
        return false
    var raw: String = source.get_as_text()
    source.close()
    var staged := FileAccess.open(pending, FileAccess.WRITE)
    if staged == null:
        return false
    staged.store_string(raw)
    staged.flush()
    staged.close()
    if _read(pending).is_empty():
        return false
    if DirAccess.rename_absolute(ProjectSettings.globalize_path(pending), ProjectSettings.globalize_path(primary)) != OK:
        return false
    return not _read(primary).is_empty()
