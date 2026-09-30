extends "res://tests/ui_management.gd"

func run() -> void:
	var game: Node = load("res://core/game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var session := HotelSession.new(71)
	session.economy.cash = 100000
	session.hotel.add_floor()
	session.progression.completed.assign([&"first_stays", &"steady_service"])
	for entry in [[&"reception", 0], [&"restaurant", 3], [&"cafe", 6], [&"lounge", 8], [&"elevator", 11], [&"bedroom", 12], [&"bedroom", 14]]:
		check(session.hotel.build(HotelCatalog.room(entry[0]), entry[1], 0) != null, "showcase room %s" % entry[0])
	for column in [0, 2, 4, 6, 8]:
		session.hotel.build(HotelCatalog.room(&"bedroom"), column, 1)
	# Buy real upgrades so captures exercise the same visual state as gameplay.
	session.hotel.add_floor()
	for column: int in [0, 3]:
		var restaurant := session.hotel.build(HotelCatalog.room(&"restaurant"), column, 2)
		check(session.upgrade_room(restaurant.id).is_empty(), "restaurant level 2 purchase")
		if column == 3:
			check(session.upgrade_room(restaurant.id).is_empty(), "restaurant level 3 purchase")
	for room: RoomState in session.hotel.rooms:
		if room.definition_id == &"elevator":
			check(session.upgrade_room(room.id).is_empty(), "showcase elevator upgrade purchase")
			check(session.upgrade_room(room.id).is_empty(), "showcase final elevator upgrade purchase")
		if room.definition_id in [&"reception", &"bedroom"] and room.column == 0:
			check(session.upgrade_room(room.id).is_empty(), "showcase upgrade purchase")
			check(session.upgrade_room(room.id).is_empty(), "showcase final upgrade purchase")
		if room.definition_id == &"bedroom" and room.floor_index == 1 and room.column == 2:
			check(session.upgrade_room(room.id).is_empty(), "keep bedroom level 2 comparison")
	for index in 5:
		var actor := session.spawn_guest()
		actor.x = 1.2 + index * 2.1
		actor.floor_index = 0
		actor.state = &"walking"
		actor.target_x = 12
		if index < 3:
			actor.archetype_id = [&"balanced", &"business", &"leisure"][index]
		else:
			actor.role = &"receptionist" if index == 3 else &"cleaner"
		var texture := HotelArt.character(actor)
		check(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "real alpha %s" % actor.role)
		var regions: Array = HotelArt.REGIONS[HotelArt.character_id(actor)]
		check(HotelArt.character_region(actor, 0) != HotelArt.character_region(actor, 1), "walk advances with simulation tick")
		check(HotelArt.character_region(actor, 0) == HotelArt.character_region(actor, 4), "walk loops after four ticks")
		for box: Array in regions:
			check(Rect2(Vector2.ZERO, texture.get_size()).encloses(Rect2(box[0], box[1], box[2], box[3])), "frame contained in texture")
	for actor: ActorState in session.actors.values():
		if actor.role == &"guest":
			var walking := HotelArt.character(actor)
			for waiting_state: StringName in [&"checkin", &"service_queue", &"lift_queue"]:
				actor.state = waiting_state
				var waiting := HotelArt.character(actor)
				check(waiting != walking, "guest has dedicated waiting texture")
				check(waiting.get_image().detect_alpha() != Image.ALPHA_NONE, "waiting alpha")
				check(HotelArt.character_region(actor, 0) != HotelArt.character_region(actor, 12), "waiting gesture advances")
				check(HotelArt.character_region(actor, 0) == HotelArt.character_region(actor, 48), "waiting loops")
				for box: Array in HotelArt.character_regions(actor):
					check(Rect2(Vector2.ZERO, waiting.get_size()).encloses(Rect2(box[0], box[1], box[2], box[3])), "waiting frame bounds")
			actor.state = &"walking"
			check(HotelArt.character(actor) == walking, "leaving queue restores walking")
			actor.state = &"checkin"
		if actor.role not in [&"cleaner", &"receptionist"]:
			continue
		var walk_texture := HotelArt.character(actor)
		actor.state = &"cleaning" if actor.role == &"cleaner" else &"working"
		var work_texture := HotelArt.character(actor)
		check(work_texture != walk_texture, "dedicated work texture")
		check(work_texture.get_image().detect_alpha() != Image.ALPHA_NONE, "work alpha")
		check(HotelArt.character_region(actor, 0) != HotelArt.character_region(actor, 4), "work advances")
		check(HotelArt.character_region(actor, 0) == HotelArt.character_region(actor, 16), "work loops")
		for box: Array in HotelArt.character_regions(actor):
			check(Rect2(Vector2.ZERO, work_texture.get_size()).encloses(Rect2(box[0], box[1], box[2], box[3])), "work frame bounds")
		actor.state = &"idle"
		var idle_texture := HotelArt.character(actor)
		check(idle_texture != walk_texture and idle_texture != work_texture, "idle has dedicated staff texture")
		check(idle_texture.get_image().detect_alpha() != Image.ALPHA_NONE, "staff idle alpha")
		for state: StringName in HotelArt.STAFF_IDLE_STATES:
			actor.state = state
			check(HotelArt.character(actor) == idle_texture, "idle and lift queue share calm posture")
			check(HotelArt.character_regions(actor).size() == 4, "staff idle four poses")
			check(HotelArt.character_region(actor, 0) != HotelArt.character_region(actor, 16), "staff idle advances")
			check(HotelArt.character_region(actor, 0) == HotelArt.character_region(actor, 64), "staff idle loops")
			var scale := HotelArt.character_scale(actor)
			check(is_equal_approx(scale, 46.0 / (722.0 if actor.role == &"cleaner" else 813.0)), "staff idle shared scale")
			for tick: int in [0, 16, 32, 48]:
				var region := HotelArt.character_region(actor, tick)
				var anchor := HotelArt.character_anchor(actor, tick)
				check(Rect2(Vector2.ZERO, idle_texture.get_size()).encloses(region), "staff idle frame bounds")
				check(Rect2(Vector2.ZERO, region.size).has_point(anchor), "staff idle shoe anchor inside frame")
				check(is_equal_approx(anchor.y, region.size.y - 4), "staff idle shoes keep four pixel padding")
		actor.state = &"walking"
		check(HotelArt.character(actor) == walk_texture, "staff movement restores walk")
		actor.state = &"cleaning" if actor.role == &"cleaner" else &"working"
		check(HotelArt.character(actor) == work_texture, "staff assignment restores work")
	var resting_staff: Array[ActorState] = []
	for role: StringName in HotelArt.STAFF_IDLE_ROLES:
		for state: StringName in HotelArt.STAFF_IDLE_STATES:
			var employee := session.spawn_guest()
			employee.role = role
			employee.state = state
			employee.floor_index = 1
			employee.x = 10.5 + resting_staff.size() * 0.8
			resting_staff.append(employee)
	# Service cycles are contextual: cups must never appear in other rooms.
	for profile: StringName in [&"balanced", &"business", &"leisure"]:
		var guest := session.spawn_guest()
		guest.archetype_id = profile
		guest.state = &"using"
		var pose := HotelArt.character(guest, &"cafe")
		check(pose != HotelArt.character(guest, &"bedroom"), "cafe pose is service specific")
		check(pose.get_image().detect_alpha() != Image.ALPHA_NONE, "cafe pose has alpha")
		check(HotelArt.character_regions(guest, &"cafe").size() == 4, "four cafe frames")
		check(HotelArt.character_region(guest, 0, &"cafe") != HotelArt.character_region(guest, 8, &"cafe"), "cafe gesture advances")
		check(HotelArt.character_region(guest, 0, &"cafe") == HotelArt.character_region(guest, 32, &"cafe"), "cafe gesture loops")
		var foot_height := -1.0
		for tick: int in [0, 8, 16, 24]:
			var region := HotelArt.character_region(guest, tick, &"cafe")
			var anchor := HotelArt.character_anchor(guest, tick, &"cafe")
			check(Rect2(Vector2.ZERO, pose.get_size()).encloses(region), "cafe frame bounds")
			check(Rect2(Vector2.ZERO, region.size).has_point(anchor), "cafe anchor inside frame")
			var height := anchor.y * HotelArt.character_scale(guest, &"cafe")
			check(foot_height < 0.0 or is_equal_approx(foot_height, height), "shared cafe foot baseline")
			foot_height = height
		for room: RoomState in session.hotel.rooms:
			if room.definition_id == &"cafe":
				guest.target_room = room.id
			guest.x = 5.8 + [&"balanced", &"business", &"leisure"].find(profile) * 0.6
	var readers: Array[ActorState] = []
	var lounge: RoomState = session.hotel.room_at(8, 0)
	for profile: StringName in [&"balanced", &"business", &"leisure"]:
		var guest := session.spawn_guest()
		guest.archetype_id = profile
		guest.state = &"using"
		guest.target_room = lounge.id
		guest.x = lounge.center()
		lounge.users.append(guest.id)
		readers.append(guest)
		var reading := HotelArt.character(guest, &"lounge")
		check(reading != HotelArt.character(guest, &"cafe"), "lounge has distinct reading art")
		check(reading != HotelArt.character(guest, &"bedroom"), "reading art is lounge specific")
		check(reading.get_image().detect_alpha() != Image.ALPHA_NONE, "reading has real alpha")
		check(HotelArt.character_regions(guest, &"lounge").size() == 4, "four reading frames")
		check(HotelArt.character_region(guest, 0, &"lounge") != HotelArt.character_region(guest, 12, &"lounge"), "page turn advances")
		check(HotelArt.character_region(guest, 0, &"lounge") == HotelArt.character_region(guest, 48, &"lounge"), "page turn loops")
		var baseline := -1.0
		for tick: int in [0, 12, 24, 36]:
			var region := HotelArt.character_region(guest, tick, &"lounge")
			var anchor := HotelArt.character_anchor(guest, tick, &"lounge")
			check(Rect2(Vector2.ZERO, reading.get_size()).encloses(region), "reading frame contained")
			check(Rect2(Vector2.ZERO, region.size).has_point(anchor), "reading anchor contained")
			check(is_equal_approx(region.size.y * HotelArt.character_scale(guest, &"lounge"), 36.0), "seated readers lower than standing guests")
			check(baseline < 0.0 or is_equal_approx(baseline, anchor.y), "reading baseline stable")
			baseline = anchor.y
		guest.state = &"service_queue"
		check(HotelArt.character(guest, &"lounge") != reading, "leaving seat restores waiting art")
		guest.state = &"using"
	for actor: ActorState in session.actors.values():
		if actor.role == &"cleaner" and actor.state == &"cleaning":
			actor.floor_index = 2
			actor.x = 7.5
		if actor.role == &"guest" and actor.state == &"checkin":
			actor.floor_index = 1
	var diners: Array[ActorState] = []
	for room: RoomState in session.hotel.rooms:
		if room.definition_id != &"restaurant":
			continue
		for slot in room.capacity():
			var guest := session.spawn_guest()
			guest.archetype_id = [&"balanced", &"business", &"leisure"][slot % 3]
			guest.state = &"using"
			guest.x = room.center()
			guest.floor_index = room.floor_index
			guest.target_room = room.id
			room.users.append(guest.id)
			diners.append(guest)
			var dining := HotelArt.character(guest, &"restaurant")
			check(dining != HotelArt.character(guest, &"lounge") and dining != HotelArt.character(guest, &"cafe"), "meal art is service specific")
			check(dining.get_image().detect_alpha() != Image.ALPHA_NONE, "dining alpha")
			check(HotelArt.character_regions(guest, &"restaurant").size() == 4, "four meal frames")
			check(HotelArt.character_region(guest, 0, &"restaurant") != HotelArt.character_region(guest, 6, &"restaurant"), "fork gesture advances")
			check(HotelArt.character_region(guest, 0, &"restaurant") == HotelArt.character_region(guest, 24, &"restaurant"), "meal loop")
			var baseline := -1.0
			for tick: int in [0, 6, 12, 18]:
				var region := HotelArt.character_region(guest, tick, &"restaurant")
				var anchor := HotelArt.character_anchor(guest, tick, &"restaurant")
				check(Rect2(Vector2.ZERO, dining.get_size()).encloses(region), "meal frame contained")
				check(Rect2(Vector2.ZERO, region.size).has_point(anchor), "meal anchor contained")
				check(is_equal_approx(region.size.y * HotelArt.character_scale(guest, &"restaurant"), 36.0), "seated dining height")
				check(baseline < 0.0 or is_equal_approx(baseline, anchor.y), "meal baseline stable")
				baseline = anchor.y
			guest.state = &"service_queue"
			check(HotelArt.character(guest, &"restaurant") != dining, "meal art ends in queue")
			guest.state = &"using"
	# Each profile sleeps in each bed level; room occupancy is explicit in the fixture.
	session.hotel.add_floor()
	session.hotel.add_floor()
	var sleepers: Array[ActorState] = []
	for entry: Array in [[0, 1, 3, &"balanced"], [2, 1, 2, &"business"], [4, 1, 1, &"leisure"], [0, 3, 1, &"balanced"], [2, 3, 1, &"business"], [4, 3, 3, &"leisure"], [0, 4, 2, &"balanced"], [2, 4, 3, &"business"], [4, 4, 2, &"leisure"]]:
		var room: RoomState = session.hotel.room_at(entry[0], entry[1])
		if room == null:
			room = session.hotel.build(HotelCatalog.room(&"bedroom"), entry[0], entry[1])
			while room.level < entry[2]:
				check(session.upgrade_room(room.id).is_empty(), "sleep showcase upgrade")
		var guest := session.spawn_guest()
		guest.archetype_id = entry[3]
		guest.state = &"using"
		guest.floor_index = room.floor_index
		guest.x = room.center()
		guest.target_room = room.id
		guest.bedroom = room.id
		guest.checked_in = true
		room.occupant = guest.id
		room.users.append(guest.id)
		sleepers.append(guest)
		var texture := HotelArt.character(guest, &"bedroom")
		check(texture != HotelArt.character(guest, &"lounge"), "sleep is bedroom specific")
		check(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "sleeper alpha")
		check(HotelArt.character_regions(guest, &"bedroom").size() == 4, "four sleep breathing poses")
		check(HotelArt.character_region(guest, 0, &"bedroom") != HotelArt.character_region(guest, 12, &"bedroom"), "sleep breathing advances")
		check(HotelArt.character_region(guest, 0, &"bedroom") == HotelArt.character_region(guest, 48, &"bedroom"), "sleep breathing loops")
		var maximum_width := 0.0
		for tick: int in [0, 12, 24, 36]:
			var region := HotelArt.character_region(guest, tick, &"bedroom")
			var scale := HotelArt.character_scale(guest, &"bedroom")
			maximum_width = maxf(maximum_width, region.size.x * scale)
			check(Rect2(Vector2.ZERO, texture.get_size()).encloses(region), "sleep region contained")
			check(region.size.x * scale >= 50.0 and region.size.x * scale <= 52.01, "sleep width stable across poses")
			check(HotelArt.character_anchor(guest, tick, &"bedroom").y == region.size.y, "sleep blanket bottom anchored")
		check(is_equal_approx(maximum_width, 52.0), "sleep maximum width fits painted bed")
		guest.state = &"walking"
		check(HotelArt.character(guest, &"bedroom") != texture, "waking restores base sprite")
		guest.state = &"using"
	session.speed = 0
	for room: RoomState in session.hotel.rooms:
		if room.definition().category == &"lodging" and room.column == 8:
			room.dirty = true
	game._replace_session(session)
	var before := SessionSnapshot.capture(session)
	game.view.zoom_factor = 0.9
	for frame in 4:
		await process_frame
	var previous_seat := -INF
	for reader: ActorState in readers:
		var point: Vector2 = game.view.actor_screen_position(reader)
		check(point.x > previous_seat + 28 * game.view.zoom_factor, "lounge seats separately pickable")
		previous_seat = point.x
		await click(root, point + game.view.global_position)
		check(game.selected_actor == reader.id, "click selects the reader at its drawn seat")
	check(SessionSnapshot.capture(session) == before, "seat layout and selection leave session unchanged")
	for diner: ActorState in diners:
		await click(root, game.view.actor_screen_position(diner) + game.view.global_position)
		check(game.selected_actor == diner.id, "diner selected at drawn seat, including upgraded rooms")
	check(SessionSnapshot.capture(session) == before, "diner selection leaves session unchanged")
	for sleeper: ActorState in sleepers:
		await click(root, game.view.actor_screen_position(sleeper) + game.view.global_position)
		check(game.selected_actor == sleeper.id, "sleeping guest picked on actual bed at every level")
	check(SessionSnapshot.capture(session) == before, "sleep selection leaves session unchanged")
	for zoom: float in [0.35, 0.9, 1.8]:
		game.view.zoom_factor = zoom
		game.view.pan = Vector2.ZERO
		for sleeper: ActorState in sleepers:
			var room := session.hotel.by_id(sleeper.target_room)
			var bed: Rect2 = game.view.room_rect(room.column, room.floor_index, room.definition().width)
			var point: Vector2 = game.view.actor_screen_position(sleeper)
			for tick: int in [0, 12, 24, 36]:
				var region := HotelArt.character_region(sleeper, tick, &"bedroom")
				var scale: float = HotelArt.character_scale(sleeper, &"bedroom") * zoom
				var anchor := HotelArt.character_anchor(sleeper, tick, &"bedroom")
				var pose := Rect2(point + Vector2(0, 17 * zoom) - anchor * scale, region.size * scale)
				check(bed.encloses(pose), "all sleep breathing poses stay in bedroom")
				check(pose.get_center().y < bed.end.y - 30 * zoom, "breathing sleeper stays on mattress above floor")
		for room: RoomState in session.hotel.rooms:
			if room.definition_id != &"restaurant":
				continue
			var room_bounds: Rect2 = game.view.room_rect(room.column, room.floor_index, room.definition().width)
			var previous_right := -INF
			for id: int in room.users:
				var diner: ActorState = session.actors[id]
				var point: Vector2 = game.view.actor_screen_position(diner)
				var left := INF
				var right := -INF
				var scale: float = HotelArt.character_scale(diner, &"restaurant") * zoom
				for tick: int in [0, 6, 12, 18]:
					var region := HotelArt.character_region(diner, tick, &"restaurant")
					var anchor := HotelArt.character_anchor(diner, tick, &"restaurant")
					left = minf(left, point.x - anchor.x * scale)
					right = maxf(right, point.x + (region.size.x - anchor.x) * scale)
				check(left > previous_right + 2 * zoom, "full restaurant has separated silhouettes at every level and phase")
				check(left >= room_bounds.position.x and right <= room_bounds.end.x, "all restaurant seats stay inside room")
				previous_right = right
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.runtime/m7-art-%.2f.png" % zoom)
	check(preload("res://tests/snapshot_comparison.gd").difference(before, SessionSnapshot.capture(session), "art").is_empty(), "rendering and animation do not mutate simulation")
	# Seed each visual phase in the paused fixture, then verify the real renderer.
	game.view.zoom_factor = 1.8
	for tick: int in [0, 8, 16, 24]:
		session.tick_count = tick
		session.time = tick * session.rules.tick
		var phase_before := SessionSnapshot.capture(session)
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.runtime/m7-cafe-frame-%d.png" % (tick / 8))
		check(preload("res://tests/snapshot_comparison.gd").difference(phase_before, SessionSnapshot.capture(session), "cafe").is_empty(), "paused cafe frame leaves simulation unchanged")
	session.tick_count = before["session"]["tick_count"]
	session.time = before["session"]["time"]
	# Pan the upper restaurants into view to inspect full N2 and N3 dining rooms.
	game.view.pan = Vector2(400, 150)
	for tick: int in [0, 6, 12, 18]:
		session.tick_count = tick
		session.time = tick * session.rules.tick
		var phase_before := SessionSnapshot.capture(session)
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.runtime/m7-dining-frame-%d.png" % (tick / 6))
		check(SessionSnapshot.capture(session) == phase_before, "paused dining does not mutate session")
	session.tick_count = before["session"]["tick_count"]
	session.time = before["session"]["time"]
	game.view.pan = Vector2.ZERO
	for tick: int in [0, 12, 24, 36]:
		session.tick_count = tick
		session.time = tick * session.rules.tick
		var phase_before := SessionSnapshot.capture(session)
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.runtime/m7-reading-frame-%d.png" % (tick / 12))
		check(SessionSnapshot.capture(session) == phase_before, "paused reading does not mutate session")
	session.tick_count = before["session"]["tick_count"]
	session.time = before["session"]["time"]
	var old_audio: bool = game.audio.enabled
	game.view.pan = Vector2(-400, 0)
	for tick: int in [0, 16, 32, 48]:
		session.tick_count = tick
		session.time = tick * session.rules.tick
		var phase_before := SessionSnapshot.capture(session)
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.runtime/m7-staff-idle-frame-%d.png" % (tick / 16))
		for employee: ActorState in resting_staff:
			await click(root, game.view.actor_screen_position(employee) + game.view.global_position)
			check(game.selected_actor == employee.id, "resting %s %s selected at rendered position" % [employee.role, employee.state])
		check(SessionSnapshot.capture(session) == phase_before, "paused staff idle and selection do not mutate session")
	session.tick_count = before["session"]["tick_count"]
	session.time = before["session"]["time"]
	game.view.pan = Vector2(400, 400)
	var sleep_samples: Dictionary = {}
	for tick: int in [0, 12, 24, 36]:
		session.tick_count = tick
		session.time = tick * session.rules.tick
		var phase_before := SessionSnapshot.capture(session)
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var capture := root.get_texture().get_image()
		capture.save_png("res://.runtime/m7-sleeping-loop-frame-%d.png" % (tick / 12))
		for sleeper: ActorState in sleepers:
			var room := session.hotel.by_id(sleeper.target_room)
			var bed: Rect2 = game.view.room_rect(room.column, room.floor_index, room.definition().width)
			if not Rect2(Vector2.ZERO, game.view.size).encloses(bed):
				continue
			if not sleep_samples.has(sleeper.id):
				sleep_samples[sleeper.id] = []
			sleep_samples[sleeper.id].append(capture.get_region(Rect2i(bed.position + game.view.global_position, bed.size)).get_data())
		check(SessionSnapshot.capture(session) == phase_before, "paused sleep breathing leaves session unchanged")
	check(sleep_samples.size() == 6, "six complete beds visible in breathing preview")
	for frames: Array in sleep_samples.values():
		check(frames.size() == 4, "bed preview covers all breathing phases")
		check(frames[0] != frames[1] or frames[0] != frames[2] or frames[0] != frames[3], "breathing changes actual rendered bed pixels")
	session.tick_count = before["session"]["tick_count"]
	session.time = before["session"]["time"]
	check(SessionSnapshot.capture(session) == before, "sleep composition leaves session unchanged")
	game.view.pan = Vector2.ZERO
	await click(root, game.hud.audio_button.get_global_rect().get_center())
	check(game.audio.enabled != old_audio, "audio button toggles")
	var probe := HotelAudio.new()
	root.add_child(probe)
	check(probe.enabled == game.audio.enabled, "audio preference persisted")
	probe.queue_free()
	await click(root, game.hud.audio_button.get_global_rect().get_center())
	check(game.audio.enabled == old_audio, "audio restored")
	for cue: StringName in HotelAudio.SOUNDS:
		check(HotelAudio.SOUNDS[cue].get_length() > 0.1, "audio asset loads")
	await housekeeping_art()
	print(JSON.stringify({"suite": "ui_art", "failures": failures, "rooms": HotelArt.ROOMS.size(), "characters": HotelArt.CHARACTERS.size()}))
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)

