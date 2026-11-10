"""Generate the placeholder dungeon tile atlas (generated art, replaceable).

Atlas: 16x16 tiles in one row. Index order MUST match assets/art/tiles/dungeon_tileset.tres (tile_name custom data):
  0 floor_a, 1 floor_b (moss), 2 floor_c (cracked), 3 floor_ash (Hollow-touched),
  4 wall_top, 5 wall_face
Output: assets/art/tiles/dungeon_tiles.png
"""
import random

from common import Canvas, save, sheet

T = 16


def floor(seed, extra=None):
    rnd = random.Random(seed)
    c = Canvas(T, T)
    c.rect(0, 0, 15, 15, "stone_mid")
    # Brick grout: two courses per tile, offset joints.
    c.rect(0, 7, 15, 7, "stone_dark")
    c.rect(0, 15, 15, 15, "stone_dark")
    c.rect(4, 0, 4, 6, "stone_dark")
    c.rect(12, 8, 12, 14, "stone_dark")
    c.rect(0, 0, 3, 0, "stone_light")
    c.rect(5, 0, 15, 0, "stone_light")
    c.rect(0, 8, 11, 8, "stone_light")
    c.rect(13, 8, 15, 8, "stone_light")
    for _ in range(6):
        c.dot(rnd.randrange(16), rnd.randrange(16), rnd.choice(["stone_light", "stone_dark"]))
    if extra:
        extra(c, rnd)
    return c.to_image()


def moss(c, rnd):
    for _ in range(10):
        x, y = rnd.randrange(16), rnd.randrange(16)
        c.dot(x, y, rnd.choice(["moss_light", "moss_dark"]))


def crack(c, rnd):
    x, y = 3, 2
    for _ in range(12):
        c.dot(x, y, "stone_deep")
        x = min(15, max(0, x + rnd.choice([0, 1, 1])))
        y = min(15, y + 1)


def ash(c, rnd):
    for _ in range(14):
        c.dot(rnd.randrange(16), rnd.randrange(16), rnd.choice(["ash_light", "ash_dark", "ash_dark"]))


def wall_top(seed):
    rnd = random.Random(seed)
    c = Canvas(T, T)
    c.rect(0, 0, 15, 15, "stone_deep")
    for _ in range(8):
        c.dot(rnd.randrange(16), rnd.randrange(16), "stone_dark")
    return c.to_image()


def wall_face(seed):
    rnd = random.Random(seed)
    c = Canvas(T, T)
    c.rect(0, 0, 15, 15, "stone_dark")
    c.rect(0, 0, 15, 1, "stone_light")  # lit top lip
    for y in (5, 10):
        c.rect(0, y, 15, y, "stone_deep")
    for x, y0, y1 in ((6, 2, 4), (11, 6, 9), (3, 6, 9), (8, 11, 14)):
        c.rect(x, y0, x, y1, "stone_deep")
    c.rect(0, 15, 15, 15, "water_black")  # contact shadow with the floor
    for _ in range(5):
        c.dot(rnd.randrange(16), rnd.randrange(2, 14), "stone_mid")
    return c.to_image()


def main():
    tiles = [
        floor(1),
        floor(2, moss),
        floor(3, crack),
        floor(4, ash),
        wall_top(5),
        wall_face(6),
    ]
    save(sheet([tiles], T, T, len(tiles)), "assets/art/tiles/dungeon_tiles.png")


if __name__ == "__main__":
    main()
