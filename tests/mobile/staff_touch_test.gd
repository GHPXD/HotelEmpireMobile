extends "res://tests/mobile/touch_management_test.gd"
## Native touch-only recruitment, delegation, confirmed dismissal and checkpoints.

func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	for scenario: Dictionary in [{"size": Vector2i(320, 568), "locale": "pt_BR", "large": false}, {"size": Vector2i(568, 320), "locale": "es", "large": true}, {"size": Vector2i(1280, 800), "locale": "en", "large": true}]:
		var dimensions: Vector2i = scenario.size
		print(JSON.stringify({"progress": "staff_touch", "dimensions": [dimensions.x, dimensions.y]}))
		UIPreferences.save_value("locale", scenario.locale)
		UIPreferences.save_large_text(scenario.large)
		root.size = dimensions
		game = preload("res://core/application/app_root.tscn").instantiate()
		inject_progress_time()
		game.controller.enable_onboarding = false
		game.controller.saves.path = "user://staff-touch-%dx%d.json" % [dimensions.x, dimensions.y]
		game.controller.saves.legacy_path = "user://staff-no-legacy.json"
		root.add_child(game)
		current_scene = game
		game.set_process(false)
		await frames(6)
		var session := game.controller.session
		await build_room(&"reception", 0, 0)
		await build_room(&"bedroom", 3, 0)
		await click(root, game.shell.nav_buttons[&"staff"].get_global_rect().get_center())
		await press_inspect(&"hire_options", 1)
		check(game.router.sheet == &"hire_options", "touch opens profile comparison")
		check(game.shell.sheet_content.find_children("*", "Button", true, false).size() == 4, "four fixed two-trait hiring profiles")
		await capture("staff-profiles-%dx%d" % [dimensions.x, dimensions.y])
		var cash := session.economy.cash
		var traits: Array[StringName] = [&"agile", &"meticulous"]
		await press_action(&"hire", {"definition": HotelSession.EMPLOYEES[1], "traits": traits})
		var actor: ActorState = session.actors[1]
		check(actor.employee.traits == traits and session.economy.cash == cash - 203 and game.router.screen == &"staff" and game.router.sheet.is_empty(), "profile touch charges once and returns to staff")
		await press_inspect(&"employee", 1)
		await press_action(&"staff_priority", {"id": 1, "priority": &"nearest"})
		check(actor.employee.priority == &"nearest", "cleaning priority changes by touch")
		await press_action(&"staff_duty", {"id": 1, "enabled": false})
		check(not actor.employee.duty_enabled and session.recurring_costs().salaries == 36, "pause retains correct trait salary")
		var room := session.hotel.rooms[1]
		room.dirty = true
		for tick_index in 60:
			game.controller.advance(session.rules.tick)
		game._refresh()
		await frames()
		check(room.dirty and room.cleaning_by == -1, "paused delegate leaves manual bottleneck")
		await capture("staff-paused-%dx%d" % [dimensions.x, dimensions.y])
		await press_action(&"staff_duty", {"id": 1, "enabled": true})
		for job_index in 6:
			room.dirty = true
			room.cleaning_quality_bonus = 0
			for tick_index in 170:
				game.controller.advance(session.rules.tick)
		game._refresh()
		await frames()
		check(actor.employee.level() == 2 and actor.employee.completed_tasks == 6 and session.recurring_costs().salaries == 38, "actual touch delegation promotes staff and changes wage")
		await capture("staff-level-%dx%d" % [dimensions.x, dimensions.y])
		var loaded := SaveService.restore(AtomicJSONStore.read(game.controller.saves.path).data)
		check(loaded.error.is_empty() and loaded.session.actors[1].employee.level() == 2 and loaded.session.actors[1].employee.priority == &"nearest", "completion checkpoint preserves promotion and controls")
		await press_action(&"request_dismiss", {"id": 1})
		check(game.shell.modal_blocker.visible and game.router.sheet == &"dismiss_confirm", "dismissal requires concrete modal confirmation")
		var before := SessionSnapshot.capture(session)
		await capture("staff-dismiss-%dx%d" % [dimensions.x, dimensions.y])
		game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await frames()
		check(SessionSnapshot.capture(session) == before and not actor.employee.dismiss_requested, "back cancels dismissal without mutation")
		await press_inspect(&"employee", 1)
		await press_action(&"request_dismiss", {"id": 1})
		cash = session.economy.cash
		await press_action(&"dismiss_employee", {"id": 1})
		check(actor.employee.dismiss_requested and session.economy.cash == cash, "confirmed dismissal has no refund")
		game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		var frozen := SessionSnapshot.capture(session)
		game.controller.advance(100)
		check(SessionSnapshot.capture(session) == frozen, "background freezes employee departure")
		game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		for tick_index in 150:
			game.controller.advance(session.rules.tick)
		game._refresh()
		await frames()
		check(not session.actors.has(1) and session.employees.dismissed == 1 and session.recurring_costs().salaries == 0, "physical departure clears employee and salary")
		loaded = SaveService.restore(AtomicJSONStore.read(game.controller.saves.path).data)
		check(loaded.error.is_empty() and loaded.session.employees.dismissed == 1 and not loaded.session.actors.has(1), "exit checkpoint prevents dismissed staff resurrection")
		await click(root, game.shell.nav_buttons[&"staff"].get_global_rect().get_center())
		await capture("staff-departed-%dx%d" % [dimensions.x, dimensions.y])
		game.queue_free()
		current_scene = null
		await frames(4)
		game = null
	finish("staff_touch", {"dimensions": 3, "input": "InputEventScreenTouch/ScreenDrag via viewport"})
