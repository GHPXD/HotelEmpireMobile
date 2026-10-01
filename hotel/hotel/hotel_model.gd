class_name HotelModel
extends RefCounted

signal changed

const COLUMNS: int = 16
const MAX_FLOORS: int = 40
const FLOOR_COST: int = 750
var floors: int = 1
var next_room_id: int = 1
var rooms: Array[RoomState] = []
var economy: HotelEconomy
var progression: HotelProgression

func _init(wallet: HotelEconomy, progress: HotelProgression = null) -> void:
	economy = wallet
	progression = progress if progress != null else HotelProgression.new()

func room_at(column: int, floor_index: int) -> RoomState:
	if floor_index < 0 or floor_index >= floors or column < 0 or column >= COLUMNS:
		return null
	for room in rooms:
		var definition := room.definition()
		var same_floor: bool = room.floor_index == floor_index or definition.category == &"transport"
		if same_floor and column >= room.column and column < room.column + definition.width:
			return room
	return null

func by_id(room_id: int) -> RoomState:
	for room in rooms:
		if room.id == room_id:
			return room
	return null

func build_error(definition: RoomDefinition, column: int, floor_index: int) -> String:
	var error := placement_error(definition, column, floor_index)
	if not error.is_empty():
		return error
	return "Caixa insuficiente." if economy.cash < definition.build_cost else ""

func placement_error(definition: RoomDefinition, column: int, floor_index: int) -> String:
	if definition == null:
		return "Selecione uma construção."
	var locked := progression.build_error(definition)
	if not locked.is_empty():
		return locked
	if floor_index < 0 or floor_index >= floors:
		return "Construa o andar primeiro."
	if column < 0 or column + definition.width > COLUMNS:
		return "Fora do terreno."
	if definition.category == &"reception" and floor_index != 0:
		return "A recepção precisa ficar no térreo."
	if definition.category == &"transport":
		for level in floors:
			if room_at(column, level) != null:
				return "O poço precisa estar livre em todos os andares."
	else:
		for cell in range(column, column + definition.width):
			if room_at(cell, floor_index) != null:
				return "Espaço ocupado."
	return ""

func build(definition: RoomDefinition, column: int, floor_index: int, time: float = 0.0) -> RoomState:
	if not build_error(definition, column, floor_index).is_empty():
		return null
	if not economy.purchase(definition.build_cost, "Construção: " + definition.display_name, time):
		return null
	return finish_build(definition, column, floor_index)

func finish_build(definition: RoomDefinition, column: int, floor_index: int) -> RoomState:
	# Application jobs already reserved the investment. This domain operation
	# places the completed room without a second charge.
	if not placement_error(definition, column, floor_index).is_empty():
		return null
	var room := RoomState.new()
	room.id = next_room_id
	next_room_id += 1
	room.definition_id = definition.id
	room.column = column
	room.floor_index = 0 if definition.category == &"transport" else floor_index
	room.queue.capacity = definition.queue_capacity
	rooms.append(room)
	changed.emit()
	return room

func add_floor(time: float = 0.0) -> String:
	if floors >= MAX_FLOORS:
		return "Limite de 40 andares atingido."
	if not economy.purchase(FLOOR_COST, "Novo andar", time):
		return "Caixa insuficiente para o andar."
	floors += 1
	changed.emit()
	return ""

func demolish(room_id: int) -> String:
	var room := by_id(room_id)
	if room == null:
		return "Selecione uma sala."
	if room.busy():
		return "Sala em uso. Aguarde a liberação."
	# Vertical transport removal will be gated by the simulation while operating.
	rooms.erase(room)
	changed.emit()
	return ""
