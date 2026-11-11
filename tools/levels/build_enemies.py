"""Write enemy data (.tres) and scenes for the Act I roster (QUESTS.md ACT1_MQ01).

Enemies are data: tune numbers here and re-run, or edit the .tres in the editor.

  python -I tools/levels/build_enemies.py
"""
import os

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))

# attack: id, shape (0 AROUND, 1 FRONT, 2 AT_TARGET), trigger, telegraph, active, recovery, cooldown,
#         damage, knockback, poise, extra fields
def attack(aid, shape, trigger, tele, active, rec, cd, dmg, kb, poise, **extra):
    return dict(id=aid, shape=shape, trigger_range=trigger, telegraph_ms=tele, active_ms=active,
                recovery_ms=rec, cooldown_ms=cd, damage=dmg, knockback=kb, poise_damage=poise, **extra)


ENEMIES = {
    "hollow_crawler": dict(
        name="Crawling Hollowed", sheet="hollowed_zombie", hp=30, speed=50, aggro=150, poise=15, xp=8,
        attacks=[attack("claw", 1, 26, 650, 120, 500, 1400, 8, 90, 10, reach=16, box_size=(22, 18))]),
    "hollow_grunt": dict(
        name="Hollowed Grunt", sheet="hollow_husk", hp=50, speed=72, aggro=170, poise=30, xp=14,
        attacks=[attack("lunge", 1, 46, 750, 140, 600, 1800, 14, 140, 18, reach=22, box_size=(34, 20), lunge_speed=150)]),
    "hollow_shield": dict(
        name="Shielded Hollowed", sheet="hollow_shield", hp=60, speed=58, aggro=170, poise=45, xp=18, shielded=True,
        attacks=[attack("bash", 1, 30, 800, 120, 650, 1700, 12, 170, 25, reach=18, box_size=(26, 22))]),
    "gaunt_sexton": dict(
        name="The Gaunt Sexton", sheet="gaunt_sexton", hp=320, speed=56, aggro=230, poise=120, xp=120, boss=True,
        scale=1.4, stagger=1800, leash=900,
        attacks=[attack("shovel_sweep", 0, 50, 900, 160, 700, 2200, 18, 160, 30, aoe_radius=46),
                 attack("grave_pit", 2, 220, 1100, 200, 600, 3400, 20, 120, 25, aoe_radius=24, weight=0.8)],
        phase2_at=0.5, phase2_summon="hollow_crawler", phase2_summon_count=3,
        phase2=[attack("shovel_sweep", 0, 50, 800, 160, 600, 2000, 20, 170, 30, aoe_radius=50),
                attack("grave_pits", 2, 240, 1000, 200, 600, 3000, 20, 120, 25, aoe_radius=24, pits=3, pit_spread=48)]),
}

TRES_ATTACK = '''[sub_resource type="Resource" id="{rid}"]
script = ExtResource("2")
{fields}
'''

SCENE = '''[gd_scene load_steps=10 format=3]

[ext_resource type="Script" path="res://scripts/entities/enemy/enemy.gd" id="1"]
[ext_resource type="Resource" path="res://data/enemies/{eid}.tres" id="2"]
[ext_resource type="Shader" path="res://assets/shaders/flash.gdshader" id="3"]
[ext_resource type="Script" path="res://scripts/systems/combat/hitbox.gd" id="4"]
[ext_resource type="Script" path="res://scripts/systems/combat/hurtbox.gd" id="5"]
[ext_resource type="Script" path="res://scripts/entities/enemy/telegraph_marker.gd" id="6"]

[sub_resource type="ShaderMaterial" id="flash"]
resource_local_to_scene = true
shader = ExtResource("3")
shader_parameter/flash_color = Color(1, 1, 1, 1)
shader_parameter/flash_amount = 0.0

[sub_resource type="CircleShape2D" id="base"]
radius = {foot}

[sub_resource type="CapsuleShape2D" id="body"]
radius = {body_r}
height = {body_h}

[node name="{node}" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 1
motion_mode = 1
script = ExtResource("1")
data = ExtResource("2")

[node name="TelegraphMarker" type="Node2D" parent="."]
script = ExtResource("6")

[node name="Sprite" type="AnimatedSprite2D" parent="."]
material = SubResource("flash")
scale = Vector2({scale}, {scale})

[node name="Collision" type="CollisionShape2D" parent="."]
shape = SubResource("base")

[node name="Hurtbox" type="Area2D" parent="."]
script = ExtResource("5")
team = 1

[node name="Shape" type="CollisionShape2D" parent="Hurtbox"]
position = Vector2(0, {body_y})
shape = SubResource("body")

[node name="Hitbox" type="Area2D" parent="."]
script = ExtResource("4")
team = 1
'''


