# Reference breakdown: Dimraeth full demo walkthrough

Source: the owner's link (https://youtu.be/ZPYExcaGRb0), sampled every 30 s
(frames in `../hollowmere_sources/reference/frames/`). What we copy is **structure,
presentation and feel**: never its art, names, text or maps.

## Flow of the first 25 minutes
| Time | What happens | Systems shown |
|---|---|---|
| 0:30 | Character creation in an open book: Class, Origin (race), Persona, name; right page shows the class blurb, 4 starting spells, an attribute radar | Character creator |
| 1:00 | Loading screen: progress bar + rotating **Tips** | Loading tips |
| 1:30 | Wake in a dark cave. Top-left tutorial list: "Move with WASD", "Run by holding Space", note "Auto sprint in Settings". Quest tracker: **The First Steps / Find your way out** | Tutorial prompts, quest tracker |
| 2:00 | Modal: **Select a movement type** (normal sprint / auto sprint while exploring) | Settings choice |
| 2:30 | A camp with a chest: "To pick up the item press [LMB]", "Open your inventory with [I]", "Craft in your backpack"; sub-steps *Check the chest for supplies*, *Craft Water*; item toast top-right ("Item: Droop Gelo") | Chests, pickups, crafting, toasts |
| 3:30 | Combat tutorial list: Attack (LMB), Block by holding Shift, Dash with Space, Cast spell with Q/E/R/F | Combat controls |
| 4:00-5:00 | Glowing crystal pillars light the cave, enemy blobs, XP rises, a big crystal chamber | Lighting, XP |
| 5:30 | Pause menu tabs: Character, Crafting Codex, **Quest**, Map, Spell, Social, Settings. Quest page: title, area, description, objective groups | Journal |
| 6:30 | Equipment tutorial: "Drag equipment into its equipment slot" | Equipment |
| 10:00 | "Rest at campfires to refill potions and other combat items" | Rest points |
| 10:30 | Area title banner: **THE LOST CAVERNS** | Area banners |
| 11:00 | Boss: name + long bar at the top of the screen, telegraphed slams | Boss bar |
| 18:00 | Village of tents, crates, banners, market stalls; "Quest: new side quest" toasts | Hub town |
| 18:30 | Interior: **THE GUILD HALL** banner; round tables, lanterns, many NPCs | Interiors |
| 19:30 | Dialogue: parchment page with the conversation log + numbered choices, large character portrait (name + title) on the right | Dialogue |
| 20:30 | Ambient NPC barks in small text boxes | Barks |
| 21:00 | Spellbook recipe tooltip, inventory grid, attribute requirements | Items, spellbooks |
| 22:00 | Quest log tabs: All, Main, Side, Deed, Completed; "Show on map" | Quest log |
| 22:30 | Interact menu on an NPC: Talk / Train / Trade | NPC services |
| 23:00 | Skill tree: constellation of nodes, available/spent points, Respec | Skill tree |
| 23:30 | World map: painted parchment map, player icon, time of day | Map |
| 1:12 | Iris (circle) transitions between areas; shop UI on parchment; travelling merchant portrait | Transitions, shops |
| 1:15 | Forge: upgrade equipment with materials | Crafting stations |
| 1:15-1:17 | Rainy forest, fog, roots and ruins; quest "A Village in Crisis" | Weather, exploration |

## Presentation rules we take from it
- **Camera and scale:** high 3/4 view; the hero is about 1/25 of the screen's height; rooms are big and mostly dark, lit by crystals, lanterns and fires.
- **HUD:** bottom-left diamond quick-slots + XP + three bars; bottom-right diamond spell bar (Q/E/R/F + weapon); right: quest tracker; top-left: tutorial prompts with key glyphs; top-right: item/quest toasts.
- **UI skin:** parchment pages with gold frames for menus, dialogue, shop, forge; dark blue panels with serif titles for the journal and map.
- **Story delivery:** area banners, toasts, short barks, portrait dialogue with numbered choices.

## Mapping to our plan
| Reference system | Our plan section | Milestone |
|---|---|---|
| Book-style creator (class, origin, persona) | GAME_PLAN 4, STORY_BIBLE 3.5 | M3 |
| Tutorial prompts, first-steps quest | QUESTS 7, ACT1_MQ01 | M3-M4 (now) |
| Chests, pickups, inventory, equipment | GAME_PLAN 6, M4 | M4 |
| Spells Q/E/R/F + spellbooks | GAME_PLAN 5.5 | M5 |
| Skill tree with respec | GAME_PLAN 6 | M6 |
| Quest log, deeds board, area banners, map | QUESTS 0, 5; GAME_PLAN 7 | M7 |
| Camps/rest points, crafting, forge | GAME_PLAN 8 | M8 |
| Portrait dialogue, NPC services (talk/train/trade) | QUESTS 3, GAME_PLAN 9 | M9 |

# Part 2: how its places and missions are built (1:12 to 2:54 of the walkthrough)

Second pass over the footage, looking only at construction. Again: we take the
**method**, never the art, names or maps.

