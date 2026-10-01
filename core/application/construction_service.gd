class_name ConstructionService
extends RefCounted
## Application owns paid jobs. Model owns completed rooms. Advance visits job
## boundaries, so a long absence costs O(queue length), never simulation ticks.

const VERSION: int = 1
const RULES: ConstructionRules = preload("res://data/construction_rules.tres")
const JOB_FIELDS: Array[String] = ["id", "kind", "definition_id", "column", "floor_index", "room_id", "target_level", "cost", "duration_ms", "accepted_ms", "start_ms", "end_ms", "slot"]
var hotel: HotelModel
var jobs: Array[Dictionary] = []
var next_id: int = 1
var completed: int = 0
var cancelled: int = 0
var last_ms: int = 0
var _events: Array[Dictionary] = []

func _init(model: HotelModel) -> void:
	hotel = model

func build_error(definition: RoomDefinition, column: int, floor_index: int) -> String:
	var error := hotel.build_error(definition, column, floor_index)
	if not error.is_empty():
		return error
	if jobs.size() >= RULES.queue_limit:
		return "construction.error.queue_full"
	return "construction.error.reserved" if reserved(definition, column, floor_index) else ""

func reserved(definition: RoomDefinition, column: int, floor_index: int) -> bool:
	for job in jobs:
		if job.kind != "build":
			continue
		var other := HotelCatalog.room(StringName(job.definition_id))
		var same_floor: bool = definition.category == &"transport" or other.category == &"transport" or floor_index == int(job.floor_index)
		if same_floor and column < int(job.column) + other.width and int(job.column) < column + definition.width:
			return true
	return false

func enqueue_build(definition: RoomDefinition, column: int, floor_index: int, now_ms: int, game_time: float) -> Dictionary:
	if not _valid_now(now_ms):
		return {"job": null, "error": "save.error.invalid"}
	advance(now_ms, game_time)
	var error := build_error(definition, column, floor_index)
	if not error.is_empty():
		return {"job": null, "error": error}
	var duration := RULES.build_ms(definition, hotel.rooms, jobs)
	return _enqueue("build", String(definition.id), column, floor_index, -1, 1, definition.build_cost, duration, now_ms, game_time)

func enqueue_upgrade(room_id: int, now_ms: int, game_time: float) -> Dictionary:
	if not _valid_now(now_ms):
		return {"job": null, "error": "save.error.invalid"}
	advance(now_ms, game_time)
	var room := hotel.by_id(room_id)
	if room == null:
		return {"job": null, "error": "Selecione uma sala."}
	if job_for_room(room_id) != null:
		return {"job": null, "error": "construction.error.upgrading"}
	var next := room.next_upgrade()
	if next == null:
		return {"job": null, "error": "Nível máximo atingido."}
	var error := hotel.progression.upgrade_error(room)
	if not error.is_empty():
		return {"job": null, "error": error}
	return _enqueue("upgrade", String(room.definition_id), room.column, room.floor_index, room.id, room.level + 1, next.cost, RULES.upgrade_ms(room.level + 1), now_ms, game_time)

func enqueue_floor(now_ms: int, game_time: float) -> Dictionary:
	if not _valid_now(now_ms):
		return {"job": null, "error": "save.error.invalid"}
	advance(now_ms, game_time)
	var target := hotel.floors
	for job in jobs:
		if job.kind == "floor":
			target += 1
	if target >= HotelModel.MAX_FLOORS:
		return {"job": null, "error": "Limite de 40 andares atingido."}
	return _enqueue("floor", "", -1, target, -1, 0, HotelModel.FLOOR_COST, RULES.floor_ms(target), now_ms, game_time)

func _enqueue(kind: String, definition_id: String, column: int, floor_index: int, room_id: int, target_level: int, cost: int, duration_ms: int, now_ms: int, game_time: float) -> Dictionary:
	if jobs.size() >= RULES.queue_limit:
		return {"job": null, "error": "construction.error.queue_full"}
	if now_ms < last_ms or now_ms > ProgressClock.MAX_TIMESTAMP_MS - duration_ms:
		return {"job": null, "error": "save.error.invalid"}
	if not hotel.economy.purchase(cost, "ledger.construction." + kind, game_time):
		return {"job": null, "error": "Caixa insuficiente."}
	var job := {"id": next_id, "kind": kind, "definition_id": definition_id, "column": column, "floor_index": floor_index, "room_id": room_id, "target_level": target_level, "cost": cost, "duration_ms": duration_ms, "accepted_ms": now_ms, "start_ms": -1, "end_ms": -1, "slot": -1}
	next_id += 1
	jobs.append(job)
	last_ms = now_ms
	_start_pending(now_ms)
	return {"job": job.duplicate(), "error": ""}

