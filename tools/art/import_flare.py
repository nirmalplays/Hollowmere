"""Build pixel-art character sheets from Flare's 8-direction sprites (CC-BY-SA 3.0).

Source: https://github.com/flareteam/flare-game (mods/fantasycore), checked out at
$HOLLOWMERE_SOURCES/flare-game. Layered avatars are composited in Flare's
per-direction draw order, then pixelized (tools/art/pixelize.py) to our scale.

Output per character:
  assets/art/characters/<name>.png   rows = <anim>_<dir> (8 dirs each), cols = frames
  data/sprites/<name>.tres           SpriteSheetDef with one animation per row

Directions use compass names: s, sw, w, nw, n, ne, e, se (s = toward the camera).

  python -I tools/art/import_flare.py
"""
import os
import re
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixelize import SOURCES, apply_palette, build_palette, outline  # noqa: E402
from pixelize import alpha_cut, downscale, enhance, remove_shadows, sharpen  # noqa: E402

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
FLARE = os.path.join(SOURCES, "flare-game", "mods", "fantasycore")
FLARE_DIRS = ["w", "nw", "n", "ne", "e", "se", "s", "sw"]  # Flare direction index order (verified visually)
OUR_DIRS = ["s", "sw", "w", "nw", "n", "ne", "e", "se"]

CANVAS = 200  # composite canvas, feet at FEET
FEET = (100, 170)

# our animation name -> (flare section, loop)
ANIMS = [
    ("idle", "stance", True),
    ("walk", "run", True),
    ("attack", "swing", False),
    ("block", "block", False),
    ("hurt", "hit", False),
    ("dead", "die", False),
]

CHARACTERS = {
    # The Unlaid: hooded, leather-clad, short blade and buckler.
    "unlaid": {
        "layers": {
            "head": "avatar/male/leather_hood", "chest": "avatar/male/chain_cuirass",
            "legs": "avatar/male/leather_pants", "feet": "avatar/male/leather_boots",
            "hands": "avatar/male/leather_gloves", "main": "avatar/male/shortsword",
            "off": "avatar/male/buckler",
        },
        "tints": {"head": (0.55, 0.68, 1.0)},  # slate-blue hood, the Unlaid's colour
        "scale": 0.34, "colors": 48, "frame": (64, 64),
        "look": {"brightness": 1.45, "contrast": 1.3, "color": 1.35},
    },
    # A Hollowed husk for the training ground (Flare's weak skeleton).
    "hollow_husk": {
        "layers": {"body": "enemies/skeleton_weak"},
        "tints": {"body": (0.78, 0.84, 0.92)},  # ash-pale: the Hollow drains colour
        "scale": 0.27, "colors": 28, "frame": (64, 64), "feet_margin": 14,
        "look": {"brightness": 1.2, "contrast": 1.25, "color": 1.1},
    },
    "hollowed_zombie": {
        "layers": {"body": "enemies/zombie"},
        "tints": {"body": (0.62, 0.72, 0.74)},
        "scale": 0.3, "colors": 28, "frame": (64, 64),
        "look": {"brightness": 1.3, "contrast": 1.25, "color": 1.1},
    },
}


def parse_animation(path):
    """Returns (image_path, {section: {"frames", "ms", "type", "cells": {(i, d): (x, y, w, h, ox, oy)}}})."""
    image, sections, cur = None, {}, None
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith("image="):
                image = line.split("=", 1)[1]
            elif line.startswith("[") and line.endswith("]"):
                cur = {"frames": 1, "ms": 100, "type": "looped", "cells": {}}
                sections[line[1:-1]] = cur
            elif cur is None:
                continue
            elif line.startswith("frames="):
                cur["frames"] = int(line.split("=")[1])
            elif line.startswith("duration="):
                cur["ms"] = int(re.sub(r"[^0-9]", "", line.split("=")[1]) or 100) * (1000 if line.endswith("s") and not line.endswith("ms") else 1)
            elif line.startswith("type="):
                cur["type"] = line.split("=")[1]
            elif line.startswith("frame="):
                v = [int(n) for n in line.split("=")[1].split(",")]
                cur["cells"][(v[0], v[1])] = tuple(v[2:8])
    return os.path.join(FLARE, image), sections


def layer_order():
    order = {}
    with open(os.path.join(FLARE, "engine", "hero_layers.txt"), encoding="utf-8") as f:
        for line in f:
            if line.startswith("layer="):
                parts = line.strip().split("=")[1].split(",")
                order[parts[0].lower()] = parts[1:]
    return order


def tint(img, rgb):
    """Recolour a layer by its luminance, keeping shading: used to give layers our palette."""
    from PIL import ImageOps
    lum = ImageOps.grayscale(img).point(lambda v: min(255, int(v * 1.6)))
    r, g, b = (lum.point(lambda v, k=k: int(v * k)) for k in rgb)
    out = Image.merge("RGBA", (r, g, b, img.getchannel("A")))
    return out


