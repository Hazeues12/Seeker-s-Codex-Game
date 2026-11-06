extends Node3D

# V0.52 WORLD FIRST: four real streamed Ring Two wards around the V0.40 spine.
# All block placements, interiors, street names and local bearings are GAME_ONLY.
# Chapter 90 establishes the architecture and Seeker Quarters, not this street grid.
const LOAD_RADIUS: float = 77.0
const UNLOAD_RADIUS: float = 97.0
const CELL_CENTERS: Dictionary = {
    "west_public": Vector2(-70.0, 50.0),
    "west_professional": Vector2(-70.0, 90.0),
    "east_public": Vector2(70.0, 50.0),
    "east_professional": Vector2(70.0, 90.0)
}
const CELL_SOURCE: String = "Chapter 90 Ring Two characteristics; street placements game_only"

var player: Node3D
var active_cells: Dictionary = {}
var material_cache: Dictionary = {}
var box_cache: Dictionary = {}
var clock: float = 0.0
var tram: Node3D
var tram_progress: float = 0.0

func _ready() -> void:
    add_to_group("magnara_city_v052")
    set_process(false)
    call_deferred("_initialize")

func _initialize() -> void:
    if not is_inside_tree():
        return
    player = get_parent().get_node_or_null("Player") as Node3D
    if not is_instance_valid(player):
        push_warning("Magnara expansion needs the existing main-scene Player")
        return
    _build_tram()
    _refresh_cells()
    set_process(true)

func get_manifest() -> Dictionary:
    return {
        "world": "Margerina",
        "nation": "Janoah",
        "city": "Magnara",
        "district": "Ring Two / Seeker Quarters",
        "streamed_cells": CELL_CENTERS.keys(),
        "confirmed": ["seven-ring city", "public living quarter", "professional Seeker facilities", "secured Citadel"],
        "game_only": ["four ward coordinates", "public rest house", "records hall", "local tram alignment"],
        "source": CELL_SOURCE
    }

func _process(delta: float) -> void:
    clock += delta
    if clock >= 0.55:
        clock = 0.0
        _refresh_cells()
    if is_instance_valid(tram):
        tram_progress = fposmod(tram_progress + delta * 5.8, 380.0)
        var travel: float = tram_progress if tram_progress <= 190.0 else 380.0 - tram_progress
        tram.position.x = -95.0 + travel
        tram.position.z = 70.1
        tram.rotation.y = 0.0 if tram_progress <= 190.0 else PI
        tram.visible = is_instance_valid(player) and player.global_position.distance_to(tram.global_position) < 95.0

func _refresh_cells() -> void:
    if not is_instance_valid(player):
        return
    var here := Vector2(player.global_position.x, player.global_position.z)
    for key in CELL_CENTERS:
        var target: Vector2 = CELL_CENTERS[key]
        var range_now: float = here.distance_to(target)
        if not active_cells.has(key) and range_now < LOAD_RADIUS:
            var block := Node3D.new()
            block.name = "MagnaraCell_" + str(key)
            block.add_to_group("magnara_streamed_cell")
            add_child(block)
            _build_cell(str(key), block)
            active_cells[key] = block
        elif active_cells.has(key) and range_now > UNLOAD_RADIUS:
            var retired: Node3D = active_cells[key] as Node3D
            active_cells.erase(key)
            retired.queue_free()

func _mat(color: Color, luminous: bool = false) -> StandardMaterial3D:
    var key: String = str(color) + ("_lit" if luminous else "_mat")
    if material_cache.has(key):
        return material_cache[key]
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.roughness = 0.78
    if luminous:
        result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        result.emission_enabled = true
        result.emission = color
        result.emission_energy_multiplier = 1.35
    material_cache[key] = result
    return result

