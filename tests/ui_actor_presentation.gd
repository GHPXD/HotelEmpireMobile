extends "res://tests/ui_management.gd"
## Real viewport clicks, sprite/badge separation and nearby actor selection.

var selected_id: int = -1

func run() -> void:
	var session := HotelSession.new(418)
	session.economy.cash = 100000
	for floor_index in 2:
		session.hotel.add_floor()
	for floor_index in 3:
		for entry in [[&"reception", 0], [&"cafe", 3], [&"lounge", 5], [&"restaurant", 8], [&"bedroom", 12]]:
			session.hotel.build(HotelCatalog.room(entry[0]), entry[1], floor_index)
	var waiting: Array[ActorState] = []
	for profile: StringName in [&"balanced", &"business", &"leisure"]:
		for state: StringName in HotelView.WAITING_STATES:
			var actor := session.spawn_guest()
			actor.archetype_id = profile
			actor.state = state
			waiting.append(actor)
	for role: StringName in HotelArt.STAFF_IDLE_ROLES:
		var actor := session.spawn_guest()
		actor.role = role
		actor.state = &"lift_queue"
		waiting.append(actor)
	for index in waiting.size():
		waiting[index].floor_index = index / 4
		waiting[index].x = 2.0 + (index % 4) * 3.5
	var neighbors: Array[ActorState] = []
	for index in 2:
		var actor := session.spawn_guest()
		actor.archetype_id = &"balanced"
		actor.state = &"checkin"
		actor.floor_index = 2
		# Deliberately only five base pixels apart, including the existing wait offset.
		actor.x = 12.6 + index * 0.08 - (actor.id % 5) * 0.13
		neighbors.append(actor)
	session.speed = 0
	var view := HotelView.new()
	root.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.session = session
	view.hotel = session.hotel
	view.actor_clicked.connect(func(id: int) -> void: selected_id = id)
	for frame in 4:
		await process_frame
	var before := SessionSnapshot.capture(session)
	for zoom: float in [0.35, 0.9, 1.8]:
		view.zoom_factor = zoom
		for actor: ActorState in waiting:
			for phase in 4:
				session.tick_count = phase * (12 if actor.role == &"guest" else 16)
				var sprite := view.actor_sprite_rect(actor)
				var badge := view.actor_wait_badge_rect(actor)
				check(badge.has_area(), "waiting has visible status")
				check(not badge.intersects(sprite), "status never covers sprite at any phase or zoom")
				check(badge.end.y <= sprite.position.y - 3.9 * zoom, "status keeps scaled gap above hair")
			session.tick_count = 0
			view.queue_redraw()
			await process_frame
			var face := view.actor_sprite_rect(actor).get_center()
			face.y -= view.actor_sprite_rect(actor).size.y * 0.3
			check(face.distance_to(view.actor_screen_position(actor)) > 14 * zoom, "face is outside former point-only hit radius")
			await click(root, face)
			check(selected_id == actor.id, "face click selects %s %s at zoom %s" % [actor.role, actor.state, zoom])
		for actor: ActorState in neighbors:
			await click(root, view.actor_screen_position(actor))
			check(selected_id == actor.id, "nearest actor selectable in overlapping queue")
		check(SessionSnapshot.capture(session) == before, "presentation and clicks preserve authoritative state")
	# Exact overlap follows paint order, independent of dictionary's first entry.
	var original_x := neighbors[1].x
	neighbors[1].x = neighbors[0].x + (neighbors[0].id % 5 - neighbors[1].id % 5) * 0.13
	await click(root, view.actor_screen_position(neighbors[0]))
	check(selected_id == neighbors[1].id, "equal-position tie selects last painted actor")
	neighbors[1].x = original_x
	for phase in 4:
		session.tick_count = phase * 12
		view.queue_redraw()
		var phase_before := SessionSnapshot.capture(session)
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.runtime/m7-queue-presentation-%d.png" % phase)
		check(SessionSnapshot.capture(session) == phase_before, "paused presentation stays unchanged")
	session.tick_count = 0
	check(SessionSnapshot.capture(session) == before, "fixture restored after phase inspection")
	await registered_queues(view)
	await luggage_travel(view)
	print(JSON.stringify({"suite": "ui_actor_presentation", "failures": failures, "waiting_contexts": waiting.size(), "zooms": 3, "phases": 4}))
	view.queue_free()
	await process_frame
	quit(1 if failures else 0)

