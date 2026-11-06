#!/usr/bin/env python3
"""V0.44 guarded V0.43 bootstrap and in-place social memory upgrade."""
import base64, io, re, tarfile, subprocess
from pathlib import Path

V043_WORKFLOW_SHA = "98cf4ba71ef2deea396c1ed481630bccf3722e68"
V043_PERSONAL_CODEX_SHA = "fd8de56907b36d28d9fc1d76358f08d94c5a5b75"

def exact(s, old, new, label):
    matches = s.count(old)
    if matches != 1:
        raise SystemExit("V0.44: anchor '%s' appeared %d times; abort" % (label, matches))
    return s.replace(old, new, 1)

def sha(path):
    return subprocess.check_output(["git", "hash-object", path], text=True).strip()

def extract_v043_from_verified_workflow():
    workflow = Path(".github/workflows/margerina-v043.yml")
    if not workflow.exists() or sha(workflow) != V043_WORKFLOW_SHA:
        raise SystemExit("V0.44: V0.43 verified installer has changed; abort")
    data = workflow.read_text(encoding="utf8")
    start = data.index("          encoded = (")
    end = data.index("\n          )", start)
    bits = re.findall(r"'([A-Za-z0-9+/=]+)'", data[start:end])
    payload = base64.b64decode("".join(bits))
    expected = {"install_v043.py","systems/personal_codex.gd",
                "docs/V043_FEATURES.md","docs/MARGERINA_MASTER_RPG_DESIGN_BIBLE.md",
                "tests/v043_codex_smoke.gd"}
    with tarfile.open(fileobj=io.BytesIO(payload), mode="r:gz") as pack:
        members = pack.getmembers()
        if {m.name for m in members} != expected or any(not m.isfile() for m in members):
            raise SystemExit("V0.44: unexpected V0.43 archived content")
        contents = {m.name: pack.extractfile(m).read() for m in members}
    for path, data in contents.items():
        dest = Path(path)
        if dest.exists() and dest.read_bytes() != data:
            raise SystemExit("V0.44: existing V0.43 source differs at " + path)
    for path, data in contents.items():
        dest = Path(path)
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)

def run():
    paths = {
        "scene": Path("scenes/main.tscn"),
        "hub": Path("systems/hub_manager.gd"),
        "player": Path("characters/player_controller.gd"),
        "codex": Path("systems/personal_codex.gd"),
    }
    scene = paths["scene"].read_text(encoding="utf8")
    if '[node name="SeekerRelationships"' in scene:
        if not Path("systems/seeker_relationships.gd").exists():
            raise SystemExit("V0.44: relationship node exists but script is missing")
        print("V0.44 already installed, no source mutation")
        return
    if not Path("systems/seeker_relationships.gd").exists():
        raise SystemExit("V0.44: staged dialogue source missing")
    extract_v043_from_verified_workflow()
    if '[node name="PersonalCodex"' not in scene:
        import install_v043
        install_v043.patch_existing_sources()
        print("V0.44 bootstrapped V0.43 from the audited V0.41 sources")
    elif sha(paths["codex"]) != V043_PERSONAL_CODEX_SHA:
        raise SystemExit("V0.44: unexpected Personal Codex version; abort")

    content = {key: path.read_text(encoding="utf8") for key, path in paths.items()}
    scene = content["scene"]
    scene = exact(scene, "[gd_scene load_steps=15 format=3]",
                  "[gd_scene load_steps=16 format=3]", "scene resources")
    ext = '[ext_resource type="Script" path="res://systems/personal_codex.gd" id="11"]'
    scene = exact(scene, ext, ext + '\n[ext_resource type="Script" path="res://systems/seeker_relationships.gd" id="12"]', "script reference")
    end = '[node name="PersonalCodex" type="Node" parent="."]\nscript = ExtResource("11")'
    scene = exact(scene, end, end + '\n\n[node name="SeekerRelationships" type="Node" parent="."]\nscript = ExtResource("12")', "relationship node")
    content["scene"] = scene

    hub = content["hub"]
    old = '''    var codex_open: bool = is_instance_valid(codex) and bool(codex.call("is_open"))
    return board_panel.visible or bag_panel.visible or journal_open or codex_open or (is_instance_valid(editor) and bool(editor.call("is_open")))'''
    new = '''    var codex_open: bool = is_instance_valid(codex) and bool(codex.call("is_open"))
    var relations: Node = get_tree().get_first_node_in_group("seeker_relationships")
    var relations_open: bool = is_instance_valid(relations) and bool(relations.call("is_open"))
    return board_panel.visible or bag_panel.visible or journal_open or codex_open or relations_open or (is_instance_valid(editor) and bool(editor.call("is_open")))'''
    hub = exact(hub, old, new, "menu interlock")
    old = '''    if is_instance_valid(codex) and codex.has_method("record_interaction"):
        codex.call("record_interaction", kind, str(nearest["title"]))


func _npc_dialogue'''
    new = '''    if is_instance_valid(codex) and codex.has_method("record_interaction"):
        codex.call("record_interaction", kind, str(nearest["title"]))
    var relations: Node = get_tree().get_first_node_in_group("seeker_relationships")
    if is_instance_valid(relations) and bool(relations.call("supports", kind)):
        relations.call("open_dialogue", kind, str(nearest["title"]))


func _npc_dialogue'''
    hub = exact(hub, old, new, "social interaction hook")
    content["hub"] = hub

    player = content["player"]
    old = '''    if is_instance_valid(personal_codex) and personal_codex.has_method("is_open"):
        editing = editing or bool(personal_codex.call("is_open"))
    if editing:
        input_dir = Vector2.ZERO'''
    new = '''    if is_instance_valid(personal_codex) and personal_codex.has_method("is_open"):
        editing = editing or bool(personal_codex.call("is_open"))
    var relations: Node = get_tree().get_first_node_in_group("seeker_relationships")
    if is_instance_valid(relations) and relations.has_method("is_open"):
        editing = editing or bool(relations.call("is_open"))
    if editing:
        input_dir = Vector2.ZERO'''
    content["player"] = exact(player, old, new, "pause movement during social dialogue")

    codex = content["codex"]
    old = '            output += " - %s (acquainted)\\n" % str(contacts[key].get("name", key))'
    new = '''            var friend: Dictionary = contacts[key]
            output += " - %s | %s | rapport %d\\n" % [str(friend.get("name", key)), str(friend.get("relationship", "acquainted")), int(friend.get("rapport", 0))]'''
    codex = exact(codex, old, new, "contact display")
    codex += '''

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
'''
    content["codex"] = codex
    # Commit patches to runner checkout only after every compatibility check.
    for key, path in paths.items():
        path.write_text(content[key], encoding="utf8")
    print("V0.44 Personal Codex and persistent NPC relationships installed")

if __name__ == "__main__":
    run()
