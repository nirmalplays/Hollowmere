"""Build the Underroot Caves (ACT1_MQ01 The Waking): layout + the prop defs it uses.

The cave follows the quest's beats in order (QUESTS.md 2): the Cradle Hollow -> the
Nameless Hall -> the Old Descent (grunts, the collapse) -> the Wardens' Mess (shield,
first Rests) -> the Sexton's Round (boss) -> the gate stair. The shape and placements
live in underroot_map.py; the prop definitions live here.

  python -I tools/levels/build_underroot.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from propgen import footprint  # noqa: E402
from underroot_map import layout_rows  # noqa: E402

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
PROP_DIR = "res://assets/art/props/lpc/"
# name -> (textures, base_inset, footprint mode, jitter, light or None, flip)
PROPS = {
    "cradle_mine": (["cradle_mine.png"], 2, "box", 0.0, None, False),
    "cradle_empty": (["cradle_empty.png"], 2, "box", 0.0, None, False),
    "cradle_shattered": (["cradle_shattered.png"], 2, "box", 0.0, None, False),
    "cradle_glowing": (["cradle_glowing.png"], 2, "box", 0.0, (0.5, 0.75, 1.0, 1.3, 0.8, 22), False),
    "brazier": (["brazier.png"], 2, "trunk", 0.0, (1.0, 0.66, 0.32, 1.6, 1.25, 52), False),
    "bone_pile": (["bone_pile.png", "bones.png"], 2, "none", 4.0, None, True),
    "skull_pile": (["skull_pile.png"], 2, "ellipse", 2.0, None, True),
    "skull": (["skull.png"], 2, "none", 4.0, None, True),
    "cobweb": (["cobweb_a.png", "cobweb_b.png"], 0, "none", 0.0, None, True),
    "hanging_skeleton": (["hanging_skeleton.png"], 0, "none", 0.0, None, False),
    "blood": (["blood.png", "slime.png"], 0, "none", 6.0, None, True),
    "table_long": (["table_long.png"], 2, "box", 0.0, None, False),
    "cauldron": (["cauldron.png"], 2, "ellipse", 0.0, (0.4, 0.9, 0.5, 0.6, 0.5, 10), False),
}
# name -> (pixels of sway, hanging): the cave breathes, webs and the hanged stir.
SWAY = {"cobweb": (1.2, True), "hanging_skeleton": (1.0, True)}
LEGEND = {"M": "cradle_mine", "C": "cradle_empty", "K": "cradle_shattered", "G": "cradle_glowing",
          "X": "cradle_shattered", "T": "brazier", "b": "bone_pile", "k": "skull_pile", "x": "skull",
          "w": "cobweb", "H": "hanging_skeleton", "B": "blood", "O": "table_long", "u": "cauldron"}
MARKERS = {
    "c": "res://scenes/entities/enemies/hollow_crawler.tscn",
    "v": "res://scenes/entities/enemies/hollow_crawler.tscn",
    "g": "res://scenes/entities/enemies/hollow_grunt.tscn",
    "h": "res://scenes/entities/enemies/hollow_shield.tscn",
    "S": "res://scenes/entities/enemies/gaunt_sexton.tscn",
    "L": "res://scenes/props/lantern_pedestal.tscn",
    "I": "res://scenes/props/crypt_inscription.tscn",
    "n": "res://scenes/props/cradle_name.tscn",
    "Z": "res://scenes/world/music_zone_waking.tscn",
    "R": "res://scenes/world/trigger.tscn",
    "D": "res://scenes/world/trigger.tscn",
    "E": "res://scenes/world/trigger.tscn",
}


def box_footprint(path, inset):
    """The stone's front half: cradles and tables block where their base stands."""
    from PIL import Image
    w, h = Image.open(path).size
    return [(-w / 2 + 2, -h * 0.45), (w / 2 - 2, -h * 0.45), (w / 2 - 2, -inset + 1.0), (-w / 2 + 2, -inset + 1.0)]


