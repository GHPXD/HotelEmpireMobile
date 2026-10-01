extends RefCounted
## Injected clocks advance real application deadlines without wall-time sleeps.

var wall_ms: int = 1800000000000
var ticks_ms: int = 0

func clock() -> ProgressClock:
	var result := ProgressClock.new()
	result.wall_source = wall
	result.monotonic_source = ticks
	return result

func wall() -> int:
	return wall_ms

func ticks() -> int:
	return ticks_ms

func utc() -> int:
	return floori(wall_ms / 1000.0)

func advance(milliseconds: int) -> void:
	wall_ms += milliseconds
	ticks_ms += milliseconds
