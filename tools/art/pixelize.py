"""Turn rendered/painted art into pixel art that matches the game's look.

Steps: boost colour/contrast (the source packs are muted; the target look is
vivid), area-downscale, hard alpha cut, snap to a shared palette (no dithering),
then add a dark 1px outline. Used by import_flare.py and import_props.py.

Third-party sources live outside the project (see SOURCES below); everything they
produce is listed in ASSETS.md with its license.
"""
import os

from PIL import Image, ImageEnhance

SOURCES = os.environ.get(
    "HOLLOWMERE_SOURCES",
    os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))),
                 "hollowmere_sources"),
)

OUTLINE = (26, 20, 32, 255)


def enhance(img, color=1.3, contrast=1.15, brightness=1.05):
    rgb = img.convert("RGB")
    rgb = ImageEnhance.Color(rgb).enhance(color)
    rgb = ImageEnhance.Contrast(rgb).enhance(contrast)
    rgb = ImageEnhance.Brightness(rgb).enhance(brightness)
    out = rgb.convert("RGBA")
    out.putalpha(img.getchannel("A"))
    return out


def downscale(img, scale):
    w, h = max(1, round(img.width * scale)), max(1, round(img.height * scale))
    # Premultiply so transparent pixels don't bleed dark fringes into edges.
    r, g, b, a = img.split()
    pre = Image.merge("RGBA", [Image.composite(c, Image.new("L", img.size, 0), a) for c in (r, g, b)] + [a])
    small = pre.resize((w, h), Image.BOX)
    sr, sg, sb, sa = small.split()
    px = []
    for (cr, cg, cb, ca) in zip(sr.getdata(), sg.getdata(), sb.getdata(), sa.getdata()):
        if ca == 0:
            px.append((0, 0, 0, 0))
        else:
            k = 255.0 / ca
            px.append((min(255, int(cr * k)), min(255, int(cg * k)), min(255, int(cb * k)), ca))
    small.putdata(px)
    return small


def alpha_cut(img, threshold=110):
    a = img.getchannel("A").point(lambda v: 255 if v >= threshold else 0)
    img.putalpha(a)
    return img


def build_palette(images, colors):
    """One shared palette for a whole sheet, so frames don't flicker between colours."""
    opaque = []
    for im in images:
        for p in im.getdata():
            if p[3] > 0:
                opaque.append(p[:3])
    if not opaque:
        return None
    side = int(len(opaque) ** 0.5) + 1
    strip = Image.new("RGB", (side, side))
    strip.putdata(opaque + [opaque[-1]] * (side * side - len(opaque)))
    return strip.quantize(colors=colors, method=Image.Quantize.MEDIANCUT)


def apply_palette(img, palette):
    if palette is None:
        return img
    q = img.convert("RGB").quantize(palette=palette, dither=Image.Dither.NONE).convert("RGBA")
    q.putalpha(img.getchannel("A"))
    return q


def outline(img, color=OUTLINE):
    w, h = img.size
    src = img.load()
    out = img.copy()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] != 0:
                    dst[x, y] = color
                    break
    return out


def pixelize_one(img, scale, palette=None, with_outline=True, **enhance_args):
    small = alpha_cut(downscale(enhance(img, **enhance_args), scale))
    small = apply_palette(small, palette)
    return outline(small) if with_outline else small


def trim(img, pad=0):
    box = img.getchannel("A").getbbox()
    if box is None:
        return img
    l, t, r, b = box
    return img.crop((max(0, l - pad), max(0, t - pad), min(img.width, r + pad), min(img.height, b + pad)))
