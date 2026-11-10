"""Generate the placeholder Unlaid player spritesheet (generated art, replaceable).

Sheet convention (GAME_PLAN 11.2): one PNG, fixed frame size, rows = animations,
columns = frames. Side frames face right; left is a runtime flip.
Row order MUST match data/sprites/unlaid.tres:
   0 idle_down   1 idle_up    2 idle_side     (4f)
   3 walk_down   4 walk_up    5 walk_side     (6f)
   6 attack_down 7 attack_up  8 attack_side   (3f: windup, strike, recover)
   9 block_down 10 block_up  11 block_side    (1f)
  12 dodge (4f, side view, flip for left)
  13 dead  (4f: stagger to knees, collapse, heap, lantern dims)

Outputs:
  assets/art/characters/unlaid_16x24.png   (in-game size)
  assets/art/characters/unlaid_32x32.png   (comparison only, M1 size decision)
"""
from common import Canvas, save, sheet

COLS = 6


# ---------------------------------------------------------------- parts

def legs_front(c, f, walking):
    lift_l = walking and f in (1, 2)
    lift_r = walking and f in (4, 5)
    for x0, lifted in ((5, lift_l), (8, lift_r)):
        top = 18 - (1 if lifted else 0)
        c.rect(x0, top, x0 + 2, top + 3, "cloth_dark")
        c.rect(x0, top + 3, x0 + 2, top + 4, "stone_deep")


def lantern(c, x, y, f, dim=False):
    if dim:
        hot, mid = "ember_dark", "blood_dark"
    else:
        hot, mid = ("ember_light", "ember_mid") if f % 2 == 0 else ("ember_mid", "ember_light")
    c.rect(x, y, x + 1, y, "iron_dark")
    c.rect(x, y + 1, x + 1, y + 1, hot)
    c.rect(x, y + 2, x + 1, y + 2, mid)


def blade(c, x0, y0, x1, y1):
    """A short blade: steel edge with a light glint at the tip end."""
    c.line(x0, y0, x1, y1, "iron_light")
    c.dot(x1, y1, "bone_white")


def body_front(c, bob, facing_up):
    c.rect(4, 10 + bob, 11, 18, "hood_mid")
    c.rect(10, 10 + bob, 11, 18, "hood_dark")
    c.rect(4, 10 + bob, 4, 17, "hood_light")
    c.rect(5, 15 + bob, 10, 15 + bob, "cloth_mid")
    if not facing_up:
        c.rect(7, 15 + bob, 8, 15 + bob, "gold")


def hood_front(c, bob, facing_up):
    c.rect(5, 2 + bob, 10, 2 + bob, "hood_mid")
    c.rect(4, 3 + bob, 11, 9 + bob, "hood_mid")
    c.rect(7, 1 + bob, 8, 1 + bob, "hood_mid")
    c.rect(10, 3 + bob, 11, 9 + bob, "hood_dark")
    c.rect(5, 3 + bob, 6, 3 + bob, "hood_light")
    if facing_up:
        c.rect(7, 4 + bob, 8, 9 + bob, "hood_dark")
    else:
        c.rect(6, 5 + bob, 9, 8 + bob, "skin_light")
        c.rect(6, 5 + bob, 9, 5 + bob, "skin_dark")
        c.rect(9, 6 + bob, 9, 8 + bob, "skin_mid")
        c.dot(6, 6 + bob, "ember_light")  # the Unlaid's ember eyes
        c.dot(9, 6 + bob, "ember_light")


def body_side(c, bob):
    c.rect(5, 10 + bob, 10, 18, "hood_mid")
    c.rect(5, 10 + bob, 6, 18, "hood_dark")
    c.rect(6, 15 + bob, 10, 15 + bob, "cloth_mid")


def hood_side(c, bob):
    c.rect(5, 2 + bob, 10, 9 + bob, "hood_mid")
    c.rect(6, 1 + bob, 7, 1 + bob, "hood_mid")
    c.rect(11, 4 + bob, 11, 9 + bob, "hood_mid")
    c.rect(5, 3 + bob, 6, 9 + bob, "hood_dark")
    c.rect(9, 5 + bob, 11, 8 + bob, "skin_light")
    c.rect(9, 5 + bob, 11, 5 + bob, "skin_dark")
    c.dot(10, 6 + bob, "ember_light")


