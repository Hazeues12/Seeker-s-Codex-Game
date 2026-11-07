extends Node3D

const ACQUIRE_DISTANCE: float = 38.0
const RELEASE_DISTANCE: float = 48.0
const PLACE: String = "Magnara / Ring Three / The Commons"
const READING_ID: String = "commons_v080_reading"
const VERSES: Array[String] = [
    "Leave a lamp burning for the feet still on the road.",
    "The bridge cools as the last worker crosses home.",
    "We shared a loaf at noon. By dusk, we shared a bench.",
]

var player: CharacterBody3D
var hub: Node
var active_tile: String = ""
var picnic: Node3D
var reading: Node3D
var family: Array[TownspersonVisual] = []
var poet: TownspersonVisual

func _ready() -> void:
    add_to_group("magnara_commons_life_v080")
    set_meta("canon_status", "game_only")
    hide()

func configure(hero: CharacterBody3D, city_hub: Node) -> void:
    player = hero
    hub = city_hub

func _build_gathering() -> void:
    picnic = Node3D.new()
    picnic.name = "FamilyPicnic"
    add_child(picnic)
    var mat_center := Vector3(6.55, 0.70, 1.35)
    _picnic_prop("WovenMat", mat_center, Vector3(3.10, 0.025, 3.0), Color(0.66, 0.26, 0.25))
    _picnic_prop("FoodBasket", mat_center + Vector3(0.0, 0.17, 0.05),
        Vector3(0.56, 0.30, 0.37), Color(0.62, 0.40, 0.24))
    family.append(_civilian(picnic, "PicnicGuestOne", Vector3(5.5, 0.72, 0.75), mat_center,
        TownspersonVisual.Form.WOMAN, Color(0.32, 0.52, 0.48), Color(0.65, 0.46, 0.33)))
    family.append(_civilian(picnic, "PicnicGuestTwo", Vector3(7.5, 0.72, 0.60), mat_center,
        TownspersonVisual.Form.MAN, Color(0.66, 0.48, 0.25), Color(0.50, 0.33, 0.25)))
    family.append(_civilian(picnic, "YoungPicnicGuest", Vector3(7.15, 0.72, 2.40), mat_center,
        TownspersonVisual.Form.CHILD, Color(0.52, 0.40, 0.59), Color(0.58, 0.40, 0.29)))
    for guest in family:
        guest.set_motion(0.0, "sit")

    reading = Node3D.new()
    reading.name = "OpenSquareReading"
    add_child(reading)
    var poet_position := Vector3(2.85, 0.75, -1.45)
    var audience_side := Vector3(2.15, 0.75, 1.50)
    poet = _civilian(reading, "PublicPoet", poet_position, audience_side, TownspersonVisual.Form.MAN,
        Color(0.35, 0.41, 0.59), Color(0.72, 0.54, 0.40))
    poet.set_motion(0.0, "recite")
    _civilian(reading, "PoetryListener", audience_side, poet_position, TownspersonVisual.Form.WOMAN,
        Color(0.59, 0.39, 0.34), Color(0.45, 0.31, 0.22))
    var sign := Label3D.new()
    sign.text = "COMMONS READING"
    sign.position = poet_position + Vector3.UP * 2.28
    sign.font_size = 30
    sign.pixel_size = 0.007
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.visibility_range_end = 18.0
    reading.add_child(sign)

func _civilian(parent: Node3D, title: String, at: Vector3, toward: Vector3,
        form: TownspersonVisual.Form, coat: Color, skin: Color) -> TownspersonVisual:
    var actor := TownspersonVisual.add_to(parent, title, form, coat, skin)
    actor.name = title
    actor.position = at
    var direction: Vector3 = toward - at
    actor.rotation.y = atan2(-direction.x, -direction.z)
    return actor

func _picnic_prop(title: String, at: Vector3, size: Vector3, tint: Color) -> void:
    var prop := MeshInstance3D.new()
    prop.name = title
    var mesh := BoxMesh.new()
    mesh.size = size
    prop.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    prop.material_override = material
    prop.position = at
    prop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    picnic.add_child(prop)

func _reading_at(hour: float) -> bool:
    return (hour >= 8.0 and hour < 10.0) or (hour >= 18.5 and hour < 21.5)

func refresh(tiles: Dictionary) -> void:
    if not is_instance_valid(hub) or not is_instance_valid(player):
        return
    var hour: float = fposmod(float(hub.get("world_minutes")), 1440.0) / 60.0
    var picnic_time: bool = hour >= 10.0 and hour < 20.5
    var reading_time: bool = _reading_at(hour)
    if not picnic_time and not reading_time:
        active_tile = ""
        hide()
        return

    var point: Vector3 = player.global_position
    # Keep the same courtyard as the player walks around it.
    if not tiles.has(active_tile) or point.distance_squared_to(global_position) > RELEASE_DISTANCE * RELEASE_DISTANCE:
        active_tile = ""
        var best: float = ACQUIRE_DISTANCE * ACQUIRE_DISTANCE
        for key in tiles:
            var tile: Dictionary = tiles[key]
            var layer: Node3D = tile["root"]
            for center in tile["court_centers"]:
                var at: Vector3 = layer.to_global(center)
                var distance: float = point.distance_squared_to(at)
                if distance < best:
                    best = distance
                    active_tile = str(key)
                    global_position = at

    if active_tile.is_empty():
        hide()
        return
    if picnic == null:
        _build_gathering()
    picnic.visible = picnic_time
    reading.visible = reading_time
    show()

func get_nearest_interaction(point: Vector3, reach: float) -> Dictionary:
    if not visible or not reading.visible or not is_instance_valid(hub):
        return {}
    var hour: float = fposmod(float(hub.get("world_minutes")), 1440.0) / 60.0
    if not _reading_at(hour) or point.distance_to(poet.global_position) >= reach:
        return {}
    return {"id": READING_ID, "title": "Commons reading", "position": poet.global_position, "node": poet}

func listen() -> void:
    if not is_instance_valid(player) or not is_instance_valid(hub):
        return
    if get_nearest_interaction(player.global_position, float(hub.get("interact_range"))).is_empty():
        return
    var day: int = floori(float(hub.get("world_minutes")) / 1440.0)
    var verse_index: int = posmod(day, VERSES.size())
    var verse: String = VERSES[verse_index]
    hub.call("_announce", "“%s”" % verse)
    var codex: Node = get_tree().get_first_node_in_group("personal_codex")
    if is_instance_valid(codex):
        codex.call("record_event", "v080:commons_reading:%d" % verse_index, "commons_reading",
            "Heard a reading in the Commons", verse, PLACE)
