# Seeker's Codex — Margerina V0.35: First Real Combat

V0.35 adds a contained combat sandbox behind the practice post, without replacing the working V0.34 mobile controls, guild contracts, inventory, Tola, XP, or browser-local V0.33 save format.

## How to play on iPhone
- Walk north along the main path, past the wooden Aura training post, to the **MARTIAL SPARRING YARD** sign.
- Approach one of the two purple practice constructs. They patrol, pursue from nearby, flash gold while winding up, hit at close range, and stagger when struck.
- Use **STRIKE** while facing an enemy within approximately 3 meters. Successful consecutive hits can chain a three-step Martial combo (18, 24, 30 damage), using the original 12 Aura + 4 Stamina per strike and 0.40-second cooldown.
- Use **DODGE** to dash away or evade a telegraphed strike; the existing 18 Stamina cost and 0.95-second cooldown remain.
- The new health bar shows up to 100 HP; each enemy hit deals 12 damage. A short damage grace window prevents rapid repeated hits.
- On knockout the player respawns at the entry with full health. There is no Tola or contract penalty.
- Constructs respawn six seconds after defeat, allowing repeatable sparring.

## Safe installation and limitations
- The workflow validates import/startup/export **before** committing changed source to `codex-modular-v31`, leaving `main` untouched.
- Existing V0.33 saves still load. Player combat health and enemy respawns are intentionally session-only in this prototype.
- Enemies use a bounded practice-yard chase, not full city navigation/pathfinding. They are training-game placeholders, not named canon characters.
- No enemy XP or Tola farming, guild rank promotion, looting, or real PvP is introduced.
- Web build is shipped as `seeker-codex-v035-web` GitHub Actions artifact; upload the **Web ZIP**, never the `.yml`, to itch.io.
