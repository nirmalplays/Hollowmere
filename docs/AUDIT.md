# Design audit (critic pass) and rebuild plan

Benchmark: Dimraeth (docs/DIMRAETH_REFERENCE.md, full walkthrough reviewed). Verdict on the
current build: the systems underneath are sound (combat states, data-driven enemies, quests,
audio bus, HUD skeleton), but the **player-facing layer is not shippable**. A player booting
it today meets a placeholder menu, a boxy map, silent transitions and text walls.

## What's wrong, by severity
| # | Area | Problem | Fix |
|---|---|---|---|
| 1 | First impression | Main menu is a grey button list; no title, no music, no mood | Painted animated title screen (forest + ruined arch + the Unlaid with a lantern), forged logo, gold-band list with sword cursor, settings, credits (owner's Bounce Lab layout) |
| 2 | Level design | Crypt rooms are rectangles joined by 2-wide corridors; no landmarks, no secrets, no reason to look around | Organic caves with irregular walls, pillars, alcoves, side rooms with chests, a vista, a light-led path (light = guidance) |
| 3 | Onboarding | Tips are plain text; nothing explains *what* the Hearth, Rest, Pressure or Scars are | Key-glyph prompts (top-left, reference style), one-time **tutorial cards** (modal, pauses) for every new concept, "QUEST COMPLETE!" banner |
| 4 | Sound design | One track per area, no combat music, silent UI, no cave bed, no stingers | Music states (explore / combat / boss / victory) with crossfades, UI clicks, area-enter stinger, lantern and rest sounds, cave ambience |
| 5 | Feedback | Kills and pickups barely register | XP numbers, item toasts with icons, death/rest flourishes |
| 6 | Dead weight | Diamond-iso glade, Flare/iso import tools, 3D leftovers, training dummy room | Delete; keep one art pipeline (LPC) and one area system (top-down) |

## Build order (now)
1. Title screen + settings + credits. Music on boot.
2. Onboarding layer: key-glyph prompts, tutorial cards, quest-complete banner.
3. Sound pass: music state machine, UI sounds, stingers, cave ambience.
4. Underroot Caves redesign: organic layout, landmarks, side chamber with a chest, readable path.
5. Remove dead weight; tests move to the new areas.
Then: Greywood + Thornwick top-down (MQ02), character creator (book), inventory/chests, trainer.
