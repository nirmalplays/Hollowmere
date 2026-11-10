# ASSETS

Every asset is listed here with its source and license (GAME_PLAN 0.2, 11.1).
Third-party sources are downloaded to `../hollowmere_sources/` (outside the project) and
imported by the scripts in `tools/art/`. Re-run them to rebuild everything:

```
python -I tools/art/import_flare.py      # characters (8-direction, pixelized)
python -I tools/art/import_props.py      # trees, ruins, camp props, native tiles
python -I tools/art/build_tilesets.py    # isometric TileSets
python -I tools/art/import_pixelfx.py    # effects (needs the pixelfx checkout)
python -I tools/levels/build_greywood_glade.py
```

"Pixelized" means downscaled, colour-boosted, palette-snapped and outlined by
`tools/art/pixelize.py`. Those are modified versions of the originals.

## Licences in use
- **CC0**: no conditions.
- **CC-BY-SA 3.0** (Flare): credit the authors (see Credits below); modified versions of
  these images must stay CC-BY-SA. This applies to the art files only, not the game's code.
- **MIT** (pixelfx): keep the copyright notice (`assets/art/fx/LICENSE-pixelfx.txt`).
- **SIL OFL 1.1** (font): `assets/fonts/OFL.txt`.

## Characters
| Asset | Source | Licence | Files | Notes |
|---|---|---|---|---|
| The Unlaid (player): hood, chain cuirass, leather, short sword, buckler | Flare game avatar layers, https://github.com/flareteam/flare-game | CC-BY-SA 3.0 | `assets/art/characters/unlaid.png`, `data/sprites/unlaid.tres` | composited + pixelized, hood tinted |
| Hollow Husk (training enemy) | Flare `enemies/skeleton_weak` | CC-BY-SA 3.0 | `assets/art/characters/hollow_husk.png` | pixelized, ash-tinted |
| Hollowed (zombie) | Flare `enemies/zombie` | CC-BY-SA 3.0 | `assets/art/characters/hollowed_zombie.png` | pixelized, ash-tinted (enemy AI in M4) |

## World
| Asset | Source | Licence | Files | Notes |
|---|---|---|---|---|
| Forest Isometric Pack (tiles, trees, rocks, grass) | KipperFalcon, https://opengameart.org/content/free-forest-isometric-pixel-art | CC0 (author asks not to resell the pack itself) | `assets/art/tiles/kf_forest_*.png`, `assets/art/props/kf_trees/` | native pixel art |
| 2D Isometric Pixel Art Cave Tiles | KipperFalcon, https://opengameart.org/content/2d-isometric-pixel-art-cave-tiles | CC0 | `assets/art/tiles/kf_cave_*.png` | native pixel art (dungeons) |
| 32x32 Isometric Tileset v01 (props, fences, signs) | https://opengameart.org/content/32x32-isometric-tileset-version-01 | CC0 | `assets/art/tiles/iso_overworld_32.png` | native pixel art |
| Isometric Trees | https://opengameart.org/content/isometric-trees-1 | CC0 | `assets/art/props/trees/` | pixelized |
| Isometric - Dark Ruins | https://opengameart.org/content/dark-ruins-tilesets-isometric | CC0 | `assets/art/props/ruins/` | pixelized, brightened |
| Isometric Props and Tents | https://opengameart.org/content/isometric-props-and-tents | CC0 | `assets/art/props/props_small|medium|large/` | pixelized |

## Effects, UI, fonts
| Asset | Source | Licence | Files |
|---|---|---|---|
| Slashes, hit spark, parry | pixelfx, https://github.com/patch-gg/pixelfx | MIT | `assets/art/fx/` (+ `LICENSE-pixelfx.txt`) |
| Press Start 2P font | https://github.com/google/fonts/tree/main/ofl/pressstart2p | SIL OFL 1.1 | `assets/fonts/` |
| Flash shader, UI bars | original (project) | project | `assets/shaders/`, `scripts/ui/` |

## Credits (CC-BY-SA attribution)
Character art adapted from **Flare** (flarerpg.org): avatar and enemy sprites by Clint Bellanger and the
Flare contributors, see https://github.com/flareteam/flare-game/blob/master/CREDITS.txt. Licensed CC-BY-SA 3.0.
This credit must appear in the game's credits screen (M12).
