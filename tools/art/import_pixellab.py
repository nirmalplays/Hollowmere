"""Build a character sheet from PixelLab frames (8-direction characters, see ASSETS.md).

Input folder (fetched with the account's MCP tools, kept outside the repo):
  <src>/rotations/<direction>.png            the standing pose per direction
  <src>/<animation>/<direction>/<i>.png      frames, i = 0..n-1
Directions are PixelLab's names (south, south-east, east, north-east, north, ...).
Only the right-hand side needs to exist: west, south-west and north-west are mirrored
from east, south-east and north-east. A direction with no frames borrows the nearest one.

Output, same format as the LPC importer so scenes don't care where art came from:
  assets/art/characters/<name>.png   one row per <anim>_<dir>
  data/sprites/<name>.tres

  python -I tools/art/import_pixellab.py <src folder> <name>
"""
import os
import sys

from PIL import Image, ImageOps

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from import_lpc import PROJECT, write_sheet_def  # noqa: E402

# our direction -> (PixelLab direction, mirrored)
DIRS = {"e": ("east", False), "se": ("south-east", False), "s": ("south", False), "sw": ("south-east", True),
        "w": ("east", True), "nw": ("north-east", True), "n": ("north", False), "ne": ("north-east", False)}
ORDER = ["south", "south-east", "east", "north-east", "north"]
# our animation -> (source animations in order of preference, fps, loop, frames to keep or None)
ANIMS = [
    ("idle", ("idle3", "idle"), 5, True, None),
    ("walk", ("run3", "run"), 12, True, None),
    ("run", ("run3", "run"), 14, True, None),
    ("attack", ("slash",), 16, False, None),
    ("block", ("idle3", "idle"), 1, True, 1),
    ("hurt", ("hurt",), 10, False, None),
    ("dead", ("death",), 9, False, None),
]


def frames(src, anims, direction):
    """Frames for the first animation that exists; falls back to the nearest direction, then the rotation."""
    want = ORDER.index(direction)
    for anim, near in [(a, d) for a in anims for d in sorted(ORDER, key=lambda d: abs(ORDER.index(d) - want))]:
        folder = os.path.join(src, anim, near)
        if os.path.isdir(folder):
            files = sorted((f for f in os.listdir(folder) if f.endswith(".png")), key=lambda f: int(os.path.splitext(f)[0]))
            if files:
                return [Image.open(os.path.join(folder, f)).convert("RGBA") for f in files]
    return [Image.open(os.path.join(src, "rotations", direction + ".png")).convert("RGBA")]


def main():
    src, name = sys.argv[1], sys.argv[2]
    rows, meta = [], []
    for our, source, fps, loop, keep in ANIMS:
        for d, (pl_dir, mirror) in DIRS.items():
            fr = frames(src, source, pl_dir)
            if keep:
                fr = fr[:keep]
            if mirror:
                fr = [ImageOps.mirror(f) for f in fr]
            rows.append(fr)
            meta.append((f"{our}_{d}", len(fr), fps, loop))
    size = rows[0][0].size
    cols = max(len(r) for r in rows)
    sheet = Image.new("RGBA", (cols * size[0], len(rows) * size[1]))
    for r, fr in enumerate(rows):
        for c, f in enumerate(fr):
            sheet.alpha_composite(f, (c * size[0], r * size[1]))
    stand = Image.open(os.path.join(src, "rotations", "south.png")).convert("RGBA")
    feet = stand.getchannel("A").getbbox()[3]
    sheet.save(os.path.join(PROJECT, "assets", "art", "characters", name + ".png"))
    write_sheet_def(name, size, meta, foot_inset=size[1] - feet + 1)
    print("character", name, sheet.size, len(meta), "animations, feet at", feet)


if __name__ == "__main__":
    main()
