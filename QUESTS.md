# QUESTS AND MISSIONS: Hollowmere (working title)

Companion to `GAME_PLAN.md` and `STORY_BIBLE.md`. Act I (the Ashen Reach, v0.1) is fully detailed. Acts II-IV are outlines. All names are original placeholders. Where this file and the story bible disagree, **the story bible's Laws of Death win**; flag the conflict in `OPEN_QUESTIONS.md`.

---

## 0. How to read this file

### 0.1 Quest entry template (every quest follows this)
```
### <ID> <Title>
- Type: Main | Side | Personal (ally) | Notice Board | Hidden
- Zone / Giver: where it starts and who gives it
- Requires: prior quests, flags, relationship level, level range
- Summary: one or two lines
- Objectives: ordered list; each has an ID (O1, O2...), a type, and a target
- Choices and flags: branches and the world/character flags they set
- Rewards: XP, items, unlocks, flags
- Key scenes: written dialogue or beats
- Edge cases: solo, co-op, death, failure
```

### 0.2 Objective types (data-driven; add new types in one place)
| Type | Meaning |
|---|---|
| `reach` | enter an area or trigger volume |
| `talk` | speak to an NPC (dialogue node id) |
| `kill` | defeat N of an enemy type or a named enemy |
| `rest` | perform a Rest finishing blow on N Hollowed (lowers Pressure) |
| `collect` | gather N of an item (drop, node or container) |
| `deliver` | bring an item to an NPC or location |
| `interact` | use an object (lever, shrine, ledger, door) |
| `survive` | last a duration or clear N waves |
| `escort` | keep an NPC alive while they travel |
| `craft` | make a recipe at a station |
| `build` | place or upgrade a home-base structure |
| `choose` | a story decision that sets flags |
| `discover` | find a codex-worthy location, ledger or Memory Shard |

### 0.3 Global quest rules
- **States:** `locked`, `available`, `active`, `complete`, `failed`. A quest can have a `failed` state only if the entry says so; most quests cannot be failed, only abandoned and retaken.
- **IDs:** `ACT1_MQ01` (main), `ACT1_SQ01` (side), `ACT1_PQ_MAREN_01` (personal), `ACT1_NB_*` (notice board), `ACT1_HQ_*` (hidden).
- **Levels:** Act I covers character levels about 1-10. Show a recommended level on every quest; never hard-lock by level.
- **XP:** shown in the entry as a number; tune in data, not code. Remember XP only becomes levels at the training yard.
- **Death:** dying never fails a quest. Quest-critical NPCs cannot be killed by the player or by Hollowed unless the entry says so.
- **Co-op:** the **host's world** owns quest state. Objectives are shared (any player's kill counts). Rewards are given **per player**. Choices (`choose`) are resolved by host, or by vote if the entry says `vote`.
- **Solo:** every quest must be completable with one player and one optional AI companion.
- **Pressure:** many quests change Hollow Pressure (see `STORY_BIBLE.md` section 4). Entries note this as `Pressure -N` or `+N`.
- **Placeholder text:** mark anything unfinished with `TODO_STORY`.

### 0.4 Voice tags (keep dialogue consistent)
| NPC | Voice |
|---|---|
| Maren Thorne | blunt, dry, warm underneath; short sentences |
| Brother Tamsin Rook | careful, apologetic, overexplains when afraid |
| Korrin Dunehorn | few words, honest, metaphors from metalwork |
| Elder Halsey Pruitt | formal, tired, suspicious; speaks for the village |
| Pip | quiet, literal, says unsettling true things |
| Edrin Vale | soldier's economy; gentle under strain; slips into old drill language |
| Rootwife Sorrel (Act II ally, mentioned early) | slow, musical, speaks in short songs and proverbs |

---

## 1. Act I: The Waking (levels 1-10)

### 1.1 Act I flow at a glance
1. **Underroot Caves** (MQ01): tutorial dungeon, first death, mini-boss.
2. **Thornwick Village** (MQ02-MQ04): hub, allies, the first truths.
3. **Greywood** (MQ05-MQ08): exploration, factions, outposts, Edrin Vale.
4. **Return and aftermath:** home base grows, personal quests continue, the Act I teaser sets up Act II.

### 1.2 NPC roster (Act I)
| NPC | Role | Location | Recruitable? | Notes |
|---|---|---|---|---|
| Maren Thorne | herbalist-innkeeper | Thornwick inn | Yes (ally 1) | Alchemy facility |
| Brother Tamsin Rook | last Lantern Warden | Thornwick cellar | Yes (ally 2) | Scribing facility |
| Korrin Dunehorn | exiled Bullhorn smith | Thornwick, dead forge | Yes (ally 3) | Forge facility |
| Elder Halsey Pruitt | village head | Thornwick hall | No | Standing changes how the village treats you |
| Pip | child who hears the Hollow | Thornwick edge | Not in v0.1 | Recurring, key to Act IV |
| Sorrel's Rootwives | hedge-witches | Greywood camp | No (v0.1) | Teach Cleansing; faction standing |
| Edrin Vale | Warden-Captain, first Unlaid | Greywood keep | No | Boss |
| The Tally-Hunter (Garrick Voss) | bounty hunter | roams Thornwick/Greywood | No | Side quest antagonist |

---

## 2. MAIN QUESTS (ACT I)

