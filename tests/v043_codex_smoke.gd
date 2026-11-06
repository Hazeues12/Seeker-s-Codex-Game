extends SceneTree

# Headless test of the additive Codex journal. Does not load or change gameplay saves.
const CodexScript = preload("res://systems/personal_codex.gd")

func _initialize() -> void:
    call_deferred("_smoke")

func _smoke() -> void:
    var codex: Node = CodexScript.new()
    codex._load_profile()
    var original_size: int = (codex.profile.get("history", []) as Array).size()
    codex.record_event("v043:smoke:event", "npc_met", "Smoke test contact", "Test-only record")
    var first_size: int = (codex.profile.get("history", []) as Array).size()
    codex.record_event("v043:smoke:event", "npc_met", "Smoke test contact", "Test-only record")
    var dedup_size: int = (codex.profile.get("history", []) as Array).size()
    if first_size != original_size + 1 or dedup_size != first_size:
        push_error("V0.43 failed event append/dedup test")
        quit(1)
        return
    if not FileAccess.file_exists("user://seeker_profile_v1.json"):
        push_error("V0.43 failed persistence test: no profile file")
        quit(1)
        return
    var reloaded: Node = CodexScript.new()
    reloaded._load_profile()
    var stored_size: int = (reloaded.profile.get("history", []) as Array).size()
    if stored_size != dedup_size:
        push_error("V0.43 failed save-load roundtrip")
        quit(1)
        return
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://seeker_profile_v1.json"))
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://seeker_profile_v1.pending.json"))
    print("V0.43 Codex persistence, event deduplication and reload passed")
    quit(0)
