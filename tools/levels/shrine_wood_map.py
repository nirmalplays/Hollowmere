"""The shape of the Shrine Wood (the opening zone, ACT1_MQ01 The Waking) and what stands in it.

One continuous piece of forest, not rooms: clearings are lumpy blobs, the trail between
them is a brush stroke that winds and changes width, every clearing has a name and a
landmark (docs/DIMRAETH_REFERENCE.md part 2). Cells: '#' forest (blocked), '.' meadow,
':' trodden dirt. Edit CLEARINGS / TRAILS / places() and re-run build_shrine_wood.py.
"""
import math
import random

W, H = 72, 52

# clearing: (cx, cy, rx, ry)
CLEARINGS = {
    "ring": (13, 39, 8.5, 5.4),      # the Cradle Ring: where the Unlaid wake, open to the sky
    "walk": (15, 13, 11.5, 6.0),     # Mourner's Walk: crawlers among old graves
    "walk_e": (25, 11, 6.0, 4.6),    #   its eastern lobe, the Listening Stone
    "camp": (40, 39, 9.0, 5.0),      # the Wardens' Camp
    "hollow": (49, 23, 3.6, 3.0),    # Charcoal Hollow: a fire to rest at, off the trail
    "plot": (57, 12, 7.6, 7.6),      # the Sexton's Plot, a round graveyard
}
NAMES = {"ring": "The Cradle Ring", "walk": "Mourner's Walk", "walk_e": "Mourner's Walk", "camp": "The Wardens' Camp",
         "hollow": "Charcoal Hollow", "plot": "The Sexton's Plot"}
# trail: ([(x, y), ...], brush radius). Trails are also where the dirt is painted.
TRAILS = [
    ([(13, 39), (13, 33), (11, 28), (13, 22), (14, 18), (15, 13)], 1.25),
    ([(15, 13), (25, 11), (30, 10), (35, 8), (39, 11), (40, 16), (38, 21), (39, 27), (39, 33), (40, 39)], 1.3),
    ([(40, 16), (43, 17)], 1.5),
    ([(39, 24), (44, 23), (49, 23)], 1.0),
    ([(40, 39), (48, 37), (53, 32), (56, 27), (56, 20), (57, 12)], 1.25),
    ([(57, 12), (57, 5), (57, 1)], 1.0),
]


def named_places():
    out = [(NAMES[k], int(cx - rx), int(cy - ry), int(cx + rx) + 1, int(cy + ry) + 1) for k, (cx, cy, rx, ry) in CLEARINGS.items()]
    out.append(("The Sunken Path", 36, 14, 43, 32))
    return out


def carve():
    """Returns the grid before anything is placed: '#', '.', ':'."""
    rng = random.Random(7)
    g = [["#"] * W for _ in range(H)]
    for cx, cy, rx, ry in CLEARINGS.values():
        lobes = [(rng.randint(2, 5), rng.uniform(0.05, 0.13), rng.uniform(0, 6.28)) for _ in range(3)]
        for y in range(1, H - 1):
            for x in range(1, W - 1):
                dx, dy = (x - cx) / rx, (y - cy) / ry
                ang = math.atan2(dy, dx)
                k = 1.0 + sum(a * math.sin(n * ang + ph) for n, a, ph in lobes)
                if dx * dx + dy * dy <= k * k:
                    g[y][x] = "."
    for pts, r in TRAILS:
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            steps = int(max(abs(x1 - x0), abs(y1 - y0)) * 3) + 1
            for i in range(steps + 1):
                t = i / steps
                px, py = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
                rr = r + 0.2 * math.sin(px * 1.3 + py * 0.9)
                for y in range(int(py - rr - 1), int(py + rr + 2)):
                    for x in range(int(px - rr - 1), int(px + rr + 2)):
                        if 0 < x < W - 1 and 0 < y < H - 1:
                            d2 = (x - px) ** 2 + (y - py) ** 2
                            if d2 <= rr * rr + 0.3 and g[y][x] == "#":
                                g[y][x] = "."
                            if d2 <= 0.75:  # the worn middle of the trail
                                g[y][x] = ":"
    return g


def at(room, dx, dy):
    cx, cy, _, _ = CLEARINGS[room]
    return (cx + dx, cy + dy)


def edge(g, room, deg, inset=0.0):
    """The last open cell walking out from a clearing's centre at `deg` (0 east, 90 south)."""
    cx, cy, _, _ = CLEARINGS[room]
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    t = 0.0
    while g[round(cy + s * (t + 0.5))][round(cx + c * (t + 0.5))] != "#":
        t += 0.5
    t = max(0.0, t - inset)
    return (round(cx + c * t), round(cy + s * t))


