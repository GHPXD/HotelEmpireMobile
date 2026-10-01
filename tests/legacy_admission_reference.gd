extends GuestSystem
## Independent reference preserves the pre-M8 room scan/release algorithm.
## A file-backed script also gives Godot a stable lifetime for this subclass.

func _arrival_rooms(hotel: HotelModel) -> Array[RoomState]:
	return hotel.rooms

func _release_room(actor: ActorState, hotel: HotelModel) -> void:
	var room := hotel.by_id(actor.bedroom)
	if room != null and room.occupant == actor.id:
		room.occupant = -1
		room.dirty = true
		room.dirty_since = current_time
		room.cleaning_quality_bonus = 0
		room.wear(work_rules.room_wear_per_stay)
	actor.bedroom = -1
