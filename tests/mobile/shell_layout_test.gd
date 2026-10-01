extends SceneTree
## Runs headless for geometry and natively for rendered screenshots of the same cases.

var failures: int = 0
var checks: int = 0
var screenshots: Array[String] = []
var game: AppRoot
var progress_time: RefCounted

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	for dimensions in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(360, 780), Vector2i(844, 390), Vector2i(960, 540), Vector2i(1280, 800)]:
		root.size = dimensions
		game = preload("res://core/application/app_root.tscn").instantiate()
		progress_time = preload("res://tests/mobile/fake_progress_time.gd").new()
		game.controller.progress_clock = progress_time.clock()
		game.controller.saves.clock = progress_time.utc
		game.controller.saves.path = "user://layout-%dx%d.json" % [dimensions.x, dimensions.y]
		game.controller.saves.legacy_path = "user://no-legacy-layout.json"
		root.add_child(game)
		current_scene = game
		game.set_process(false)
		await frames(5)
		check(game.controller.session != null and game.view != null, "mobile root boots")
		game.safe_area.override_safe_area = Rect2(20, 12, dimensions.x - 40, dimensions.y - 30)
		game.safe_area.override_window_size = dimensions
		game.safe_area.refresh()
		await frames(5)
		var safe_rect := Rect2(20, 12, dimensions.x - 40, dimensions.y - 30)
		for button: Button in game.shell.nav_buttons.values():
			check(inside(safe_rect, button.get_global_rect()), "navigation inside cutout safe area %s %s" % [dimensions, button.get_global_rect()])
			check(button.size.y >= 48, "navigation target height")
		check(game.view.size.y >= 100, "hotel remains visible")
		game._navigate(&"build")
		await frames(3)
		check(game.shell.sheet.visible and game.shell.sheet_scroll.size.y > 0, "scrollable build sheet")
		check(game.view.size.y >= 100 and not game.view.get_global_rect().intersects(game.shell.sheet.get_global_rect()), "hotel remains visible without context overlap")
		check(inside(Rect2(Vector2.ZERO, game.shell.size), game.shell.sheet.get_rect()), "sheet fits shell")
		game._choose_build(HotelCatalog.room(&"reception"))
		await frames(2)
		var point := game.view.room_rect(0, 0, 3).get_center()
		var before_cash := game.controller.session.economy.cash
		game.gestures.handle(touch(0, point, true))
		game.gestures.handle(touch(0, point, false))
		await frames(2)
		check(game.router.sheet == &"build_confirm" and game.shell.modal_blocker.visible, "tap opens explicit construction confirmation")
		check(game.controller.session.hotel.rooms.is_empty(), "preview cannot spend cash")
		game._confirm_build()
		await frames(2)
		check(game.controller.session.hotel.rooms.is_empty() and game.controller.construction.jobs.size() == 1 and game.controller.session.economy.cash == before_cash - 800, "confirmed construction checkpoints a paid pending job")
		game.controller.enter_background()
		progress_time.advance(10000)
		game.controller.resume()
		await frames(2)
		check(game.controller.session.hotel.rooms.size() == 1 and game.controller.session.economy.cash < before_cash, "confirmed construction integrates domain/save")
		check(not game.shell.modal_blocker.visible, "confirm releases overlay")
		var origin := game.view.world_to_screen(Vector2.ZERO)
		game._pinch(1.2, origin, origin + Vector2(5, 10))
		check(game.view.world_to_screen(Vector2.ZERO).distance_to(origin + Vector2(5, 10)) < 0.01, "pinch preserves focus across zoom")
		for locale in ["pt_BR", "en", "es"]:
			MobileLocale.install(locale)
			game._navigate(&"staff")
			await frames(3)
			game._refresh()
			check(not game.shell.cash.text.begins_with("ui."), "localized metrics " + locale)
			check(game.shell.nav_buttons[&"build"].text == TranslationServer.translate("ui.build"), "locale change updates navigation " + locale)
			check_metric_words(locale + " " + str(dimensions))
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				var path := "user://mobile-%dx%d-%s.png" % [dimensions.x, dimensions.y, locale]
				var image := root.get_texture().get_image()
				check(not image.is_empty() and image.save_png(path) == OK, "rendered capture")
				screenshots.append(ProjectSettings.globalize_path(path))
		game._navigate(&"settings")
		game._toggle_text()
		game.shell.set_message("construction.purchase_hint")
		await frames(3)
		check(inside(Rect2(Vector2.ZERO, game.shell.size), game.shell.sheet.get_rect()), "large text sheet stays inside")
		check_metric_words("large text " + str(dimensions))
		check(inside(Rect2(Vector2.ZERO, game.shell.size), game.shell.body.get_rect()), "long feedback and enlarged type preserve shell bounds")
		for button: Button in game.shell.nav_buttons.values():
			check(inside(safe_rect, button.get_global_rect()), "large text navigation inside cutout safe area %s %s" % [dimensions, button.get_global_rect()])
		game._toggle_text()
		game.controller.enter_background()
		var tick_count := game.controller.session.tick_count
		game.controller.advance(1000)
		check(game.controller.session.tick_count == tick_count, "app background does not simulate")
		game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		check(game.controller.background, "focus-in cannot resume an OS-paused app")
		game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		check(not game.controller.background, "resume requires active lifecycle and focus")
		game.queue_free()
		current_scene = null
		await frames(3)
		game = null
	# The audio server releases stopped playback on its own mixer thread.
	await create_timer(0.12).timeout
	print(JSON.stringify({"suite": "mobile_shell_layout", "checks": checks, "failures": failures, "screenshots": screenshots, "rendered": DisplayServer.get_name() != "headless"}))
	print("MOBILE_TEST_COMPLETE")
	quit(1 if failures else 0)

func frames(count: int) -> void:
	for frame in count:
		await process_frame

func inside(outer: Rect2, inner: Rect2) -> bool:
	return outer.grow(1).encloses(inner)

func check_metric_words(context: String) -> void:
	for label: Label in [game.shell.cash, game.shell.reputation, game.shell.guests]:
		var font := label.get_theme_font("font")
		var font_size := label.get_theme_font_size("font_size")
		for word: String in label.text.split(" ", false):
			check(font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= label.size.x, "HUD does not split a word " + context + " " + word)

func touch(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