def fmt(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, tuple):
        return f"Vector2({v[0]}, {v[1]})"
    if isinstance(v, str):
        return f'&"{v}"'
    if isinstance(v, float):
        return f"{v}"
    return str(v)


def attack_block(rid, a):
    fields = "\n".join(f"{k} = {fmt(float(v) if k in ('trigger_range', 'damage', 'knockback', 'poise_damage', 'aoe_radius', 'reach', 'lunge_speed', 'pit_spread', 'weight') else v)}" for k, v in a.items())
    return TRES_ATTACK.format(rid=rid, fields=fields)


def write_enemy(eid, e):
    ext = ['[ext_resource type="Script" path="res://scripts/entities/enemy/enemy_data.gd" id="1"]',
           '[ext_resource type="Script" path="res://scripts/entities/enemy/enemy_attack_data.gd" id="2"]',
           f'[ext_resource type="Resource" path="res://data/sprites/{e["sheet"]}.tres" id="3"]',
           '[ext_resource type="Resource" path="res://data/fx/hit_spark.tres" id="4"]']
    if e.get("phase2_summon"):
        ext.append(f'[ext_resource type="PackedScene" path="res://scenes/entities/enemies/{e["phase2_summon"]}.tscn" id="5"]')
    subs = []
    refs1 = []
    for i, a in enumerate(e["attacks"]):
        subs.append(attack_block(f"a{i}", a))
        refs1.append(f'SubResource("a{i}")')
    refs2 = []
    for i, a in enumerate(e.get("phase2", [])):
        subs.append(attack_block(f"p{i}", a))
        refs2.append(f'SubResource("p{i}")')
    lines = [f'[gd_resource type="Resource" script_class="EnemyData" load_steps={len(ext) + len(subs) + 1} format=3]', ""]
    lines += ext + [""] + subs
    lines += ["[resource]", 'script = ExtResource("1")', f'id = &"{eid}"', f'display_name = "{e["name"]}"',
              f"max_hp = {float(e['hp'])}", f"xp = {e['xp']}", f"move_speed = {float(e['speed'])}",
              f"aggro_radius = {float(e['aggro'])}", f"leash_radius = {float(e.get('leash', 340))}",
              f"max_poise = {float(e['poise'])}", f"stagger_ms = {e.get('stagger', 1500)}",
              f"shielded = {fmt(e.get('shielded', False))}", f"is_boss = {fmt(e.get('boss', False))}",
              f"attacks = Array[ExtResource(\"2\")]([{', '.join(refs1)}])",
              'sprite_sheet = ExtResource("3")', 'hit_fx = ExtResource("4")']
    if refs2:
        lines += [f"phase2_at = {e['phase2_at']}", f"phase2_attacks = Array[ExtResource(\"2\")]([{', '.join(refs2)}])",
                  'phase2_summon = ExtResource("5")', f"phase2_summon_count = {e['phase2_summon_count']}"]
    lines.append("")
    os.makedirs(os.path.join(PROJECT, "data", "enemies"), exist_ok=True)
    with open(os.path.join(PROJECT, "data", "enemies", eid + ".tres"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    scale = e.get("scale", 1.0)
    os.makedirs(os.path.join(PROJECT, "scenes", "entities", "enemies"), exist_ok=True)
    with open(os.path.join(PROJECT, "scenes", "entities", "enemies", eid + ".tscn"), "w", encoding="utf-8", newline="\n") as f:
        f.write(SCENE.format(eid=eid, node="".join(w.title() for w in eid.split("_")), scale=scale,
                             foot=round(6 * scale, 1), body_r=round(8 * scale, 1), body_h=round(30 * scale, 1),
                             body_y=round(-18 * scale, 1)))


def main():
    # Summoned types first so the boss can reference their scenes.
    for eid in sorted(ENEMIES, key=lambda k: ENEMIES[k].get("boss", False)):
        write_enemy(eid, ENEMIES[eid])
    print("enemies:", ", ".join(ENEMIES))


if __name__ == "__main__":
    main()
