class_name HotelQueueProjection
extends RefCounted
## Read-only world-pixel placement from authoritative FIFO reservations.

const ROOM_MARGIN: float = 12.0
const SLOT_SPACING: float = 24.0
const LIFT_DOOR_OFFSET: float = 36.0
const LIFT_LANE_WIDTH: float = 200.0
const ENTRY_SECONDS: float = 0.4
const ROOM_POINT_Y: float = -32.0
const LIFT_POINT_Y: float = -20.0
const STANDING_HEIGHT: float = 46.0

static func build(session: HotelSession, cell: float, floor_height: float) -> Dictionary:
	var result: Dictionary = {"positions": {}, "groups": []}
	for room: RoomState in session.hotel.rooms:
		if room.queue.members.is_empty():
			continue
		var start := room.column * cell + ROOM_MARGIN
		var span := room.definition().width * cell - ROOM_MARGIN * 2
		_add_group(result, session, room.queue.members, &"room", room.id, room.floor_index, start, span, 1.0, cell, floor_height)
	for lift: ElevatorState in session.transport.lifts:
		var floors: Dictionary = {}
		for id: int in lift.queue.members:
			var actor: ActorState = session.actors.get(id)
			if actor == null or actor.state != &"lift_queue" or actor.elevator_id != lift.room_id:
				continue
			if not floors.has(actor.floor_index):
				floors[actor.floor_index] = []
			floors[actor.floor_index].append(id)
		var lane := _lift_lane(lift, cell)
		for floor_index: int in floors:
			var members: Array[int] = []
			members.assign(floors[floor_index])
			_add_group(result, session, members, &"lift", lift.room_id, floor_index, lane.x, lane.y, lane.z, cell, floor_height)
	return result

static func position_for(session: HotelSession, actor: ActorState, cell: float, floor_height: float) -> Vector2:
	if actor.state in [&"checkin", &"service_queue"]:
		var room := session.hotel.by_id(actor.target_room)
		if room != null and actor.floor_index == room.floor_index:
			var rank := room.queue.members.find(actor.id)
			if rank >= 0:
				return _position(actor, rank, room.queue.members.size(), room.column * cell + ROOM_MARGIN, room.definition().width * cell - ROOM_MARGIN * 2, 1.0, ROOM_POINT_Y, cell, floor_height)
	elif actor.state == &"lift_queue":
		var lift := session.transport.lift_by_id(actor.elevator_id)
		if lift != null:
			var rank := -1
			var count := 0
			for id: int in lift.queue.members:
				var member: ActorState = session.actors.get(id)
				if member == null or member.state != &"lift_queue" or member.elevator_id != lift.room_id or member.floor_index != actor.floor_index:
					continue
				if id == actor.id:
					rank = count
				count += 1
			if rank >= 0:
				var lane := _lift_lane(lift, cell)
				return _position(actor, rank, count, lane.x, lane.y, lane.z, LIFT_POINT_Y, cell, floor_height)
	return Vector2(INF, INF)

static func _lift_lane(lift: ElevatorState, cell: float) -> Vector3:
	var direction := 1.0 if lift.column < HotelModel.COLUMNS / 2.0 else -1.0
	var start := lift.column * cell + LIFT_DOOR_OFFSET * direction
	var available := HotelModel.COLUMNS * cell - ROOM_MARGIN - start if direction > 0 else start - ROOM_MARGIN
	return Vector3(start, maxf(0, minf(LIFT_LANE_WIDTH, available)), direction)

static func _position(actor: ActorState, rank: int, count: int, start: float, span: float, direction: float, point_y: float, cell: float, floor_height: float) -> Vector2:
	var spacing := minf(SLOT_SPACING, span / maxi(1, count - 1))
	var target := Vector2(start + direction * rank * spacing, -actor.floor_index * floor_height + point_y)
	var arrival := Vector2((actor.x + (actor.id % 5) * 0.13) * cell, -actor.floor_index * floor_height - 20)
	return arrival.lerp(target, clampf(actor.waiting / ENTRY_SECONDS, 0.0, 1.0))

static func _add_group(result: Dictionary, session: HotelSession, members: Array[int], kind: StringName, owner_id: int, floor_index: int, start: float, span: float, direction: float, cell: float, floor_height: float) -> void:
	var point_y := ROOM_POINT_Y if kind == &"room" else LIFT_POINT_Y
	var spacing := minf(SLOT_SPACING, span / maxi(1, members.size() - 1))
	var label_x := minf(start, start + direction * (members.size() - 1) * spacing) - 5
	result.groups.append({"kind": kind, "owner_id": owner_id, "floor": floor_index, "count": members.size(), "header_world": Vector2(label_x, -floor_index * floor_height + point_y + 17 - STANDING_HEIGHT - 4)})
	for rank in members.size():
		var actor: ActorState = session.actors.get(members[rank])
		if actor == null or actor.floor_index != floor_index:
			continue
		if kind == &"room" and (actor.state not in [&"checkin", &"service_queue"] or actor.target_room != owner_id):
			continue
		result.positions[actor.id] = _position(actor, rank, members.size(), start, span, direction, point_y, cell, floor_height)
