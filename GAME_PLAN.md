# GAME PLAN: "Hollowmere" (working title)

A pixel-art, top-down action RPG with Souls-lite combat, a build-your-own home base, and companions. **It is a single-player game first; online drop-in co-op for up to 8 players is an optional mode.** Built in **Godot 4.3+ (GDScript)**.

> This document is the single source of truth for Claude Code. Read it fully before writing code. Work milestone by milestone (Section 14). Do not skip ahead. Keep the game runnable at the end of every milestone.

---

## 0. Ground rules (read first)

1. **Mechanics are modeled on the genre reference (Dimraeth). Content is original.** Systems like race x class archetypes, stamina combat, home-base building, and world-bound vs. character-bound progression are game mechanics and are fine to reproduce. **Names, story, dialogue, maps, spell names, item names, character designs and art must be original.** Do not copy text, sprites, maps, or names from Dimraeth. Placeholder names used in this doc are all original; the owner will replace the story/lore later.
2. **Placeholder art only from CC0 / properly licensed packs** (Section 11). Track every asset in `ASSETS.md` with source and license.
3. **Data-driven everything.** Races, classes, spells, items, enemies, recipes, buildings, quests live in `.tres` resources or JSON under `data/`, not hardcoded in scripts. Adding content must not need code changes.
4. **Solo is the primary mode; multiplayer-aware from day one.** Every system must work with exactly one player. Even in milestone 1, write code with the host-authority model in Section 9 in mind (solo = a host with no connected peers), because retrofitting netcode later is far more painful.
5. **Small, testable steps.** After each milestone: the project opens, runs, and has no script errors (`godot --headless --quit` should exit clean). Commit after each milestone.
6. **Check in at every milestone.** When a milestone is finished, stop: summarize what works, show how to run it, list any decisions made and any questions (also written to `OPEN_QUESTIONS.md`), and **ask the owner before starting the next milestone.** For ambiguity inside a milestone, pick the simplest default and note it.

---

## 1. Vision and pillars

- **Deliberate combat.** Every attack is a commitment. Stamina, telegraphs, dodge, block, parry. Fights are demanding but fair.
- **Adventure, then return home.** Explore a zone, fight, loot, gather, then return to a home base that visibly grows.
- **Build identity.** 8 races x 6 classes = 48 archetypes, each with its own skill tree flavor and playstyle.
- **Relationships matter.** Recruit allies, deepen bonds, unlock conversations, personal quests, and upgrades to their facilities.
- **Play alone or together.** The game is fully playable and balanced solo. Co-op (drop-in/drop-out, up to 8 players) is optional and must never be required to progress or reach any ending.

**Scope for first playable (v0.1):** 3 races, 3 classes (9 archetypes), 1 starter region with 3 zones, 2 bosses, home base with core buildings, 3 recruitable allies, online co-op for up to 8.
The full 8 races x 6 classes is the long-term target; the data layout must make adding the rest a content task only.

---

## 2. Tech stack and project setup

- **Engine:** Godot 4.3+ (stable), **GDScript** with static typing everywhere (`var hp: int = 10`).
- **Renderer:** Compatibility or Forward+ (choose Compatibility for broad web/desktop support; note in README).
- **Pixel settings:** Project Settings -> Rendering -> Textures -> Default Texture Filter = **Nearest**. Viewport 480x270, stretch mode `canvas_items`, aspect `keep`, integer scaling on. Snap 2D transforms and vertices to pixel.
- **Base tile size:** 16x16. Characters 16x16 or 16x24 (decide in M1, keep consistent).
- **Networking:** Godot High-Level Multiplayer API, `ENetMultiplayerPeer`, host-authoritative (Section 9).
- **Input:** Keyboard+mouse and gamepad. Define all actions in InputMap (Section 12).
- **Version control:** git, one commit per milestone minimum. `.gitignore` for `.godot/`, exports, saves.
- **Target platforms:** Windows, Linux, macOS desktop first. Web export is out of scope for v0.1 (ENet does not work in browsers).

### Folder layout

