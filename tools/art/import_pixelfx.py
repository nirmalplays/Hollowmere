"""Render pixelfx effects to sprite sheets and write matching FxDef resources.

Needs a pixelfx checkout (https://github.com/patch-gg/pixelfx, MIT) and Node 18+.
Location: env PIXELFX_DIR, default: a "pixelfx" folder next to this project.

  python tools/art/import_pixelfx.py

Each entry below is: output name, pixelfx id, options, anchor offset from the
effect's pivot (the point our node sits on), and whether it rotates with direction.
"""
import json
import os
import shutil
import subprocess

from common import PROJECT

PIXELFX = os.environ.get("PIXELFX_DIR", os.path.join(os.path.dirname(PROJECT), "pixelfx"))

STEEL = ["#1a1420", "#283247", "#3d4a63", "#5b6b85", "#8c94a3", "#cfd2d6", "#f4f1ea"]
EMBER = ["#2c2a31", "#7a2a2a", "#e0702c", "#ffb347", "#ffe08a", "#f4f1ea", "#ffffff"]
SPARKS = ["#ffe08a", "#ffb347", "#e0702c", "#b8433a"]

# sword-slash: arc centre is (+6, -26) from the pivot (src/fx/melee/sword-slash.js).
EFFECTS = [
    ("slash_light", "melee/sword-slash", {"radius": 16, "palette": STEEL, "sparks": SPARKS, "seed": 2}, (6, -26), True),
    ("slash_heavy", "melee/sword-slash", {"radius": 22, "palette": EMBER, "sparks": SPARKS, "seed": 5}, (6, -26), True),
    ("hit_spark", "impacts/hit-spark", {"height": 6}, (0, -6), True),
    ("parry", "impacts/parry", {}, (0, -30), False),
]

TRES = """[gd_resource type="Resource" script_class="FxDef" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/systems/fx/fx_def.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/art/fx/{name}.png" id="2"]

[resource]
script = ExtResource("1")
texture = ExtResource("2")
frame_size = Vector2i({fw}, {fh})
columns = {cols}
frame_count = {frames}
fps = {fps}.0
anchor = Vector2({ax}, {ay})
rotates = {rot}
source_id = "{src}"
"""


def main():
    out_png = os.path.join(PROJECT, "assets", "art", "fx")
    out_tres = os.path.join(PROJECT, "data", "fx")
    os.makedirs(out_png, exist_ok=True)
    os.makedirs(out_tres, exist_ok=True)
    for name, fx_id, opts, (dx, dy), rotates in EFFECTS:
        subprocess.run(
            ["node", "tools/render.mjs", fx_id, "--sheet", "--opts", json.dumps(opts)],
            cwd=PIXELFX, check=True, capture_output=True,
        )
        base = fx_id.split("/")[-1]
        rec = os.path.join(PIXELFX, "records", *fx_id.split("/"))
        shutil.copy(os.path.join(rec, base + ".png"), os.path.join(out_png, name + ".png"))
        with open(os.path.join(rec, base + ".json"), encoding="utf-8") as f:
            meta = json.load(f)["meta"]["pixelfx"]
        px, py = meta["pivot"]
        with open(os.path.join(out_tres, name + ".tres"), "w", encoding="utf-8", newline="\n") as f:
            f.write(TRES.format(
                name=name, fw=meta["frameSize"][0], fh=meta["frameSize"][1], cols=meta["columns"],
                frames=meta["frames"], fps=meta["fps"], ax=px + dx, ay=py + dy,
                rot="true" if rotates else "false", src=fx_id,
            ))
        print("fx", name, "<-", fx_id, meta["frameSize"], meta["frames"], "frames")


if __name__ == "__main__":
    main()
