extends SceneTree
## Localization completeness, truthful projections and optional device feedback.

var failures: int = 0
var checks: int = 0
var calls: Array[Vector2] = []

func _initialize() -> void:
	MobileLocale.install("en")
	var catalogs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MobileLocale.PATH))
	var keys: Array = catalogs.en.keys()
	for locale: String in catalogs:
		check(catalogs[locale].size() == keys.size(), "locale key parity " + locale)
		for key: String in keys:
			check(catalogs[locale].has(key) and not catalogs[locale][key].is_empty(), "translation exists " + locale + " " + key)
	var session := HotelSession.new()
	var room := session.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
	for reason: String in ["empty", "missing_head", "head_travelling", "unstaffed", "processing", "ready", "cleaning", "occupied", "unaffordable", "no_accessible_bedroom"]:
		check(catalogs.en.has("checkin." + reason), "causal diagnosis localized " + reason)
	for locale in ["pt_BR", "en", "es"]:
		MobileLocale.install(locale)
		var before := SessionSnapshot.capture(session)
		check(not MobileLabels.checkin(session, room).begins_with("checkin."), "empty reception translates " + locale)
		check(SessionSnapshot.capture(session) == before, "projection does not mutate domain")
	var feedback := HapticService.new()
	feedback.preference_path = "user://haptic-test.cfg"
	feedback.backend = func(duration: int, amplitude: float) -> void: calls.append(Vector2(duration, amplitude))
	feedback.platform = "Windows"
	feedback.confirm()
	check(calls.is_empty(), "no vibration on unsupported host")
	feedback.platform = "Android"
	feedback.confirm()
	check(calls == [Vector2(18, 0.3)], "brief confirmation requested from device adapter")
	check(UIPreferences.save_value("locale", "es", feedback.preference_path) == OK, "locale saved")
	check(feedback.toggle() == OK and not feedback.enabled, "haptics toggle persists")
	feedback.confirm()
	check(calls.size() == 1, "disabled haptics never call adapter")
	var restored := HapticService.new()
	restored.preference_path = feedback.preference_path
	restored.load_preference()
	check(not restored.enabled and UIPreferences.load_locale(feedback.preference_path) == "es", "haptics and locale preferences survive together")
	check(UIPreferences.save_large_text(true, feedback.preference_path) == OK and UIPreferences.load_locale(feedback.preference_path) == "es", "changing text size preserves other preferences")
	print(JSON.stringify({"suite": "mobile_presentation", "checks": checks, "failures": failures, "translation_keys": keys.size()}))
	print("MOBILE_TEST_COMPLETE")
	quit(1 if failures else 0)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
