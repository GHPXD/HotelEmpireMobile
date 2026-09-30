extends "res://tests/ui_management.gd"

func run() -> void:
	var session := SimulationRunner.make_hotel(765, "tower", 1000000)
	session.progression.completed.assign([&"first_stays", &"steady_service"])
	var view := HotelView.new()
	root.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.hotel = session.hotel
	view.session = session
	view.selected = session.hotel.rooms[0].id
	for index in 120:
		var actor := session.spawn_guest()
		actor.x = float(index % 20) * 0.8
		actor.floor_index = index % 20
		actor.state = &"walking" if index % 2 else &"checkin"
		actor.target_x = 0
		if index % 5 == 0:
			actor.role = &"cleaner"
			actor.state = [&"cleaning", &"idle", &"lift_queue"][index / 5 % 3]
		elif index % 5 == 1:
			actor.role = &"receptionist"
			actor.state = [&"working", &"idle", &"lift_queue"][index / 5 % 3]
	for column: int in [0, 2, 4]:
		check(session.hotel.demolish(session.hotel.room_at(column, 1).id).is_empty(), "clear service showcase space")
	var lounge := session.hotel.build(HotelCatalog.room(&"lounge"), 0, 1)
	var cafe := session.hotel.build(HotelCatalog.room(&"cafe"), 4, 1)
	check(lounge != null and cafe != null, "unlocked service rooms built")
	if lounge == null or cafe == null:
		view.queue_free()
		await process_frame
		quit(1)
		return
	var restaurant := session.hotel.room_at(6, 0)
	check(session.upgrade_room(restaurant.id).is_empty(), "restaurant N2 for culling")
	check(session.upgrade_room(restaurant.id).is_empty(), "restaurant N3 for culling")
	for room: RoomState in [lounge, cafe, restaurant]:
		for slot in room.capacity():
			var actor := session.spawn_guest()
			actor.archetype_id = [&"balanced", &"business", &"leisure"][slot % 3]
			actor.state = &"using"
			actor.target_room = room.id
			actor.x = room.center()
			actor.floor_index = room.floor_index
			room.users.append(actor.id)
	for slot in 3:
		var room := session.hotel.room_at(slot * 2, 2)
		while room.level < slot + 1:
			check(session.upgrade_room(room.id).is_empty(), "sleep bed level for culling")
		var actor := session.spawn_guest()
		actor.archetype_id = [&"balanced", &"business", &"leisure"][slot]
		actor.state = &"using"
		actor.x = room.center()
		actor.floor_index = room.floor_index
		actor.target_room = room.id
		actor.bedroom = room.id
		actor.checked_in = true
		room.users.append(actor.id)
		room.occupant = actor.id
	for room: RoomState in session.hotel.rooms:
		if room.definition().category == &"lodging":
			room.dirty = true
	var before := SessionSnapshot.capture(session)
	for zoom: float in [0.35, 1.0, 1.8]:
		for offset: Vector2 in [Vector2.ZERO, Vector2(431, 817), Vector2(-516, 1579)]:
			view.zoom_factor = zoom
			view.pan = offset
			view.cull_offscreen = false
			view.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var reference: PackedByteArray = root.get_texture().get_image().get_data()
			view.cull_offscreen = true
			view.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			check(reference == root.get_texture().get_image().get_data(), "pixel equivalence zoom %s pan %s" % [zoom, offset])
	check(preload("res://tests/snapshot_comparison.gd").difference(before, SessionSnapshot.capture(session), "culling").is_empty(), "culling does not mutate gameplay")
	print(JSON.stringify({"suite": "ui_culling", "failures": failures, "camera_cases": 9}))
	view.queue_free()
	await process_frame
	quit(1 if failures else 0)
