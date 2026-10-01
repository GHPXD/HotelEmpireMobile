extends "res://tests/mobile/render_harness.gd"
## Sends only screen touch/drag through Input and the viewport, never emits buttons.

var game: AppRoot

func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	for dimensions: Vector2i in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(360, 780), Vector2i(844, 390), Vector2i(1280, 800)]:
		print(JSON.stringify({"progress": "touch_flow", "dimensions": [dimensions.x, dimensions.y]}))
		root.size = dimensions
		game = preload("res://core/application/app_root.tscn").instantiate()
		game.controller.saves.path = "user://touch-%dx%d.json" % [dimensions.x, dimensions.y]
		game.controller.saves.legacy_path = "user://no-legacy.json"
		root.add_child(game)
		current_scene = game
		game.set_process(false)
		await frames(6)
		var session := game.controller.session
		check(session != null and session.hotel.rooms.is_empty(), "fresh touch flow")
		await build_room(&"reception", 0, 0)
		await build_room(&"bedroom", 3, 0)
		await click(root, game.shell.nav_buttons[&"staff"].get_global_rect().get_center())
		check(game.router.screen == &"staff", "staff through bottom navigation")
		await press_action(&"hire", {"definition": HotelSession.EMPLOYEES[0]})
		check(session.actors.size() == 1, "single touch hires exactly one employee")
		await press_inspect(&"employee", 1)
		await press_action(&"assign", {"id": 1, "destination": session.hotel.rooms[0].id})
		check(session.actors[1].preferred_room == session.hotel.rooms[0].id, "assign reception via touch")
		await click(root, game.shell.open_button.get_global_rect().get_center())
		check(session.opened, "open via touch")
		for tick in 1200:
			game.controller.advance(session.rules.tick)
		check(session.guests.bookings > 0, "touch-built hotel receives paying bookings")
		check(session.economy.revenue > 0, "hotel earns through actual simulation")
		await click(root, game.shell.pause_button.get_global_rect().get_center())
		check(session.speed == 0, "pause via touch")
		# Seed funds only for management scenarios after the fresh F2P loop above.
		session.economy.cash = 100000
		await click(root, game.shell.nav_buttons[&"build"].get_global_rect().get_center())
		await press_action(&"add_floor")
		check(session.hotel.floors == 2, "floor via touch")
		await build_room(&"elevator", 15, 0)
		await click(root, game.shell.nav_buttons[&"staff"].get_global_rect().get_center())
		await press_action(&"hire", {"definition": HotelSession.EMPLOYEES[1]})
		var cleaner_id := session.next_actor_id - 1
		await press_inspect(&"employee", cleaner_id)
		await press_action(&"assign", {"id": cleaner_id, "destination": 1})
		check(session.actors[cleaner_id].preferred_floor == 1, "cleaner floor assignment via touch")
		await click(root, game.shell.nav_buttons[&"hotel"].get_global_rect().get_center())
		await press_link(&"operations")
		check(game.router.screen == &"operations", "operations reachable through hotel")
		var bedroom := session.hotel.rooms[1]
		await press_inspect(&"room", bedroom.id)
		var revenue := session.economy.revenue
		await press_action(&"tariff", {"id": bedroom.id, "percent": 125})
		check(bedroom.price_percent == 125 and session.economy.revenue == revenue, "tariff changes price without inventing revenue")
		var before_level := bedroom.level
		var cash := session.economy.cash
		var cost := bedroom.next_upgrade().cost
		await press_action(&"upgrade", {"id": bedroom.id})
		check(bedroom.level == before_level + 1 and session.economy.cash == cash - cost, "upgrade exact cost through touch")
		await capture("room-%dx%d" % [dimensions.x, dimensions.y])
		game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await frames()
		check(game.router.sheet.is_empty() and game.router.screen == &"operations", "Android back returns to originating screen")
		await press_status(1)
		var expected := HotelAnalytics.rooms(session, &"", -1, 1).size()
		check(game.shell.sheet_content.find_children("*", "Button", true, false).filter(func(button: Button) -> bool: return button.has_meta("inspect_id")).size() == expected, "queue filter uses actual domain state")
		game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await frames()
		await click(root, game.shell.nav_buttons[&"hotel"].get_global_rect().get_center())
		await press_link(&"finances")
		check(game.router.screen == &"finances", "finances reachable by touch")
		await capture("finance-%dx%d" % [dimensions.x, dimensions.y])
		await click(root, game.shell.nav_buttons[&"hotel"].get_global_rect().get_center())
		await press_link(&"reviews")
		check(game.router.screen == &"reviews" and not session.guests.reviews.is_empty(), "real departure reviews reachable")
		await capture("reviews-%dx%d" % [dimensions.x, dimensions.y])
		# Scrolling a sheet cannot move the hotel or activate a room.
		var pan := game.view.pan
		var scroll_before := game.shell.sheet_scroll.scroll_vertical
		var point := game.shell.sheet_scroll.get_global_rect().get_center()
		await touch(0, point, true)
		await drag(0, point - Vector2(0, 60), Vector2(0, -60))
		await touch(0, point - Vector2(0, 60), false)
		check(game.view.pan == pan and game.router.sheet.is_empty(), "sheet scroll stays out of world gesture routing")
		if game.shell.sheet_content.size.y > game.shell.sheet_scroll.size.y + 60:
			check(game.shell.sheet_scroll.scroll_vertical > scroll_before, "real touch scroll advances content")
		game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await frames()
		await world_gestures()
		# A construction cancel must never spend or leave a stuck pointer.
		await click(root, game.shell.nav_buttons[&"build"].get_global_rect().get_center())
		await press_action(&"choose_build", {"definition": HotelCatalog.room(&"bedroom")})
		var before := SessionSnapshot.capture(session)
		await click(root, game.view.room_rect(5, 0, 2).get_center() + game.view.global_position)
		check(game.router.sheet == &"build_confirm", "construction requires confirmation")
		game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await frames()
		check(SessionSnapshot.capture(session) == before, "back cancels preview without domain mutation")
		game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		check(game.view.blueprint == null and game.gestures.pointers.is_empty(), "back cancels blueprint and resets pointers")
		await click(root, game.shell.nav_buttons[&"staff"].get_global_rect().get_center())
		var before_hire_scroll := SessionSnapshot.capture(session)
		for button: Button in game.shell.sheet_content.find_children("*", "Button", true, false):
			if button.get_meta("mobile_action", &"") == &"hire":
				game.shell.sheet_scroll.ensure_control_visible(button)
				await frames()
				var start := button.get_global_rect().get_center()
				await touch(0, start, true)
				await drag(0, start - Vector2(0, 45), Vector2(0, -45))
				await touch(0, start - Vector2(0, 45), false)
				break
		check(SessionSnapshot.capture(session) == before_hire_scroll, "drag over hire button cancels activation and cannot spend")
		await click(root, game.shell.actions.get_child(2).get_global_rect().get_center())
		var initial_sound := game.audio.enabled
		await press_action(&"sound")
		check(game.audio.enabled != initial_sound, "sound toggles by touch")
		var audio_probe := HotelAudio.new()
		root.add_child(audio_probe)
		check(audio_probe.enabled == game.audio.enabled, "sound preference restored")
		audio_probe.queue_free()
		await press_action(&"sound")
		await press_action(&"haptics")
		var haptic_probe := HapticService.new()
		haptic_probe.load_preference()
		check(haptic_probe.enabled == game.haptics.enabled, "haptics preference restored")
		await press_action(&"haptics")
		await press_action(&"locale", {"locale": "es"})
		check(TranslationServer.get_locale() == "es" and UIPreferences.load_locale() == "es", "language selection persists via touch")
		await press_action(&"large_text")
		check(UIPreferences.load_large_text() and UIPreferences.load_locale() == "es", "text size preserves selected language")
		await capture("settings-large-%dx%d" % [dimensions.x, dimensions.y])
		await press_action(&"large_text")
		await press_action(&"locale", {"locale": "en"})
		await build_room(&"restaurant", 8, 0)
		var empty_room: RoomState = session.hotel.rooms.back()
		await click(root, game.shell.nav_buttons[&"hotel"].get_global_rect().get_center())
		await press_link(&"operations")
		await press_status(0)
		await press_inspect(&"room", empty_room.id)
		await press_action(&"request_demolish", {"id": empty_room.id})
		var before_demolition := SessionSnapshot.capture(session)
		game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await frames()
		check(SessionSnapshot.capture(session) == before_demolition, "back cancels demolition without mutation")
		await press_inspect(&"room", empty_room.id)
		await press_action(&"request_demolish", {"id": empty_room.id})
		var before_demolition_cash := session.economy.cash
		await press_action(&"demolish", {"id": empty_room.id})
		check(session.hotel.by_id(empty_room.id) == null and session.economy.cash == before_demolition_cash, "explicit demolition has no refund %s room=%s cash=%s/%s route=%s" % [dimensions, session.hotel.by_id(empty_room.id), session.economy.cash, before_demolition_cash, game.router.sheet])
		var save := SaveService.new()
		save.path = game.controller.saves.path
		var restored := save.boot()
		check(restored.error.is_empty() and restored.session.hotel.rooms[1].price_percent == 125 and restored.session.actors[cleaner_id].preferred_floor == 1, "UI commands checkpoint tariffs and assignments")
		game.queue_free()
		current_scene = null
		await frames(4)
		game = null
	finish("mobile_touch_management", {"dimensions": 5, "input": "InputEventScreenTouch/ScreenDrag via Input.parse_input_event"})

