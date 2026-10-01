extends SceneTree
## Paid construction across autosave, OS kill, background and hostile envelopes.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var cases: RefCounted = load("res://tests/mobile/construction_lifecycle_cases.gd").new()
	var result: Dictionary = cases.run()
	cases = null
	print(JSON.stringify(result))
	print("MOBILE_TEST_COMPLETE")
	quit(1 if result.failures else 0)
