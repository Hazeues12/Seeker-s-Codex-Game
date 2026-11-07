extends RefCounted
# November 7, 2026 direct author correction.
# Magnara main ocean port = outermost Ring VII. Ring II may have ONLY
# small, shallow-draft local canal piers; its warehouse is a land depot.
# Exact coastline, canal reachability and ferry paths are still UNMAPPED.
const RINGS: int = 7
const MAJOR_SEAPORT_RING: int = 7
const RING_TWO: int = 2
const MAIN_PORT_ID: String = "iron_cothon"
const STATUS: String = "creator_confirmed_ring_location_coordinates_unfinalized"
const CANAL_VESSEL: String = "shallow_draft_local"

static func can_berth(ring: int, waterway: String, craft: String) -> bool:
    if ring == MAJOR_SEAPORT_RING and waterway == "major_seaport":
        return craft in ["small","medium","large"]
    if ring == RING_TWO and waterway == "minor_canal_quay":
        return craft == CANAL_VESSEL
    return false

static func is_inland_freight(ring: int, role: String) -> bool:
    return ring == RING_TWO and role == "road_wagon_depot"

static func allowed_inter_ring_leg(origin: int,destination: int,
        route_status: String) -> bool:
    # There is no authored physical Ring II ↔ VII road/canal path yet.
    # The existing Ring II counter is a scenic preview, not transport.
    if origin == RING_TWO and destination == MAJOR_SEAPORT_RING:
        return route_status == "author_mapped_and_physically_verified"
    return false

static func validate_atlas(atlas: Dictionary, water: Dictionary) -> bool:
    if atlas.get("city","") != "Magnara" or int(atlas.get("ring_count",0)) != RINGS:
        return false
    var policy: Dictionary = atlas.get("port_geography",{})
    if int(policy.get("main_seaport_ring",-1)) != MAJOR_SEAPORT_RING \
            or int(policy.get("outermost_ring",-1)) != MAJOR_SEAPORT_RING \
            or str(policy.get("primary_harbor","")) != "Iron Cothon":
        return false
    var ring_seven: Dictionary = {}
    var ring_two: Dictionary = {}
    for item in atlas.get("rings",[]):
        if int(item.get("ring",-1)) == MAJOR_SEAPORT_RING:
            ring_seven = item
        elif int(item.get("ring",-1)) == RING_TWO:
            ring_two = item
    if ring_seven.is_empty() or ring_two.is_empty():
        return false
    if not str(ring_seven.get("canonical_features",[])).contains("port") \
            or not str(ring_two.get("canonical_features",[])).contains("canal"):
        return false
    var harbors: Array = water.get("harbors",[])
    if harbors.size() < 2:
        return false
    var found: bool = false
    var survey: bool = false
    for entry in harbors:
        if entry.get("id","") == MAIN_PORT_ID:
            found = int(entry.get("ring",-1)) == MAJOR_SEAPORT_RING \
                and not bool(entry.get("inland_ring_two_maritime_access",true))
        if entry.get("id","") == "iron_cothon_civil_survey_v071":
            survey = int(entry.get("represents_actual_ring",-1)) == MAJOR_SEAPORT_RING \
                and int(entry.get("entry_counter_ring",-1)) == RING_TWO \
                and not bool(entry.get("real_inter_ring_transport",true))
    var local: Dictionary = water.get("local_canals",{})
    return found and survey and int(local.get("ring",-1)) == RING_TWO \
        and not bool(local.get("ocean_vessels_allowed",true)) \
        and not bool(local.get("large_commercial_seaport",true))

static func source_status() -> Dictionary:
    return {"magnara_outermost_ring":MAJOR_SEAPORT_RING,
        "ocean_going_main_docks_ring":MAJOR_SEAPORT_RING,
        "ring_two_minor_canal_quays":true,
        "ring_two_inland_wagon_depot":true,
        "main_port_location":STATUS,
        "ring_two_seaport":false,
        "ring_two_to_outer_port_navigable_canal_mapped":false,
        "survey_counter_is_not_travel":true}
