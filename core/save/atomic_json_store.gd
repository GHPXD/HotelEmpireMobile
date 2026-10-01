class_name AtomicJSONStore
extends RefCounted
## Shared storage protocol for domain and application snapshots.

const MAX_BYTES: int = 8 * 1024 * 1024

static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"data": null, "error": "save.error.missing"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"data": null, "error": "save.error.read"}
	if file.get_length() > MAX_BYTES:
		file.close()
		return {"data": null, "error": "save.error.size"}
	var parser := JSON.new()
	var error := parser.parse(file.get_as_text())
	file.close()
	if error != OK or not parser.data is Dictionary:
		return {"data": null, "error": "save.error.corrupt"}
	return {"data": parser.data, "error": ""}

static func write(data: Dictionary, path: String, validator: Callable) -> String:
	if not validator.call(data):
		return "save.error.invalid"
	var encoded := JSON.stringify(data, "", true, true)
	if encoded.to_utf8_buffer().size() > MAX_BYTES:
		return "save.error.size"
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return "save.error.write"
	file.store_string(encoded)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return "save.error.write"
	# A corrupt primary must never replace the last valid recovery copy.
	var full_path := ProjectSettings.globalize_path(path)
	var backup := full_path + ".bak"
	if FileAccess.file_exists(path):
		var previous := read(path)
		if previous.error.is_empty() and validator.call(previous.data):
			if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK:
				return "save.error.backup"
			if DirAccess.rename_absolute(full_path, backup) != OK:
				return "save.error.backup"
		elif DirAccess.remove_absolute(full_path) != OK:
			return "save.error.replace"
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), full_path) != OK:
		if FileAccess.file_exists(backup) and not FileAccess.file_exists(full_path):
			DirAccess.copy_absolute(backup, full_path)
		return "save.error.replace"
	return ""
