class_name HapticService
extends RefCounted
## Brief optional feedback at successful construction/upgrade boundaries.

var enabled: bool = true
var platform: String = OS.get_name()
var backend: Callable = Input.vibrate_handheld
var preference_path: String = UIPreferences.PATH

func load_preference() -> void:
	var config := ConfigFile.new()
	if config.load(preference_path) == OK:
		var value: Variant = config.get_value("interface", "haptics", true)
		enabled = value if value is bool else true

func toggle() -> Error:
	var error := UIPreferences.save_value("haptics", not enabled, preference_path)
	if error == OK:
		enabled = not enabled
	return error

func confirm() -> void:
	if enabled and platform in ["Android", "iOS"] and backend.is_valid():
		backend.call(18, 0.3)
