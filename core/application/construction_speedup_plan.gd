class_name ConstructionSpeedupPlan
extends RefCounted
## Prepare a complete valid future snapshot without touching the live hotel.
## Application writes it atomically, then applies the same deterministic command.

static func prepare(session: HotelSession, construction: ConstructionService, inventory: PlayerInventory, guide: OnboardingService, modules: Dictionary, clock_state: Dictionary, job_id: int, item_id: StringName, operation_id: int, now_ms: int) -> Dictionary:
	var error := inventory.spend_error(item_id, operation_id)
	if not error.is_empty():
		return {"error": error}
	var item := PlayerInventory.definition(item_id)
	error = construction.acceleration_error(job_id, item.seconds * 1000, now_ms)
	if not error.is_empty():
		return {"error": error}
	var restored := SessionSnapshot.restore(SessionSnapshot.capture(session))
	if not restored.error.is_empty():
		return {"error": "save.error.invalid"}
	var future: HotelSession = restored.session
	var future_construction := ConstructionService.new(future.hotel)
	var future_inventory := PlayerInventory.new()
	var future_guide := OnboardingService.new()
	if not future_construction.restore(construction.snapshot(), now_ms) or not future_inventory.restore(inventory.snapshot()) or not future_guide.restore(guide.snapshot()):
		return {"error": "save.error.invalid"}
	var acceleration := future_construction.accelerate(job_id, item.seconds * 1000, now_ms, future.time)
	if not acceleration.error.is_empty():
		return {"error": acceleration.error}
	if not future_inventory.spend(item_id, operation_id).is_empty():
		return {"error": "save.error.invalid"}
	future_guide.observe(future)
	if future_guide.enabled and future_guide.stage == OnboardingService.STEPS.size():
		future_inventory.claim_reward(&"tutorial")
	var future_modules := modules.duplicate(true)
	future_modules["progress_clock"] = clock_state.duplicate()
	future_modules["construction"] = future_construction.snapshot()
	future_modules["player_inventory"] = future_inventory.snapshot()
	if future_guide.enabled:
		future_modules["onboarding"] = future_guide.snapshot()
	return {"error": "", "session": future, "inventory": future_inventory, "onboarding": future_guide, "modules": future_modules, "applied_ms": int(acceleration.applied_ms)}