def legs_side(c, stride):
    c.rect(6 - stride, 18, 8 - stride, 21, "cloth_dark")
    c.rect(6 - stride, 22, 8 - stride, 22, "stone_deep")
    c.rect(7 + stride, 18, 9 + stride, 21, "cloth_mid")
    c.rect(7 + stride, 22, 9 + stride, 22, "stone_deep")


# ---------------------------------------------------------------- poses

def idle_walk_front(c, f, walking, facing_up):
    bob = -1 if (walking and f in (1, 4)) or (not walking and f in (2, 3)) else 0
    legs_front(c, f, walking)
    swing = 0
    if walking:
        swing = -1 if f in (4, 5) else (1 if f in (1, 2) else 0)
    c.rect(3, 11 + bob + swing, 3, 15 + bob + swing, "hood_dark")
    c.dot(3, 16 + bob + swing, "skin_mid")
    c.rect(12, 11 + bob - swing, 12, 15 + bob - swing, "hood_dark")
    c.dot(12, 16 + bob - swing, "skin_mid")
    body_front(c, bob, facing_up)
    hood_front(c, bob, facing_up)
    lantern(c, 12, 17 + bob - swing, f)


def idle_walk_side(c, f, walking):
    bob = -1 if (walking and f in (1, 4)) or (not walking and f in (2, 3)) else 0
    stride = [0, 1, 1, 0, -1, -1][f] if walking else 0
    legs_side(c, stride)
    body_side(c, bob)
    hood_side(c, bob)
    c.rect(8, 11 + bob, 9, 14 + bob, "hood_dark")
    c.dot(10, 15 + bob, "skin_mid")
    lantern(c, 10 + max(-stride if walking else 0, 0), 16 + bob, f)


def attack_front(c, f, facing_up):
    """f: 0 windup, 1 strike, 2 recover. Lantern moves to the left hand."""
    bob = 1 if f == 1 else 0
    legs_front(c, 0, False)
    c.rect(3, 11 + bob, 3, 15 + bob, "hood_dark")
    lantern(c, 2, 16 + bob, 0)
    body_front(c, bob, facing_up)
    if facing_up:
        hood_front(c, bob, True)
        if f == 0:
            c.rect(12, 12, 12, 16, "hood_dark")
            blade(c, 13, 15, 14, 21)
        elif f == 1:
            c.rect(9, 6, 10, 9, "hood_dark")
            blade(c, 9, 5, 8, 0)
        else:
            c.rect(12, 9, 12, 13, "hood_dark")
            blade(c, 13, 9, 15, 5)
    else:
        if f == 0:
            c.rect(12, 7, 12, 11, "hood_dark")
            blade(c, 13, 8, 14, 1)
            hood_front(c, bob, False)
        elif f == 1:
            hood_front(c, bob, False)
            c.rect(9, 13, 10, 16, "hood_dark")
            c.dot(9, 17, "skin_mid")
            blade(c, 9, 18, 8, 23)
        else:
            hood_front(c, bob, False)
            c.rect(12, 11, 12, 15, "hood_dark")
            blade(c, 13, 16, 15, 20)


def attack_side(c, f):
    lean = 1 if f == 1 else 0
    legs_side(c, 1 if f == 1 else 0)
    body_side(c, 0)
    hood_side(c, 0)
    c.dot(4, 14, "ember_mid")  # lantern glow peeking behind the cloak
    if f == 0:
        c.rect(5, 10, 6, 12, "hood_dark")
        blade(c, 5, 9, 2, 4)
    elif f == 1:
        c.rect(9, 11, 11, 12, "hood_dark")
        c.dot(12, 12, "skin_mid")
        blade(c, 13, 12, 15, 12 - lean)
    else:
        c.rect(9, 12, 10, 14, "hood_dark")
        blade(c, 11, 15, 14, 18)


def block_front(c, facing_up):
    legs_front(c, 0, False)
    body_front(c, 0, facing_up)
    hood_front(c, 0, facing_up)
    c.rect(4, 11, 11, 12, "hood_dark")  # forearms raised across the chest
    blade(c, 3, 10, 12, 10)
    lantern(c, 12, 13, 0)