func luggage_travel(view: HotelView) -> void:
	var session := HotelSession.new(712)
	session.speed = 0
	view.session = session
	view.hotel = session.hotel
	for profile: StringName in [&"balanced", &"business", &"leisure"]:
		session.actors.clear()
		var actor := session.spawn_guest()
		actor.archetype_id = profile
		actor.x = 5
		session.guests._arrive(actor, [])
		check(actor.destination_state == &"exit" and HotelArt.travelling_with_luggage(actor), "rejected arrival exits with luggage")
		actor.state = &"deciding"
		actor.age = 10000
		session.guests._choose(actor, session.hotel, session.transport)
		check(actor.destination_state == &"exit" and HotelArt.travelling_with_luggage(actor), "stay completion selects travel art")
		var reception := session.hotel.by_id(1)
		if reception == null:
			reception = session.hotel.build(HotelCatalog.room(&"reception"), 3, 0)
		actor.state = &"arriving"
		session.guests._arrive(actor, [reception])
		check(actor.destination_state == &"checkin" and HotelArt.travelling_with_luggage(actor), "real reception arrival selects travel art")
		reception.queue.leave(actor.id)
		for destination: StringName in [&"checkin", &"exit"]:
			actor.destination_state = destination
			for state: StringName in [&"walking", &"lift_queue", &"riding"]:
				actor.state = state
				check(HotelArt.animation_id(actor) == StringName("%s-travel" % profile), "travel context retains luggage")
				if state != &"walking":
					check(HotelArt.character_frame(actor, 0) == HotelArt.character_frame(actor, 99), "stationary luggage pose does not walk")
		actor.state = &"checkin"
		check(HotelArt.animation_id(actor) == StringName("%s-waiting" % profile), "reception service retains wait animation")
		actor.state = &"walking"
		actor.destination_state = &"checkin"
		actor.checked_in = true
		check(not HotelArt.travelling_with_luggage(actor), "stale checkin destination does not show luggage after admission")
		actor.checked_in = false
		actor.destination_state = &"service_queue"
		check(HotelArt.animation_id(actor) == profile, "internal service trip uses base walk")
		actor.destination_state = &"exit"
		var texture := HotelArt.character(actor)
		check(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "travel texture has alpha")
		for zoom: float in [0.35, 0.9, 1.8]:
			view.zoom_factor = zoom
			view.pan = Vector2.ZERO
			view.pan += view.size * 0.5 - view.actor_screen_position(actor)
			for direction: int in [-1, 1]:
				actor.target_x = actor.x + direction
				for phase in 4:
					session.tick_count = phase
					session.time = phase * session.rules.tick
					var before := SessionSnapshot.capture(session)
					var region := HotelArt.character_region(actor, phase)
					var anchor := HotelArt.character_anchor(actor, phase)
					var scale := HotelArt.character_scale(actor) * zoom
					var sprite := view.actor_sprite_rect(actor)
					var reflected := Vector2(region.size.x - anchor.x, anchor.y) if direction < 0 else anchor
					check((sprite.position + reflected * scale).distance_to(view.actor_screen_position(actor) + Vector2(0, 17 * zoom)) < 0.001, "mirrored shoe anchor remains on actor floor point")
					check(Rect2(Vector2.ZERO, texture.get_size()).encloses(region), "travel source rectangle within texture")
					await click(root, sprite.get_center())
					check(selected_id == actor.id, "travel body is selectable")
					var luggage := sprite.position + sprite.size * Vector2(0.9 if direction < 0 else 0.1, 0.85)
					await click(root, luggage)
					check(selected_id == actor.id, "travel luggage is selectable in either direction")
					check(SessionSnapshot.capture(session) == before, "paused travel render and input preserve simulation")
					if phase == 0:
						view.cull_offscreen = false
						view.queue_redraw()
						await process_frame
						await RenderingServer.frame_post_draw
						var full := root.get_texture().get_image()
						view.cull_offscreen = true
						view.queue_redraw()
						await process_frame
						await RenderingServer.frame_post_draw
						var culled := root.get_texture().get_image()
						check(full.get_data() == culled.get_data(), "luggage culling preserves visible pixels")
						if zoom == 1.8:
							culled.save_png("res://.runtime/m7-travel-%s-%d.png" % [profile, direction])
		var restored := SessionSnapshot.restore(SessionSnapshot.capture(session))
		check(restored.error.is_empty(), "travel context snapshot restores: %s" % restored.error)
		if restored.error.is_empty():
			var loaded: ActorState = restored.session.actors[actor.id]
			check(HotelArt.animation_id(loaded) == HotelArt.animation_id(actor), "luggage context restored without schema changes")
	print(JSON.stringify({"travel_profiles": 3, "travel_directions": 2, "travel_phases": 4, "travel_zooms": 3, "failures": failures}))

