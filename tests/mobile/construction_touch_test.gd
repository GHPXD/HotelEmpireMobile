extends "res://tests/mobile/touch_management_test.gd"
## Touch-only paid queue, reservations, confirmation, deadlines and restart.

func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	for scenario: Dictionary in [{"size": Vector2i(320, 568), "locale": "pt_BR", "large": false}, {"size": Vector2i(568, 320), "locale": "es", "large": true}, {"size": Vector2i(1280, 800), "locale": "en", "large": true}]:
		var dimensions: Vector2i = scenario.size
		print(JSON.stringify({"progress": "construction_touch", "dimensions": [dimensions.x, dimensions.y]}))
		UIPreferences.save_value("locale", scenario.locale)
		UIPreferences.save_large_text(scenario.large)
		root.size = dimensions
		game = preload("res://core/application/app_root.tscn").instantiate()
		inject_progress_time()
		game.controller.enable_onboarding = false
		game.controller.saves.path = "user://construction-touch-%dx%d.json" % [dimensions.x, dimensions.y]
		game.controller.saves.legacy_path = "user://construction-no-legacy.json"
		root.add_child(game)
		current_scene = game
		game.set_process(false)
		await frames(6)
		var session := game.controller.session
		var initial_cash := session.economy.cash
		await build_room(&"reception", 0, 0, false)
		await build_room(&"bedroom", 3, 0, false)
		await build_room(&"restaurant", 5, 0, false)
		check(session.hotel.rooms.is_empty() and game.controller.construction.jobs[2].slot == -1 and session.economy.cash == initial_cash - 2400, "touch fills two crews and paid FIFO without early services")
		await capture("construction-queued-%dx%d" % [dimensions.x, dimensions.y])
		await click(root, game.shell.nav_buttons[&"hotel"].get_global_rect().get_center())
		await press_inspect(&"construction", 2)
		await press_action(&"request_construction_cancel", {"id": 2})
		check(game.router.sheet == &"construction_cancel_confirm" and game.shell.modal_blocker.visible, "cancel shows amount and modal before refund")
		await capture("construction-cancel-%dx%d" % [dimensions.x, dimensions.y])
		var before := game.controller.construction.snapshot()
		var cash := session.economy.cash
		game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await frames()
		check(game.controller.construction.snapshot() == before and session.economy.cash == cash, "back leaves paid project and reservation intact")
		await click(root, game.shell.nav_buttons[&"hotel"].get_global_rect().get_center())
		await press_inspect(&"construction", 2)
		await press_action(&"request_construction_cancel", {"id": 2})
		await press_action(&"cancel_construction", {"id": 2})
		check(game.controller.construction.by_id(2) == null and session.economy.cash == cash + 600 and game.controller.construction.jobs[1].slot >= 0, "confirmed refund starts queued project immediately")
		await build_room(&"bedroom", 3, 0, false)
		check(game.controller.construction.jobs.back().slot == -1, "refunded plot can be bought again with a fresh id")
		session.speed = 0
		progress_time.advance(9999)
		game.controller.advance(0.01)
		check(session.hotel.rooms.is_empty(), "touch product exposes no room a millisecond before deadline")
		await click(root, game.shell.nav_buttons[&"hotel"].get_global_rect().get_center())
		await press_inspect(&"construction", 1)
		await capture("construction-active-%dx%d" % [dimensions.x, dimensions.y])
		progress_time.advance(1)
		game.controller.advance(0.01)
		game._refresh()
		await frames()
		check(session.hotel.rooms.size() == 1 and game.controller.construction.by_id(1) == null and game.controller.construction.by_id(4).slot >= 0, "deadline opens reception once and activates next queued build")
		cash = session.economy.cash
		var ticks := session.tick_count
		var save_path := game.controller.saves.path
		game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		progress_time.advance(120000)
		game.queue_free()
		current_scene = null
		await frames(4)
		game = preload("res://core/application/app_root.tscn").instantiate()
		game.controller.enable_onboarding = false
		game.controller.progress_clock = progress_time.clock()
		game.controller.saves.clock = progress_time.utc
		game.controller.saves.path = save_path
		game.controller.saves.legacy_path = "user://construction-no-legacy.json"
		root.add_child(game)
		current_scene = game
		game.set_process(false)
		await frames(6)
		session = game.controller.session
		check(session.hotel.rooms.size() == 3 and game.controller.construction.jobs.is_empty() and game.controller.construction.completed == 3 and game.controller.construction.cancelled == 1, "recreated app completes paid jobs after OS kill")
		check(session.tick_count == ticks and session.economy.cash == cash and game.controller.return_construction.size() == 2, "restart consumes absence with no billing replay or simulation ticks")
		check(game.router.sheet == &"construction_return", "return presents completed construction before continuing")
		await capture("construction-return-%dx%d" % [dimensions.x, dimensions.y])
		await press_action(&"construction_return_continue")
		check(game.router.sheet.is_empty(), "touch dismisses return summary without an extra reward claim")
		var loaded := SaveService.restore(AtomicJSONStore.read(save_path).data)
		check(loaded.error.is_empty() and loaded.app_state.construction.completed == 3 and loaded.app_state.construction.cancelled == 1, "product checkpoints completion and refund counters together")
		game.queue_free()
		current_scene = null
		await frames(4)
		game = null
	finish("construction_touch", {"dimensions": 3, "input": "InputEventScreenTouch/ScreenDrag through viewport"})
