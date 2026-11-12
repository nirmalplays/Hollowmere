"""Build the Shrine Wood (the opening zone): painted ground, the forest, props, layout.

The ground is one painted picture, not tiles (docs/DIMRAETH_REFERENCE.md part 2): dark
forest floor, lighter meadow where you can walk, a worn dirt trail, all with soft lumpy
edges. The forest wall is real trees standing on the blocked cells. The shape and the
hand placements live in shrine_wood_map.py.

  python -I tools/art/import_outdoor.py      (once: cuts the tree and plant sprites)
  python -I tools/levels/build_shrine_wood.py
"""
import os
import random
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from propgen import footprint  # noqa: E402
from shrine_wood_map import H, W, layout, named_places  # noqa: E402

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
TILE = 32
AREA = "shrine_wood"
LPC = "res://assets/art/props/lpc/"
WILD = "res://assets/art/props/wild/"

# name -> dict(dir, textures, inset, mode, jitter, light, flip, sway, hanging, shadow, sound)
def prop(directory, textures, inset=2, mode="none", jitter=0.0, light=None, flip=False, sway=0.0, shadow=True, sound=""):
    return dict(dir=directory, textures=textures, inset=inset, mode=mode, jitter=jitter, light=light, flip=flip,
                sway=sway, shadow=shadow, sound=sound)


PROPS = {
    # the dead's furniture (drawn / LPC dungeon)
    "cradle_mine": prop(LPC, ["cradle_mine.png"], mode="box"),
    "cradle_empty": prop(LPC, ["cradle_empty.png"], mode="box"),
    "cradle_shattered": prop(LPC, ["cradle_shattered.png"], mode="box"),
    "cradle_glowing": prop(LPC, ["cradle_glowing.png"], mode="box", light=(0.5, 0.75, 1.0, 1.3, 0.8, 22)),
    "brazier": prop(LPC, ["brazier.png"], mode="trunk", light=(1.0, 0.66, 0.32, 1.5, 1.2, 52), sound="amb_fire"),
    "bone_pile": prop(LPC, ["bone_pile.png", "bones.png"], jitter=4.0, flip=True),
    "skull_pile": prop(LPC, ["skull_pile.png"], mode="ellipse", jitter=2.0, flip=True),
    "skull": prop(LPC, ["skull.png"], jitter=4.0, flip=True),
    "table_long": prop(LPC, ["table_long.png"], mode="box"),
    "cauldron": prop(LPC, ["cauldron.png"], mode="ellipse", light=(0.4, 0.9, 0.5, 0.6, 0.5, 10)),
    # the wood
    "rock": prop(WILD, ["rock_big.png", "rock_small.png"], mode="ellipse", flip=True),
    "log": prop(WILD, ["log_a.png", "log_b.png"], mode="ellipse", flip=True),
    "stump": prop(WILD, ["stump.png"], mode="ellipse"),
    "woodpile": prop(WILD, ["woodpile.png"], mode="ellipse"),
    "hut": prop(WILD, ["hut.png"], mode="ellipse"),
    "tree_solo": prop(WILD, ["mid_a.png", "mid_b.png", "mid_c.png", "mid_e.png", "leafy_b.png"], inset=9, mode="tree",
                      flip=True, sway=1.6, shadow=False),
    # scattered (no collision: the blocked cells under the forest do the blocking)
    "tree_wall": prop(WILD, ["oak_a.png", "oak_b.png", "oak_c.png", "oak_d.png", "round_a.png", "round_b.png", "leafy_a.png",
                             "leafy_c.png", "leafy_d.png", "mid_a.png", "mid_c.png", "mid_d.png"], inset=12, flip=True,
                      sway=1.8, shadow=False),
    "tree_great": prop(WILD, ["oak_great.png", "oak_dense.png"], inset=20, flip=True, sway=2.2, shadow=False),
    "tree_pine": prop(WILD, ["pine_a.png", "pine_b.png", "pine_c.png"], inset=6, flip=True, sway=1.4, shadow=False),
    "tree_dead": prop(WILD, ["dead_oak_a.png", "dead_oak_c.png", "dead_leafy_c.png", "dead_mid_d.png", "dead_round_a.png"],
                      inset=12, flip=True, sway=1.2, shadow=False),
    "bush": prop(WILD, ["bush_a.png", "bush_b.png"], flip=True, sway=1.0, shadow=False),
    "plant": prop(WILD, ["plant_a.png", "plant_b.png", "plant_c.png", "plant_d.png", "fern.png"], flip=True, sway=1.6, shadow=False),
    "flower": prop(WILD, ["flower_a.png", "flower_b.png", "mushrooms.png"], flip=True, sway=1.0, shadow=False),
}
LEGEND = {"M": "cradle_mine", "C": "cradle_empty", "K": "cradle_shattered", "G": "cradle_glowing", "X": "cradle_shattered",
          "T": "brazier", "b": "bone_pile", "k": "skull_pile", "x": "skull", "O": "table_long", "u": "cauldron",
          "o": "rock", "l": "log", "s": "stump", "W": "woodpile", "N": "hut", "t": "tree_solo"}
