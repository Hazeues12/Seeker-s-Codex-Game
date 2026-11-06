extends RefCounted
# V0.59: game-only family stories for an original Seeker. These six choices
# were present as names or families in earlier Margerina game prototypes;
# they are NOT claimed to match the undocumented exact v385 six-line roster.
# A claimed line is NEVER proof of bloodline ancestry or an ocular unlock.
const FAMILY_IDS: Array[String] = [
    "common_line", "kairo_black_clan_claim", "wonder_family_branch_claim",
    "abel_sky_talon_branch_claim", "flamehart_war_line_claim",
    "butters_vitalis_line_claim"
]
const FAMILY_NAMES: Array[String] = [
    "Common Line / family unknown", "Kairo / Black Clan claim",
    "Wonder family branch claim", "Abel Sky-Talon branch claim",
    "Flamehart war-family claim", "Butters Vitalis family claim"
]
const BONDS: Array[String] = ["supportive", "complicated", "estranged"]
const DISCLOSURES: Array[String] = ["private", "public"]
const RESTRICTED_LINE: String = "kairo_black_clan_claim"

static func label_for(family: String) -> String:
    var i: int = FAMILY_IDS.find(family)
    return FAMILY_NAMES[i] if i >= 0 else "Unrecorded"

static func new_record(family: String, bond: String, disclosure: String) -> Dictionary:
    if not FAMILY_IDS.has(family) or not BONDS.has(bond) or not DISCLOSURES.has(disclosure):
        return {}
    return {
        "version": 1,
        "family_id": family,
        "bond": bond,
        "disclosure": disclosure,
        "lineage_status": "not_claimed" if family == "common_line" else "unverified_claim",
        "ocular_license": "none",
        "viatra_access": false,
        "bloodline_confirmed": false,
        "archive_requested": false,
        "archive_status": "not_requested",
        "family_privilege": "none",
        "source_status": "original_seeker_game_only"
    }

static func sanitize(value: Variant) -> Dictionary:
    if typeof(value) != TYPE_DICTIONARY:
        return {}
    var raw: Dictionary = value
    var clean: Dictionary = new_record(
        str(raw.get("family_id", "")), str(raw.get("bond", "")),
        str(raw.get("disclosure", "")))
    if clean.is_empty():
        return {}
    if bool(raw.get("archive_requested", false)):
        clean["archive_requested"] = true
        clean["archive_status"] = "pending_evidence" if clean["family_id"] != "common_line" else "not_applicable"
    # In V0.59 there is no evidence-verification quest or legal credentialing.
    # Recalculate restricted flags even if an old/malicious file claimed them.
    return clean

static func choose_once(previous: Variant, family: String, bond: String, disclosure: String) -> Dictionary:
    if not sanitize(previous).is_empty():
        return {}
    return new_record(family, bond, disclosure)

static func request_archive(value: Variant) -> Dictionary:
    var clean: Dictionary = sanitize(value)
    if clean.is_empty() or bool(clean["archive_requested"]):
        return {}
    clean["archive_requested"] = true
    clean["archive_status"] = "pending_evidence" if clean["family_id"] != "common_line" else "not_applicable"
    return clean

static func attention(value: Variant) -> int:
    var d: Dictionary = sanitize(value)
    if d.is_empty() or str(d["family_id"]) == "common_line":
        return 0
    if str(d["disclosure"]) == "public":
        return 2 if str(d["family_id"]) == RESTRICTED_LINE else 1
    if bool(d["archive_requested"]) and str(d["family_id"]) == RESTRICTED_LINE:
        return 1
    return 0

static func courier_adjustment(value: Variant) -> int:
    var d: Dictionary = sanitize(value)
    if d.is_empty():
        return 0
    match str(d["bond"]):
        "supportive":
            return 1
        "estranged":
            return -1
        _:
            return 0

static func relationship_response(value: Variant, npc_id: String) -> String:
    var d: Dictionary = sanitize(value)
    if d.is_empty():
        return ""
    var line: String = str(d["family_id"])
    var public_claim: bool = str(d["disclosure"]) == "public"
    var requested: bool = bool(d["archive_requested"])
    if npc_id == "npc_ring2_register":
        if line == "common_line" and requested:
            return "The registrar recorded your household inquiry. No inherited powers are established."
        if line == RESTRICTED_LINE and public_claim:
            return "The registrar notes your unverified Black Clan claim. A surname does not establish Viatra inheritance, and access remains restricted."
        if requested:
            return "Your family-record inquiry is filed. No verification has been returned; no credentials or rank are granted."
        if public_claim:
            return "Your declared family connection is on file as a claim only. Independent evidence is still required."
        return "The registrar respects your decision to keep family history private."
    if npc_id == "npc_ring2_sentry" and public_claim and line == RESTRICTED_LINE:
        return "The sentry acknowledges your recorded Black Clan claim, but the Citadel gate still requires authorization."
    if npc_id == "npc_ring2_noodles" and str(d["bond"]) == "estranged" and public_claim:
        return "The vendor notices you speaking of difficult family ties and avoids making assumptions."
    return ""

static func summary(value: Variant) -> String:
    var d: Dictionary = sanitize(value)
    if d.is_empty():
        return "No family history recorded."
    return "%s | Kinship: %s | Filing: %s | Proof: %s | Archive: %s | Attention: %d" % [
        label_for(str(d["family_id"])), str(d["bond"]), str(d["disclosure"]),
        str(d["lineage_status"]), str(d["archive_status"]), attention(d)]
