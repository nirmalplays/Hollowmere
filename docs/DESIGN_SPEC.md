# Design spec: what the reference does, in numbers, and our targets

Sources: the full Dimraeth demo walkthrough (2h56m), sampled every 30 s
(`../hollowmere_sources/reference/frames/`, 352 frames). Our game is a **2D souls-like**:
stamina-gated, telegraphed, punishing-but-fair combat; death has a cost; the world teaches
by doing. Where the reference is softer than a souls-like, we go harder (noted).

Limits of this analysis: frames show everything visual. **Sound cannot be judged from
frames**; the sound section is our design, built on the owner's packs.

## 1. Pacing (first hour)
| Minute | Reference beat | Our beat (Act I) |
|---|---|---|
| 0:00-0:30 | Character creator (book): class, origin, persona, name | Same, with race x class (GAME_PLAN 4) |
| 0:30-1:30 | Loading tip, wake in a dark cave, move/run prompts | MQ01: wake in the cradle, lantern |
| 2:00-4:00 | Chest + crafting basics, first fights, combat controls list | Crawlers, stamina; inscription |
| 4:00-10:00 | Cave exploration, crystals, rest point at a camp | Grunts/dodge, scripted death, Hearth |
| 10:30-12:30 | Area banner, **first boss** (top bar, telegraphed slams, adds) | Gaunt Sexton (mini-boss) |
| 13:00-17:00 | Spirit mentor dialogue, home base: build tent + campfire, craft | (M8) The Refuge: workbench first |
| 17:30-25:00 | Village hub: guild hall, trainer, merchant, quest board | MQ02 Thornwick |
| 25:00-60:00 | Farmland zone: 3-enemy packs, side quests, gathering, waypoints | Ghostcap Field, Greywood edge |

Rules taken from it: **a new mechanic every 1-3 minutes in the first 15**; every mechanic is
introduced by a prompt the moment it's needed, never in a wall of text; **first boss by ~12 minutes**.

## 2. Combat numbers
| Measure | Reference (observed) | Our target (souls-like) |
|---|---|---|
| Player hit vs fodder | 4-9 damage, fodder dies in 3-5 hits | Light 11-12 dmg vs 30-50 HP: 3-5 hits |
| Spell/crit spikes | 40-100 (fire bursts, crits) | Heavy x2.2, riposte x2 on staggered |
| Enemy hit vs player | ~5-15% of HP | **10-18% of HP** (harder): crawler 8, grunt 14, Sexton 18-20 of 100 |
| Pack size | 1-4, usually 2-3; elites outlined | 1-3 in tutorial rooms, 3-5 in zones, 1 elite per pack |
| Telegraphs | Red ground decals, glow on wind-up, ~0.6-1.1 s | 0.65-1.1 s; boss pits 1.1 s |
| Boss | Name + long bar on top, arena, slams, adds, phase change | Same; phase 2 at 50% with adds |
| Stamina | Sprint costs stamina in combat only | Attacks, dodge, block, sprint all cost; exhaustion lockout |
| Rest points | Campfires refill potions | Hearths (lit shrines) refill flasks, respawn point |

## 3. Systems inventory (reference -> ours)
| Reference system | Detail observed | Ours | Status |
|---|---|---|---|
| Classes + origins | Class, Origin (race), Persona; 4 starter spells | 8 races x 6 classes | M3 |
| Attributes via trainer | Memory, Charisma, Adventure, Physique, Intelligence, Agility, Strength, Energy; XP spent per point | Might, Agility, Vitality, Intellect, Spirit, Luck; XP converts at the trainer | M6 |
| Skill tree | Constellation, points from levels, respec, spellbook tab | Same, per archetype | M6 |
| Spells | Q/E/R/F + weapon; fireburst, dragon's breath, blizzard | 5 slots | M5 |
| Gear + runes | Slots: rune, under-coat, belt, charm, ring, amulet, badge, bracer; **set bonuses** at 2/3/5/6 pieces; forge upgrades with essence | Equipment + forge upgrades; sets later | M4/M8 |
| Survival | **Hunger** (food), **carry weight** ("You cannot carry that much weight") | Meals (buffs) only for v0.1; weight later | M8 |
| Home base | Sanctum: build menu (bed, workbenches, cooking, alchemy, crops, decor) | The Refuge | M8 |
| Crafting | Backpack crafting, campfire cooking, codex of recipes, toasts on unlock | Workbench, kitchen, alchemy | M8 |
| World | Hub village, farmlands, wildwood, caverns; waypoints + fast travel; day/night clock; rain | Ashen Reach zones; Hearths as waypoints | M7 |
| Quests | Main/side/deed tabs; deed board donations; "QUEST COMPLETE!" | QUESTS.md (done: tracker, banner) | M7 |
| NPCs | Portrait dialogue on parchment, numbered choices, Talk/Train/Trade menu, ambient barks | Same | M9 |
| Map | Painted map, fog of war, beacons, zoom | Same | M7 |

## 4. Presentation rules (checked on every screen)
1. Hero ~1/25 of screen height; rooms large; most of the screen is world.
2. Darkness is the default; light marks the path (crystals, lanterns, braziers).
3. Every area: an entrance banner, a landmark visible early, a side path with a reward.
4. UI: parchment for menus/dialogue/shops; dark blue for journal/map; serif titles, diamond bullets.
5. Never more than 3 lines of prompt on screen; tutorial cards only for concepts, not controls.

## 5. Sound (our design)
| Layer | Rule |
|---|---|
| Music | States: area (explore) -> battle (any engaged enemy) -> boss; 4 s calm before returning; menu has its own theme |
| Ambience | One bed per area (forest birds, cave reverb, rain); positional loops on fires and water |
| SFX | Every player action and every hit has a sound with pitch variation; UI moves/selects/backs; quest and item stingers |
| Mix | Music -4 dB, ambience -6 dB, SFX 0, UI -3; footsteps quiet (-14 dB) |
