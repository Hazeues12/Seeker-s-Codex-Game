extends Node

# V0.45 GAME-ONLY social simulation and professional reputation.
# Canon institutions are respected; no official rank, restricted access,
# inherited Eye, Celestial power, or story secret can be bought or persuaded open.
const TRADE_ITEM: String = "Canal Trade Cloth"
const BUY_PRICE: int = 14
const SELL_PRICE: int = 8
const CONSENTING_ADULT_ROLES: Dictionary = {
    "npc_ring2_noodles": {"age": 28, "romance_available": true},
    "npc_ring2_canal": {"age": 27, "romance_available": true}
}
const PROFESSIONAL_REPUTATION: Dictionary = {
    "association_trust": 0,
    "public_fame": 0,
    "guild_reliability": 0,
    "local_respect": 0,
    "underworld_attention": 0
}
const ROLES: Dictionary = {
    "npc_ring2_noodles": "Noodle Vendor",
    "npc_ring2_canal": "Canal Resident",
    "npc_ring2_register": "Registration Clerk",
    "npc_ring2_medic": "Medical Instructor",
    "npc_ring2_trainer": "Silver Team Instructor",
    "npc_ring2_soulwright": "Soulwright Officer",
    "npc_ring2_sentry": "Citadel Patrol Sentry"
}
const WORK_LINES: Dictionary = {
    "npc_ring2_noodles": "The lunch rush keeps me busy. Seekers, medics, and workers all need to eat.",
    "npc_ring2_canal": "Residents maintain the canals and bridges even when Seekers are on assignment.",
    "npc_ring2_register": "Certification is verified through formal records, not an informal conversation.",
    "npc_ring2_medic": "Rest and recovery are part of a Seeker's training, especially after Aura strain.",
    "npc_ring2_trainer": "Our Silver squad trains timing, formations, and restraint against practice constructs.",
    "npc_ring2_soulwright": "Public field observation is permitted; restricted Soul Law files are not.",
    "npc_ring2_sentry": "The Citadel approach is public. The secured gate requires authorization."
}
var codex: Node
var hub: Node
var _action_guard: bool = false

func _ready() -> void:
    add_to_group("seeker_society")
    call_deferred("_setup")

func _setup() -> void:
    codex = get_tree().get_first_node_in_group("personal_codex")
    hub = get_tree().get_first_node_in_group("hub_manager")
    # Existing contract saves grant their first reputation effects only once.
    if _ensure_connections() and is_instance_valid(hub):
        var completed: Array = hub.get("contract_finished")
        for i in range(completed.size()):
            if bool(completed[i]):
                record_contract_outcome(i)

func _ensure_connections() -> bool:
    if not is_instance_valid(codex):
        codex = get_tree().get_first_node_in_group("personal_codex")
    if not is_instance_valid(hub):
        hub = get_tree().get_first_node_in_group("hub_manager")
    return is_instance_valid(codex) and not bool(codex.get("save_blocked"))

func _state() -> Dictionary:
    var existing: Dictionary = codex.profile.get("society", {})
    if not existing.has("reputation"):
        existing["reputation"] = PROFESSIONAL_REPUTATION.duplicate(true)
    if not existing.has("decisions"):
        existing["decisions"] = {}
    if not existing.has("quests"):
        existing["quests"] = {}
    if not existing.has("romance"):
        existing["romance"] = {}
    if not existing.has("trades"):
        existing["trades"] = 0
    if not existing.has("player_adult_confirmed"):
        existing["player_adult_confirmed"] = false
    return existing

func supports(kind: String) -> bool:
    return ROLES.has(kind)