func _part(parent: Node3D, name: String, at: Vector3, dimensions: Vector3,
        color: Color, solid: bool = false, wall: bool = false, luminous: bool = false) -> MeshInstance3D:
    var part := MeshInstance3D.new()
    part.name = name
    var key: String = str(dimensions)
    var mesh: BoxMesh
    if box_cache.has(key):
        mesh = box_cache[key]
    else:
        mesh = BoxMesh.new()
        mesh.size = dimensions
        box_cache[key] = mesh
    part.mesh = mesh
    part.material_override = _mat(color, luminous)
    part.position = at
    part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(part)
    if solid:
        var body := StaticBody3D.new()
        body.name = name + "Solid"
        if wall:
            body.add_to_group("traversal_wall")
        part.add_child(body)
        var collider := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = dimensions
        collider.shape = shape
        body.add_child(collider)
    return part

func _tag(parent: Node3D, text_value: String, at: Vector3, size: int = 31) -> void:
    var label := Label3D.new()
    label.text = text_value
    label.font_size = size
    label.pixel_size = 0.006
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    label.position = at
    parent.add_child(label)

func _lamp(parent: Node3D, at: Vector3) -> void:
    var bronze := Color(0.44, 0.31, 0.20)
    _part(parent, "BronzeStreetLamp", at + Vector3(0.0, 1.54, 0.0),
        Vector3(0.16, 2.25, 0.16), bronze)
    _part(parent, "GlassSigilLantern", at + Vector3(0.0, 2.76, 0.0),
        Vector3(0.48, 0.56, 0.48), Color(0.27, 0.77, 0.91), false, false, true)
    _part(parent, "BronzeLampCap", at + Vector3(0.0, 3.09, 0.0),
        Vector3(0.57, 0.12, 0.57), bronze)

func _city_house(parent: Node3D, name: String, x: float, z: float, floors: int, tint: Color) -> void:
    var height: float = 3.4 + float(floors) * 1.16
    var face: float = -1.0 if x > 0.0 else 1.0
    _part(parent, name + "StoneStructure", Vector3(x, 0.5 + height * 0.5, z),
        Vector3(11.6, height, 9.2), tint, true, true)
    _part(parent, name + "SlateRoof", Vector3(x, 0.62 + height, z),
        Vector3(12.1, 0.24, 9.7), Color(0.19, 0.26, 0.32), true)
    _part(parent, name + "BronzeCornice", Vector3(x, 0.76 + height, z),
        Vector3(12.4, 0.13, 9.9), Color(0.51, 0.37, 0.25))
    for floor_index in range(floors):
        var wy: float = 2.05 + float(floor_index) * 1.26
        for iz in [-2.60, 2.60]:
            _part(parent, name + "GlassCasement",
                Vector3(x + face * 5.86, wy, z + iz),
                Vector3(0.08, 0.83, 1.42), Color(0.31, 0.58, 0.66))
            _part(parent, name + "WindowLintel",
                Vector3(x + face * 5.92, wy + 0.48, z + iz),
                Vector3(0.12, 0.12, 1.70), Color(0.69, 0.56, 0.36))
    _part(parent, name + "EntryDoor", Vector3(x + face * 5.89, 1.65, z),
        Vector3(0.10, 2.20, 1.56), Color(0.24, 0.28, 0.30))
    _part(parent, name + "DoorAwning", Vector3(x + face * 6.35, 2.85, z),
        Vector3(1.17, 0.18, 2.45), Color(0.38, 0.44, 0.49))
    for balcony in [-2.5, 2.5]:
        _part(parent, name + "Balcony", Vector3(x + face * 6.24, 3.52, z + balcony),
            Vector3(1.12, 0.18, 2.12), Color(0.35, 0.36, 0.39))
    _part(parent, name + "Chimney", Vector3(x - face * 3.25, 1.10 + height, z + 2.5),
        Vector3(0.70, 1.5, 0.70), Color(0.38, 0.39, 0.43))