```
res://
  project.godot
  ASSETS.md, OPEN_QUESTIONS.md, README.md
  data/
    races/            # one .tres per race
    classes/          # one .tres per class
    archetypes/       # optional overrides per race+class pair
    spells/
    items/
    recipes/
    enemies/
    buildings/
    allies/
    quests/
    loot_tables/
    dialogue/         # JSON or .tres
  scripts/
    core/             # autoloads: GameState, NetManager, SaveManager, DataRegistry, EventBus
    entities/         # Player, Enemy, Ally, Pet, Projectile
    systems/          # Combat, Stats, Skills, Spells, Inventory, Crafting, Quests, Dialogue
    world/            # Zone loader, spawners, home base grid
    ui/
  scenes/
    entities/ world/ ui/ zones/ home/
  assets/
    art/ audio/ fonts/
  tests/              # headless test scenes/scripts
```

### Autoloads (singletons)

- `EventBus`: global signals (damage_dealt, enemy_killed, item_picked, quest_updated...).
- `DataRegistry`: loads all `data/` resources at startup, lookup by id.
- `GameState`: current world, difficulty, flags, connected players.
- `NetManager`: host/join/leave, peer list, RPC helpers.
- `SaveManager`: character profile and world saves (Section 10).

---

## 3. Core game loop

1. Create or load a **character** (race, class, name, appearance tint).
2. Create or load a **world** (host) or **join** one (client). World difficulty (Normal/Hard) is chosen at creation and is permanent.
3. Spawn at the **home base**. Use workbench, storage, shops, allies.
4. Take quests from a **notice board** and the main storyline. Travel to a zone.
5. Explore, fight (Souls-lite), loot, gather, recruit allies, discover recipes.
6. Return home (walk back, or via a consumable/portal item). Deposit loot, craft, upgrade buildings, **train** to convert XP into levels and skill points.
7. Repeat with stronger gear and spells; progress the main story to a boss.

---

## 4. Characters: races, classes, archetypes

### 4.1 Races (data: `data/races/*.tres`)

Each race defines: base attribute modifiers, base HP/stamina/mana modifiers, one passive trait, one racial spell, sprite set, and starting resistance profile.

**v0.1 races (placeholders, original):**

| Race | Feel | Attribute lean | Passive trait (example) |
|---|---|---|---|
| Human | Adaptable | Balanced, +XP gain | "Quick Learner": +5% XP |
| Bullhorn (large horned folk) | Tank | +Strength, +Vitality | "Thick Hide": flat damage reduction |
| Sylvan (forest folk) | Agile caster | +Dexterity, +Intellect | "Light Step": faster stamina regen when not attacking |

**Later races (stubs only, 5 more to reach 8):** design placeholders such as a stone-skinned race, a dusk-dwelling race, a small nimble race, a river folk, a fire-touched race. Create empty resource stubs so the character creator can list them as "Coming soon".

### 4.2 Classes (data: `data/classes/*.tres`)

Each class defines: weapon proficiencies, base combat style, starting spells, skill tree root, and attribute scaling.

**v0.1 classes (placeholders, original):**

| Class | Role | Style |
|---|---|---|
| Bruiser | Melee tank/damage | Heavy committed melee, block/parry focus, high stamina cost |
| Arcanist | Ranged caster | Spell rotations, mana + stamina, fragile |
| Prowler | Agile melee/stealth | Fast light attacks, backstab, dodge-focused |

**Later classes (stubs, 3 more to reach 6):** e.g. a support/healer, a ranged weapon user, a summoner.

### 4.3 Archetypes (race x class)

- Archetype = `race_id + class_id`. 3x3 = 9 in v0.1, 8x6 = 48 target.
- Each archetype gets its **own skill tree layout**: shared class tree + race-specific branch nodes, optionally an archetype override file for unique nodes.
- Generate the skill-tree UI from data, so a new pair needs only data.

### 4.4 Attributes

