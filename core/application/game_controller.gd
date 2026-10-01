class_name GameController
extends RefCounted
## Single application owner of the active hotel; presentation sends commands.

signal session_changed
signal simulation_advanced
signal lifecycle_changed(background: bool)

var session: HotelSession
var saves: SaveService
var background: bool = false
var accumulator: float = 0.0
var boot_status: String = ""
var last_error: String = ""

func _init(save_service: SaveService = null) -> void:
	saves = save_service if save_service != null else SaveService.new()

func boot() -> String:
	var result := saves.boot()
	boot_status = result.status
	last_error = result.error
	if last_error.is_empty():
		session = result.session
		background = false
		accumulator = 0.0
		session_changed.emit()
	return last_error

func advance(delta: float) -> void:
	if session == null or background or delta <= 0.0 or not is_finite(delta):
		return
	# Preserve the fixed tick and cap catch-up after a delayed foreground frame.
	accumulator += minf(delta, 0.25) * session.speed
	var advanced := false
	while accumulator + SimulationRules.TIME_EPSILON >= session.rules.tick:
		session.tick(session.rules.tick)
		accumulator = maxf(0.0, accumulator - session.rules.tick)
		advanced = true
	saves.advance_autosave(delta, session)
	if advanced:
		simulation_advanced.emit()

func enter_background() -> String:
	if background or session == null:
		return last_error
	background = true
	accumulator = 0.0
	last_error = saves.checkpoint(session, &"background")
	lifecycle_changed.emit(true)
	return last_error

func resume() -> void:
	if not background or session == null:
		return
	background = false
	accumulator = 0.0
	# Aggregated offline settlement is added with timers in Sprint 5.
	lifecycle_changed.emit(false)

func checkpoint(reason: StringName = &"command") -> String:
	if session == null:
		return "save.error.invalid"
	last_error = saves.checkpoint(session, reason)
	return last_error

func build(definition: RoomDefinition, column: int, floor_index: int) -> Dictionary:
	if session == null:
		return {"room": null, "error": "error.command"}
	var error := session.hotel.build_error(definition, column, floor_index)
	if not error.is_empty():
		return {"room": null, "error": error}
	var room := session.hotel.build(definition, column, floor_index, session.time)
	return {"room": room, "error": checkpoint(&"construction")}

func add_floor() -> String:
	var error := session.hotel.add_floor(session.time)
	return checkpoint(&"floor") if error.is_empty() else error

func hire(definition: EmployeeDefinition) -> String:
	var error := session.hire(definition)
	return checkpoint(&"staff") if error.is_empty() else error

func upgrade(id: int) -> String:
	var error := session.upgrade_room(id)
	return checkpoint(&"upgrade") if error.is_empty() else error

func demolish(id: int) -> String:
	var error := session.demolish(id)
	return checkpoint(&"demolish") if error.is_empty() else error

func set_tariff(id: int, percent: int) -> String:
	var error := session.set_room_tariff(id, percent)
	return checkpoint(&"tariff") if error.is_empty() else error

func configure_employee(id: int, destination: int) -> String:
	var error := session.configure_employee(id, destination)
	return checkpoint(&"assignment") if error.is_empty() else error

func toggle_open() -> void:
	session.opened = not session.opened
	checkpoint(&"operation")

func toggle_pause() -> void:
	session.speed = 1 if session.speed == 0 else 0
	checkpoint(&"pause")