func registered_queues(view: HotelView) -> void:
	var session := HotelSession.new(511)
	session.progression.completed.assign([&"first_stays"])
	for floor_index in 3:
		session.hotel.add_floor()
	var reception := session.hotel.build(HotelCatalog.room(&"reception"), 3, 0)
	var cafe := session.hotel.build(HotelCatalog.room(&"cafe"), 8, 1)
	session.hotel.build(HotelCatalog.room(&"elevator"), 15, 0)
	session.transport.sync(session.hotel)
	var lift: ElevatorState = session.transport.lifts[0]
	var arrived: Array[ActorState] = []
	for room: RoomState in [reception, cafe]:
		var members: Array[ActorState] = []
		for index in 12:
			var actor := session.spawn_guest()
			actor.archetype_id = [&"balanced", &"business", &"leisure"][index % 3]
			actor.state = &"checkin" if room == reception else &"service_queue"
			actor.floor_index = room.floor_index
			actor.target_floor = room.floor_index
			actor.target_room = room.id
			actor.x = room.center()
			actor.waiting = 1.0
			members.append(actor)
		# Reverse IDs: visible order must follow reservations, never ID arithmetic.
		members.reverse()
		for actor: ActorState in members:
			check(room.queue.join(actor.id), "reserve room queue")
			arrived.append(actor)
		# Reception reserves places before arrival; retain that gap in the layout.
		if room == reception:
			members[4].state = &"walking"
			arrived.erase(members[4])
	for index in 10:
		var actor := session.spawn_guest()
		actor.state = &"lift_queue"
		actor.elevator_id = lift.room_id
		actor.floor_index = 2 if index % 3 else 3
		actor.x = lift.column
		actor.waiting = 1.0
		if index < 2:
			actor.role = &"cleaner" if index == 0 else &"receptionist"
		lift.queue.join(actor.id)
		arrived.append(actor)
	session.speed = 0
	view.session = session
	view.hotel = session.hotel
	var before := SessionSnapshot.capture(session)
	var projected := HotelQueueProjection.build(session, view.CELL, view.FLOOR_HEIGHT)
	check(projected.groups.size() == 4, "two room queues and two lift floors")
	check(projected.positions.size() == 33, "walk reservation has no waiting sprite position")
	for group: Dictionary in projected.groups:
		var ids: Array[int] = []
		if group.kind == &"room":
			ids.assign(session.hotel.by_id(group.owner_id).queue.members)
		else:
			for id: int in lift.queue.members:
				if session.actors[id].floor_index == group.floor:
					ids.append(id)
		check(group.count == ids.size(), "aggregate counts reservations per group")
		var previous := INF if group.kind == &"lift" else -INF
		for id: int in ids:
			if not projected.positions.has(id):
				continue
			var point: Vector2 = projected.positions[id]
			check(point.x < previous if group.kind == &"lift" else point.x > previous, "FIFO anchors are distinct and ordered")
			previous = point.x
			check(point.x > 0 and point.x < HotelModel.COLUMNS * view.CELL, "queue stays inside hotel")
			check(point == HotelQueueProjection.position_for(session, session.actors[id], view.CELL, view.FLOOR_HEIGHT), "single query matches batched projection")
	# Entry uses existing elapsed wait; paused drawing has no private animation clock.
	var first: ActorState = arrived[0]
	var target: Vector2 = projected.positions[first.id]
	first.waiting = 0
	var entry := HotelQueueProjection.position_for(session, first, view.CELL, view.FLOOR_HEIGHT)
	check(entry == Vector2((first.x + (first.id % 5) * 0.13) * view.CELL, -first.floor_index * view.FLOOR_HEIGHT - 20), "entry starts at arrival anchor")
	first.waiting = 0.2
	check(HotelQueueProjection.position_for(session, first, view.CELL, view.FLOOR_HEIGHT).is_equal_approx(entry.lerp(target, 0.5)), "entry interpolation halfway")
	first.waiting = 1.0
	# Opposite-edge elevator points inward too.
	var old_column := lift.column
	lift.column = 0.5
	var left := HotelQueueProjection.build(session, view.CELL, view.FLOOR_HEIGHT)
	var previous := -INF
	for id: int in lift.queue.members:
		if session.actors[id].floor_index != 2:
			continue
		var point: Vector2 = left.positions[id]
		check(point.x > previous and point.x < HotelModel.COLUMNS * view.CELL, "left-edge lift FIFO points inward")
		previous = point.x
	lift.column = old_column
	for zoom: float in [0.35, 0.9, 1.8]:
		view.zoom_factor = zoom
		for actor: ActorState in arrived:
			view.pan = Vector2.ZERO
			view.pan += view.size / 2 - view.actor_screen_position(actor)
			view.queue_redraw()
			await process_frame
			check(not view.actor_wait_badge_rect(actor).has_area(), "registered queue uses aggregate status")
			await click(root, view.actor_screen_position(actor))
			check(selected_id == actor.id, "real click selects every registered queue member")
		for group: Dictionary in projected.groups:
			var header := view.world_to_screen(group.header_world)
			for actor: ActorState in arrived:
				var in_group: bool = actor.target_room == group.owner_id if group.kind == &"room" else actor.elevator_id == group.owner_id and actor.floor_index == group.floor
				if in_group:
					check(header.y <= view.actor_sprite_rect(actor).position.y - 3.9 * zoom, "aggregate clears every queue sprite")
		view.pan = Vector2.ZERO
		view.cull_offscreen = false
		view.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var reference := root.get_texture().get_image().get_data()
		view.cull_offscreen = true
		view.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		check(reference == root.get_texture().get_image().get_data(), "registered queue culling preserves pixels")
		root.get_texture().get_image().save_png("res://.runtime/m7-fifo-queue-%s.png" % zoom)
	check(SessionSnapshot.capture(session) == before, "queue layout and clicks preserve authoritative state")
	var restored := SessionSnapshot.restore(before)
	check(restored.error.is_empty(), "queue fixture restores through schema")
	if restored.error.is_empty():
		check(HotelQueueProjection.build(restored.session, view.CELL, view.FLOOR_HEIGHT) == projected, "save restore reproduces positions and groups")
