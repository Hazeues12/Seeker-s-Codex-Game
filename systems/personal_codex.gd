extends Node

# V0.43 Personal Codex. Game-only chronology, never a promotion or canon unlock.
# Read legacy saves for context; NEVER overwrite or migrate them.
const SAVE_FILE: String = "user://seeker_profile_v1.json"
const PENDING_FILE: String = "user://seeker_profile_v1.pending.json"
const APPEARANCE_FILE: String = "user://margerina_appearance_v038.json"
const MAX_HISTORY: int = 240

var profile: Dictionary = {}
var seen_events: Dictionary = {}
var save_blocked: bool = false
var hub: Node
var player: CharacterBody3D
var panel: PanelContainer
var journal_view: RichTextLabel
var codex_button: Button
var check_timer: float = 0.0

func _ready() -> void:
    add_to_group("personal_codex")
    set_process(false)
    call_deferred("_setup")

func _setup() -> void:
    if not is_inside_tree():
        return
    hub = get_tree().get_first_node_in_group("hub_manager")
    player = get_parent().get_node_or_null("Player") as CharacterBody3D
    _load_profile()
    _make_ui()
    _sync_identity()
    _backfill_completed_contracts()
    _refresh_view()
    set_process(true)

func _new_profile() -> Dictionary:
    return {
        "schema_version": 1,
        "profile_id": "local-original-seeker-001",
        "identity": {"name": "New Seeker", "origin_id": "unselected", "background_id": "unselected"},
        "career": {"guild_id": "none", "certifications": [], "exam_history": []},
        "reputation": {"association_trust": "not_assessed", "public_fame": "not_assessed", "guild_reliability": "not_assessed"},
        "contacts": {},
        "discovered_locations": [],
        "history": [],
        "affinities": {"trained_spokes": [], "celestial_status": "restricted", "ocular_lineage": "unverified"},
        "soul_development": {"soul_bloom": "unrevealed", "spirit_bloom": "unrevealed", "eidolon": "unrevealed", "ryoiki": "unrevealed"}
    }

func _load_profile() -> void:
    profile = _new_profile()
    if not FileAccess.file_exists(SAVE_FILE):
        return
    var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
    if file == null:
        save_blocked = true
        push_warning("Personal Codex: existing profile could not be opened; will not overwrite it")
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        save_blocked = true
        push_warning("Personal Codex: invalid profile JSON; refusing overwrite")
        return
    var record: Dictionary = parsed
    if int(record.get("schema_version", -1)) != 1 or typeof(record.get("history", null)) != TYPE_ARRAY:
        save_blocked = true
        push_warning("Personal Codex: unsupported schema or history; refusing overwrite")
        return
    profile = record
    for entry in profile.get("history", []):
        if typeof(entry) == TYPE_DICTIONARY:
            var key: String = str(entry.get("id", ""))
            if not key.is_empty():
                seen_events[key] = true

func _save_profile() -> void:
    if save_blocked:
        return
    var file := FileAccess.open(PENDING_FILE, FileAccess.WRITE)
    if file == null:
        push_warning("Personal Codex: browser storage not writable")
        return
    file.store_string(JSON.stringify(profile))
    file.close()
    var error: int = DirAccess.rename_absolute(ProjectSettings.globalize_path(PENDING_FILE), ProjectSettings.globalize_path(SAVE_FILE))
    if error != OK:
        push_warning("Personal Codex: could not finalize profile storage")

func _sync_identity() -> void:
    var current_name: String = str(GameState.player_name).substr(0, 24)
    if FileAccess.file_exists(APPEARANCE_FILE):
        var f := FileAccess.open(APPEARANCE_FILE, FileAccess.READ)
        if f != null:
            var raw: Variant = JSON.parse_string(f.get_as_text())
            f.close()
            if typeof(raw) == TYPE_DICTIONARY and int(raw.get("version", 0)) == 1:
                current_name = str(raw.get("name", current_name)).substr(0, 24)
    var identity: Dictionary = profile.get("identity", {})
    if identity.get("name", "") != current_name and not current_name.is_empty():
        identity["name"] = current_name
        profile["identity"] = identity
        _save_profile()

