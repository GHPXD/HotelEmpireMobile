class_name HotelView
extends Control
## Original raster art; shared textures and deterministic visual animation.
## This view never changes simulation data.

signal cell_clicked(column: int, floor_index: int)
signal cancelled
signal actor_clicked(id: int)

const CELL: float = 62.0
const FLOOR_HEIGHT: float = 108.0
var hotel: HotelModel
var session: HotelSession
var selected: int = -1
var blueprint: RoomDefinition
var zoom_factor: float = 1.0
var pan: Vector2 = Vector2.ZERO
var pointer: Vector2 = Vector2(-1000, -1000)
var drag: bool = false
var hovered_cell := Vector2i(-1, -1)
# Reference switch for visual equivalence tests and profiling.
var cull_offscreen: bool = true

func _in_view(rectangle: Rect2) -> bool:
	return not cull_offscreen or Rect2(Vector2.ZERO, size).intersects(rectangle.grow(4))

func origin() -> Vector2:
	return Vector2((size.x - HotelModel.COLUMNS * CELL * zoom_factor) / 2.0, size.y - 95) + pan

func world_to_screen(point: Vector2) -> Vector2:
	return origin() + point * zoom_factor

func cell_at(point: Vector2) -> Vector2i:
	var local: Vector2 = (point - origin()) / zoom_factor
	return Vector2i(floori(local.x / CELL), floori(-local.y / FLOOR_HEIGHT))

func room_rect(column: int, floor_index: int, width: int = 1) -> Rect2:
	return Rect2(world_to_screen(Vector2(column * CELL, -(floor_index + 1) * FLOOR_HEIGHT)), Vector2(width * CELL, FLOOR_HEIGHT) * zoom_factor)

func _ready() -> void:
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pointer = event.position
		if drag:
			pan += event.relative
		hovered_cell = cell_at(pointer)
		queue_redraw()
	if event is InputEventMouseButton:
		pointer = event.position
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			drag = event.pressed
		if not event.pressed:
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if blueprint == null and session != null:
				for actor: ActorState in session.actors.values():
					if actor_screen_position(actor).distance_to(pointer) < 14 * zoom_factor:
						actor_clicked.emit(actor.id)
						return
			var cell := cell_at(pointer)
			cell_clicked.emit(cell.x, cell.y)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancelled.emit()
		elif event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var previous: Vector2 = (pointer - origin()) / zoom_factor
			zoom_factor = clampf(zoom_factor * (1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1), 0.35, 1.8)
			pan += pointer - world_to_screen(previous)
			queue_redraw()

func _draw() -> void:
	draw_texture_rect(HotelArt.CITY, Rect2(Vector2.ZERO, size), false)
	if hotel == null:
		return
	var ground: Vector2 = origin()
	if ground.y < size.y:
		draw_texture_rect(HotelArt.GROUND, Rect2(Vector2(0, ground.y), Vector2(size.x, maxf(95, size.y - ground.y))), false)
	for level in hotel.floors:
		var floor_rect := room_rect(0, level, HotelModel.COLUMNS)
		if not _in_view(floor_rect.grow(40)):
			continue
		for column in HotelModel.COLUMNS:
			if not _in_view(room_rect(column, level)):
				continue
			draw_texture_rect(HotelArt.CORRIDOR, room_rect(column, level), false)
			if blueprint != null:
				draw_rect(room_rect(column, level), Color(1, 1, 1, 0.3), false, 1)
		draw_line(floor_rect.end, Vector2(floor_rect.position.x, floor_rect.end.y), Color("576b68"), 5 * zoom_factor)
		_text(floor_rect.position + Vector2(-35, 25), "T" if level == 0 else str(level), Color("455d5c"), 16)
	for room in hotel.rooms:
		_draw_room(room)
	if session != null:
		_draw_simulation()
	if blueprint != null:
		var cell := cell_at(pointer)
		var valid: bool = hotel.build_error(blueprint, cell.x, cell.y).is_empty()
		var preview := room_rect(cell.x, cell.y, blueprint.width)
		var tint := Color(0.1, 0.65, 0.36, 0.45) if valid else Color(0.9, 0.22, 0.2, 0.5)
		draw_rect(preview, tint)
		draw_rect(preview, tint.lightened(0.2), false, 3)
		_text(preview.position + Vector2(8, 22), "+" if valid else "×", Color.WHITE, 20)
	_text(Vector2(22, 30), "SEU HOTEL, UM ANDAR DE CADA VEZ", Color("55716e"), 14)
	draw_rect(Rect2(12, size.y - 46, minf(610, size.x - 24), 34), Color(0.06, 0.14, 0.14, 0.86))
	_text(Vector2(22, size.y - 22), "Scroll: zoom   •   Botão do meio: mover   •   Clique direito / Esc: cancelar", Color("f1f5e9"), 14)

