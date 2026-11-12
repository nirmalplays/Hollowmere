extends Node
## Plays music, ambience and sound effects by name (GAME_PLAN 11.4).
## Buses: Master > Music, Ambient, SFX, Voice, UI (default_bus_layout.tres).
## Every effect is a set of real recordings: one is picked at random each time, with a
## little pitch and level drift, so nothing repeats exactly (AudioStreamRandomizer).
##   AudioManager.music(&"music_explore")         crossfades to a looping track
##   AudioManager.ambient(&"amb_forest")          one looping ambience bed
##   AudioManager.sfx(&"sword_swing_light")             a one-shot, random variation + pitch
##   AudioManager.sfx_at(&"hollowed_hurt", position) positional (fades with distance)

const BANK_PATH: String = "res://data/audio/sound_bank.tres"
const FADE_TIME: float = 1.2
const SFX_VOICES: int = 16
const QUIET_DB: float = -60.0
const BUS_FOR_GROUP := {&"music": &"Music", &"ambient": &"Ambient", &"sfx": &"SFX", &"ui": &"UI", &"voice": &"Voice"}

var bank: SoundBank

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_name: StringName = &""
var _ambient: AudioStreamPlayer
var _ambient_name: StringName = &""
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _random: Dictionary = {}  # sound -> AudioStreamRandomizer over its variations
var _last_played: Dictionary = {}  # sound -> msec, to stop machine-gun stacking
## Music is placed, not constant (docs/DESIGN_SPEC.md 5): exploration is ambience only;
## music plays in music zones (towns, shrines, story beats) and in boss fights.
var area_music: StringName = &""  ## an area's own track, if it has one (towns); usually empty
var _zone_music: StringName = &""
var _boss: Node
var _bus_rest: Dictionary = {}  # bus -> its volume before a duck


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # music keeps playing while paused
	bank = load(BANK_PATH) as SoundBank
	_music_a = _make_player(&"Music")
	_music_b = _make_player(&"Music")
	_ambient = _make_player(&"Ambient")
	for i in SFX_VOICES:
		_voices.append(_make_player(&"SFX"))
	EventBus.enemy_aggro.connect(_on_enemy_aggro)
	if bank:
		for sound: StringName in bank.sounds:
			if bank.groups.get(sound, &"sfx") in [&"music", &"ambient"]:
				continue
			var r := AudioStreamRandomizer.new()
			r.random_pitch = 1.15
			r.random_volume_offset_db = 1.5
			for stream: AudioStream in bank.variations(sound):
				r.add_stream(-1, stream)
			_random[sound] = r


## Areas call this instead of music(): it becomes the calm state to return to.
func set_area_music(sound: StringName) -> void:
	area_music = sound
	_zone_music = &""
	_boss = null
	_refresh_music()


## Music zones call this on enter (a track) and exit (&"").
func zone_music(sound: StringName) -> void:
	_zone_music = sound
	_refresh_music()


func _refresh_music() -> void:
	var want := &"music_miniboss" if is_instance_valid(_boss) else (_zone_music if _zone_music != &"" else area_music)
	if want == &"":
		stop_music(2.5)
	else:
		music(want, 1.5)


## Caves and crypts echo: a reverb on effects and ambience.
func set_reverb(on: bool) -> void:
	for bus in [&"SFX", &"Ambient"]:
		var idx := AudioServer.get_bus_index(bus)
		if idx < 0:
			continue
		while AudioServer.get_bus_effect_count(idx) > 0:
			AudioServer.remove_bus_effect(idx, 0)
		if on:
			var rev := AudioEffectReverb.new()
			rev.room_size = 0.7
			rev.damping = 0.6
			rev.wet = 0.18
			rev.dry = 1.0
			AudioServer.add_bus_effect(idx, rev)


## Only bosses bring in combat music; ordinary fights stay with the area's sound.
func _on_enemy_aggro(enemy: Node, engaged: bool) -> void:
	if enemy.get(&"data") == null or not enemy.data.is_boss:
		return
	_boss = enemy if engaged and not enemy.is_dead() else null
	_refresh_music()


func music(sound: StringName, fade: float = FADE_TIME) -> void:
	if sound == _music_name or bank == null:
		return
	_music_name = sound
	var stream := _looping(bank.pick(sound))
	var old := _music_a if _music_a.playing else _music_b
	var new := _music_b if old == _music_a else _music_a
	_fade_out(old, fade)
	if stream:
		new.stream = stream
		new.volume_db = QUIET_DB
		new.play()
		create_tween().tween_property(new, ^"volume_db", 0.0, fade)


