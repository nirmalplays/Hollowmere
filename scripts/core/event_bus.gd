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
