extends Node

## Banque de sons + musique générés par code (synthèse) — aucun fichier audio.
## Déclaré en autoload (singleton "Sfx") : Sfx.play(Sfx.coin), Sfx.play_music()

const RATE := 22050

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music_player: AudioStreamPlayer

var coin: AudioStreamWAV
var attack: AudioStreamWAV
var hurt: AudioStreamWAV
var enemy_die: AudioStreamWAV
var level_up: AudioStreamWAV
var game_over: AudioStreamWAV
var door: AudioStreamWAV
var powerup: AudioStreamWAV
var music: AudioStreamWAV


func _ready() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -9.0
	add_child(_music_player)

	coin = _sweep(880.0, 1320.0, 0.12, 0.40, false)
	attack = _sweep(620.0, 190.0, 0.13, 0.32, true)
	hurt = _sweep(220.0, 110.0, 0.20, 0.42, true)
	enemy_die = _sweep(520.0, 90.0, 0.22, 0.34, false)
	level_up = _arp([523.0, 659.0, 784.0, 1047.0], 0.09, 0.34, false)
	game_over = _arp([440.0, 349.0, 294.0, 220.0], 0.16, 0.36, false)
	door = _arp([392.0, 587.0, 784.0], 0.11, 0.32, false)
	powerup = _arp([659.0, 880.0, 1175.0], 0.07, 0.34, false)
	music = _make_music()


func play(stream: AudioStream) -> void:
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.play()


func play_music() -> void:
	if not _music_player.playing:
		_music_player.stream = music
		_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func _exit_tree() -> void:
	# Stoppe la lecture avant la destruction (évite les fuites au shutdown)
	if is_instance_valid(_music_player):
		_music_player.stop()


## Son à fréquence glissante avec enveloppe décroissante.
func _sweep(start_freq: float, end_freq: float, dur: float, vol: float, square: bool) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		var freq := lerpf(start_freq, end_freq, t)
		phase += TAU * freq / RATE
		var s := sin(phase)
		if square:
			s = signf(s)
		var env := 1.0 - t
		if t < 0.02:
			env *= t / 0.02
		data.encode_s16(i * 2, int(clampf(s * env * vol, -1.0, 1.0) * 32767.0))
	return _to_wav(data)


## Suite de notes (arpège).
func _arp(notes: Array, note_dur: float, vol: float, square: bool) -> AudioStreamWAV:
	var per := int(RATE * note_dur)
	var data := PackedByteArray()
	data.resize(per * notes.size() * 2)
	var idx := 0
	for note in notes:
		var freq: float = note
		var phase := 0.0
		for i in per:
			var t := float(i) / per
			phase += TAU * freq / RATE
			var s := sin(phase)
			if square:
				s = signf(s)
			var env := 1.0 - t
			if t < 0.02:
				env *= t / 0.02
			data.encode_s16(idx * 2, int(clampf(s * env * vol, -1.0, 1.0) * 32767.0))
			idx += 1
	return _to_wav(data)


## Boucle musicale d'ambiance : basse + mélodie pentatonique.
func _make_music() -> AudioStreamWAV:
	var mel := [
		440.0, 523.0, 587.0, 659.0, 587.0, 523.0, 440.0, 392.0,
		440.0, 523.0, 659.0, 784.0, 659.0, 587.0, 523.0, 440.0,
	]
	var bass := [
		110.0, 110.0, 146.0, 146.0, 164.0, 164.0, 110.0, 110.0,
		110.0, 110.0, 146.0, 146.0, 196.0, 196.0, 110.0, 110.0,
	]
	var step_dur := 0.30
	var per := int(RATE * step_dur)
	var total := per * mel.size()
	var data := PackedByteArray()
	data.resize(total * 2)
	var mphase := 0.0
	var bphase := 0.0
	for s in mel.size():
		var mf: float = mel[s]
		var bf: float = bass[s]
		for i in per:
			var t := float(i) / per
			mphase += TAU * mf / RATE
			bphase += TAU * bf / RATE
			var m := sin(mphase) * (1.0 - t) * 0.16
			var b := sin(bphase) * (0.6 + 0.4 * (1.0 - t)) * 0.12
			var idx := s * per + i
			data.encode_s16(idx * 2, int(clampf(m + b, -1.0, 1.0) * 32767.0))
	var w := _to_wav(data)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = total
	return w


func _to_wav(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
