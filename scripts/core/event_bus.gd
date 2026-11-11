extends Node
## Global signal hub. Systems emit/listen here so they never reference each other directly.
## Signals are added per milestone; declared up front so later code has a stable contract.

# Combat (M2+)
signal damage_dealt(source: Node, target: Node, amount: int, damage_type: StringName)
signal enemy_killed(enemy: Node, killer: Node)
signal player_died(player: Node)

# Items and quests (M4+)
signal item_picked(owner_id: int, item_id: StringName, count: int)
signal quest_updated(quest_id: StringName, state: StringName)

# Story (M7+; see STORY_BIBLE.md)
signal hollow_pressure_changed(zone_id: StringName, value: int)
signal story_flag_changed(flag: StringName, value: Variant)
signal lore_shown(text: String)  ## an inscription/page was read; the HUD shows it
signal tip_shown(text: String)  ## a tutorial prompt (QUESTS 7); empty text hides it
signal enemy_rested(enemy: Node, by: Node)  ## a Hollowed was laid to rest (Pressure falls)
signal boss_phase_changed(boss: Node, phase: int)
signal area_entered(title: String)  ## area banner ("THE UNDERROOT CAVES")
signal boss_engaged(boss: Node)  ## shows the boss bar
signal toast_shown(kind: String, text: String)  ## top-right toast ("Item", "Cradle Lantern")
