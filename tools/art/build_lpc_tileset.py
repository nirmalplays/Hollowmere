"""Copy LPC environment sheets into the project and write the top-down TileSet.

Top-down 3/4 on a square 32 px grid (docs/ART_DIRECTION.md). Every tile gets a
"tile_name" (custom data) so room layouts and the room builder use names.
Sources: LPC Base Assets, LPC Tile Atlas, LPC Dungeon Elements (CC-BY-SA 3.0 / GPL 3.0),
in $HOLLOWMERE_SOURCES/lpc_env.

  python -I tools/art/build_lpc_tileset.py
"""
import os
import shutil

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
SOURCES = os.environ.get("HOLLOWMERE_SOURCES", os.path.join(PROJECT, "sources"))
ENV = os.path.join(SOURCES, "lpc_env")
BASE = os.path.join(ENV, "lpc_base_assets", "LPC Base Assets", "tiles")
OUT_DIR = "assets/art/tiles/lpc"

SHEETS = {  # id -> source file
    "dungeon": os.path.join(BASE, "dungeon.png"),
    "floors": os.path.join(BASE, "castlefloors.png"),
    "lights": os.path.join(BASE, "castle_lightsources.png"),
    "stairs": os.path.join(BASE, "stairs.png"),
    "terrain": os.path.join(ENV, "Atlas_0", "terrain_atlas.png"),
    "dungeon_props": os.path.join(ENV, "dungeon_0", "dungeonex.png"),
}

# name -> (sheet, col, row, solid)
TILES = {}
for i, (c, r) in enumerate([(5, 5), (6, 5), (7, 5), (8, 5), (5, 6), (8, 6), (5, 7), (6, 7)]):
    TILES[f"crypt_floor_{i}"] = ("floors", c, r, False)
TILES["crypt_floor_moss_0"] = ("floors", 6, 6, False)
TILES["crypt_floor_moss_1"] = ("floors", 7, 6, False)
for i in range(3):
    TILES[f"crypt_wall_cap_{i}"] = ("dungeon", i, 0, True)
    TILES[f"crypt_wall_mid_{i}"] = ("dungeon", i, 1, True)
    TILES[f"crypt_wall_base_{i}"] = ("dungeon", i, 2, True)
    TILES[f"crypt_ledge_{i}"] = ("dungeon", i, 3, True)
TILES["crypt_trim_right"] = ("dungeon", 4, 1, True)  # wall cell with a floor to its right
TILES["crypt_trim_left"] = ("dungeon", 6, 1, True)  # wall cell with a floor to its left
TILES["crypt_void"] = ("dungeon", 0, 4, True)  # the dark mass behind walls

SHEET_IDS = list(SHEETS)
SQUARE = "PackedVector2Array(-16, -16, 16, -16, 16, 16, -16, 16)"


def main():
    out = os.path.join(PROJECT, OUT_DIR)
    os.makedirs(out, exist_ok=True)
    for sid, src in SHEETS.items():
        shutil.copy(src, os.path.join(out, sid + ".png"))
    used = sorted({t[0] for t in TILES.values()})
    lines = [f'[gd_resource type="TileSet" load_steps={1 + 2 * len(used)} format=3]', ""]
    for i, sid in enumerate(used):
        lines.append(f'[ext_resource type="Texture2D" path="res://{OUT_DIR}/{sid}.png" id="t{i}"]')
    lines.append("")
    for i, sid in enumerate(used):
        lines += [f'[sub_resource type="TileSetAtlasSource" id="src{i}"]', f'texture = ExtResource("t{i}")',
                  "texture_region_size = Vector2i(32, 32)"]
        for name, (sheet, c, r, solid) in TILES.items():
            if sheet != sid:
                continue
            key = f"{c}:{r}/0"
            lines.append(f"{key} = 0")
            if solid:
                lines.append(f"{key}/physics_layer_0/polygon_0/points = {SQUARE}")
            lines.append(f'{key}/custom_data_0 = "{name}"')
        lines.append("")
    lines += ["[resource]", "tile_size = Vector2i(32, 32)", "physics_layer_0/collision_layer = 1",
              "physics_layer_0/collision_mask = 0", 'custom_data_layer_0/name = "tile_name"',
              "custom_data_layer_0/type = 4"]
    lines += [f'sources/{i} = SubResource("src{i}")' for i in range(len(used))]
    lines.append("")
    with open(os.path.join(PROJECT, OUT_DIR, "crypt.tres"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("tileset", len(TILES), "tiles from", used)


if __name__ == "__main__":
    main()
