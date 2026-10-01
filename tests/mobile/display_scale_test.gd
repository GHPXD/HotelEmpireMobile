extends "res://tests/mobile/render_harness.gd"
## Uses actual canvas_items stretch and physical touch coordinates at 1x/2x/3x.

func run() -> void:
	for scenario: Dictionary in [{"logical": Vector2i(360, 780), "scale": 1.0}, {"logical": Vector2i(360, 780), "scale": 2.0}, {"logical": Vector2i(360, 780), "scale": 3.0}, {"logical": Vector2i(844, 390), "scale": 2.0}, {"logical": Vector2i(1280, 800), "scale": 1.0}]:
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		root.content_scale_size = Vector2i.ZERO
		root.size = Vector2i(Vector2(scenario.logical) * scenario.scale)
		var game: AppRoot = preload("res://core/application/app_root.tscn").instantiate()
		game.display_scale.override_scale = scenario.scale
		game.controller.saves.path = "user://density-%d-%d.json" % [scenario.logical.x, int(scenario.scale)]
		game.controller.saves.legacy_path = "user://none-density.json"
		root.add_child(game)
		current_scene = game
		game.set_process(false)
		await frames(5)
		check(game.size.distance_to(Vector2(scenario.logical)) < 2, "logical canvas follows device scale")
		var raw_size := Vector2(root.size)
		game.safe_area.override_safe_area = Rect2(Vector2(12, 24) * scenario.scale, raw_size - Vector2(24, 42) * scenario.scale)
		game.safe_area.override_window_size = raw_size
		game.safe_area.refresh()
		await frames(5)
		var physical_scale := raw_size / root.get_visible_rect().size
		check(absf(physical_scale.x - scenario.scale) < 0.01 and absf(physical_scale.y - scenario.scale) < 0.01, "physical canvas scale is correct")
		for button: Button in game.shell.nav_buttons.values():
			check(button.size.y * physical_scale.y >= 48 * scenario.scale - 1, "touch target keeps physical density")
			var physical_rect := Rect2(button.get_global_rect().position * physical_scale, button.size * physical_scale)
			check(game.safe_area.override_safe_area.encloses(physical_rect), "physical target avoids cutout")
		var point: Vector2 = game.shell.nav_buttons[&"build"].get_global_rect().get_center() * physical_scale
		await click(root, point)
		check(game.router.screen == &"build", "physical touch reaches stretched button")
		check(game.view.size.y >= 100, "stretched hotel remains visible")
		await capture("density-%d-%dx" % [scenario.logical.x, int(scenario.scale)])
		# Rotation updates the canvas instead of shrinking the UI to a fixed base.
		root.size = Vector2i(root.size.y, root.size.x)
		await frames(6)
		check(game.size.distance_to(Vector2(scenario.logical.y, scenario.logical.x)) < 2, "rotation preserves logical scale")
		game.queue_free()
		current_scene = null
		await frames(4)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	finish("mobile_display_scale", {"cases": 5, "densities": [1, 2, 3]})
