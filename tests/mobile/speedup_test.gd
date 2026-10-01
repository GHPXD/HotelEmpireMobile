extends SceneTree
## Inventory receipts, durable speedup plans, storage faults and reentrant hooks.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var cases: RefCounted = load("res://tests/mobile/speedup_cases.gd").new()
	var result: Dictionary = cases.run()
	cases = null
	print(JSON.stringify(result))
	print("MOBILE_TEST_COMPLETE")
	quit(1 if result.failures else 0)