def places(g):
    """[(x, y, char)]. Offsets are from a clearing's centre, so a clearing can be moved whole."""
    out = []

    def put(pos, ch):
        out.append((pos[0], pos[1], ch))

    # The Cradle Ring: two rows of cradles: 'M' yours, 'G' still glows, 'X' is scratched out.
    for dx, ch in ((-5, "C"), (-3, "K"), (-1, "M"), (2, "C"), (4, "G")):
        put(at("ring", dx, -2), ch)
        if ch != "M":
            put(at("ring", dx, -1), "n")
    for dx, ch in ((-4, "X"), (-2, "C"), (3, "C")):
        put(at("ring", dx, 2), ch)
        put(at("ring", dx, 3), "n")
    put(at("ring", 1, 0), "L")
    put(at("ring", -1, 1), "P")
    put(at("ring", 1, 1), "Z")
    for deg in (195, 345, 150, 30):
        put(edge(g, "ring", deg, 1.0), "T")
    put(edge(g, "ring", 125, 1.5), "o")
    put(edge(g, "ring", 55, 1.5), "l")
    # Mourner's Walk: crawlers among leaning graves; the Listening Stone in the east lobe.
    put((14, 19), "R")
    put(at("walk", -6, 0), "c")
    put(at("walk", 1, -2), "c")
    put(at("walk", 6, 2), "c")
    put(edge(g, "walk_e", 270, 1.0), "I")
    for deg in (180, 320, 120):
        put(edge(g, "walk", deg, 1.0), "T")
    put(edge(g, "walk_e", 25, 1.0), "T")
    for dx, dy, ch in ((-8, 2, "b"), (-3, 3, "k"), (3, 1, "b"), (-2, -1, "s"), (8, -1, "x"), (-5, -3, "o"),
                       (-7, -2, "t"), (4, -4, "t"), (-1, 4, "l")):
        put(at("walk", dx, dy), ch)
    # The Sunken Path: two grunts, then the grave-earth gives way.
    put((35, 8), "g")
    put((43, 17), "g")
    put((39, 28), "D")
    put((40, 12), "T")
    put((37, 22), "x")
    put((40, 14), "b")
    # Charcoal Hollow: a fire to rest at.
    put(at("hollow", 0, 0), "F")
    put(at("hollow", -2, -1), "N")
    put(at("hollow", 2, 1), "l")
    put(at("hollow", 1, -2), "W")
    # The Wardens' Camp: a shield-bearer and two crawlers round a long table.
    put(at("camp", 1, 0), "h")
    put(at("camp", -5, 1), "v")
    put(at("camp", 5, 2), "v")
    put(at("camp", -3, -2), "O")
    put(at("camp", 0, -3), "u")
    for deg in (190, 350, 150, 35):
        put(edge(g, "camp", deg, 1.0), "T")
    put(at("camp", 4, -2), "s")
    put(edge(g, "camp", 100, 1.5), "k")
    put(edge(g, "camp", 165, 1.5), "W")
    put(at("camp", -6, -1), "t")
    # The Sexton's Plot: bone heaps ring the edge; he digs in the middle.
    put(at("plot", 0, 0), "S")
    for deg in (20, 70, 110, 160, 200, 340):
        put(edge(g, "plot", deg, 1.0), "T")
    for deg, ch in ((45, "k"), (135, "b"), (180, "k"), (0, "b"), (225, "x"), (315, "x")):
        put(edge(g, "plot", deg, 2.5), ch)
    put((57, 2), "E")
    return out


def layout():
    """Returns (rows with everything placed, the bare terrain grid)."""
    terrain = carve()
    floor = {(x, y) for y in range(H) for x in range(W) if terrain[y][x] != "#"}
    seen, todo = set(), [next(iter(floor))]
    while todo:
        c = todo.pop()
        if c in floor and c not in seen:
            seen.add(c)
            todo += [(c[0] + 1, c[1]), (c[0] - 1, c[1]), (c[0], c[1] + 1), (c[0], c[1] - 1)]
    assert seen == floor, "the wood is not one connected space"
    g = [row[:] for row in terrain]
    used = {}
    for x, y, ch in places(terrain):
        assert terrain[y][x] != "#", (x, y, ch)
        assert (x, y) not in used, (x, y, ch, used[(x, y)])
        used[(x, y)] = ch
        g[y][x] = ch
    return ["".join(r) for r in g], terrain
