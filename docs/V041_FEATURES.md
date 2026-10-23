# Seeker's Codex: Margerina V0.41 — Living Seeker Quarters

**Scope:** An interactive, source-conscious expansion of the V0.40 Ring Two city bands. Character roles, conversations, orientation visits and geographic bearings are prototype *game_only* content, not additions to published canon.

## Published canon honored
- Public/civic Ring Two includes residents, noodles, working canals, shops and ordinary lives alongside Seekers.
- Professional Ring Two contains registration/certification, medical instruction, coordinated Silver-team combat training, Aura exhaustion training and Soulwright Division personnel.
- Secured precinct remains behind a guarded approach with the Seeker Citadel and its thirteen towers; no accessible guessed offices/interiors.
- Rin Kairo's mysterious box position from Chapter 90 is **not revealed**.

## Gameplay
- Seven interactable low-poly role NPCs, each with proximity talk and simple time-of-day shifts. Existing **TALK / USE** works without adding another touch action.
- Public quarter: noodle vendor and canal resident.
- Professional precinct: registration clerk, medical instructor, Silver-team trainer, Soulwright field officer, and Citadel sentry.
- Open-air workstations and a simulated coordinated three-Seeker practice squad versus a non-hostile Spirit training construct.
- One five-visit **visitor orientation** that progresses via dialogue. It does not grant rank, Tola, abilities, or official certifications.
- The **RING TWO** HUD button opens a journal for role directions, visit status, and lore status. A separate `user://margerina_ringtwo_orientation_v041.json` stores visit progress; existing inventory, quests, HP, and appearance save systems are untouched.
- Proximity hides remote role NPCs and Silver practice figures to reduce iPhone WebGL overhead.

## Controls preserved
- iOS multitouch joystick, camera drag, RUN + JUMP, double jump, wall-running, water running, STRIKE, DODGE, GUARD and LOOK are unchanged.
- `codex-modular-v31` development branch only. Original browser game on `main` remains intact.

## Playtest
1. On iPhone, verify joystick held + RUN toggled + JUMP + camera still work.
2. Travel along the extended +Z boulevard to z~52: talk to public-quarter vendor and resident.
3. Go to z~77: TALK / USE with registrar, then follow journal checkpoints at z~80/87/98/111.
4. Watch Silver team practice and inspect medical and Soulwright stations.
5. Test journal open/close, save/reload visitor orientation, return to old Hanami/contract hub, then SAVE/LOAD original progression.
6. Confirm the Citadel approach remains restricted; do not treat game placeholder coordinates as canon.

**Limitations:** Workstations are outside fully solid V0.40 exteriors. No interior loading, AI dialogue models, official promotions, or full NPC navigation yet. Godot headless startup confirms parse/runtime loading but does not replace Safari gameplay testing.
