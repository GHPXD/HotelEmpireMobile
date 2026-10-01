extends SceneTree

var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	var analytics := AnalyticsService.new()
	check(analytics.record(&"app_open", {"load_status": "new"}), "lifecycle event contract")
	analytics.flush()
	check(analytics.pending.size() == 1, "unconfigured analytics cannot block/lose gameplay")
	check(not analytics.record(&"app_open", {"email": "private@example.invalid"}), "PII field rejected")
	check(not analytics.record(&"unknown"), "unknown schema event rejected")
	for count in 200:
		analytics.record(&"resume")
	check(analytics.pending.size() == AnalyticsService.MAX_PENDING, "offline queue has memory bound")
	var mock := MockAnalyticsProvider.new()
	analytics.provider = mock
	mock.available = false
	analytics.flush()
	check(mock.received.is_empty() and analytics.pending.size() == AnalyticsService.MAX_PENDING, "provider offline is safe")
	mock.available = true
	analytics.flush(16)
	check(mock.received.size() == 16 and analytics.pending.size() == AnalyticsService.MAX_PENDING - 16, "bounded flush")
	analytics.flush(200)
	check(analytics.pending.is_empty() and mock.received.size() == AnalyticsService.MAX_PENDING, "no duplicate delivery while draining")
	analytics.flush()
	check(mock.received.size() == AnalyticsService.MAX_PENDING, "empty flush idempotent")
	var config := RemoteConfigService.new()
	check(not config.refresh() and config.values.ui_refresh_seconds == 0.2, "offline local defaults")
	var remote := MockRemoteConfigProvider.new()
	config.provider = remote
	remote.response = {"schema": 1, "revision": 1, "values": {"ui_refresh_seconds": 0.3}}
	check(config.refresh() and config.values.ui_refresh_seconds == 0.3, "mock configuration applies")
	check(not config.refresh(), "stale revision ignored")
	for invalid in [{"rewarded_offline_multiplier": 20.0}, {"offline_cap_seconds": 3600.5}, {"unknown": 1}, {"ui_refresh_seconds": -1}, {"offline_cap_seconds": true}]:
		remote.response = {"schema": 1, "revision": 2, "values": invalid}
		check(not config.refresh() and config.revision == 1 and config.values.ui_refresh_seconds == 0.3, "invalid configuration rejected atomically")
	print(JSON.stringify({"suite": "mobile_platform_adapters", "checks": checks, "failures": failures}))
	print("MOBILE_TEST_COMPLETE")
	quit(1 if failures else 0)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
