extends RefCounted
# V0.68: deterministic game-only rooftop parkour for the already-streamed
# Magnara Ring Two building kit. All heights and coordinates are scenic,
# not an assertion about published Magnara buildings or Seeker ability tiers.
const District = preload("res://systems/magnara_stream_rules_v067.gd")
const STEP_RISE_MAX: float = 1.45
const STEP_GAP_MAX: float = 4.4
const DECK_THICKNESS: float = 0.22
const ACCESS_PER_CHUNK: int = 2
const MAX_PARKOUR_PIECES_PER_CHUNK: int = 92

static func roof_y(cell: Vector2i, slot: int) -> float:
    var parcel: Dictionary = District.parcel(cell, slot)
    if parcel.is_empty():
        return -100.0
    return 0.56 + float(parcel["height"]) + 0.365

static func roof_deck(cell: Vector2i, slot: int) -> Dictionary:
    var parcel: Dictionary = District.parcel(cell, slot)
    if parcel.is_empty():
        return {}
    return {"id": "roof:%s:%d" % [District.key(cell), slot],
        "local_position": (parcel["center"] as Vector3) + Vector3(0, roof_y(cell, slot) - DECK_THICKNESS * 0.5, 0),
        "size": Vector3(float(parcel["width"]) + 0.7, DECK_THICKNESS,
            float(parcel["depth"]) + 0.7),
        "top_y": roof_y(cell, slot), "kind": "roof", "canon_status": "game_only"}

static func entry_stairs(cell: Vector2i, side: int) -> Array[Dictionary]:
    var stairs: Array[Dictionary] = []
    if not District.allowed(cell) or side < 0 or side > 1:
        return stairs
    var first: Dictionary = District.parcel(cell, side)
    var roof_height: float = roof_y(cell, side)
    var start: float = 0.80
    var final_top: float = roof_height - 0.95
    var stages: int = maxi(4, ceili((final_top - start) / STEP_RISE_MAX))
    var building_x: float = absf((first["center"] as Vector3).x)
    var facade: float = building_x - float(first["width"]) * 0.5
    var side_sign: float = -1.0 if side == 0 else 1.0
    for n in range(stages):
        var t: float = float(n + 1) / float(stages)
        var above: float = lerpf(start, final_top, t)
        var x: float = side_sign * lerpf(12.3, facade - 2.3, t)
        stairs.append({
            "id": "stair:%s:%d:%d" % [District.key(cell), side, n],
            "local_position": Vector3(x, above - DECK_THICKNESS * 0.5,
                float((first["center"] as Vector3).z)),
            "size": Vector3(3.1, DECK_THICKNESS, 3.0),
            "top_y": above, "kind": "stair", "canon_status": "game_only"
        })
    return stairs

static func _between(cell: Vector2i, side: int, from_row: int, across_tile: bool) -> Array[Dictionary]:
    var steps: Array[Dictionary] = []
    if not District.allowed(cell) or side < 0 or side > 1:
        return steps
    var a_index: int = side + from_row * 2
    var current: Dictionary = District.parcel(cell, a_index)
    if current.is_empty():
        return steps
    var neighbor: Vector2i = cell + Vector2i(0, 1) if across_tile else cell
    var b_index: int = side if across_tile else side + (from_row + 1) * 2
    var next: Dictionary = District.parcel(neighbor, b_index)
    if next.is_empty():
        return steps
    var a_y: float = roof_y(cell, a_index)
    var b_y: float = roof_y(neighbor, b_index)
    var a_z: float = float((current["center"] as Vector3).z) + float(current["depth"]) * 0.5 - 1.2
    var b_z: float = float((next["center"] as Vector3).z) - float(next["depth"]) * 0.5 + 1.2
    if across_tile:
        b_z += District.TILE_M
    var separation: float = b_z - a_z
    var count: int = maxi(4, maxi(ceili(separation / STEP_GAP_MAX), ceili(absf(a_y - b_y) / STEP_RISE_MAX)))
    # Position planks between two reachable roof edges. End-to-end hops are
    # visible, physics-backed and short enough for the existing double jump.
    for n in range(count):
        var t: float = float(n + 1) / float(count + 1)
        var height: float = lerpf(a_y - 0.22, b_y - 0.22, t)
        steps.append({
            "id": "link:%s:%d:%d:%d" % [District.key(cell), side, from_row, n],
            "local_position": Vector3(float((current["center"] as Vector3).x),
                height - DECK_THICKNESS * 0.5, lerpf(a_z, b_z, t)),
            "size": Vector3(3.6, DECK_THICKNESS, 3.0),
            "top_y": height, "kind": "bridge", "canon_status": "game_only"
        })
    return steps

static func roof_routes(cell: Vector2i) -> Array[Dictionary]:
    var parts: Array[Dictionary] = []
    if not District.allowed(cell):
        return parts
    for slot in range(District.PARCELS_PER_CHUNK):
        parts.append(roof_deck(cell, slot))
    for side in range(ACCESS_PER_CHUNK):
        parts.append_array(entry_stairs(cell, side))
        for row in range(2):
            parts.append_array(_between(cell, side, row, false))
        if cell.y < District.MAX_ROW:
            parts.append_array(_between(cell, side, 2, true))
    return parts

static func height_differences_safe(cell: Vector2i) -> bool:
    # Verifies each staircase and each bridge goes from one solid anchor to
    # another without a step exceeding ordinary prototype jump capabilities.
    if not District.allowed(cell):
        return false
    for side in range(ACCESS_PER_CHUNK):
        var steps: Array[Dictionary] = entry_stairs(cell, side)
        if steps.is_empty():
            return false
        var previous_y: float = 0.80
        var previous_x: float = -12.3 if side == 0 else 12.3
        for entry in steps:
            var platform_pos: Vector3 = entry["local_position"]
            var next_y: float = float(entry["top_y"])
            if next_y - previous_y > STEP_RISE_MAX + 0.01 or absf(platform_pos.x - previous_x) > 4.0:
                return false
            previous_y = next_y
            previous_x = platform_pos.x
        if roof_y(cell, side) - previous_y > STEP_RISE_MAX:
            return false
        for row in range(2):
            var last: float = roof_y(cell, side + row * 2)
            for entry in _between(cell, side, row, false):
                if absf(float(entry["top_y"]) - last) > STEP_RISE_MAX + 0.02:
                    return false
                last = float(entry["top_y"])
            if absf(roof_y(cell, side + (row + 1) * 2) - last) > STEP_RISE_MAX + 0.25:
                return false
    return true

static func jump_hint(cell: Vector2i, side: int) -> String:
    if not District.allowed(cell):
        return "No authored route here."
    return "Run + Jump to climb the visible roof steps. Double-jump across the maintenance decks; keep momentum."
