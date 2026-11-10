# Hollowmere (working title)

Pixel-art, top-down Souls-lite action RPG in Godot 4.3+ (GDScript). Solo first, optional co-op later.
Design docs: [GAME_PLAN.md](GAME_PLAN.md), [STORY_BIBLE.md](STORY_BIBLE.md).

## Run
Open the folder in Godot 4.3+ and press F5, or: `godot --path .`

## Test
- Smoke boot: `godot --headless --path . --quit-after 3`
- M0 checks: `godot --headless --path . --script res://tests/m0_smoke.gd` (exit code 0 = pass)

## Renderer
Compatibility (`gl_compatibility`) for broad desktop support. Viewport 480x270, integer scaling, Nearest filtering.

## Milestone log
- **M0 (done):** project skeleton, pixel settings, folder layout, autoload stubs (EventBus, DataRegistry, GameState, NetManager, SaveManager), full InputMap, boots to a main menu.
