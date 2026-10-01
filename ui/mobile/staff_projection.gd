class_name StaffProjection
extends RefCounted
## Read-only department and recruitment projections; no manager NPC is implied.

static func definition(role: StringName) -> EmployeeDefinition:
	for item in HotelSession.EMPLOYEES:
		if item.id == role:
			return item
	return null

static func department(session: HotelSession, role: StringName) -> Dictionary:
	var result := {"staff": 0, "enabled": 0, "active": 0, "paused": 0, "departing": 0, "backlog": 0, "salary": 0}
	var base := definition(role)
	for actor: ActorState in session.actors.values():
		if actor.role != role:
			continue
		var progress := actor.employee if actor.employee != null else EmployeeProgress.new()
		result.staff += 1
		result.salary += progress.salary(base.salary)
		if progress.dismiss_requested:
			result.departing += 1
		else:
			if progress.duty_enabled:
				result.enabled += 1
			else:
				result.paused += 1
			if actor.assignment >= 0 and (actor.in_transit() or actor.state in [&"working", &"cleaning"]):
				result.active += 1
	for room in session.hotel.rooms:
		if role == &"receptionist" and room.definition().category == &"reception":
			result.backlog += room.queue.members.size()
		elif role == &"cleaner" and room.dirty:
			result.backlog += 1
	return result

static func details(actor: ActorState) -> Dictionary:
	var progress := actor.employee if actor.employee != null else EmployeeProgress.new()
	var base := definition(actor.role)
	var level := progress.level()
	return {"level": level, "xp": progress.xp, "next_xp": EmployeeProgress.RULES.thresholds[level] if level < EmployeeProgress.RULES.thresholds.size() else -1, "salary": progress.salary(base.salary), "efficiency": roundi(progress.efficiency(actor.skill) * 100), "quality": progress.quality(), "jobs": progress.completed_tasks}
