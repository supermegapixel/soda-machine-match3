extends Node

const SAMPLE_RATE := 22050
const MAX_VOICES := 12
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []

func _ready() -> void:
	sounds["swap"] = synthesize([420.0, 620.0], 0.045)
	sounds["match"] = synthesize([1046.5, 1318.5, 1568.0, 2093.0], 0.065)
	sounds["explosion"] = synthesize([160.0, 90.0, 45.0], 0.09, true)
	sounds["win"] = synthesize([523.25, 659.25, 783.99, 1046.5], 0.14)
	sounds["loss"] = synthesize([392.0, 329.63, 261.63, 196.0], 0.16)

func synthesize(notes: Array, note_seconds: float, noisy: bool = false) -> AudioStreamWAV:
	var frames := int(SAMPLE_RATE * note_seconds)
	var data := PackedByteArray()
	data.resize(frames * notes.size() * 2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 42
	for note in notes.size():
		for frame in frames:
			var t := float(frame) / SAMPLE_RATE
			var envelope := minf(t / 0.005, 1.0) * pow(1.0 - float(frame) / frames, 2.0)
			var wave := sin(TAU * notes[note] * t)
			if noisy:
				wave = wave * 0.4 + noise.randf_range(-1.0, 1.0) * 0.6
			data.encode_s16((note * frames + frame) * 2, int(wave * envelope * 16000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

func play_sound(kind: String, pitch: float = 1.0) -> void:
	var voice: AudioStreamPlayer
	for candidate in voices:
		if not candidate.playing:
			voice = candidate
			break
	if voice == null:
		if voices.size() >= MAX_VOICES:
			voice = voices.pop_front()
			voice.stop()
		else:
			voice = AudioStreamPlayer.new()
			add_child(voice)
		voices.append(voice)
	voice.stream = sounds[kind]
	voice.pitch_scale = pitch
	voice.volume_db = -10.0
	voice.play()

func stop_all() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null

func _exit_tree() -> void:
	stop_all()

func match_pitch(cascade: int) -> float:
	return pow(2.0, mini(maxi(cascade - 1, 0), 12) / 12.0)

func play_swap() -> void:
	play_sound("swap")

func play_match(cascade: int) -> void:
	play_sound("match", match_pitch(cascade))

func play_explosion() -> void:
	play_sound("explosion")

func play_win() -> void:
	play_sound("win")

func play_loss() -> void:
	play_sound("loss")
