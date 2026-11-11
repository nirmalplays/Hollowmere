extends Node
## Plays music, ambience and sound effects by name (GAME_PLAN 11.4).
## Buses: Master > Music, Ambient, SFX, UI (default_bus_layout.tres).
##   AudioManager.music(&"music_explore")         crossfades to a looping track
##   AudioManager.ambient(&"amb_forest")          one looping ambience bed
##   AudioManager.sfx(&"swing_light")             a one-shot, random variation + pitch
##   AudioManager.sfx_at(&"enemy_hurt", position) positional (fades with distance)

const BANK_PATH: String = "res://data/audio/sound_bank.tres"
const FADE_TIME: float = 1.2
const SFX_VOICES: int = 16
const QUIET_DB: float = -60.0
const BUS_FOR_GROUP := {&"music": &"Music", &"ambient": &"Ambient", &"sfx": &"SFX", &"ui": &"UI", &"spells": &"SFX"}

var bank: SoundBank

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_name: StringName = &""
var _ambient: AudioStreamPlayer
var _ambient_name: StringName = &""
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _last_played: Dictionary = {}  # sound -> msec, to stop machine-gun stacking
## Music states (docs/AUDIT.md #4): the area's track, battle when Hollowed engage,
## the mini-boss theme when a boss is among them; back to the area after a calm beat.
var area_music: StringName = &""
var _engaged: Dictionary = {}  # enemy -> is_boss
var _calm_timer: SceneTreeTimer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # music keeps playing while paused
	bank = load(BANK_PATH) as SoundBank
	_music_a = _make_player(&"Music")
	_music_b = _make_player(&"Music")
	_ambient = _make_player(&"Ambient")
	for i in SFX_VOICES:
		_voices.append(_make_player(&"SFX"))
	EventBus.enemy_aggro.connect(_on_enemy_aggro)


## Areas call this instead of music(): it becomes the calm state to return to.
func set_area_music(sound: StringName) -> void:
	area_music = sound
	_engaged.clear()
	music(sound)


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


func _on_enemy_aggro(enemy: Node, engaged: bool) -> void:
	if area_music == &"":
		return
	if engaged:
		_engaged[enemy] = enemy.get(&"data") != null and enemy.data.is_boss
	else:
		_engaged.erase(enemy)
	for e in _engaged.keys():
		if not is_instance_valid(e):
			_engaged.erase(e)
	if _engaged.is_empty():
		_calm_timer = get_tree().create_timer(4.0)
		_calm_timer.timeout.connect(func() -> void:
			if _engaged.is_empty():
				music(area_music, 2.5))
		return
	music(&"music_miniboss" if true in _engaged.values() else &"music_battle", 0.8)


## Crossfades to a looping track (a random variation if the name has several).
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
	voice.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	voice.play()


## A one-shot placed in the world: quieter and panned with distance from the listener.
func sfx_at(sound: StringName, at: Vector2, volume_db: float = 0.0, pitch_jitter: float = 0.06) -> void:
	var stream := _ready_stream(sound, 30)
	if stream == null:
		return
	var p := AudioStreamPlayer2D.new()
	p.bus = &"SFX"
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
	return bank.pick(sound)


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