func _draw_room(room: RoomState) -> void:
	var definition := room.definition()
	var rectangle := room_rect(room.column, room.floor_index, definition.width).grow(-2 * zoom_factor)
	if definition.category == &"transport":
		rectangle = room_rect(room.column, hotel.floors - 1, 1)
		rectangle.size.y = hotel.floors * FLOOR_HEIGHT * zoom_factor
		for level in hotel.floors:
			if not _in_view(room_rect(room.column, level)):
				continue
			draw_texture_rect(HotelArt.room(definition.id), room_rect(room.column, level), false)
	else:
		if not _in_view(rectangle):
			return
		draw_texture_rect(HotelArt.room(definition.id, room.level), rectangle, false)
		if zoom_factor >= 0.65:
			draw_rect(Rect2(rectangle.position, Vector2(rectangle.size.x, 22 * zoom_factor)), Color(0.06, 0.14, 0.14, 0.88))
			_text(rectangle.position + Vector2(7, 17) * zoom_factor, definition.display_name + (" N%d" % room.level if room.level > 1 else ""), Color("fff1cc"), int(13 * zoom_factor))
	if room.id == selected:
		draw_rect(rectangle, Color("f9cd69"), false, 4)

func _text(at: Vector2, value: String, color: Color, font_size: int) -> void:
	draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func actor_screen_position(actor: ActorState) -> Vector2:
	var sleeping_room := _sleeping_room(actor)
	if sleeping_room != null:
		var bed := room_rect(sleeping_room.column, sleeping_room.floor_index, sleeping_room.definition().width).grow(-2 * zoom_factor)
		return bed.position + bed.size * HotelArt.SLEEP_BED_ANCHOR - Vector2(0, 17 * zoom_factor)
	var level: float = actor.floor_index
	var column: float = actor.x
	if actor.state == &"riding":
		var lift := session.transport.lift_by_id(actor.elevator_id)
		if lift != null:
			level = lift.floor_position
			column = lift.column
	if actor.role == &"guest" and actor.state == &"using":
		var room := hotel.by_id(actor.target_room)
		if room != null and HotelArt.SERVICE_ACTIONS.has(room.definition_id):
			var slot := room.users.find(actor.id)
			if slot >= 0:
				# Spread admitted guests visually; navigation and save state stay intact.
				column = room.column + room.definition().width * (float(slot) + 0.5) / room.capacity()
	var offset: float = float(actor.id % 5) * 0.13 if actor.state in [&"checkin", &"service_queue", &"lift_queue"] else 0.0
	return world_to_screen(Vector2((column + offset) * CELL, -level * FLOOR_HEIGHT - 20))

func _sleeping_room(actor: ActorState) -> RoomState:
	if actor.role != &"guest" or actor.state != &"using":
		return null
	var room := hotel.by_id(actor.target_room)
	return room if room != null and room.definition_id == &"bedroom" else null