func advance(now_ms: int, game_time: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not _valid_now(now_ms):
		return events
	_start_pending(last_ms)
	for _boundary in RULES.queue_limit:
		var candidate: Dictionary = {}
		for job in jobs:
			if int(job.slot) >= 0 and int(job.end_ms) <= now_ms and (candidate.is_empty() or int(job.end_ms) < int(candidate.end_ms) or (job.end_ms == candidate.end_ms and job.id < candidate.id)):
				candidate = job
		if candidate.is_empty():
			break
		var event := _complete(candidate)
		jobs.erase(candidate)
		if event.error.is_empty():
			completed += 1
		else:
			cancelled += 1
			hotel.economy.refund_capital(int(candidate.cost), "ledger.construction.refund_invalidated", game_time)
		events.append(event)
		_events.append(event)
		if _events.size() > RULES.queue_limit * 4:
			_events.pop_front()
		_start_pending(int(candidate.end_ms))
	last_ms = now_ms
	return events

func _start_pending(at_ms: int) -> void:
	for slot in RULES.slots:
		var occupied := false
		for job in jobs:
			occupied = occupied or int(job.slot) == slot
		if occupied:
			continue
		for job in jobs:
			if int(job.slot) >= 0 or (job.kind == "floor" and hotel.floors != int(job.floor_index)):
				continue
			job.slot = slot
			job.start_ms = maxi(at_ms, int(job.accepted_ms))
			job.end_ms = int(job.start_ms) + int(job.duration_ms)
			break

func _complete(job: Dictionary) -> Dictionary:
	var room_id := int(job.room_id)
	var error := ""
	match job.kind:
		"build":
			var room := hotel.finish_build(HotelCatalog.room(StringName(job.definition_id)), int(job.column), int(job.floor_index))
			if room != null:
				room_id = room.id
			else:
				error = "construction.error.invalidated"
		"upgrade":
			var room := hotel.by_id(room_id)
			if room != null and room.level + 1 == int(job.target_level) and room.definition_id == StringName(job.definition_id):
				room.level += 1
				hotel.changed.emit()
			else:
				error = "construction.error.invalidated"
		"floor":
			if hotel.floors == int(job.floor_index):
				hotel.floors += 1
				hotel.changed.emit()
			else:
				error = "construction.error.invalidated"
		_:
			error = "construction.error.invalidated"
	return {"id": job.id, "kind": job.kind, "room_id": room_id, "error": error}

func cancel(job_id: int, now_ms: int, game_time: float) -> String:
	if not _valid_now(now_ms):
		return "save.error.invalid"
	advance(now_ms, game_time)
	var job: Variant = by_id(job_id)
	if job == null:
		return "construction.error.missing"
	if job.kind == "floor":
		for other in jobs:
			if other.kind == "floor" and int(other.floor_index) > int(job.floor_index):
				return "construction.error.dependent"
	if not hotel.economy.refund_capital(int(job.cost), "ledger.construction.refund", game_time):
		return "save.error.invalid"
	jobs.erase(job)
	cancelled += 1
	last_ms = maxi(last_ms, now_ms)
	_start_pending(last_ms)
	return ""

func by_id(job_id: int) -> Variant:
	for job in jobs:
		if int(job.id) == job_id:
			return job
	return null

func job_for_room(room_id: int) -> Variant:
	for job in jobs:
		if job.kind == "upgrade" and int(job.room_id) == room_id:
			return job
	return null

func snapshot() -> Dictionary:
	return {"version": VERSION, "next_id": next_id, "completed": completed, "cancelled": cancelled, "last_ms": last_ms, "jobs": jobs.duplicate(true)}

func restore(data: Variant, now_ms: int) -> bool:
	if not data is Dictionary or data.size() != 6 or not _integer(data.get("version"), VERSION, VERSION):
		return false
	if not _integer(data.get("next_id"), 1, 2147483647) or not _integer(data.get("completed"), 0, 2147483646) or not _integer(data.get("cancelled"), 0, 2147483646):
		return false
	if not _integer(data.get("last_ms"), 0, now_ms) or now_ms > ProgressClock.MAX_TIMESTAMP_MS or not data.get("jobs") is Array or data.jobs.size() > RULES.queue_limit:
		return false
	if data.completed + data.cancelled + data.jobs.size() != data.next_id - 1:
		return false
	var restored: Array[Dictionary] = []
	var used_slots: Array[int] = []
	var upgrade_rooms: Array[int] = []
	var floor_targets: Array[int] = []
	var total_cost := 0
	var previous_id := 0
	for value: Variant in data.jobs:
		if not value is Dictionary or value.size() != JOB_FIELDS.size():
			return false
		for field in JOB_FIELDS:
			if not value.has(field):
				return false
		if not value.kind is String or value.kind not in ["build", "upgrade", "floor"] or not value.definition_id is String:
			return false
		if not _integer(value.id, previous_id + 1, int(data.next_id) - 1) or not _integer(value.cost, 0, 1000000000) or not _integer(value.duration_ms, 1000, RULES.maximum_seconds * 1000):
			return false
		if not _integer(value.accepted_ms, 0, int(data.last_ms)) or not _integer(value.slot, -1, RULES.slots - 1):
			return false
		if int(value.slot) == -1:
			if value.start_ms != -1 or value.end_ms != -1:
				return false
		else:
			if int(value.slot) in used_slots or not _integer(value.start_ms, int(value.accepted_ms), int(data.last_ms)) or not _integer(value.end_ms, int(data.last_ms) + 1, ProgressClock.MAX_TIMESTAMP_MS):
				return false
			if value.end_ms != value.start_ms + value.duration_ms:
				return false
			used_slots.append(int(value.slot))
		if not _integer(value.floor_index, 0, HotelModel.MAX_FLOORS - 1) or not _integer(value.column, -1, HotelModel.COLUMNS - 1) or not _integer(value.room_id, -1, hotel.next_room_id - 1) or not _integer(value.target_level, 0, 5):
			return false
		if value.kind == "floor":
			if value.definition_id != "" or value.column != -1 or value.room_id != -1 or value.target_level != 0 or value.cost != HotelModel.FLOOR_COST or int(value.floor_index) in floor_targets:
				return false
			if int(value.floor_index) < hotel.floors or (int(value.slot) >= 0 and int(value.floor_index) != hotel.floors):
				return false
			floor_targets.append(int(value.floor_index))
		else:
			var definition := HotelCatalog.room(StringName(value.definition_id))
			if definition == null or value.column < 0:
				return false
			if value.kind == "build":
				if value.room_id != -1 or value.target_level != 1 or not hotel.placement_error(definition, int(value.column), int(value.floor_index)).is_empty():
					return false
				for other in restored:
					if other.kind != "build":
						continue
					var other_definition := HotelCatalog.room(StringName(other.definition_id))
					var same_floor: bool = definition.category == &"transport" or other_definition.category == &"transport" or value.floor_index == other.floor_index
					if same_floor and value.column < other.column + other_definition.width and other.column < value.column + definition.width:
						return false
			else:
				var room := hotel.by_id(int(value.room_id))
				if room == null or room.id in upgrade_rooms or room.definition_id != definition.id or room.column != int(value.column) or room.floor_index != int(value.floor_index) or room.level + 1 != int(value.target_level) or room.next_upgrade() == null:
					return false
				upgrade_rooms.append(room.id)
		total_cost += int(value.cost)
		previous_id = int(value.id)
		restored.append(value.duplicate(true))
	floor_targets.sort()
	for index in floor_targets.size():
		if floor_targets[index] != hotel.floors + index:
			return false
	if total_cost > hotel.economy.capital_spent:
		return false
	if used_slots.size() < RULES.slots:
		for job in restored:
			if int(job.slot) == -1 and (job.kind != "floor" or int(job.floor_index) == hotel.floors):
				return false
	jobs = restored
	next_id = int(data.next_id)
	completed = int(data.completed)
	cancelled = int(data.cancelled)
	last_ms = int(data.last_ms)
	_events.clear()
	return true

func take_events() -> Array[Dictionary]:
	var result := _events.duplicate(true)
	_events.clear()
	return result

func _valid_now(now_ms: int) -> bool:
	return now_ms >= last_ms and now_ms <= ProgressClock.MAX_TIMESTAMP_MS

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= minimum and value <= maximum
