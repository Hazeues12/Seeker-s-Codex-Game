# Seeker's Codex: World of Margerina — V0.34 Martial Prototype

This milestone builds directly on the working V0.33 Seeker Quarters hub. The original HTML game on `main` is untouched.

## Mobile controls
- Left joystick: move; swipe on the right (away from buttons): look.
- RUN: toggle sprint. JUMP: jump. TALK / USE: interact.
- **STRIKE:** basic Martial Muti aura pulse. Costs 12 Aura and 4 Stamina; 0.40s cooldown.
- **DODGE:** short ground-level dash in the movement direction (or camera-forward). Costs 18 Stamina; 0.95s cooldown. Prototype dodge does not grant invulnerability.
- On desktop: `F` to strike and `Q` to dodge.

## Mini-game loop
- Accept **Aura Technique Drills** at the guild board.
- Approach the wooden training post and use STRIKE three times. The original TALK / USE training option still works.
- Return to the board and claim your reward; other V0.33 contracts, Hanami's shop, inventory and browser-local save stay intact.

## Scope and caveats
- No enemy AI or combat damage yet. STRIKE makes a lightweight temporary pulse for visual feedback.
- The existing joystick/swipe input logic is deliberately preserved to avoid regressing the iPhone controls already tested on itch.io.
- Saves continue using the V0.33 browser-local format; site-data clearing can delete progress.
- This is gameplay scaffolding, not new story canon or an official Seeker rank-examination rule.
