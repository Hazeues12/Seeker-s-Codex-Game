extends Node3D
# V0.69 actual parkour approaches to V0.65/V0.66 authored venues.
# Public rooftops are collidable already; bridges/steps are game-only
# maintenance scaffolds. Their positions are NOT established story canon.
const HOMES: Array[Dictionary] = [
    {"id":"talking_boar","x":-30.0,"z":555.0,"half":12.0,"front":1.0,"top":5.78},
    {"id":"lebells","x":-94.0,"z":620.0,"half":9.3,"front":1.0,"top":5.73},
    {"id":"avicci","x":94.0,"z":650.0,"half":9.3,"front":-1.0,"top":5.73},
    {"id":"vernal_divongcci","x":-94.0,"z":686.0,"half":9.3,"front":1.0,"top":5.73}
]
var built: bool = false
var platforms: Array[StaticBody3D] = []

func _ready() -> void:
    add_to_group("v069_legacy_rooftops")
    call_deferred("_build")

func _material(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
    m.roughness = 0.86
    return m

func _plank(title: String, at: Vector3, size: Vector3, shade: Color) -> StaticBody3D:
    var solid := StaticBody3D.new()
    solid.name = title
    solid.position = at
    solid.add_to_group("v069_public_roof_parkour")
    add_child(solid)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.material_override = _material(shade)
    mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    solid.add_child(mesh)
    var collider := CollisionShape3D.new()
    collider.name = "V069LegacyRoofCollision"
    var shape := BoxShape3D.new()
    shape.size = size
    collider.shape = shape
    solid.add_child(collider)
    platforms.append(solid)
    return solid

func _label(text: String, position: Vector3) -> void:
    var sign := Label3D.new()
    sign.name = "V069RoofwayMarker"
    sign.text = text
    sign.position = position
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sign.no_depth_test = true
    sign.pixel_size = 0.0045
    sign.font_size = 23
    add_child(sign)

func _build() -> void:
    for data in HOMES:
        var facade: float = float(data["x"]) + float(data["front"]) * float(data["half"])
        var entry_x: float = facade + float(data["front"]) * 11.8
        var roof_x: float = facade + float(data["front"]) * 0.5
        var offset_z: float = float(data["z"]) + 7.0
        var previous: float = 0.83
        for n in range(8):
            var ratio: float = float(n + 1) / 8.0
            var top: float = lerpf(0.83,float(data["top"])-0.43,ratio)
            var x: float = lerpf(entry_x,roof_x,ratio)
            var plank: StaticBody3D = _plank("V069Access_%s_%d" % [str(data["id"]),n],
                Vector3(x,top-0.13,offset_z),Vector3(3.5,0.26,3.0),
                Color(0.61,0.55,0.42) if n % 2 == 0 else Color(0.39,0.53,0.58))
            plank.set_meta("rise_from_previous",top-previous)
            previous = top
        _label("ROOF ACCESS / RUN + JUMP / %s" % str(data["id"]).replace("_"," ").to_upper(),
            Vector3(entry_x,3.0,offset_z))
    # Same-side elevated maintenance walk between two shop roofs.
    # The other long east/west city crossing is not pretended to be jumpable.
    for n in range(16):
        var fraction: float = float(n+1) / 17.0
        var along_z: float = lerpf(631.0,675.0,fraction)
        _plank("V069PublicRoofCatwalk_%02d" % n,
            Vector3(-94.0,5.66,along_z),Vector3(3.8,0.25,3.2),
            Color(0.36,0.52,0.62))
    built = true

func get_manifest() -> Dictionary:
    return {"version":69,"legacy_venues_with_roof_access":HOMES.size(),
        "access_stairs_per_venue":8,"shop_roof_catwalk_planks":16,
        "real_colliders":platforms.size(),"built":built,
        "published_roof_coordinates":false,"canon_status":"game_only_access_scaffolds"}
