extends SceneTree
## Checks real WAV playback, background suspension and deferred mixer cleanup.

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for cue: StringName in HotelAudio.SOUNDS:
		var before: int = HotelAudio.SOUNDS[cue].get_reference_count()
		var sound := HotelAudio.new()
		root.add_child(sound)
		sound.enabled = true
		sound.play(cue)
		check(sound.player.playing and sound.player.stream == HotelAudio.SOUNDS[cue], "cue starts actual WAV " + String(cue))
		sound.suspend()
		check(not sound.player.playing and sound.player.stream == null, "background stops and clears stream")
		var player_ref: WeakRef = weakref(sound.player)
		sound.queue_free()
		await process_frame
		await create_timer(0.15).timeout
		check(player_ref.get_ref() == null, "player released")
		check(HotelAudio.SOUNDS[cue].get_reference_count() == before, "mixer releases playback resource " + String(cue))
	print(JSON.stringify({"suite": "mobile_audio_lifecycle", "checks": checks, "failures": failures}))
	print("MOBILE_TEST_COMPLETE")
	quit(1 if failures else 0)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
