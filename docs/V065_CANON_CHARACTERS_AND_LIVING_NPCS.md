# Seeker's Codex — Young Blood 3D / V0.65 Living Characters and Magnara Population

**World:** Margerina, 1500 A.S. **Target branch:** `codex-modular-v31` only after CI pass. **Original game branch:** `main`, untouched.

## Canon evidence and hierarchy

The registry `data/seeker_character_registry_v065.json` is a **best-effort, expandable** character index, not a claim to contain every named figure from all existing chapters/chats. It currently contains 64 named story character/group records, 10 factions/organizations, and 10 published/author-locked venues plus 22 distinct newly created game-only civilian NPCs.

Source hierarchy: newest explicit author correction > published original chapters > locked manuscript/dossier > game-only prototype. Audited prior project canon files and the official Royal Road sources, including:
- [Beyond the Abyssal Line / mainline contents](https://www.royalroad.com/fiction/132012/seekers-codex-beyond-the-abyssal-line) (91 listed chapters as of 2026-11-06)
- [Trial By Mind](https://www.royalroad.com/fiction/132012/seekers-codex-beyond-the-abyssal-line/chapter/2594711/trial-by-mind) (Squad One, Two, Three and Four rosters, personalities)
- [Order of the Crescent Halo](https://www.royalroad.com/fiction/132012/seekers-codex-beyond-the-abyssal-line/chapter/2704900/order-of-the-crescent-halo) (The Talking Boar, Hanami, Ven, city culture)
- [United States of Janoah](https://www.royalroad.com/fiction/132012/seekers-codex-beyond-the-abyssal-line/chapter/2689891/the-united-states-of-janoahthe-steel-flame-republic) (Forgehouse and Janoah arrival)
- [Darker Than Black Pt 8](https://www.royalroad.com/fiction/132012/seekers-codex-beyond-the-abyssal-line/chapter/4243742/trial-by-mercy-darker-than-black-pt-8) (Rin's **covert** rooftop investigation; Nezubunta/Onzu reconnaissance; Le'Bell's, Avicci, Vernal Divongcci, Flama, BLADE and Terra Firma)
- [Light Born](https://www.royalroad.com/fiction/140309/seekers-codex-light-born) historical William distinct from current William.

## Real physical V0.65 content

`world/magnara_population_v065.gd` appends **three collidable street spines**, walkable pavements and a cross avenue north of V0.64. A new open public venue, **The Talking Boar**, has a real floor, roof, side walls, entry aperture, walkway, service bar, tables, dispatch counter and kitchen partition. The guildhouse is a *canon venue*, but its newly selected coordinates, basic mesh appearance and daily route assignments are **game-only and not fixed in the series atlas**. Canon buildings beyond this district are *registered*, not falsely rendered.

The prototype instantiates 28 separate 3D population models: 22 ordinary named game-only civilians and 6 canonical public figures (**William, Hanami, Ven, Kai, Aria and Lila**), using genuine guild affiliation and equipment metadata where available. Aria's blonde hair, Kai's Sun staff, and William's light-colored coat are expressed in basic prototype meshes. Rin **does not** casually appear on the street while his published story places him in active stealth; Nezubunta and Onzu, Seizen, Yobokari and restricted figures never become public randomized NPCs. Other canonical characters remain rostered for story/region-specific authored venues.

Each public NPC offers a mobile-compatible talk panel with grounded individual role, personal dialogue and daytime routine. Daily relationship choices (listen +1, help +2, dismiss -2) are recorded per NPC in the Personal Codex `user://seeker_profile_v1.json`, limited to one choice per person per game day, clamped and sanitized. This does **not** rewrite mainline character arcs or grant guild membership, family relationships, special powers or Seeker ranks. After choices, full records are verified on disk.

## Schedule engine and performance

`systems/character_population_rules_v065.gd` computes every public civilian's unique hourly pattern from their stable identity, job, shift offset, home/work/leisure anchor and night-shift role. Residents commute through mapped road spines and plazas, work, take meal breaks, meet in public squares, go home and sleep. They are advanced analytically from the world clock, so **offscreen time passes without ticking a full simulated actor each frame**. On-screen visual updates are throttled and culled beyond 125m. No expensive Godot NavigationServer or unbounded AI planning loop.

The six onstage canonical character routines are conservative **game-only approximation schedules** tied to published venues and public relationships. William handles mentor and guildmaster duties, Hanami handles dispatch and hospitality, Ven divides his time between the Forgehouse (offscreen) and guild, Kai trains/visits the guild, Aria trains, and Lila makes periodic guild appearances. They are time-gated to the author's default `trial_week_open_world_parallel` stage. Their canon schedule details are unknown until verified; the NPC system must never claim these inferred times are events in published chapters. Historical William, Sagas heroes, antagonists, covert figures and NPCs from other nations must remain offstage until proper timeframe/region/story gates.

### Canon-specific barriers

- No random high-tier eyes, Celestial awakening, Seeker ranks, guild ranks, rare summons or secret bloodlines granted to generic filler citizens.
- A canonical character is never spawned without a known public scene and explicit story-scenario gate.
- Family links stay attached to confirmed roles; the *Lalia/Laila* naming discrepancy is retained for author reconciliation.
- Rin's historical Yoru Oni / later Chi no Ryōken weapon continuity remains unresolved, and this release does not conflate them.
- The outer-band shops (Le'Bell's, Avicci, Vernal Divongcci) and guild banners (Flama, BLADE, Terra Firma) have registry entries, but **no fabricated shop owners, prices or coordinates**. Their actual buildings and interior inventories await authored implementation.
- Squad One/Two/Four include precisely the published four members each. Do not spawn them as all simultaneously living at the Talking Boar; route by exam/trial narrative phase when physical locations are built.

## Validation gates

`tests/v065_population_rules_scene.tscn` checks 64 named records, 22 civilians, canonical squads, guarded character visibility, equipment/family locks, schedules, safe roads and persistent social data validation. `tests/v065_population_world_scene.tscn` boots the full game and verifies **actual** buildings, staff and civilian 3D models, nearby mobile interaction, daytime movement, stored relationships and save/reload, while ensuring prior V0.54-V0.64 worlds remain.

The V0.65 staging CI also checks project import, legacy V0.64 civic, V0.62 market, V0.63 save integrity and Web export. Passing CI validates Godot functionality, **not** final iPhone Safari FPS. No manual phone test required until larger neighborhoods are ready.

## Remaining population roadmap

This is the *beginning* of complete world population, not a claim all 64 named characters are rendered or all countries are built. Next steps: data-driven regional streaming and population budgets for all known cities and nations; author-defined daily contracts, personalities, homes and gear; The Talking Boar's complete multi-floor life and staff; real businesses, guild halls, squads, families and vehicle schedules; peer rivalries, NPC goals, injury and conflict memory; personality-consistent authored dialogue; and stringent online/author-lore change audits. Only build what is known, mark what is unverified, and never use filler to impersonate mainline canon.
