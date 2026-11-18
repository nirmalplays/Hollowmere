"""Copy the game's audio into assets/audio with clean names and write the sound bank.

Every effect is a real recording from a CC0 pack (nothing is synthesised here; this
script only copies files). Each action gets three or more variations where the packs
have them, and AudioManager plays one at random with a little pitch and level drift.

Sources in $HOLLOWMERE_SOURCES/audio (see ASSETS.md for URLs and licences):
  impact/      Kenney Impact Sounds   (footsteps, punches, plate and metal hits)
  RPGsounds_Kenney/  Kenney RPG Audio (cloth, knives, coins, books)
  ui_audio/    Kenney UI Audio        (clicks, rollovers, switches)
  rpg_sound_pack/    RPG Sound Pack, artisticdude (swings, unsheathing, magic)
  80-CC0-RPG-SFX_0/  80 CC0 RPG SFX, rubberduck (blades, spells, items, creatures)
  voice_dl/    OpenGameArt CC0 voices: male grunts, hurt sounds, hit sounds and a
               death, monster growls, 80 CC0 creature SFX
Music and weather beds are the owner's own tracks (BGM/, Climate sounds/ in the
project root).

  python -I tools/audio/import_audio.py
"""
import os
import shutil

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
# The raw packs ship with the project in sources/; HOLLOWMERE_SOURCES overrides.
SOURCES = os.environ.get("HOLLOWMERE_SOURCES", os.path.join(PROJECT, "sources"))
A = os.path.join(SOURCES, "audio")
IMPACT = os.path.join(A, "impact", "addons", "kenney impact sounds")
KEN = os.path.join(A, "RPGsounds_Kenney", "OGG")
UI = os.path.join(A, "ui_audio", "addons", "kenney_ui_audio")
RPG = os.path.join(A, "rpg_sound_pack", "RPG Sound Pack")
CC80 = os.path.join(A, "80-CC0-RPG-SFX_0")
V = os.path.join(A, "voice_dl")
CREATURE = os.path.join(V, "80-cc0-creature-sfx")
OWN = PROJECT


def seq(pattern, numbers):
    return [pattern % n for n in numbers]


# sound name -> (group, [source files]); group decides the bus (see AudioManager)
BANK = {
    # music and weather (looped): the owner's own tracks
    "music_menu": ("music", [f"{OWN}/BGM/Intro music.mp3"]),
    "music_explore": ("music", [f"{OWN}/BGM/Exploration 1.mp3", f"{OWN}/BGM/Exploration 2.mp3", f"{OWN}/BGM/Exploration 3.mp3"]),
    "music_battle": ("music", [f"{OWN}/BGM/Battle 1.mp3"]),
    "music_miniboss": ("music", [f"{OWN}/BGM/Mini battle 1.mp3", f"{OWN}/BGM/Miini battle 2.mp3", f"{OWN}/BGM/Mini battle 3.mp3"]),
    "music_cutscene": ("music", [f"{OWN}/BGM/First cut scene BGM.mp3"]),
    "amb_forest": ("ambient", [f"{OWN}/Climate sounds/Breeze and birds.mp3"]),
    "amb_fire": ("ambient", [f"{OWN}/Climate sounds/Fire burn.mp3"]),
    "amb_rain": ("ambient", [f"{OWN}/Climate sounds/Rain.mp3"]),
    "thunder": ("ambient", [f"{OWN}/Climate sounds/Thunder.mp3"]),
    # interface (Kenney UI Audio)
    "ui_hover": ("ui", seq(UI + "/rollover%d.wav", (1, 2, 3, 4))),
    "ui_click": ("ui", seq(UI + "/click%d.wav", (1, 2, 3, 4, 5))),
    "ui_back": ("ui", seq(UI + "/switch%d.wav", (2, 3, 4))),
    "game_start": ("ui", seq(RPG + "/battle/sword-unsheathe%s.wav", ("", "2", "3"))),
    # the body (Kenney Impact Sounds, Kenney RPG Audio)
    "footstep": ("sfx", seq(IMPACT + "/footstep_grass_00%d.ogg", range(5))),
    "footstep_stone": ("sfx", seq(IMPACT + "/footstep_concrete_00%d.ogg", range(5))),
    "dodge_whoosh": ("sfx", seq(KEN + "/cloth%d.ogg", (1, 2, 3, 4))),
    # steel
    "sword_swing_light": ("sfx", [f"{RPG}/battle/swing.wav", f"{RPG}/battle/swing2.wav", f"{RPG}/battle/swing3.wav"]),
    "sword_swing_heavy": ("sfx", seq(CC80 + "/blade_0%d.ogg", (1, 2, 3))),
    "hit_flesh": ("sfx", seq(IMPACT + "/impact_punch_medium_00%d.ogg", range(5))),
    "hit_heavy": ("sfx", seq(IMPACT + "/impact_punch_heavy_00%d.ogg", range(5))),
    "hit_armor": ("sfx", seq(IMPACT + "/impact_plate_medium_00%d.ogg", range(5))),
    "parry_clang": ("sfx", seq(IMPACT + "/impact_metal_heavy_00%d.ogg", range(5))),
    # the hero's voice (OpenGameArt CC0)
    "voice_attack": ("voice", seq(V + "/male-gruntyelling-sounds/yelling sounds/3grunt%d.wav", (1, 2, 3, 4, 5, 6))),
    "voice_dodge": ("voice", seq(V + "/male-gruntyelling-sounds/yelling sounds/3grunt%d.wav", (2, 4, 6))),
    "voice_hurt": ("voice", [V + "/hurt-sound-effects--hurt_01_0.mp3"] + seq(V + "/hurt-sound-effects--hurt_0%d.mp3", (2, 3, 4, 5, 6))),
    "voice_death": ("voice", [V + "/5-hit-sounds-dying/ogg/die1.ogg"]),
    # the Hollowed
    "hollowed_groan": ("voice", seq(CREATURE + "/grunt_0%d.ogg", (1, 2, 3, 4, 5))),
    "hollowed_hurt": ("voice", seq(CREATURE + "/hurt_0%d.ogg", (1, 2, 3, 4, 5))),
    "hollowed_die": ("voice", [CC80 + "/creature_die_01.ogg"] + seq(V + "/16-monster-growls/monster.%d.ogg", (1, 2, 3))),
    "boss_telegraph": ("voice", seq(CREATURE + "/roar_0%d.ogg", (1, 2, 3))),
    # lantern, spells, rewards
    "lantern_rest": ("sfx", seq(CC80 + "/spell_0%d.ogg", (1, 2))),
    "spell_cast": ("sfx", seq(CC80 + "/spell_fire_0%d.ogg", (1, 2, 3, 4))),
    "pickup": ("sfx", seq(CC80 + "/item_gem_0%d.ogg", (1, 2, 3, 4))),
    "coins": ("sfx", seq(CC80 + "/item_coins_0%d.ogg", (1, 2, 3, 4))),
    "treasure": ("sfx", seq(CC80 + "/lock_0%d.ogg", (1, 2, 3))),
    "level_up": ("sfx", [f"{RPG}/inventory/metal-ringing.wav"]),
    "quest_complete": ("sfx", [f"{KEN}/bookClose.ogg", f"{KEN}/bookPlace1.ogg"]),
    "respawn": ("sfx", [f"{RPG}/battle/magic1.wav"]),
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
