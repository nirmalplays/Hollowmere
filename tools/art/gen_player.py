"""Generate the placeholder Unlaid player spritesheet (generated art, replaceable).

Sheet convention (GAME_PLAN 11.2): one PNG, fixed frame size, rows = animations,
columns = frames. Rows: idle_down, idle_up, idle_side, walk_down, walk_up, walk_side.
Side frames face right; left is a runtime flip.

Outputs:
  assets/art/characters/unlaid_16x24.png   (chosen in-game size)
  assets/art/characters/unlaid_32x32.png   (comparison only, for the M1 size decision)
"""
from common import Canvas, save, sheet

ROWS = ["idle_down", "idle_up", "idle_side", "walk_down", "walk_up", "walk_side"]
COLS = 6
IDLE_FRAMES = 4
WALK_FRAMES = 6


def _legs_front(c, f, walking):
    lift_l = walking and f in (1, 2)
    lift_r = walking and f in (4, 5)
    for x0, lifted in ((5, lift_l), (8, lift_r)):
        top = 18 - (1 if lifted else 0)
        c.rect(x0, top, x0 + 2, top + 3, "cloth_dark")
        c.rect(x0, top + 3, x0 + 2, top + 4, "stone_deep")


def _lantern(c, x, y, f):
    hot, mid = ("ember_light", "ember_mid") if f % 2 == 0 else ("ember_mid", "ember_light")
    c.rect(x, y, x + 1, y, "iron_dark")
    c.rect(x, y + 1, x + 1, y + 1, hot)
    c.rect(x, y + 2, x + 1, y + 2, mid)


def draw_front(c, f, walking, facing_up):
    bob = -1 if (walking and f in (1, 4)) or (not walking and f in (2, 3)) else 0
    _legs_front(c, f, walking)
    swing = 0
    if walking:
        swing = -1 if f in (4, 5) else (1 if f in (1, 2) else 0)
    # Arms (sleeves + hands); left arm swings opposite to the right.
    c.rect(3, 11 + bob + swing, 3, 15 + bob + swing, "hood_dark")
    c.dot(3, 16 + bob + swing, "skin_mid")
    c.rect(12, 11 + bob - swing, 12, 15 + bob - swing, "hood_dark")
    c.dot(12, 16 + bob - swing, "skin_mid")
    # Cloak body.
    c.rect(4, 10 + bob, 11, 18, "hood_mid")
    c.rect(10, 10 + bob, 11, 18, "hood_dark")
    c.rect(4, 10 + bob, 4, 17, "hood_light")
    c.rect(5, 15 + bob, 10, 15 + bob, "cloth_mid")
    if not facing_up:
        c.rect(7, 15 + bob, 8, 15 + bob, "gold")
    # Hood.
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
    _lantern(c, 12, 17 + bob - swing, f)


def draw_side(c, f, walking):
    bob = -1 if (walking and f in (1, 4)) or (not walking and f in (2, 3)) else 0
    stride = [0, 1, 1, 0, -1, -1][f] if walking else 0
    # Back leg (darker), then front leg.
    c.rect(6 - stride, 18, 8 - stride, 21, "cloth_dark")
    c.rect(6 - stride, 22, 8 - stride, 22, "stone_deep")
    c.rect(7 + stride, 18, 9 + stride, 21, "cloth_mid")
    c.rect(7 + stride, 22, 9 + stride, 22, "stone_deep")
    # Cloak.
    c.rect(5, 10 + bob, 10, 18, "hood_mid")
    c.rect(5, 10 + bob, 6, 18, "hood_dark")
    c.rect(6, 15 + bob, 10, 15 + bob, "cloth_mid")
    # Hood, face opening toward +x.
    c.rect(5, 2 + bob, 10, 9 + bob, "hood_mid")
    c.rect(6, 1 + bob, 7, 1 + bob, "hood_mid")
    c.rect(11, 4 + bob, 11, 9 + bob, "hood_mid")
    c.rect(5, 3 + bob, 6, 9 + bob, "hood_dark")
    c.rect(9, 5 + bob, 11, 8 + bob, "skin_light")
    c.rect(9, 5 + bob, 11, 5 + bob, "skin_dark")
    c.dot(10, 6 + bob, "ember_light")
    # Front arm holding the lantern forward.
    arm = -stride if walking else 0
    c.rect(8, 11 + bob, 9, 14 + bob, "hood_dark")
    c.dot(10, 15 + bob, "skin_mid")
    _lantern(c, 10 + max(arm, 0), 16 + bob, f)


def frame(direction, anim, f, w, h, scale, ox, oy):
    c = Canvas(w, h, scale, ox, oy)
    walking = anim == "walk"
    if direction == "side":
        draw_side(c, f, walking)
    else:
        draw_front(c, f, walking, direction == "up")
    c.outline()
    return c.to_image()


def build(w, h, scale, ox, oy):
    rows = []
    for name in ROWS:
        anim, direction = name.split("_")
        count = WALK_FRAMES if anim == "walk" else IDLE_FRAMES
        rows.append([frame(direction, anim, f, w, h, scale, ox, oy) for f in range(count)])
    return sheet(rows, w, h, COLS)


def main():
    save(build(16, 24, 1.0, 0, 0), "assets/art/characters/unlaid_16x24.png")
    # 32x32 comparison: same design scaled 1.3x, centered, feet on the bottom row.
    save(build(32, 32, 1.3, 6, 2), "assets/art/characters/unlaid_32x32.png")


if __name__ == "__main__":
    main()
