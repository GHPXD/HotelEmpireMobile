class_name MobileLocale
extends RefCounted
## Runtime translations use product keys; no provider or editor import required.

const PATH: String = "res://data/localization/mobile.json"
static var installed: bool = false

static func install(locale: String = "") -> void:
	if not installed:
		var catalogs: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		assert(catalogs is Dictionary, "Missing mobile localization catalogs")
		for language: String in catalogs:
			var translation := Translation.new()
			translation.locale = language
			for key: String in catalogs[language]:
				translation.add_message(key, catalogs[language][key])
			TranslationServer.add_translation(translation)
		installed = true
	var selected := locale if not locale.is_empty() else OS.get_locale()
	if selected.begins_with("pt"):
		selected = "pt_BR"
	elif selected.begins_with("es"):
		selected = "es"
	else:
		selected = "en"
	TranslationServer.set_locale(selected)

static func number(value: int) -> String:
	return TextServerManager.get_primary_interface().format_number(str(value), TranslationServer.get_locale())