## How places are named
| What | Their pattern (examples seen) | Our equivalent |
|---|---|---|
| Zones | "The" + adjective + noun, or a compound + biome: The Lost Caverns, The Guild Hall, Wildwood Forest | The Underroot Caves, The Ashen Reach, Thornwick |
| Named spots inside a zone | Shown on the map and in quest text, not as banners (a "Sanctum" fast-travel point) | Every cavern has a name in the level file: the Cradle Hollow, the Nameless Hall, the Old Descent, the Wardens' Mess, the Sexton's Round |
| NPCs | First name + an epithet under it: "The Travelling Merchant", "The Gentlest Spirit", "Dwarven Poet", "Guild Leader" | Name + epithet on the dialogue portrait and the bark plate |
| Quests | Short and literary, often possessive or "The X of Y": A Village in Crisis, A Merchant's Lost Tools, The Art of Runesmithing, Verses Beneath the Bark, a named character's "Lament" | QUESTS.md already follows this (The Waking) |
| Bosses and elites | Adjective + creature for bosses; role names for elites (a warden, a caller, a weaver) | The Gaunt Sexton; elites get role names |

## How a location is constructed
1. **One continuous landmass, never rooms and corridors.** The map screen shows a zone as
   a winding ribbon of ground that loops around black lakes and voids, with the hub in
   the middle and points of interest as icons along it.
2. **Edges are natural.** Canopy masses, cliffs, water and darkness bound the play space.
   No straight wall runs longer than a few steps.
3. **The ground is painted, not tiled.** Two or three tones in soft blobs; the lighter
   tone is the path and leads the eye. No visible grid.
4. **Every screen has a landmark:** a giant stump, a ruined arch, a rune circle, a crystal
   cluster, a wrecked cart, a dock. You can always say where you are.
5. **Light leads.** Lamp posts, crystals and campfires sit along the intended route;
   side pockets are darker.
6. **Rest points are pockets off the path:** tent, bedroll, fire. Safe, warm-lit.
7. **Biome shift signals danger.** Green forest, then blue night marsh, then a red and
   purple corrupted wood, then the boss arena: an enclosed round clearing with its own
   palette.
8. **Everything breathes:** rain, drifting leaves, swaying canopy and grass, light shafts,
   floating wisps.

## How missions are built
- **Main quest shape:** three parallel objectives in any order ("find and slay the first /
  second / third source"), then a gate ("slay monsters to open the way 0/8"), then the boss.
- **Side quests are found, not listed:** an NPC in trouble barks at you in the wild
  ("Hey you! Help me out!"), and the quest starts on the spot.
- **Deeds trigger by place:** walking into an elite's territory pops "New Deed" with its
  own small objective.
- **Fetch quests always turn:** "find the lost tools" becomes "slay the ambushers", then
  "return to the merchant". Gather quests ask for small counts (5 wood, 5 stone).
- **The tracker shows only the active quest**, one to four live objectives, counters inline.
- **Enemies are never idle props.** Packs of two to five roam clearings and engage on
  sight; elites carry a red outline and a role name; bosses get the bar and their name.
- **Numbers stay small:** hits read 6 to 16 on fodder, 40 to 95 for spells and crits.

## What we changed because of this
- The Underroot is now carved from lumpy caverns and brush-stroke passages
  (`tools/levels/underroot_map.py`); each cavern is named and has a landmark.
- The Hollowed no longer wait for the quest: they attack on sight, and The Waking's
  objectives are conditions that can be met in any order.
- Still owed: painted ground (floor variation by region), a rest pocket with a reward,
  three-way objectives in the first outdoor zone, found side quests and place-triggered deeds.

## Every banner in the walkthrough (automated scan, one frame per second)
A script looked for the banner's white title text in all three hours of footage and
pulled 130 hits. What they show:

- **A zone is a string of named sub-areas**, and the banner fires every time you cross
  into one. Names share a regional prefix: a village, its farmlands, its cross roads,
  its road waygate, and north / south waypoints, all carrying the same first word.
  Wild places drop the prefix and get evocative names (a pool of remembrance, an old
  ones' ruins, a hidden grove, an elite's own grove). Interiors take "The".
- **Fast travel points are named places too** (waypoints, a waygate) and announce
  themselves like any other spot.
- **"Quest complete" uses the same banner** with the quest's name beneath, and it fires
  often: about 25 times in three hours, so roughly one every seven minutes. Early quests
  are tutorials by name (first steps, learning to build, learning to train, new lessons,
  reach the village), then chores for the village (pitching in, thinning the fields,
  maintaining the defences), then the wild (a refugee, a poet's verses, a lost shipment).
- **Deeds are a board:** "Available Deeds (4/10)" with repeatable patrol and scouting jobs.

Applied: `AreaLayout.place_names / place_rects` and `AreaScene` announce each named
place in the Underroot as the player walks into it. Thornwick and the Ashen Reach should
share a prefix scheme the same way (Thornwick Gate, Thornwick Green, Thornwick Mill...).
