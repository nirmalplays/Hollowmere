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