func _backfill_completed_contracts() -> void:
    if not is_instance_valid(hub):
        return
    var done: Array = hub.get("contract_finished")
    var labels: Array[String] = ["Field Kit Delivery", "Medicinal Herb Survey", "Aura Technique Drills"]
    for i in range(mini(done.size(), labels.size())):
        if bool(done[i]):
            record_event("contract:%d" % i, "contract_completed", "Completed " + labels[i], "Recovered from an existing local save; original reward remains unchanged.")

func _process(delta: float) -> void:
    check_timer += delta
    if check_timer < 1.1:
        return
    check_timer = 0.0
    _backfill_completed_contracts()
    if not is_instance_valid(player):
        return
    var pos: Vector3 = player.global_position
    if absf(pos.x) < 34.0 and pos.z > -30.0 and pos.z < 130.0:
        if pos.z >= 105.0:
            record_event("district:citadel_approach", "location_discovered", "Reached the Citadel approach", "Observed the restricted approach from the public side; entry not granted.")
        elif pos.z >= 72.0:
            record_event("district:professional", "location_discovered", "Visited Ring Two's professional quarter", "Observed registration, training and medical facilities.")
        elif pos.z >= 30.0:
            record_event("district:public", "location_discovered", "Visited Ring Two's public quarter", "Found broad streets, residences and working canals.")
    if is_open():
        _sync_identity()
        _refresh_view()

func record_interaction(kind: String, display_name: String) -> void:
    if kind.begins_with("npc_") or kind == "hanami":
        var contact_id: String = "contact:" + kind
        record_event(contact_id, "npc_met", "Met " + display_name, "Spoke to a resident or Seeker in Magnara's quarters.")
        var contacts: Dictionary = profile.get("contacts", {})
        if not contacts.has(kind):
            contacts[kind] = {"name": display_name, "relationship": "acquainted", "canon_status": "game_only"}
            profile["contacts"] = contacts
            _save_profile()
    elif kind == "board":
        record_event("landmark:contract_board", "location_discovered", "Discovered the guild contract board", "Explored the original Seeker Quarters hub.")
    elif kind == "dummy":
        record_event("landmark:training_post", "location_discovered", "Visited the Aura training post", "Found a location for Martial drills.")

func record_contract(index: int, title: String, reward_tola: int, reward_xp: int) -> void:
    record_event("contract:%d" % index, "contract_completed", "Completed " + title,
        "Earned %d Tola and %d XP from a prototype contract." % [reward_tola, reward_xp])

func record_event(event_id: String, kind: String, heading: String, details: String) -> void:
    if save_blocked or event_id.is_empty() or seen_events.has(event_id):
        return
    if profile.is_empty():
        profile = _new_profile()
    var minutes: float = 480.0
    if is_instance_valid(hub):
        minutes = float(hub.get("world_minutes"))
    var minute_of_day: int = posmod(int(minutes), 1440)
    var place: String = "Magnara / Seeker Quarters (game map)"
    if is_instance_valid(player):
        var z: float = player.global_position.z
        if z >= 105.0:
            place = "Magnara / Ring Two / Citadel approach"
        elif z >= 72.0:
            place = "Magnara / Ring Two / Professional quarter"
        elif z >= 30.0:
            place = "Magnara / Ring Two / Public quarter"
    var entry: Dictionary = {
        "id": event_id.substr(0, 96), "kind": kind.substr(0, 50),
        "title": heading.substr(0, 110), "detail": details.substr(0, 240),
        "day": int(floor(minutes / 1440.0)) + 1,
        "clock": "%02d:%02d" % [int(minute_of_day / 60), minute_of_day % 60],
        "place": place, "canon_status": "game_only"
    }
    var history: Array = profile.get("history", [])
    history.append(entry)
    while history.size() > MAX_HISTORY:
        var deleted: Variant = history.pop_front()
        if typeof(deleted) == TYPE_DICTIONARY:
            seen_events.erase(str(deleted.get("id", "")))
    profile["history"] = history
    seen_events[entry["id"]] = true
    if kind == "location_discovered":
        var locations: Array = profile.get("discovered_locations", [])
        if not locations.has(entry["id"]):
            locations.append(entry["id"])
        profile["discovered_locations"] = locations
    _save_profile()
    if is_open():
        _refresh_view()

