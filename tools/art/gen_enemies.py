"""Generate placeholder enemy spritesheets (generated art, replaceable).

training_dummy (24x24). Row order MUST match data/sprites/training_dummy.tres:
  0 idle (2f)  1 windup (2f)  2 swing (2f)  3 stagger (2f)  4 broken (1f)
A straw-and-burlap dummy gone Hollow: ash-pale sack, a crossbeam it swings.
"""
from common import Canvas, save, sheet

W = H = 24


def dummy_base(c, tilt=0, droop=0):
    c.rect(8, 21, 15, 23, "stone_dark")  # base stone
    c.rect(8, 21, 15, 21, "stone_light")
    c.rect(11, 9, 12, 20, "cloth_mid")  # post
    c.rect(12, 9, 12, 20, "cloth_dark")
    # burlap body
    for y in range(8, 18):
        for x in range(7, 17):
            if ((x - 11.5) / 5) ** 2 + ((y - 12.5) / 5) ** 2 <= 1:
                c.dot(x + tilt, y, "ash_dark")
    c.rect(8 + tilt, 9, 10 + tilt, 11, "ash_light")
    c.dot(13 + tilt, 14, "moss_dark")
    c.dot(9 + tilt, 15, "moss_dark")
    c.rect(8 + tilt, 13, 15 + tilt, 13, "cloth_dark")  # rope
    # sack head with stitched eyes
    hx = 9 + tilt + (1 if droop else 0)
    hy = 2 + droop
    c.rect(hx, hy, hx + 5, hy + 5, "ash_light")
    c.rect(hx + 4, hy, hx + 5, hy + 5, "ash_dark")
    c.dot(hx + 1, hy + 2, "void")
    c.dot(hx + 4, hy + 2, "void")
    c.line(hx + 1, hy + 4, hx + 4, hy + 4, "stone_dark")


def beam(c, x0, y0, x1, y1):
    c.line(x0, y0, x1, y1, "cloth_mid")
    c.line(x0, y0 + 1, x1, y1 + 1, "cloth_dark")


def frame(row, f):
    c = Canvas(W, H)
    if row == 0:  # idle: gentle sway
        dummy_base(c, tilt=f)
        beam(c, 2, 10, 21, 10)
    elif row == 1:  # windup: beam cranks back
        dummy_base(c, tilt=-1)
        if f == 0:
            beam(c, 3, 13, 20, 7)
        else:
            beam(c, 4, 15, 19, 5)
    elif row == 2:  # swing: beam whips through
        dummy_base(c, tilt=1)
        if f == 0:
            beam(c, 2, 6, 21, 14)
        else:
            beam(c, 4, 4, 19, 16)
    elif row == 3:  # stagger: lurches, head droops
        dummy_base(c, tilt=2 - f, droop=1)
        beam(c, 3, 12, 21, 9)
    else:  # broken: post snapped, sack on the ground
        c.rect(8, 21, 15, 23, "stone_dark")
        c.rect(8, 21, 15, 21, "stone_light")
        c.rect(11, 16, 12, 20, "cloth_mid")
        for y in range(15, 22):
            for x in range(1, 12):
                if ((x - 6) / 5) ** 2 + ((y - 19) / 3) ** 2 <= 1:
                    c.dot(x, y, "ash_dark")
        c.rect(14, 17, 19, 21, "ash_light")
        c.dot(16, 19, "void")
        beam(c, 2, 22, 13, 21)
    c.outline()
    return c.to_image()


def main():
    counts = [2, 2, 2, 2, 1]
    rows = [[frame(r, f) for f in range(n)] for r, n in enumerate(counts)]
    save(sheet(rows, W, H, 2), "assets/art/enemies/training_dummy.png")


if __name__ == "__main__":
    main()
