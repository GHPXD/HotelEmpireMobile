extends SceneTree
## Active deadlines, restart/absence and rollback without real-time sleeps.

var checks: int = 0
var failures: int = 0
var wall_ms: int = 1000000
var ticks_ms: int = 1000

func _initialize() -> void:
	call_deferred("run")

func make_clock() -> ProgressClock:
	var clock := ProgressClock.new()
	clock.wall_source = func() -> int: return wall_ms
	clock.monotonic_source = func() -> int: return ticks_ms
	return clock

func run() -> void:
	var clock := make_clock()
	var boot := clock.begin()
	check(boot.error.is_empty() and boot.elapsed_ms == 0 and clock.now_ms() == wall_ms, "new profile invents no absence")
	var deadline := clock.now_ms() + 10000
	ticks_ms += 375
	check(clock.now_ms() == 1000375 and deadline - clock.now_ms() == 9625, "deadline consumes monotonic milliseconds")
	wall_ms += 3600000
	check(clock.now_ms() == 1000375, "changing wall time cannot finish active construction")
	ticks_ms += 9625
	check(clock.now_ms() == deadline, "active deadline completes at elapsed duration")
	clock.suspend()
	var frozen := clock.now_ms()
	var persisted := clock.snapshot()
	wall_ms += 300000
	ticks_ms += 300000
	check(clock.now_ms() == frozen, "suspended time awaits explicit settlement")
	check(clock.snapshot() == persisted, "background checkpoint cannot consume absence before resume")
	var resumed := clock.resume()
	check(resumed.error.is_empty() and resumed.elapsed_ms == 300000 and clock.now_ms() == frozen + 300000, "resume settles absence once without double-counting monotonic ticks")
	check(clock.resume().elapsed_ms == 0 and clock.now_ms() == frozen + 300000, "duplicate resume cannot duplicate elapsed time")
	var restored := make_clock()
	boot = restored.begin(JSON.parse_string(JSON.stringify(persisted)))
	check(boot.elapsed_ms == 300000 and restored.now_ms() == clock.now_ms(), "restart and resume agree on persisted absence")
	var latest := restored.snapshot()
	var again := make_clock()
	check(again.begin(latest).elapsed_ms == 0 and again.now_ms() == restored.now_ms(), "checkpoint restart cannot settle the same interval twice")
	wall_ms -= 600000
	var rollback := make_clock()
	boot = rollback.begin(latest)
	check(boot.rollback and boot.elapsed_ms == 0 and rollback.now_ms() == int(latest.time_ms), "wall rollback neither rewinds deadlines nor grants absence")
	ticks_ms += 10000
	check(rollback.now_ms() == int(latest.time_ms) + 10000, "legitimate active play advances during wall rollback")
	var rollback_saved := rollback.snapshot()
	check(rollback_saved.wall_watermark_ms == latest.wall_watermark_ms, "rollback cannot lower the persisted wall watermark")
	wall_ms = int(latest.wall_watermark_ms)
	var caught_up := make_clock()
	check(caught_up.begin(rollback_saved).elapsed_ms == 0, "returning to prior wall time grants no second absence")
	wall_ms += 1000
	var next_boot := make_clock()
	check(next_boot.begin(rollback_saved).elapsed_ms == 1000, "only time beyond watermark grants new absence")
	wall_ms += ProgressClock.MAX_ABSENCE_MS * 2
	var long_absence := make_clock()
	boot = long_absence.begin(next_boot.snapshot())
	# An active checkpoint observes the current wall watermark without advancing
	# deadlines. The next interval begins from that checkpoint.
	check(boot.elapsed_ms == 0, "saved watermark is the observed checkpoint wall time")
	var anchor := long_absence.snapshot()
	wall_ms += ProgressClock.MAX_ABSENCE_MS * 2
	var capped := make_clock()
	boot = capped.begin(anchor)
	check(boot.capped and boot.elapsed_ms == ProgressClock.MAX_ABSENCE_MS, "extreme absence is bounded without replaying ticks")
	var capped_restart := make_clock()
	check(capped_restart.begin(capped.snapshot()).elapsed_ms == 0, "discarded excess cannot be claimed again at same wall time")
	var legacy := make_clock()
	check(legacy.begin({}, int(wall_ms / 1000.0) - 60).elapsed_ms == 60000, "legacy mobile timestamp seeds the migration clock")
	var before_invalid := legacy.snapshot()
	for invalid: Variant in [null, [], {}, {"version": 2, "time_ms": 0, "wall_watermark_ms": 0}, {"version": 1, "time_ms": -1, "wall_watermark_ms": 0}, {"version": 1, "time_ms": 0.5, "wall_watermark_ms": 0}, {"version": 1, "time_ms": "0", "wall_watermark_ms": 0}, {"version": 1, "time_ms": 0, "wall_watermark_ms": INF}, {"version": 1, "time_ms": 0, "wall_watermark_ms": NAN}, {"version": 1, "time_ms": 0, "wall_watermark_ms": ProgressClock.MAX_TIMESTAMP_MS + 1}, {"version": 1, "time_ms": 0, "wall_watermark_ms": 0, "extra": true}]:
		check(not ProgressClock.valid(invalid), "malformed clock state rejected")
	check(not legacy.begin({"version": 2}).error.is_empty() and legacy.snapshot() == before_invalid, "failed restore leaves live clock intact")
	check(not ProgressClock.valid({"version": true, "time_ms": 0, "wall_watermark_ms": 0}), "boolean cannot impersonate a schema version")
	check(ProgressClock.valid(JSON.parse_string(JSON.stringify(legacy.snapshot()))), "JSON integer conversion preserves clock schema")
	var baseline := legacy.now_ms()
	ticks_ms -= 1000
	check(legacy.now_ms() == baseline, "unexpected monotonic source rollback cannot rewind deadline")
	ticks_ms += 1500
	check(legacy.now_ms() == baseline + 500, "monotonic catch-up does not duplicate rollback interval")
	print(JSON.stringify({"suite": "progress_clock", "checks": checks, "failures": failures}))
	print("MOBILE_TEST_COMPLETE")
	quit(1 if failures else 0)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