MARKERS = {
    "c": "res://scenes/entities/enemies/hollow_crawler.tscn",
    "v": "res://scenes/entities/enemies/hollow_crawler.tscn",
    "g": "res://scenes/entities/enemies/hollow_grunt.tscn",
    "h": "res://scenes/entities/enemies/hollow_shield.tscn",
    "S": "res://scenes/entities/enemies/gaunt_sexton.tscn",
    "L": "res://scenes/props/lantern_pedestal.tscn",
    "I": "res://scenes/props/crypt_inscription.tscn",
    "n": "res://scenes/props/cradle_name.tscn",
    "F": "res://scenes/props/rest_fire.tscn",
    "Z": "res://scenes/world/music_zone_waking.tscn",
    "R": "res://scenes/world/trigger.tscn",
    "D": "res://scenes/world/trigger.tscn",
    "E": "res://scenes/world/trigger.tscn",
}
SCATTER = ["tree_wall", "tree_great", "tree_pine", "tree_dead", "bush", "plant", "flower"]


def fs_path(res):
    return os.path.join(PROJECT, res.replace("res://", "").replace("/", os.sep))


def footprints(p):
    out = []
    for t in p["textures"]:
        path = fs_path(p["dir"] + t)
        w, h = Image.open(path).size
        if p["mode"] == "box":  # the stone's front half
            out.append([(-w / 2 + 2, -h * 0.45), (w / 2 - 2, -h * 0.45), (w / 2 - 2, -p["inset"] + 1.0), (-w / 2 + 2, -p["inset"] + 1.0)])
        elif p["mode"] == "tree":  # just the trunk
            out.append([(-9, -8), (9, -8), (11, -2), (0, 2), (-11, -2)])
        else:
            out.append(footprint(path, p["mode"], p["inset"]))
    return out


