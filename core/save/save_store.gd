class_name SaveStore
extends RefCounted

const DEFAULT_PATH: String = "user://hotel-v1.json"
const MAX_BYTES: int = AtomicJSONStore.MAX_BYTES

static func save_session(session: HotelSession, path: String = DEFAULT_PATH) -> String:
	var snapshot := SessionSnapshot.capture(session)
	var validated := SessionSnapshot.restore(snapshot)
	if not validated.error.is_empty():
		return "Não foi possível salvar: " + validated.error
	var error := AtomicJSONStore.write(snapshot, path, _valid_snapshot)
	if not error.is_empty():
		return error
	print("[SAVE] Gravado: ", path)
	return ""

static func load_session(path: String = DEFAULT_PATH) -> Dictionary:
	var loaded := AtomicJSONStore.read(path)
	if not loaded.error.is_empty():
		return {"session": null, "error": loaded.error}
	return SessionSnapshot.restore(loaded.data)

static func _valid_snapshot(data: Variant) -> bool:
	return SessionSnapshot.restore(data).error.is_empty()
