"""Generate data/rooms/greywood_glade.tres and the prop defs it uses.

The glade is the first playable area in the new isometric look: forest walls,
a raised plateau, a pond, the ruined Underroot shrine, a Rootwife-style camp,
a Hollow-blighted dead grove, and a training husk near the spawn.
Layout is generated once (seeded) so it can be hand-edited afterwards.

  python -I tools/levels/build_greywood_glade.py
"""
import math
import os
import random

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
N = 40

# Prop defs: name -> (texture paths, base_inset, collision radius, jitter, light (r,g,b,energy,scale,height) or None)
PROP_DIR = "res://assets/art/props/"
PROPS = {
    "tree_green": ([f"trees/trees_r{r:02d}c{c:02d}.png" for r in (0, 2, 6) for c in range(10)], 10, 7.0, 6.0, None),
    "tree_dead": ([f"trees/trees_r{r:02d}c{c:02d}.png" for r in (8, 10) for c in range(10)], 8, 4.0, 6.0, None),
    "ruin_shrine": (["ruins/ruin_01.png"], 30, 0.0, 0.0, (0.55, 0.8, 1.0, 1.4, 1.6, 20)),
    "ruin_gate": (["ruins/ruin_06.png", "ruins/ruin_08.png"], 8, 0.0, 0.0, None),
    "ruin_pillar": (["ruins/ruin_07.png", "ruins/ruin_09.png"], 6, 5.0, 2.0, None),
    "ruin_rubble": ([f"ruins/ruin_{i:02d}.png" for i in (10, 11, 12, 13)], 4, 6.0, 4.0, None),
    "ruin_wall": ([f"ruins/ruin_{i:02d}.png" for i in (14, 15, 16)], 6, 0.0, 0.0, None),
    "campfire": ([f"props_medium/props_medium_r03c{c:02d}.png" for c in (2, 3, 4, 5)], 4, 6.0, 0.0, (1.0, 0.62, 0.3, 1.6, 1.3, 6)),
    "cauldron": ([f"props_medium/props_medium_r04c{c:02d}.png" for c in range(6)], 4, 6.0, 2.0, None),
    "tent": ([f"props_medium/props_medium_r00c{c:02d}.png" for c in range(8)], 10, 14.0, 0.0, None),
    "crates": ([f"props_small/props_small_r05c{c:02d}.png" for c in range(16)], 3, 5.0, 4.0, None),
    "stump": (["props_small/props_small_r02c14.png", "props_small/props_small_r02c15.png"]
              + [f"props_small/props_small_r03c{c:02d}.png" for c in range(12)], 2, 4.0, 5.0, None),
    "bones": ([f"props_small/props_small_r07c{c:02d}.png" for c in range(7)], 1, 0.0, 6.0, None),
    "stakes": ([f"props_small/props_small_r01c{c:02d}.png" for c in range(16)], 3, 0.0, 4.0, None),
}

LEGEND_PROPS = {"T": "tree_green", "X": "tree_dead", "R": "ruin_shrine", "G": "ruin_gate", "I": "ruin_pillar",
                "r": "ruin_rubble", "L": "ruin_wall", "F": "campfire", "C": "cauldron", "N": "tent",
                "B": "crates", "s": "stump", "b": "bones", "k": "stakes"}


def make_layout():
    rnd = random.Random(11)
    g = [["." for _ in range(N)] for _ in range(N)]

    def put(x, y, ch):
        if 0 <= x < N and 0 <= y < N:
            g[y][x] = ch

    # Forest walls: dense trees round the edge, thinning inward; dead trees to the north.
    for y in range(N):
        for x in range(N):
            edge = min(x, y, N - 1 - x, N - 1 - y)
            if edge <= 1 or (edge == 2 and rnd.random() < 0.75) or (edge == 3 and rnd.random() < 0.3):
                g[y][x] = "X" if (x + y < 22 and rnd.random() < 0.5) else "T"
            elif rnd.random() < 0.12:
                g[y][x] = ","
    # Raised plateau in the north with a ragged edge.
    for y in range(4, 13):
        for x in range(5, 16):
            if (x - 10) ** 2 / 30 + (y - 8) ** 2 / 18 < 1 + rnd.uniform(-0.15, 0.1):
                put(x, y, "#")
    # Pond to the north-east.
    for y in range(N):
        for x in range(N):
            if ((x - 29) / 4.5) ** 2 + ((y - 10) / 3.2) ** 2 < 1:
                put(x, y, "~")
    # Stone path: spawn (south-west) -> shrine -> the north-east edge.
    for t in range(0, 101):
        x = round(9 + (21 - 9) * t / 100)
        y = round(31 + (20 - 31) * t / 100)
        for w in (0, 1):
            put(x + w, y, "=")
    for t in range(0, 101):
        x = round(22 + (33 - 22) * t / 100)
        y = round(20 + (26 - 20) * t / 100)
        put(x, y, "=")
        put(x, y + 1, "=")
    # Clear a circle for the shrine and place it with pillars and rubble around.
    for y in range(N):
        for x in range(N):
            if (x - 21) ** 2 + (y - 18) ** 2 <= 16 and g[y][x] not in "#~":
                g[y][x] = "."
    put(21, 18, "R")
    for (x, y, ch) in [(16, 15, "I"), (26, 15, "I"), (17, 23, "r"), (26, 22, "I"), (15, 19, "L"), (24, 13, "r")]:
        put(x, y, ch)
    put(17, 27, "G")
    # Hollow-blighted grove west of the shrine: dead trees, bones, ashen dark grass.
    for _ in range(26):
        x, y = rnd.randint(5, 13), rnd.randint(15, 24)
        if g[y][x] == ".":
            g[y][x] = rnd.choice(["X", "X", ",", "b", ","])
    # Camp to the south-east (Rootwife-style: tents round a fire).
    for (x, y, ch) in [(29, 30, "F"), (27, 29, "N"), (31, 28, "N"), (30, 32, "C"), (32, 31, "B"), (26, 32, "B"),
                       (28, 33, "k"), (33, 29, "s")]:
        put(x, y, ch)
    # Scatter stumps and crates.
    for _ in range(10):
        x, y = rnd.randint(5, 34), rnd.randint(5, 34)
        if g[y][x] == ".":
            g[y][x] = rnd.choice(["s", "s", "b"])
    # Spawn and the training husk.
    put(9, 31, "P")
    put(14, 28, "D")
    for (x, y) in [(13, 28), (15, 28), (14, 27), (14, 29), (10, 30), (10, 31), (11, 31), (12, 30)]:
        if g[y][x] not in "P=":
            g[y][x] = "."
    return ["".join(r) for r in g]


