# Seeker's Codex — V0.59 Family History, Clan Claims and Consequences

**World:** Margerina, year 1500 A.S. **Build:** Godot 4.4.1 / mobile-browser 3D.

## The source limitation
Young Blood v385 was described as having six family lines. The exact six labels in the v385 `young-blood-v173.jsx` build and its full guide were **not available for line-by-line comparison** in this integration. The six names below come from documented prior game-prototype family options and series canon. They are **unverified claims for the player-created character**, not approved v385 labels, legal ancestry, or new family members in the novels.

Working selection (can later be reconciled against actual v385 source):
1. Common Line / family unknown
2. Kairo / Black Clan claim
3. Wonder family branch claim
4. Abel Sky-Talon branch claim
5. Flamehart war-family claim
6. Butters Vitalis family claim

The Kairo, Wonder, Abel, Flamehart and Butters surnames are grounded in existing Seeker's Codex lore. Their availability to an original player character is a **game-only alternative story**, not proof of relationship to Rin, Seizen, Aria, Lila, the Wonder family, or Jeremiah Abel.

## Actual game behavior
- After the user selects a road and social origin at Magnara's walkable **Life Registrar**, the same in-world panel offers six claim paths, a household tie (**supportive / complicated / estranged**), and **private / public** disclosure.
- A sealed family story is persisted at `profile.family_v059` in the existing Personal Codex save; it cannot be overwritten by the ordinary registrar controls. Legacy profiles without it remain valid.
- Family tie affects one small slice of the **actual civilian courier economy**: a supportive household gives +1 Tola gross and an estranged one gives -1; an unresolved bond gives 0. Existing debt withholding is computed afterward.
- A **physically present Public Family Records counter** in Magnara's Ring Two lets the player submit one one-time archive inquiry. It creates a persistent `pending_evidence` history flag for claimed lineages. This is a player-side investigation milestone; it does not promise automatic future approval or real lineage verification.
- The local registration clerk and Citadel sentry now **react to public Black Clan claims** in the active `SeekerSociety` dialogue system, while confidential claims stay private in public patrol talk. Public family disclosure can increase a 0–2 institutional scrutiny measure. Neither action creates an official criminal accusation.
- Personal Codex displays claim, family bonds, public/private state, archive inquiry and explicit *no restricted ocular access*.

## Inherited powers remain locked
The lore identifies **Viatra as tied to the Kairo/Black Clan lineage**, with stages I Kurodō, II Shōen no Me, III Tenseigan Shikai, IV Ankoku Raigan, IV.5 Makugan: Reimei (Seizen-specific), and theoretical V Shinkōgan. **Genmugan is a Black Clan illusion discipline, not a separate eye.** A mere original Seeker's family claim grants none of the above.

`FamilyV059.sanitize()` rejects all externally asserted `viatra_access`, `bloodline_confirmed`, `ocular_license`, `family_privilege` and invented canon-verification flags. A later lore-verified ancestry/evidence quest may be designed separately, with author approval, evidence and hard eligibility tests. Bloodtras Survivor implants and suspicion are a distinct story path; they are not casually assigned by family selection.

These limits also protect Azure Tenzan Eye (Tsar), Tokoyami (Nightshade) and other rare inherited ocular traditions. The creator must not turn restricted clan abilities or royal/celestial authority into ordinary starting perks.

## World-first implementation
The new public records counter is a physical, touch-interactable object alongside the existing city registrar, not a separate menu pretending to be a 3D settlement. All prior working environment systems remain: 26 km proposed Magnara ring geography; Janoah countryside, working river collision, bridges; camera and iPhone controls; six accessible early interiors; personal profiles; existing guild quests and relationships.

The public registry is game-only. It doesn't change published canonical institutions, add a new settlement, or assert a new geography point beyond the existing measured Ring Two preview.

## Verification and release gates
Run:
- whole-project Godot import and startup (fail on any parse/runtime errors);
- V0.48–V0.58 regression test scenes;
- V0.59 six-line/rights pure tests, malformed JSON and forged-bloodline rejection;
- V0.59 physical archive and dialogue integration with a separate clean user-data directory;
- browser Web export with HTML/JS/WASM/PCK artifacts.
Only fast-forward validated code from `young-blood-family-v059-staging` to `codex-modular-v31`. Preserve `main`.

## Next unmet goals
Actual original Young Blood v385 family list and exact rules once its JSX source is available; family ancestry quests and NPC kinship schedules; multigenerational households, homes and inheritance; faction investigation, witnesses and evidence; late-game bloodline disciplines with validated canon and consequences; fuller social interactions, adult romance, parenting, betrayal, trade and property; city neighborhoods beyond these prototype stations; secure cross-file transaction recovery and physical iPhone-browser profiling.

**Status:** a playable family-choice and local archive slice inside an unfinished RPG, not the completed world.
