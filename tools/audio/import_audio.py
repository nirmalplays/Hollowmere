"""Copy the game's audio into assets/audio with clean names and write the sound bank.

Sources:
  - the owner's packs, dropped in the project root (BGM/, Climate sounds/,
    Sound effects/, Special effect/), git-ignored as raw files
  - CC0 packs in $HOLLOWMERE_SOURCES/audio: RPG Sound Pack (artisticdude),
    80 CC0 RPG SFX (rubberduck), 50 RPG Sound Effects (Kenney)
Output: assets/audio/<group>/<name>.<ext> and data/audio/sound_bank.tres
(name -> list of variations; one is picked at random each play).

  python -I tools/audio/import_audio.py
"""
import os
import shutil

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
SOURCES = os.environ.get("HOLLOWMERE_SOURCES", os.path.join(os.path.dirname(PROJECT), "hollowmere_sources"))
A = os.path.join(SOURCES, "audio")
RPG = os.path.join(A, "rpg_sound_pack", "RPG Sound Pack")
CC80 = os.path.join(A, "80-CC0-RPG-SFX_0")
KEN = os.path.join(A, "RPGsounds_Kenney", "OGG")
OWN = PROJECT

# sound name -> (group, [source files])
BANK = {
    # music (looped)
    "music_menu": ("music", [f"{OWN}/BGM/Intro music.mp3"]),
    "music_explore": ("music", [f"{OWN}/BGM/Exploration 1.mp3", f"{OWN}/BGM/Exploration 2.mp3", f"{OWN}/BGM/Exploration 3.mp3"]),
    "music_battle": ("music", [f"{OWN}/BGM/Battle 1.mp3"]),
    "music_miniboss": ("music", [f"{OWN}/BGM/Mini battle 1.mp3", f"{OWN}/BGM/Miini battle 2.mp3", f"{OWN}/BGM/Mini battle 3.mp3"]),
    "music_cutscene": ("music", [f"{OWN}/BGM/First cut scene BGM.mp3"]),
    # ambience (looped)
    "amb_forest": ("ambient", [f"{OWN}/Climate sounds/Breeze and birds.mp3"]),
    "amb_fire": ("ambient", [f"{OWN}/Climate sounds/Fire burn.mp3"]),
    "amb_rain": ("ambient", [f"{OWN}/Climate sounds/Rain.mp3"]),
    "amb_cave": ("ambient", [f"{A}/dungeon_ambient_1.ogg"]),  # Loopable Dungeon Ambience (CC0, OpenGameArt)
    "thunder": ("ambient", [f"{OWN}/Climate sounds/Thunder.mp3"]),
    # interface
    "ui_move": ("ui", [f"{OWN}/Sound effects/mixkit-game-ball-tap-2073.wav"]),
    "ui_select": ("ui", [f"{RPG}/interface/interface2.wav"]),
    "ui_back": ("ui", [f"{RPG}/interface/interface5.wav"]),
    "game_start": ("ui", [f"{OWN}/Sound effects/freesound_community-game-start-6104.mp3"]),
    # player
    "footstep": ("sfx", [f"{KEN}/footstep0{i}.ogg" for i in range(10)]),
    "swing_light": ("sfx", [f"{RPG}/battle/swing.wav", f"{RPG}/battle/swing2.wav", f"{RPG}/battle/swing3.wav"]),
    "swing_heavy": ("sfx", [f"{CC80}/blade_01.ogg", f"{CC80}/blade_02.ogg", f"{CC80}/blade_03.ogg"]),
    "dodge": ("sfx", [f"{KEN}/cloth{i}.ogg" for i in range(1, 5)]),
    "block": ("sfx", [f"{CC80}/metal_01.ogg", f"{CC80}/metal_02.ogg", f"{CC80}/metal_03.ogg"]),
    "parry": ("sfx", [f"{OWN}/Sound effects/mixkit-magic-glitter-shot-2353.wav"]),
    "player_hurt": ("sfx", [f"{OWN}/Sound effects/mixkit-small-hit-in-a-game-2072.wav"]),
    "player_death": ("sfx", [f"{OWN}/Sound effects/mixkit-player-losing-or-failing-2042.wav"]),
    "respawn": ("sfx", [f"{OWN}/Sound effects/universfield-game-respawn-153317.mp3"]),
    # enemies
    "hit_flesh": ("sfx", [f"{OWN}/Sound effects/mixkit-game-blood-pop-slide-2363.wav", f"{OWN}/Sound effects/mixkit-small-hit-in-a-game-2072.wav"]),
    "enemy_hurt": ("sfx", [f"{CC80}/creature_hurt_01.ogg", f"{CC80}/creature_hurt_02.ogg"]),
    "enemy_die": ("sfx", [f"{CC80}/creature_die_01.ogg"]),
    "enemy_windup": ("sfx", [f"{CC80}/creature_misc_0{i}.ogg" for i in range(1, 5)]),
    # rewards and story beats (used from M4+)
    "pickup": ("sfx", [f"{OWN}/Sound effects/floraphonic-power-up-sparkle-1-177983.mp3"]),
    "coins": ("sfx", [f"{CC80}/item_coins_0{i}.ogg" for i in range(1, 5)]),
    "treasure": ("sfx", [f"{OWN}/Sound effects/mixkit-video-game-treasure-2066.wav"]),
    "quest_complete": ("sfx", [f"{OWN}/Sound effects/mixkit-medieval-show-fanfare-announcement-226.wav"]),
    "level_up": ("sfx", [f"{OWN}/Sound effects/mixkit-game-level-completed-2059.wav"]),
    "game_over": ("sfx", [f"{OWN}/Sound effects/alphix-game-over-417465.mp3"]),
    # spells (M5)
    "spell_air": ("spells", [f"{OWN}/Special effect/Air.mp3"]),
    "spell_earth": ("spells", [f"{OWN}/Special effect/Earth.mp3"]),
    "spell_fire": ("spells", [f"{OWN}/Special effect/Fire.mp3"]),
    "spell_water": ("spells", [f"{OWN}/Special effect/Wave.mp3"]),
}
LOOPED_GROUPS = {"music", "ambient"}