def block_side(c):
    legs_side(c, 0)
    body_side(c, 0)
    hood_side(c, 0)
    c.rect(9, 10, 10, 12, "hood_dark")
    blade(c, 12, 14, 12, 4)


def dodge(c, f):
    """A tucked roll toward +x. Highlight orbits the ball to read as rotation."""
    if f in (0, 3):
        c.rect(4, 14, 11, 21, "hood_mid")
        c.rect(4, 14, 5, 21, "hood_dark")
        c.rect(7, 11, 12, 15, "hood_mid")  # head tucked forward
        c.dot(11, 13, "ember_light")
        c.rect(5, 22, 10, 22, "stone_deep")
        return
    for y in range(13, 23):
        for x in range(3, 14):
            if (x - 8) ** 2 + (y - 18) ** 2 <= 26:
                c.dot(x, y, "hood_mid")
    hl = [(5, 15), (11, 16)][f - 1]
    sh = [(11, 21), (5, 20)][f - 1]
    c.rect(hl[0], hl[1], hl[0] + 1, hl[1] + 1, "hood_light")
    c.rect(sh[0], sh[1], sh[0] + 1, sh[1] + 1, "hood_dark")
    c.dot(*[(10, 15), (6, 21)][f - 1], "ember_mid")


def dead(c, f):
    if f == 0:  # to the knees
        c.rect(4, 13, 11, 21, "hood_mid")
        c.rect(10, 13, 11, 21, "hood_dark")
        c.rect(4, 6, 11, 12, "hood_mid")
        c.rect(6, 9, 9, 11, "skin_dark")
        lantern(c, 12, 19, 0)
    elif f == 1:  # slumping forward
        c.rect(3, 16, 12, 21, "hood_mid")
        c.rect(5, 11, 11, 16, "hood_mid")
        c.rect(10, 11, 11, 21, "hood_dark")
        lantern(c, 13, 19, 1)
    else:  # a heap of cloak; the lantern gutters out
        c.rect(2, 18, 13, 22, "hood_mid")
        c.rect(4, 17, 10, 17, "hood_mid")
        c.rect(2, 21, 13, 22, "hood_dark")
        c.rect(5, 18, 7, 18, "hood_light")
        lantern(c, 13, 20, 0, dim=(f == 3))


# ---------------------------------------------------------------- sheet

def rows_spec():
    """(row name, frame count, draw fn(c, f))."""
    return [
        ("idle_down", 4, lambda c, f: idle_walk_front(c, f, False, False)),
        ("idle_up", 4, lambda c, f: idle_walk_front(c, f, False, True)),
        ("idle_side", 4, lambda c, f: idle_walk_side(c, f, False)),
        ("walk_down", 6, lambda c, f: idle_walk_front(c, f, True, False)),
        ("walk_up", 6, lambda c, f: idle_walk_front(c, f, True, True)),
        ("walk_side", 6, lambda c, f: idle_walk_side(c, f, True)),
        ("attack_down", 3, lambda c, f: attack_front(c, f, False)),
        ("attack_up", 3, lambda c, f: attack_front(c, f, True)),
        ("attack_side", 3, attack_side),
        ("block_down", 1, lambda c, f: block_front(c, False)),
        ("block_up", 1, lambda c, f: block_front(c, True)),
        ("block_side", 1, lambda c, f: block_side(c)),
        ("dodge", 4, dodge),
        ("dead", 4, dead),
    ]


def build(w, h, scale, ox, oy):
    rows = []
    for _name, count, fn in rows_spec():
        frames = []
        for f in range(count):
            c = Canvas(w, h, scale, ox, oy)
            fn(c, f)
            c.outline()
            frames.append(c.to_image())
        rows.append(frames)
    return sheet(rows, w, h, COLS)


def main():
    save(build(16, 24, 1.0, 0, 0), "assets/art/characters/unlaid_16x24.png")
    save(build(32, 32, 1.3, 6, 2), "assets/art/characters/unlaid_32x32.png")


if __name__ == "__main__":
    main()
