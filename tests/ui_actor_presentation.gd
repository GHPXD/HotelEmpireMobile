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
	print(JSON.stringify({"suite": "ui_actor_presentation", "failures": failures, "waiting_contexts": waiting.size(), "zooms": 3, "phases": 4}))
	view.queue_free()
	await process_frame
	quit(1 if failures else 0)