func build_room(definition_id: StringName, column: int, floor_index: int) -> void:
	await click(root, game.shell.nav_buttons[&"build"].get_global_rect().get_center())
	await press_action(&"choose_build", {"definition": HotelCatalog.room(definition_id)})
	var session := game.controller.session
	var cash := session.economy.cash
	var count := session.hotel.rooms.size()
	var definition := HotelCatalog.room(definition_id)
	if definition_id == &"reception":
		game.view.zoom_factor = 1.8
	# Reaching a distant slot uses the same drag gestures as the player.
	for attempt in 32:
		var target := game.view.room_rect(column, floor_index).get_center()
		if Rect2(Vector2.ZERO, game.view.size).grow(-8).has_point(target):
			break
		var focus := game.view.get_global_rect().get_center()
		var delta := (game.view.size / 2 - target).limit_length(80)
		await touch(0, focus, true)
		await drag(0, focus + delta, delta)
		await touch(0, focus + delta, false)
	await click(root, game.view.room_rect(column, floor_index).get_center() + game.view.global_position)
	check(game.router.sheet == &"build_confirm", "world touch opens preview for " + String(definition_id))
	check(game.view.fixed_preview and game.view.preview_cell == Vector2i(column, floor_index), "preview stays anchored when sheet resizes world")
	check(Rect2(Vector2.ZERO, game.view.size).encloses(game.view.room_rect(column, floor_index, definition.width)), "confirmed placement remains visible beside context %s %s viewport=%s room=%s" % [root.size, definition_id, game.view.size, game.view.room_rect(column, floor_index, definition.width)])
	check(session.economy.cash == cash and session.hotel.rooms.size() == count, "preview and emulated mouse never double spend")
	var pan := game.view.pan
	await click(root, game.shell.nav_buttons[&"staff"].get_global_rect().get_center())
	check(game.router.sheet == &"build_confirm" and game.view.pan == pan, "modal blocks navigation and world")
	await press_action(&"confirm_build")
	check(session.hotel.rooms.size() == count + 1 and session.economy.cash == cash - definition.build_cost, "confirmed touch builds once")
	check(session.hotel.rooms.back().column == column, "construction begins at tapped cell")

