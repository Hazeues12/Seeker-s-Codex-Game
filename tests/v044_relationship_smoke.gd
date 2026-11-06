extends Node

# Runs only in isolated GitHub Actions workspace, not in players' browsers.
const CodexScript = preload("res://systems/personal_codex.gd")

func _ready() -> void:
    call_deferred("_check")

func _check() -> void:
    var codex: Node = CodexScript.new()
    codex._load_profile()
    var npc: String = "npc_ring2_noodles"
    var size_before: int = (codex.profile.get("history", []) as Array).size()
    var a: bool = codex.remember_social_choice(npc, "Noodle Vendor", "respect", "Showed respect", "The vendor remembers.", 1)
    var b: bool = codex.remember_social_choice(npc, "Noodle Vendor", "respect", "Showed respect", "The vendor remembers.", 1)
    if not a or b or codex.get_contact_rapport(npc) != 1 or (codex.profile.get("history", []) as Array).size() != size_before + 1:
        push_error("V0.44 first/duplicate choice test failed")
        get_tree().quit(1)
        return
    var loaded: Node = CodexScript.new()
    loaded._load_profile()
    if not loaded.has_social_choice(npc, "respect") or loaded.get_contact_rapport(npc) != 1:
        push_error("V0.44 save reload test failed")
        get_tree().quit(1)
        return
    loaded.free()
    codex.free()
    print("V0.44 SOCIAL MEMORY SMOKE PASS")
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://seeker_profile_v1.json"))
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://seeker_profile_v1.pending.json"))
    get_tree().quit(0)
