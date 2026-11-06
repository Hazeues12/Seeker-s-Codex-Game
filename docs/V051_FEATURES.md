# Margerina V0.51 — Living Ring Two Routines and Daily Civic Events

**Development-only** extension to the verified V0.50 world. It is not a finished RPG release.

## Daily routines
- The seven Ring Two professional/public NPCs and the three earlier neighborhood NPCs use deterministic, role-specific working hours and duty-route stops based on the existing in-game clock.
- Medic and patrol roles maintain night coverage. Public vendors and registration desks have closing hours; the journal shows which public services are open.
- Near the player, residents visibly move toward the next duty point. Distant or off-shift NPCs are hidden rather than running full simulation on Safari. The collision/camera/multi-touch systems remain unchanged.
- Work locations and NPC roles are **game-only placeholders** based on Chapter 90 geography, not assertions about canonical city maps or named residents.

## Reactive civic bulletin
- A City Duty Bulletin is located beside the Ring Two professional boulevard, accessed via the existing TALK / USE input.
- Each game day offers **one** exclusive response: help civic services, report verified observations from actual completed work, or accept a suspicious shortcut with professional misconduct consequences.
- Later bulletins reference the resolved canal incident and/or completed waystation expedition. Neither content nor positive reports are fabricated when the player has no evidence.
- Choices modify bounded civic/professional reputation and are recorded **together** with their day and chronicle in the existing Personal Codex save. Choices cannot be repeated the same day; later days generate new opportunities.
- No extra currency payout is introduced. No automatic ranks, invented Eye inheritances, Soul Bloom, Spirit Bloom, Eidolon, Citadel access, or canonical events.

## Validation and limits
- Godot 4.4.1 import, full scene startup, V0.48/49/50 regression tests, V0.51 daily schedule/choice/JSON test, Web export, then development-branch commit.
- Existing V0.33 gameplay save, V0.38 appearance, V0.41 orientation, V0.43+ Personal Codex, companion state and mission saves remain intact.
- This is bounded deterministic behavior, not advanced autonomous NPC cognition, full schedule pathfinding, or an entire simulated nation. A true finished RPG still requires authored areas, story missions, art polish and iPhone acceptance testing.
