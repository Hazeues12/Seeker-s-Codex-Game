extends Node3D
const Posture = preload("res://combat/triad_posture_rules_v069.gd")
const Seals = preload("res://systems/alchemic_seal_rules_v069.gd")
const Guild = preload("res://systems/guild_public_director_v069.gd")

func _ready() -> void:
    call_deferred("_run")
func _fail(message: String) -> void:
    push_error("V0.69 TRIAD SEALS DIRECTOR RULES FAILED: "+message)
    get_tree().call_deferred("quit",1)

func _run() -> void:
    if Posture.rank_at_least("Stray","Gold") or Posture.rank_at_least("Silver","Gold"):
        _fail("ordinary beginners automatically receive Steel")
        return
    if not Posture.rank_at_least("Gold","Gold") or not Posture.rank_at_least("Sage","Grand"):
        _fail("correct highest-tier rank ordering missing")
        return
    if Posture.legal_will("Gold","steel",true,false):
        _fail("Gold alone grants an authored Will technique")
        return
    if not Posture.legal_will("Gold","steel",true,true) or Posture.legal_will("Silver","steel",true,true):
        _fail("Steel Gold+ canon rank gate invalid")
        return
    if Posture.legal_will("Gold","oi",true,true) or Posture.legal_will("Grand","oi",false,true):
        _fail("Sovereignty automatically unlocked without Grand+ and individual permission")
        return
    if not Posture.legal_will("Grand","oi",true,true):
        _fail("individually authorized Grand+ sovereignty gate missing")
        return
    if Posture.legal_will("Iron","sight",true,false) or not Posture.legal_will("Iron","sight",true,true):
        _fail("Sight not based on genuine authored training permission")
        return
    if not Posture.parry(0.11,true) or Posture.parry(0.17,true):
        _fail("basic 130ms reflex parry timing invalid")
        return
    if not Posture.parry(0.17,true,"Iron",true,true) or Posture.parry(0.12,false):
        _fail("scripted Sight parry extension or guard input invalid")
        return
    if Posture.parry(-1,true) or Posture.parry(INF,true):
        _fail("invalid timing was accepted")
        return
    var basic: Dictionary = Posture.posture_hit(80,24,false)
    var guarded: Dictionary = Posture.posture_hit(80,24,true)
    if not bool(basic.get("valid",false)) or float(basic["remaining"]) >= float(guarded["remaining"]):
        _fail("guard doesn't prevent posture collapse")
        return
    if not bool(Posture.posture_hit(15,30,false).get("break",false)):
        _fail("ordinary attacks cannot break guard")
        return
    if Posture.recover(20,1,false) >= Posture.recover(20,1,true):
        _fail("authored Steel does not regenerate posture faster")
        return
    if bool(Posture.oi_pressure("Gold","Stray",true,true,2).get("allowed",false)):
        _fail("Gold exerted Sovereignty on civilians")
        return
    if not bool(Posture.oi_pressure("Grand","Gold",true,true,3).get("allowed",false)):
        _fail("story-authorized Grand rank pressure calculation missing")
        return
    if bool(Posture.oi_pressure("Grand","Stray",true,true,12).get("allowed",false)):
        _fail("out-of-radius story aura affects distant citizens")
        return

    var ward: Dictionary = Seals.recipe("impact","ward")
    var signal: Dictionary = Seals.recipe("aura_ready","signal")
    if Seals.sanitize(ward).is_empty() or Seals.sanitize(signal).is_empty():
        _fail("finite alchemic compiler can't encode legitimate 3-rune recipes")
        return
    if ward.get("steps",[]).size() != 3 or not (ward["steps"][1] as Dictionary).get("op","") == "aura_at_least":
        _fail("alchemic trigger-condition-effect syntax was not compiled")
        return
    var forbidden: Dictionary = ward.duplicate(true)
    forbidden["steps"][2]["op"] = "teleport_janoah"
    if not Seals.sanitize(forbidden).is_empty():
        _fail("arbitrary seal code, teleport, or hostile commands accepted")
        return
    if not Seals.recipe("impact","ice_blast").is_empty() or not Seals.recipe("erase_memory","ward").is_empty():
        _fail("unlicensed Ice Muti or psychic soul crime in public rune set")
        return
    var armed: Dictionary = Seals.arm(ward)
    if armed.is_empty() or not bool(armed["armed"]):
        _fail("valid seal cannot arm")
        return
    if bool(Seals.fire(armed,{},"aura_ready",80,1).get("fired",false)):
        _fail("event mismatch caused automatic magic trigger")
        return
    if bool(Seals.fire(armed,{},"impact",10,1).get("fired",false)):
        _fail("seal fired despite insufficient Aura")
        return
    var triggered: Dictionary = Seals.fire(armed,{},"impact",80,1)
    if not bool(triggered.get("fired",false)) or not bool(triggered.get("absorbed",false)) or int(triggered.get("cost",-1)) != 18:
        _fail("prepared one-hit ward didn't generate safe paid effect")
        return
    if bool(Seals.fire(armed,triggered["next_receipts"],"impact",80,1).get("fired",false)):
        _fail("infinite free shield exploit by repeating today's impact")
        return
    if not bool(Seals.fire(armed,triggered["next_receipts"],"impact",80,2).get("fired",false)):
        _fail("new day cannot reactivate available training seal")
        return
    if not Seals.ledger({"day:1":true,"day:99":false,"day:-1":true,"day:5":"true"}).size() == 1:
        _fail("seal receipts trust forged types")
        return

    var book: Dictionary = {"day:1:lebells":2,"day:1:avicci":1}
    var d1: Dictionary = Guild.description("shop_watch",1,book)
    if d1.is_empty() or d1 != Guild.description("shop_watch",1,book):
        _fail("public trade-driven daily assignment isn't deterministic")
        return
    if int(d1.get("public_observed_units",-1)) != 3:
        _fail("public director ignores verified shop trade units")
        return
    if Guild.rank_allows("Stray","rooftop_report") or not Guild.rank_allows("Stray","shop_watch"):
        _fail("civilian observation and Seeker field work rank gates broken")
        return
    if not Guild.accept({},"rooftop_report",1,"Stray").is_empty():
        _fail("Stray accepted an Iron+ contract")
        return
    var accepted: Dictionary = Guild.accept({},"shop_watch",1,"Stray")
    if accepted.is_empty() or not Guild.accept(accepted,"shop_watch",1,"Stray").is_empty():
        _fail("one active job rule missing")
        return
    var far: Vector3 = Vector3(-20,0,620)
    if Guild.can_finish(accepted,"shop_watch",1,far) or Guild.can_finish(accepted,"shop_watch",2,Guild.LOCATIONS[0]):
        _fail("day or player-position completion exploit")
        return
    var done: Dictionary = Guild.finish(accepted,"shop_watch",1,Guild.LOCATIONS[0])
    if done.is_empty() or not str(done["active"]).is_empty():
        _fail("real destination failed public job completion")
        return
    if not Guild.finish(done,"shop_watch",1,Guild.LOCATIONS[0]).is_empty() or not Guild.accept(done,"shop_watch",1,"Stray").is_empty():
        _fail("same quest can pay twice on one day")
        return
    if Guild.accept(done,"shop_watch",2,"Stray").is_empty():
        _fail("public local quest rotation doesn't reopen new day")
        return
    var forged: Dictionary = Guild.sanitize({"active":"secret_red_order_raid",
        "accepted_day":1,"receipts":{"day:1:shop_watch":true,"day:2:red_order":true,
        "day:0:shop_watch":true,"day:3:rooftop_report":"true"}})
    if not str(forged["active"]).is_empty() or (forged["receipts"] as Dictionary).size() != 1:
        _fail("hidden faction raids or forged receipts reached civilian board")
        return
    print("V0.69 TRIAD GOLD GRAND GATES POSTURE PARRY FINITE SEAL DIRECTOR DAILY CONTRACT RULES PASS")
    get_tree().call_deferred("quit",0)
