"""Cut outdoor props (trees, plants, logs, rocks, camp pieces) out of the LPC packs.

Sources (in $HOLLOWMERE_SOURCES/lpc_env, see ASSETS.md):
  lpc-trees/lpc-trees/trees-green.png, trees-dead.png   [LPC] Trees Mega-Pack (CC-BY-SA 3.0)
  LPC_forest_0/LPC_forest/forest_tiles.png              LPC Forest Tiles (CC-BY-SA 3.0)
Trees are found by flood fill (each sprite with its baked shadow is one island) and
picked by a point inside them; forest pieces are cut on the 32 px grid.
Output: assets/art/props/wild/<name>.png

  python -I tools/art/import_outdoor.py
"""
import os
import sys
from collections import deque

from PIL import Image

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
# The raw packs ship with the project in sources/; HOLLOWMERE_SOURCES overrides.
SOURCES = os.environ.get("HOLLOWMERE_SOURCES", os.path.join(PROJECT, "sources"))
ENV = os.path.join(SOURCES, "lpc_env")
OUT = os.path.join(PROJECT, "assets", "art", "props", "wild")

# name -> a point inside the sprite on the trees sheet
TREES = {
    "oak_great": (405, 800), "oak_dense": (670, 800),
    "oak_a": (385, 580), "oak_b": (575, 580), "oak_c": (755, 580), "oak_d": (910, 580),
    "round_a": (75, 590), "round_b": (220, 590),
    "leafy_a": (478, 410), "leafy_b": (608, 410), "leafy_c": (765, 410), "leafy_d": (940, 410),
    "pine_a": (95, 430), "pine_b": (30, 420), "pine_c": (30, 285),
    "bush_a": (15, 80), "bush_b": (47, 80), "bush_c": (80, 76),
    "mid_a": (170, 160), "mid_b": (270, 150), "mid_c": (368, 150), "mid_d": (480, 150), "mid_e": (590, 150),
}
DEAD = ["oak_a", "oak_c", "leafy_c", "mid_d", "round_a"]  # also cut from trees-dead.png as dead_<name>

# name -> (x, y, w, h) on forest_tiles.png
FOREST = {
    "plant_a": (0, 96, 32, 32), "plant_b": (32, 96, 32, 32), "plant_c": (64, 96, 32, 32),
    "plant_d": (96, 96, 32, 32), "flower_a": (128, 96, 32, 32), "flower_b": (160, 96, 32, 32),
    "stump": (192, 96, 32, 32), "log_a": (224, 96, 64, 32), "log_b": (288, 96, 64, 32),
    "rock_big": (352, 32, 64, 32), "rock_small": (384, 32, 32, 32), "mushrooms": (416, 0, 32, 32),
    "fern": (416, 64, 32, 32), "campfire_cold": (0, 160, 32, 32), "campfire": (32, 160, 32, 32),
    "pine_small": (320, 32, 32, 64), "hut": (448, 64, 64, 64), "woodpile": (352, 64, 64, 32),
}


def islands(im):
    """Label connected opaque regions; returns {label: (x0, y0, x1, y1)} and the label map."""
    w, h = im.size
    alpha = im.getchannel("A").load()
    label = [[0] * w for _ in range(h)]
    boxes = {}
    n = 0
    for y in range(h):
        for x in range(w):
            if alpha[x, y] == 0 or label[y][x]:
                continue
            n += 1
            box = [x, y, x, y]
            todo = deque([(x, y)])
            label[y][x] = n
            while todo:
                cx, cy = todo.popleft()
                box = [min(box[0], cx), min(box[1], cy), max(box[2], cx), max(box[3], cy)]
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h and not label[ny][nx] and alpha[nx, ny] > 0:
                            label[ny][nx] = n
                            todo.append((nx, ny))
            boxes[n] = tuple(box)
    return boxes, label


def cut_trees(sheet, names, prefix=""):
    im = Image.open(os.path.join(ENV, "lpc-trees", "lpc-trees", sheet)).convert("RGBA")
    boxes, label = islands(im)
    for name in names:
        x, y = TREES[name]
        found = label[y][x]
        if not found:  # the point missed: take the nearest island
            found = min(boxes, key=lambda k: (max(boxes[k][0] - x, 0, x - boxes[k][2]) ** 2 + max(boxes[k][1] - y, 0, y - boxes[k][3]) ** 2))
        x0, y0, x1, y1 = boxes[found]
        tile = im.crop((x0, y0, x1 + 1, y1 + 1))
        # Drop pixels of other islands that fall inside the box.
        px = tile.load()
        for ty in range(tile.height):
            for tx in range(tile.width):
                if label[y0 + ty][x0 + tx] != found:
                    px[tx, ty] = (0, 0, 0, 0)
        tile.save(os.path.join(OUT, prefix + name + ".png"))
        print(prefix + name, tile.size)


def cut_forest():
    im = Image.open(os.path.join(ENV, "LPC_forest_0", "LPC_forest", "forest_tiles.png")).convert("RGBA")
    for name, (x, y, w, h) in FOREST.items():
        tile = im.crop((x, y, x + w, y + h))
        box = tile.getbbox()
        if box is None:
            print("EMPTY", name)
            continue
        tile.crop(box).save(os.path.join(OUT, name + ".png"))


def main():
    os.makedirs(OUT, exist_ok=True)
    cut_trees("trees-green.png", list(TREES))
    cut_trees("trees-dead.png", DEAD, "dead_")
    cut_forest()
    if len(sys.argv) > 1:  # a contact sheet to eyeball the cuts
        files = sorted(f for f in os.listdir(OUT) if f.endswith(".png"))
        ims = [Image.open(os.path.join(OUT, f)).convert("RGBA") for f in files]
        rows, row, width = [], [], 0
        for i in ims:
            if width + i.width + 6 > 1500 and row:
                rows.append(row)
                row, width = [], 0
            row.append(i)
            width += i.width + 6
        rows.append(row)
        sheet = Image.new("RGBA", (1500, sum(max(i.height for i in r) + 6 for r in rows)), (52, 82, 58, 255))
        y = 0
        for r in rows:
            x, hh = 3, max(i.height for i in r)
            for i in r:
                sheet.alpha_composite(i, (x, y + hh - i.height + 3))
                x += i.width + 6
            y += hh + 6
        sheet.save(sys.argv[1])


if __name__ == "__main__":
    main()
