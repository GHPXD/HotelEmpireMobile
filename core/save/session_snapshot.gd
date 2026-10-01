class_name SessionSnapshot
extends RefCounted
## Schema v9 adds bounded staff progression, delegation and cleaning quality.

const VERSION: int = 9
const WAIT_FIELDS: Array[String] = ActorState.WAIT_FIELDS
const ROOM_FIELDS: Array[String] = ["id", "definition_id", "column", "floor_index", "occupant", "dirty", "dirty_since", "cleaning_quality_bonus", "cleaning_by", "repairing_by", "condition", "income", "level", "price_percent"]
const ACTOR_FIELDS: Array[String] = ["id", "role", "display_name", "state", "x", "floor_index", "target_x", "target_floor", "target_room", "destination_state", "elevator_id", "timer", "age", "waiting", "happiness", "money", "bedroom", "checked_in", "meals", "sleeps", "speed", "skill", "assignment", "workload", "agreed_price", "preferred_room", "preferred_floor", "archetype_id", "service_uses", "reception_seconds", "lift_queue_seconds", "service_queue_seconds"]
const LIFT_FIELDS: Array[String] = ["room_id", "column", "capacity", "floor_position", "target_floor", "door_timer", "boarded", "delivered", "wait_total", "wait_max", "busy_seconds"]
const SESSION_FIELDS: Array[String] = ["next_actor_id", "time", "tick_count", "arrival_timer", "day", "opened", "speed"]
const ECONOMY_FIELDS: Array[String] = ["cash", "revenue", "expenses", "capital_spent"]
const GUEST_FIELDS: Array[String] = ["completed", "meals_served", "bookings", "score_total", "reputation", "service_uses"]
const STATES: Array[StringName] = [&"arriving", &"walking", &"lift_queue", &"riding", &"checkin", &"deciding", &"service_queue", &"using", &"exit", &"idle", &"working", &"cleaning", &"employee_exit", &"room_service_wait", &"manual_checkin", &"manual_cleaning", &"manual_repair", &"manual_prepare", &"manual_deliver"]

static func capture(session: HotelSession) -> Dictionary:
	var rooms: Array[Dictionary] = []
	for room in session.hotel.rooms:
		var item := _read(room, ROOM_FIELDS)
		item["users"] = room.users.duplicate()
		item["queue"] = room.queue.members.duplicate()
		rooms.append(item)
	var actors: Array[Dictionary] = []
	for actor: ActorState in session.actors.values():
		var item := _read(actor, ACTOR_FIELDS)
		item["needs"] = actor.needs.duplicate(true)
		item["utility_scores"] = actor.utility_scores.duplicate(true)
		item["employee"] = actor.ensure_employee().snapshot() if actor.is_employee() else null
		actors.append(item)
	var lifts: Array[Dictionary] = []
	for lift in session.transport.lifts:
		var item := _read(lift, LIFT_FIELDS)
		item["queue"] = lift.queue.members.duplicate()
		item["passengers"] = lift.passengers.duplicate()
		lifts.append(item)
	return {"version": VERSION, "dismissed": session.employees.dismissed, "player_work": PlayerWorkSnapshot.capture(session.player_work), "reviews": session.guests.reviews.duplicate(true), "progression": session.progression.snapshot(), "session": _read(session, SESSION_FIELDS), "economy": _read(session.economy, ECONOMY_FIELDS), "ledger": session.economy.ledger.duplicate(true), "floors": session.hotel.floors, "next_room_id": session.hotel.next_room_id, "rooms": rooms, "actors": actors, "lifts": lifts, "guests": _read(session.guests, GUEST_FIELDS), "cleaned": session.employees.cleaned, "path_requests": session.transport.path_requests, "rng_seed": str(session.rng.seed), "rng_state": str(session.rng.state)}

