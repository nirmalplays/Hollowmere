"""Cut LPC props out of their sheets, and draw the props no free pack has (the stone cradles).

Cut props: LPC Dungeon Elements and LPC Base Assets (CC-BY-SA 3.0 / GPL 3.0).
Drawn props (cradles, cradle lantern pedestal): original, in the LPC palette and shading.
Output: assets/art/props/lpc/<name>.png

  python -I tools/art/import_lpc_props.py
"""
import os

from PIL import Image, ImageDraw

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
SOURCES = os.environ.get("HOLLOWMERE_SOURCES", os.path.join(os.path.dirname(PROJECT), "hollowmere_sources"))
ENV = os.path.join(SOURCES, "lpc_env")
SHEETS = {
    "dex": os.path.join(ENV, "dungeon_0", "dungeonex.png"),
    "lights": os.path.join(ENV, "lpc_base_assets", "LPC Base Assets", "tiles", "castle_lightsources.png"),
}
OUT = os.path.join(PROJECT, "assets", "art", "props", "lpc")

# name -> (sheet, x, y, w, h) in pixels; trimmed to their pixels afterwards
CUTS = {
    "cauldron": ("dex", 32, 0, 32, 32),
    "embers": ("dex", 32, 32, 32, 32),
    "table_round": ("dex", 96, 0, 32, 64),
    "chair_a": ("dex", 64, 0, 32, 64),
    "chair_b": ("dex", 128, 0, 32, 64),
    "table_long": ("dex", 160, 16, 96, 52),
    "hanging_skeleton": ("dex", 0, 256, 32, 64),
    "chains": ("dex", 32, 256, 32, 32),
    "skull": ("dex", 64, 256, 32, 32),
    "bones": ("dex", 96, 256, 32, 32),
    "skull_pile": ("dex", 32, 288, 32, 32),
    "bone_pile": ("dex", 64, 288, 32, 32),
    "cobweb_a": ("dex", 288, 128, 32, 32),
    "cobweb_b": ("dex", 288, 160, 32, 32),
    "slime": ("dex", 224, 96, 32, 32),
    "blood": ("dex", 224, 128, 32, 32),
    "cell_bars": ("dex", 256, 160, 32, 160),
    "wall_torch": ("lights", 32, 0, 32, 32),
    "brazier": ("lights", 64, 0, 32, 64),
    "lamp_post": ("lights", 128, 0, 32, 96),
}

STONE = [(52, 52, 64), (78, 78, 92), (104, 106, 120), (136, 138, 150), (170, 172, 182)]
INK = (24, 20, 30)
EMBER = [(255, 236, 160), (255, 196, 92), (230, 120, 48)]
BLUE = [(150, 210, 255), (90, 150, 230)]


def trim(img):
    box = img.getchannel("A").getbbox()
    return img.crop(box) if box else img


def cradle(state):
    """A stone sarcophagus seen from the 3/4 top-down view: 36x52, lid off.
    state: 'empty', 'shattered', 'glowing', 'mine' (the player's, a faint warm glow)."""
    img = Image.new("RGBA", (36, 52))
    d = ImageDraw.Draw(img)
    # Front face (the 3/4 view shows the stone's south side below the top).
    d.rectangle([2, 38, 33, 49], fill=STONE[1], outline=INK)
    for x in range(6, 33, 8):
        d.line([x, 39, x, 48], fill=STONE[0])
    d.line([3, 39, 32, 39], fill=STONE[2])
    # Top rim and the hollow inside.
    d.rectangle([2, 4, 33, 38], fill=STONE[3], outline=INK)
    d.rectangle([3, 5, 32, 6], fill=STONE[4])
    d.rectangle([6, 9, 29, 35], fill=STONE[0], outline=INK)
    d.rectangle([7, 10, 28, 12], fill=(36, 36, 46))
    # Carved band and a worn rune at the head.
    d.rectangle([15, 1, 20, 4], fill=STONE[2], outline=INK)
    d.point([(17, 2), (18, 3)], fill=STONE[0])
    if state == "shattered":
        d.polygon([(20, 4), (26, 18), (22, 24), (33, 30), (33, 4)], fill=(0, 0, 0, 0))
        d.line([(20, 4), (26, 18), (22, 24), (33, 30)], fill=INK)
        for (x, y) in [(28, 44), (31, 47), (25, 47), (6, 46)]:
            d.rectangle([x, y, x + 2, y + 1], fill=STONE[2], outline=INK)
    elif state == "glowing":
        for r, c in ((10, (90, 150, 230, 90)), (7, (150, 210, 255, 160)), (4, (220, 240, 255, 230))):
            d.ellipse([17 - r, 22 - r * 1.4, 18 + r, 22 + r * 1.4], fill=c)
    elif state == "mine":
        d.rectangle([9, 14, 26, 32], fill=(60, 54, 58))
        d.ellipse([12, 18, 23, 28], fill=(110, 80, 60, 120))
    return img


def lantern_pedestal(lit):
    """A short stone pedestal holding the cracked Cradle Lantern."""
    img = Image.new("RGBA", (20, 40))
    d = ImageDraw.Draw(img)
    d.rectangle([4, 22, 15, 37], fill=STONE[2], outline=INK)
    d.rectangle([2, 19, 17, 23], fill=STONE[3], outline=INK)
    d.rectangle([3, 34, 16, 39], fill=STONE[1], outline=INK)
    if lit:
        d.rectangle([6, 6, 13, 18], fill=(70, 60, 50), outline=INK)
        d.rectangle([8, 9, 11, 16], fill=EMBER[0])
        d.point([(9, 12), (10, 11)], fill=EMBER[1])
        d.line([(12, 7), (10, 13)], fill=INK)  # the crack
        d.rectangle([8, 3, 11, 6], fill=(70, 60, 50), outline=INK)
    return img


def hearth_glow():
    """A soft ring of light drawn under the Hearth cradle once it is lit."""
    img = Image.new("RGBA", (48, 24))
    d = ImageDraw.Draw(img)
    for r, a in ((24, 40), (18, 70), (12, 110)):
        d.ellipse([24 - r, 12 - r / 2, 24 + r, 12 + r / 2], outline=(255, 196, 92, a))
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    sheets = {k: Image.open(v).convert("RGBA") for k, v in SHEETS.items()}
    for name, (sheet, x, y, w, h) in CUTS.items():
        trim(sheets[sheet].crop((x, y, x + w, y + h))).save(os.path.join(OUT, name + ".png"))
    for state in ("empty", "shattered", "glowing", "mine"):
        cradle(state).save(os.path.join(OUT, f"cradle_{state}.png"))
    lantern_pedestal(True).save(os.path.join(OUT, "lantern_pedestal_lit.png"))
    lantern_pedestal(False).save(os.path.join(OUT, "lantern_pedestal_empty.png"))
    hearth_glow().save(os.path.join(OUT, "hearth_glow.png"))
    print(len(CUTS), "cut, 7 drawn ->", OUT)


if __name__ == "__main__":
    main()
