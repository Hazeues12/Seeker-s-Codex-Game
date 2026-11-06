# Seeker's Codex: World of Margerina — V0.46 Seven Spokes Combat Foundation

## Scope and canon restrictions

This version adds **supervised, game-only combat simulations** in Magnara's existing sparring yard, **not** new official techniques or permanent Spoke unlocks. A Stray Seeker is NOT entitled to freely master all Seven Spokes. The preview program demonstrates how combat categories should feel while the later character creator, lineage, mentorship and training requirements are built.

- Ordinary Seven Spokes: Elemental, Martial, Spirit, Alchemy, Psychic, Spatial, Abyssal. The hotbar cycles seven sandbox previews; Celestial remains exceptional and is excluded.
- Soul Bloom and Spirit Bloom remain separate; there is no automatic Ryōiki/Eidolon/Soul Manifestation unlock.
- No forbidden effects are learned outside the training court. No authority, inherited ocular technique or Citadel access granted.

## Mechanics

- `MUTI` cycles the active demonstration; `ART` executes it. `R` on a keyboard also executes the selected Art. The existing joystick, RUN, JUMP, STRIKE, GUARD, DODGE, LOOK, TALK/USE, NPC relationships and saves are not replaced.
- All practice costs Aura (14–28) and incurs technique-specific cooldowns (0.8–5.0 seconds). Failed attempts do not consume Aura. Casting is disabled outside the original sparring court, near closed menus, or when knocked out.
- Martial: up-close reinforced impact. Elemental: ranged energy hit. Spirit: restore 16 HP if injured. Alchemy: a ward that expires or blocks one attack. Psychic: interrupt a live enemy. Spatial: collision-checked short shift inside the court. Abyssal: high impact with 7 HP bodily strain.
- Damage is still subject to construct guarding and the previously established combat logic. Player always retains at least 1 HP from demonstration strain.
- On first successful use of a Spoke demonstration, the Personal Codex records one **practice-only** event, never a permanent mastery entry.
- Visual technique flashes use small temporary meshes and avoid expensive mobile shaders.

## Testing / release

GitHub workflow validates: install input SHAs, script parsing, game startup, existing V0.44 relationship regression, new Seven Spokes cost/cooldown/sandbox invariants, and full Web export. iPhone multi-finger real-world performance and interaction testing are reserved for the later completed-release gate, as requested by the owner.

## Next systems

Build training licenses and custom backgrounds, field combat variants, reliable enemy AI counters, environmental Muti interactions, injury and preparation, and scenario missions spanning the city and roads. Only promote game mechanics into published canon after explicit author confirmation.