Six attributes (original naming, adjust freely): **Might, Agility, Vitality, Intellect, Spirit, Luck.**
- Might: melee damage, carry weight, heavy weapon requirement.
- Agility: attack speed, dodge i-frames window, crit chance.
- Vitality: max HP, stamina pool, physical resistance.
- Intellect: spell power, max mana.
- Spirit: mana/stamina regen, healing power, status resistance.
- Luck: loot rarity chance, crit damage.
- **Attributes gate equipment and spells** (each has an `attribute_requirements` dictionary). Equipping/casting below requirement is blocked or heavily penalized (decide: blocked, with a UI message).

---

## 5. Combat system (Souls-lite)

Top-down, real-time, 8-direction movement and aiming (mouse or right stick).

### 5.1 Resources
- **HP**, **Stamina**, **Mana**. All have max and regen values driven by stats.
- Stamina is spent on: attack, dodge roll, sprint, block-hold, some spells. Stamina regen pauses briefly after spending. At 0 stamina you cannot act until a minimum threshold regenerates.

### 5.2 Actions
| Action | Behavior |
|---|---|
| Light attack | Short wind-up, short recovery, low stamina |
| Heavy attack | Long wind-up, big damage, high stamina, can break enemy poise |
| Dodge roll | Direction roll, i-frames for first N ms, stamina cost, recovery lock |
| Block | Hold to reduce damage by shield/weapon value, drains stamina on hit |
| Parry | Block pressed within a short window before hit: negates damage, staggers enemy, opens riposte |
| Sprint | Optional, drains stamina |
| Spell cast | Uses equipped spell slot; cost mana (and/or stamina); has cast time and recovery |

**Commitment rule:** once an attack or cast starts, it plays through its wind-up and recovery. Only dodge-cancel at defined cancel windows (configurable per weapon). No animation cancelling otherwise.

### 5.3 Implementation requirements
- A **state machine** for the player: Idle, Move, Attack(light/heavy), Dodge, Block, Parry, Cast, Hurt, Stagger, Dead. Each state in its own script.
- **Hitboxes/hurtboxes** with `Area2D`. Attacks define frames where the hitbox is active (data-driven per weapon/attack: wind-up ms, active ms, recovery ms, damage multiplier, stamina cost, knockback, poise damage).
- **Poise system:** enemies have a poise bar; heavy hits and parries break it to cause stagger.
- **Telegraphs:** enemy attacks show a visible tell during wind-up (sprite flash, ground marker for AoE). Telegraph duration is data-driven per enemy attack.
- **Damage types:** physical plus elemental (Section 5.4). Damage formula lives in one place (`systems/combat/damage_calc.gd`) and is unit-tested.
- **Hit feedback:** hit-stop (a few frames), screen shake (small), damage numbers, flash on hit.

### 5.4 Elements and statuses
Elements (original set, tweakable): **Fire, Frost, Storm, Venom, Void.**
- Each enemy and armor has resistances/weaknesses per element.
- Status effects: Burn (DoT), Chill (slow), Shock (stamina drain), Poison (DoT + reduced regen), Stun/Stagger.
- Statuses stack rules in data. Status application chance scales with stat.

### 5.5 Spells and the ability bar
- **5 equippable spell slots** (hotkeys 1-5).
- Spell sources: race grants, class grants, **skill tree unlocks**, **spellbooks** (crafted/found, unlock universal spells if attribute requirements met), exploration rewards, boss drops.
- Spell data: id, element, cost (mana/stamina), cast time, cooldown, range, shape (projectile, cone, AoE, self, summon), damage coefficients, attribute requirements, status applied, tags (for combos).
- **Combos:** tag-based synergy (e.g. Frost then Shatter bonus). Keep v0.1 simple: 2 or 3 combo rules in data.
- v0.1 target: ~25 spells (not 300). Format must support hundreds.

