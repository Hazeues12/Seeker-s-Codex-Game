extends Node3D

const Main = preload("res://scenes/main.tscn")
const Wards = preload("res://systems/magnara_expansion_rules_v071.gd")
const PASS := "V0.88 DISTINCT TOWNSFOLK SHARED SHIFT IDENTITY AND CROWD LOD PASS"


func _ready() -> void:
    call_deferred("_run")


func _check(ok: bool, reason: String) -> bool:
    if not ok:
        push_error("V0.88 TOWNSFOLK: " + reason)
        get_tree().call_deferred("quit", 1)
    return ok


func _run() -> void:
    var game := Main.instantiate() as Node3D
    add_child(game)
    for i in range(8):
        await get_tree().process_frame
    var courier := game.find_child("COURIER", true, false).get_node("Townsperson") as TownspersonVisual
    var trainee := game.find_child("SEEKER_TRAINEE", true, false).get_node("Townsperson") as TownspersonVisual
    if not _check(courier.form == TownspersonVisual.Form.MAN
            and trainee.form == TownspersonVisual.Form.WOMAN and courier.figure.mesh != trainee.figure.mesh,
            "the starting quarter did not get two different silhouettes"):
        return
    for resident in [courier, trainee]:
        var mesh: ArrayMesh = resident.figure.mesh
        var arrays: Array = mesh.surface_get_arrays(0)
        if not _check(mesh.get_surface_count() == 1 and resident.figure.skin != null
                and arrays[Mesh.ARRAY_TEX_UV] is PackedVector2Array
                and arrays[Mesh.ARRAY_INDEX].size() / 3 < 4000,
                "close model is missing paint or exceeds the one-surface mesh budget"):
            return

    var ward := game.get_node("MagnaraExpandedWardsV071")
    var interiors := game.get_node("MagnaraWardInteriorsV072")
    var hub := game.get_node("HubManager")
    var player := game.get_node("Player") as CharacterBody3D
    var cell := Vector2i(2, 0)
    var identity: String = Wards.resident(cell, 11)["id"]
    hub.set("world_minutes", 500.0)
    player.global_position = Wards.resident_state(cell, 11, 500.0)["world_position"]
    for i in range(5):
        ward.call("_refresh_chunks")
    ward.call("_refresh_crowds")
    interiors.call("_refresh")
    var street: Node3D = ward.get("close_models").get(identity)
    var site: Dictionary = interiors.get("sites").get(Wards.key(cell), {})
    if not _check(street != null and not site.is_empty(), "the same ward was not streamed on both systems"):
        return
    var outdoors := street.get_node("Townsperson") as TownspersonVisual
    var employee := site["staff"] as Node3D
    var indoors := employee.get_node("Townsperson") as TownspersonVisual
    if not _check(outdoors.form == indoors.form and outdoors.coat == indoors.coat
            and outdoors.skin == indoors.skin and outdoors.scale.is_equal_approx(indoors.scale),
            "a resident changed appearance when moving into work"):
        return
    hub.set("world_minutes", 670.0)
    ward.call("_refresh_crowds")
    interiors.call("_refresh")
    if not _check(employee.visible and not ward.get("close_models").has(identity),
            "the visual upgrade duplicated a worker during an indoor shift"):
        return
    var ward_chunk: Dictionary = ward.get("active_chunks")[Wards.key(cell)]
    var batch := ward_chunk["crowd"] as MultiMeshInstance3D
    if not _check(batch.multimesh.mesh == TownspersonVisual.mid_mesh(), "the mid crowd lost its shared batch"):
        return

    if OS.has_feature("web"):
        game.queue_free()
        await get_tree().process_frame
        _studio()
        for i in range(8):
            await get_tree().process_frame
    print(PASS)
    if OS.has_feature("web"):
        await get_tree().create_timer(15.0).timeout
    get_tree().call_deferred("quit", 0)


func _studio() -> void:
    var room := WorldEnvironment.new()
    room.environment = Environment.new()
    room.environment.background_mode = Environment.BG_COLOR
    room.environment.background_color = Color("#EAE4D9")
    add_child(room)
    var forms := [TownspersonVisual.Form.MAN, TownspersonVisual.Form.WOMAN,
        TownspersonVisual.Form.CHILD, TownspersonVisual.Form.WOMAN, TownspersonVisual.Form.MAN]
    var colors := [Color("#7D877A"), Color("#7D877A"), Color("#8F788F"),
        Color("#A47857"), Color("#678392")]
    var skin := [Color("#DBA67F"), Color("#DBA67F"), Color("#AC785D"),
        Color("#815342"), Color("#F1C8AA")]
    for index in range(forms.size()):
        var resident := TownspersonVisual.add_to(self, "preview_" + str(index), forms[index],
            colors[index], skin[index])
        resident.position.x = 1.72 - 0.86 * index
        resident.rotation.y = [0.0, 0.0, 0.12, 2.3, -0.60][index]
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 2.68
    camera.position = Vector3(0, 1.1, -7)
    add_child(camera)
    camera.look_at(Vector3(0, 1.11, 0))
    camera.make_current()
