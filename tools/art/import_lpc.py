"""Build character sheets from the Liberated Pixel Cup (LPC) layers.

Source: https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator
(checked out at $HOLLOWMERE_SOURCES/lpc; art CC-BY-SA 3.0 / GPL 3.0, see CREDITS.csv there).
LPC is native pixel art in the stylised, big-head look we want, so layers are only
composited (no pixelizing). LPC sheets: 64 px frames, rows up/left/down/right;
oversized weapon attacks use 128 px frames.

Output per character (same names as before, so scenes keep working):
  assets/art/characters/<name>.png  rows = <anim>_<dir> for 8 dirs, 128 px frames
  data/sprites/<name>.tres

  python -I tools/art/import_lpc.py
"""
import os
import sys

from PIL import Image, ImageOps

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixelize import SOURCES  # noqa: E402

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
LPC = os.path.join(SOURCES, "lpc", "spritesheets")
FRAME = 128
ROW = {"up": 0, "left": 1, "down": 2, "right": 3}
# Our 8 compass directions -> LPC's 4 rows (diagonals use the side view, like most LPC games).
DIRS = {"s": "down", "sw": "left", "w": "left", "nw": "left", "n": "up", "ne": "right", "e": "right", "se": "right"}

# our anim -> (LPC anim, first frame, frame count or None for all, fps, loop, fallback)
ANIMS = [
    ("idle", "idle", 0, None, 3, True, ("walk", 0, 1)),
    ("walk", "walk", 1, 8, 12, True, None),
    ("run", "run", 0, 8, 14, True, ("walk", 1, 8)),
    ("attack", "slash", 0, 6, 14, False, None),
    ("block", "combat_idle", 0, 1, 1, True, ("walk", 0, 1)),
    ("hurt", "hurt", 0, 2, 10, False, None),
    ("dead", "hurt", 0, 6, 9, False, None),
]

# Layers bottom -> top. Each: path template ("{anim}", optional "{color}") and options.
# "oversize": a 128 px attack sheet used only for the attack animation.
CHARACTERS = {
    "unlaid": [
        {"path": "weapon/sword/arming/attack_slash/bg/{color}.png", "color": "steel", "only": "slash", "oversize": True},
        {"path": "cape/tattered/bg/{anim}.png", "tint": (0.3, 0.36, 0.52)},
        {"path": "body/bodies/male/{anim}.png"},
        {"path": "head/heads/human/male/{anim}.png"},
        {"path": "feet/boots/basic/male/{anim}.png"},
        {"path": "legs/pants/male/{anim}/{color}.png", "color": "black"},
        {"path": "torso/armour/leather/male/{anim}.png"},
        {"path": "cape/tattered/fg/{anim}.png", "tint": (0.3, 0.36, 0.52)},
        {"path": "hat/cloth/hood/adult/{anim}.png", "tint": (0.36, 0.44, 0.66)},  # the Unlaid's slate-blue hood
        {"path": "shield/round/{anim}/{color}.png", "color": "brown"},
        {"path": "weapon/sword/arming/universal/fg/{anim}/{color}.png", "color": "steel", "skip": "slash"},
        {"path": "weapon/sword/arming/attack_slash/fg/{color}.png", "color": "steel", "only": "slash", "oversize": True},
    ],
    "hollow_husk": [
        {"path": "body/bodies/skeleton/{anim}.png", "tint": (0.82, 0.88, 0.96)},
        {"path": "head/heads/skeleton/adult/{anim}.png", "tint": (0.82, 0.88, 0.96)},
        {"path": "weapon/sword/arming/universal/fg/{anim}/{color}.png", "color": "iron", "skip": "slash"},
        {"path": "weapon/sword/arming/attack_slash/fg/{color}.png", "color": "iron", "only": "slash", "oversize": True},
    ],
    "hollow_shield": [
        {"path": "body/bodies/skeleton/{anim}.png", "tint": (0.82, 0.88, 0.96)},
        {"path": "head/heads/skeleton/adult/{anim}.png", "tint": (0.82, 0.88, 0.96)},
        {"path": "shield/round/{anim}/{color}.png", "color": "black"},
        {"path": "weapon/sword/arming/universal/fg/{anim}/{color}.png", "color": "iron", "skip": "slash"},
        {"path": "weapon/sword/arming/attack_slash/fg/{color}.png", "color": "iron", "only": "slash", "oversize": True},
    ],
    # The Gaunt Sexton (QUESTS ACT1_MQ01): a Hollowed gravedigger, ash-pale, sack hood, shovel.
    "gaunt_sexton": [
        {"path": "tools/shovel/bg/{anim}.png"},
        {"path": "cape/tattered/bg/{anim}.png", "tint": (0.34, 0.32, 0.3)},
        {"path": "body/bodies/male/{anim}.png", "tint": (0.78, 0.8, 0.84)},
        {"path": "head/heads/human/male/{anim}.png", "tint": (0.78, 0.8, 0.84)},
        {"path": "feet/boots/basic/male/{anim}.png"},
        {"path": "legs/pants/male/{anim}/{color}.png", "color": "brown"},
        {"path": "torso/armour/leather/male/{anim}.png", "tint": (0.45, 0.42, 0.4)},
        {"path": "cape/tattered/fg/{anim}.png", "tint": (0.34, 0.32, 0.3)},
        {"path": "hat/cloth/hood_sack/adult/{anim}.png", "tint": (0.62, 0.58, 0.52)},
        {"path": "tools/shovel/fg/{anim}.png"},
    ],
    "hollowed_zombie": [
        {"path": "body/bodies/zombie/{anim}/zombie.png"},
        {"path": "head/heads/zombie/adult/{anim}.png"},
        {"path": "legs/pants/male/{anim}/{color}.png", "color": "maroon"},
    ],
}