func _open_house(parent: Node3D, name: String, x: float, z: float,
        entry_face: float, professional: bool, sign_text: String = "") -> void:
    # Hollow, collidable room: door gap is real open space, not a texture.
    var room := Node3D.new()
    room.name = "Enterable" + name
    room.position = Vector3(x, 0.0, z)
    parent.add_child(room)
    var w: float = 13.0
    var d: float = 11.0
    var stone: Color = Color(0.52, 0.56, 0.60) if professional else Color(0.71, 0.62, 0.51)
    var outer: Color = Color(0.19, 0.25, 0.32)
    var bronze: Color = Color(0.72, 0.52, 0.26)
    _part(room, "InteriorTileFloor", Vector3(0.0, 0.57, 0.0),
        Vector3(w - 0.45, 0.12, d - 0.45), Color(0.61, 0.60, 0.55), true)
    for front_back in [-1.0, 1.0]:
        _part(room, "StoneSideWall", Vector3(0.0, 2.80, front_back * d * 0.5),
            Vector3(w, 4.60, 0.40), stone, true, true)
    _part(room, "RearStoneWall", Vector3(-entry_face * w * 0.5, 2.80, 0.0),
        Vector3(0.40, 4.60, d), stone, true, true)
    var segment: float = (d - 2.80) * 0.5
    for side in [-1.0, 1.0]:
        _part(room, "DoorwayWing", Vector3(entry_face * w * 0.5, 2.80,
            side * (1.40 + segment * 0.5)),
            Vector3(0.40, 4.60, segment), stone, true, true)
    _part(room, "DoorwayHeader", Vector3(entry_face * w * 0.5, 4.08, 0.0),
        Vector3(0.44, 2.04, 2.80), stone, true)
    _part(room, "RoofDeck", Vector3(0.0, 5.23, 0.0),
        Vector3(w + 0.60, 0.30, d + 0.60), outer, true)
    _part(room, "RoofBronzeTrim", Vector3(0.0, 5.43, 0.0),
        Vector3(w + 1.00, 0.10, d + 1.00), bronze)
    for side in [-1.0, 1.0]:
        _part(room, "InteriorWindow", Vector3(2.45, 2.85, side * 5.74),
            Vector3(1.60, 1.20, 0.08), Color(0.27, 0.69, 0.77), false, false, true)
    _part(room, "ServiceDesk", Vector3(-entry_face * 1.25, 1.06, -2.85),
        Vector3(2.5, 1.08, 1.18), Color(0.33, 0.28, 0.24), true)
    _part(room, "Bench", Vector3(-entry_face * 1.2, 0.88, 3.3),
        Vector3(2.2, 0.40, 0.76), Color(0.38, 0.29, 0.20), true)
    for side in [-1.0, 1.0]:
        _part(room, "HangingLantern", Vector3(0.0, 3.9, side * 3.15),
            Vector3(0.45, 0.55, 0.45), Color(0.83, 0.70, 0.43), false, false, true)
    var room_sign: String = ("PUBLIC SEEKER RECORDS" if professional else "PUBLIC REST HOUSE") if sign_text.is_empty() else sign_text
    _tag(room, room_sign + " / GAME-ONLY",
        Vector3(entry_face * 6.9, 6.25, 0.0), 29)
    # Rooftop access: physically collidable climbing platforms in a side alley.
    # Steps stay off the entrance centerline; double jump remains available.
    for index in range(10):
        var rise: float = float(index + 1) * 0.48
        var step_x: float = -entry_face * (8.9 - float(index) * 0.70)
        _part(room, "RooftopAccessStep_%d" % index,
            Vector3(step_x, 0.5 + rise * 0.5, 6.95),
            Vector3(1.12, rise, 1.30), Color(0.49, 0.50, 0.52), true)
    _tag(room, "ROOF ACCESS", Vector3(0.0, 6.2, 6.25), 24)

