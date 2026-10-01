extends "res://tests/mobile/touch_management_test.gd"
## Paid reforms, all audiences and level gates through actual viewport touch.

func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	for scenario: Dictionary in [{"size": Vector2i(320, 568), "locale": "pt_BR", "large": false}, {"size": Vector2i(568, 320), "locale": "es", "large": true}, {"size": Vector2i(1280, 800), "locale": "en", "large": true}]:
		root.size = scenario.size
		UIPreferences.save_value("locale", scenario.locale)
		UIPreferences.save_large_text(scenario.large)
		print(JSON.stringify({"progress": "positioning_touch", "size": [root.size.x, root.size.y]}))
		game = preload("res://core/application/app_root.tscn").instantiate()
		inject_progress_time()
		game.controller.enable_onboarding = false
		game.controller.saves.path = "user://positioning-touch-%dx%d.json" % [root.size.x, root.size.y]
		game.controller.saves.legacy_path = "user://positioning-touch-no-legacy.json"
		root.add_child(game)
		current_scene = game
		game.set_process(false)
		await frames(6)
		game.safe_area.override_safe_area = Rect2(12, 8, root.size.x - 24, root.size.y - 20)
		game.safe_area.override_window_size = root.size
		game.safe_area.refresh()
		var session := game.controller.session
		# Late management fixture. This does not claim the natural F2P unlock time.
		session.economy.cash = 100000
		session.progression.evaluate({"bookings": 3})
		session.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
		for column in [3, 5, 7]:
			var room := session.hotel.build(HotelCatalog.room(&"bedroom"), column, 0)
			check(session.upgrade_room(room.id).is_empty() and session.upgrade_room(room.id).is_empty(), "fixture pays N2/N3")
		check(game.controller.checkpoint().is_empty(), "late fixture has valid durable progression")
		game._refresh()
		await _open_room(2)
		check(_button(&"upgrade").disabled and _has_text(TranslationServer.translate("upgrade.requirement") % TranslationServer.translate("objective.steady_service")), "N4 shows precise localized requirement")
		check(_has_text(MobileLabels.room_comparison(session.hotel.by_id(2), 4, &"")), "upgrade shows derived before/after rate, upkeep and quality")
		await press_inspect(&"room_specializations", 2)
		for option in HotelCatalog.room(&"bedroom").specializations:
			var button := _button(&"request_specialization", option.id)
			check(button != null and not button.disabled, "three initial branches are genuinely available after N3")
			await _check_button_text(button)
		await capture("positioning-choices-%dx%d" % [root.size.x, root.size.y])
		var before := SessionSnapshot.capture(session)
		await press_action(&"request_specialization", {"id": 2, "specialization": &"executive"})
		check(game.router.sheet == &"specialization_confirm" and game.shell.modal_blocker.visible and SessionSnapshot.capture(session) == before, "choice opens explicit cost/effect modal without spending")
		await _confirmation_visible()
		await capture("positioning-confirm-%dx%d" % [root.size.x, root.size.y])
		await click(root, game.shell.nav_buttons[&"staff"].get_global_rect().get_center())
		check(game.router.sheet == &"specialization_confirm", "renovation modal blocks unrelated navigation")
		game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await frames()
		check(SessionSnapshot.capture(session) == before and game.controller.construction.jobs.is_empty(), "back cancels choice without Cash or job")
		await _choose(2, &"executive")
		var fault: RefCounted = preload("res://tests/mobile/speedup_fault_writer.gd").new()
		fault.game = game.controller
		game.controller.saves.writer = fault.write
		await press_action(&"specialize", {"id": 2, "specialization": &"executive"})
		check(SessionSnapshot.capture(session) == before and game.controller.construction.jobs.is_empty() and game.shell.message.text == TranslationServer.translate("save.error.write"), "storage failure cannot charge a touch renovation")
		check(fault.nested_error == "speedup.error.busy" and fault.build_error == "speedup.error.busy", "reentrant writer cannot tick or buy another construction")
		await capture("positioning-save-error-%dx%d" % [root.size.x, root.size.y])
		game.controller.saves.writer = AtomicJSONStore.write
		fault.game = null
		await press_action(&"specialize", {"id": 2, "specialization": &"executive"})
		check(game.router.sheet == &"construction" and session.hotel.by_id(2).specialization_id.is_empty() and session.economy.cash == int(before.economy.cash) - 650, "retry pays once and operates with previous positioning")
		check(_has_text(MobileLabels.construction_name(game.controller.construction.jobs[0])), "constructor names selected branch in all locales")
		for entry: Dictionary in [{"id": 3, "branch": &"comfort"}, {"id": 4, "branch": &"economy"}]:
			await _choose(entry.id, entry.branch)
			await press_action(&"specialize", {"id": entry.id, "specialization": entry.branch})
		check(game.controller.construction.jobs.size() == 3 and game.controller.construction.jobs.back().slot == -1, "touch queues all branches in two free crews")
		await capture("positioning-queued-%dx%d" % [root.size.x, root.size.y])
		await click(root, game.shell.nav_buttons[&"hotel"].get_global_rect().get_center())
		await press_inspect(&"construction", 1)
		await press_action(&"request_speedup", {"id": 1, "item": &"5m"})
		await press_action(&"use_speedup", {"id": 1, "item": &"5m", "operation_id": 1})
		check(session.hotel.by_id(2).specialization_id == &"executive" and game.controller.inventory.quantity(&"5m") == 0 and game.controller.construction.by_id(3).slot >= 0, "one free speedup finishes paid branch and starts FIFO job")
		await click(root, game.shell.nav_buttons[&"hotel"].get_global_rect().get_center())
		await press_inspect(&"construction", 2)
		await press_action(&"request_construction_cancel", {"id": 2})
		var cash := session.economy.cash
		await press_action(&"cancel_construction", {"id": 2})
		check(session.economy.cash == cash + 550 and session.hotel.by_id(3).specialization_id.is_empty() and game.controller.inventory.quantity(&"5m") == 0, "cancel refunds only paid renovation Cash")
		await _choose(3, &"comfort")
		await press_action(&"specialize", {"id": 3, "specialization": &"comfort"})
		await finish_construction()
		check(session.hotel.by_id(2).specialization_id == &"executive" and session.hotel.by_id(3).specialization_id == &"comfort" and session.hotel.by_id(4).specialization_id == &"economy", "all branch deadlines yield actual room state")
		await _open_room(3)
		await press_inspect(&"room_specializations", 3)
		check(_button(&"request_specialization", &"comfort").disabled, "current branch cannot rebill")
		await capture("positioning-current-%dx%d" % [root.size.x, root.size.y])
		session.progression.evaluate({"bookings": 10, "meals": 5, "cleaned": 5})
		game._refresh()
		await _open_room(2)
		check(not _button(&"upgrade").disabled, "steady-service milestone enables N4 without UI restart")
		await press_action(&"upgrade", {"id": 2})
		check(session.hotel.by_id(2).level == 3, "N4 stays pending during paid timer")
		await finish_construction()
		await _open_room(2)
		check(session.hotel.by_id(2).level == 4 and _button(&"upgrade").disabled, "N4 completes and N5 remains gated")
		await capture("positioning-level-four-%dx%d" % [root.size.x, root.size.y])
		session.progression.evaluate({"completed": 20, "reputation": 65})
		game._refresh()
		check(not _button(&"upgrade").disabled, "trusted-hotel milestone enables N5 in open sheet")
		await press_action(&"upgrade", {"id": 2})
		await finish_construction()
		await _open_room(2)
		check(session.hotel.by_id(2).level == 5 and _button(&"upgrade") == null and session.hotel.by_id(2).specialization_id == &"executive", "N5 is maximum while preserving specialization")
		await capture("positioning-level-five-%dx%d" % [root.size.x, root.size.y])
		var loaded := SaveService.restore(AtomicJSONStore.read(game.controller.saves.path).data)
		check(loaded.error.is_empty() and loaded.session.hotel.by_id(2).level == 5 and loaded.session.hotel.by_id(3).specialization_id == &"comfort", "touch levels and branches persist coherently")
		game.queue_free()
		current_scene = null
		await frames(4)
		game = null
	finish("room_positioning_touch", {"dimensions": 3, "input": "InputEventScreenTouch through viewport", "branches": 3, "levels": [3, 4, 5]})