def write_prop_defs():
    out_dir = os.path.join(PROJECT, "data", "props")
    os.makedirs(out_dir, exist_ok=True)
    for name, (textures, inset, radius, jitter, light) in PROPS.items():
        textures = [t for t in textures if os.path.exists(os.path.join(PROJECT, "assets", "art", "props", t))]
        lines = [f'[gd_resource type="Resource" script_class="PropDef" load_steps={2 + len(textures)} format=3]', "",
                 '[ext_resource type="Script" path="res://scripts/world/prop_def.gd" id="1"]']
        for i, t in enumerate(textures):
            lines.append(f'[ext_resource type="Texture2D" path="{PROP_DIR}{t}" id="t{i}"]')
        refs = ", ".join(f'ExtResource("t{i}")' for i in range(len(textures)))
        lines += ["", "[resource]", 'script = ExtResource("1")', f"textures = Array[Texture2D]([{refs}])",
                  f"base_inset = {inset}", f"collision_radius = {radius}", f"jitter = {jitter}",
                  f"flip_randomly = {'false' if name.startswith('ruin') else 'true'}"]
        if light:
            r, g, b, energy, scale, height = light
            lines += [f"light_color = Color({r}, {g}, {b}, 1)", f"light_energy = {energy}",
                      f"light_scale = {scale}", f"light_height = {height}.0"]
        lines.append("")
        with open(os.path.join(out_dir, name + ".tres"), "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(lines))


def write_room(rows):
    used = sorted({LEGEND_PROPS[c] for row in rows for c in row if c in LEGEND_PROPS})
    lines = [f'[gd_resource type="Resource" script_class="IsoRoomLayout" load_steps={4 + len(used)} format=3]', "",
             '[ext_resource type="Script" path="res://scripts/world/iso_room_layout.gd" id="1"]',
             '[ext_resource type="TileSet" path="res://assets/art/tiles/greywood_iso.tres" id="2"]',
             '[ext_resource type="PackedScene" path="res://scenes/entities/training_dummy.tscn" id="3"]']
    for name in used:
        lines.append(f'[ext_resource type="Resource" path="res://data/props/{name}.tres" id="p_{name}"]')
    props = ",\n".join(f'"{c}": ExtResource("p_{n}")' for c, n in LEGEND_PROPS.items() if n in used)
    lines += ["", "[resource]", 'script = ExtResource("1")', 'rows = "' + "\n".join(rows) + '\n"',
              'tileset = ExtResource("2")', "tile_seed = 5",
              'ground = {\n".": ["grass_b", "grass_b", "grass_b", "grass_d", "grass_b", "grass_flowers"],\n'
              '",": ["grass_dark_a", "grass_dark_b", "grass_dark_c"],\n'
              '"=": ["grass_dark_a", "grass_dark_b", "grass_dark_a", "grass_d"],\n'
              '"~": ["water"]\n}',
              'raised = {\n"#": ["cliff_grass_a", "cliff_grass_b", "cliff_grass_c", "cliff_grass_d"]\n}',
              "props = {\n" + props + "\n}",
              'markers = {\n"D": ExtResource("3")\n}', 'prop_ground = "."', ""]
    with open(os.path.join(PROJECT, "data", "rooms", "greywood_glade.tres"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    write_prop_defs()
    rows = make_layout()
    write_room(rows)
    print("\n".join(rows))
