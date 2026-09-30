extends "res://tests/ui_management.gd"
## Native navigation, focus and playfield cost of all six painted panel controls.

func run() -> void:
	var game: Node = load("res://core/game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var session := SimulationRunner.make_hotel(848, "standard", 250000)
	session.speed = 0
	game._replace_session(session)
	var snapshot := SessionSnapshot.capture(session)
	var panels: Dictionary = {&"finances": game.finances_dialog, &"operations": game.operations_panel, &"reviews": game.reviews_panel, &"staff": game.staff_panel, &"objectives": game.progression_panel, &"help": game.help_panel}
	var cases := 0
	var layouts: Array[Dictionary] = []
	for resolution: Vector2i in [Vector2i(1024, 640), Vector2i(1280, 800), Vector2i(1600, 900), Vector2i(3840, 2160)]:
		root.size = resolution
		for large: bool in [false, true]:
			if game.large_text != large:
				game._toggle_text_size()
			for button: Button in game.hud.management_buttons.values():
				button.icon = null
			for frame in 4:
				await process_frame
			var plain_height: float = game.hud.world_slot.size.y
			var plain_widths: Dictionary = {}
			for id: StringName in panels:
				plain_widths[id] = game.hud.management_buttons[id].get_minimum_size().x
			var maximum_button_height := 0.0
			for id: StringName in panels:
				var button: Button = game.hud.management_buttons[id]
				button.icon = HotelArt.management_icon(id)
			for frame in 4:
				await process_frame
			for button: Button in game.hud.management_buttons.values():
				maximum_button_height = maxf(maximum_button_height, button.size.y)
			var bar: HFlowContainer = game.hud.operations_button.get_parent()
			var allowed_row := maximum_button_height + bar.get_theme_constant("v_separation")
			check(game.hud.world_slot.size.y >= plain_height - allowed_row - 0.01, "six panel icons cost at most one extra toolbar row")
			layouts.append({"window": [resolution.x, resolution.y], "large_text": large, "plain_playfield_height": plain_height, "decorated_playfield_height": game.hud.world_slot.size.y})
			await RenderingServer.frame_post_draw
			var capture := root.get_texture().get_image()
			var pixel_scale := Vector2(capture.get_size()) / root.get_visible_rect().size
			for id: StringName in panels:
				var button: Button = game.hud.management_buttons[id]
				var panel: Window = panels[id]
				check(button.icon == HotelArt.management_icon(id) and button.icon.get_width() == 256 and button.icon.get_image().detect_alpha() != Image.ALPHA_NONE, "dedicated budgeted transparent management icon")
				check(not button.expand_icon and button.get_theme_constant("icon_max_width") == 28, "toolbar icon constrained to 28px and included in minimum size")
				check(button.get_minimum_size().x >= plain_widths[id] + 28, "flow button reserves real icon width")
				var margin := button.get_theme_stylebox("normal").get_content_margin(SIDE_LEFT)
				var icon_bounds := Rect2(button.global_position + Vector2(margin, (button.size.y - 28) / 2), Vector2(28, 28))
				var pixels := Rect2(icon_bounds.position * pixel_scale, icon_bounds.size * pixel_scale)
				var crop := Rect2i(pixels.position.ceil(), pixels.end.floor() - pixels.position.ceil())
				var bright := 0
				for y in range(crop.position.y, crop.end.y):
					for x in range(crop.position.x, crop.end.x):
						var color := capture.get_pixel(x, y)
						if maxf(color.r, maxf(color.g, color.b)) > 0.65:
							bright += 1
				check(bright >= 10, "actual icon area contains painted pixels beyond toolbar background")
				check(not button.text.is_empty() and root.get_visible_rect().encloses(button.get_global_rect()), "native label and decorated button fit window")
				check(button.size.x >= button.get_combined_minimum_size().x and button.size.y >= button.get_combined_minimum_size().y, "native icon and label minimum size fit")
				for sibling: Node in bar.get_children():
					if sibling is Button and sibling != button:
						check(not button.get_global_rect().intersects(sibling.get_global_rect()), "toolbar buttons do not overlap")
				for keyboard: bool in [false, true]:
					if keyboard:
						button.grab_focus()
						await key(root, KEY_ENTER)
					else:
						await click(root, button.get_global_rect().get_center())
					check(panel.visible, "management icon opens its correct panel")
					for other: Window in panels.values():
						if other != panel:
							check(not other.visible, "opening management command does not open another panel")
					check(SessionSnapshot.capture(session) == snapshot, "management navigation preserves paused session")
					await key(panel, KEY_ESCAPE)
					check(not panel.visible and button.has_focus(), "Escape closes panel and returns to decorated opener")
					cases += 1
			if resolution in [Vector2i(1024, 640), Vector2i(3840, 2160)] and large:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://.runtime/m7-management-toolbar-%d.png" % resolution.x)
	print(JSON.stringify({"suite": "ui_management_icons", "management_icons": panels.size(), "painted_areas": panels.size() * layouts.size(), "activations": cases, "layouts": layouts, "failures": failures}))
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