func is_open() -> bool:
    return is_instance_valid(panel) and panel.visible

func _make_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "PersonalCodexCanvas"
    layer.layer = 14
    get_parent().add_child(layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)
    codex_button = Button.new()
    codex_button.name = "OpenPersonalCodex"
    codex_button.text = "MY CODEX"
    codex_button.add_theme_font_size_override("font_size", 20)
    codex_button.anchor_top = 1.0
    codex_button.anchor_bottom = 1.0
    codex_button.offset_left = 25.0
    codex_button.offset_right = 193.0
    codex_button.offset_top = -310.0
    codex_button.offset_bottom = -254.0
    codex_button.pressed.connect(_toggle)
    root.add_child(codex_button)
    panel = PanelContainer.new()
    panel.name = "PersonalCodexPanel"
    panel.anchor_left = 0.12
    panel.anchor_right = 0.88
    panel.anchor_top = 0.08
    panel.anchor_bottom = 0.91
    panel.visible = false
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(0.04, 0.07, 0.13, 0.97)
    skin.border_color = Color(0.32, 0.64, 0.81)
    skin.set_border_width_all(3)
    skin.set_corner_radius_all(10)
    panel.add_theme_stylebox_override("panel", skin)
    root.add_child(panel)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 17)
    margin.add_theme_constant_override("margin_right", 17)
    margin.add_theme_constant_override("margin_top", 13)
    margin.add_theme_constant_override("margin_bottom", 13)
    panel.add_child(margin)
    var contents := VBoxContainer.new()
    contents.add_theme_constant_override("separation", 8)
    margin.add_child(contents)
    var heading := Label.new()
    heading.text = "PERSONAL SEEKER'S CODEX / PROTOTYPE"
    heading.add_theme_font_size_override("font_size", 24)
    contents.add_child(heading)
    journal_view = RichTextLabel.new()
    journal_view.bbcode_enabled = false
    journal_view.scroll_active = true
    journal_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
    journal_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    journal_view.add_theme_font_size_override("normal_font_size", 18)
    contents.add_child(journal_view)
    var close := Button.new()
    close.text = "RETURN TO MARGERINA"
    close.custom_minimum_size = Vector2(0, 54)
    close.pressed.connect(_close)
    contents.add_child(close)

func _toggle() -> void:
    if is_open():
        _close()
    else:
        var creator: Node = get_tree().get_first_node_in_group("seeker_creator")
        var daily: Node = get_tree().get_first_node_in_group("ring_two_life")
        if (is_instance_valid(creator) and creator.call("is_open")) or (is_instance_valid(daily) and daily.call("is_open")):
            return
        if is_instance_valid(hub) and hub.has_method("_any_panel_open") and bool(hub.call("_any_panel_open")):
            return
        _sync_identity()
        _refresh_view()
        panel.show()

func _close() -> void:
    if is_instance_valid(panel):
        panel.hide()

