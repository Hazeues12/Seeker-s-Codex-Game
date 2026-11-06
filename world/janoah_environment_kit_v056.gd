extends RefCounted
# V0.56 reusable stage palette for locally authored Janoah terrain.
# NOT a generic culture reskin system. Other nations require separate asset kits.
const STAGES: Array[String] = [
    "industrial_outskirts", "farmed_countryside", "rolling_interior_route"
]

static func valid_stage(stage: String) -> bool:
    return STAGES.has(stage)

static func ground_color(stage: String) -> Color:
    match stage:
        "industrial_outskirts":
            return Color(0.46, 0.47, 0.41)
        "farmed_countryside":
            return Color(0.42, 0.52, 0.35)
        "rolling_interior_route":
            return Color(0.40, 0.47, 0.39)
        _:
            return Color(0.47, 0.49, 0.46)

static func gravel_color(stage: String) -> Color:
    if stage == "industrial_outskirts":
        return Color(0.45, 0.43, 0.40)
    if stage == "farmed_countryside":
        return Color(0.60, 0.54, 0.43)
    return Color(0.48, 0.51, 0.49)

static func vegetation_color(stage: String) -> Color:
    if stage == "industrial_outskirts":
        return Color(0.31, 0.40, 0.34)
    if stage == "farmed_countryside":
        return Color(0.27, 0.44, 0.28)
    return Color(0.25, 0.40, 0.29)

static func stage_motif(stage: String) -> String:
    match stage:
        "industrial_outskirts": return "working freight yards and retaining works"
        "farmed_countryside": return "orchards, cultivation and rural verges"
        "rolling_interior_route": return "low ridge contours and roadside stones"
    return "unspecified local terrain"

static func culture_scope() -> String:
    return "Janoah / industrial republic / provisional regional materials only"