### 5.6 Enemies and AI
- Enemy data: HP, poise, resistances, movement speed, attack list (with telegraphs), aggro radius, leash radius, loot table, XP.
- AI as a simple state machine or behavior tree: Idle/Patrol, Chase, Attack (choose from weighted list), Reposition, Stagger, Dead.
- **Aggro with multiple players:** target the highest recent damage / nearest; re-evaluate on a timer. Server-side.
- Archetype roles for v0.1 enemy set: melee grunt, ranged archer, fast skirmisher, tank, caster, plus **mini-bosses** and **2 bosses**.
- Bosses: multi-phase, arena-bound, unique telegraphs, health scales with number of players in the party (data curve).

---

### 5.7 Story-driven death mechanics (see `STORY_BIBLE.md` sections 3.0 and 4)
The player is one of the **Unlaid** and cannot stay dead. These rules apply in solo and co-op:
- **Death is a cost, not a game over.** On death the player rises at the last **Hearth** (home base or a lit shrine) after a short sequence.
- **Hollow Pressure** (world stat, host-owned, per zone): each Unlaid death raises the zone's Pressure. High Pressure darkens the zone, spawns more Hollowed, changes ambient audio, and can push the world toward the failure ending. Pressure falls through Rests and cleansing tasks.
- **Rest:** a Lantern-lit finishing blow on a Hollowed enemy lets its soul pass and lowers local Pressure slightly. Implement as a special finisher on staggered Hollowed, using the poise system.
- **Scars:** each death can add a **Scar**, a small debuff (e.g. -3% max HP, slightly reduced stamina regen) that persists until cleansed at the home base shrine for materials. Scars cost the character a hidden Memory Shard until cleansed.
- **Solo revive:** since no friend can revive you, you simply rise at the Hearth. Optionally a consumable, the **Last Ember**, lets you rise on the spot once, preventing the Pressure cost.
- **Co-op revive (Rekindle):** a downed player can be Rekindled by a teammate within a time window, preventing that death's Pressure and Scar cost.
- **Guardrail:** death must matter but never wreck a run. Scars are always cleansable.

### 5.8 Companion in combat (solo and co-op)
- The player can bring **one recruited ally at a time** into the field as an AI companion (swap at the home base). In co-op, each player may bring one, up to a world-wide cap (default 4 companions) to protect performance.
- Companion AI: simple state machine (Follow, Engage, Dodge/Block, Use ability, Retreat when low HP). It should **not** steal aggro or act as a second player; keep its damage modest so the player stays the main fighter.
- Each ally has one signature ability (data-driven), scales with their relationship level, and can be downed (they recover after combat; they never permanently die from normal combat, only through story events).
- Companions are **world-bound** (see 9.3): their relationship and state stay with the world, not the character.
- Toggle off in Settings for players who want to fight alone.

## 6. Progression

- **XP -> level conversion happens at a training location (home base).** Earning XP does not auto-level; the player must return and "train" to spend XP for levels, which grant skill points and attribute points. This reinforces the return-home loop.
- **Skill tree:** node graph per archetype. Nodes: passive stat boosts, spell unlocks, spell upgrades, trait modifiers. Features: connected paths with prerequisites, **search box**, tooltips, **respec** (costs a resource).
- **Attributes:** points allocated on level; gate gear and spells.
- **Equipment:** slots (weapon, offhand, head, chest, legs, boots, 2 accessories). Rarity tiers (Common, Uncommon, Rare, Epic, Legendary). **Upgrade** gear at crafting stations using materials.
- **Meals and potions:** consumables with timed buffs (cooked meals boost vitality/regen).
- **Achievements:** ~20 in v0.1, stored per character profile.

---

## 7. World and content structure

