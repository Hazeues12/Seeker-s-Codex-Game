extends Node

# Headless non-interactive smoke test. Runs inside Actions, no browser storage shared.
const CodexScript = preload("res://systems/personal_codex.gd")
const SocietyScript = preload("res://systems/seeker_society.gd")

func _ready() -> void:
    call_deferred("_test")

func _assert(ok: bool, message: String) -> bool:
    if not ok:
        push_error("V0.45 SMOKE FAIL: " + message)
        get_tree().quit(1)
        return false
    return true

func _test() -> void:
    var data_file: String = ProjectSettings.globalize_path("user://seeker_profile_v1.json")
    DirAccess.remove_absolute(data_file)
    var codex: Node = CodexScript.new()
    codex._load_profile()
    var social: Node = SocietyScript.new()
    add_child(social)
    social.codex = codex
    GameState.tola = 150
    var rapport: bool = bool(codex.remember_social_choice("npc_ring2_noodles", "Noodle Vendor", "respect", "Respect", "Thanks", 1))
    if not _assert(rapport, "base social rapport"):
        return
    if not _assert(bool(social.act("npc_ring2_noodles", "start_delivery").get("ok", false)), "start delivery"):
        return
    if not _assert(social.get_quest_status("canal_delivery") == "active", "quest active"):
        return
    if not _assert(not bool(social.act("npc_ring2_noodles", "start_delivery").get("ok", false)), "cannot start duplicate"):
        return
    if not _assert(bool(social.act("npc_ring2_canal", "finish_delivery").get("ok", false)), "finish delivery"):
        return
    if not _assert(social.get_reputation("local_respect") == 2, "reputation from delivery"):
        return
    var codex_reload: Node = CodexScript.new()
    codex_reload._load_profile()
    social.codex = codex_reload
    if not _assert(social.get_quest_status("canal_delivery") == "completed", "save and reload quest"):
        return
    if not _assert(social.get_decision("delivery:resolution") == "finish_delivery", "exclusive outcome saved"):
        return
    if not _assert(not bool(social.act("npc_ring2_canal", "sell_delivery_info").get("ok", false)), "cannot betray resolved job"):
        return
    if not _assert(bool(social.act("npc_ring2_noodles", "confirm_adult").get("ok", false)), "player adult opt-in"):
        return
    if not _assert(bool(social.act("npc_ring2_noodles", "flirt").get("ok", false)), "mutual flirt"):
        return
    if not _assert(bool(social.act("npc_ring2_noodles", "invite_date").get("ok", false)), "adult courtship"):
        return
    if not _assert(social.get_romance_status("npc_ring2_noodles") == "courting", "romance saved"):
        return
    if not _assert(bool(social.act("npc_ring2_sentry", "bribe_gate").get("ok", false)), "bribe attempt recorded"):
        return
    if not _assert(social.get_reputation("association_trust") == -3, "professional sanction"):
        return
    var last_codex: Node = CodexScript.new()
    last_codex._load_profile()
    social.codex = last_codex
    if not _assert(social.get_reputation("association_trust") == -3, "reputation survived reload"):
        return
    if not _assert(social.get_romance_status("npc_ring2_noodles") == "courting", "romance survived reload"):
        return
    if not _assert(not bool(social.act("npc_ring2_sentry", "respect_gate").get("ok", false)), "bribe and respect mutually exclusive"):
        return
    print("V0.45 SOCIETY OUTCOMES SMOKE PASS")
    DirAccess.remove_absolute(data_file)
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://seeker_profile_v1.pending.json"))
    remove_child(social)
    social.free()
    codex.free()
    codex_reload.free()
    last_codex.free()
    get_tree().call_deferred("quit", 0)
