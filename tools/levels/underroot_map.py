"""The shape of the Underroot Caves and where everything stands in it.

The Underroot is one continuous cave, not rooms and corridors (docs/DIMRAETH_REFERENCE,
part 2): caverns are lumpy blobs, passages are brush strokes that wind and change width,
and every cavern has a name and a landmark. Edit CAVERNS / PASSAGES / places() and
re-run build_underroot.py.
"""
import math
import random

W, H = 64, 46

# cavern: (cx, cy, rx, ry)
CAVERNS = {
    "cradle": (13, 37, 8.5, 5.2),    # A: the Cradle Hollow, where the Unlaid wake
    "hall": (15, 12, 11.5, 6.0),     # B: the Nameless Hall, crawlers among the dead
    "hall_e": (24, 10, 6.0, 4.6),    #    its eastern lobe (the cracked wall)
    "guard": (38, 36, 9.0, 5.0),     # D: the Wardens' Mess
    "ossuary": (52, 11, 7.6, 7.6),   # E: the Sexton's Round, a ring arena
}
# passage: ([(x, y), ...], brush radius)
PASSAGES = [
    ([(13, 32), (11, 27), (13, 22), (14, 18)], 1.25),  # the climb out of the Hollow
    ([(29, 10), (34, 8), (38, 11), (39, 16), (37, 21), (38, 26), (38, 32)], 1.3),  # the Old Descent
    ([(38, 16), (41, 17)], 1.5),                      # a widening where the second grunt waits
    ([(46, 35), (51, 31), (53, 26), (52, 19)], 1.25),  # the Bone Stair, up to the Round
    ([(52, 4), (52, 1)], 0.8),                        # the gate stair
]

# Named places (announced on entering): (name, x0, y0, x1, y1) in cells.
def named_places():
    names = {"cradle": "The Cradle Hollow", "hall": "The Nameless Hall", "hall_e": "The Nameless Hall",
             "guard": "The Wardens' Mess", "ossuary": "The Sexton's Round"}
    out = [(names[k], int(cx - rx), int(cy - ry), int(cx + rx) + 1, int(cy + ry) + 1) for k, (cx, cy, rx, ry) in CAVERNS.items()]
    out.append(("The Old Descent", 35, 14, 43, 30))
    return out


def carve():
    rng = random.Random(7)
    g = [["#"] * W for _ in range(H)]
    for cx, cy, rx, ry in CAVERNS.values():
        # A lumpy outline: the radius breathes with a few sine lobes.
        lobes = [(rng.randint(2, 5), rng.uniform(0.05, 0.13), rng.uniform(0, 6.28)) for _ in range(3)]
        for y in range(1, H - 1):
            for x in range(1, W - 1):
                dx, dy = (x - cx) / rx, (y - cy) / ry
                ang = math.atan2(dy, dx)
                k = 1.0 + sum(a * math.sin(n * ang + ph) for n, a, ph in lobes)
                if dx * dx + dy * dy <= k * k:
                    g[y][x] = "."
    for pts, r in PASSAGES:
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            steps = int(max(abs(x1 - x0), abs(y1 - y0)) * 3) + 1
            for i in range(steps + 1):
                t = i / steps
                px, py = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
                rr = r + 0.2 * math.sin(px * 1.3 + py * 0.9)  # the width wanders
                for y in range(int(py - rr - 1), int(py + rr + 2)):
                    for x in range(int(px - rr - 1), int(px + rr + 2)):
                        if 0 < x < W - 1 and 0 < y < H - 1 and (x - px) ** 2 + (y - py) ** 2 <= rr * rr + 0.3:
                            g[y][x] = "."
    return g


def at(room, dx, dy):
    cx, cy, _, _ = CAVERNS[room]
    return (cx + dx, cy + dy)


def edge(g, room, deg, inset=0):
    """The last floor cell walking out from a cavern's centre at `deg` (0 east, 90 south)."""
    cx, cy, _, _ = CAVERNS[room]
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    t = 0.0
    while g[round(cy + s * (t + 0.5))][round(cx + c * (t + 0.5))] != "#":
        t += 0.5
    t = max(0.0, t - inset)
    return (round(cx + c * t), round(cy + s * t))