func _draw_simulation() -> void:
	for lift in session.transport.lifts:
		var cabin := Rect2(world_to_screen(Vector2((lift.column - 0.37) * CELL, -(lift.floor_position + 0.72) * FLOOR_HEIGHT)), Vector2(CELL * 0.74, FLOOR_HEIGHT * 0.65) * zoom_factor)
		if not _in_view(cabin):
			continue
		var lift_room := hotel.by_id(lift.room_id)
		draw_texture_rect(HotelArt.cabin(lift_room.level if lift_room != null else 1), cabin, false)
		if zoom_factor > 0.65:
			_text(cabin.position + Vector2(8, 24) * zoom_factor, "%d/%d" % [lift.passengers.size(), lift.capacity], Color.WHITE, int(13 * zoom_factor))
	for room in hotel.rooms:
		if room.dirty:
			var box := room_rect(room.column, room.floor_index, room.definition().width)
			_status_badge(box.position + Vector2(7, 29) * zoom_factor, "LIMPAR")
		if not room.queue.members.is_empty():
			var box := room_rect(room.column, room.floor_index, room.definition().width)
			_status_badge(box.position + Vector2(7, 51) * zoom_factor, "Fila: %d" % room.queue.members.size())
	# Beds and their footboards precede people circulating in the foreground.
	for draw_sleepers: bool in [true, false]:
		for actor: ActorState in session.actors.values():
			var sleeping_room := _sleeping_room(actor)
			if (sleeping_room != null) == draw_sleepers:
				_draw_actor(actor, sleeping_room)

func _draw_actor(actor: ActorState, sleeping_room: RoomState) -> void:
	var point := actor_screen_position(actor)
	# Include the entire sprite, waiting badge and antialiased edge at every zoom.
	if not _in_view(Rect2(point - Vector2(36, 60) * zoom_factor, Vector2(72, 88) * zoom_factor).grow(16)):
		return
	var service_room := hotel.by_id(actor.target_room) if actor.state == &"using" else null
	var service_id: StringName = service_room.definition_id if service_room != null else &""
	var texture := HotelArt.character(actor, service_id)
	var region := HotelArt.character_region(actor, session.tick_count, service_id)
	var sprite_scale := HotelArt.character_scale(actor, service_id) * zoom_factor
	var sprite_size := region.size * sprite_scale
	var anchor := HotelArt.character_anchor(actor, session.tick_count, service_id)
	var destination := Rect2(point + Vector2(0, 17 * zoom_factor) - anchor * sprite_scale, sprite_size)
	if actor.target_x < actor.x and actor.state == &"walking":
		destination.position.x += destination.size.x
		destination.size.x = -destination.size.x
	draw_texture_rect_region(texture, destination, region)
	if sleeping_room != null and sleeping_room.level >= 3:
		var bed := room_rect(sleeping_room.column, sleeping_room.floor_index, sleeping_room.definition().width).grow(-2 * zoom_factor)
		var bed_texture := HotelArt.room(&"bedroom", sleeping_room.level)
		var front := HotelArt.SLEEP_FOOTBOARD
		draw_texture_rect_region(bed_texture, Rect2(bed.position + bed.size * front.position, bed.size * front.size), Rect2(bed_texture.get_size() * front.position, bed_texture.get_size() * front.size))
	if actor.state in [&"lift_queue", &"checkin", &"service_queue"]:
		_status_badge(point + Vector2(-7, -42) * zoom_factor, "…")

func _status_badge(at: Vector2, label: String) -> void:
	var font_size := maxi(9, int(12 * zoom_factor))
	var text_size := ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	if not _in_view(Rect2(at, text_size + Vector2(8, 2))):
		return
	draw_rect(Rect2(at, Vector2(text_size.x + 8, text_size.y + 2)), Color(0.12, 0.18, 0.17, 0.94))
	_text(at + Vector2(4, text_size.y - 3), label, Color("ffe0a0"), font_size)