func _refresh_view() -> void:
    if not is_instance_valid(journal_view):
        return
    var identity: Dictionary = profile.get("identity", {})
    var contacts: Dictionary = profile.get("contacts", {})
    var entries: Array = profile.get("history", [])
    var locations: Array = profile.get("discovered_locations", [])
    var rank: String = str(GameState.seeker_rank)
    var coins: int = int(GameState.tola)
    var xp: int = 0
    var guild_rep: int = 0
    var aura: float = 0.0
    var stamina: float = 0.0
    if is_instance_valid(hub):
        xp = int(hub.get("experience"))
        guild_rep = int(hub.get("guild_rep"))
        aura = float(hub.get("aura"))
        stamina = float(hub.get("stamina"))
    var output: String = ""
    var life_record: Dictionary = profile.get("life_v057", {})
    var life_road: String = str(life_record.get("road", ""))
    var life_nation: String = str(life_record.get("nation", "unselected"))
    var origin_data: Dictionary = profile.get("origin_v058", {})
    var background_label: String = "not yet selected"
    if typeof(origin_data) == TYPE_DICTIONARY and not origin_data.is_empty():
        background_label = str(origin_data.get("background", "unknown")).replace("_", " ").capitalize()
    output += "IDENTITY\n%s | Home Nation: %s | Background: %s\n" % [
        str(identity.get("name", "New Seeker")), life_nation, background_label]
    if not origin_data.is_empty():
        var temperament: String = str(origin_data.get("temperament", ""))
        var trait: String = str(origin_data.get("trait", ""))
        var burdens: Array = origin_data.get("burdens", [])
        var perks: Array = origin_data.get("perks", [])
        output += "Temperament: %s | Trait: %s\n" % [temperament.capitalize(), trait.replace("_", " ").capitalize()]
        output += "Burdens: %s | Perks: %s | Remaining debt: %d Tola\n" % [
            ", ".join(PackedStringArray(burdens)) if burdens.size() else "none",
            ", ".join(PackedStringArray(perks)) if perks.size() else "none",
            int(origin_data.get("debt_tola", 0))]
    output += "YOUR ROAD\n%s\n" % ("Not chosen" if life_road.is_empty() else life_road)
    if life_road == "trade":
        var life_work: Dictionary = life_record.get("work", {})
        output += "Civilian courier shifts: %d | Parcel: %s\n" % [int(life_work.get("completed", 0)), str(life_work.get("stage", "idle"))]
    output += "\nSEEKER CAREER\nRank: %s | Guild: not joined\nTola: %d | XP: %d | Local guild rep: %d\n" % [rank, coins, xp, guild_rep]
    output += "\nAURA & MUTI\nCurrent Aura: %.0f/100 | Stamina: %.0f/100\nMartial drills: prototype only. Seven Spokes training paths are not yet unlocked.\n" % [aura, stamina]
    output += "\nSOCIAL MEMORY\nPeople met: %d | Explored locations: %d\n" % [contacts.size(), locations.size()]
    if contacts.size() > 0:
        var keys: Array = contacts.keys()
        keys.sort()
        for key in keys.slice(0, 8):
            var friend: Dictionary = contacts[key]
            output += " - %s | %s | rapport %d\n" % [str(friend.get("name", key)), str(friend.get("relationship", "acquainted")), int(friend.get("rapport", 0))]
    output += "\nREPUTATION & SOUL\n"
    var society_data: Dictionary = profile.get("society", {})
    var reputation_data: Dictionary = society_data.get("reputation", {})
    if reputation_data.is_empty():
        output += "Professional reputation: not assessed yet.\n"
    else:
        output += "Association trust: %d | Public fame: %d | Guild reliability: %d\n" % [
            int(reputation_data.get("association_trust", 0)),
            int(reputation_data.get("public_fame", 0)),
            int(reputation_data.get("guild_reliability", 0))]
        output += "Neighborhood respect: %d | Underworld attention: %d\n" % [
            int(reputation_data.get("local_respect", 0)),
            int(reputation_data.get("underworld_attention", 0))]
        var decisions: Dictionary = society_data.get("decisions", {})
        var quests: Dictionary = society_data.get("quests", {})
        var romance: Dictionary = society_data.get("romance", {})
        output += "Life decisions recorded: %d | Neighborhood delivery: %s\n" % [
            decisions.size(), str(quests.get("canal_delivery", "not started"))]
        for resident in romance:
            output += "Adult relationship: %s — %s\n" % [str(resident), str(romance[resident])]
    output += "Soul Bloom / Spirit Bloom: separate, unrevealed.\nEidolon / Ryōiki / rare Eyes: no unlock recorded.\n"
    var field: Dictionary = profile.get("field_mission_v048", {})
    if not field.is_empty():
        output += "\nFIELD WATCH\nStage: %s | Decision: %s\n" % [str(field.get("stage", "available")), str(field.get("choice", "not chosen"))]
    var companion: Dictionary = profile.get("companion_v049", {})
    if not companion.is_empty():
        output += "\nFIELD COMPANION / GAME-ONLY\n"
        output += "Trust: %d | Injury: %d/100 | Interceptions: %d\n" % [
            int(companion.get("loyalty", 0)), int(companion.get("injury", 0)), int(companion.get("interventions", 0))]
        output += "Last field outcome: %s\n" % str(companion.get("outcome", "unresolved"))
    var expedition_record: Dictionary = profile.get("expedition_v050", {})
    if not expedition_record.is_empty():
        output += "\nMULTI-DAY WAYSTATION ASSIGNMENT / GAME-ONLY\n"
        output += "Stage: %s | Preparation: %s | Outcome: %s\n" % [
            str(expedition_record.get("stage", "available")),
            str(expedition_record.get("preparation", "not chosen")),
            str(expedition_record.get("outcome", "pending"))]
        output += "Departed day %d | Rest day %d | Paid: %s\n" % [
            int(expedition_record.get("departure_day", 0)), int(expedition_record.get("rest_day", 0)),
            "Yes" if bool(expedition_record.get("paid", false)) else "No"]
    var city_events: Dictionary = profile.get("daily_bulletin_v051", {})
    var answered_days: Dictionary = city_events.get("days", {})
    if answered_days.size() > 0:
        output += "\nDAILY CITY EVENTS\nDays with decisions: %d\n" % answered_days.size()
        var recent: Array = answered_days.keys()
        recent.sort()
        for entry_day in recent.slice(maxi(0, recent.size() - 3), recent.size()):
            var civic_event: Dictionary = answered_days[entry_day]
            output += "%s | %s | %s\n" % [str(entry_day), str(civic_event.get("context", "routine")), str(civic_event.get("choice", ""))]
    output += "\nLIFE CHRONICLE  (%d saved events)\n" % entries.size()
    var first: int = maxi(0, entries.size() - 14)
    for i in range(entries.size() - 1, first - 1, -1):
        var event: Variant = entries[i]
        if typeof(event) == TYPE_DICTIONARY:
            output += "Day %d %s — %s\n   %s\n" % [int(event.get("day", 1)), str(event.get("clock", "??")), str(event.get("title", "Entry")), str(event.get("place", "Magnara"))]
    if entries.is_empty():
        output += "Explore Ring Two, speak to Seekers, or complete a contract to create your first entry.\n"
    if save_blocked:
        output += "\nWARNING: Previous Codex file could not be read. Saving is blocked to protect it.\n"
    output += "\nThese are records of game events, not new published Seeker's Codex canon.\n"
    journal_view.text = output


