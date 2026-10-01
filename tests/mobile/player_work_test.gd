extends SceneTree
## Load regression cases at runtime so the SceneTree script does not pin their
## static dependency graph during engine teardown. Assertions stay in the cases.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var cases: RefCounted = load("res://tests/mobile/player_work_cases.gd").new()
	var result: Dictionary = cases.run()
	cases = null
	print(JSON.stringify(result))
	print("MOBILE_TEST_COMPLETE")
	quit(1 if result.failures else 0)
