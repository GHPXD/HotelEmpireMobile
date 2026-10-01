extends "res://tests/mobile/touch_management_test.gd"
## Guided fresh-profile loop through native touch events; no injected hotel funds.

func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	var cases := [
		{"size": Vector2i(320, 568), "locale": "pt_BR", "large": false},
		{"size": Vector2i(568, 320), "locale": "es", "large": true},
		{"size": Vector2i(1280, 800), "locale": "en", "large": true},
	]
	for scenario in cases:
		var dimensions: Vector2i = scenario.size
		print(JSON.stringify({"progress": "onboarding_touch", "dimensions": [dimensions.x, dimensions.y]}))
		UIPreferences.save_value("locale", scenario.locale)
		UIPreferences.save_large_text(scenario.large)
		root.size = dimensions
		game = preload("res://core/application/app_root.tscn").instantiate()
		inject_progress_time()
		game.controller.saves.path = "user://intro-touch-%dx%d.json" % [dimensions.x, dimensions.y]
		game.controller.saves.legacy_path = "user://intro-no-legacy.json"
		root.add_child(game)
		current_scene = game
		game.set_process(false)
		await frames(6)
		var session := game.controller.session
		check(session.economy.cash == 2400 and game.router.sheet == &"overview", "guide visible at fresh boot")
		await capture("intro-start-%dx%d" % [dimensions.x, dimensions.y])
		await guide_build(&"reception", 0)
		check(game.controller.onboarding.stage == 1, "touch construction advances by domain fact")
		await hotel_overview()
		await guide_build(&"bedroom", 3)
		await hotel_overview()
		await press_action(&"guide_next")
		check(session.opened and game.controller.onboarding.stage == 3, "guide opens real hotel by touch")
		await press_action(&"guide_next")
		check(game.router.sheet == &"room" and game.router.context_id == 1, "guide locates reception")
		await simulate_until(func() -> bool: return session.player_work.task_error(session, "checkin", 1).is_empty(), 100)
		var cash: int = session.economy.cash
		await press_action(&"player_work", {"kind": "checkin", "id": 1})
		check(session.player_work.reserved_guest() > 0 and session.economy.cash == cash and game.controller.onboarding.stage == 3, "touch starts real work without early money or guide completion")
		await press_action(&"player_cancel")
		check(session.player_work.job.is_empty() and session.guests.bookings == 0 and session.economy.cash == cash, "touch cancel has no booking effect")
		await simulate_until(func() -> bool: return not session.player_work.busy(session), 80)
		await press_action(&"player_work", {"kind": "checkin", "id": 1})
		await capture("intro-checkin-%dx%d" % [dimensions.x, dimensions.y])
		await simulate_until(func() -> bool: return session.player_work.job.is_empty(), 120)
		check(game.controller.onboarding.stage == 4 and session.guests.bookings == 1 and session.economy.revenue == 140, "touch checkin finishes once")
		check(HotelArt.portrait(session.player_work.worker(session)) != null and HotelArt.character(session.player_work.worker(session)) != null, "player has existing original raster presentation")
		await hotel_overview()
		await guide_build(&"restaurant", 5)
		await hotel_overview()
		await simulate_until(func() -> bool: return not session.player_work.orders.is_empty(), 1500)
		var order_id: int = int(session.player_work.orders[0].id) if not session.player_work.orders.is_empty() else -1
		var revenue: int = session.economy.revenue
		await press_action(&"room_service", {"order_id": order_id})
		check(session.player_work.job.get("kind") == "room_service" and session.economy.revenue == revenue, "room-service touch reserves real order")
		await simulate_until(func() -> bool: return session.player_work.job.get("phase") == "prepare", 120)
		await capture("intro-room-service-%dx%d" % [dimensions.x, dimensions.y])
		var snapshot := SessionSnapshot.capture(session)
		game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		game.controller.advance(900)
		check(preload("res://tests/snapshot_comparison.gd").difference(snapshot, SessionSnapshot.capture(session), "paused touch").is_empty(), "background cannot complete delivery")
		game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		await simulate_until(func() -> bool: return session.player_work.job.is_empty(), 200)
		check(session.player_work.totals.delivered == 1 and session.economy.revenue == revenue + 28 and game.controller.onboarding.stage == 6, "touch delivery creates actual meal and revenue")
		await simulate_until(func() -> bool: return session.hotel.rooms[1].dirty, 2000)
		await hotel_overview()
		await press_action(&"guide_next")
		await press_action(&"player_work", {"kind": "cleaning", "id": 2})
		await simulate_until(func() -> bool: return session.player_work.job.get("phase") == "action", 100)
		check(HotelArt.animation_id(session.player_work.worker(session)) == &"cleaner-cleaning", "manual cleanup uses original cleaning animation")
		await capture("intro-cleaning-%dx%d" % [dimensions.x, dimensions.y])
		await simulate_until(func() -> bool: return session.player_work.job.is_empty(), 100)
		check(not session.hotel.rooms[1].dirty and game.controller.onboarding.stage == 7, "touch clean releases bedroom")
		await hotel_overview()
		await press_action(&"guide_next")
		var repair_id: int = game.router.context_id
		var room := session.hotel.by_id(repair_id)
		cash = session.economy.cash
		await press_action(&"player_work", {"kind": "repair", "id": repair_id})
		await simulate_until(func() -> bool: return session.player_work.job.is_empty(), 150)
		check(room.condition == 100 and session.economy.cash == cash - 5 and game.controller.onboarding.stage == 8, "touch repair has exact material expense and real efficiency effect")
		await hotel_overview()
		await press_action(&"guide_next")
		await press_action(&"hire", {"definition": HotelSession.EMPLOYEES[0]})
		check(game.controller.onboarding.stage == 9 and not game.controller.onboarding.active(), "touch delegation completes all guide facts")
		check(game.controller.inventory.quantity(&"15m") == 1 and game.controller.inventory.claimed(&"tutorial"), "physical tutorial grants exactly one free fifteen-minute item")
		check(session.economy.cash == 2400 + session.economy.revenue - session.economy.expenses - session.economy.capital_spent and session.economy.cash >= 0, "mobile profile remains solvent without injected money")
		check(game.shell.sheet_content.find_children("*", "Button", true, false).filter(func(button: Button) -> bool: return button.get_meta("inspect_kind", &"") == &"employee").size() == 1, "player excluded from employee list")
		await hotel_overview()
		await capture("intro-done-%dx%d" % [dimensions.x, dimensions.y])
		var restored := SaveService.restore(AtomicJSONStore.read(game.controller.saves.path).data)
		check(restored.error.is_empty() and restored.app_state.onboarding.stage == 9 and restored.session.player_work.totals.delivered == 1, "touch flow saved completed guide and physical work")
		check(_saved_tutorial(restored.app_state.player_inventory), "touch tutorial reward persists and cannot be granted twice")
		game.queue_free()
		current_scene = null
		await frames(4)
		game = null
	finish("onboarding_touch", {"dimensions": 3, "input": "InputEventScreenTouch/ScreenDrag through viewport", "starting_cash": 2400})

