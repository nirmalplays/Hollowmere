"""Import free environment art into the project (pixelized or copied as-is).

Rendered packs are pixelized to the characters' scale (tools/art/pixelize.py);
native pixel-art packs are copied unchanged. Sources live in $HOLLOWMERE_SOURCES/oga
(downloaded from OpenGameArt; licenses in ASSETS.md and assets/art/LICENSES.md).

  python -I tools/art/import_props.py
"""
import os
import shutil
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pixelize import SOURCES, build_palette, pixelize_one, trim  # noqa: E402

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OGA = os.path.join(SOURCES, "oga")
OUT = os.path.join(PROJECT, "assets", "art")

# (group, sheet, cell w, cell h, scale, colours, look) -- every non-empty cell becomes a sprite.
GRID_SHEETS = [
    ("trees", "trees_01.png", 384, 768, 0.25, 32, {"color": 0.95, "contrast": 1.15, "brightness": 1.0}),  # Isometric Trees (CC0)
    ("props_small", "props/props_1x1.png", 128, 128, 0.32, 24, {}),  # Isometric Props and Tents (CC0)
    ("props_medium", "props/props_2x2.png", 256, 256, 0.32, 24, {}),
    ("props_large", "props/props_4x4.png", 512, 512, 0.32, 24, {}),
]
RUINS_SCALE = 0.4  # Isometric - Dark Ruins (CC0), one piece per file

# Native pixel-art packs, copied unchanged.
COPY = [
    ("forest/Forest Isometric Pack Free/Atlas_files/Tileset_Atlas.png", "tiles/kf_forest_tiles.png"),
    ("forest/Forest Isometric Pack Free/Atlas_files/Rocks.png", "tiles/kf_forest_rocks.png"),
    ("forest/Forest Isometric Pack Free/Atlas_files/Leaves.png", "tiles/kf_forest_grass.png"),
    ("forest/Forest Isometric Pack Free/Trees/Tree_1.png", "props/kf_trees/tree_1.png"),
    ("forest/Forest Isometric Pack Free/Trees/Tree_2.png", "props/kf_trees/tree_2.png"),
    ("forest/Forest Isometric Pack Free/Trees/Tree_3.png", "props/kf_trees/tree_3.png"),
    ("forest/Forest Isometric Pack Free/Trees/death_Tree_2.png", "props/kf_trees/dead_tree_2.png"),
    ("forest/Forest Isometric Pack Free/Trees/death_Tree_3.png", "props/kf_trees/dead_tree_3.png"),
    ("tileset_cave.png", "tiles/kf_cave_tiles.png"),
    ("decorations_cave.png", "tiles/kf_cave_decorations.png"),
    ("minerals_cave.png", "tiles/kf_cave_minerals.png"),
    ("overworld_no_spaces_updated_0.png", "tiles/iso_overworld_32.png"),
]


def save(img, rel):
    path = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)


def cells(sheet, cw, ch):
    for r in range(sheet.height // ch):
        for c in range(sheet.width // cw):
            cell = sheet.crop((c * cw, r * ch, c * cw + cw, r * ch + ch))
            if cell.getchannel("A").getbbox():
                yield r, c, cell


def import_grid(group, rel, cw, ch, scale, colours, look):
    sheet = Image.open(os.path.join(OGA, rel)).convert("RGBA")
    found = list(cells(sheet, cw, ch))
    palette = build_palette([pixelize_one(cell, scale, None, False, **look) for _, _, cell in found[::4]], colours)
    for r, c, cell in found:
        save(trim(pixelize_one(cell, scale, palette, **look), 1), f"props/{group}/{group}_r{r:02d}c{c:02d}.png")
    print(group, len(found), "sprites")


def import_ruins():
    pieces = sorted(f for f in os.listdir(os.path.join(OGA, "ruins")) if f[:2].isdigit())
    imgs = [Image.open(os.path.join(OGA, "ruins", f)).convert("RGBA") for f in pieces]
    look = {"contrast": 1.2, "color": 1.2, "brightness": 1.4}
    palette = build_palette([pixelize_one(i, RUINS_SCALE, None, False, **look) for i in imgs], 32)
    for f, img in zip(pieces, imgs):
        save(trim(pixelize_one(img, RUINS_SCALE, palette, **look), 1), f"props/ruins/ruin_{f}")
    print("ruins", len(pieces), "sprites")


def main():
    only = sys.argv[1:]
    if only:
        for args in GRID_SHEETS:
            if args[0] in only:
                import_grid(*args)
        return
    for src, dst in COPY:
        path = os.path.join(OUT, dst)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        shutil.copy(os.path.join(OGA, src), path)
    print("copied", len(COPY), "native pixel files")
    import_ruins()
    for args in GRID_SHEETS:
        import_grid(*args)


if __name__ == "__main__":
    main()
