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
	&"cleaner-idle": preload("res://assets/art/characters/cleaner-idle.png"),
	&"receptionist-idle": preload("res://assets/art/characters/receptionist-idle.png"),
	&"balanced-sleeping": preload("res://assets/art/characters/balanced-sleeping.png"),
	&"business-sleeping": preload("res://assets/art/characters/business-sleeping.png"),
	&"leisure-sleeping": preload("res://assets/art/characters/leisure-sleeping.png"),
	&"balanced-dining": preload("res://assets/art/characters/balanced-dining.png"),
	&"business-dining": preload("res://assets/art/characters/business-dining.png"),
	&"leisure-dining": preload("res://assets/art/characters/leisure-dining.png"),
	&"balanced-reading": preload("res://assets/art/characters/balanced-reading.png"),
	&"business-reading": preload("res://assets/art/characters/business-reading.png"),
	&"leisure-reading": preload("res://assets/art/characters/leisure-reading.png"),
	&"balanced-drinking": preload("res://assets/art/characters/balanced-drinking.png"),
	&"business-drinking": preload("res://assets/art/characters/business-drinking.png"),
	&"leisure-drinking": preload("res://assets/art/characters/leisure-drinking.png"),
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
	&"cleaner-idle": [[246, 21, 208, 719], [729, 18, 205, 722], [1202, 29, 214, 711], [1653, 21, 203, 719]],
	&"receptionist-idle": [[116, 42, 260, 812], [558, 41, 262, 813], [1001, 51, 263, 803], [1446, 42, 261, 812]],
	&"balanced-sleeping": [[28, 9, 1718, 867]],
	&"business-sleeping": [[31, 16, 1713, 862]],
	&"leisure-sleeping": [[23, 12, 1730, 864]],
	&"balanced-dining": [[66, 89, 455, 582], [600, 89, 440, 582], [1118, 89, 437, 582], [1635, 89, 439, 582]],
	&"business-dining": [[68, 76, 461, 598], [595, 76, 447, 598], [1114, 76, 448, 598], [1649, 76, 455, 598]],
	&"leisure-dining": [[83, 66, 459, 611], [612, 66, 447, 611], [1141, 66, 445, 611], [1674, 66, 448, 611]],
	&"balanced-reading": [[41, 201, 420, 547], [478, 201, 419, 547], [917, 201, 417, 547], [1354, 201, 418, 547]],
	&"business-reading": [[56, 88, 478, 618], [583, 88, 480, 618], [1106, 88, 478, 618], [1646, 88, 474, 618]],
	&"leisure-reading": [[43, 66, 489, 629], [586, 66, 490, 629], [1130, 66, 489, 629], [1685, 66, 486, 629]],
	&"balanced-drinking": [[68, 5, 382, 874], [468, 5, 380, 874], [876, 5, 379, 874], [1314, 5, 380, 874]],
	&"business-drinking": [[94, 8, 319, 867], [515, 8, 311, 867], [939, 8, 306, 867], [1365, 8, 318, 867]],
	&"leisure-drinking": [[84, 6, 313, 881], [528, 6, 313, 881], [959, 6, 324, 881], [1396, 6, 317, 881]],
	&"balanced-cafe": [[219, 10, 606, 1463]],
	&"business-cafe": [[243, 38, 507, 1445]],
	&"leisure-cafe": [[273, 53, 499, 1432]],
	&"balanced-waiting": [[116, 55, 275, 778], [517, 55, 286, 778], [982, 55, 273, 778], [1404, 55, 270, 778]],
	&"business-waiting": [[114, 35, 272, 808], [550, 35, 245, 808], [964, 35, 273, 808], [1392, 35, 251, 808]],
	&"leisure-waiting": [[100, 43, 249, 795], [507, 43, 256, 795], [988, 43, 273, 795], [1428, 43, 245, 795]],
	&"cleaner-cleaning": [[111, 88, 289, 710], [506, 104, 387, 694], [974, 91, 294, 707], [1364, 109, 384, 694]],
	&"receptionist-working": [[121, 44, 271, 796], [531, 60, 297, 780], [955, 43, 275, 797], [1353, 41, 390, 799]],
}