func _saved_tutorial(data: Dictionary) -> bool:
	# Keep probe references out of the coroutine that shuts down the SceneTree.
	var inventory := PlayerInventory.new()
	return inventory.restore(data) and inventory.quantity(&"15m") == 1 and not inventory.claim_reward(&"tutorial")

func hotel_overview() -> void:
	await click(root, game.shell.nav_buttons[&"hotel"].get_global_rect().get_center())
	check(game.router.sheet == &"overview", "hotel overview accessible by touch")

func guide_build(definition_id: StringName, column: int) -> void:
	await press_action(&"guide_next")
	check(game.view.blueprint == HotelCatalog.room(definition_id), "guide locates blueprint")
	var cash: int = game.controller.session.economy.cash
	for attempt in 32:
		var target := game.view.room_rect(column, 0).get_center()
		if Rect2(Vector2.ZERO, game.view.size).grow(-8).has_point(target):
			break
		var focus := game.view.get_global_rect().get_center()
		var delta := (game.view.size / 2 - target).limit_length(80)
		await touch(0, focus, true)
		await drag(0, focus + delta, delta)
		await touch(0, focus + delta, false)
	await click(root, game.view.room_rect(column, 0).get_center() + game.view.global_position)
	check(game.router.sheet == &"build_confirm" and game.controller.session.economy.cash == cash, "guided construction still needs confirmation")
	await press_action(&"confirm_build")
	check(game.controller.session.economy.cash == cash - HotelCatalog.room(definition_id).build_cost, "guided build uses exact Cash cost")
	check(game.controller.construction.jobs.size() == 1 and game.controller.session.hotel.room_at(column, 0) == null, "guide purchase does not expose an unfinished service")
	await finish_construction()

func simulate_until(predicate: Callable, maximum_ticks: int) -> void:
	for index in maximum_ticks:
		if predicate.call():
			game._refresh()
			await frames(3)
			return
		game.controller.advance(game.controller.session.rules.tick)
		if index % 10 == 0:
			game._refresh()
	check(false, "simulation reaches intended physical state")
	game._refresh()
	await frames(3)