static func restore(data: Variant) -> Dictionary:
	if data is Dictionary and data.get("version") == 1:
		data = _migrate_v1(data)
	var legacy: bool = data is Dictionary and data.get("version") == 2
	if legacy:
		data = data.duplicate(true)
		data.version = 3
		data["progression"] = {"completed": [], "legacy_access": true}
	if data is Dictionary and data.get("version") == 3:
		data = _migrate_v3(data)
	if data is Dictionary and data.get("version") == 4:
		data = data.duplicate(true)
		if not data.get("rooms") is Array:
			return _error("Salas inválidas.")
		for room_data: Variant in data.rooms:
			if not room_data is Dictionary:
				return _error("Sala inválida.")
			room_data["price_percent"] = 100
		data.version = 5
	if data is Dictionary and data.get("version") == 5:
		data = data.duplicate(true)
		data["reviews"] = []
		data.version = 6
	if data is Dictionary and data.get("version") == 6:
		data = data.duplicate(true)
		if not data.get("actors") is Array or not data.get("reviews") is Array:
			return _error("Histórico de espera inválido.")
		for actor_data: Variant in data.actors:
			if not actor_data is Dictionary:
				return _error("Agente inválido.")
			for field: String in WAIT_FIELDS:
				actor_data[field] = -1.0
		for review_data: Variant in data.reviews:
			if not review_data is Dictionary or review_data.size() != 8:
				return _error("Avaliação antiga inválida.")
			for field: String in WAIT_FIELDS:
				review_data[field] = null
		data.version = 7
	if data is Dictionary and data.get("version") == 7:
		data = data.duplicate(true)
		if not data.get("rooms") is Array:
			return _error("Salas inválidas.")
		for room_data: Variant in data.rooms:
			if not room_data is Dictionary:
				return _error("Sala inválida.")
			room_data["condition"] = 100
			room_data["repairing_by"] = -1
		data["player_work"] = PlayerWorkSnapshot.capture(PlayerWorkSystem.new())
		data.version = 8
	if data is Dictionary and data.get("version") == 8:
		data = data.duplicate(true)
		if not data.get("rooms") is Array or not data.get("actors") is Array:
			return _error("Equipe ou salas inválidas.")
		for room_data: Variant in data.rooms:
			if not room_data is Dictionary:
				return _error("Sala inválida.")
			room_data["dirty_since"] = -1.0
			room_data["cleaning_quality_bonus"] = 0
		for actor_data: Variant in data.actors:
			if not actor_data is Dictionary:
				return _error("Agente inválido.")
			actor_data["employee"] = EmployeeProgress.new().snapshot() if actor_data.get("role") in ["receptionist", "cleaner"] else null
		data["dismissed"] = 0
		data.version = VERSION
	if not data is Dictionary or data.get("version") != VERSION:
		return _error("Versão de save desconhecida ou formato inválido.")
	var session := HotelSession.new()
	if not session.progression.restore(data.get("progression")):
		return _error("Progressão inválida.")
	if not _write(session, data.get("session"), SESSION_FIELDS) or not _write(session.economy, data.get("economy"), ECONOMY_FIELDS) or not _write(session.guests, data.get("guests"), GUEST_FIELDS):
		return _error("Estado de sessão/economia inválido.")
	if not _integer(data.get("floors"), 1, HotelModel.MAX_FLOORS) or not _integer(data.get("next_room_id"), 1, 10000000) or not _integer(data.get("cleaned"), 0, 100000000) or not _integer(data.get("path_requests"), 0, 100000000):
		return _error("Contadores inválidos.")
	if session.time < 0 or session.tick_count < 0 or not is_equal_approx(session.time, session.tick_count * session.rules.tick) or session.day != floori(session.time / session.rules.day_seconds) or session.speed < 0 or session.speed > 3 or session.next_actor_id < 1:
		return _error("Relógio ou IDs inválidos.")
	session.time = session.tick_count * session.rules.tick
	if session.guests.reputation < 0 or session.guests.reputation > 100:
		return _error("Reputação inválida.")
	if session.guests.service_uses < session.guests.meals_served or session.guests.service_uses < 0:
		return _error("Contagem de serviços inválida.")
	for key in ["rooms", "actors", "lifts", "ledger"]:
		if not data.get(key) is Array:
			return _error("Lista ausente: " + key)
	if data.rooms.size() > HotelModel.MAX_FLOORS * HotelModel.COLUMNS or data.actors.size() > 5000 or data.lifts.size() > HotelModel.COLUMNS or data.ledger.size() > HotelEconomy.LEDGER_LIMIT:
		return _error("Save excede limites suportados.")
	session.hotel.floors = int(data.floors)
	if not _integer(data.get("dismissed"), 0, session.next_actor_id - 1):
		return _error("Desligamentos inválidos.")
	session.employees.dismissed = int(data.dismissed)
	session.hotel.next_room_id = int(data.next_room_id)
	session.employees.cleaned = int(data.cleaned)
	session.transport.path_requests = int(data.path_requests)
	for item: Variant in data.rooms:
		var room := RoomState.new()
		if not _write(room, item, ROOM_FIELDS) or room.definition() == null or room.id < 1 or room.id >= session.hotel.next_room_id or session.hotel.by_id(room.id) != null:
			return _error("Sala desconhecida ou ID inválido.")
		if room.level < 1 or room.level > room.definition().upgrades.size() + 1:
			return _error("Nível de sala inválido.")
		if room.condition < 0 or room.condition > 100 or room.repairing_by < -1 or room.repairing_by == 0 or room.cleaning_by < -1 or room.cleaning_by == 0:
			return _error("Condição ou reserva de sala inválida.")
		if room.dirty_since < -1 or room.dirty_since > session.time or (not room.dirty and room.dirty_since != -1) or room.cleaning_quality_bonus < 0 or room.cleaning_quality_bonus > EmployeeProgress.RULES.thresholds.size() - 1 + EmployeeProgress.RULES.quality_bonus:
			return _error("Histórico ou qualidade de limpeza inválidos.")
		if (room.dirty or room.occupant >= 0 or room.definition().category != &"lodging") and room.cleaning_quality_bonus != 0:
			return _error("Qualidade de limpeza fora de um quarto disponível.")
		if room.price_percent not in [75, 100, 125] or (room.definition().category not in [&"lodging", &"service"] and room.price_percent != 100):
			return _error("Tarifa de sala inválida.")
		var previous_cash: int = session.economy.cash
		session.economy.cash = 100000000
		var geometry_error := session.hotel.build_error(room.definition(), room.column, room.floor_index)
		session.economy.cash = previous_cash
		if not geometry_error.is_empty() or (room.definition().category == &"transport" and room.floor_index != 0):
			return _error("Geometria inválida: " + geometry_error)
		room.queue.capacity = room.definition().queue_capacity
		if not _ids(item.get("queue"), room.queue.members, room.queue.capacity) or not _ids(item.get("users"), room.users, room.capacity()):
			return _error("Ocupação inválida.")
		session.hotel.rooms.append(room)
	var reserved_posts: Dictionary = {}
	for item: Variant in data.actors:
		var actor := ActorState.new()
		if not _write(actor, item, ACTOR_FIELDS) or actor.id < 1 or actor.id >= session.next_actor_id or session.actors.has(actor.id):
			return _error("Agente inválido ou duplicado.")
		if actor.role not in [&"guest", &"receptionist", &"cleaner", &"player"] or actor.state not in STATES or actor.destination_state not in STATES:
			return _error("Papel ou estado de agente desconhecido.")
		if not item.has("employee"):
			return _error("Evolução da equipe ausente.")
		if actor.is_employee():
			actor.employee = EmployeeProgress.restore(item.employee, actor.role)
			if actor.employee == null:
				return _error("Evolução da equipe inválida.")
			if actor.employee.dismiss_requested and (actor.assignment != -1 or actor.preferred_room != -1 or actor.preferred_floor != -1 or actor.target_room != -1):
				return _error("Funcionário saindo ainda possui atribuição.")
		elif item.employee != null:
			return _error("Evolução atribuída a quem não é funcionário.")
		if (actor.state == &"employee_exit" or actor.destination_state == &"employee_exit") and (not actor.is_employee() or not actor.employee.dismiss_requested):
			return _error("Saída de funcionário inválida.")
		if actor.archetype() == null or actor.service_uses < actor.meals or actor.service_uses < 0:
			return _error("Perfil ou contagem de serviços inválida.")
		for field: String in WAIT_FIELDS:
			var seconds: float = actor.get(field)
			if seconds != -1.0 and (seconds < 0 or seconds > 100000000):
				return _error("Tempo de espera inválido.")
		if actor.agreed_price < 0 or actor.preferred_floor < -1 or actor.preferred_floor >= session.hotel.floors or actor.preferred_room < -1:
			return _error("Preço ou atribuição inválida.")
		if actor.preferred_room >= 0:
			var preferred := session.hotel.by_id(actor.preferred_room)
			if actor.role != &"receptionist" or preferred == null or preferred.definition().category != &"reception":
				return _error("Posto de recepção inválido.")
			if reserved_posts.has(actor.preferred_room):
				return _error("Dois recepcionistas fixos no mesmo posto.")
			reserved_posts[actor.preferred_room] = actor.id
		if actor.preferred_floor >= 0 and actor.role != &"cleaner":
			return _error("Andar de limpeza inválido.")
		if actor.floor_index < 0 or actor.floor_index >= session.hotel.floors or actor.target_floor < 0 or actor.target_floor >= session.hotel.floors or actor.x < -2 or actor.x > HotelModel.COLUMNS or actor.target_x < -2 or actor.target_x > HotelModel.COLUMNS or actor.speed <= 0 or actor.speed > 10 or actor.skill <= 0 or actor.skill > 10 or actor.money < 0 or actor.happiness < 0 or actor.happiness > 100 or actor.age < 0 or actor.waiting < 0:
			return _error("Atributos de agente fora dos limites.")
		if not item.get("needs") is Dictionary or not item.get("utility_scores") is Dictionary:
			return _error("Necessidades inválidas.")
		for need in actor.needs:
			if not _number(item.needs.get(need)) or float(item.needs[need]) < 0 or float(item.needs[need]) > 100:
				return _error("Necessidade fora dos limites.")
			actor.needs[need] = float(item.needs[need])
		for key: Variant in item.utility_scores:
			if not key is String or not _number(item.utility_scores[key]):
				return _error("Utilidade inválida.")
		actor.utility_scores = item.utility_scores.duplicate(true)
		session.actors[actor.id] = actor
	session.transport.sync(session.hotel)
	if session.transport.lifts.size() != data.lifts.size():
		return _error("Elevadores inconsistentes.")
	var lift_ids: Array[int] = []
	for item: Variant in data.lifts:
		var lift := ElevatorState.new()
		if not _write(lift, item, LIFT_FIELDS) or lift_ids.has(lift.room_id):
			return _error("Elevador inválido ou duplicado.")
		var room := session.hotel.by_id(lift.room_id)
		if room == null or room.definition().category != &"transport" or lift.column != room.center() or lift.capacity != room.capacity() or lift.floor_position < 0 or lift.floor_position > session.hotel.floors - 1 or lift.target_floor < 0 or lift.target_floor >= session.hotel.floors or lift.door_timer < 0:
			return _error("Geometria do elevador inválida.")
		lift.speed_multiplier = room.speed_multiplier()
		if not _ids(item.get("queue"), lift.queue.members, 2000) or not _ids(item.get("passengers"), lift.passengers, lift.capacity):
			return _error("Fila do elevador inválida.")
		lift_ids.append(lift.room_id)
		var index: int = session.transport.lifts.find(session.transport.lift_by_id(lift.room_id))
		session.transport.lifts[index] = lift
	if not PlayerWorkSnapshot.restore(session, data.get("player_work")):
		return _error("Trabalho manual inválido.")
	var relation_error := _validate_relations(session)
	if not relation_error.is_empty():
		return _error(relation_error)
	if not _restore_reviews(session, data.get("reviews")):
		return _error("Histórico de avaliações inválido.")
	for item: Variant in data.ledger:
		if not item is Dictionary or not _integer(item.get("amount"), -1000000000, 1000000000) or not item.get("reason") is String or not _number(item.get("time")):
			return _error("Extrato inválido.")
		session.economy.ledger.append({"amount": int(item.amount), "reason": item.reason, "time": float(item.time)})
	for key in ["rng_seed", "rng_state"]:
		if not data.get(key) is String or not data[key].is_valid_int() or str(int(data[key])) != data[key]:
			return _error("Estado aleatório inválido.")
	session.rng.seed = int(data.rng_seed)
	session.rng.state = int(data.rng_state)
	if legacy:
		session.progression.evaluate(session.progression_metrics())
	for room in session.hotel.rooms:
		if room.level == 3:
			# Check the entitlement to the installed level, without mutating the room.
			var previous := RoomState.new()
			previous.definition_id = room.definition_id
			previous.level = 2
			if not session.progression.upgrade_error(previous).is_empty():
				return _error("Nível de sala sem desbloqueio.")
	return {"session": session, "error": ""}

