class_name OnboardingService
extends RefCounted
## Non-blocking guide; advances from completed hotel effects, never UI clicks.

const STEPS: Array[String] = ["reception", "bedroom", "open", "checkin", "food", "room_service", "cleaning", "repair", "hire"]
var enabled: bool = false
var skipped: bool = false
var stage: int = 0
var completed_at: Array[float] = []

func start() -> void:
	enabled = true
	skipped = false

func active() -> bool:
	return enabled and not skipped and stage < STEPS.size()

func step_id() -> String:
	return STEPS[stage] if stage < STEPS.size() else "done"

func observe(session: HotelSession) -> bool:
	if not enabled or skipped:
		return false
	var previous: int = stage
	while stage < STEPS.size() and _fulfilled(session, STEPS[stage]):
		completed_at.append(session.time)
		stage += 1
	return stage != previous

func _fulfilled(session: HotelSession, step: String) -> bool:
	match step:
		"reception": return first_room(session, &"reception") != null
		"bedroom": return first_room(session, &"lodging") != null
		"open": return session.opened or session.guests.bookings > 0
		"checkin": return int(session.player_work.totals.checkins) > 0
		"food": return first_room(session, &"service", &"hunger") != null
		"room_service": return int(session.player_work.totals.delivered) > 0
		"cleaning": return int(session.player_work.totals.cleaned) > 0
		"repair": return int(session.player_work.totals.repaired) > 0
		"hire":
			for actor: ActorState in session.actors.values():
				if actor.role in [&"receptionist", &"cleaner"]:
					return true
	return false

static func first_room(session: HotelSession, category: StringName, need: StringName = &"") -> RoomState:
	for room in session.hotel.rooms:
		if room.definition().category == category and (need.is_empty() or room.definition().need == need):
			return room
	return null

func snapshot() -> Dictionary:
	return {"version": 1, "enabled": enabled, "skipped": skipped, "stage": stage, "completed_at": completed_at.duplicate()}

func restore(data: Variant) -> bool:
	if not valid(data):
		return false
	enabled = data.enabled
	skipped = data.skipped
	stage = int(data.stage)
	completed_at.clear()
	for time: Variant in data.completed_at:
		completed_at.append(float(time))
	return true

static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 5 or data.get("version") != 1 or not data.get("enabled") is bool or not data.get("skipped") is bool or not SaveService._integer(data.get("stage"), 0, STEPS.size()) or not data.get("completed_at") is Array or data.completed_at.size() != int(data.stage):
		return false
	var previous: float = -1.0
	for value: Variant in data.completed_at:
		if not SessionSnapshot._number(value) or value < 0 or value < previous:
			return false
		previous = float(value)
	return true
