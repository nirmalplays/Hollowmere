"""Shared helpers for generated pixel art (GAME_PLAN 11.1b).

Sprites are drawn as grids of palette color names, then an automatic 1px outline
pass is applied. Everything is deterministic so art can be tweaked by editing code.
"""
import json
import math
import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.normpath(os.path.join(HERE, "..", ".."))

with open(os.path.join(HERE, "palette.json"), encoding="utf-8") as f:
    PALETTE = {k: v for k, v in json.load(f).items() if not k.startswith("_")}
assert len(PALETTE) <= 32, "palette cap is 32 colors"


def rgba(name):
    h = PALETTE[name].lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


class Canvas:
    """Grid of palette names (None = transparent) with an optional design-grid scale."""

    def __init__(self, w, h, scale=1.0, ox=0, oy=0):
        self.w, self.h, self.s, self.ox, self.oy = w, h, scale, ox, oy
        self.px = [[None] * w for _ in range(h)]

    def _map(self, v, o):
        return int(math.floor(v * self.s)) + o

    def put(self, x, y, color):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = color

    def rect(self, x0, y0, x1, y1, color):
        """Inclusive rect in design-grid coordinates (scaled into the canvas)."""
        for y in range(self._map(y0, self.oy), self._map(y1 + 1, self.oy)):
            for x in range(self._map(x0, self.ox), self._map(x1 + 1, self.ox)):
                self.put(x, y, color)

    def dot(self, x, y, color):
        self.rect(x, y, x, y, color)

    def outline(self, color="outline"):
        filled = [[c is not None for c in row] for row in self.px]
        for y in range(self.h):
            for x in range(self.w):
                if filled[y][x]:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < self.w and 0 <= ny < self.h and filled[ny][nx]:
                        self.px[y][x] = color
                        break

    def flip_h(self):
        for row in self.px:
            row.reverse()

    def to_image(self):
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        for y, row in enumerate(self.px):
            for x, c in enumerate(row):
                if c is not None:
                    img.putpixel((x, y), rgba(c))
        return img


def save(img, rel_path):
    path = os.path.join(PROJECT, rel_path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("wrote", rel_path, img.size)
    return path


def sheet(frames_by_row, fw, fh, cols):
    """frames_by_row: list of rows, each a list of PIL images. Rows = animations."""
    img = Image.new("RGBA", (fw * cols, fh * len(frames_by_row)), (0, 0, 0, 0))
    for r, row in enumerate(frames_by_row):
        for c, fr in enumerate(row):
            img.paste(fr, (c * fw, r * fh))
    return img
