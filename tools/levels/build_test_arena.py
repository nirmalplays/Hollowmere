"""A small walled arena for automated tests (movement, walls, combat vs. a training husk).

  python -I tools/levels/build_test_arena.py
"""
import os

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
ROWS = [
    "######################",
    "######################",
    "######################",
    "##..................##",
    "##..................##",
    "##..................##",
    "##...P........D.....##",
    "##..................##",
    "##..................##",
    "##..................##",
    "######################",
    "######################",
]

LAYOUT = '''[gd_resource type="Resource" script_class="AreaLayout" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/world/area_layout.gd" id="1"]
[ext_resource type="TileSet" path="res://assets/art/tiles/lpc/crypt.tres" id="2"]
[ext_resource type="PackedScene" path="res://scenes/entities/training_dummy.tscn" id="3"]

[resource]
script = ExtResource("1")
rows = "{rows}
"
tileset = ExtResource("2")
wall_char = "#"
wall_set = "crypt"
floors = {{
".": ["crypt_floor_0", "crypt_floor_1", "crypt_floor_2"]
}}
markers = {{
"D": ExtResource("3")
}}
prop_floor = "."
'''

SCENE = '''[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/world/area_scene.gd" id="1"]
[ext_resource type="Resource" path="res://data/areas/test_arena.tres" id="2"]

[node name="TestArena" type="Node2D"]
script = ExtResource("1")
layout = ExtResource("2")
music = &""

[node name="Ambient" type="CanvasModulate" parent="."]

[node name="Floor" type="TileMapLayer" parent="."]

[node name="Walls" type="TileMapLayer" parent="."]

[node name="World" type="Node2D" parent="."]
y_sort_enabled = true

[node name="Entities" type="Node2D" parent="World"]
y_sort_enabled = true

[node name="FxLayer" type="CanvasLayer" parent="."]
layer = 2
follow_viewport_enabled = true
'''

if __name__ == "__main__":
    with open(os.path.join(PROJECT, "data", "areas", "test_arena.tres"), "w", encoding="utf-8", newline="\n") as f:
        f.write(LAYOUT.format(rows="\n".join(ROWS)))
    with open(os.path.join(PROJECT, "tests", "arena.tscn"), "w", encoding="utf-8", newline="\n") as f:
        f.write(SCENE)
    print("test arena written")
