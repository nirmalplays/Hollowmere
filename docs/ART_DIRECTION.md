# Art direction and presentation (reference: Dimraeth)

Our bar: it should feel like an indie team's game, not a generated one. Every screen gets
checked against the reference shots before it ships.

## What the reference does
| Area | Dimraeth | Rule for Hollowmere |
|---|---|---|
| Camera | Top-down 3/4, orthographic, square grid. Walls, fences and rooms run straight; buildings show their front face | Square 32 px grid, no diamond isometric. Front faces of walls/cliffs are visible |
| Scale | Zoomed out. Characters ~5% of screen height; trees and buildings several times taller than a person | Render 960x540. Characters ~48 px (LPC). Trees 3-6x a character's height; doors and props sized to a person |
| Characters | Chibi pixel art: big head, short body, flat clean colours, readable silhouette | LPC-family sprites; same outline and shading for everyone |
| World | Dense, hand-placed: stumps, crates, lanterns, bones, books, grass in clumps. Paths worn, edges broken | Hand-authored areas. Clusters, not scatter; every area has a landmark and a reason |
| Light | Dark ambient, warm point lights (lanterns, fires), cold accents (crystals, water), fog, dust, fireflies | CanvasModulate at night levels, PointLight2D on every light source, particles in every scene |
| HUD | Bottom-left: diamond quick slots, XP, slanted stamina/mana bars over a big slanted HP bar. Bottom-right: diamond ability bar. Right: quest tracker (serif title, diamond bullets). Lore text in small serif boxes | Same layout and grammar, our own art and colours |
| Story delivery | Short lore lines on interaction ("A journal page reads..."), quest steps always visible | Inscriptions, ledgers and barks from STORY_BIBLE, shown the same way |

## Vertical slice: Act I opening, "The Waking" (STORY_BIBLE 6)
1. Wake in a stone cradle in the sealed crypt under the shrine. A cracked lantern burns; other cradles are empty, shattered, one still glowing; names carved on the empty ones.
2. Quest tracker: **The Waking** (Find a way out of the crypt).
3. Inscriptions to read (lore boxes). First Hollowed (husks) teach stamina, dodge, block and parry.
4. The scripted first death: rise at the cradle (the Hearth), a Scar is explained.
5. The Gaunt Sexton (mini-boss) in the ossuary. Drops the Sexton's Key and the first Memory Shard.
6. Stairs up into the shrine ruin overlooking the grey valley (Greywood): end of the slice.

## Art sources (all free, credited in ASSETS.md)
- Characters, NPCs, monsters: Universal LPC Spritesheet (CC-BY-SA 3.0 / GPL 3.0).
- Tiles and props: LPC tile atlases and dungeon sets (CC-BY-SA), CC0 packs where they match.
- Effects: pixelfx (MIT). Fonts: OFL.