_cache = {}


def load(rel):
    if rel not in _cache:
        path = os.path.join(LPC, rel)
        _cache[rel] = Image.open(path).convert("RGBA") if os.path.exists(path) else None
    return _cache[rel]


def tint(img, rgb):
    lum = ImageOps.grayscale(img).point(lambda v: min(255, int(v * 1.5)))
    r, g, b = (lum.point(lambda v, k=k: int(v * k)) for k in rgb)
    return Image.merge("RGBA", (r, g, b, img.getchannel("A")))


def layer_sheet(layer, lpc_anim):
    if "only" in layer and layer["only"] != lpc_anim:
        return None, 64
    if layer.get("skip") == lpc_anim:
        return None, 64
    rel = layer["path"].format(anim=lpc_anim, color=layer.get("color", ""))
    img = load(rel)
    if img is None and "{color}" in layer["path"]:  # some items have no colour folders
        img = load(layer["path"].replace("/{color}", "").format(anim=lpc_anim))
    if img is not None and "tint" in layer:
        key = (rel, layer["tint"])
        if key not in _cache:
            _cache[key] = tint(img, layer["tint"])
        img = _cache[key]
    return img, (128 if layer.get("oversize") else 64)


# Standing poses many items don't draw: borrow the item's first walk frame instead.
STANDING = {"idle", "combat_idle"}


def frame(layers, lpc_anim, row, col):
    out = Image.new("RGBA", (FRAME, FRAME))
    for layer in layers:
        img, size = layer_sheet(layer, lpc_anim)
        use_col = col
        if img is None and lpc_anim in STANDING and not layer.get("only"):
            img, size = layer_sheet(layer, "walk")
            use_col = 0
        if img is None:
            continue
        col_saved, col = col, use_col
        r = min(row, img.height // size - 1)  # one-row sheets (hurt) face the camera only
        if (col + 1) * size > img.width:
            col = col_saved
            continue
        cell = img.crop((col * size, r * size, col * size + size, r * size + size))
        off = (FRAME - size) // 2
        out.alpha_composite(cell, (off, off))
        col = col_saved
    return out


def available(layers, lpc_anim):
    base, _ = layer_sheet(layers[0] if not layers[0].get("only") else layers[1], lpc_anim)
    for layer in layers:
        if layer.get("only") or layer.get("skip") == lpc_anim:
            continue
        img, _ = layer_sheet(layer, lpc_anim)
        if img is not None:
            return img.width // 64
    return 0


# Characters whose attack is a thrust (shovels, spears) rather than a slash.
ATTACK_ANIM = {"gaunt_sexton": "thrust"}


def build(name, layers):
    rows, meta = [], []
    for our, lpc_anim, first, count, fps, loop, fallback in ANIMS:
        if our == "attack" and name in ATTACK_ANIM:
            lpc_anim, count = ATTACK_ANIM[name], 8
        total = available(layers, lpc_anim)
        if total == 0 and fallback:
            lpc_anim, first, count = fallback
            total = available(layers, lpc_anim)
        if total == 0:
            continue
        count = count or total - first
        for d_name, lpc_dir in DIRS.items():
            frames = [frame(layers, lpc_anim, ROW[lpc_dir], first + i) for i in range(count)]
            rows.append(frames)
            meta.append((f"{our}_{d_name}", len(frames), fps, loop))
    cols = max(len(r) for r in rows)
    sheet = Image.new("RGBA", (cols * FRAME, len(rows) * FRAME))
    for r, frames in enumerate(rows):
        for c, fr in enumerate(frames):
            sheet.alpha_composite(fr, (c * FRAME, r * FRAME))
    # Feet: the lowest opaque row of the standing-down frame.
    probe = rows[[m[0] for m in meta].index("idle_s")][0]
    feet = probe.getchannel("A").getbbox()[3]
    out = os.path.join(PROJECT, "assets", "art", "characters", name + ".png")
    sheet.save(out)
    write_sheet_def(name, (FRAME, FRAME), meta, foot_inset=FRAME - feet + 1)
    print("character", name, sheet.size, len(meta), "animations, feet at", feet)


def write_sheet_def(name, frame, meta, foot_inset):
    """SpriteSheetDef .tres: one animation per sheet row."""
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
    with open(os.path.join(PROJECT, "data", "sprites", name + ".tres"), "w", encoding="utf-8", newline="
") as f:
        f.write("
".join(out))


def main():
    for name in sys.argv[1:] or list(CHARACTERS):
        build(name, CHARACTERS[name])


if __name__ == "__main__":
    main()
