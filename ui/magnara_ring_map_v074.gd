extends Control
# Drawn only when player explicitly opens the V0.74 city map.
# 26km planning-scale chart, true relative ring radii, player position.
# This is a city layout reference, not a revealed story map or exact coast.
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const Rules = preload("res://systems/magnara_seven_ring_rules_v074.gd")
const StreetsV075 = preload("res://systems/magnara_streetscape_rules_v075.gd")
var player: Node3D

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
    if visible:
        queue_redraw()

func _draw() -> void:
    var dimensions: Vector2 = size
    if dimensions.x < 80.0 or dimensions.y < 80.0:
        return
    var center: Vector2 = dimensions*0.5
    var chart_radius: float = minf(dimensions.x,dimensions.y)*0.46
    draw_circle(center,chart_radius,Color(0.14,0.20,0.24,0.45))
    for n in range(Rules.RADIAL_COUNT):
        var angle: float = Rules.radial_angle(n)
        var line_end: Vector2 = center+Vector2(cos(angle),sin(angle))*chart_radius
        draw_line(center,line_end,Color(0.43,0.48,0.52,0.24),1.5,true)
    for ring in range(7,0,-1):
        var bound: float = Geo.OUTER_BOUNDS_M[ring-1]
        var radius: float = chart_radius*bound/Rules.CITY_RADIUS_M
        draw_arc(center,radius,0,TAU,160,
            Rules.RING_COLORS[ring-1].lightened(0.32),3.3,true)
    # 84 ring/avenue survey intersections are shown as light dots.
    # These are road geometry, not named canon properties or docks.
    for ring in range(1,8):
        for avenue in range(Rules.RADIAL_COUNT):
            var intersection: Dictionary = StreetsV075.junction(ring,avenue)
            var world: Vector3 = intersection["world_pos"]
            var plan: Vector2 = Vector2(world.x-Geo.CITY_CENTER.x,
                world.z-Geo.CITY_CENTER.y)
            draw_circle(center+plan/Rules.CITY_RADIUS_M*chart_radius,
                2.4,Color(0.80,0.84,0.81,0.87))
    if not is_instance_valid(player):
        return
    var pos: Vector3 = player.global_position
    var dot := Vector2(pos.x-Geo.CITY_CENTER.x,pos.z-Geo.CITY_CENTER.y)
    var shifted: Vector2 = center+dot/Rules.CITY_RADIUS_M*chart_radius
    if dot.length() <= Rules.CITY_RADIUS_M:
        draw_circle(shifted,6.5,Color(0.99,0.81,0.42))
        draw_arc(shifted,9.0,0,TAU,24,Color(0.13,0.13,0.16),2.0,true)
    draw_circle(center,4.5,Color(0.91,0.90,0.85))
