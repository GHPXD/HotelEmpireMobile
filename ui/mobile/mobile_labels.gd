class_name MobileLabels
extends RefCounted
## Localized read-only descriptions of simulation facts.

static func actor_name(actor: ActorState) -> String:
	if actor.role == &"player":
		return TranslationServer.translate("work.you")
	if actor.role == &"guest":
		return TranslationServer.translate("actor.guest") % actor.id
	return TranslationServer.translate("staff." + String(actor.role) + ".name") + " #%d" % actor.id

static func room_name(room: RoomState) -> String:
	return TranslationServer.translate("room." + String(room.definition_id) + ".name") + " #%d" % room.id

static func actor_details(actor: ActorState, hotel: HotelModel) -> String:
	var state := TranslationServer.translate("state." + String(actor.state))
	var goal := actor.destination_state if actor.in_transit() else actor.state
	var target := hotel.by_id(actor.assignment if actor.role != &"guest" else actor.target_room)
	var destination: String = room_name(target) if target != null else String(TranslationServer.translate("actor.no_destination"))
	var text := TranslationServer.translate("actor.details") % [state, destination, roundi(actor.waiting)]
	if actor.role == &"guest":
		text += "\n" + TranslationServer.translate("actor.experience") % [roundi(actor.happiness), roundi(actor.age), MobileLocale.number(actor.money)]
		text += "\n" + TranslationServer.translate("actor.needs") % [roundi(actor.needs.hunger), roundi(actor.needs.energy), roundi(actor.needs.entertainment), roundi(actor.needs.comfort)]
	else:
		text += "\n" + TranslationServer.translate("actor.workload") % roundi(actor.workload)
	if goal == &"exit":
		text += "\n" + TranslationServer.translate("actor.leaving")
	return text

static func checkin(session: HotelSession, room: RoomState) -> String:
	if session.player_work.job.get("kind") == "checkin" and session.player_work.job.get("target_room") == room.id:
		return TranslationServer.translate("work.manual_checkin")
	return TranslationServer.translate("checkin." + CheckinDiagnostics.reason(session, room))

static func player_work(session: HotelSession) -> String:
	var work := session.player_work
	if work.job.is_empty():
		return TranslationServer.translate("work.returning") if work.busy(session) else TranslationServer.translate("work.idle")
	var room := session.hotel.by_id(int(work.job.target_room))
	var text := TranslationServer.translate("work.status") % [TranslationServer.translate("work." + String(work.job.kind)), TranslationServer.translate("work.phase." + String(work.job.phase)), room_name(room) if room != null else ""]
	if work.job.phase in ["action", "prepare", "deliver"]:
		text += "\n" + TranslationServer.translate("work.remaining") % float(work.job.remaining)
	if work.job.kind == "room_service":
		text += "\n" + TranslationServer.translate("work.delivery_price") % MobileLocale.number(int(work.job.price))
	return text

static func elevator(metrics: Dictionary) -> String:
	var text := TranslationServer.translate("lift.current") % [metrics.passengers, metrics.capacity, metrics.queue, roundi(metrics.current_max)]
	if metrics.boarded > 0:
		text += "\n" + TranslationServer.translate("lift.history") % [roundi(metrics.average_wait), roundi(metrics.max_wait), metrics.delivered]
	else:
		text += "\n" + TranslationServer.translate("lift.no_history")
	return text

static func review(item: Dictionary, day_seconds: float) -> String:
	var result := TranslationServer.translate("review.header") % [item.guest_id, floori(item.time / day_seconds) + 1, roundi(item.score)]
	result += "\n" + TranslationServer.translate("review.stayed" if item.checked_in else "review.not_stayed")
	result += "\n" + TranslationServer.translate("review.activities") % [item.meals, item.services - item.meals, item.sleeps]
	var waits: Array[String] = []
	for field: String in ActorState.WAIT_FIELDS:
		waits.append(TranslationServer.translate("review.unknown") if item[field] == null else "%.1fs" % float(item[field]))
	result += "\n" + TranslationServer.translate("review.waits") % waits
	return result

static func transaction_reason(reason: String) -> String:
	var key := "other"
	if reason.begins_with("Construção:"):
		key = "construction"
	elif reason.begins_with("Contratação:"):
		key = "hiring"
	elif reason.begins_with("Melhoria:"):
		key = "upgrade"
	elif reason == "Manutenção diária":
		key = "maintenance"
	elif reason == "Salários diários":
		key = "salaries"
	elif reason == "Hospedagem":
		key = "lodging"
	elif reason == "Reparo simples":
		key = "repair"
	elif reason == "Room service":
		key = "room_service"
	else:
		for definition: RoomDefinition in HotelCatalog.ROOMS:
			if reason == definition.display_name:
				return TranslationServer.translate("room." + String(definition.id) + ".name")
	return TranslationServer.translate("finance." + key)