func get_npc_reaction(kind: String) -> String:
    if not _ensure_connections():
        return "Your history is unavailable."
    var trust: int = get_reputation("association_trust")
    var local: int = get_reputation("local_respect")
    if kind in ["npc_ring2_register", "npc_ring2_sentry"] and trust <= -3:
        return "An officer recognizes your misconduct report. Procedures remain strict."
    if kind == "npc_ring2_noodles" and get_quest_status("canal_delivery") == "completed":
        return "The vendor remembers your successful delivery. You've earned a warm welcome."
    if kind in ["npc_ring2_noodles", "npc_ring2_canal"] and local <= -2:
        return "People here recognize your questionable conduct and keep their distance."
    if kind == "npc_ring2_trainer" and get_reputation("guild_reliability") >= 2:
        return "The Silver instructor remembers your reliable field work."
    return "Your actions and conversation history affect their response."

func get_reputation(key: String) -> int:
    if not _ensure_connections():
        return 0
    var rep: Dictionary = _state().get("reputation", {})
    return int(rep.get(key, 0))

func get_reputation_summary() -> String:
    return "Association %d | Public %d | Guild %d | Neighborhood %d | Underworld %d" % [
        get_reputation("association_trust"), get_reputation("public_fame"),
        get_reputation("guild_reliability"), get_reputation("local_respect"),
        get_reputation("underworld_attention")]

func get_decision(scene_id: String) -> String:
    if not _ensure_connections():
        return ""
    var decisions: Dictionary = _state().get("decisions", {})
    return str(decisions.get(scene_id, ""))

func get_quest_status(quest_id: String) -> String:
    if not _ensure_connections():
        return ""
    var quests: Dictionary = _state().get("quests", {})
    return str(quests.get(quest_id, ""))

func get_romance_status(kind: String) -> String:
    if not _ensure_connections():
        return ""
    var romance: Dictionary = _state().get("romance", {})
    return str(romance.get(kind, ""))

func is_player_adult_confirmed() -> bool:
    return _ensure_connections() and bool(_state().get("player_adult_confirmed", false))

func _option(result: Array[Dictionary], id: String, label: String,
        available: bool = true, reason: String = "") -> void:
    result.append({"id": id, "label": label, "available": available, "reason": reason})

