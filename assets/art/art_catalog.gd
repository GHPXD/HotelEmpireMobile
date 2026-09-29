class_name HotelArt
extends RefCounted
## Shared raster textures. Visual state never consumes simulation RNG.

const ROOMS: Dictionary = {
	&"reception": preload("res://assets/art/rooms/reception.png"),
	&"bedroom": preload("res://assets/art/rooms/bedroom.png"),
	&"restaurant": preload("res://assets/art/rooms/restaurant.png"),
	&"cafe": preload("res://assets/art/rooms/cafe.png"),
	&"lounge": preload("res://assets/art/rooms/lounge.png"),
	&"elevator": preload("res://assets/art/environment/elevator.png"),
}
const CITY: Texture2D = preload("res://assets/art/environment/city.png")
const GROUND: Texture2D = preload("res://assets/art/environment/ground.png")
const CORRIDOR: Texture2D = preload("res://assets/art/environment/corridor.png")
const CABIN: Texture2D = preload("res://assets/art/environment/cabin.png")
const CABIN_UPGRADE: Texture2D = preload("res://assets/art/environment/cabin-level-2.png")
const CABIN_FINAL_UPGRADE: Texture2D = preload("res://assets/art/environment/cabin-level-3.png")

static func cabin(level: int) -> Texture2D:
	if level >= 3:
		return CABIN_FINAL_UPGRADE
	return CABIN_UPGRADE if level >= 2 else CABIN

const ROOM_UPGRADES: Dictionary = {
	&"restaurant": preload("res://assets/art/rooms/restaurant-level-2.png"),
	&"bedroom": preload("res://assets/art/rooms/bedroom-level-2.png"),
	&"reception": preload("res://assets/art/rooms/reception-level-2.png"),
}

const ROOM_FINAL_UPGRADES: Dictionary = {
	&"bedroom": preload("res://assets/art/rooms/bedroom-level-3.png"),
	&"reception": preload("res://assets/art/rooms/reception-level-3.png"),
	&"restaurant": preload("res://assets/art/rooms/restaurant-level-3.png"),
}

static func room(id: StringName, level: int = 1) -> Texture2D:
	if level >= 3 and ROOM_FINAL_UPGRADES.has(id):
		return ROOM_FINAL_UPGRADES[id]
	if level >= 2 and ROOM_UPGRADES.has(id):
		return ROOM_UPGRADES[id]
	return ROOMS.get(id)

const CHARACTERS: Dictionary = {
	&"balanced-cafe": preload("res://assets/art/characters/balanced-cafe.png"),
	&"business-cafe": preload("res://assets/art/characters/business-cafe.png"),
	&"leisure-cafe": preload("res://assets/art/characters/leisure-cafe.png"),
	&"balanced-waiting": preload("res://assets/art/characters/balanced-waiting.png"),
	&"business-waiting": preload("res://assets/art/characters/business-waiting.png"),
	&"leisure-waiting": preload("res://assets/art/characters/leisure-waiting.png"),
	&"cleaner-cleaning": preload("res://assets/art/characters/cleaner-cleaning.png"),
	&"receptionist-working": preload("res://assets/art/characters/receptionist-working.png"),
	&"balanced": preload("res://assets/art/characters/balanced.png"),
	&"business": preload("res://assets/art/characters/business.png"),
	&"cleaner": preload("res://assets/art/characters/cleaner.png"),
	&"leisure": preload("res://assets/art/characters/leisure.png"),
	&"receptionist": preload("res://assets/art/characters/receptionist.png"),
}
const REGIONS: Dictionary = {"balanced": [[50, 67, 425, 746], [531, 66, 226, 747], [919, 72, 440, 741], [1414, 66, 247, 751]], "business": [[49, 42, 444, 780], [574, 41, 207, 783], [907, 42, 468, 783], [1403, 43, 333, 781]], "cleaner": [[33, 49, 409, 770], [520, 49, 293, 774], [912, 49, 429, 772], [1411, 49, 319, 773]], "leisure": [[33, 45, 430, 772], [505, 45, 355, 769], [904, 45, 447, 771], [1396, 45, 320, 771]], "receptionist": [[52, 43, 438, 771], [556, 45, 217, 767], [922, 47, 431, 767], [1408, 45, 278, 771]]}

static func character_id(actor: ActorState) -> StringName:
	return actor.archetype_id if actor.role == &"guest" else actor.role

static func character(actor: ActorState, service_id: StringName = &"") -> Texture2D:
	return CHARACTERS[animation_id(actor, service_id)]

const ACTION_REGIONS: Dictionary = {
	&"balanced-cafe": [[219, 10, 606, 1463]],
	&"business-cafe": [[243, 38, 507, 1445]],
	&"leisure-cafe": [[273, 53, 499, 1432]],
	&"balanced-waiting": [[116, 55, 275, 778], [517, 55, 286, 778], [982, 55, 273, 778], [1404, 55, 270, 778]],
	&"business-waiting": [[114, 35, 272, 808], [550, 35, 245, 808], [964, 35, 273, 808], [1392, 35, 251, 808]],
	&"leisure-waiting": [[100, 43, 249, 795], [507, 43, 256, 795], [988, 43, 273, 795], [1428, 43, 245, 795]],
	&"cleaner-cleaning": [[111, 88, 289, 710], [506, 104, 387, 694], [974, 91, 294, 707], [1364, 109, 384, 694]],
	&"receptionist-working": [[121, 44, 271, 796], [531, 60, 297, 780], [955, 43, 275, 797], [1353, 41, 390, 799]],
}

static func animation_id(actor: ActorState, service_id: StringName = &"") -> StringName:
	if actor.role == &"guest" and actor.state == &"using" and service_id == &"cafe":
		return StringName("%s-cafe" % actor.archetype_id)
	if actor.role == &"guest" and actor.state in [&"lift_queue", &"checkin", &"service_queue"]:
		return StringName("%s-waiting" % actor.archetype_id)
	if actor.role == &"cleaner" and actor.state == &"cleaning":
		return &"cleaner-cleaning"
	if actor.role == &"receptionist" and actor.state == &"working":
		return &"receptionist-working"
	return character_id(actor)

static func character_regions(actor: ActorState, service_id: StringName = &"") -> Array:
	var id := animation_id(actor, service_id)
	return ACTION_REGIONS[id] if ACTION_REGIONS.has(id) else REGIONS[id]

static func character_region(actor: ActorState, tick: int, service_id: StringName = &"") -> Rect2:
	var regions := character_regions(actor, service_id)
	var index: int = (tick + actor.id * 2) % 4 if actor.state == &"walking" else 1
	if ACTION_REGIONS.has(animation_id(actor)):
		# Waiting uses slower gestures; all animations freeze with the simulation.
		var frame_ticks := 12.0 if actor.role == &"guest" else 4.0
		index = (floori(tick / frame_ticks) + actor.id) % 4
	var box: Array = regions[index % regions.size()]
	return Rect2(box[0], box[1], box[2], box[3])

static func character_scale(actor: ActorState, service_id: StringName = &"") -> float:
	var height: float = 0.0
	for box: Array in character_regions(actor, service_id):
		height = maxf(height, box[3])
	return 46.0 / height
