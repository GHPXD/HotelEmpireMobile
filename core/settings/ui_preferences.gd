class_name UIPreferences
extends RefCounted
## Device preference, deliberately separate from hotel snapshots.

const PATH: String = "user://interface.cfg"

static func load_large_text(path: String = PATH) -> bool:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return false
	var value: Variant = config.get_value("interface", "large_text", false)
	return value if value is bool else false

static func save_large_text(value: bool, path: String = PATH) -> Error:
	return save_value("large_text", value, path)

static func load_locale(path: String = PATH) -> String:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return ""
	var value: Variant = config.get_value("interface", "locale", "")
	return value if value is String and value in ["pt_BR", "en", "es"] else ""

static func save_value(key: String, value: Variant, path: String = PATH) -> Error:
	var config := ConfigFile.new()
	config.load(path)
	config.set_value("interface", key, value)
	return config.save(path)
