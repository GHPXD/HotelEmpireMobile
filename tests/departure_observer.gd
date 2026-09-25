extends RefCounted
## Test-only observer: retain live references until the tick removes departing guests.

var pending: Array[ActorState] = []
var groups: Dictionary = {
	"stayed": {"count": 0, "score_total": 0.0, "minimum": 100.0, "maximum": 0.0},
	"no_stay": {"count": 0, "score_total": 0.0, "minimum": 100.0, "maximum": 0.0},
}

func before_step(session: HotelSession) -> void:
	pending.clear()
	for actor: ActorState in session.actors.values():
		if actor.role == &"guest":
			pending.append(actor)

func after_step(session: HotelSession) -> void:
	for actor: ActorState in pending:
		if session.actors.has(actor.id):
			continue
		var group: Dictionary = groups["stayed" if actor.checked_in else "no_stay"]
		group.count += 1
		group.score_total += actor.happiness
		group.minimum = minf(group.minimum, actor.happiness)
		group.maximum = maxf(group.maximum, actor.happiness)
	pending.clear()

func report() -> Dictionary:
	var result := groups.duplicate(true)
	for group: Dictionary in result.values():
		group["mean"] = group.score_total / group.count if group.count > 0 else null
		if group.count == 0:
			group.minimum = null
			group.maximum = null
	return result