func press_action(action: StringName, arguments: Dictionary = {}) -> void:
	await press_matching("mobile_action", action, arguments)

func press_inspect(kind: StringName, id: int) -> void:
	for button: Button in game.shell.sheet_content.find_children("*", "Button", true, false):
		if button.get_meta("inspect_kind", &"") == kind and button.get_meta("inspect_id", -1) == id:
			await press_button(button)
			return
	check(false, "missing inspect " + String(kind) + " %d" % id)

func press_link(destination: StringName) -> void:
	await press_matching("destination", destination)

func press_status(status: int) -> void:
	await press_matching("room_status", status)

func press_matching(meta: String, value: Variant, arguments: Dictionary = {}) -> void:
	for button: Button in game.shell.sheet_content.find_children("*", "Button", true, false):
		if button.has_meta(meta) and button.get_meta(meta) == value and (arguments.is_empty() or button.get_meta("arguments", {}) == arguments):
			await press_button(button)
			return
	check(false, "missing " + meta + " " + str(value))

func press_button(button: Button) -> void:
	game.shell.sheet_scroll.ensure_control_visible(button)
	await frames()
	check(root.get_visible_rect().encloses(button.get_global_rect()), "touch target inside viewport")
	check(game.shell.sheet_scroll.get_global_rect().has_point(button.get_global_rect().get_center()), "touch center inside scroll clipping area %s button=%s scroll=%s" % [button.get_meta("mobile_action", ""), button.get_global_rect(), game.shell.sheet_scroll.get_global_rect()])
	check(button.size.y >= 48, "48-unit target")
	await click(root, button.get_global_rect().get_center())

func world_gestures() -> void:
	game._fit_initial_camera()
	var point := game.view.get_global_rect().get_center()
	var before := SessionSnapshot.capture(game.controller.session)
	var initial_pan := game.view.pan
	await touch(0, point, true)
	await drag(0, point + Vector2(32, 20), Vector2(32, 20))
	await touch(0, point + Vector2(32, 20), false)
	check(game.view.pan.distance_to(initial_pan + Vector2(32, 20)) < 0.1, "world drag follows screen gesture")
	check(game.router.sheet.is_empty(), "drag cannot select a room")
	var zoom := game.view.zoom_factor
	await touch(0, point - Vector2(40, 0), true)
	await touch(1, point + Vector2(40, 0), true)
	await drag(1, point + Vector2(65, 0), Vector2(25, 0))
	await touch(1, point + Vector2(65, 0), false)
	await touch(0, point - Vector2(40, 0), false)
	check(game.view.zoom_factor > zoom and game.router.sheet.is_empty(), "pinch zoom through GUI routing without accidental tap")
	check(SessionSnapshot.capture(game.controller.session) == before, "gestures preserve authoritative state")
	game.view.pan = Vector2.ZERO
	game._fit_initial_camera()
	await frames()
