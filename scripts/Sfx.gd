extends Node

## Banque de sons générés par code (synthèse) — aucun fichier audio à stocker.
## Déclaré en autoload (singleton "Sfx"), donc accessible partout : Sfx.play(Sfx.coin)

const RATE := 22050

var _players: Array[AudioStreamPlayer] = []
var _next := 0

var coin: AudioStreamWAV
var attack: AudioStreamWAV
var hurt: AudioStreamWAV
var enemy_die: AudioStreamWAV
var level_up: AudioStreamWAV
var game_over: AudioStreamWAV


func _ready() -> void:
	# Petit pool de lecteurs pour jouer plusieurs sons en même temps
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

	coin = _sweep(880.0, 1320.0, 0.12, 0.40, false)
	attack = _sweep(620.0, 190.0, 0.13, 0.32, true)
	hurt = _sweep(220.0, 110.0, 0.20, 0.40, true)
	enemy_die = _sweep(520.0, 90.0, 0.22, 0.34, false)
	level_up = _arp([523.0, 659.0, 784.0, 1047.0], 0.09, 0.34, false)
	game_over = _arp([440.0, 349.0, 294.0, 220.0], 0.16, 0.36, false)


func play(stream: AudioStream) -> void:
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.play()


## Génère un son à fréquence glissante (start -> end) avec enveloppe décroissante.
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
			env *= t / 0.02   # petite attaque pour éviter le "clic"
		data.encode_s16(i * 2, int(clampf(s * env * vol, -1.0, 1.0) * 32767.0))
	return _to_wav(data)


## Génère un arpège (suite de notes) — utilisé pour "niveau suivant" et "game over".
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


func _to_wav(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
