# Seeker's Codex — Margerina V0.37: First Visual Evolution

## What's new
- **Seeker silhouette:** an articulated, procedural low-poly player with head, clothing, arms, legs, boots, belt and Aura insignia.
- **Animation:** arms and legs move while walking/sprinting, a right-arm strike plays during Martial attacks, body leans during dodges, with breathing/idle motion.
- **Enemy models:** Iron Guard and Swift Shade now use matching humanoid fighter models with distinct outfits and simple guarded/windup/stagger poses. Enemy attack damage, guard and flanking logic are unchanged.
- **Magnara district dressing:** decorative Ring Two canal, two small bridges, residence facades, windows and lanterns along the outer edge of the hub.

## Kept intact
- Same Godot 4.4.1 project, scene and touchscreen UI for itch.io iPhone play.
- V0.36 combat AI, Aura/HP, controls, three existing contracts, Hanami, inventory, Tola, XP, and V0.33 browser-local saves.
- `main` retains the earlier original browser game; workflow commits only to `codex-modular-v31` and only *after* Godot import/startup/export pass.

## Limits
- The characters are intentionally **procedural prototype models**, not bespoke animated/rigged GLB assets or final designs for Kai and others.
- Bridges, canals and facade buildings are decorative only, with no swimming, interiors, schedules or collision. No invented lore is canonized.

## iPhone checklist
1. Launch the game, rotate the camera and observe the Seeker's new head, coat, hands and boots.
2. Walk, run, strike and dodge; character limbs should respond.
3. Go to the sparring yard; the two enemies should be humanoid and behave like V0.36.
4. Check the canals/residence details off the main path.
5. Confirm Hanami, contract completion, save/load and touch buttons still work.
