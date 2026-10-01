class_name ConstructionPurchasePlan
extends RefCounted
## Validate the paid future hotel before publishing a live construction job.

static func prepare(session: HotelSession, construction: ConstructionService, kind: StringName, arguments: Dictionary, now_ms: int) -> Dictionary:
	var restored := SessionSnapshot.restore(SessionSnapshot.capture(session))
	if not restored.error.is_empty():
		return {"error": "save.error.invalid", "job": null}
	var future: HotelSession = restored.session
	var jobs := ConstructionService.new(future.hotel)
	if not jobs.restore(construction.snapshot(), now_ms):
		return {"error": "save.error.invalid", "job": null}
	var result := apply(jobs, kind, arguments, now_ms, future.time)
	if not result.error.is_empty():
		return result
	return {"error": "", "session": future, "construction": jobs, "job": result.job}

static func apply(construction: ConstructionService, kind: StringName, arguments: Dictionary, now_ms: int, game_time: float) -> Dictionary:
	match kind:
		&"build":
			return construction.enqueue_build(arguments.definition, arguments.column, arguments.floor_index, now_ms, game_time)
		&"floor":
			return construction.enqueue_floor(now_ms, game_time)
		&"upgrade":
			return construction.enqueue_upgrade(arguments.id, now_ms, game_time)
		&"specialize":
			return construction.enqueue_specialization(arguments.id, arguments.specialization, now_ms, game_time)
	return {"error": "error.command", "job": null}
