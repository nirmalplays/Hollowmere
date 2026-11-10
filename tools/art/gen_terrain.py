"""Generate 3D terrain textures (generated art, replaceable). 32 px = 1 metre.

Each texture tiles seamlessly (noise wraps). Output: assets/art/terrain/<name>.png
  grass, grass_dark, moss, path_stone, ash, cliff_side, wall_side, wall_top, dirt
"""
import math
import random

from PIL import Image

from common import rgba, save

S = 32


def hexc(name):
    return rgba(name)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


def value_noise(seed, cells):
    """Tileable value noise sampler in 0..1 with `cells` lattice cells per tile."""
    rnd = random.Random(seed)
    lat = [[rnd.random() for _ in range(cells)] for _ in range(cells)]

    def smooth(t):
        return t * t * (3 - 2 * t)

    def sample(x, y):
        fx, fy = x / S * cells, y / S * cells
        x0, y0 = int(math.floor(fx)) % cells, int(math.floor(fy)) % cells
        x1, y1 = (x0 + 1) % cells, (y0 + 1) % cells
        tx, ty = smooth(fx - math.floor(fx)), smooth(fy - math.floor(fy))
        a = lat[y0][x0] + (lat[y0][x1] - lat[y0][x0]) * tx
        b = lat[y1][x0] + (lat[y1][x1] - lat[y1][x0]) * tx
        return a + (b - a) * ty

    return sample


def ramp(colors, t):
    """Hard-stepped palette ramp (pixel art: no smooth gradients)."""
    i = min(len(colors) - 1, max(0, int(t * len(colors))))
    return hexc(colors[i])


def grass(seed, colors):
    n1, n2 = value_noise(seed, 4), value_noise(seed + 1, 8)
    img = Image.new("RGBA", (S, S))
    for y in range(S):
        for x in range(S):
            t = n1(x, y) * 0.65 + n2(x, y) * 0.35
            img.putpixel((x, y), ramp(colors, t))
    rnd = random.Random(seed + 2)
    for _ in range(26):  # little blades: a bright tip over a dark root
        x, y = rnd.randrange(S), rnd.randrange(S)
        img.putpixel((x, y), hexc(colors[-1]))
        img.putpixel((x, (y + 1) % S), hexc(colors[0]))
    return img


def path_stone(seed):
    """Irregular flagstones with dark grout and lit top-left edges."""
    rnd = random.Random(seed)
    pts = [(rnd.uniform(0, S), rnd.uniform(0, S)) for _ in range(7)]
    shades = [rnd.choice(["stone_light", "stone_mid", "stone_mid"]) for _ in pts]
    img = Image.new("RGBA", (S, S))

    def nearest2(x, y):
        ds = []
        for i, (px, py) in enumerate(pts):
            dx = min(abs(x - px), S - abs(x - px))
            dy = min(abs(y - py), S - abs(y - py))
            ds.append((dx * dx + dy * dy, i))
        ds.sort()
        return ds[0], ds[1]

    for y in range(S):
        for x in range(S):
            (d0, i0), (d1, _) = nearest2(x, y)
            edge = math.sqrt(d1) - math.sqrt(d0)
            if edge < 1.1:
                c = hexc("stone_deep")
            else:
                c = hexc(shades[i0])
                (dl, il), _ = nearest2((x - 1) % S, (y - 1) % S)
                if il != i0:
                    c = mix(c, hexc("ash_light"), 0.35)  # lit edge
            img.putpixel((x, y), c)
    for _ in range(8):
        img.putpixel((rnd.randrange(S), rnd.randrange(S)), hexc("moss_dark"))
    return img


def ash(seed):
    n = value_noise(seed, 6)
    img = Image.new("RGBA", (S, S))
    for y in range(S):
        for x in range(S):
            img.putpixel((x, y), ramp(["stone_mid", "ash_dark", "ash_dark", "ash_light"], n(x, y)))
    return img


def strata(seed, bands, crack):
    """Rock face: horizontal strata with a lit top lip and cracks."""
    rnd = random.Random(seed)
    n = value_noise(seed, 4)
    img = Image.new("RGBA", (S, S))
    for y in range(S):
        for x in range(S):
            band = int((y + n(x, y) * 5) / (S / len(bands))) % len(bands)
            img.putpixel((x, y), hexc(bands[band]))
    for _ in range(5):
        x, y = rnd.randrange(S), rnd.randrange(S)
        for _ in range(rnd.randrange(4, 9)):
            img.putpixel((x % S, y % S), hexc(crack))
            x += rnd.choice([-1, 0, 1])
            y += 1
    return img


def wall_side(seed):
    """Cut stone blocks for built walls."""
    rnd = random.Random(seed)
    img = Image.new("RGBA", (S, S), hexc("stone_mid"))
    rows = [0, 8, 16, 24]
    for r, y0 in enumerate(rows):
        off = (r % 2) * 8
        for y in range(y0, y0 + 8):
            for x in range(S):
                c = hexc("stone_mid")
                if y == y0:
                    c = hexc("stone_deep")
                elif y == y0 + 1:
                    c = hexc("stone_light")
                elif (x + off) % 16 == 0:
                    c = hexc("stone_deep")
                elif (x + off) % 16 == 1:
                    c = hexc("stone_light")
                img.putpixel((x, y), c)
    for _ in range(18):
        img.putpixel((rnd.randrange(S), rnd.randrange(S)), hexc(rnd.choice(["stone_dark", "moss_dark"])))
    return img


def main():
    out = {
        "grass": grass(1, ["leaf_dark", "leaf_mid", "leaf_mid", "leaf_light"]),
        "grass_dark": grass(2, ["leaf_dark", "leaf_dark", "leaf_mid"]),
        "moss": grass(3, ["leaf_mid", "moss_dark", "moss_light"]),
        "path_stone": path_stone(4),
        "ash": ash(5),
        "cliff_side": strata(6, ["stone_mid", "stone_dark", "stone_mid", "stone_deep"], "stone_deep"),
        "dirt": strata(7, ["cloth_mid", "cloth_dark", "cloth_mid"], "cloth_dark"),
        "wall_side": wall_side(8),
        "wall_top": strata(9, ["stone_dark", "stone_deep"], "stone_deep"),
    }
    for name, img in out.items():
        save(img, f"assets/art/terrain/{name}.png")


if __name__ == "__main__":
    main()
