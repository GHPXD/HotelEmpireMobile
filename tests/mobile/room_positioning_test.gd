extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var cases: RefCounted = load("res://tests/mobile/room_positioning_cases.gd").new()
	var result: Dictionary = cases.run()
	cases = null
	print(JSON.stringify(result))
	print("MOBILE_TEST_COMPLETE")
	quit.call_deferred(1 if result.failures else 0)
