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
		check(HotelArt.character(actor) == walk_texture, "idle restores base texture")
		actor.state = &"cleaning" if actor.role == &"cleaner" else &"working"
	# Static service poses are contextual: cups must never appear in other rooms.
	for profile: StringName in [&"balanced", &"business", &"leisure"]:
		var guest := session.spawn_guest()
		guest.archetype_id = profile
		guest.state = &"using"
		var pose := HotelArt.character(guest, &"cafe")
		check(pose != HotelArt.character(guest, &"bedroom"), "cafe pose is service specific")
		check(pose.get_image().detect_alpha() != Image.ALPHA_NONE, "cafe pose has alpha")
		check(HotelArt.character_region(guest, 0, &"cafe") == HotelArt.character_region(guest, 200, &"cafe"), "single service pose stays stable")
		for room: RoomState in session.hotel.rooms:
			if room.definition_id == &"cafe":
				guest.target_room = room.id
			guest.x = 5.8 + [&"balanced", &"business", &"leisure"].find(profile) * 0.6
	session.speed = 0
	for room: RoomState in session.hotel.rooms:
		if room.definition().category == &"lodging" and room.column == 8:
			room.dirty = true
	game._replace_session(session)
	var before := SessionSnapshot.capture(session)
	for zoom: float in [0.35, 0.9, 1.8]:
		game.view.zoom_factor = zoom
		game.view.pan = Vector2.ZERO
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.runtime/m7-art-%.2f.png" % zoom)
	check(preload("res://tests/snapshot_comparison.gd").difference(before, SessionSnapshot.capture(session), "art").is_empty(), "rendering and animation do not mutate simulation")
	var old_audio: bool = game.audio.enabled
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
	print(JSON.stringify({"suite": "ui_art", "failures": failures, "rooms": HotelArt.ROOMS.size(), "characters": HotelArt.CHARACTERS.size()}))
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
