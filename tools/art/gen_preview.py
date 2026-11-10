"""Build tools/art/preview.png: every generated sprite on a tile backdrop, scaled 4x.

Re-run after any art batch so the owner can review (GAME_PLAN 11.1b).
Includes the M1 size comparison (16x24 vs 32x32 against 16x16 tiles).
"""
import os

from PIL import Image, ImageDraw

from common import HERE, PROJECT

ZOOM = 4


def load(rel):
    return Image.open(os.path.join(PROJECT, rel)).convert("RGBA")


def backdrop(tiles, w_tiles, h_tiles):
    bg = Image.new("RGBA", (w_tiles * 16, h_tiles * 16))
    for ty in range(h_tiles):
        for tx in range(w_tiles):
            idx = 4 if ty == 0 else (5 if ty == 1 else (tx * 7 + ty * 3) % 4)
            bg.paste(tiles.crop((idx * 16, 0, idx * 16 + 16, 16)), (tx * 16, ty * 16))
    return bg


def strip(sheet_img, fw, fh, row, count, y_floor, bg, x0):
    for i in range(count):
        fr = sheet_img.crop((i * fw, row * fh, i * fw + fw, row * fh + fh))
        bg.alpha_composite(fr, (x0 + i * (fw + 4), y_floor - fh))


def main():
    tiles = load("assets/art/tiles/dungeon_tiles.png")
    small = load("assets/art/characters/unlaid_16x24.png")
    large = load("assets/art/characters/unlaid_32x32.png")

    bg = backdrop(tiles, 18, 8)
    # Row 1: 16x24 idle down/up/side + walk_down cycle. Row 2: same for 32x32.
    for r, sheet_img, fw, fh, y in ((0, small, 16, 24, 72), (0, large, 32, 32, 120)):
        x = 4
        for row in (0, 1, 2):
            strip(sheet_img, fw, fh, row, 1, y, bg, x)
            x += fw + 4
        strip(sheet_img, fw, fh, 3, 6, y, bg, x + 8)

    img = bg.resize((bg.width * ZOOM, bg.height * ZOOM), Image.NEAREST)
    d = ImageDraw.Draw(img)
    d.text((8, 4), "Tiles: floor a/b/c/ash, wall top, wall face", fill=(255, 255, 255, 255))
    d.text((8, 40 * ZOOM), "16x24 (chosen)", fill=(255, 224, 138, 255))
    d.text((8, 82 * ZOOM), "32x32 (comparison)", fill=(200, 200, 200, 255))
    out = os.path.join(HERE, "preview.png")
    img.save(out)
    print("wrote tools/art/preview.png", img.size)


if __name__ == "__main__":
    main()