- **Handcrafted pixel-art open-ish region** composed of connected **zones** (separate scenes loaded as you cross zone edges or enter doors). Build with Godot `TileMapLayer` and hand-placed points of interest.
- **v0.1 starter region (original placeholder: "The Ashen Reach")**, 3 zones in a line:
  1. **Underroot Caves** (tutorial dungeon): teaches movement, stamina, dodge, a mini-boss.
  2. **Thornwick Village** (town hub #1): quest board, shop, 2 recruitable allies, training spot.
  3. **Greywood** (forest): open exploration, side quests, resource nodes, a hidden hideout, a main-story boss at the end.
- **Main story (placeholder, owner will rewrite):** The player awakens after a failed ritual, unable to die permanently, and must stop a spreading blight in the region. Final v0.1 boss is the blight's first herald. Keep story data in `data/quests/` and `data/dialogue/` so it can be swapped.
- **Quest types:** main story chain, side quests, and a **repeatable Notice Board** (original name) with difficulty tiers, bounties, and material rewards that scales endgame loop.
- **Resource nodes:** trees, ore, herbs, with respawn timers (host-authoritative).
- **Fast return:** consumable "Homeward Charm" item plus a one-way shortcut unlockable per zone.
- **Difficulty:** Normal / Hard chosen at world creation, immutable. Affects enemy HP/damage multipliers and loot.

---

## 8. Home base ("The Refuge", original placeholder)

A persistent, buildable area, **tied to the world (host's world), not to the character.**

### 8.1 Build order and features
1. **Workbench** (first priority): basic crafting.
2. **Storage chests**: shared inventory for the world.
3. **Water well, farm plots, quarry/lumber stations**: passive resource generation (tick while players are online, plus offline catch-up capped).
4. **Crafting stations:** forge (weapons/armor), alchemy table (potions), kitchen (meals), scribing desk (spellbooks).
5. **Trainer's yard:** where XP converts to levels/points.
6. **Ally houses/facilities:** investing materials in an ally's facility expands shop stock, unlocks crafting services, or opens farming plots.
7. **"Home upgrade" tiers:** raises area size, unlocks more buildings and follower slots.

### 8.2 Implementation notes
- Grid-based placement on a TileMap-like grid with a build menu. Placed buildings stored as `{building_id, grid_pos, tier, state}` in the world save.
- Building definitions in `data/buildings/*.tres`: cost, size, unlock requirement, produces, tick interval, interactions.
- **Host-only placement authority**, replicated to clients.
- Followers: NPCs assigned to buildings to produce/boost output.

---

## 9. Multiplayer (online co-op, up to 8)

### 9.0 Solo is the default
- A solo game runs through the **same code path** as multiplayer: the player is the host and there are zero peers. Do not write a separate single-player branch.
- All balance (enemy HP/damage, boss phases, loot) is tuned for **1 player first**; the player-count scaling curve in 9.4 only adds on top for 2-8 players.
- Solo support systems: allies can fight beside you (see 8 and the story bible), and dying has a self-revive path (see 5.7).
- Co-op menus (host/join) are reachable from the main menu but never block starting a solo game.

### 9.1 Model
- **Host-authoritative listen server.** One player hosts; others join by IP/port (v0.1) with an optional later relay/Steam-style lobby.
- Godot `MultiplayerAPI` + `ENetMultiplayerPeer`. Max peers = 8.
- **Server owns:** enemies, loot drops, resource nodes, quests/story flags, building state, damage resolution for NPCs.
- **Clients own (with server validation):** their own movement input and local prediction.
- **Use `MultiplayerSpawner` and `MultiplayerSynchronizer`** for player/enemy/projectile replication where it fits.
- Players send **inputs/intent** (attack pressed, dodge dir, cast slot, interact); the server validates (stamina, cooldown, range) and applies results.

### 9.2 Seamless drop-in/drop-out
- Players can join or leave at any time. On join: server sends world snapshot, spawns the player at home base or at a party member.
- On leave: server saves that character's profile data if hosting for them (see 10), despawns, and rebalances boss scaling.
- Handle host migration as **out of scope** for v0.1: if host leaves, the session ends.

### 9.5 How players actually connect (decision)
Home routers and many ISPs block direct inbound connections, so a plain "host and share your IP" setup often fails. Plan in stages:
1. **v0.1 (build this):** direct IP + port over ENet. For testing with friends, everyone installs a free virtual-LAN tool (**Tailscale** or **ZeroTier**) and the host shares their virtual IP. No extra code. Also works on the same Wi-Fi or with multiple local windows.
2. **Public release (later):** add a connection layer behind a `NetTransport` interface so the game code never depends on the method. Options: **Noray** (open-source relay + NAT punch-through for Godot, players join by room code), or **Steam / Epic Online Services** networking if releasing on those stores.
3. Keep all connection logic inside `NetManager` and one transport class so swapping methods does not touch gameplay code.

See also `STORY_BIBLE.md` for story, lore, endings, and the Hollow Pressure / Scar mechanics that tie into combat and saving, and `QUESTS.md` for every quest, objective, reward, flag and the Notice Board (Act I fully detailed, Acts II-IV outlined).

### 9.3 What travels vs. what stays (critical rule)
| Travels with the **character** (to any world they join) | Stays with the **world** (host's save) |
|---|---|
| Level, XP, attributes | Main story progress and quest flags |
| Skill tree choices | Recruited allies and their relationship state |
| Equipment worn | Buildings and home base layout |
| Personal inventory | World storage chests |
| Learned/equipped spells | Resource node state, defeated bosses |
| Personal achievements | World difficulty |

Design the data model around this split from M1 (`CharacterProfile` vs. `WorldSave`).

### 9.4 Scaling and anti-cheat basics
- Enemy HP/damage scale with connected player count (curve in data).
- Loot: per-player instanced rolls (avoid loot fights), or shared drops with a visible owner timer; pick **per-player instanced** for v0.1.
- Server validates all damage, pickups, crafting, and inventory changes. Never trust client-reported results.
- Keep packets small: sync positions at 20-30 Hz with interpolation; events via reliable RPC.

---

## 10. Saving and data model

- **CharacterProfile** (local to each player, `user://characters/<id>.json`): name, race, class, level, xp, unspent points, attributes, skill nodes, equipment, inventory, spells, spell bar, achievements, cosmetics.
- **WorldSave** (host, `user://worlds/<id>.json`): seed/id, difficulty, story flags, quests, allies + relationship values, buildings, world chests, node states, defeated bosses, day/time, version.
- Save format: JSON with a `version` field and a migration function per version bump.
- **Autosave** on zone change, on returning home, and every few minutes; manual save at home.
- Clients keep their own CharacterProfile; on join, the client sends the profile to the host for **validation** (reject impossible values), and the host holds a live copy during the session, sending the updated profile back on leave.
- Unit tests for save/load round trips and migration.

---

## 11. Art, animation, audio

### 11.1 Placeholder art (CC0 / permissive; verify each license on its page before use)
Primary source: **Kenney.nl** (CC0). Candidates:
- Tiny Dungeon (16x16 characters, dungeon tiles)
- Tiny Town (village/buildings)
- Roguelike / RPG Urban / Roguelike Characters packs (16x16)
- 1-Bit Pack (if a stylized look is wanted)
- UI Pack / Pixel UI Pack (menus)
- Optional: OpenGameArt CC0 items (check license per asset)

Record each pack in `ASSETS.md`: name, URL, license, files used. No asset without a recorded license.

### 11.1b Fallback: Claude Code draws the missing art
If CC0 packs do not cover a needed sprite (a specific enemy, boss, building, spell effect, or UI piece), Claude Code should **generate original pixel art itself** instead of stopping:
- Write small Python scripts (Pillow) under `tools/art/` that draw sprites pixel by pixel from palette-indexed arrays or simple shape code, and output PNG spritesheets to `assets/art/` in the spritesheet convention below (fixed frame size, rows = animations).
- Use one **shared palette file** (`tools/art/palette.json`, max 32 colors) so generated and pack art look consistent; run pack art through the same palette where practical.
- Keep generated art simple but readable: strong silhouettes, 1px outlines, 2-3 shade ramps. Anything generated is tagged `generated` in `ASSETS.md` so the owner can replace it later.
- Generate a **preview sheet** (`tools/art/preview.png`) of all generated sprites after each batch so the owner can review and request changes.
- Scripts must be deterministic (fixed seeds) and re-runnable so art can be tweaked by editing code.
- Order of preference: (1) CC0 pack sprite, (2) recolor/recombine a pack sprite, (3) generate from scratch.

### 11.2 Style target
Vibrant, handcrafted pixel-art world: saturated palette, readable silhouettes, soft ambient lighting via `PointLight2D`/`CanvasModulate`, parallax-free tight top-down view. The placeholders will not match this fully; **structure the art pipeline so replacing sprites is a file swap:**
- Spritesheet convention: one PNG per entity, fixed frame size, rows = animations (idle, walk, attack_light, attack_heavy, dodge, block, hurt, death), columns = frames, directions via flip or separate rows.
- Use `AnimatedSprite2D` or `AnimationPlayer` driven from data; **never hardcode frame numbers in logic**, use animation names and signals (`hit_frame`).
- Race/class visuals: base body + palette swap via shader (`data/palettes`) to avoid unique sprites per archetype. Equipment layers as separate sprites composited by slot.

### 11.3 Custom art spec (for the owner / commissioned artist later)
- Tile 16x16, character 16x24, boss 48x48 or larger, 4 or 8 directions (decide in M2), idle 4f, walk 6f, attacks 4-6f, dodge 4f, hurt 2f, death 6f.
- Palette cap: 32 colors per zone, shared global palette for UI.

### 11.4 Audio
- CC0 SFX (Kenney audio packs, freesound CC0) for hits, steps, UI. One looping track per zone and a boss track. Audio buses: Master, Music, SFX, UI with volume sliders.

### 11.5 UI
Pixel font (CC0), HUD: HP/Stamina/Mana bars, 5-slot spell bar, buff icons, minimap (optional), party list (up to 8 names + HP), damage numbers, interaction prompts, boss bar.

---

## 12. Controls (InputMap actions)

| Action | KB/Mouse | Gamepad |
|---|---|---|
| move_up/down/left/right | WASD | Left stick |
| aim | Mouse | Right stick |
| attack_light | LMB | X / West |
| attack_heavy | Hold LMB or RMB | Y / North |
| dodge | Space | B / East |
| block / parry | Hold Shift or RMB (decide) | LT |
| sprint | Left Ctrl (optional) | LS click |
| spell_1..5 | 1-5 | D-pad / face-modified |
| interact | E | A / South |
| inventory | I | Select |
| skill_tree | K | Start-menu |
| map | M | |
| pause | Esc | Start |

Everything rebindable via an options screen (post-v0.1 acceptable, but use InputMap actions from the start).

---

## 13. Non-goals for v0.1

- Web export, host migration, dedicated servers, matchmaking, voice chat.
- All 8 races, all 6 classes, 300 spells. (Data format supports them; content comes later.)
- Romance system beyond a relationship meter with 2 or 3 conversation unlocks (full romance paths later).
- Pets beyond 2 simple examples.
- Procedural generation.

---

## 14. Milestones (build in order)

Each milestone ends with: runs clean, committed, short note appended to `README.md` on what works.

**M0: Project skeleton**
Godot project, pixel settings, folder layout, autoload stubs, InputMap, `ASSETS.md`, `.gitignore`. Empty main menu scene that boots.
*Done when:* project launches to a menu with no errors.

**M1: Single-player movement and test room**
Player scene with 8-dir movement, camera, a test TileMap room with collision, placeholder sprite and animation hookup.
*Done when:* you can walk around a room with correct pixel-perfect rendering.

**M2: Combat core**
Player state machine, stamina, light/heavy attack, dodge with i-frames, block/parry, hitbox/hurtbox, damage calc (+ unit tests), one training-dummy enemy with poise and telegraph, hit feedback.
*Done when:* all actions consume stamina and feel committed; parry staggers the dummy.

**M3: Data layer and stats**
`DataRegistry`, resources for race/class/attributes, character creation screen (race + class + name), stat derivation, HP/stamina/mana HUD.
*Done when:* different race/class choices produce different stats and starting kits.

**M4: Enemies, AI, loot, items**
5 enemy types with AI and telegraphs, loot tables, inventory UI, equipment slots with attribute requirements, rarity tiers, pickups.
*Done when:* you can kill enemies, loot gear, equip it, and see stat changes.

**M5: Spells and elements**
Spell data, 5-slot bar, projectile/cone/AoE/self shapes, elements and resistances, statuses (burn, chill, shock, poison), 2 combo rules, ~10 spells.
*Done when:* an Arcanist can run a rotation and exploit a weakness.

**M6: Progression**
XP gain, **training-location conversion**, attributes, skill tree UI generated from data (search, prerequisites, respec), spellbook unlocks.
*Done when:* spending skill points changes abilities and respec works.

**M7: Zones and quests**
Zone loading/transitions, the 3 starter zones (blockout art OK), quest system, notice board, 1 mini-boss, 1 boss with phases, difficulty selection at world creation.
*Done when:* the starter chain is completable start to boss.

**M8: Home base and crafting**
Grid building, workbench, storage, farm/quarry passive production, crafting stations, recipes, gear upgrade, meals/potions, homeward charm.
*Done when:* a full gather -> return -> craft -> upgrade -> go out loop works.

**M9: Allies and relationships**
Recruitable allies with dialogue, relationship meter, unlocks (extra conversation, personal quest, facility upgrade), 2 simple pets.
*Done when:* investing in an ally changes shop/crafting options.

**M10: Save/load**
CharacterProfile + WorldSave with versioning, autosave, load menus, round-trip tests.
*Done when:* quit and reload restores character and world exactly.

**M11: Online co-op (optional mode; build only after the solo game M0-M10 is complete)**
Host/join UI, ENet, `MultiplayerSpawner`/`Synchronizer`, server-authoritative combat and loot (per-player instanced), enemy/boss scaling by player count, drop-in/out, profile validation on join, party HUD, up to 8 peers.
*Done when:* 3+ instances (local testing with multiple windows) can play together, join/leave mid-session, and character progress persists across worlds while world state stays with the host.

**M12: Polish and content pass**
Audio, screen shake and hit-stop tuning, options menu, rebinding, achievements (~20), balance pass, bug fixing, replace placeholder art where possible, build exports (Win/Linux/Mac).

---

## 15. Testing and quality

- **Unit tests** (GUT addon or plain headless scripts in `tests/`): damage calc, stat derivation, attribute gating, loot table rolls, save/load and migration, quest state transitions.
- **Headless smoke test:** `godot --headless --path . --quit` must exit with no script errors in CI/local before each commit.
- **Netcode test:** a script that launches a host and 2 clients (`--headless` or windowed), joins, runs a scripted fight, and checks state consistency.
- **Performance targets:** 60 FPS with 8 players and 40 active enemies on a mid-range PC.
- Log with a simple logger; add a debug overlay (F3) showing FPS, ping, entity counts.

---

## 16. Conventions for Claude Code

- Static typing, `class_name` on reusable scripts, signals up / calls down.
- One responsibility per script; keep scripts under ~300 lines.
- No magic numbers: tunables go in data resources or a `constants.gd`.
- Comment the *why*, especially in netcode.
- When adding content, add data files only; if code changes are needed for content, refactor the system first.
- Update `README.md` (how to run, how to test, how to host/join) at every milestone.
- If blocked inside a milestone, record in `OPEN_QUESTIONS.md` and continue with the simplest sensible default. At the end of each milestone, stop and ask the owner before moving on (see Ground rule 6).

---

## 17. Open decisions for the owner (answer before or during M0-M2)

1. Final game title, setting, and story (the current ones are placeholders).
2. Character sprite size (16x24 vs 32x32) and 4 vs 8 facing directions. **Delegated to Claude Code:** in M1, build a small test of both sizes using free-pack and generated sprites, produce a side-by-side preview, recommend one, and ask the owner to confirm before continuing.
3. Block and parry on one button or separate buttons.
4. ~~Online connectivity~~ Decided: direct IP + Tailscale/ZeroTier for v0.1, relay or store networking later (Section 9.5).
5. Aesthetic direction for the final custom art (commission, self-drawn, or asset-pack kitbash).
6. Release target: itch.io, Steam, or personal project only.