def main():
    out_root = os.path.join(PROJECT, "assets", "audio")
    entries = {}
    for name, (group, files) in BANK.items():
        paths = []
        for i, src in enumerate(files):
            if not os.path.exists(src):
                print("missing", src)
                continue
            ext = os.path.splitext(src)[1].lower()
            dst_rel = f"{group}/{name}{'_' + str(i + 1) if len(files) > 1 else ''}{ext}"
            dst = os.path.join(out_root, dst_rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy(src, dst)
            paths.append("res://assets/audio/" + dst_rel)
        entries[name] = (group, paths)
    lines = ['[gd_resource type="Resource" script_class="SoundBank" load_steps=2 format=3]', "",
             '[ext_resource type="Script" path="res://scripts/core/sound_bank.gd" id="1"]', ""]
    ids, n = {}, 0
    for name, (_, paths) in entries.items():
        for p in paths:
            n += 1
            ids[p] = f"s{n}"
            lines.insert(-1, f'[ext_resource type="AudioStream" path="{p}" id="s{n}"]')
    body = ",\n".join(f'"{name}": [' + ", ".join(f'ExtResource("{ids[p]}")' for p in paths) + "]"
                      for name, (_, paths) in entries.items() if paths)
    groups = ",\n".join(f'"{name}": &"{group}"' for name, (group, paths) in entries.items() if paths)
    lines += ["", "[resource]", 'script = ExtResource("1")', "sounds = {\n" + body + "\n}", "groups = {\n" + groups + "\n}", ""]
    os.makedirs(os.path.join(PROJECT, "data", "audio"), exist_ok=True)
    with open(os.path.join(PROJECT, "data", "audio", "sound_bank.tres"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print(len(entries), "sounds,", n, "files")


if __name__ == "__main__":
    main()