static func _restore_reviews(session: HotelSession, entries: Variant) -> bool:
	if not entries is Array or entries.size() > GuestSystem.REVIEW_LIMIT or entries.size() > session.guests.completed:
		return false
	var seen: Dictionary = {}
	var previous_time: float = -1
	for entry: Variant in entries:
		if not entry is Dictionary or entry.size() != 11:
			return false
		if not _integer(entry.get("guest_id"), 1, session.next_actor_id - 1) or seen.has(int(entry.guest_id)) or session.actors.has(int(entry.guest_id)):
			return false
		if not entry.get("profile") is String or HotelCatalog.guest(StringName(entry.profile)) == null or not entry.get("checked_in") is bool:
			return false
		if not _number(entry.get("time")) or entry.time < 0 or entry.time < previous_time or entry.time > session.time + SimulationRules.TIME_EPSILON:
			return false
		if not _number(entry.get("score")) or entry.score < 0 or entry.score > 100:
			return false
		for key: String in ["meals", "services", "sleeps"]:
			if not _integer(entry.get(key), 0, 100000000):
				return false
		if entry.services < entry.meals:
			return false
		for field: String in WAIT_FIELDS:
			if not entry.has(field) or (entry[field] != null and (not _number(entry[field]) or entry[field] < 0 or entry[field] > 100000000)):
				return false
		seen[int(entry.guest_id)] = true
		previous_time = float(entry.time)
		session.guests.reviews.append({"guest_id": int(entry.guest_id), "profile": entry.profile, "time": float(entry.time), "score": float(entry.score), "checked_in": entry.checked_in, "meals": int(entry.meals), "services": int(entry.services), "sleeps": int(entry.sleeps)})
		for field: String in WAIT_FIELDS:
			session.guests.reviews.back()[field] = float(entry[field]) if entry[field] != null else null
	return true

