extends Node3D
const Main = preload("res://scenes/main.tscn")
const Geo = preload("res://systems/known_world_geometry_v054.gd")
const City = preload("res://systems/magnara_seven_ring_rules_v074.gd")
const Art = preload("res://systems/magnara_published_city_visual_rules_v076.gd")
const Integrity = preload("res://systems/game_save_integrity_v063.gd")

func _ready() -> void:
    call_deferred("_run")

func _fail(why: String) -> void:
    push_error("V0.76 LIVE PUBLISHED CANON MAGNARA CITY FAILED: "+why)
    get_tree().call_deferred("quit",1)

func _run() -> void:
    var game: Node3D = Main.instantiate() as Node3D
    add_child(game)
    for n in range(8):
        await get_tree().process_frame
    var player: CharacterBody3D = game.get_node_or_null("Player") as CharacterBody3D
    var hub: Node = game.get_node_or_null("HubManager")
    var geometry: Node = game.get_node_or_null("MagnaraGeographyV054")
    var city: Node = game.get_node_or_null("MagnaraSevenRingFoundationV074")
    var streets: Node = game.get_node_or_null("MagnaraStreetscapeV075")
    var visuals: Node = game.get_node_or_null("MagnaraPublishedRingVisualsV076")
    if player == null or hub == null or geometry == null or city == null \
            or streets == null or visuals == null:
        _fail("new published city visual style did not mount in original Godot city")
        return
    for old in ["MagnaraRingTwo","MagnaraCityV052","MagnaraStreamedBlocksV067",
        "MagnaraExpandedWardsV071","MagnaraWardInteriorsV072",
        "MargerinaOceanCommerceV071","MagnaraLocalLogisticsV073",
        "MagnaraLegacyRoofwaysV069","PublicGuildDirectorV069"]:
        if game.get_node_or_null(old) == null:
            _fail("lost original Seeker Quarter, harbor physics or public services: "+old)
            return
    if not bool(visuals.get("initialized")) or not bool(city.get("initialized")):
        _fail("published source guard prevented verified safe city architecture boot")
        return
    var roles: Dictionary = {}
    for ring in [3,4,5,7]:
        var radius: float = {3:3560.0,4:5540.0,5:7620.0,7:11830.0}[ring]
        var at := Vector3(Geo.CITY_CENTER.x+radius,1.2,Geo.CITY_CENTER.y)
        player.global_position = at
        player.velocity = Vector3.ZERO
        for n in range(5):
            geometry.call("_refresh_cells")
            city.call("_refresh_near")
        city.call("_refresh_skyline",true)
        city.call("_status")
        streets.call("_refresh_tiles")
        visuals.call("_refresh_tiles")
        await get_tree().physics_frame
        var manifest: Dictionary = visuals.call("get_manifest")
        var base: Dictionary = city.call("get_manifest")
        var ring_report: Dictionary = base
        if int(base.get("current_ring",0)) != ring:
            city.call("_status")
            ring_report=city.call("get_manifest")
        if int(ring_report.get("current_ring",0)) != ring:
            _fail("player's in-world location doesn't match published zone index")
            return
        if int(manifest.get("render_tiles",0)) > Art.MAX_ACTIVE_ART_TILES \
                or int(manifest.get("all_gpu_instances",0)) > 9*Art.MAX_ART_PER_TILE:
            _fail("published architecture breaks the iPhone streaming budget")
            return
        if manifest.get("new_named_canon_buildings",1)!=0 \
                or not manifest.get("actual_source_audited",false) \
                or manifest.get("real_ring_vii_coastline_placed",true):
            _fail("generated buildings claimed author-approved addresses or seawall")
            return
        var index: String = {3:"commons_park_patches",
            4:"academy_glass_domes",5:"market_public_awnings",
            7:"ring_vii_industrial_gantries"}[ring]
        if int(manifest.get(index,0)) <= 0:
            _fail("Ring %d has no newly visible published-region architectural forms" % ring)
            return
        var parent_tiles: Dictionary = city.get("near_tiles")
        var decorated: Dictionary = visuals.get("decorated")
        var matching: bool = false
        for key in decorated.keys():
            if not parent_tiles.has(key):
                _fail("authored style node leaked beyond original nine city chunks")
                return
            var parent: Node3D = parent_tiles[key]["node"]
            var layer: Node3D = decorated[key]["root"]
            if not is_instance_valid(layer) or layer.get_parent() != parent:
                _fail("GPU visual art is orphaned outside the underlying real city parcel")
                return
            var art: Dictionary = Art.tile_art(decorated[key]["tile"])
            var status: Dictionary = art["stats"]
            if ring==3 and int(status["commons_lawns"])>0:
                matching = is_instance_valid(layer.get_node_or_null("V076CommonsParkGroundGPU"))
            elif ring==4 and int(status["academy_glass"])>0:
                matching = is_instance_valid(layer.get_node_or_null("V076AcademyGlassAndCommonsTreesGPU"))
            elif ring==5 and int(status["market_awnings"])>0:
                matching = is_instance_valid(layer.get_node_or_null("V076GenericFacadeAndIndustrialSilhouettesGPU"))
            elif ring==7 and int(status["outer_ring_gantries"])>0:
                matching = is_instance_valid(layer.get_node_or_null("V076GenericFacadeAndIndustrialSilhouettesGPU"))
            if matching:
                break
        if not matching:
            _fail("GPU decoration statistics were true but no corresponding real mesh was drawn")
            return
        if int(ring_report.get("far_skyline_gpu_buildings",0)) < 100:
            _fail("new style removed the long-range 2km metropolitan skyline")
            return
        if ring == 3 and int(manifest.get("commons_courts", 0)) < 1:
            _fail("Ring III has no streamed public courtyards")
            return
        if ring == 3:
            var lantern_position := Vector3.ZERO
            for entry in decorated.values():
                if not entry["lanterns"].is_empty():
                    lantern_position = entry["root"].to_global(entry["lanterns"][0]["at"])
                    break
            if lantern_position == Vector3.ZERO:
                _fail("Commons courtyards have no streamed lanterns")
                return
            player.global_position = lantern_position - Vector3.UP * 2.0
            var lights: Array = visuals.get("commons_lights")
            hub.set("world_minutes", 720.0)
            visuals.call("_refresh_commons_lights")
            if lights.any(func(light: OmniLight3D) -> bool: return light.visible):
                _fail("Commons lamps cast light during the day")
                return
            hub.set("world_minutes", 1470.0)
            visuals.call("_refresh_commons_lights")
            if lights.size() != 4 or not lights[0].visible \
                    or not lights[0].global_position.is_equal_approx(lantern_position):
                _fail("night lighting did not pick the closest streamed lamp")
                return
            player.global_position = Vector3.ZERO
            visuals.call("_refresh_commons_lights")
            if lights.any(func(light: OmniLight3D) -> bool: return light.visible):
                _fail("Commons lights stayed active outside their range")
                return
        roles[ring]=int(manifest[index])

    # The original developed public Ring II remains precisely where it
    # already was. All 30 workrooms, market freight and the skiff survive.
    player.global_position = Vector3(0,1.0,70)
    for n in range(5):
        geometry.call("_refresh_cells")
        city.call("_refresh_near")
    streets.call("_refresh_tiles")
    visuals.call("_refresh_tiles")
    var original_cell: String = Geo.cell_id(Geo.tile_index(player.global_position))
    var original_decorations: Dictionary = visuals.get("decorated")
    if original_decorations.has(original_cell):
        _fail("published architecture painted over real Seeker Quarter interior/street tile")
        return
    city.call("_status")
    if int(city.call("get_manifest")["current_ring"]) != 2:
        _fail("retained original Seeker Quarter incorrectly moved outside Ring II")
        return
    if roles.size()!=4 or visuals.get_manifest().get("unverified_red_order_territory_events",true):
        _fail("specific verified ring architecture was replaced by fabricated faction activity")
        return
    if not bool(hub.call("_save_game")):
        _fail("existing 3D Seeker saving broken by render-only region work")
        return
    var backed: Dictionary = Integrity.load_best().get("data",{})
    if backed.get("position",[]).size()!=3:
        _fail("save data was overwritten by new ring art or unpublished currency ledger")
        return
    print("V0.76 LIVE PUBLISHED COMMONS GREEN ACADEMIES GLASS MARKETS AWNINGS OUTER PORT SKYLINE ALL ON SEVEN RING GODOT WORLD WITH OLD SAVES PASS")
    game.queue_free()
    get_tree().call_deferred("quit",0)