def places(g):
    """[(x, y, char)]. Offsets are from a cavern's centre, so a cavern can be moved whole."""
    out = []

    def put(pos, ch):
        out.append((pos[0], pos[1], ch))

    # A: the Cradle Hollow. Two rows of cradles: 'M' is yours, 'G' still glows, 'X' is scratched out.
    for dx, ch in ((-5, "C"), (-3, "K"), (-1, "M"), (2, "C"), (4, "G")):
        put(at("cradle", dx, -2), ch)
        if ch != "M":
            put(at("cradle", dx, -1), "n")
    for dx, ch in ((-4, "X"), (-2, "C"), (3, "C")):
        put(at("cradle", dx, 2), ch)
        put(at("cradle", dx, 3), "n")
    put(at("cradle", 0, 0), "L")
    put(at("cradle", -1, 1), "P")
    put(at("cradle", 1, 1), "Z")
    for deg in (195, 345, 150, 30):
        put(edge(g, "cradle", deg), "T")
    put(edge(g, "cradle", 125, 1), "b")
    put(edge(g, "cradle", 55, 1), "k")
    put(edge(g, "cradle", 225), "w")
    # B: the Nameless Hall. Crawlers lie among the bone heaps; the cracked wall is in the east lobe.
    put((14, 18), "R")
    put(at("hall", -6, 0), "c")
    put(at("hall", 1, -2), "c")
    put(at("hall", 6, 2), "c")
    put(edge(g, "hall_e", 270), "I")
    for deg in (180, 215, 320, 120):
        put(edge(g, "hall", deg), "T")
    put(edge(g, "hall_e", 25), "T")
    for deg, ch in ((250, "H"), (285, "H"), (235, "w"), (300, "w")):
        put(edge(g, "hall", deg), ch)
    for dx, dy, ch in ((-8, 2, "b"), (-3, 3, "k"), (3, 1, "b"), (-2, -1, "B"), (8, -1, "x"), (-5, -3, "x")):
        put(at("hall", dx, dy), ch)
    # The Old Descent: two grunts, then the ceiling gives way.
    put((34, 8), "g")
    put((41, 17), "g")
    put((38, 27), "D")
    put((38, 12), "T")
    put((37, 22), "x")
    put((39, 14), "b")
    # D: the Wardens' Mess. A shield-bearer and two crawlers round a long table.
    put(at("guard", 1, 0), "h")
    put(at("guard", -5, 1), "v")
    put(at("guard", 5, 2), "v")
    put(at("guard", -3, -2), "O")
    put(at("guard", 0, -3), "u")
    for deg in (190, 350, 150, 35):
        put(edge(g, "guard", deg), "T")
    put(at("guard", 4, -2), "B")
    put(edge(g, "guard", 100, 1), "k")
    put(edge(g, "guard", 165, 1), "b")
    # E: the Sexton's Round. Bone heaps ring the wall; he digs in the middle.
    put(at("ossuary", 0, 0), "S")
    for deg in (20, 70, 110, 160, 200, 340):
        put(edge(g, "ossuary", deg), "T")
    for deg, ch in ((45, "k"), (135, "b"), (180, "k"), (0, "b"), (225, "x"), (315, "x")):
        put(edge(g, "ossuary", deg, 1.5), ch)
    for deg in (245, 295):
        put(edge(g, "ossuary", deg), "H")
    put((52, 2), "E")
    return out


def layout_rows():
    g = carve()
    floor = {(x, y) for y in range(H) for x in range(W) if g[y][x] != "#"}
    seen, todo = set(), [next(iter(floor))]
    while todo:
        c = todo.pop()
        if c in floor and c not in seen:
            seen.add(c)
            todo += [(c[0] + 1, c[1]), (c[0] - 1, c[1]), (c[0], c[1] + 1), (c[0], c[1] - 1)]
    assert seen == floor, "the cave is not one connected space"
    used = {}
    for x, y, ch in places(g):
        assert g[y][x] != "#", (x, y, ch)
        assert (x, y) not in used, (x, y, ch, used[(x, y)])
        used[(x, y)] = ch
        g[y][x] = ch
    return ["".join(r) for r in g]