static func _validate_relations(session: HotelSession) -> String:
	for room in session.hotel.rooms:
		for id in room.queue.members + room.users:
			var actor: ActorState = session.actors.get(id)
			if actor == null or actor.target_room != room.id:
				return "Referência de fila/sala inválida."
		if room.occupant >= 0:
			var actor: ActorState = session.actors.get(room.occupant)
			if actor == null or actor.bedroom != room.id or room.definition().category != &"lodging":
				return "Reserva de quarto inválida."
		if room.cleaning_by >= 0:
			var actor: ActorState = session.actors.get(room.cleaning_by)
			if actor == null or actor.role not in [&"cleaner", &"player"] or actor.assignment != room.id:
				return "Atribuição de limpeza inválida."
	for actor: ActorState in session.actors.values():
		if actor.target_room >= 0 and session.hotel.by_id(actor.target_room) == null:
			return "Destino inexistente."
		if actor.bedroom >= 0 and session.hotel.by_id(actor.bedroom) == null:
			return "Quarto inexistente."
		if actor.state in [&"riding", &"lift_queue"]:
			var lift := session.transport.lift_by_id(actor.elevator_id)
			if lift == null or (actor.state == &"riding" and not lift.passengers.has(actor.id)) or (actor.state == &"lift_queue" and not lift.queue.members.has(actor.id)):
				return "Passageiro sem transporte."
		if actor.state == &"using":
			var room := session.hotel.by_id(actor.target_room)
			if room == null or not room.users.has(actor.id):
				return "Uso de serviço inconsistente."
			if actor.agreed_price > actor.money:
				return "Orçamento não cobre o preço contratado."
	for lift in session.transport.lifts:
		for id in lift.queue.members + lift.passengers:
			var actor: ActorState = session.actors.get(id)
			var expected: StringName = &"riding" if lift.passengers.has(id) else &"lift_queue"
			if actor == null or actor.elevator_id != lift.room_id or actor.state != expected or (lift.queue.members.has(id) and lift.passengers.has(id)):
				return "Referência de passageiro inválida."
	return ""

