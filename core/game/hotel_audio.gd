class_name HotelAudio
extends Node
## Presentation-only sound; no simulation signals or saved gameplay state.

const SOUNDS: Dictionary = {
	&"build": preload("res://assets/audio/build.wav"),
	&"upgrade": preload("res://assets/audio/upgrade.wav"),
	&"objective": preload("res://assets/audio/objective.wav"),
}
var enabled: bool = true
var player: AudioStreamPlayer

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.volume_db = -12.0
	add_child(player)
	var config := ConfigFile.new()
	if config.load("user://audio.cfg") == OK:
		var stored: Variant = config.get_value("audio", "enabled", true)
		if stored is bool:
			enabled = stored

func play(cue: StringName) -> void:
	if enabled and player != null and SOUNDS.has(cue):
		player.stream = SOUNDS[cue]
		player.play()

func toggle() -> void:
	enabled = not enabled
	if not enabled:
		player.stop()
	var config := ConfigFile.new()
	config.set_value("audio", "enabled", enabled)
	config.save("user://audio.cfg")

func suspend() -> void:
	if player != null:
		player.stop()
		player.stream = null

func _exit_tree() -> void:
	suspend()
