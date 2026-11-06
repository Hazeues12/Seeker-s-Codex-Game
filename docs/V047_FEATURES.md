# Margerina V0.47 — Reactive Canal Incident / Vertical Slice

**Game-only prototype**, inspired by Ring Two's public life in the author's Chapter 90 setting. Does not define a canonical rescue, new named character, or official Seeker career examination.

## Playable incident

- A public canal-side noticeboard at approximately (2, 41), an endangered civilian at (-2, 52), and a supply shipment at (3, 60), along the V0.40 boulevard.
- Accept the incident through the existing TALK / USE system. Travel between distinct world props to decide on **rescuing the worker**, **securing cargo**, or **withdrawing**. Only one final outcome is possible.
- Rescuing a person raises Association Trust and Neighborhood Respect; prioritizing cargo improves Guild Reliability but damages local standing; withdrawing diminishes trust in follow-through. This is a local prototype, not an official disciplinary finding.
- Visible warning signal changes according to status; cargo disappears after recovery, with saved results restored after browser reload.
- All state and the resulting consequence transaction are saved in the current Personal Codex JSON, with `society` reputation and `civic_events` status updated together. No duplicate rewards or Tola changes.
- UI closes without overwriting quest menus, conversation, LOOK or the saved Codex. Existing iPhone joystick, run+jump, double jump, wall-run and water-run are unchanged.

## Safeguards and next steps

- The scenario uses fictional workplace roles without inventing names or hidden plot revelations. The Citadel remains restricted. Celestial, Bloodline Eyes, official promotions, Soul Bloom and Spirit Bloom do not unlock.
- This is the start of a full mission loop. Later scenarios should add enemies outside the sparring yard, actual civilian movement, preparing equipment, carriage routes, injuries and consequences across multiple days. Those systems are **not implemented** by this milestone.
- Validation includes full Godot import, startup, V0.46 Spoke-safety test, V0.47 decision guards, Web export, and commit only after success. Mobile device testing is deliberately deferred until a larger release candidate.
