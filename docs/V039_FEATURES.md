# Seeker's Codex: World of Margerina — V0.39 Traversal and Multitouch

## Core rule: actions must compose
- iPhone movement, camera, RUN, JUMP, STRIKE, DODGE, GUARD, TALK/USE and HUD menus must not share a single-pointer lock. A separate touch ID tracks joystick and camera; additional fingers can tap on-screen buttons.
- **RUN + JUMP works without releasing RUN or the joystick.** RUN remains a toggle. The second airborne JUMP becomes a double jump.
- Desktop retains mouse and keyboard; `SPACE`/Enter jump, Shift run, F strike, Q dodge. Touch input stays native on iPhone browsers with primary-finger mouse emulation retained for menus.
- Game-rule restrictions (Aura/stamina costs, attack cooldowns, guard slowdown, KO) still apply, but they do not interfere with the input routing.

## Parkour prototype
- Double jump: one jump from the ground plus one in the air. Landing on a roof resets both jumps.
- Wall run: RUN with directional movement while airborne within arm's reach of a marked traversal wall; gravity is reduced for a brief limited duration. Tap JUMP from the wall to kick off.
- Water run: RUN while moving over the shallow blue Aura Water Lane for a speed boost. The lane uses an underlying safe solid ground plane as a prototype; it is not full ocean physics or buoyancy yet.
- Three **physically collidable rooftop terraces** and two wall-run surfaces are installed north of the Market Walk in Ring Two. The original houses, NPCs, board, inventory, and combat area are unchanged.
- Wall-running and water-running are not canonical techniques by themselves. This is a traversal mechanic prototype awaiting lore-specific naming/balancing.

## Protecting earlier milestones
- V0.38 character editor, combat, GUARD, quest board, Hanami, Tola, inventory, V0.33 main save, and appearance save remain. Original browser game on `main` is not changed.
- Don't upload to itch.io until the GitHub Action passes the Godot 120-frame startup and export tests. Test simultaneous left-thumb joystick + right-thumb jump, camera + joystick, jump during sprint, double jump, wall-running, water-running and rooftop landings.
