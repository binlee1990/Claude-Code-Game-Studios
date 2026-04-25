class_name SRPGAudioBus
extends Node

## Generates short UI/battle tones at runtime so the production slice has
## audible feedback without depending on external audio assets.

const _SAMPLE_RATE := 22050
const _CUES := {
	"menu": {"frequency": 440.0, "duration": 0.060, "volume": 0.18},
	"camp": {"frequency": 660.0, "duration": 0.090, "volume": 0.16},
	"attack": {"frequency": 180.0, "duration": 0.080, "volume": 0.20},
	"victory": {"frequency": 880.0, "duration": 0.160, "volume": 0.16},
	"save": {"frequency": 520.0, "duration": 0.070, "volume": 0.14},
	"error": {"frequency": 130.0, "duration": 0.110, "volume": 0.16},
}

var enable_playback: bool = true
var _played_cues: Array[String] = []

func play_cue(cue_id: String) -> void:
	if not _CUES.has(cue_id):
		cue_id = "menu"
	_played_cues.append(cue_id)
	if not enable_playback:
		return
	var player := AudioStreamPlayer.new()
	player.stream = _build_tone(_CUES[cue_id])
	player.volume_db = -10.0
	add_child(player)
	player.play()
	var timer := get_tree().create_timer(float(_CUES[cue_id].get("duration", 0.08)) + 0.05)
	timer.timeout.connect(_free_audio_player.bind(player.get_instance_id()))

func get_played_cues() -> Array[String]:
	return _played_cues.duplicate()

func clear_history() -> void:
	_played_cues.clear()

func _build_tone(spec: Dictionary) -> AudioStreamWAV:
	var frequency := float(spec.get("frequency", 440.0))
	var duration := float(spec.get("duration", 0.08))
	var volume := float(spec.get("volume", 0.16))
	var frame_count := maxi(1, int(float(_SAMPLE_RATE) * duration))
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	for i in range(frame_count):
		var t := float(i) / float(_SAMPLE_RATE)
		var fade := 1.0 - (float(i) / float(frame_count))
		var sample := int(sin(TAU * frequency * t) * 32767.0 * volume * fade)
		var offset := i * 2
		data[offset] = sample & 0xff
		data[offset + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = _SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

func _free_audio_player(instance_id: int) -> void:
	var instance := instance_from_id(instance_id)
	if instance is Node and is_instance_valid(instance):
		(instance as Node).queue_free()
