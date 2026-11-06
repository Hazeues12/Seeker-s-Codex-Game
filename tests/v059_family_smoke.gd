extends Node3D

const Family = preload("res://systems/young_blood_family_v059.gd")
const TEMP_FILE: String = "user://v059_family_rules_smoke.json"

func _ready() -> void:
    call_deferred("_run")

func _fail(why: String) -> void:
    push_error("V0.59 FAMILY RULES FAILED: " + why)
    get_tree().call_deferred("quit", 1)

func _run() -> void:
    if Family.FAMILY_IDS.size() != 6 or Family.FAMILY_NAMES.size() != 6:
        _fail("family roster must be six provisional choices")
        return
    if not Family.sanitize({}).is_empty() or Family.courier_adjustment({}) != 0:
        _fail("legacy save fallback is broken")
        return
    for family_id in Family.FAMILY_IDS:
        for visibility in Family.DISCLOSURES:
            var record: Dictionary = Family.choose_once({}, family_id, "complicated", visibility)
            if record.is_empty() or Family.sanitize(record) != record:
                _fail("family choice rejected " + family_id)
                return
            if bool(record["viatra_access"]) or bool(record["bloodline_confirmed"]):
                _fail("claim unlocked a restricted bloodline")
                return
            if str(record["ocular_license"]) != "none" or str(record["family_privilege"]) != "none":
                _fail("claim falsely granted access or privilege")
                return
            if not Family.choose_once(record, "common_line", "supportive", "public").is_empty():
                _fail("sealed family record could be rewritten")
                return
            if not Family.request_archive(record).is_empty():
                var reviewed: Dictionary = Family.request_archive(record)
                if not bool(reviewed.get("archive_requested", false)):
                    _fail("archive request did not set a persistent flag")
                    return
                if not Family.request_archive(reviewed).is_empty():
                    _fail("duplicate archive inquiry was accepted")
                    return
                if bool(reviewed.get("viatra_access", true)):
                    _fail("archive inquiry unlocked inherited eyes")
                    return
    if not Family.choose_once({}, "nightshade_tukoyami", "supportive", "public").is_empty():
        _fail("unapproved family branch was allowed")
        return
    if not Family.choose_once({}, Family.RESTRICTED_LINE, "devoted", "public").is_empty():
        _fail("invalid household tie was allowed")
        return
    var public_black: Dictionary = Family.choose_once({}, Family.RESTRICTED_LINE, "estranged", "public")
    var private_black: Dictionary = Family.choose_once({}, Family.RESTRICTED_LINE, "supportive", "private")
    if Family.attention(public_black) != 2 or Family.attention(private_black) != 0:
        _fail("disclosure did not create relative institutional attention")
        return
    if Family.courier_adjustment(private_black) != 1 or Family.courier_adjustment(public_black) != -1:
        _fail("household bonds have no game consequence")
        return
    var private_petition: Dictionary = Family.request_archive(private_black)
    if Family.attention(private_petition) != 1 or str(private_petition["disclosure"]) != "private":
        _fail("confidential Black Clan inquiry either erased privacy or lacked a consequence")
        return
    if Family.relationship_response(public_black, "npc_ring2_register").find("unverified") < 0:
        _fail("registrar does not challenge a public ancestry claim")
        return
    if Family.relationship_response(public_black, "npc_ring2_sentry").find("authorization") < 0:
        _fail("Citadel sentry must preserve rank and gate rules")
        return
    if not Family.relationship_response(private_black, "npc_ring2_sentry").is_empty():
        _fail("private family claim was broadcast to guards")
        return
    var forged: Dictionary = public_black.duplicate(true)
    forged["bloodline_confirmed"] = true
    forged["viatra_access"] = true
    forged["ocular_license"] = "Viatra stage V"
    forged["lineage_status"] = "canon_verified"
    forged["family_privilege"] = "Citadel access"
    var clean: Dictionary = Family.sanitize(forged)
    if bool(clean["bloodline_confirmed"]) or bool(clean["viatra_access"]) or clean["lineage_status"] != "unverified_claim":
        _fail("malicious save granted secret powers or canon identity")
        return
    var storage := FileAccess.open(TEMP_FILE, FileAccess.WRITE)
    if storage == null:
        _fail("isolated file storage unavailable")
        return
    storage.store_string(JSON.stringify(private_petition))
    storage.close()
    storage = FileAccess.open(TEMP_FILE, FileAccess.READ)
    if storage == null:
        _fail("isolated file reload unavailable")
        return
    var loaded: Variant = JSON.parse_string(storage.get_as_text())
    storage.close()
    DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_FILE))
    if Family.sanitize(loaded) != private_petition or Family.attention(loaded) != 1:
        _fail("archival inquiry or privacy was lost on reload")
        return
    print("V0.59 FAMILY PRIVACY INSTITUTIONAL CONSEQUENCES AND SAVE RULES PASS")
    get_tree().call_deferred("quit", 0)