# Local foot centers measured from alpha; gestures keep a shared floor anchor.
const ACTION_ANCHORS: Dictionary = {
	&"cleaner-idle": [Vector2(118, 715), Vector2(115.5, 718), Vector2(119, 707), Vector2(113, 715)],
	&"receptionist-idle": [Vector2(120, 808), Vector2(122, 809), Vector2(122.5, 799), Vector2(120, 808)],
	&"balanced-dining": [Vector2(225.5, 578), Vector2(216, 578), Vector2(218, 578), Vector2(215, 578)],
	&"business-dining": [Vector2(234, 594), Vector2(229, 594), Vector2(226, 594), Vector2(230, 594)],
	&"leisure-dining": [Vector2(228.5, 607), Vector2(222, 607), Vector2(222, 607), Vector2(223, 607)],
	&"balanced-reading": [Vector2(217.5, 543), Vector2(217, 543), Vector2(216, 543), Vector2(216, 543)],
	&"business-reading": [Vector2(291.5, 614), Vector2(286.5, 614), Vector2(286.5, 614), Vector2(282.5, 614)],
	&"leisure-reading": [Vector2(262.5, 625), Vector2(262.5, 625), Vector2(261.5, 625), Vector2(260.5, 625)],
	&"balanced-drinking": [Vector2(234, 870), Vector2(232, 870), Vector2(231, 870), Vector2(232, 870)],
	&"business-drinking": [Vector2(182, 863), Vector2(183, 863), Vector2(181, 863), Vector2(183, 863)],
	&"leisure-drinking": [Vector2(188, 877), Vector2(189, 877), Vector2(190, 877), Vector2(192, 877)],
}

const SERVICE_ACTIONS: Dictionary = {&"cafe": "drinking", &"lounge": "reading", &"restaurant": "dining", &"bedroom": "sleeping"}
const SERVICE_FRAME_TICKS: Dictionary = {&"cafe": 8.0, &"lounge": 12.0, &"restaurant": 6.0}
const SERVICE_HEIGHTS: Dictionary = {&"lounge": 36.0, &"restaurant": 36.0}
const SLEEP_WIDTH: float = 52.0
const STAFF_IDLE_ROLES: Array[StringName] = [&"cleaner", &"receptionist"]
const STAFF_IDLE_STATES: Array[StringName] = [&"idle", &"lift_queue"]
const STAFF_IDLE_FRAME_TICKS: float = 16.0
const SLEEP_BED_ANCHOR: Vector2 = Vector2(0.5, 0.62)
# Normalized bounds of the N3 footboard, restored in front of the sleeper.
const SLEEP_FOOTBOARD: Rect2 = Rect2(0.28, 0.572, 0.435, 0.09)

static func animation_id(actor: ActorState, service_id: StringName = &"") -> StringName:
	if actor.role in STAFF_IDLE_ROLES and actor.state in STAFF_IDLE_STATES:
		return StringName("%s-idle" % actor.role)
	if actor.role == &"guest" and actor.state == &"using" and SERVICE_ACTIONS.has(service_id):
		return StringName("%s-%s" % [actor.archetype_id, SERVICE_ACTIONS[service_id]])
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

static func character_frame(actor: ActorState, tick: int, service_id: StringName = &"") -> int:
	var regions := character_regions(actor, service_id)
	var index: int = (tick + actor.id * 2) % 4 if actor.state == &"walking" else 1
	if ACTION_REGIONS.has(animation_id(actor, service_id)):
		# All gestures freeze with simulation ticks; service cadence is contextual.
		var frame_ticks := 12.0 if actor.role == &"guest" else 4.0
		if actor.role in STAFF_IDLE_ROLES and actor.state in STAFF_IDLE_STATES:
			frame_ticks = STAFF_IDLE_FRAME_TICKS
		if actor.role == &"guest" and actor.state == &"using":
			frame_ticks = SERVICE_FRAME_TICKS.get(service_id, frame_ticks)
		index = (floori(tick / frame_ticks) + actor.id) % 4
	return index % regions.size()

static func character_region(actor: ActorState, tick: int, service_id: StringName = &"") -> Rect2:
	var box: Array = character_regions(actor, service_id)[character_frame(actor, tick, service_id)]
	return Rect2(box[0], box[1], box[2], box[3])

static func character_anchor(actor: ActorState, tick: int, service_id: StringName = &"") -> Vector2:
	var id := animation_id(actor, service_id)
	if ACTION_ANCHORS.has(id):
		return ACTION_ANCHORS[id][character_frame(actor, tick, service_id)]
	var region := character_region(actor, tick, service_id)
	return Vector2(region.size.x / 2.0, region.size.y)

static func character_scale(actor: ActorState, service_id: StringName = &"") -> float:
	var height: float = 0.0
	var width: float = 0.0
	for box: Array in character_regions(actor, service_id):
		height = maxf(height, box[3])
		width = maxf(width, box[2])
	if actor.role == &"guest" and actor.state == &"using" and service_id == &"bedroom":
		return SLEEP_WIDTH / width
	# Seated guests have a lower head height than standing guests.
	var visual_height: float = SERVICE_HEIGHTS.get(service_id, 46.0) if actor.role == &"guest" and actor.state == &"using" else 46.0
	return visual_height / height