func _open_room(id: int) -> void:
	await click(root, game.shell.nav_buttons[&"hotel"].get_global_rect().get_center())
	await press_link(&"operations")
	await press_inspect(&"room", id)

func _choose(id: int, branch: StringName) -> void:
	await _open_room(id)
	await press_inspect(&"room_specializations", id)
	await press_action(&"request_specialization", {"id": id, "specialization": branch})
	await _confirmation_visible()

func _button(action: StringName, branch: StringName = &"") -> Button:
	for button: Button in game.shell.sheet_content.find_children("*", "Button", true, false):
		if button.get_meta("mobile_action", &"") == action and (branch.is_empty() or button.get_meta("arguments", {}).get("specialization", &"") == branch):
			return button
	return null

func _has_text(value: String) -> bool:
	return game.shell.sheet_content.find_children("*", "Label", true, false).any(func(label: Label) -> bool: return label.text == value)

func _confirmation_visible() -> void:
	await frames()
	var button := _button(&"specialize")
	check(button != null and not button.disabled, "confirmation has eligible renovation action")
	if button == null:
		return
	game.shell.sheet_scroll.ensure_control_visible(button)
	await frames()
	check(game.shell.sheet_scroll.get_global_rect().encloses(button.get_global_rect()), "confirmation target fits clipped scroll viewport")
	await _check_button_text(button)

func _check_button_text(button: Button) -> void:
	await frames()
	var available := button.size.x - button.get_theme_stylebox("normal").get_minimum_size().x - 32 - button.get_theme_constant("h_separation")
	var width := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
	check(width <= available and button.size.y >= 48, "selected branch remains legible on 48-unit touch action %s %s %s/%s" % [root.size, button.text, width, available])
