# OPEN QUESTIONS

Questions and defaults chosen while building. The owner answers; Claude Code continues with the default meanwhile.

## M0
1. **Block/parry button.** Default chosen: one `block` action (Shift / LT); a parry is a block pressed inside a short window (GAME_PLAN 12, open decision 3). Heavy attack is RMB, so block is not on RMB.
2. **Gamepad gaps.** `skill_tree` and `map` have no gamepad binding yet (table leaves them empty). Suggest a pause-menu tab later.
3. **Aim.** Mouse aim is read from the cursor in code; right stick uses `aim_*` actions.
4. **Godot version.** Built and checked on 4.3-stable (portable build). Newer 4.x should work.
5. **Open decisions still unanswered** (GAME_PLAN 17): title, art direction, release target. Not blocking until M1/M2.

## M1
6. **Character size: 16x24 chosen** (GAME_PLAN 17.2). Side-by-side preview with 32x32 is in `tools/art/preview.png`. 16x24 sits cleanly on 16x16 tiles and matches the custom-art spec (11.3). Say so if you prefer 32x32; the sheet format is data-driven, so it's a data + art swap.
7. **Facing: 4 directions (down, up, side + flip)** for art; movement is full 8-direction. 8-direction art can be added later as extra rows without code changes beyond the direction picker.
8. **Art source.** Kenney packs were not downloaded (no stable direct URLs); all M1 art is generated with `tools/art/` and tagged `generated` in ASSETS.md.
9. **UI font: Press Start 2P** (OFL). Very readable at 8px but wide; a narrower pixel font may suit dialogue better later.
10. **Mouse aim.** The mouse becomes the aim source for 2s after it moves or clicks; otherwise you face where you walk. Right stick always wins.

## Visual overhaul
11. **Supersedes 6 and 7:** characters are now about 40 px tall with 8 directions (Flare-based), on a 32x16 isometric grid.
12. **Dodge has no roll animation** in the Flare set: it's a sped-up run with a ghosted body during i-frames. A custom roll can be drawn later.
13. **CC-BY-SA art (Flare characters)** needs credit in the game's credits screen (planned for M12); modified sprites stay CC-BY-SA.
14. **Still missing from free packs:** NPC townsfolk and building interiors for Thornwick. Will look again at M7/M9 or draw them.