def write_props():
    out = os.path.join(PROJECT, "data", "props")
    os.makedirs(out, exist_ok=True)
    for name, (textures, inset, mode, jitter, light, flip) in PROPS.items():
        paths = [os.path.join(PROJECT, "assets", "art", "props", "lpc", t) for t in textures]
        if mode == "box":
            prints = [box_footprint(p, inset) for p in paths]
        else:
            prints = [footprint(p, mode, inset) for p in paths]
        lines = [f'[gd_resource type="Resource" script_class="PropDef" load_steps={2 + len(textures)} format=3]', "",
                 '[ext_resource type="Script" path="res://scripts/world/prop_def.gd" id="1"]']
        lines += [f'[ext_resource type="Texture2D" path="{PROP_DIR}{t}" id="t{i}"]' for i, t in enumerate(textures)]
        refs = ", ".join(f'ExtResource("t{i}")' for i in range(len(textures)))
        lines += ["", "[resource]", 'script = ExtResource("1")', f"textures = Array[Texture2D]([{refs}])",
                  f"base_inset = {inset}", f"jitter = {jitter}", f"flip_randomly = {'true' if flip else 'false'}"]
        if all(prints):
            polys = ", ".join("PackedVector2Array(" + ", ".join(f"{x:.1f}, {y:.1f}" for x, y in p) + ")" for p in prints)
            lines.append(f"footprints = Array[PackedVector2Array]([{polys}])")
        if light:
            r, g, b, energy, scale, height = light
            lines += [f"light_color = Color({r}, {g}, {b}, 1)", f"light_energy = {energy}",
                      f"light_scale = {scale}", f"light_height = {height}.0"]
        if name in SWAY:
            lines += [f"sway = {SWAY[name][0]}", f"hanging = {'true' if SWAY[name][1] else 'false'}"]
        if name == "brazier":
            lines.append('sound = &"amb_fire"')
        lines.append("")
        with open(os.path.join(out, f"crypt_{name}.tres"), "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(lines))


def write_layout(rows):
    used = sorted({LEGEND[c] for r in rows for c in r if c in LEGEND})
    mk = sorted({c for r in rows for c in r if c in MARKERS})
    ext = ['[ext_resource type="Script" path="res://scripts/world/area_layout.gd" id="1"]',
           '[ext_resource type="TileSet" path="res://assets/art/tiles/lpc/crypt.tres" id="2"]']
    ext += [f'[ext_resource type="Resource" path="res://data/props/crypt_{n}.tres" id="p_{n}"]' for n in used]
    scenes = sorted(set(MARKERS[c] for c in mk))
    ext += [f'[ext_resource type="PackedScene" path="{s}" id="m{i}"]' for i, s in enumerate(scenes)]
    props = ",\n".join(f'"{c}": ExtResource("p_{n}")' for c, n in LEGEND.items() if n in used)
    markers = ",\n".join(f'"{c}": ExtResource("m{scenes.index(MARKERS[c])}")' for c in mk)
    floors = [f"crypt_floor_{i}" for i in range(8)] * 3 + ["crypt_floor_moss_0", "crypt_floor_moss_1"]
    lines = [f'[gd_resource type="Resource" script_class="AreaLayout" load_steps={len(ext) + 1} format=3]', ""] + ext
    lines += ["", "[resource]", 'script = ExtResource("1")', 'rows = "' + "\n".join(rows) + '\n"',
              'tileset = ExtResource("2")', "tile_seed = 9", 'wall_char = "#"', 'wall_set = "crypt"',
              'floors = {\n".": [' + ", ".join(f'"{f}"' for f in floors) + "]\n}",
              "props = {\n" + props + "\n}", "markers = {\n" + markers + "\n}", 'prop_floor = "."', ""]
    os.makedirs(os.path.join(PROJECT, "data", "areas"), exist_ok=True)
    with open(os.path.join(PROJECT, "data", "areas", "underroot_caves.tres"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    write_props()
    rows = layout_rows()
    write_layout(rows)
    print("\n".join(rows))
