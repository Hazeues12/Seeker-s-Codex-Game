# Seeker's Codex: World of Margerina — V0.38 Seeker Identity

A cautious extension of the successful V0.37 browser build. This is playable prototype content rather than new story canon.

## Look editor (new)
- Tap **LOOK** at the top of the screen while outside the combat yard.
- Choose a Seeker name, four skin tones, four hairstyles, four coat palettes, and four Aura accent colors.
- The low-poly humanoid changes immediately in the world. Tap **SAVE LOOK** to persist choices on the same browser/site.
- Appearance is stored as `user://margerina_appearance_v038.json` separately from the V0.33 contract/inventory save. No quest, rank or Tola progress is overwritten.
- This is a prototype appearance editor. Face sliders, nation origins, Seven Spokes, class decisions, and full rigged animations come later.

## Defensive combat (new)
- Tap **GUARD OFF** to toggle defensive stance to **GUARD ON**, tap again to lower.
- A successful block consumes 15 Stamina and reduces incoming HP damage to about 30% of the attack.
- Striking disables guard briefly, dashing prevents it while active, and guarding slows normal movement. Stamina exhaustion breaks individual blocks.
- The old STRIKE/DODGE/JUMP/RUN controls, Arena enemy behaviors, quests and saves remain.

## Market Walk and conversations (new)
- A decorative Market Walk east of the central path (towards x=12, z=15) with four shaded stalls.
- Three roaming, non-colliding prototype NPCs: Canal Guide, Market Seller, Seeker Scout. Approach and tap **TALK / USE** for dialogue.
- Guide and seller have simple daytime availability based on the world clock; the scout stays on patrol.
- Existing decorative canal, quest board, Hanami, training yard, saved locations and contract loop remain.

## Limitations and test checklist
- Visual primitive buildings and NPCs have no building interiors, quests, crafting or advanced pathfinding yet.
- Test LOOK preview + SAVE LOOK + reload, GUARD vs both enemies, iPhone joystick/camera, old contract board, Hanami and existing SAVE/LOAD.
- Browser save data can be lost when site data is cleared. Keep V0.37 ZIP until V0.38 is tested on itch.io.
- `main` must remain untouched; changes are only on `codex-modular-v31` after passing Godot validation.