func options_for(kind: String) -> Array[Dictionary]:
    var options: Array[Dictionary] = []
    if not ROLES.has(kind) or not _ensure_connections():
        return options
    for topic in ["work", "respect", "demand"]:
        var labels: Dictionary = {
            "work": "Ask about their work",
            "respect": "Show respect for their work",
            "demand": "Demand special treatment (harms rapport)"}
        var already: bool = bool(codex.call("has_social_choice", kind, topic))
        _option(options, "social_" + topic, str(labels[topic]), not already,
            "You already discussed that." if already else "")
    var key: String = ""
    match kind:
        "npc_ring2_noodles":
            var note: String = get_quest_status("canal_delivery")
            key = get_decision("vendor:delivery_offer")
            if key.is_empty():
                _option(options, "start_delivery", "Accept a canal supply delivery")
                _option(options, "refuse_delivery", "Decline the delivery")
            _option(options, "buy_cloth", "BUY canal trade cloth — %d Tola" % _buy_price(),
                GameState.tola >= _buy_price(), "Not enough Tola")
            var owned: int = 0
            if is_instance_valid(hub):
                owned = int(hub.get("inventory").get(TRADE_ITEM, 0))
            _option(options, "sell_cloth", "SELL canal trade cloth — %d Tola" % SELL_PRICE,
                owned > 0, "You have no trade cloth")
            if note == "completed":
                _option(options, "delivery_thanks", "Ask about the completed delivery", true)
        "npc_ring2_canal":
            if get_quest_status("canal_delivery") == "active":
                _option(options, "finish_delivery", "Deliver the vendor's note (honest work)")
                _option(options, "sell_delivery_info", "Sell the delivery details to a fixer (illegal)")
        "npc_ring2_register":
            if get_decision("official:registration").is_empty():
                var has_record: bool = false
                if is_instance_valid(hub):
                    for completed in hub.get("contract_finished"):
                        if bool(completed):
                            has_record = true
                _option(options, "file_true", "File a truthful contract report", has_record,
                    "Complete a real hub contract first")
                _option(options, "file_false", "Claim an unearned certification (misconduct)")
        "npc_ring2_medic":
            if get_decision("medical:donation").is_empty():
                _option(options, "donate", "Donate 6 Tola for public medical supplies",
                    GameState.tola >= 6, "Not enough Tola")
                _option(options, "decline_donation", "Politely decline to donate")
        "npc_ring2_trainer":
            if get_decision("trainer:drill").is_empty():
                var stamina: float = float(hub.get("stamina")) if is_instance_valid(hub) else 0.0
                _option(options, "team_drill", "Join a coordinated drill (-15 Stamina)",
                    stamina >= 15.0, "Not enough Stamina")
                _option(options, "boast", "Dismiss the Silver squad's training")
        "npc_ring2_soulwright":
            if get_decision("soulwright:learning").is_empty():
                _option(options, "study_public", "Study lawful public observation techniques")
                _option(options, "force_files", "Demand access to restricted records (misconduct)")
        "npc_ring2_sentry":
            if get_decision("citadel:conduct").is_empty():
                _option(options, "respect_gate", "Respect the secured Citadel boundary")
                _option(options, "bribe_gate", "Try an 18-Tola bribe (confiscation and investigation)",
                    GameState.tola >= 18, "Not enough Tola")
    if CONSENTING_ADULT_ROLES.has(kind):
        if not is_player_adult_confirmed():
            _option(options, "confirm_adult", "Confirm my Seeker character is 18+ for romance")
        else:
            var score: int = int(codex.call("get_contact_rapport", kind))
            var romance_status: String = get_romance_status(kind)
            if get_decision("romance:%s:approach" % kind).is_empty():
                _option(options, "flirt", "Attempt a respectful flirt (adult, mutual interest)", score >= 1,
                    "Build positive rapport first")
                _option(options, "stay_friends", "Keep the relationship platonic")
            elif romance_status == "interested" and get_decision("romance:%s:invitation" % kind).is_empty():
                _option(options, "invite_date", "Invite them to spend time together", score >= 2,
                    "More mutual trust needed")
                _option(options, "respect_space", "Respect their space and remain friends")
    return options

func _buy_price() -> int:
    if not _ensure_connections():
        return BUY_PRICE
    return 12 if int(codex.call("get_contact_rapport", "npc_ring2_noodles")) >= 2 else BUY_PRICE

func _alter_reputation(state: Dictionary, changes: Dictionary) -> void:
    var rep: Dictionary = state.get("reputation", PROFESSIONAL_REPUTATION.duplicate(true))
    for key in changes:
        if PROFESSIONAL_REPUTATION.has(key):
            rep[key] = clampi(int(rep.get(key, 0)) + int(changes[key]), -20, 20)
    state["reputation"] = rep

func _record(kind: String, scene_id: String, option_id: String, text: String,
        rapport: int, reputations: Dictionary, details: String = "") -> Dictionary:
    if get_decision(scene_id) != "":
        return {"ok": false, "message": "That decision is already part of your history."}
    var state: Dictionary = _state()
    var decisions: Dictionary = state.get("decisions", {})
    decisions[scene_id] = option_id
    state["decisions"] = decisions
    _alter_reputation(state, reputations)
    codex.profile["society"] = state
    var contacts: Dictionary = codex.profile.get("contacts", {})
    var contact: Dictionary = contacts.get(kind, {"name": ROLES.get(kind, kind), "canon_status": "game_only"})
    contact["rapport"] = clampi(int(contact.get("rapport", 0)) + rapport, -3, 3)
    var score: int = int(contact["rapport"])
    contact["relationship"] = "comfortable" if score >= 2 else "wary" if score <= -2 else "warming up" if score > 0 else "cautious" if score < 0 else "acquainted"
    contacts[kind] = contact
    codex.profile["contacts"] = contacts
    codex.call("record_event", "v045:%s" % scene_id, "consequential_decision", text, details if not details.is_empty() else text)
    codex.call("_save_profile")
    return {"ok": true, "message": text}

