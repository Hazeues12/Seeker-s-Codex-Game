# Seeker's Codex — V0.58 Young Blood Original-Seeker Identity

## Production intent
Adapt Young Blood's character authorship into a walkable 3D RPG while preserving the developing known-world terrain and Margerina's 1500 A.S. story continuity. The user wants a finished game playtest, not a succession of unfinished public releases.

## Source boundary
The user provided the Young Blood v385 system description (save version 303, filename `young-blood-v173.jsx`). The JSX and full written guide were **not available for line-by-line verification** when this patch was prepared. Therefore the **nine social-origin labels and numerical bonuses in this implementation are game-only design proposals**. They are not presented as exact exported Young Blood v385 data or as new canon.

## Actual 3D gameplay implemented
- The existing **Magnara Life Road Registrar** now includes a second, permanent character-history section after a life path has been chosen.
- 9 provisional social-origin templates: monastery ward, guild apprentice, dockworker household, caravan raised, rural household, merchant household, noble dependent, frontier survivor, displaced civilian.
- 5 temperaments, 8 selectable traits, up to 2 explicit disadvantages, and 5 perk options, with 1 free perk point plus 1 for each accepted disadvantage. Invalid overspending, duplicate perks and retroactive origin edits are rejected.
- Real gameplay modifiers: personal stamina ceiling and recovery, sprint multiplier, Aura recovery, guard stamina discount, local Essence Tonic price, and civic courier earnings. Calculations have strict caps.
- **Debt** starts as 40 Tola and withholds up to 4 Tola from a completed courier delivery until repaid; a receipt and reduced debt are written together to the Personal Codex before in-game payment.
- The existing low-poly **3D seeker character rig** now adds a different national outfit silhouette for each of the ten home-nation choices supplied in the user's Young Blood creator summary. National outfit cues are Janoah workwear, Rajistan saffron drape, Chun cross-collar, Vinlan mantle, Britannia tabard, Germania greatcoat, Tsar fur collar, Zirael hood/face wrap, Africanus shoulder weave, Americana duster. These are *prototype player clothing concepts*, not final or exhaustive representation of any nation's or culture's fashion.
- Each visible outfit is created as real separate 3D meshes on the articulated rig without replacing the existing collider, camera, running, jumping, dodge, or attack systems. The existing LOOK editor retains skin, hairstyle, coat and Aura customization.
- Origins and debt are stored in the existing `user://seeker_profile_v1.json` under `origin_v058`; old saves without that entry use original default movement/prices and remain readable. The original game save `margerina_v033.json` remains on schema 1.
- The Personal Codex now lists original-Seeker background, temperament, trait, disadvantages, perks and remaining debt, rather than claiming these were never chosen.

## Canon restrictions
- No inherited Eyes, Viatra, Black Clan arts, Spirit Bloom, Soul Bloom, Celestial, Arcwheel secret, new official Seeker rank or Pillar appointment can be acquired through an origin or national costume.
- The canon cast remains intact and independently active. A player's starting background is game-only.
- `Take the Exam`, `Already Sworn`, and `Live a Trade` remain distinct. A civilian cannot claim a licensed Seeker contract just by using the existing starter board.
- National clothing templates are provisional **Silhouettes**, not proof that all citizens of each nation wear identical uniforms. A final art audit will require internal regional and class diversity, especially Africanus' five blocs.

## Testing gates
1. Full Godot 4.4.1 project import and main-scene startup.
2. All saved gameplay/world regression tests V0.48–V0.57.
3. Pure deterministic origin tests: every background, temperament, trait; locked history; 2-disadvantage limit; earned perk points; negative effects; debt withholding; exact save/reload.
4. Full 3D integration: ten national outfit node groups, in-world registrar, mobile modal, real-currency courier receipt and no duplicate payout.
5. Full HTML5/Web export, internal artifact only, no public distribution.
6. Promote only staging passing builds to `codex-modular-v31`, preserve `main`.

## Still to build
Young Blood's 11-step character creator, genders/body choices, full hairstyles, family-specific lineage restrictions, 6-stage Aura ladder, true signature-technique forge, 36-step examination and its canon encounters, other eight civilian trades, long-term careers, rich adult romance/family, household property, player entrepreneurship, varied NPC life simulation, injuries across body parts and controlled Arcwheel-legacy story consequences. Full atomic recovery across the Codex and old-money save is still a **release gate**; receipt-first checks stop ordinary double payments but do not settle every crash timing case.

The world remains incomplete. Build geography and inhabited cities at planned scale rather than treating new systems as sufficient to release the game.