func stop_music(fade: float = FADE_TIME) -> void:
	_music_name = &""
	_fade_out(_music_a, fade)
	_fade_out(_music_b, fade)


func ambient(sound: StringName, volume_db: float = -6.0) -> void:
	if sound == _ambient_name or bank == null:
		return
	_ambient_name = sound
	_ambient.stream = _looping(bank.pick(sound))
	_ambient.volume_db = QUIET_DB
	_ambient.play()
	create_tween().tween_property(_ambient, ^"volume_db", volume_db, FADE_TIME)


## A one-shot sound. `pitch_jitter` varies pitch a little so repeats feel alive.
func sfx(sound: StringName, volume_db: float = 0.0, pitch_jitter: float = 0.06, min_gap_ms: int = 30) -> void:
	var stream := _ready_stream(sound, min_gap_ms)
	if stream == null:
		return
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.bus = BUS_FOR_GROUP.get(bank.groups.get(sound, &"sfx"), &"SFX")
	voice.stream = stream
	voice.volume_db = volume_db
	voice.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter) * 0.5
	voice.play()


## A one-shot placed in the world: quieter and panned with distance from the listener.
func sfx_at(sound: StringName, at: Vector2, volume_db: float = 0.0, pitch_jitter: float = 0.06) -> void:
	var stream := _ready_stream(sound, 30)
	if stream == null:
		return
	var p := AudioStreamPlayer2D.new()
	p.bus = BUS_FOR_GROUP.get(bank.groups.get(sound, &"sfx"), &"SFX")
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.max_distance = 420.0
	p.attenuation = 1.4
	p.global_position = at
	p.finished.connect(p.queue_free)
	var scene := get_tree().current_scene
	(scene if scene else self).add_child(p)
	p.play()


## A looping positional emitter (campfires, waterfalls). The caller owns the node.
func make_emitter(sound: StringName, volume_db: float = -4.0, max_distance: float = 220.0) -> AudioStreamPlayer2D:
	var p := AudioStreamPlayer2D.new()
	p.bus = &"Ambient"
	p.stream = _looping(bank.pick(sound)) if bank else null
	p.volume_db = volume_db
	p.max_distance = max_distance
	p.autoplay = p.stream != null
	return p


## A blow lands: music and the air drop back for a moment so the hit owns the mix.
## Runs on real time, so it works through hit-stop.
func duck(seconds: float, depth_db: float = -7.0) -> void:
	for bus: StringName in [&"Music", &"Ambient"]:
		var idx := AudioServer.get_bus_index(bus)
		if idx < 0 or AudioServer.is_bus_mute(idx):
			continue
		var rest: float = _bus_rest.get(bus, AudioServer.get_bus_volume_db(idx))
		_bus_rest[bus] = rest
		AudioServer.set_bus_volume_db(idx, rest + depth_db)
		_unduck(bus, idx, rest, seconds)


## Real-time timers (they ignore time scale), stepping the bus back up to where it was.
func _unduck(bus: StringName, idx: int, rest: float, seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout
	for step in 5:
		AudioServer.set_bus_volume_db(idx, lerpf(AudioServer.get_bus_volume_db(idx), rest, 0.5))
		await get_tree().create_timer(0.06, true, false, true).timeout
	AudioServer.set_bus_volume_db(idx, rest)
	_bus_rest.erase(bus)


func set_bus_volume(bus: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(idx, linear <= 0.001)


func get_bus_volume(bus: StringName) -> float:
	var idx := AudioServer.get_bus_index(bus)
	return 0.0 if idx < 0 or AudioServer.is_bus_mute(idx) else db_to_linear(AudioServer.get_bus_volume_db(idx))


func _ready_stream(sound: StringName, min_gap_ms: int) -> AudioStream:
	if bank == null:
		return null
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sound, -100000)) < min_gap_ms:
		return null
	_last_played[sound] = now
	return _random.get(sound, bank.pick(sound))


func _make_player(bus: StringName) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _fade_out(player: AudioStreamPlayer, fade: float) -> void:
	if not player.playing:
		return
	var tween := create_tween()
	tween.tween_property(player, ^"volume_db", QUIET_DB, fade)
	tween.tween_callback(player.stop)


static func _looping(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	return stream