def compose(layers, order, section, i, flare_dir):
    canvas = Image.new("RGBA", (CANVAS, CANVAS))
    names = order.get(FLARE_DIRS[flare_dir], list(layers)) if len(layers) > 1 else list(layers)
    for kind in names:
        if kind not in layers:
            continue
        img, sections = layers[kind]
        sec = sections.get(section)
        if not sec or (i, flare_dir) not in sec["cells"]:
            continue
        x, y, w, h, ox, oy = sec["cells"][(i, flare_dir)]
        canvas.alpha_composite(img.crop((x, y, x + w, y + h)), (FEET[0] - ox, FEET[1] - oy))
    return canvas


def frame_sequence(sec):
    n = sec["frames"]
    if sec["type"] == "back_forth" and n > 2:
        return list(range(n)) + list(range(n - 2, 0, -1))
    return list(range(n))


def build(name, spec, order):
    layers = {}
    for kind, rel in spec["layers"].items():
        img_path, sections = parse_animation(os.path.join(FLARE, "animations", rel + ".txt"))
        img = Image.open(img_path).convert("RGBA")
        if kind in spec.get("tints", {}):
            img = tint(img, spec["tints"][kind])
        layers[kind] = (img, sections)
    any_sections = next(iter(layers.values()))[1]
    scale, (fw, fh) = spec["scale"], spec["frame"]
    feet_s = (round(FEET[0] * scale), round(FEET[1] * scale))
    margin = spec.get("feet_margin", 4)  # space under the feet anchor for limbs that hang below it
    rows, meta = [], []
    for our_name, section, loop in ANIMS:
        sec = any_sections.get(section)
        if sec is None:
            continue
        seq = frame_sequence(sec)
        fps = len(seq) / max(sec["ms"] / 1000.0, 0.05) if sec["type"] != "back_forth" else len(seq) / (2 * sec["ms"] / 1000.0)
        for d_name in OUR_DIRS:
            fd = FLARE_DIRS.index(d_name)
            frames = []
            for i in seq:
                look = spec.get("look", {})
                big = sharpen(enhance(remove_shadows(compose(layers, order, section, i, fd)), **look), 200)
                small = alpha_cut(downscale(big, scale))
                cell = Image.new("RGBA", (fw, fh))
                cell.alpha_composite(small, (fw // 2 - feet_s[0], fh - margin - feet_s[1]))
                frames.append(cell)
            rows.append(frames)
            meta.append((f"{our_name}_{d_name}", len(frames), fps, loop))
    palette = build_palette([f for r in rows for f in r], spec["colors"])
    cols = max(len(r) for r in rows)
    sheet = Image.new("RGBA", (cols * fw, len(rows) * fh))
    for r, frames in enumerate(rows):
        for c, fr in enumerate(frames):
            sheet.alpha_composite(outline(apply_palette(fr, palette)), (c * fw, r * fh))
    out_png = os.path.join(PROJECT, "assets", "art", "characters", name + ".png")
    os.makedirs(os.path.dirname(out_png), exist_ok=True)
    sheet.save(out_png)
    write_sheet_def(name, (fw, fh), meta, foot_inset=margin)
    print("character", name, sheet.size, len(meta), "animations")


def write_sheet_def(name, frame, meta, foot_inset):
    out = [f'[gd_resource type="Resource" script_class="SpriteSheetDef" load_steps={3 + len(meta)} format=3]', "",
           '[ext_resource type="Script" path="res://scripts/systems/animation/sprite_sheet_def.gd" id="1"]',
           '[ext_resource type="Script" path="res://scripts/systems/animation/sprite_anim_row.gd" id="2"]',
           f'[ext_resource type="Texture2D" path="res://assets/art/characters/{name}.png" id="3"]', ""]
    for i, (anim, count, fps, loop) in enumerate(meta):
        out += [f'[sub_resource type="Resource" id="a{i}"]', 'script = ExtResource("2")', f'name = &"{anim}"',
                f"row = {i}", "column = 0", f"frame_count = {count}", f"fps = {fps:.2f}",
                f"loop = {'true' if loop else 'false'}", ""]
    refs = ", ".join(f'SubResource("a{i}")' for i in range(len(meta)))
    out += ["[resource]", 'script = ExtResource("1")', 'texture = ExtResource("3")',
            f"frame_size = Vector2i({frame[0]}, {frame[1]})", f'animations = Array[ExtResource("2")]([{refs}])',
            f"foot_inset = {foot_inset}", ""]
    path = os.path.join(PROJECT, "data", "sprites", name + ".tres")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))


def main():
    order = layer_order()
    wanted = sys.argv[1:] or list(CHARACTERS)
    for name in wanted:
        build(name, CHARACTERS[name], order)


if __name__ == "__main__":
    main()
