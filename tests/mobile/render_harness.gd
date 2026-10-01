extends SceneTree
## Native event routing and render evidence shared by mobile UI suites.

var failures: int = 0
var checks: int = 0
var screenshots: Array[String] = []
var audio_baseline: Dictionary = {}

func _initialize() -> void:
	# Native ScrollContainer gates touch dragging on touchscreen availability.
	# Enable Godot's hardware emulation for QA on this Windows/headless host.
	Input.emulate_touch_from_mouse = true
	MobileLocale.install("en")
	audio_baseline = _audio_references()
	call_deferred("run")

func frames(count: int = 3) -> void:
	for frame in count:
		await process_frame

func click(_viewport: Viewport, point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames(2)
	await frames()

func drag(index: int, point: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = point
	event.relative = relative
	Input.parse_input_event(event)
	await frames(2)

func touch(index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	Input.parse_input_event(event)
	await frames(2)

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var path := "user://mobile-%s.png" % name
	var image := root.get_texture().get_image()
	check(not image.is_empty() and image.save_png(path) == OK, "rendered capture " + name)
	screenshots.append(ProjectSettings.globalize_path(path))

func _store_capture(image: Image, path: String) -> void:
	check(image.save_png(path) == OK, "capture written")
	screenshots.append(ProjectSettings.globalize_path(path))

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func finish(suite: String, extra: Dictionary = {}) -> void:
	_complete.call_deferred(suite, extra)

func _audio_references() -> Dictionary:
	# Query on a synchronous stack; the polling coroutine must not retain a WAV.
	var counts := {}
	for cue: StringName in HotelAudio.SOUNDS:
		counts[cue] = HotelAudio.SOUNDS[cue].get_reference_count()
	return counts

func _complete(suite: String, extra: Dictionary) -> void:
	# AudioServer releases stopped playback on its own mixer thread, after nodes
	# have gone. Wait for exact original counts, with a hard bound and assertions.
	var deadline := Time.get_ticks_msec() + 2000
	while _audio_references() != audio_baseline and Time.get_ticks_msec() < deadline:
		await create_timer(0.02).timeout
	var counts := _audio_references()
	for cue: StringName in audio_baseline:
		check(counts[cue] == audio_baseline[cue], "mixer released " + String(cue))
	var result := {"suite": suite, "checks": checks, "failures": failures, "rendered": DisplayServer.get_name() != "headless", "screenshots": screenshots}
	result.merge(extra)
	print(JSON.stringify(result))
	print("MOBILE_TEST_COMPLETE")
	# Async callers release their domain/UI locals before the engine tears down.
	quit.call_deferred(1 if failures else 0)