### ACT1_MQ01 The Waking
- **Type:** Main (tutorial)
- **Zone / Giver:** Underroot Caves, automatic start
- **Requires:** new game
- **Summary:** You wake in a stone cradle, learn to move and fight, die once on purpose, and claw your way out past a Hollowed gravedigger.
- **Objectives:**
  - O1 `interact` the cradle lantern (picks up the **Cradle Lantern**, a starting item that powers Rests)
  - O2 `reach` the crypt hall (teaches movement and camera)
  - O3 `kill` 3 crawling Hollowed (teaches light attack and stamina)
  - O4 `interact` the cracked wall inscription (first Codex entry)
  - O5 `kill` 2 Hollowed grunts using dodge (teaches dodge roll i-frames)
  - O6 `survive` the **scripted death**: a collapse lands on you; you wake at the first Hearth with a message that death is not the end (no Pressure cost, no Scar; this is the tutorial for resurrection)
  - O7 `kill` 1 shielded Hollowed (teaches block and parry)
  - O8 `rest` 1 staggered Hollowed using the Cradle Lantern (teaches Rest and Pressure)
  - O9 `kill` **The Gaunt Sexton** (mini-boss)
  - O10 `collect` **Sexton's Key**
  - O11 `reach` the stairwell exit
- **Choices and flags:** none. Sets `act = 1`, `tutorial_done = true`, `boss_defeated += gaunt_sexton`.
- **Rewards:** 120 XP, Memory Shard 01 ("The Cradle"), starting gear choice by class, Hearth unlock (first Hearth).
- **Key scenes:**
  - *Waking.* Screen black. Distant dripping. Text: *"Cold stone. Your lungs remember a breath you did not take."* The player stands. In co-op, each player wakes in their own cradle; unoccupied cradles show a carved name (the other Unlaid: SORREL, TOBIAS, LYSA, ANSELM, MIREILLE, HALDOR; Edrin's cradle is empty and scratched out).
  - *Inscription (O4).* Carved: *"EIGHT BREATHS TAKEN. EIGHT BREATHS KEPT. WHEN THE LAST IS LOST, REMEMBER US."*
  - *Scripted death (O6).* Ceiling gives way. Brief white-out. A voice that is not a voice: *"Again."* You rise by the lit Hearth. A short tooltip explains: dying raises Pressure and may leave Scars, but the tutorial death is free.
  - *The Gaunt Sexton.* He digs in an empty crypt, muttering a half-remembered litany: *"Row nine, plot four. Row nine, plot four."* Phase 1: shovel sweeps and grave-pit AoE (telegraphed ground circles). Phase 2 at 50%: he calls crawlers from the pits. On Rest, he whispers *"...plot four. Thank you."* and drops the key.
- **Edge cases:**
  - Solo and co-op share the same scripted death; in co-op all players die together and rise together.
  - If a player skips ahead and dies naturally before O6, skip the scripted death and mark O6 complete.
  - The Gaunt Sexton can be killed instead of Rested; Resting gives a bonus (-3 Pressure and a bonus Memory Shard fragment); either way the quest completes.
  - Co-op: the boss HP scales per player count (see `GAME_PLAN.md` 9.4).

### ACT1_MQ02 The Quiet Valley
- **Type:** Main
- **Zone / Giver:** Thornwick Village gate, automatic on arrival
- **Requires:** MQ01 complete
- **Summary:** The village won't open its gate to the Unlaid. Prove you can help by cleansing the Hollowed nest that silenced the valley's birds.
- **Objectives:**
  - O1 `reach` Thornwick gate (cutscene: Elder Halsey and guards confront you)
  - O2 `talk` Elder Halsey (dialogue branches)
  - O3 `survive` a Hollowed wave at the gate (3 waves; teaches the Notice Board's combat style)
  - O4 `talk` Elder Halsey again (he lets you in, grudgingly)
  - O5 `reach` the Ghostcap Field outside the village
  - O6 `rest` the Hollowed nest (4 Hollowed plus a nest object that must be Rested)
  - O7 `talk` Elder Halsey (reports the birds' return, minor)
- **Choices and flags:**
  - In O2 the player chooses how to answer Halsey: **Honest** ("We are the Unlaid. We don't know why."), **Defiant** ("Open the gate."), or **Humble** ("We'll earn our place."). Sets `halsey_standing` (-1, -2, +1). This only changes tone and one later price; no path blocks content.
  - Sets `act1_nest_rested = true`.
- **Rewards:** 150 XP, 40 coin-equivalent (Thornwick Marks), access to the inn, shop, and training yard, unlocks the Notice Board, Pressure -4 in Thornwick Valley.
- **Key scenes:**
  - *The gate.* Halsey stands above the barricade with a lantern. *"Back. We don't open to Tally."* A guard adds, quietly: *"My grandmother's grandmother wrote about the ones who don't stay dead."* The player answers (see Choices).
  - *Honest branch.* Halsey: *"You say you don't know. That is either honesty or a good lie."*
  - *After the wave.* Halsey, lowering the lantern: *"The gate opens. Not for you. For my people, who watched you bleed and kept standing."*
  - *Nest (O6).* Pale ghostcap grows in rings, humming faint, tuneless notes. A Hollowed child-shaped figure stands in the center with its back turned, not attacking. Resting it requires the Cradle Lantern held for 3 seconds. The humming stops. Pressure -4.
- **Edge cases:**
  - In co-op, each player may answer Halsey; the **host** decides the recorded choice (or vote if the group enables it).
  - The Hollowed wave is Pressure-neutral if all players survive; each death adds the normal Pressure cost.
  - If the player has the Last Ember (see plan 5.7), it works here.

### ACT1_MQ03 A Name on the Stone
- **Type:** Main (introduces Maren)
- **Zone / Giver:** Thornwick inn, Maren Thorne
- **Requires:** MQ02 complete
- **Summary:** Maren's son Wyn vanished in Greywood. She asks you, bluntly, to find whatever is left.
- **Objectives:**
  - O1 `talk` Maren at the inn (she offers a room and a hard bargain)
  - O2 `reach` the Greywood edge (zone transition; first look at fog and forgotten trees)
  - O3 `discover` the half-drowned chapel
  - O4 `kill` the chapel's Hollowed guardians (a former choir)
  - O5 `collect` **Wyn's Satchel** and **a carved whistle** (the whistle is a quest item that also feeds Maren's personal quest)
  - O6 `deliver` the satchel to Maren
- **Choices and flags:**
  - In O6 Maren asks: *"Was he... was there anything of him left?"* The player can answer **Truthfully** (the whistle carried an echo of his humming), **Gently** (a half-truth), or **Not at all** (lie). Sets `maren_trust` (+2, +1, -1). Truthful unlocks Maren's relationship faster.
  - Sets `maren_recruitable = true`.
- **Rewards:** 140 XP, Maren becomes a recruitable ally (Alchemy facility available at relationship Lv1), 1 Memory Shard fragment, **Chapel Charm** (accessory: +small spirit).
- **Key scenes:**
  - *Maren, first meeting.* She doesn't look up from the bar. *"If you're the Tally, you can pay in coin or in killing. Which are you?"*
  - *The ask.* *"My boy went into Greywood for ghostcap. Thirteen years old. He had the sense of a goat. Find what's left. I don't care what it is."*
  - *The whistle (O5).* Picking it up plays a thin, tuneless echo of a child humming. The tune drifts apart.
  - *Delivery (O6).* Maren holds the satchel a long moment. *"He always packed too much."* She doesn't cry. She pours you a drink instead.
- **Edge cases:** if the player brings the whistle to Tamsin first, he identifies it as a "residual echo", which is a lore beat but does not change the quest.

### ACT1_MQ04 What the Cellar Knows
- **Type:** Main (introduces Tamsin)
- **Zone / Giver:** Thornwick cellar, Brother Tamsin Rook
- **Requires:** MQ02 complete (can be done before or after MQ03)
- **Summary:** A frightened Warden trades the first piece of truth for protection on a trip to a hidden outpost.
- **Objectives:**
  - O1 `discover` the sealed cellar door (hinted by Pip's chalk drawings)
  - O2 `talk` Tamsin through the door
  - O3 `interact` the cellar lock (requires **Sexton's Key**)
  - O4 `talk` Tamsin (he tells the first truth, see below)
  - O5 `escort` Tamsin to the Greywood Warden outpost (he is slow and nervous; short fights along the road)
  - O6 `interact` the outpost's vault (retrieves **Warden Ledger I** and a **Lantern Fragment**)
  - O7 `talk` Tamsin (he reads the ledger)
- **Choices and flags:**
  - After O7 the player chooses how to treat Tamsin's confession that he was an apprentice during the rite: **Comfort**, **Press**, or **Warn**. Sets `tamsin_truth_level` (+1 in all cases; Press reveals one extra lore line but lowers `tamsin_trust`).
  - Sets `ledgers_found += ledger_01`.
- **Rewards:** 160 XP, Tamsin becomes a recruitable ally (Scribing facility), **Lantern Fragment** (upgrade to the Cradle Lantern, increasing Rest speed), Memory Shard 02.
- **Key scenes:**
  - *Through the door.* *"Please. I only bring bad news. Go away."* Then, after a beat: *"...Is the lantern in your hand lit?"*
  - *The first truth (O4).* *"There were eight of you. We wrote it down. We wrote down everything, except what it cost."*
  - *The ledger (O7).* A page reads: *"Day 4 of the Vigil. The eight are asleep and well. The blight does not retreat. It pauses. As if listening."* Tamsin: *"It was listening. We never asked what to."*
- **Edge cases:** Tamsin must not die during the escort; if he falls, he is Downed and revives when combat ends. In co-op, he follows the host.

### ACT1_MQ05 Salt and Song (main thread)
- **Type:** Main (faction introduction)
- **Zone / Giver:** Greywood, the Rootwife camp (first visit)
- **Requires:** MQ03 or MQ04 complete
- **Summary:** The Rootwives tend the forest edge with songs and salt. They offer a way to cleanse Hollow ground, and a first hint that the Hollow is grief.
- **Objectives:**
  - O1 `discover` the Rootwife camp
  - O2 `talk` the camp's elder, **Marit Oakhand** (she speaks for Sorrel in her absence)
  - O3 `collect` 3 **Cleansing Salt** from marked shrines (side route through Greywood)
  - O4 `deliver` the salt to the camp's cleansing circle
  - O5 `interact` the cleansing circle with the Cradle Lantern (learn **Cleansing**: clears Hollow ground over time)
  - O6 `talk` Marit (first hint: *the Hollow is grief*)
- **Choices and flags:** none; sets `rootwives_standing +10`.
- **Rewards:** 140 XP, **Cleansing** ability (a home base and field tool; reduces Pressure when used on marked ground), 1 recipe (**Cleansing Salt**), Memory Shard 03.
- **Key scenes:**
  - *Marit.* *"You carry the lantern like it burns. Hold it like it is warm."*
  - *The hint.* *"We don't fight what grieves. We keep it company until it is tired."*
- **Edge cases:** the three salt shrines can be done in any order; the last one is guarded by a mini-group of Hollowed.

### ACT1_MQ06 Scrapfang Hollow
- **Type:** Main (dungeon)
- **Zone / Giver:** Greywood, Marit's warning and a map piece from Tamsin
- **Requires:** MQ05 complete
- **Summary:** A band of scavengers calling themselves the Scrapfang have made a hideout in a hollow tree. They hold the only safe route to the old Warden keep.
- **Objectives:**
  - O1 `discover` the false cave (a misleading turn that leads to a dead end and a few Hollowed)
  - O2 `reach` the real Scrapfang hollow
  - O3 `kill` the scavenger chief **Brannoch Scrap** (human mini-boss) **or** `talk` to him (see choice)
  - O4 `collect` the **Keep Route Map**
  - O5 `reach` the road to the Warden keep
- **Choices and flags:**
  - `choose` after reaching the chief: **Fight** (kill the scavengers), **Bargain** (pay 60 Marks; they leave), or **Recruit** (requires `halsey_standing >= 1`; they become Thornwick laborers who later staff a home base building). Sets `scrapfang_fate` (`killed`, `paid`, `recruited`).
- **Rewards:** 180 XP, **Keep Route Map**, mini-boss loot (Scrap-plate armor piece), Pressure -2 if killed or paid, no Pressure change if recruited.
- **Key scenes:**
  - *The chief.* Brannoch (gravelly, cheerful): *"Ghosts are cheap. Ghosts with lanterns, though. Those are rare."*
  - *Recruit.* *"Work, you say? ...Alright. But we eat first."*
- **Edge cases:** all three paths must give the map; recruiting changes later home base options only.

### ACT1_MQ07 The Road to the Vigil
- **Type:** Main
- **Zone / Giver:** Greywood, automatic after MQ06
- **Requires:** MQ06 complete
- **Summary:** The road to Edrin's keep is littered with signs of a century-long solitary war. You learn who Edrin was, and what he has been doing.
- **Objectives:**
  - O1 `reach` the first guard post (ruined)
  - O2 `discover` 3 **Vigil Markers** (small cairns Edrin built, each with a carved tally)
  - O3 `interact` the keep gate (sealed; needs **Vigil Key**)
  - O4 `collect` the **Vigil Key** (from the Warden outpost's secondary vault, unlocked via Ledger I)
  - O5 `talk` to Pip (he appears silently at the road's edge and tells you something strange)
- **Choices and flags:** none; sets `ledgers_found += ledger_02, ledger_03`.
- **Rewards:** 130 XP, Vigil Key, Memory Shard 04, 2 Warden Ledgers.
- **Key scenes:**
  - *Vigil Markers.* Each carved tally ends with a short note: *"Day 3,212. Still holding."* *"Day 9,640. Sorry."* *"Day 36,500. Not sure what for."*
  - *Pip.* *"The man at the keep keeps counting. He is very tired. Don't make him count you."*

### ACT1_MQ08 The Unrested
- **Type:** Main (boss)
- **Zone / Giver:** Greywood, the Warden keep
- **Requires:** MQ07 complete
- **Summary:** Edrin Vale, the first of you to wake, has been fighting alone for a hundred years. He remembers you, and he is slowly becoming Hollow.
- **Objectives:**
  - O1 `reach` the keep courtyard
  - O2 `talk` Edrin (long scene)
  - O3 `kill` Edrin Vale, phase 1 (a controlled duel; he is protecting you from himself)
  - O4 `kill` Edrin Vale, phase 2 (the Hollow takes over; arena spawns Hollowed)
  - O5 `choose` his fate
  - O6 `talk` Edrin (last words)
- **Choices and flags (the first major story flag):**
  - **Grant rest** (Rest finishing blow: he dies permanently). Sets `edrin_fate = rested`, Pressure -8, unlocks the **Hearth's Return** requirement.
  - **Bind him** (a sealing rite: he lives on, Hollowed, and returns as a hostile boss in Act II or III). Sets `edrin_fate = bound`. Makes the **Hearth's Return** ending impossible.
  - Default if the player does neither (leaves him alive): `edrin_fate = unresolved`; he remains at the keep.
- **Rewards:** 350 XP, **Edrin's Broken Blade** (quest item used in Korrin's personal quest), Memory Shards 05-06, **Warden Captain's Cloak** (armor), unlocks Act II teaser.
- **Key scenes:**
  - *Edrin, first words.* He is at the gate, tally stone in hand. *"You're late. ...No, I'm early. Or I'm... What day is it? Count it for me, would you."*
  - *He recognizes you.* *"Eight cradles. Eight breaths. You woke up. I woke up first. I think."* A pause. *"I think I'm the only one who woke. Is that right? Are you real?"*
  - *Phase 1.* He fights with military discipline, murmuring drill phrases: *"Shield. Strike. Shield."* He pulls his strikes slightly. He tells you, mid-fight: *"I can hold it. For a bit. Don't let me stop."*
  - *Phase 2 transition.* His voice splits. The Hollow wells up from his armor. *"Run. No. ...no, you can't, can you?"*
  - *Last words (if rested).* *"Eight. There were eight of us. I counted them every day. The Queen... didn't die. She's still at... the Sunken Lantern."* Beat. *"Tell her I held."*
  - *Last words (if bound).* He is silent. The seal burns blue. The only sound is a faint count of days, fading.
- **Edge cases:**
  - Co-op: the choice is a **vote** (host breaks ties).
  - Solo: one companion present may comment; Maren, Tamsin or Korrin each have a unique line on the choice.
  - Boss scales with player count and with the world's Hard difficulty.
  - If Pressure in Greywood is very high, phase 2 adds extra Hollowed; if low, phase 2 is shorter.

---

## 3. ALLY AND PERSONAL QUESTS (ACT I)

### 3.1 Relationship levels (0-5)
Relationship rises through: finishing the ally's intro quest, talking at the home base (once per in-game day), gifts they like, doing their personal quests, and bringing them into combat (small gain per fight). Each level unlocks the next layer.

| Level | Unlocks |
|---|---|
| 1 | Recruited; facility opens at tier 1; basic conversation set |
| 2 | Second conversation set; extra shop stock or recipes |
| 3 | **Personal quest** unlocks |
| 4 | Combat signature ability gets an upgrade; deeper lore dialogue |
| 5 | Facility tier 2; final personal-quest epilogue scene |

### ACT1_PQ_MAREN_01 Wyn's Whistle
- **Type:** Personal (Maren, level 3)
- **Requires:** MQ03 complete; Maren relationship Lv3
- **Summary:** The whistle you found carries an echo of Wyn's voice. Maren must decide whether to keep it or let it go.
- **Objectives:**
  - O1 `talk` Maren (she asks you to bring the whistle to the Rootwives' circle)
  - O2 `deliver` the whistle to the Rootwife cleansing circle
  - O3 `interact` the circle (hear the full echo: Wyn humming a half-finished lullaby)
  - O4 `choose` **Let it go** or **Keep it**
  - O5 `talk` Maren
- **Choices and flags:**
  - **Let it go:** the echo fades with a sound like a breath. Sets `maren_son_quest = released`. Maren grieves, then heals. Unlocks Cleansing Draughts at Lv5.
  - **Keep it:** the echo stays in the whistle. Sets `maren_son_quest = kept`. She stays haunted but gains a unique buff-potion recipe. Cleansing Draughts are unlocked later.
- **Rewards:** 150 XP, relationship +2, recipe (Echo Tincture if Kept, Calm Tea if Released), Memory Shard 07.
- **Key scenes:**
  - *Maren, after the echo.* Quietly: *"That's his lullaby. He never learned the end of it."* Beat. *"Neither did I."*
  - *Let it go.* She holds the whistle to her lips and doesn't blow it. *"Go on, then. You were always late for supper."*
  - *Keep it.* *"I know what it costs. I'll pay it. Don't tell me it's unhealthy."*
- **Edge cases:** the story bible's Hearth's Return requires **all personal quests completed**, not a specific branch; but the epilogue and Wyn's return scene vary by `maren_son_quest` (see `STORY_BIBLE.md` section 16, question 5).

### ACT1_PQ_TAMSIN_01 The Cellar Ledger
- **Type:** Personal (Tamsin, level 3)
- **Requires:** MQ04 complete; Tamsin relationship Lv3
- **Summary:** Tamsin finally admits he **knew** the rite's cost and stayed silent. You decide what he owes.
- **Objectives:**
  - O1 `talk` Tamsin (he asks you to follow him; he is shaking)
  - O2 `reach` the hidden Warden archive under the cellar
  - O3 `interact` the Ledger of Costs (reveals the rite's price: "one mortality, held in trust")
  - O4 `talk` Tamsin (confession)
  - O5 `choose` how to respond: **Forgive**, **Shame**, or **Expel**
- **Choices and flags:**
  - **Forgive:** `tamsin_truth_level = 3`, relationship +2, he shares everything.
  - **Shame:** `tamsin_truth_level = 2`, relationship +1; he works harder but shares less.
  - **Expel:** he leaves the village. `tamsin_truth_level = 1`; you lose the Scribing facility until you find him again in Act II. Sets `tamsin_alive = true` (he is not killed). **Blocks** the Hearth's Return only if he is not recovered by Act IV.
- **Rewards:** 170 XP, a **Warden Ledger** (the Ledger of Costs), Memory Shard 08 (only on Forgive or Shame), **Scribing tier 1.5** (unlocks one extra spellbook recipe).
- **Key scenes:**
  - *Confession.* *"I held the lamp while Corvane read the words. I saw the Queen's face when she understood. I did not say a word."*
  - *Forgive.* Tamsin, breaking: *"I have been afraid of you since the cradle opened. It was never you I was afraid of."*

### ACT1_PQ_KORRIN_00 A Cold Forge
- **Type:** Personal (Korrin, introduction)
- **Zone / Giver:** Thornwick, the dead forge
- **Requires:** MQ02 complete
- **Summary:** Korrin keeps a cold forge and an old grudge. He won't work for people who won't earn it.
- **Objectives:**
  - O1 `talk` Korrin (he refuses to speak at first)
  - O2 `collect` 5 **Coal** from the Ghostcap Field mine
  - O3 `collect` 3 **Iron Scrap** (from Hollowed armor)
  - O4 `deliver` both to the forge
  - O5 `craft` a simple blade together (tutorial for crafting)
  - O6 `talk` Korrin (he joins)
- **Choices and flags:** none; sets `korrin_recruited = true`, `korrin_blade_quest = open`.
- **Rewards:** 130 XP, Korrin becomes a recruitable ally (Forge facility tier 1), a basic weapon of your class.
- **Key scenes:**
  - *Korrin, refusing.* *"Cold iron is honest. Hot iron lies to you till it cools."*
  - *After the forge lights.* He runs a thumb along the new blade. *"Not bad. For a ghost."*

### ACT1_PQ_KORRIN_01 The Blade of the Vigil
- **Type:** Personal (Korrin, level 3)
- **Requires:** MQ08 complete (you hold **Edrin's Broken Blade**); Korrin relationship Lv3
- **Summary:** Reforge the blade of the first Unlaid. What it becomes depends on how Edrin ended.
- **Objectives:** O1 `talk` Korrin, O2 `deliver` the blade, O3 `collect` 3 **Warden Steel** (from keep ruins), O4 `craft` the reforging, O5 `choose` the name and inscription (cosmetic).
- **Choices and flags:**
  - If `edrin_fate = rested`: the blade becomes **Edrin's Mercy** (a Rest-focused weapon that restores a little stamina on Rests). Sets `korrin_blade_quest = reforged`.
  - If `edrin_fate = bound`: the blade becomes **Edrin's Vow** (a stronger, riskier weapon that adds Hollow damage and a small Pressure cost per use). Sets `korrin_blade_quest = reforged`.
  - If `edrin_fate = unresolved`: Korrin refuses until the player decides.
- **Rewards:** 180 XP, the legendary-tier weapon, relationship +2.
- **Key scenes:** *Korrin, at the anvil.* *"A blade remembers who held it. Better it remembers well."*

### 3.2 Level 5 facility upgrades (summary)
- **Maren:** Alchemy tier 2, unlocks **Cleansing Draughts** (remove one Scar).
- **Tamsin:** Scribing tier 2, a ritual that reads old-tongue inscriptions and recovers lost Memory Shards.
- **Korrin:** Forge tier 2, legendary upgrade tier.

---

## 4. SIDE QUESTS (ACT I)

Each is short (10-25 minutes) and fits one zone.

### ACT1_SQ01 The Last Bell
- **Zone / Giver:** Thornwick, the bell tower (Elder Halsey mentions it)
- **Summary:** The bell has been silent since the first Hollowed attack. Ringing it draws Hollowed.
- **Objectives:** O1 `reach` the tower, O2 `interact` the bell (Hollowed spawn), O3 `survive` 2 waves, O4 `choose` how to use it.
- **Choices:** **Disable it** (cut the rope; safe), **Use it as a trap** (lure and kill Hollowed for loot; small Pressure risk), **Ring it for the village** (it comforts people, `halsey_standing +1`, but pulls one wave every night for 3 nights).
- **Rewards:** 90 XP, **Bell Clapper** (crafting material), village goodwill.
- **Key scene:** Halsey: *"My mother rang that bell the night the first of them came. I'd like it to ring again. I'd also like not to die."*

### ACT1_SQ02 Forgotten Names
- **Zone / Giver:** Thornwick, a woman named **Edda Marsh**
- **Summary:** Edda forgets her husband's name a little more each day. You help her write it down.
- **Objectives:** O1 `talk` Edda, O2 `collect` 3 **Letters** from her home (search drawers), O3 `deliver` the letters, O4 `talk` Edda.
- **Choices:** none; the quest teaches **Forgetting** (a Hollow effect where names vanish).
- **Rewards:** 80 XP, Codex entry ("Forgetting"), small Pressure -1 in Thornwick.
- **Key scene:** Edda: *"Tell me his name again. ...No. Write it down. Write it large."*

### ACT1_SQ03 Songs for the Tired
- **Zone / Giver:** Greywood, the Rootwife camp (Marit)
- **Summary:** The Rootwives need three lullabies to calm a restless Hollow patch. Fragments survive only as echoes in Hollowed who once sang them.
- **Objectives:** O1 `talk` Marit, O2 `rest` 3 specific Hollowed singers (each yields a verse), O3 `deliver` the verses to the camp, O4 `interact` the circle (the song plays).
- **Rewards:** 110 XP, `rootwives_standing +10`, **Lullaby Charm** (reduces Hollow status buildup).
- **Edge cases:** the verses are original text; mark `TODO_STORY` and have the owner write the actual lyrics.

### ACT1_SQ04 The Tally-Hunter
- **Zone / Giver:** Thornwick, a notice nailed to the board: "Wanted: Tally, living or otherwise."
- **Summary:** A bounty hunter, **Garrick Voss**, tracks you. You can fight him, talk to him, or recruit his silence.
- **Objectives:** O1 `discover` the bounty notice, O2 `reach` the hunter's camp, O3 `talk` or `kill` Garrick, O4 `choose` his fate.
- **Choices:**
  - **Kill him:** `garrick_fate = dead`, small Pressure +1, rare loot.
  - **Spare and send away:** `garrick_fate = gone`; he returns in Act II as a rival.
  - **Show him a death:** let him watch you die and rise (the quest asks you to deliberately fall); `garrick_fate = witness`. He swears to keep the secret and becomes a minor informant in Act II.
- **Rewards:** 120 XP, a **Hunter's Cloak**.
- **Key scene:** Garrick: *"Eight hundred marks for the ones who won't stay down. Rent's due. You understand."*

### ACT1_SQ05 A Table for Eight
- **Zone / Giver:** Greywood and Thornwick (discovered, no giver)
- **Summary:** Eight chairs, scattered across the region, once sat around a banquet table at the Vigil. Finding them reveals the original gathering.
- **Objectives:** O1-O8 `discover` each chair (each has a short memory vignette), O9 `interact` the Table in the half-drowned chapel to place them.
- **Rewards:** 180 XP, Memory Shard 09 (a flashback of the eight laughing before the rite), **Vigil Wine** (consumable; temporary Spirit buff).
- **Key scene:** The vignette of the banquet: Edrin's laugh, the Queen's quiet smile, Tobias arguing about wine. Sorrel humming. A single line from the Queen: *"Whatever happens, remember we were happy once."*

### ACT1_SQ06 The Gravedigger's Debt
- **Zone / Giver:** Underroot Caves and Thornwick graveyard (unlocked after the Gaunt Sexton is Rested)
- **Requires:** MQ01 O8 done by Rest (not by kill)
- **Summary:** The Sexton muttered "row nine, plot four." That plot exists. Find it and bury his wife's marker.
- **Objectives:** O1 `discover` the Thornwick graveyard, O2 `discover` row nine, plot four, O3 `collect` the broken headstone, O4 `interact` to restore it.
- **Rewards:** 100 XP, Pressure -3 in Thornwick, a Memory Shard fragment, Codex entry on Sextons.
- **Key scene:** The restored stone reads a name the Sexton never spoke. A faint warmth settles over the plot.

### ACT1_SQ07 Pip Hears It
- **Zone / Giver:** Thornwick edge, Pip (the child who hears the Hollow)
- **Summary:** Pip draws chalk marks that point to buried Hollow veins. Following them is a small treasure hunt with a creepy tone.
- **Objectives:** O1 `talk` Pip, O2 `discover` 3 chalk marks (each leads to a nest or a Memory Shard), O3 `rest` or `interact` each, O4 `talk` Pip.
- **Rewards:** 110 XP, Memory Shard 10, `pip_trust +2`, Pip's **Chalk Charm** (small detection bonus for hidden Hollow nests).
- **Key scene:** Pip: *"It's not angry. It's just full. You are full too. That's why it likes you."*

---

## 5. NOTICE BOARD (REPEATABLE CONTENT)

The Thornwick Notice Board offers repeatable **Deeds** and **Bounties** with difficulty tiers. It unlocks after MQ02. The board refreshes when the player returns from a zone and resets partially each in-game day.

### 5.1 Tiers
| Tier | Level range | Rewards scale |
|---|---|---|
| I | 1-4 | Marks, common materials |
| II | 4-8 | Uncommon gear, spellbook pages |
| III | 8-12 | Rare gear, boss materials |

### 5.2 Deed templates (data-driven; generate from these)
| Deed | Objectives | Rewards |
|---|---|---|
| Clear a Hollow Nest | `reach` nest site, `rest` N Hollowed, `interact` nest | Marks, Pressure reduction |
| Escort the Wagon | `escort` a wagon across a zone | Marks, goodwill (`halsey_standing`) |
| Gather Ghostcap | `collect` N ghostcap | Alchemy materials |
| Slay a Named Hollowed | `kill` a named elite with a distinct drop | Rare crafting material |
| Salt the Shrines | `collect` and `interact` three marked shrines | `rootwives_standing`, Cleansing Salt |

### 5.3 Rules
- Each board posting is generated from a template plus a zone and difficulty. Names and flavor lines come from data tables.
- A completed Deed is not repeatable the same day; Bounties on named enemies respawn after a delay.
- Repeating Deeds should lower Pressure over time if the player Rests Hollowed, and raise it if they die often.

---

## 6. COLLECTIBLES, CODEX AND ACHIEVEMENTS (ACT I)

### 6.1 Memory Shards (Act I: 10 of about 40)
| # | Name | Source |
|---|---|---|
| 01 | The Cradle | MQ01 |
| 02 | The Lamp | MQ04 |
| 03 | Salt | MQ05 |
| 04 | The Tally | MQ07 |
| 05 | The Shield | MQ08 (rested) |
| 06 | The Count | MQ08 (bound or rested) |
| 07 | Wyn's Song | Maren personal quest |
| 08 | The Silent Page | Tamsin personal quest |
| 09 | The Banquet | A Table for Eight |
| 10 | Chalk | Pip Hears It |

Each shard unlocks a short flashback card (text plus a still image); original text only, tagged `TODO_STORY`.

### 6.2 Warden Ledgers (Act I: 6 of about 25)
| # | Ledger | Source | Reveals |
|---|---|---|---|
| 01 | The First Page | MQ04 | The blight "listened" |
| 02 | Rosters | MQ07 | The eight and their Lanterns |
| 03 | A Soldier's Count | MQ07 | Edrin's first years of waking |
| 04 | Ledger of Costs | Tamsin personal quest | "One mortality, held in trust" |
| 05 | The Founder's Margin | hidden, Greywood chapel | A hint of Aldric's crime |
| 06 | Salt and Ash | Rootwife camp | Early ties between Wardens and Rootwives |

### 6.3 Codex (unlock on discovery; short entries)
- **People:** Maren, Tamsin, Korrin, Halsey, Pip, Edrin, Marit.
- **Places:** Underroot Caves, Thornwick, Ghostcap Field, Greywood, Scrapfang Hollow, the Vigil Keep.
- **The Rite:** the Second Breath (partial), the Eight Lanterns (partial).
- **The Hollow:** Hollowed, Forgetting, Pressure, Rest, Cleansing.
- **Creatures:** crawlers, grunts, the Gaunt Sexton, singers, Scrapfang scavengers.

### 6.4 Achievements (Act I, 12 of about 20 for v0.1)
| Achievement | Condition |
|---|---|
| First Breath | Complete MQ01 |
| Not Today | Die for the first time outside the tutorial |
| Quiet Valley | Complete MQ02 |
| Hearth and Home | Build the workbench |
| Honest Ghost | Pick the Honest answer to Halsey |
| Salt of the Earth | Complete Salt and Song |
| Thirteen | Return Wyn's satchel to Maren |
| Lamp and Ledger | Read all Act I ledgers |
| Eight Chairs | Complete A Table for Eight |
| Mercy | Grant Edrin rest |
| No Stone Added | Finish Act I without adding to Pressure beyond a threshold |
| Rest Easy | Perform 50 Rests |

---

## 7. TUTORIAL AND TEACHING TRIGGERS (for UI)

| Trigger | Tip shown |
|---|---|
| First move | Movement and camera |
| First enemy | Light attack, stamina bar |
| First low stamina | Stamina regen pause |
| First dodge need | Dodge roll and i-frames |
| First shield enemy | Block and parry |
| First staggered Hollowed | Rest with the Cradle Lantern |
| First death | Hearth, Pressure, Scars |
| First Scar | Cleansing at the shrine |
| First nest | Pressure and Rest |
| First home base use | Workbench, storage, building |
| First training | XP converts to levels only at the Trainer's yard |

---

## 8. ACTS II-IV: OUTLINES

Detail these when Act I is built and playtested.

### Act II: The Ledger (Marrowfen and the drowned approaches to Highwell)
- **Theme:** the truth about the rite surfaces; Pressure becomes a world problem; factions harden.
- **Allies introduced:** Sorrel Anwick (Rootwife leader, Unlaid #2), Anselm Duren (keeper of the ledgers, Unlaid #5), Ash (a Hollowed who kept his mind), Garrick Voss (if `garrick_fate = witness` or `gone`).
- **Main quest beats:**
  - ACT2_MQ01 The Ferry to Marrowfen: cross the flooded bog.
  - ACT2_MQ02 What the Water Remembers: find Mireille, the Drowned Tide.
  - ACT2_MQ03 The Ledger Hall: reach Anselm; he gives you the full ledger set if you earn his trust.
  - ACT2_MQ04 The Rootwife Rift: Sorrel is torn between hiding the Hollow's cause and telling the world; the player mediates.
  - ACT2_MQ05 Mireille, the Drowned Tide (boss): a rising-water arena.
  - ACT2_MQ06 (Optional) Haldor in the Roots: an optional boss that reshapes the arena.
  - ACT2_MQ07 Tamsin's Return: if he was expelled, you find him; otherwise he gives a key lore scene.
- **Faction quests:** Rootwives (cleansing in the fen), Ashen Court (a first envoy tempts you), Pale Choir (a first sermon in a drowned chapel).
- **Flags set:** `ledgers_found` total, `sorrel_allied`, `anselm_allied`, `mireille_fate`, `rootwives_standing`, `ashen_court_standing`.
- **Pressure beat:** at the end of Act II, regions begin to visibly worsen unless Pressure is managed.

### Act III: The Choir and the Court (Highwell, the ruined capital)
- **Theme:** the fallen Unlaid appear as bosses; the vessel truth surfaces; the Founder's crime is revealed in full.
- **Main quest beats:**
  - ACT3_MQ01 The Gates of Highwell.
  - ACT3_MQ02 The Court of Ash: meet the Ashen Court; they offer a path to the Crown ending.
  - ACT3_MQ03 Tobias, the Crown's Blade (boss): a parry-focused mirror duel.
  - ACT3_MQ04 The Pale Choir: Lysa Corrin preaches death as mercy; a multi-add boss fight.
  - ACT3_MQ05 The Founder's Tomb: discover Aldric's crime and the Crown's true nature.
  - ACT3_MQ06 The Queen's Diary: recover the Queen's Memory Shards; learn she volunteered as the vessel.
  - ACT3_MQ07 The Road to the Sunken Lantern.
- **Faction quests:** a choice to side with the Court, the Choir or neither, shaping Crown and Hearth requirements.
- **Flags set:** `tobias_fate`, `lysa_fate`, `founder_truth_known`, `queen_shards_recovered`, `ashen_court_standing`, `pale_choir_standing`.

### Act IV: The Reckoning (the Sunken Lantern)
- **Theme:** the final choice.
- **Main quest beats:**
  - ACT4_MQ01 The Sunken Descent: a dungeon through the Hollow's heart.
  - ACT4_MQ02 The Eight Lanterns: gather the eight Lanterns or their stand-ins (some are carried by allies, some by fallen Unlaid).
  - ACT4_MQ03 The Queen Kneels: the final scene and choice (see `STORY_BIBLE.md` section 8).
  - ACT4_MQ04 Epilogue: ending-dependent.
- **Wake ending trigger:** world Pressure crossing the threshold before ACT4_MQ03 forces ending V.

### 8.1 Hearth's Return requirement tracker (for implementation)
| Requirement | Set by |
|---|---|
| Edrin granted permanent rest | ACT1_MQ08 (`edrin_fate = rested`) |
| Maren, Tamsin, Korrin personal quests complete | ACT1_PQ_MAREN_01, ACT1_PQ_TAMSIN_01, ACT1_PQ_KORRIN_00/01 |
| Sorrel and Anselm spared, allied, present | ACT2_MQ03/MQ04, ACT4_MQ02 |
| All Queen's Memory Shards restored | ACT3_MQ06 + collection of all shards |
| Global Hollow Pressure below threshold | all quests with Pressure effects; checked at ACT4_MQ03 |

---

## 9. FLAGS USED BY THIS FILE

World flags (host's `WorldSave`):
```
act, hollow_pressure{zone}, halsey_standing, maren_trust, maren_son_quest,
tamsin_truth_level, tamsin_trust, tamsin_alive, korrin_recruited, korrin_blade_quest,
scrapfang_fate, garrick_fate, pip_trust, edrin_fate, boss_defeated[],
ledgers_found[], rootwives_standing, ashen_court_standing, pale_choir_standing,
act1_nest_rested, tutorial_done
```
Character flags (`CharacterProfile`): `memory_shards[]`, `scars[]`, `deaths_total`, `achievements[]`.

---

## 10. HOW CLAUDE CODE SHOULD USE THIS FILE

1. Convert each quest entry into a `data/quests/<ID>.tres` (or JSON) following the structure in 0.1. Objective types come from the table in 0.2.
2. Implement the quest system (state machine, objective tracking, rewards, flag setting) **before** writing quest content (milestone M7 in `GAME_PLAN.md`).
3. Write dialogue into `data/dialogue/` using the voice tags in 0.4. Where this file gives only beats, write short lines in that NPC's voice and tag them `TODO_STORY` for the owner to polish.
4. Use the milestone order in `GAME_PLAN.md` 14; only MQ01 is needed at M3-M4, MQ02-MQ08 at M7, personal quests at M9.
5. After each milestone, stop and ask the owner before continuing.

---

## 11. OPEN QUESTIONS FOR THE OWNER

1. Should MQ02 let the player skip the gate scene (fast start) or is it mandatory?
2. Are three Act I allies enough, or should Pip be recruitable late in Act I?
3. Should the Notice Board include timed events (e.g. a "night of the bell")?
4. How punishing should Scars be in the first hour (a free pass until after the tutorial)?
5. Do you want the Tally-Hunter's reveal ("watch you die and rise") to be kept, or made less dark?
6. Edrin's cradle: scratched out. Do you want that kept as a mystery until Act II, or explained in Act I?
