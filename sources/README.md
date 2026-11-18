# Raw source packs

Everything the game's art and sound were cut, composited or copied from, so any asset can
be rebuilt with the scripts in `tools/` (they read this folder by default; set
`HOLLOWMERE_SOURCES` to use another). Godot ignores this folder (`.gdignore`); the game
only loads the prepared copies in `assets/`.

| Folder | What | Licence |
|---|---|---|
| `lpc/spritesheets` | Universal LPC character layers (the parts we use) | CC-BY-SA 3.0 / GPL 3.0, authors in `lpc/CREDITS.csv` |
| `lpc_env` | LPC trees mega-pack, LPC forest tiles, LPC base assets and atlases | CC-BY-SA 3.0 (see each pack's credits file) |
| `oga` | Assorted OpenGameArt packs tried during early art direction | see `ASSETS.md` |
| `audio` | Kenney Impact / RPG / UI audio, RPG Sound Pack, 80 CC0 RPG SFX, OpenGameArt voice and creature packs | CC0 (one voice pack is also offered as OGA-BY 3.0) |

Not included: the reference gameplay footage studied for design (another studio's video,
not ours to redistribute) and the Flare engine checkout (no longer used).
The owner's own music and weather recordings are in `BGM/` and `Climate sounds/` at the
project root, with the raw effect folders `Sound effects/` and `Special effect/`.