static func _read(object: Object, fields: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	for field in fields:
		var value: Variant = object.get(field)
		result[field] = String(value) if value is StringName else value
	return result

static func _write(object: Object, data: Variant, fields: Array[String]) -> bool:
	if not data is Dictionary:
		return false
	for field in fields:
		if not data.has(field):
			return false
		var value: Variant = data[field]
		match typeof(object.get(field)):
			TYPE_INT:
				if not _integer(value, -1000000000000, 1000000000000):
					return false
				object.set(field, int(value))
			TYPE_FLOAT:
				if not _number(value):
					return false
				object.set(field, float(value))
			TYPE_BOOL:
				if not value is bool:
					return false
				object.set(field, value)
			TYPE_STRING, TYPE_STRING_NAME:
				if not value is String or value.length() > 512:
					return false
				object.set(field, value)
			_:
				return false
	return true

static func _ids(data: Variant, target: Array[int], limit: int) -> bool:
	if not data is Array or data.size() > limit:
		return false
	for value: Variant in data:
		if not _integer(value, 1, 1000000000) or target.has(int(value)):
			return false
		target.append(int(value))
	return true

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return _number(value) and float(value) == floorf(float(value)) and float(value) >= minimum and float(value) <= maximum

static func _error(message: String) -> Dictionary:
	return {"session": null, "error": message}

static func _migrate_v1(original: Dictionary) -> Dictionary:
	var data := original.duplicate(true)
	if not data.get("rooms") is Array or not data.get("actors") is Array:
		return {}
	var definitions: Dictionary = {}
	for room: Variant in data.rooms:
		if not room is Dictionary:
			return {}
		room["level"] = 1
		if room.get("definition_id") is String:
			definitions[room.get("id")] = HotelCatalog.room(room.definition_id)
	for actor: Variant in data.actors:
		if not actor is Dictionary:
			return {}
		actor["preferred_room"] = -1
		actor["preferred_floor"] = -1
		actor["agreed_price"] = 0
		var definition: RoomDefinition = definitions.get(actor.get("target_room"))
		if actor.get("state") == "using" and definition != null and definition.category == &"service":
			actor["agreed_price"] = definition.price
	data.version = 2
	return data

static func _migrate_v3(original: Dictionary) -> Dictionary:
	var data := original.duplicate(true)
	if not data.get("actors") is Array or not data.get("guests") is Dictionary:
		return {}
	for actor: Variant in data.actors:
		if not actor is Dictionary:
			return {}
		actor["archetype_id"] = "balanced"
		actor["service_uses"] = actor.get("meals")
	data.guests["service_uses"] = data.guests.get("meals_served")
	data.version = 4
	return data