func _market(parent: Node3D, x: float, z: float, prefix: String) -> void:
    for n in range(3):
        var dx: float = float(n) * 3.20
        _part(parent, prefix + "PublicVendorTable", Vector3(x, 1.16, z + dx),
            Vector3(1.9, 1.1, 1.7), Color(0.42, 0.29, 0.19))
        _part(parent, prefix + "ColoredAwning", Vector3(x, 2.73, z + dx),
            Vector3(2.40, 0.18, 2.15),
            Color(0.31, 0.53, 0.62) if n % 2 == 0 else Color(0.65, 0.40, 0.28))
    _tag(parent, "MARKET WALK", Vector3(x, 3.5, z + 2.8), 26)

func _bridge(parent: Node3D, x: float, z: float) -> void:
    _part(parent, "IronFootbridgeDeck", Vector3(x, 0.80, z),
        Vector3(8.1, 0.30, 8.6), Color(0.33, 0.36, 0.41), true)
    for side in [-1.0, 1.0]:
        _part(parent, "BridgeRail", Vector3(x + side * 3.88, 1.48, z),
            Vector3(0.17, 1.16, 8.7), Color(0.40, 0.33, 0.29))

func _build_cell(key: String, parent: Node3D) -> void:
    var center: Vector2 = CELL_CENTERS[key]
    var west: bool = key.begins_with("west")
    var public: bool = key.ends_with("public")
    var mx: float = center.x
    var cz: float = center.y
    var stone := Color(0.55, 0.56, 0.56)
    # Four contiguous ground sections touching the existing V0.40 footprint
    # exactly at x = +/-34; player saves are extended to these new cells.
    if key == "west_public":
        _part(parent, "CanalNorthWalkableGround", Vector3(mx, 0.0, 37.25),
            Vector3(72.0, 1.0, 14.5), stone, true)
        _part(parent, "CanalSouthWalkableGround", Vector3(mx, 0.0, 60.25),
            Vector3(72.0, 1.0, 19.5), stone, true)
        _part(parent, "LowerCanalBed", Vector3(mx, -0.96, 47.5),
            Vector3(72.0, 0.50, 6.0), Color(0.32, 0.43, 0.49), true)
        _part(parent, "BlueResonanceCanalSurface", Vector3(mx, -0.67, 47.5),
            Vector3(72.0, 0.04, 6.0), Color(0.11, 0.48, 0.65), false, false, true)
        for edge in [44.5, 50.5]:
            _part(parent, "CanalStoneBank", Vector3(mx, 0.73, edge),
                Vector3(72.0, 0.45, 0.30), Color(0.72, 0.70, 0.64))
        _bridge(parent, -62.0, 47.5)
        _bridge(parent, -88.0, 47.5)
    else:
        _part(parent, "WalkableCellGround", Vector3(mx, 0.0, cz),
            Vector3(72.0, 1.0, 40.0), stone, true)
    # Streets keep the old Magnara spine open and create real cross-city paths.
    var street_x: float = -62.0 if west else 62.0
    _part(parent, "NorthSouthSeekerStreet", Vector3(street_x, 0.55, cz),
        Vector3(10.0, 0.09, 39.75), Color(0.73, 0.69, 0.62))
    _part(parent, "TransverseAvenue", Vector3(mx, 0.57, 69.25 if public else 71.0),
        Vector3(71.5, 0.06, 7.70), Color(0.69, 0.65, 0.59))
    for xside in [-1.0, 1.0]:
        _part(parent, "BronzeTramRail", Vector3(mx, 0.625, 69.30 + xside * 1.25),
            Vector3(70.0, 0.055, 0.11), Color(0.67, 0.47, 0.27))
    for n in range(4):
        var zlamp: float = (34.0 if public else 77.0) + float(n) * 9.1
        _lamp(parent, Vector3(street_x + (6.0 if west else -6.0), 0.0, zlamp))
    var outer_x: float = -89.0 if west else 89.0
    var inner_x: float = -43.0 if west else 43.0
    var zlist: Array = [38.0, 57.5] if public else [82.0, 101.0]
    for j in range(2):
        var zz: float = zlist[j]
        if key == "east_public" and j == 0:
            _open_house(parent, "PublicRestHouse", outer_x, zz, -1.0, false)
        elif key == "west_professional" and j == 1:
            _open_house(parent, "SeekerRecordsHall", outer_x, zz, 1.0, true)
        else:
            _city_house(parent, key + "Outer_%d" % j, outer_x, zz, 2 + j,
                Color(0.66, 0.60, 0.55) if public else Color(0.49, 0.55, 0.59))
        # Four additional physical interiors: no fake entrance decals.
        # Their occupations and coordinates are provisional game-only content.
        var interior_name: String = ""
        var interior_sign: String = ""
        if key == "west_public" and j == 1:
            interior_name = "CanalServiceHouse"
            interior_sign = "CANAL SERVICE HOUSE"
        elif key == "east_public" and j == 1:
            interior_name = "CivicDiningHall"
            interior_sign = "PUBLIC DINING HALL"
        elif key == "west_professional" and j == 0:
            interior_name = "SeekerMedicalAnnex"
            interior_sign = "MEDICAL ANNEX"
        elif key == "east_professional" and j == 1:
            interior_name = "SupplyInspectionHall"
            interior_sign = "SUPPLY INSPECTION"
        if not interior_name.is_empty():
            _open_house(parent, interior_name, inner_x, zz,
                -1.0 if west else 1.0, not public, interior_sign)
        else:
            _city_house(parent, key + "Inner_%d" % j, inner_x, zz, 2 + (j + 1) % 2,
                Color(0.61, 0.57, 0.56) if public else Color(0.55, 0.58, 0.63))
    if key == "west_public":
        _market(parent, -53.0, 33.6, "CanalWard")
        _tag(parent, "SEEKER QUARTERS / CANAL WALK", Vector3(-61.0, 5.3, 35.0), 30)
    elif key == "east_public":
        _market(parent, 53.0, 45.0, "PublicWard")
        _tag(parent, "RING TWO / CIVIC RESIDENCES", Vector3(63.0, 5.3, 36.0), 30)
        _part(parent, "PublicLaundryLine", Vector3(71.0, 2.3, 57.5),
            Vector3(7.0, 0.12, 0.15), Color(0.82, 0.75, 0.56))
    elif key == "west_professional":
        _tag(parent, "SEEKER SERVICE COURTS", Vector3(-62.0, 5.2, 84.0), 30)
        _part(parent, "NoticeLedgerStone", Vector3(-53.0, 1.44, 91.5),
            Vector3(2.5, 1.80, 0.26), Color(0.34, 0.45, 0.51))
    elif key == "east_professional":
        _tag(parent, "PROFESSIONAL PRECINCT / TRAM CONNECTION", Vector3(65.0, 5.2, 84.0), 29)
        _part(parent, "RaisedTramStationDeck", Vector3(72.0, 0.68, 76.0),
            Vector3(9.6, 0.24, 3.2), Color(0.58, 0.56, 0.53), true)
        _part(parent, "SolidTransitWaitingBench", Vector3(69.0, 1.12, 76.8),
            Vector3(2.2, 0.60, 0.62), Color(0.38, 0.29, 0.22), true)
        _part(parent, "StationEdgeSafetyRail", Vector3(72.0, 1.40, 77.70),
            Vector3(9.2, 0.92, 0.18), Color(0.38, 0.36, 0.34), true)
        _part(parent, "TramShelterRoof", Vector3(72.0, 3.0, 76.0),
            Vector3(9.1, 0.19, 3.2), Color(0.30, 0.38, 0.43))
        for post in [-4.0, 4.0]:
            _part(parent, "TramShelterPillar", Vector3(72.0 + post, 1.80, 76.0),
                Vector3(0.25, 2.75, 0.25), Color(0.46, 0.38, 0.24))
        _part(parent, "ServiceCourtyard", Vector3(70.5, 0.61, 97.0),
            Vector3(10.5, 0.15, 9.0), Color(0.42, 0.51, 0.57))
    _dress_ward(parent, key, street_x)
    # Visible distant urban silhouette; not fake traversable districts.
    for n in range(4):
        var sx: float = (-111.0 if west else 111.0) + (-float(n) if west else float(n)) * 4.5
        var sz: float = (34.0 if public else 77.0) + float(n) * 8.5
        var high: float = 13.0 + float(n % 3) * 5.0
        _part(parent, "UnbuiltCitySkyline", Vector3(sx, 0.5 + high * 0.5, sz),
            Vector3(5.8, high, 7.1), Color(0.28, 0.33, 0.39))


