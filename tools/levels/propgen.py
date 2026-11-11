"""Shared prop helpers for level builders: collision footprints computed from sprite pixels."""

BAND_THICKNESS = 9  # px of wall "depth" behind the bottom contour


def _ellipse(cx, cy, w, h, n=10):
    import math as m
    return [(cx + w / 2 * m.cos(2 * m.pi * i / n), cy + h / 2 * m.sin(2 * m.pi * i / n)) for i in range(n)]


def footprint(path, mode, inset):
    """Collision polygon in node space (origin = where the prop meets the ground)."""
    from PIL import Image
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    a = img.getchannel("A").load()
    rows = [y for y in range(h) if any(a[x, y] for x in range(w))]
    if mode == "none" or not rows:
        return None
    yb = rows[-1]
    ox, oy = w / 2.0, h - inset
    if mode == "trunk":
        xs = [x for x in range(w) for y in range(max(0, yb - 3), yb + 1) if a[x, y]]
        cx = (min(xs) + max(xs)) / 2.0
        tw = max(7.0, min(16.0, max(xs) - min(xs) + 3.0))
        pts = _ellipse(cx, yb - tw / 4.0, tw, tw / 2.0, 8)
    elif mode == "ellipse":
        cols = [x for x in range(w) if any(a[x, y] for y in range(h))]
        bw = (max(cols) - min(cols)) * 0.85
        pts = _ellipse((max(cols) + min(cols)) / 2.0, yb - bw * 0.21, bw, bw * 0.42, 12)
    else:  # band: follow the bottom contour, BAND_THICKNESS deep
        lower = []
        for x in range(0, w, 3):
            ys = [y for y in range(h) if a[x, y]]
            if ys:
                lower.append((x, max(ys[-1], yb - 28)))
        if len(lower) < 2:
            return None
        pts = lower + [(x, y - BAND_THICKNESS) for x, y in reversed(lower)]
    return [(round(x - ox, 1), round(y - oy, 1)) for x, y in pts]


LEGEND_PROPS = {"T": "tree_green", "X": "tree_dead", "R": "ruin_shrine", "G": "ruin_gate", "I": "ruin_pillar",
                "r": "ruin_rubble", "L": "ruin_wall", "F": "campfire", "C": "cauldron", "N": "tent",
                "B": "crates", "s": "stump", "b": "bones", "k": "stakes", "g": "grass_tuft", "o": "rock"}
