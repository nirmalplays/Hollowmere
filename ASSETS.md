# ASSETS

Every asset must be listed here with source and license (GAME_PLAN 0.2, 11.1).
Generated art is tagged `generated` so the owner can replace it later. Generators live in `tools/art/`
(deterministic; edit and re-run, then `python tools/art/gen_preview.py` for `tools/art/preview.png`).

| Asset | Source / URL | License | Files used | Tag |
|---|---|---|---|---|
| Unlaid player sheet 16x24 | `tools/art/gen_player.py` | Original (project) | `assets/art/characters/unlaid_16x24.png` | generated |
| Unlaid player sheet 32x32 (size comparison only) | `tools/art/gen_player.py` | Original (project) | `assets/art/characters/unlaid_32x32.png` | generated |
| Dungeon tiles | `tools/art/gen_tiles.py` | Original (project) | `assets/art/tiles/dungeon_tiles.png` | generated |
| Press Start 2P font | https://github.com/google/fonts/tree/main/ofl/pressstart2p | SIL Open Font License 1.1 (`assets/fonts/OFL.txt`) | `assets/fonts/PressStart2P-Regular.ttf` | pack |
