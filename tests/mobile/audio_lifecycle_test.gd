extends SceneTree
## Checks real WAV playback, background suspension and deferred mixer cleanup.

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for cue: StringName in HotelAudio.SOUNDS:
		var before := _references(cue)
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
		var deadline := Time.get_ticks_msec() + 2000
		while _references(cue) != before and Time.get_ticks_msec() < deadline:
			await create_timer(0.02).timeout
		check(player_ref.get_ref() == null, "player released")
		check(_references(cue) == before, "mixer releases playback resource " + String(cue))
	print(JSON.stringify({"suite": "mobile_audio_lifecycle", "checks": checks, "failures": failures}))
	print("MOBILE_TEST_COMPLETE")
	quit(1 if failures else 0)

func _references(cue: StringName) -> int:
	# Finish the resource access on this synchronous stack before the polling
	# coroutine yields, so its own expression cannot hold a playback reference.
	return HotelAudio.SOUNDS[cue].get_reference_count()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
