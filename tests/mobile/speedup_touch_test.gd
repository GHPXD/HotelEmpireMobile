extends "res://tests/mobile/touch_management_test.gd"
## Native viewport touch exercises real stock, confirmation, faults and restart.

func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	_icon()
	for scenario: Dictionary in [{"size": Vector2i(320, 568), "locale": "pt_BR", "large": false}, {"size": Vector2i(568, 320), "locale": "es", "large": true}, {"size": Vector2i(1280, 800), "locale": "en", "large": true}]:
		var dimensions: Vector2i = scenario.size
		print(JSON.stringify({"progress": "speedup_touch", "dimensions": [dimensions.x, dimensions.y]}))
		UIPreferences.save_value("locale", scenario.locale)
		UIPreferences.save_large_text(scenario.large)
		root.size = dimensions
		await _boot("full-%dx%d" % [dimensions.x, dimensions.y])
		await _full()
		await _dispose()
		await _boot("partial-%dx%d" % [dimensions.x, dimensions.y])
		await _partial()
		await _dispose()
	finish("speedup_touch", {"dimensions": 3, "input": "InputEventScreenTouch through viewport", "profiles": 6})

func _icon() -> void:
	var texture := HotelArt.action_icon(&"speedup")
	check(texture != null and maxi(texture.get_width(), texture.get_height()) == 256, "original hourglass has bounded runtime import")
	var image := texture.get_image()
	check(image.detect_alpha() != Image.ALPHA_NONE, "speedup texture has actual transparency")
	for point: Vector2i in [Vector2i.ZERO, Vector2i(image.get_width() - 1, 0), Vector2i(0, image.get_height() - 1), Vector2i(image.get_width() - 1, image.get_height() - 1)]:
		check(image.get_pixelv(point).a == 0, "speedup corner is transparent")
	check(image.get_pixel(image.get_width() / 2, image.get_height() / 2).a > 0.5, "speedup center contains visible original artwork")

func _boot(id: String, existing_path: String = "") -> void:
	game = preload("res://core/application/app_root.tscn").instantiate()
	if existing_path.is_empty():
		inject_progress_time()
	else:
		game.controller.progress_clock = progress_time.clock()
		game.controller.saves.clock = progress_time.utc
	game.controller.enable_onboarding = false
	game.controller.saves.path = existing_path if not existing_path.is_empty() else "user://speedup-touch-" + id + ".json"
	game.controller.saves.legacy_path = "user://speedup-touch-no-legacy.json"
	root.add_child(game)
	current_scene = game
	game.set_process(false)
	await frames(6)
	game.safe_area.override_safe_area = Rect2(12, 8, root.size.x - 24, root.size.y - 20)
	game.safe_area.override_window_size = root.size
	game.safe_area.refresh()
	await frames()
	check(game.controller.session != null and game.panels.inventory == game.controller.inventory, "product boots with authoritative global inventory")

func _dispose() -> void:
	game.queue_free()
	current_scene = null
	await frames(4)
	game = null

func _open_job(id: int) -> void:
	await click(root, game.shell.nav_buttons[&"hotel"].get_global_rect().get_center())
	await press_inspect(&"construction", id)

func _button(action: StringName, item: StringName = &"") -> Button:
	for button: Button in game.shell.sheet_content.find_children("*", "Button", true, false):
		if button.get_meta("mobile_action", &"") == action and (item.is_empty() or button.get_meta("arguments", {}).get("item", &"") == item):
			return button
	return null

func _reveal_confirmation() -> void:
	await frames()
	var button := _button(&"use_speedup")
	check(button != null and not button.disabled, "confirmation offers one eligible spend")
	game.shell.sheet_scroll.ensure_control_visible(button)
	await frames()
	check(game.shell.sheet_scroll.get_global_rect().encloses(button.get_global_rect()), "confirmation action fits the scroll viewport")
	check(button.icon == HotelArt.action_icon(&"speedup") and button.size.y >= 48, "confirmation uses original art and a full touch target")
	var selected := PlayerInventory.definition(game.panels.speedup_item)
	check(button.text == TranslationServer.translate("speedup.use") % MobileLabels.duration(selected.seconds * 1000), "consumable duration remains on the scrolled confirmation action")
	var available := button.size.x - button.get_theme_stylebox("normal").get_minimum_size().x - 32 - button.get_theme_constant("h_separation")
	check(button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x <= available, "confirmation action states one item and its duration without ellipsis")