def write_props():
    out = os.path.join(PROJECT, "data", "props")
    for name, p in PROPS.items():
        prints = footprints(p)
        n = len(p["textures"])
        lines = [f'[gd_resource type="Resource" script_class="PropDef" load_steps={2 + n} format=3]', "",
                 '[ext_resource type="Script" path="res://scripts/world/prop_def.gd" id="1"]']
        lines += [f'[ext_resource type="Texture2D" path="{p["dir"]}{t}" id="t{i}"]' for i, t in enumerate(p["textures"])]
        refs = ", ".join(f'ExtResource("t{i}")' for i in range(n))
        lines += ["", "[resource]", 'script = ExtResource("1")', f"textures = Array[Texture2D]([{refs}])",
                  f"base_inset = {p['inset']}", f"jitter = {p['jitter']}", f"flip_randomly = {'true' if p['flip'] else 'false'}",
                  f"soft_shadow = {'true' if p['shadow'] else 'false'}"]
        if all(prints):
            polys = ", ".join("PackedVector2Array(" + ", ".join(f"{x:.1f}, {y:.1f}" for x, y in pp) + ")" for pp in prints)
            lines.append(f"footprints = Array[PackedVector2Array]([{polys}])")
        if p["sway"]:
            lines.append(f"sway = {p['sway']}")
        if p["sound"]:
            lines.append(f'sound = &"{p["sound"]}"')
        if p["light"]:
            r, g, b, energy, scale, height = p["light"]
            lines += [f"light_color = Color({r}, {g}, {b}, 1)", f"light_energy = {energy}", f"light_scale = {scale}",
                      f"light_height = {height}.0"]
        lines.append("")
        with open(os.path.join(out, f"wood_{name}.tres"), "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(lines))


# ---------------------------------------------------------------- ground painting

def cell_mask(terrain, chars):
    m = Image.new("L", (W, H), 0)
    px = m.load()
    for y in range(H):
        for x in range(W):
            if terrain[y][x] in chars:
                px[x, y] = 255
    return m


def lumpy(mask, seed, wobble=70.0, blur=5):
    """A cell mask blown up to pixels with a soft, wandering edge."""
    big = mask.resize((W * TILE, H * TILE), Image.BICUBIC).filter(ImageFilter.GaussianBlur(6))
    random.seed(seed)
    noise = Image.effect_noise((W * TILE // 4, H * TILE // 4), wobble).resize((W * TILE, H * TILE), Image.BICUBIC)
    noise = noise.filter(ImageFilter.GaussianBlur(blur))
    mixed = ImageChops.add(big, noise, 1.0, -128)
    return mixed.point(lambda v: 255 if v > 118 else 0)


def speckle(size, seed, grain, threshold):
    """Clumpy two-tone mottling mask."""
    random.seed(seed)
    n = Image.effect_noise((size[0] // grain, size[1] // grain), 60.0).resize(size, Image.NEAREST if grain <= 2 else Image.BICUBIC)
    return n.point(lambda v: 255 if v > threshold else 0)


def paint_ground(terrain):
    size = (W * TILE, H * TILE)
    rng = random.Random(3)
    open_mask = lumpy(cell_mask(terrain, ".:"), 11)
    trail_mask = lumpy(cell_mask(terrain, ":").filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.7)), 23, 55.0, 4)
    trail_mask = ImageChops.multiply(trail_mask, open_mask)
    deep = cell_mask(terrain, ".:").filter(ImageFilter.MaxFilter(9)).resize(size, Image.BICUBIC).filter(ImageFilter.GaussianBlur(24))

    def flat(c):
        return Image.new("RGB", size, c)

    # Forest floor: dark, cool, mottled; almost black far from any clearing.
    img = flat((20, 46, 44))
    img.paste(flat((25, 56, 50)), mask=speckle(size, 1, 10, 140))
    img.paste(flat((16, 38, 38)), mask=speckle(size, 2, 6, 168))
    img = Image.composite(img, flat((9, 20, 22)), deep)
    # Meadow: a rim of darker grass, then two greens.
    rim = open_mask.filter(ImageFilter.MaxFilter(9))
    img.paste(flat((30, 74, 50)), mask=rim)
    meadow = flat((50, 110, 58))
    meadow.paste(flat((60, 124, 60)), mask=speckle(size, 3, 12, 138))
    meadow.paste(flat((43, 97, 55)), mask=speckle(size, 4, 7, 160))
    img.paste(meadow, mask=open_mask)
    # Trail: darker lip, then two dirt tones and pebbles.
    lip = ImageChops.multiply(trail_mask.filter(ImageFilter.MaxFilter(7)), open_mask)
    img.paste(flat((66, 92, 52)), mask=lip)
    dirt = flat((146, 110, 74))
    dirt.paste(flat((131, 97, 65)), mask=speckle(size, 5, 8, 140))
    dirt.paste(flat((160, 124, 84)), mask=speckle(size, 6, 5, 176))
    img.paste(dirt, mask=trail_mask)
    # Hand-drawn bits: grass ticks on the meadow, pebbles on the trail.
    draw = ImageDraw.Draw(img)
    om, tm = open_mask.load(), trail_mask.load()
    for _ in range(9000):
        x, y = rng.randrange(4, size[0] - 4), rng.randrange(4, size[1] - 4)
        if tm[x, y]:
            if rng.random() < 0.35:
                c = rng.choice([(110, 82, 56), (176, 142, 100)])
                draw.rectangle((x, y, x + rng.randint(1, 2), y + 1), fill=c)
        elif om[x, y]:
            c = rng.choice([(74, 142, 66), (36, 86, 50), (88, 156, 70)])
            draw.line((x, y, x - 1, y - 3), fill=c)
            draw.line((x + 1, y, x + 2, y - 2), fill=c)
        elif rng.random() < 0.25:
            draw.point((x, y), fill=(30, 66, 56))
    out = os.path.join(PROJECT, "assets", "art", "ground")
    os.makedirs(out, exist_ok=True)
    img.save(os.path.join(out, AREA + ".png"))


# ---------------------------------------------------------------- the forest

def scatter(terrain, rows):
    """[(def name, x px, y px)]: the forest wall on blocked cells, growth in the meadow."""
    rng = random.Random(19)

    def is_open(x, y):
        return 0 <= x < W and 0 <= y < H and terrain[y][x] != "#"

    def ring(x, y):  # how far (in cells) the nearest open cell is, up to 4
        for d in range(1, 5):
            if any(is_open(x + dx, y + dy) for dx in range(-d, d + 1) for dy in range(-d, d + 1)):
                return d
        return 5

    out, taken = [], []

    def free(px, py, gap):
        return all((px - qx) ** 2 + ((py - qy) * 1.4) ** 2 >= gap * gap for qx, qy in taken)

    cells = [(x, y) for y in range(H) for x in range(W) if terrain[y][x] == "#"]
    rng.shuffle(cells)
    for x, y in cells:
        d = ring(x, y)
        if d > 3:
            continue
        px = x * TILE + 16 + rng.uniform(-9, 9)
        py = y * TILE + 24 + rng.uniform(-6, 6)
        gap = 44 if d == 1 else 54
        if not free(px, py, gap):
            continue
        # A tree's crown reaches several cells up from its foot. One that would roof over
        # walkable ground is swapped for something lower, so clearings stay readable and
        # only the crowns along the bottom edge lean in.
        def roofed(half, tall):
            return sum(1 for cx in range(x - half, x + half + 1) for cy in range(y - tall + 1, y) if is_open(cx, cy))

        roll = rng.random()
        if d >= 2 and roll < 0.14 and roofed(4, 9) == 0:
            kind = "tree_great"
        elif roll < 0.3 and roofed(2, 5) <= 3:
            kind = "tree_dead" if roll < 0.1 else "tree_wall"
        elif roofed(2, 5) <= 3:
            kind = "tree_wall"
        elif roofed(0, 4) <= 1:
            kind = "tree_pine"
        elif d == 1 and rng.random() < 0.6:
            kind = "bush"
        else:
            continue
        taken.append((px, py))
        out.append((kind, px, py))
    # Undergrowth: bushes hug the tree line, plants and flowers dot the meadow, never the trail.
    for y in range(H):
        for x in range(W):
            if rows[y][x] != ".":
                continue
            by_trees = any(not is_open(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1))
            roll = rng.random()
            px, py = x * TILE + rng.uniform(4, 28), y * TILE + rng.uniform(8, 30)
            if by_trees and roll < 0.2:
                out.append(("bush", px, py))
            elif roll < 0.2:
                out.append(("plant", px, py))
            elif roll < 0.27:
                out.append(("flower", px, py))
    return out


def write_layout(rows, points):
    used = sorted({LEGEND[c] for r in rows for c in r if c in LEGEND})
    mk = sorted({c for r in rows for c in r if c in MARKERS})
    ext = ['[ext_resource type="Script" path="res://scripts/world/area_layout.gd" id="1"]',
           '[ext_resource type="TileSet" path="res://assets/art/tiles/lpc/crypt.tres" id="2"]',
           '[ext_resource type="Script" path="res://scripts/world/prop_def.gd" id="3"]',
           f'[ext_resource type="Texture2D" path="res://assets/art/ground/{AREA}.png" id="4"]']
    ext += [f'[ext_resource type="Resource" path="res://data/props/wood_{n}.tres" id="p_{n}"]' for n in sorted(set(used) | set(SCATTER))]
    scenes = sorted(set(MARKERS[c] for c in mk))
    ext += [f'[ext_resource type="PackedScene" path="{s}" id="m{i}"]' for i, s in enumerate(scenes)]
    props = ",\n".join(f'"{c}": ExtResource("p_{n}")' for c, n in LEGEND.items() if n in used)
    markers = ",\n".join(f'"{c}": ExtResource("m{scenes.index(MARKERS[c])}")' for c in mk)
    lines = [f'[gd_resource type="Resource" script_class="AreaLayout" load_steps={len(ext) + 1} format=3]', ""] + ext
    lines += ["", "[resource]", 'script = ExtResource("1")', 'rows = "' + "\n".join(rows) + '\n"',
              'tileset = ExtResource("2")', "tile_seed = 9", 'wall_char = "#"', 'wall_set = "crypt"', "floors = {}",
              "props = {\n" + props + "\n}", "markers = {\n" + markers + "\n}", 'prop_floor = "."',
              'ground = ExtResource("4")',
              "scatter_defs = Array[ExtResource(\"3\")]([" + ", ".join(f'ExtResource("p_{n}")' for n in SCATTER) + "])",
              "scatter_points = PackedVector2Array(" + ", ".join(f"{x:.0f}, {y:.0f}" for _, x, y in points) + ")",
              "scatter_index = PackedInt32Array(" + ", ".join(str(SCATTER.index(k)) for k, _, _ in points) + ")",
              "place_names = PackedStringArray(" + ", ".join('"%s"' % n for n, *_ in named_places()) + ")",
              "place_rects = Array[Rect2i]([" + ", ".join("Rect2i(%d, %d, %d, %d)" % (x0, y0, x1 - x0, y1 - y0) for _, x0, y0, x1, y1 in named_places()) + "])",
              ""]
    with open(os.path.join(PROJECT, "data", "areas", AREA + ".tres"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    rows, terrain = layout()
    write_props()
    paint_ground(terrain)
    points = scatter(terrain, rows)
    write_layout(rows, points)
    print("\n".join(rows))
    print(len(points), "scattered props")