func housekeeping_art() -> void:
	var session := HotelSession.new(612)
	session.progression.completed.assign([&"first_stays", &"steady_service"])
	session.economy.cash = 100000
	session.hotel.add_floor()
	var dirty_rooms: Array[RoomState] = []
	for level in range(1, 4):
		for floor_index in 2:
			var room := session.hotel.build(HotelCatalog.room(&"bedroom"), 3 + level * 2, floor_index)
			for upgrade_index in range(1, level):
				check(session.upgrade_room(room.id).is_empty(), "housekeeping actual room upgrade")
			room.dirty = floor_index == 0
			var texture := HotelArt.room_state(room)
			check(texture == HotelArt.DIRTY_BEDROOMS[level - 1] if room.dirty else texture == HotelArt.room(&"bedroom", level), "painting follows level and dirty state")
			check(texture.get_size() == HotelArt.room(&"bedroom", level).get_size(), "dirty painting preserves source dimensions")
			if room.dirty:
				dirty_rooms.append(room)
				var cleaner := session.spawn_guest()
				cleaner.role = &"cleaner"
				cleaner.state = &"cleaning"
				cleaner.assignment = room.id
				cleaner.x = room.center()
				cleaner.timer = 0.05
				room.cleaning_by = cleaner.id
	var reception := session.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
	reception.dirty = true
	check(HotelArt.room_state(reception) == HotelArt.room(&"reception"), "other room types retain their normal painting")
	reception.dirty = false
	session.speed = 0
	var view := HotelView.new()
	root.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.session = session
	view.hotel = session.hotel
	var before := SessionSnapshot.capture(session)
	for zoom: float in [0.35, 0.9, 1.8]:
		view.zoom_factor = zoom
		view.queue_redraw()
		for frame in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.runtime/m7-housekeeping-%s.png" % zoom)
		check(SessionSnapshot.capture(session) == before, "housekeeping render preserves state")
	var path := "user://housekeeping-art-save.json"
	check(SaveStore.save_session(session, path).is_empty(), "housekeeping save")
	var restored := SaveStore.load_session(path)
	check(restored.error.is_empty(), "housekeeping load")
	if restored.error.is_empty():
		for room: RoomState in dirty_rooms:
			check(HotelArt.room_state(restored.session.hotel.by_id(room.id)) == HotelArt.room_state(room), "dirty room painting survives save load")
	session.employees.step(session.actors, session.hotel, session.transport, 0.1)
	check(session.employees.cleaned == 3, "real employee completion cleans all levels")
	for room: RoomState in dirty_rooms:
		check(not room.dirty and room.cleaning_by == -1, "employee resets dirty state")
		check(HotelArt.room_state(room) == HotelArt.room(&"bedroom", room.level), "cleaning restores clean painting at same level")
	view.queue_redraw()
	for frame in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.runtime/m7-housekeeping-cleaned.png")
	view.queue_free()
	await process_frame
