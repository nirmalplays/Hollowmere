"""Build the Underroot Caves (ACT1_MQ01 The Waking): layout + the prop defs it uses.

Rooms follow the quest's beats in order (QUESTS.md 2): cradle chamber -> crypt hall ->
the long corridor (grunts, the collapse) -> guard room (shield, first Rests) -> ossuary
(the Gaunt Sexton) -> stairwell. Hand-placed: edit ROOMS/PLACES and re-run.

  python -I tools/levels/build_underroot.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from propgen import footprint  # noqa: E402

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
W, H = 48, 36

# Floor rectangles (x0, y0, x1, y1) inclusive.
ROOMS = [
    (5, 23, 18, 31),   # A: cradle chamber
    (11, 15, 12, 22),  # corridor up
    (4, 5, 26, 14),    # B: crypt hall
    (27, 8, 33, 10),   # corridor east
    (31, 11, 33, 25),  # the long corridor south (the collapse)
    (24, 26, 40, 32),  # D: guard room
    (38, 17, 40, 25),  # corridor north to the ossuary
    (37, 3, 46, 16),   # E: ossuary (boss), reachable only through the guard room
    (41, 1, 43, 2),    # stairwell out
]

# (x, y, char)
PLACES = [
    # A: the cradle chamber. 'M' yours, C empty, K shattered, G glowing (Edrin's is 'X', scratched).
    (11, 25, "M"), (7, 25, "C"), (9, 25, "K"), (14, 25, "C"), (16, 25, "G"),
    (7, 29, "X"), (9, 29, "C"), (14, 29, "C"),
    (7, 26, "n"), (9, 26, "n"), (14, 26, "n"), (16, 26, "n"), (7, 30, "n"), (9, 30, "n"), (14, 30, "n"),
    (12, 27, "L"), (11, 28, "P"), (12, 29, "Z"),
    (5, 23, "T"), (18, 23, "T"), (5, 31, "T"), (18, 31, "T"), (6, 31, "b"), (17, 31, "k"), (5, 27, "w"),
    # B: the crypt hall.
    (11, 14, "R"), (15, 5, "I"), (8, 10, "c"), (16, 9, "c"), (22, 11, "c"),
    (6, 5, "H"), (24, 5, "H"), (4, 5, "w"), (26, 5, "w"), (5, 12, "b"), (20, 13, "k"), (24, 12, "x"),
    (9, 6, "T"), (21, 6, "T"), (4, 14, "T"), (26, 14, "T"), (13, 8, "B"), (18, 12, "b"),
    # The long corridor: grunts, then the ceiling gives way.
    (30, 9, "g"), (32, 15, "g"), (32, 21, "D"), (33, 12, "T"), (31, 24, "x"), (33, 18, "b"),
    # D: the guard room.
    (31, 29, "h"), (27, 30, "v"), (35, 30, "v"), (26, 27, "O"), (29, 27, "u"), (37, 31, "k"),
    (24, 26, "T"), (40, 26, "T"), (24, 32, "T"), (34, 27, "B"), (25, 31, "b"),
    # E: the ossuary. Bone heaps round the walls, the Sexton digs in the middle.
    (42, 10, "S"), (37, 3, "T"), (46, 3, "T"), (37, 16, "T"), (46, 16, "T"),
    (38, 5, "k"), (45, 6, "b"), (38, 14, "b"), (45, 14, "k"), (39, 3, "H"), (44, 3, "H"),
    (38, 9, "x"), (45, 11, "x"), (42, 2, "E"), (37, 4, "w"), (46, 4, "w"),
]

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


def layout_rows():
    g = [["#"] * W for _ in range(H)]
    for x0, y0, x1, y1 in ROOMS:
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                g[y][x] = "."
    for x, y, ch in PLACES:
        assert g[y][x] != "#" or ch in "HTw", (x, y, ch)
        g[y][x] = ch
    return ["".join(r) for r in g]


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
