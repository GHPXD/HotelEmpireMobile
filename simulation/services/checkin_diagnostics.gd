class_name CheckinDiagnostics
extends RefCounted
## Read-only next-step diagnosis for the first guest; never changes admission rules.

static func reason(session: HotelSession, reception: RoomState) -> String:
	if reception.queue.members.is_empty():
		return "empty"
	var head: ActorState = session.actors.get(reception.queue.members[0])
	if head == null:
		return "missing_head"
	if head.state != &"checkin":
		return "head_travelling"
	var staff: ActorState
	for employee: ActorState in session.actors.values():
		if employee.role == &"receptionist" and employee.assignment == reception.id and employee.state == &"working" and (employee.employee == null or (not employee.employee.dismiss_requested and (employee.employee.duty_enabled or head.timer > 0))):
			staff = employee
			break
	if staff == null:
		return "unstaffed"
	if head.timer + session.rules.tick * staff.work_efficiency() + SimulationRules.TIME_EPSILON < reception.duration():
		return "processing"
	var dirty_free: bool = false
	var affordable_accessible: bool = false
	var accessible: bool = false
	for room: RoomState in session.hotel.rooms:
		if room.definition().category != &"lodging" or not session.transport.accessible(head.floor_index, room.floor_index):
			continue
		accessible = true
		if head.money < room.price():
			continue
		affordable_accessible = true
		if room.occupant < 0:
			if not room.dirty:
				return "ready"
			dirty_free = true
	if dirty_free:
		return "cleaning"
	if affordable_accessible:
		return "occupied"
	return "unaffordable" if accessible else "no_accessible_bedroom"