func _stock_buttons(queued: bool) -> void:
	await frames()
	for item in PlayerInventory.DEFINITIONS:
		var button := _button(&"request_speedup", item.id)
		check(button != null, "each authored item has a stock action")
		if button == null:
			continue
		check(button.disabled == (queued or game.controller.inventory.quantity(item.id) == 0), "queued or empty stock cannot open a spend")
		check(button.icon == HotelArt.action_icon(&"speedup") and button.get_theme_constant("icon_max_width") == 32, "original hourglass is displayed at 32 units")
		var style := button.get_theme_stylebox("normal")
		var available := button.size.x - style.get_minimum_size().x - 32 - button.get_theme_constant("h_separation")
		var text_width := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
		check(text_width <= available, "stock and duration stay readable without ellipsis %s %s %s/%s" % [root.size, button.text, text_width, available])

func _full() -> void:
	var controller := game.controller
	var session := controller.session
	check(controller.inventory.quantity(&"5m") == 1, "fresh F2P profile owns one free welcome item")
	await build_room(&"reception", 0, 0, false)
	await build_room(&"bedroom", 3, 0, false)
	await build_room(&"restaurant", 5, 0, false)
	var cash := session.economy.cash
	await _stock_buttons(true)
	await capture("speedup-queued-%dx%d" % [root.size.x, root.size.y])
	await _open_job(2)
	await _stock_buttons(false)
	await press_action(&"request_speedup", {"id": 2, "item": &"5m"})
	check(game.router.sheet == &"speedup_confirm" and game.shell.modal_blocker.visible, "stock action opens explicit modal confirmation")
	var stock := controller.inventory.snapshot()
	var queue := controller.construction.snapshot()
	await click(root, game.shell.nav_buttons[&"staff"].get_global_rect().get_center())
	check(game.router.sheet == &"speedup_confirm", "confirmation blocks navigation")
	await _reveal_confirmation()
	await capture("speedup-confirm-%dx%d" % [root.size.x, root.size.y])
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames()
	check(controller.inventory.snapshot() == stock and controller.construction.snapshot() == queue and session.economy.cash == cash, "back leaves items and paid work intact")
	await _open_job(2)
	await press_action(&"request_speedup", {"id": 2, "item": &"5m"})
	session.speed = 0
	progress_time.advance(20000)
	controller.advance(0.01)
	game._refresh()
	await frames()
	check(controller.construction.by_id(2) == null and _button(&"use_speedup") == null and controller.inventory.snapshot() == stock, "natural completion during confirmation cannot consume an item")
	await capture("speedup-expired-%dx%d" % [root.size.x, root.size.y])
	game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await frames()
	await _open_job(3)
	await press_action(&"request_speedup", {"id": 3, "item": &"5m"})
	var fault: RefCounted = preload("res://tests/mobile/speedup_fault_writer.gd").new()
	fault.game = controller
	controller.saves.writer = fault.write
	var before := SessionSnapshot.capture(session)
	queue = controller.construction.snapshot()
	await press_action(&"use_speedup", {"id": 3, "item": &"5m", "operation_id": 1})
	check(game.router.sheet == &"speedup_confirm" and game.shell.message.text == TranslationServer.translate("save.error.write"), "storage failure is shown and keeps confirmation available")
	check(controller.inventory.snapshot() == stock and controller.construction.snapshot() == queue and SessionSnapshot.capture(session) == before, "failed touch spend preserves live hotel, cash and stock")
	await capture("speedup-save-error-%dx%d" % [root.size.x, root.size.y])
	controller.saves.writer = AtomicJSONStore.write
	fault.game = null
	await press_action(&"use_speedup", {"id": 3, "item": &"5m", "operation_id": 1})
	check(controller.construction.jobs.is_empty() and session.hotel.rooms.size() == 3 and controller.inventory.quantity(&"5m") == 0 and session.economy.cash == cash and session.tick_count == 0, "retry consumes exactly one item and finishes only the paid room")
	var events := game.analytics.pending.filter(func(event: Dictionary) -> bool: return event.name == "speedup_used")
	check(events.size() == 1 and events[0].properties == {"kind": "5m", "duration_seconds": 20.0}, "actual touch spend records one event with actual twenty-second reduction")
	var loaded := SaveService.restore(AtomicJSONStore.read(controller.saves.path).data)
	var saved_stock := PlayerInventory.new()
	check(loaded.error.is_empty() and saved_stock.restore(loaded.app_state.player_inventory) and saved_stock.quantity(&"5m") == 0 and loaded.session.hotel.rooms.size() == 3, "touch spend persists delivery and consumed stock together")
	await capture("speedup-complete-%dx%d" % [root.size.x, root.size.y])