func _save_economy() -> void:
    if is_instance_valid(hub) and hub.has_method("_save_game"):
        hub.call("_save_game")

func _trade(operation: String) -> Dictionary:
    if not is_instance_valid(hub):
        return {"ok": false, "message": "Trading is unavailable at this time."}
    var inventory: Dictionary = hub.get("inventory")
    var n: int = int(inventory.get(TRADE_ITEM, 0))
    var result: String = ""
    if operation == "buy_cloth":
        var price: int = _buy_price()
        if GameState.tola < price or not GameState.spend_tola(price):
            return {"ok": false, "message": "You need %d Tola." % price}
        inventory[TRADE_ITEM] = n + 1
        result = "Bought 1 canal trade cloth for %d Tola." % price
    else:
        if n < 1:
            return {"ok": false, "message": "You do not own trade cloth to sell."}
        inventory[TRADE_ITEM] = n - 1
        GameState.earn_tola(SELL_PRICE)
        result = "Sold 1 canal trade cloth for %d Tola. Resale is below the purchase price." % SELL_PRICE
    hub.set("inventory", inventory)
    _save_economy()
    var state: Dictionary = _state()
    var serial: int = int(state.get("trades", 0)) + 1
    state["trades"] = serial
    codex.profile["society"] = state
    codex.call("record_event", "v045:market:%d" % serial, "market_trade", result, "Public-quarter trade; no rank or powers awarded")
    return {"ok": true, "message": result}

func _confirm_player_adult() -> Dictionary:
    var state: Dictionary = _state()
    state["player_adult_confirmed"] = true
    codex.profile["society"] = state
    codex.call("_save_profile")
    return {"ok": true, "message": "Your Seeker is marked as an adult (18+) for optional romantic dialogue. NPC consent is still required."}

func _social(kind: String, choice: String) -> Dictionary:
    var topic: String = choice.trim_prefix("social_")
    var reply: String = ""
    var rapport: int = 0
    match topic:
        "work":
            reply = str(WORK_LINES.get(kind, "There is work to do in the quarter."))
        "respect":
            reply = "Thank you for treating my work with respect. I will remember that."
            rapport = 1
        "demand":
            reply = "No one owes you special treatment because you are a Seeker."
            rapport = -1
        _:
            return {"ok": false, "message": "Unknown topic."}
    var changed: bool = bool(codex.call("remember_social_choice", kind, str(ROLES[kind]), topic,
        "Spoke with " + str(ROLES[kind]) + " about " + topic, reply, rapport))
    return {"ok": changed, "message": reply if changed else "You have already discussed this topic."}

func act(kind: String, option_id: String) -> Dictionary:
    if _action_guard or not ROLES.has(kind) or not _ensure_connections():
        return {"ok": false, "message": "The interaction is unavailable."}
    _action_guard = true
    var result: Dictionary = _act_inner(kind, option_id)
    _action_guard = false
    return result

