"""Write Godot isometric TileSets from the imported tile atlases.

Each tile gets a "tile_name" (custom data) so layouts refer to names, not atlas
coordinates. Two atlas sources share one texture:
  source 0 = ground level (top face on the cell)
  source 1 = raised one block (drawn 16 px higher, solid)
Water is solid at ground level.

  python -I tools/art/build_tilesets.py
"""
import os

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))

# Kipperfalcon forest atlas (CC0): 32x32 blocks, top face = upper 32x16 diamond.
FOREST = {
    "texture": "res://assets/art/tiles/kf_forest_tiles.png",
    "out": "assets/art/tiles/greywood_iso.tres",
    "tiles": {
        "grass_a": (0, 0), "grass_b": (1, 0), "grass_flowers": (2, 0), "grass_c": (0, 1),
        "grass_d": (1, 1), "grass_e": (2, 1), "grass_dark_a": (0, 2), "grass_dark_b": (1, 2),
        "grass_dark_c": (2, 2), "path_edge_a": (3, 0), "path_edge_b": (4, 0), "path_edge_c": (3, 1),
        "path_edge_d": (4, 1), "path_a": (3, 2), "path_b": (4, 2), "path_speckled": (4, 3),
        "path_corner_a": (5, 2), "path_corner_b": (6, 2), "path_corner_c": (5, 3), "path_corner_d": (6, 3),
        "earth_a": (0, 3), "earth_b": (1, 3), "earth_c": (2, 3), "earth_dark": (2, 7), "earth_d": (2, 6),
        "cliff_grass_a": (3, 3), "cliff_grass_b": (0, 4), "cliff_grass_c": (3, 4), "cliff_grass_d": (2, 5),
        "tall_grass_a": (1, 4), "tall_grass_b": (2, 4), "tall_grass_c": (3, 6), "tall_grass_d": (3, 7),
        "reeds": (3, 5), "sand_a": (5, 0), "sand_b": (6, 0), "water": (4, 4), "water_b": (4, 6),
        "water_c": (5, 6),
    },
    "solid_ground": {"water", "water_b", "water_c"},
}

DIAMOND = "PackedVector2Array(0, -8, 16, 0, 0, 8, -16, 0)"


def write(spec):
    lines = ['[gd_resource type="TileSet" load_steps=4 format=3]', "",
             f'[ext_resource type="Texture2D" path="{spec["texture"]}" id="1"]', ""]
    for source_id, origin_y, solid_all in ((0, -8, False), (1, 8, True)):
        lines += [f'[sub_resource type="TileSetAtlasSource" id="src{source_id}"]', 'texture = ExtResource("1")',
                  "texture_region_size = Vector2i(32, 32)"]
        for name, (x, y) in spec["tiles"].items():
            key = f"{x}:{y}/0"
            lines.append(f"{key} = 0")
            lines.append(f"{key}/texture_origin = Vector2i(0, {origin_y})")
            if solid_all or name in spec["solid_ground"]:
                lines.append(f"{key}/physics_layer_0/polygon_0/points = {DIAMOND}")
            # Raised blocks sort with characters by their base, not their drawn top.
            if source_id == 1:
                lines.append(f"{key}/y_sort_origin = 8")
            lines.append(f'{key}/custom_data_0 = "{name}"')
        lines.append("")
    lines += ["[resource]", "tile_shape = 1", "tile_layout = 5", "tile_size = Vector2i(32, 16)",
              "physics_layer_0/collision_layer = 1", "physics_layer_0/collision_mask = 0",
              'custom_data_layer_0/name = "tile_name"', "custom_data_layer_0/type = 4",
              'sources/0 = SubResource("src0")', 'sources/1 = SubResource("src1")', ""]
    path = os.path.join(PROJECT, spec["out"])
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("tileset", spec["out"], len(spec["tiles"]), "tiles x2 levels")


if __name__ == "__main__":
    write(FOREST)