func _partial() -> void:
	var controller := game.controller
	var session := controller.session
	# Authored late-hotel fixture; the fresh free item remains the only stock source.
	session.economy.cash = 100000
	check(session.hotel.add_floor().is_empty(), "late hotel fixture floor")
	for column in range(0, 16, 2):
		check(session.hotel.build(HotelCatalog.room(&"bedroom"), column, 0) != null, "late hotel fixture room")
	check(controller.checkpoint().is_empty(), "late hotel fixture checkpoint")
	game._refresh()
	await build_room(&"bedroom", 0, 1, false)
	var cash := session.economy.cash
	check(controller.construction.jobs[0].duration_ms == 600000, "touch investment uses authored mid-game duration")
	session.speed = 0
	progress_time.advance(10000)
	controller.advance(0.01)
	await _stock_buttons(false)
	await press_action(&"request_speedup", {"id": 1, "item": &"5m"})
	check(game.shell.sheet_content.find_children("*", "Label", true, false).any(func(label: Label) -> bool: return label.text == TranslationServer.translate("speedup.reduction") % [MobileLabels.duration(300000), MobileLabels.duration(290000)]), "confirmation states exact reduction and remaining duration")
	await _reveal_confirmation()
	await capture("speedup-partial-confirm-%dx%d" % [root.size.x, root.size.y])
	await press_action(&"use_speedup", {"id": 1, "item": &"5m", "operation_id": 1})
	check(game.router.sheet == &"construction" and controller.construction.jobs[0].end_ms - controller.progress_clock.now_ms() == 290000 and controller.inventory.quantity(&"5m") == 0 and session.hotel.rooms.size() == 8 and session.economy.cash == cash, "touch reduction leaves unfinished room and correct balance")
	await _stock_buttons(false)
	await capture("speedup-partial-%dx%d" % [root.size.x, root.size.y])
	var save_path := controller.saves.path
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	progress_time.advance(289999)
	await _dispose()
	await _boot("", save_path)
	controller = game.controller
	session = controller.session
	check(controller.construction.jobs.size() == 1 and session.hotel.rooms.size() == 8 and controller.inventory.quantity(&"5m") == 0 and session.economy.cash == cash, "OS recreation one millisecond before shortened deadline preserves consumed item")
	await _open_job(1)
	await _stock_buttons(false)
	await capture("speedup-restarted-%dx%d" % [root.size.x, root.size.y])
	progress_time.advance(1)
	controller.advance(0.01)
	game._refresh()
	await frames()
	check(controller.construction.jobs.is_empty() and session.hotel.rooms.size() == 9 and controller.inventory.quantity(&"5m") == 0 and session.tick_count == 0 and session.economy.cash == cash, "shortened deadline completes once without cash or simulation replay")