func _act_inner(kind: String, option_id: String) -> Dictionary:
    # Never trust only disabled UI; revalidate at execution time.
    var allowed: bool = false
    for option in options_for(kind):
        if str(option["id"]) == option_id and bool(option["available"]):
            allowed = true
            break
    if not allowed:
        return {"ok": false, "message": "That choice is unavailable or has already been made."}
    if option_id.begins_with("social_"):
        return _social(kind, option_id)
    if option_id in ["buy_cloth", "sell_cloth"]:
        return _trade(option_id)
    if option_id == "confirm_adult":
        return _confirm_player_adult()
    match option_id:
        "start_delivery":
            var response: Dictionary = _record(kind, "vendor:delivery_offer", option_id, "Accepted a neighborhood delivery", 1, {},
                "Promised to carry a supply note to the canal resident.")
            if bool(response.get("ok", false)):
                var state: Dictionary = _state()
                var quests: Dictionary = state.get("quests", {})
                quests["canal_delivery"] = "active"
                state["quests"] = quests
                codex.profile["society"] = state
                codex.call("_save_profile")
                response["message"] = "The vendor hands over a note. Deliver it to the canal resident near the bridges."
            return response
        "refuse_delivery":
            return _record(kind, "vendor:delivery_offer", option_id, "Declined an optional neighborhood delivery", 0, {},
                "The vendor accepts the refusal; you can still trade here.")
        "finish_delivery":
            if get_quest_status("canal_delivery") != "active":
                return {"ok": false, "message": "You do not have a delivery to complete."}
            var done: Dictionary = _record(kind, "delivery:resolution", option_id, "Delivered the vendor's note honestly", 1,
                {"guild_reliability": 2, "local_respect": 2, "association_trust": 1},
                "The canal resident confirms that the supplies reached their destination.")
            if bool(done.get("ok", false)):
                var state: Dictionary = _state()
                var quests: Dictionary = state.get("quests", {})
                quests["canal_delivery"] = "completed"
                state["quests"] = quests
                codex.profile["society"] = state
                codex.call("_save_profile")
                GameState.earn_tola(12)
                _save_economy()
                done["message"] = "Delivery completed. Earned 12 Tola; neighborhood trust and guild reliability increased."
            return done
        "sell_delivery_info":
            var betrayed: Dictionary = _record(kind, "delivery:resolution", option_id, "Exploited a neighborhood delivery", -1,
                {"association_trust": -3, "guild_reliability": -3, "local_respect": -2, "underworld_attention": 2},
                "A fixer took the delivery details; the recipient reported the breach of trust.")
            if bool(betrayed.get("ok", false)):
                var state: Dictionary = _state()
                var quests: Dictionary = state.get("quests", {})
                quests["canal_delivery"] = "betrayed"
                state["quests"] = quests
                codex.profile["society"] = state
                codex.call("_save_profile")
                betrayed["message"] = "The recipient reports your misconduct. The delivery fails, and your Association record suffers."
            return betrayed
        "delivery_thanks":
            return {"ok": true, "message": "The vendor thanks you for handling the note without exploiting anyone."}
        "file_true":
            return _record(kind, "official:registration", option_id, "Filed a truthful contract report", 1,
                {"association_trust": 2, "guild_reliability": 1},
                "The clerk records genuine field work. This is not a rank promotion.")
        "file_false":
            return _record(kind, "official:registration", option_id, "Made a false certification claim", -2,
                {"association_trust": -4, "local_respect": -1},
                "The claim was rejected; no rank or certification was granted.")
        "donate":
            if GameState.tola < 6 or not GameState.spend_tola(6):
                return {"ok": false, "message": "You cannot afford the 6-Tola donation."}
            var donated: Dictionary = _record(kind, "medical:donation", option_id, "Supported public medical supplies", 1,
                {"local_respect": 2}, "Donated 6 Tola to the medical station's public supplies.")
            _save_economy()
            return donated
        "decline_donation":
            return _record(kind, "medical:donation", option_id, "Declined a voluntary medical donation", 0, {},
                "The medic respects the decision; donations are not compulsory.")
        "team_drill":
            if not is_instance_valid(hub) or float(hub.get("stamina")) < 15.0:
                return {"ok": false, "message": "Recover your Stamina before training."}
            hub.set("stamina", float(hub.get("stamina")) - 15.0)
            var trained: Dictionary = _record(kind, "trainer:drill", option_id, "Joined a coordinated Silver-team drill", 1,
                {"guild_reliability": 2}, "Spent 15 Stamina practicing footwork and squad timing; no new rank awarded.")
            _save_economy()
            return trained
        "boast":
            return _record(kind, "trainer:drill", option_id, "Dismissed experienced Seeker training", -1,
                {"guild_reliability": -1}, "The Silver instructor remembers your unwillingness to learn.")
        "study_public":
            return _record(kind, "soulwright:learning", option_id, "Studied public Soulwright field notes", 1,
                {"association_trust": 1}, "Public information only; no forbidden Soul Law revealed.")
        "force_files":
            return _record(kind, "soulwright:learning", option_id, "Demanded restricted Soulwright records", -2,
                {"association_trust": -3}, "Access was denied; the officer recorded the attempted breach.")
        "respect_gate":
            return _record(kind, "citadel:conduct", option_id, "Respected the Citadel security perimeter", 1,
                {"association_trust": 1}, "You remain outside the secured precinct, as required.")
        "bribe_gate":
            if GameState.tola < 18 or not GameState.spend_tola(18):
                return {"ok": false, "message": "You do not have 18 Tola to offer."}
            var failed: Dictionary = _record(kind, "citadel:conduct", option_id, "Attempted to bribe a Citadel sentry", -2,
                {"association_trust": -4, "local_respect": -2, "underworld_attention": 2},
                "The 18-Tola attempted bribe was confiscated and reported. Citadel access remains denied.")
            _save_economy()
            failed["message"] = "The sentry refuses, confiscates the 18 Tola, and files a report. The gate stays locked."
            return failed
        "flirt":
            if not is_player_adult_confirmed() or not CONSENTING_ADULT_ROLES.has(kind):
                return {"ok": false, "message": "Only confirmed adult characters can pursue romance."}
            var approach: Dictionary = _record(kind, "romance:%s:approach" % kind, option_id,
                "Shared a respectful moment with an adult resident", 1, {},
                "A mutual, optional flirtation. Both participants are adults and consent is required.")
            if bool(approach.get("ok", false)):
                var state: Dictionary = _state()
                var romance: Dictionary = state.get("romance", {})
                romance[kind] = "interested"
                state["romance"] = romance
                codex.profile["society"] = state
                codex.call("_save_profile")
                approach["message"] = "The resident smiles and welcomes getting to know you. Their continued consent matters."
            return approach
        "stay_friends":
            return _record(kind, "romance:%s:approach" % kind, option_id,
                "Chose to remain friends", 0, {}, "No romantic expectations were created.")
        "invite_date":
            if get_romance_status(kind) != "interested":
                return {"ok": false, "message": "The resident has not expressed mutual interest."}
            var date: Dictionary = _record(kind, "romance:%s:invitation" % kind, option_id,
                "Accepted an adult resident's invitation to spend time together", 1, {},
                "Two consenting adult characters arrange a public outing in Magnara's quarter.")
            if bool(date.get("ok", false)):
                var state: Dictionary = _state()
                var romance: Dictionary = state.get("romance", {})
                romance[kind] = "courting"
                state["romance"] = romance
                codex.profile["society"] = state
                codex.call("_save_profile")
                date["message"] = "You agree to a relaxed outing together. Your relationship moves toward courtship."
            return date
        "respect_space":
            var space: Dictionary = _record(kind, "romance:%s:invitation" % kind, option_id,
                "Respectfully stepped back from romance", 0, {}, "Both remain free to choose a platonic relationship.")
            if bool(space.get("ok", false)):
                var state: Dictionary = _state()
                var romance: Dictionary = state.get("romance", {})
                romance[kind] = "friends"
                state["romance"] = romance
                codex.profile["society"] = state
                codex.call("_save_profile")
            return space
        _:
            return {"ok": false, "message": "That action has no available outcome."}

func record_contract_outcome(index: int) -> void:
    if not _ensure_connections() or index < 0 or index > 2:
        return
    var key: String = "career:contract:%d" % index
    if not get_decision(key).is_empty():
        return
    var state: Dictionary = _state()
    var decisions: Dictionary = state.get("decisions", {})
    decisions[key] = "verified_completion"
    state["decisions"] = decisions
    _alter_reputation(state, {"association_trust": 2, "guild_reliability": 2})
    codex.profile["society"] = state
    codex.call("_save_profile")