# V0.53 architecture and pedestrian continuity: these elements are genuine
# scene geometry instead of menu-only or image-only city dressing.
func _dress_ward(parent: Node3D, key: String, street_x: float) -> void:
    var west: bool = key.begins_with("west")
    var public_zone: bool = key.ends_with("public")
    var start_z: float = 30.4 if public_zone else 71.6
    var sandstone := Color(0.67, 0.65, 0.61)
    var bronze := Color(0.62, 0.44, 0.27)
    var stone := Color(0.48, 0.53, 0.57)
    var street_inner_x: float = street_x + (8.15 if west else -8.15)
    # Continuous pavement outside the vehicle street; a safe pedestrian strip
    # from the north edge through the entire ward.
    _part(parent, "ContinuousPedestrianPromenade",
        Vector3(street_inner_x, 0.58, start_z + 18.8),
        Vector3(2.65, 0.15, 37.6), sandstone, true)
    for n in range(7):
        var zz: float = start_z + 3.2 + float(n) * 5.4
        _part(parent, "BronzePavementInset", Vector3(street_inner_x, 0.675, zz),
            Vector3(2.5, 0.02, 0.12), bronze)
    # Stone-and-bronze public arcades: freestanding colonnades keep the roadway
    # open and never close the entrance of the six walk-in interiors.
    var arcade_x: float = -72.0 if west else 72.0
    var arcade_z: float = 31.5 if public_zone else 85.2
    for bay in range(4):
        var offset: float = float(bay) * 3.6
        _part(parent, "ArcadeColumnBase", Vector3(arcade_x, 0.82, arcade_z + offset),
            Vector3(0.78, 0.54, 0.78), sandstone, true)
        _part(parent, "ArcadeBronzeColumn", Vector3(arcade_x, 2.23, arcade_z + offset),
            Vector3(0.35, 2.32, 0.35), bronze, true)
        _part(parent, "ArcadeCapital", Vector3(arcade_x, 3.46, arcade_z + offset),
            Vector3(0.86, 0.20, 0.86), sandstone)
    _part(parent, "ArcadeContinuousCanopy",
        Vector3(arcade_x, 3.68, arcade_z + 5.4),
        Vector3(2.70, 0.26, 13.4), stone, true)
    _part(parent, "CanopyBronzeRidge",
        Vector3(arcade_x, 3.90, arcade_z + 5.4),
        Vector3(2.74, 0.12, 13.5), bronze)
    # Slender arches beside the sidewalks give the Janoan precinct a distinct
    # engineered silhouette while preserving at-grade traversal.
    for gate_index in range(2):
        var gate_z: float = start_z + 10.0 + float(gate_index) * 17.0
        var arch_x: float = street_x + (-6.7 if west else 6.7)
        for side in [-1.0, 1.0]:
            _part(parent, "PortalStonePier",
                Vector3(arch_x + side * 1.0, 1.86, gate_z),
                Vector3(0.44, 2.55, 0.50), sandstone, true)
        _part(parent, "PortalBronzeLintel",
            Vector3(arch_x, 3.23, gate_z),
            Vector3(2.65, 0.28, 0.66), bronze, true)
    if key == "west_public":
        # Public quay along the blue-resonance water channel. A physically
        # raised edge provides a reachable observation perch.
        _part(parent, "CanalQuayPaving", Vector3(-72.0, 0.60, 43.0),
            Vector3(44.0, 0.16, 2.15), sandstone, true)
        # Separate quay rail sections leave the two iron bridge approaches open.
        _part(parent, "QuayBronzeGuardMid", Vector3(-75.0, 1.10, 44.22),
            Vector3(15.0, 0.82, 0.16), bronze, true)
        _part(parent, "QuayBronzeGuardEast", Vector3(-53.5, 1.10, 44.22),
            Vector3(6.5, 0.82, 0.16), bronze, true)
        for bollard_x in [-94.0, -78.0, -70.0, -50.0]:
            _part(parent, "PublicQuayMooring",
                Vector3(float(bollard_x), 1.07, 42.5),
                Vector3(0.42, 0.96, 0.42), stone, true)
        _tag(parent, "CANAL QUAY / IRON BRIDGES",
            Vector3(-72.0, 4.28, 42.2), 27)
    elif key == "east_public":
        _part(parent, "CivicSquareStoneTiles",
            Vector3(70.5, 0.62, 60.7), Vector3(17.0, 0.13, 5.5),
            Color(0.74, 0.69, 0.60), true)
        for bench_x in [66.0, 75.0]:
            _part(parent, "PublicSquareBench", Vector3(float(bench_x), 0.94, 62.5),
                Vector3(3.0, 0.48, 0.68), Color(0.34, 0.28, 0.23), true)
        _tag(parent, "PUBLIC SQUARE / RESIDENTIAL SERVICES",
            Vector3(70.5, 4.35, 64.0), 25)
    elif key == "west_professional":
        _part(parent, "ProfessionalPavingCourt", Vector3(-72.0, 0.62, 103.6),
            Vector3(15.0, 0.12, 8.5), sandstone, true)
        for lx in [-75.0, -69.0]:
            _part(parent, "TrainingPillar", Vector3(float(lx), 1.75, 104.0),
                Vector3(0.46, 2.45, 0.46), stone, true)
        _tag(parent, "RECORDS / MEDICAL SERVICE COURT",
            Vector3(-72.0, 4.5, 107.0), 25)
    elif key == "east_professional":
        _part(parent, "TramWorkshopYard", Vector3(71.0, 0.66, 93.0),
            Vector3(15.0, 0.16, 9.0), sandstone, true)
        _part(parent, "WorkshopCargoPlatform", Vector3(74.0, 1.20, 94.3),
            Vector3(5.6, 1.00, 2.4), stone, true)
        for rail_idx in range(3):
            _part(parent, "StationCargoCrate",
                Vector3(72.0 + float(rail_idx) * 1.6, 1.90, 94.2),
                Vector3(1.10, 0.65, 1.05), bronze, true)
        _tag(parent, "TRAM SERVICE YARD / GAME-ONLY",
            Vector3(71.0, 4.7, 92.0), 25)

func _build_tram() -> void:
    tram = Node3D.new()
    tram.name = "MagnaraAmbientTramPrototype"
    add_child(tram)
    _part(tram, "BrassTramCarriage", Vector3(0.0, 1.52, 0.0),
        Vector3(5.8, 2.75, 2.4), Color(0.41, 0.39, 0.33))
    _part(tram, "TramRoof", Vector3(0.0, 3.00, 0.0),
        Vector3(6.1, 0.24, 2.6), Color(0.21, 0.31, 0.37))
    for side in [-1.0, 1.0]:
        for window in [-1.8, 0.0, 1.8]:
            _part(tram, "TramIlluminatedWindow", Vector3(window, 1.85, side * 1.24),
                Vector3(1.10, 0.86, 0.06), Color(0.37, 0.77, 0.80), false, false, true)
    _tag(tram, "MAGNARA / PUBLIC TRAM", Vector3(0.0, 3.65, 0.0), 24)
    tram.position = Vector3(-95.0, 0.0, 70.1)
