extends Node3D

const World = preload("res://scenes/main.tscn")
const Family = preload("res://systems/young_blood_family_v059.gd")
const Road = preload("res://systems/young_blood_life_rules_v057.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(why: String) -> void:
    push_error("V0.59 FAMILY WORLD FAILED: " + why)
    get_tree().call_deferred("quit", 1)

func _run() -> void:
    var scene: Node3D = World.instantiate() as Node3D
    add_child(scene)
    await get_tree().process_frame
    await get_tree().process_frame
    await get_tree().process_frame
    var life: Node = scene.get_node_or_null("YoungBloodLifeV057")
    var hub: Node = scene.get_node_or_null("HubManager")
    var codex: Node = scene.get_node_or_null("PersonalCodex")
    var society: Node = scene.get_node_or_null("SeekerSociety")
    var player: Node = scene.get_node_or_null("Player")
    if not is_instance_valid(life) or not is_instance_valid(hub) or not is_instance_valid(codex) or not is_instance_valid(society) or not is_instance_valid(player):
        _fail("missing persistent world or registration actors")
        return
    if not bool(life.get("initialized")):
        _fail("life path registrar failed to initialize")
        return
    var places: Array = hub.get("locations")
    var archive: Node3D = null
    for spot in places:
        if str(spot.get("id", "")) == "yb_v059_archive":
            archive = spot.get("node")
    if not is_instance_valid(archive):
        _fail("family archive is not in the traversable Magnara district")
        return
    var ledger: Node = archive.find_child("FamilyLedgerCounter", true, false)
    if ledger == null or ledger.find_child("LifeRoadStaticCollider", true, false) == null:
        _fail("the records counter has no physical mesh or collision")
        return
    if not (life.call("_current_family") as Dictionary).is_empty():
        _fail("clean test should start with no chosen family")
        return
    life.call("_choose_path", Road.ROAD_TRADE)
    if str((life.call("_current_life") as Dictionary).get("road", "")) != Road.ROAD_TRADE:
        _fail("original civilian road cannot be registered")
        return
    life.call("_register_origin")
    if (life.call("_current_origin") as Dictionary).is_empty():
        _fail("original-seeker origin cannot be registered")
        return
    var family_option: OptionButton = life.get("family_option")
    var bond_option: OptionButton = life.get("bond_option")
    var disclosure_option: OptionButton = life.get("disclosure_option")
    if not is_instance_valid(family_option) or not is_instance_valid(bond_option) or not is_instance_valid(disclosure_option):
        _fail("family choices are missing from the real 3D registrar")
        return
    family_option.select(1) # Kairo/Black Clan claim - never certified
    bond_option.select(0) # supportive
    disclosure_option.select(1) # public
    life.call("_refresh_family_controls")
    var seal: Button = life.get("family_confirm")
    if seal.disabled:
        _fail("the valid family choice cannot be sealed")
        return
    life.call("_register_family")
    var chosen: Dictionary = life.call("_current_family")
    if str(chosen.get("family_id", "")) != Family.RESTRICTED_LINE:
        _fail("the family record was not persisted")
        return
    if bool(chosen.get("viatra_access", true)) or bool(chosen.get("bloodline_confirmed", true)):
        _fail("selection improperly unlocks inherited powers")
        return
    if Family.attention(chosen) != 2:
        _fail("public clan disclosure has no scrutiny consequence")
        return
    var clerk_reply: String = str(society.call("get_npc_reaction", "npc_ring2_register"))
    var sentry_reply: String = str(society.call("get_npc_reaction", "npc_ring2_sentry"))
    if clerk_reply.find("unverified Black Clan") < 0 or sentry_reply.find("Citadel gate") < 0:
        _fail("institutional dialogue ignored the declared lineage")
        return
    life.call("interact", "yb_v059_archive")
    var reviewed: Dictionary = life.call("_current_family")
    if not bool(reviewed.get("archive_requested", false)) or str(reviewed.get("archive_status", "")) != "pending_evidence":
        _fail("archive interaction did not produce a persistent inquiry")
        return
    life.call("interact", "yb_v059_archive")
    if (life.call("_current_family") as Dictionary) != reviewed:
        _fail("duplicate archive interaction changed the sealed record")
        return
    var stored: Variant = null
    var disk := FileAccess.open("user://seeker_profile_v1.json", FileAccess.READ)
    if disk == null:
        _fail("Personal Codex was not written to storage")
        return
    stored = JSON.parse_string(disk.get_as_text())
    disk.close()
    if typeof(stored) != TYPE_DICTIONARY or Family.sanitize(stored.get("family_v059", {})) != reviewed:
        _fail("family archive and privacy did not survive real save")
        return
    var previous_coins: int = GameState.tola
    life.call("_accept_shift")
    life.call("_pickup")
    life.call("_deliver")
    if GameState.tola - previous_coins != 9:
        _fail("supportive kinship did not affect real courier earnings")
        return
    if int((life.call("_current_life") as Dictionary).get("work", {}).get("completed", -1)) != 1:
        _fail("existing courier job was broken by the family system")
        return
    life.call("_deliver")
    if GameState.tola - previous_coins != 9:
        _fail("family payout was farmable through duplicate delivery")
        return
    if bool((codex.get("profile") as Dictionary).get("family_v059", {}).get("bloodline_confirmed", true)):
        _fail("canonical ocular bloodline was fabricated")
        return
    print("V0.59 PHYSICAL FAMILY ARCHIVE NPC REACTIONS AND COURIER CONSEQUENCES PASS")
    scene.queue_free()
    get_tree().call_deferred("quit", 0)
