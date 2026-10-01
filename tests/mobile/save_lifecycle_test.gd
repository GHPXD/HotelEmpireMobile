extends SceneTree

var failures: int = 0
var checks: int = 0
var now_utc: int = 1000000
var checkpoint_count: int = 0

func _initialize() -> void:
	var saves := SaveService.new()
	saves.path = "user://profile-test.json"
	saves.legacy_path = "user://legacy-test.json"
	saves.clock = func() -> int: return now_utc
	for filename in [saves.path, saves.path + ".bak", saves.legacy_path, saves.legacy_path + ".bak"]:
		if FileAccess.file_exists(filename):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(filename))
	var game := GameController.new(saves)
	check(game.boot().is_empty() and game.boot_status == "new", "fresh boot")
	check(game.session.hotel.build(HotelCatalog.room(&"reception"), 0, 0) != null, "domain command")
	saves.app_state = {"test_module": {"owned": ["original_theme"], "count": 2}}
	saves.checkpoint_completed.connect(func(_reason: StringName) -> void: checkpoint_count += 1)
	game.advance(0.25)
	check(game.session.tick_count == 2, "fixed simulation tick")
	game.session.speed = 0
	game.advance(30.0)
	check(checkpoint_count == 1 and FileAccess.file_exists(saves.path), "autosave while paused")
	var restored := saves.boot()
	check(restored.error.is_empty() and restored.session.hotel.rooms.size() == 1, "hotel roundtrip")
	check(saves.app_state.test_module.owned == ["original_theme"], "global envelope roundtrip")
	game.session.speed = 1
	now_utc += 60
	check(game.enter_background().is_empty(), "background checkpoint")
	var ticks := game.session.tick_count
	game.advance(100000.0)
	game.enter_background()
	check(game.session.tick_count == ticks and checkpoint_count == 2, "background stops processing and deduplicates hooks")
	game.resume()
	game.resume()
	game.advance(0.1)
	check(game.session.tick_count == ticks + 1, "resume no accumulated catch-up")
	var killed := GameController.new(saves)
	check(killed.boot().is_empty() and killed.session.tick_count == ticks, "OS kill recovery at last checkpoint")
	write_file(saves.path, "{truncated")
	var recovered := saves.boot()
	check(recovered.status == "recovered" and recovered.session != null, "automatic backup recovery")
	var valid_backup := FileAccess.get_file_as_string(saves.path + ".bak")
	check(saves.checkpoint(recovered.session).is_empty(), "checkpoint after corrupt primary")
	check(FileAccess.get_file_as_string(saves.path + ".bak") == valid_backup, "corrupt primary never replaces valid backup")
	# Simulate process death in the primary/backup rename gap.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saves.path))
	check(saves.boot().status == "recovered", "recover when only backup exists")
	check(saves.checkpoint(recovered.session).is_empty(), "restore primary from recovery")
	var malformed_version := AtomicJSONStore.read(saves.path).data as Dictionary
	malformed_version.version = "invalid"
	write_file(saves.path, JSON.stringify(malformed_version))
	check(saves.boot().status == "recovered", "corrupt version can recover from valid backup")
	check(saves.checkpoint(recovered.session).is_empty(), "restore after malformed version")
	var future := AtomicJSONStore.read(saves.path).data as Dictionary
	future.version = 999
	write_file(saves.path, JSON.stringify(future))
	check(saves.boot().error == "save.error.version", "unknown application version blocks downgrade")
	check(not saves.checkpoint(game.session).is_empty(), "autosave cannot overwrite future data")
	check(AtomicJSONStore.read(saves.path).data.version == 999, "future file preserved")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saves.path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saves.path + ".bak"))
	var legacy := HotelSession.new(17)
	legacy.hotel.build(HotelCatalog.room(&"bedroom"), 4, 0)
	check(SaveStore.save_session(legacy, saves.legacy_path).is_empty(), "legacy fixture")
	check(saves.boot().status == "legacy", "domain v7 imported automatically")
	check(saves.checkpoint(legacy).is_empty() and FileAccess.file_exists(saves.legacy_path), "migration preserves old file")
	for fixture in ["m2-save-v1", "m3-save-v2", "m4-save-v3"]:
		write_file(saves.legacy_path, FileAccess.get_file_as_string("res://tests/fixtures/" + fixture + ".json"))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(saves.path))
		check(saves.boot().status == "legacy", "legacy migration " + fixture)
		check(saves.checkpoint(saves.boot().session).is_empty(), "migrated checkpoint " + fixture)
	var invalid := future.duplicate(true)
	invalid.version = SaveService.VERSION
	invalid.saved_at_utc = -1
	check(not SaveService.restore(invalid).error.is_empty(), "negative timestamp rejected")
	invalid.saved_at_utc = 0
	invalid.app_state = {"bad": Vector2.ZERO}
	check(not SaveService.restore(invalid).error.is_empty(), "non-primitive global state rejected")
	write_file(saves.path, "broken")
	write_file(saves.path + ".bak", "broken")
	check(saves.boot().session == null and saves.write_blocked, "both corrupt copies cannot silently become new game")
	check(not saves.checkpoint(legacy).is_empty(), "corrupt data preserved from autosave")
	print(JSON.stringify({"suite": "mobile_save_lifecycle", "checks": checks, "failures": failures}))
	print("MOBILE_TEST_COMPLETE")
	quit(1 if failures else 0)

func write_file(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