# V0.44: all choices are recorded in the existing Personal Codex save.
func get_contact_rapport(kind: String) -> int:
    var contacts: Dictionary = profile.get("contacts", {})
    var entry: Dictionary = contacts.get(kind, {})
    return clampi(int(entry.get("rapport", 0)), -3, 3)

func has_social_choice(kind: String, topic: String) -> bool:
    var contacts: Dictionary = profile.get("contacts", {})
    var entry: Dictionary = contacts.get(kind, {})
    var choices: Dictionary = entry.get("choices", {})
    return choices.has(topic)

func remember_social_choice(kind: String, display_name: String, topic: String,
        heading: String, reply: String, delta: int) -> bool:
    if save_blocked or not kind.begins_with("npc_ring2_") or topic.is_empty():
        return false
    if profile.is_empty():
        profile = _new_profile()
    var contacts: Dictionary = profile.get("contacts", {})
    var friend: Dictionary = contacts.get(kind, {
        "name": display_name, "relationship": "acquainted", "canon_status": "game_only"})
    var choices: Dictionary = friend.get("choices", {})
    if choices.has(topic):
        return false
    var bounded_delta: int = clampi(delta, -1, 1)
    choices[topic] = {"reply": reply.substr(0, 240), "change": bounded_delta}
    friend["choices"] = choices
    var rapport: int = clampi(int(friend.get("rapport", 0)) + bounded_delta, -3, 3)
    friend["rapport"] = rapport
    if rapport >= 2:
        friend["relationship"] = "comfortable"
    elif rapport <= -2:
        friend["relationship"] = "wary"
    elif rapport == 1:
        friend["relationship"] = "warming up"
    elif rapport == -1:
        friend["relationship"] = "cautious"
    else:
        friend["relationship"] = "acquainted"
    contacts[kind] = friend
    profile["contacts"] = contacts
    record_event("social:%s:%s" % [kind, topic], "npc_conversation", heading, reply)
    _save_profile()
    return true
