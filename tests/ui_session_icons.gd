extends "res://tests/ui_new_game.gd"
## Painted native controls: on-disk continuity and destructive confirmation at each layout.

func run() -> void:
	var game: Node = load("res://core/game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var session := SimulationRunner.make_hotel(849, "standard", 250000)
	session.opened = true
	for index in 600:
		session.tick(session.rules.tick)
	session.speed = 0
	game._replace_session(session)
	game.save_path = "user://session-icons-test.json"
	var before := SessionSnapshot.capture(session)
	var activations := 0
	var confirmations := 0
	var cancellations := 0
	var layouts: Array[Dictionary] = []
	var painted_areas := 0
	for resolution: Vector2i in [Vector2i(1024, 640), Vector2i(1280, 800), Vector2i(1600, 900), Vector2i(3840, 2160)]:
		root.size = resolution
		for large: bool in [false, true]:
			if game.large_text != large:
				game._toggle_text_size()
			for button: Button in game.hud.session_icon_buttons.values():
				button.icon = null
			for frame in 4:
				await process_frame
			var plain_height: float = game.hud.world_slot.size.y
			var plain_widths: Dictionary = {}
			for id: StringName in game.hud.session_icon_buttons:
				plain_widths[id] = game.hud.session_icon_buttons[id].get_minimum_size().x
				game.hud.session_icon_buttons[id].icon = HotelArt.session_icon(id)
			for frame in 4:
				await process_frame
			var bar: HFlowContainer = game.hud.session_icon_buttons[&"save"].get_parent()
			var max_height := 0.0
			for button: Button in game.hud.session_icon_buttons.values():
				max_height = maxf(max_height, button.size.y)
			check(game.hud.world_slot.size.y >= plain_height - max_height - bar.get_theme_constant("v_separation") - 0.01, "session icons cost at most one additional toolbar row")
			layouts.append({"window": [resolution.x, resolution.y], "large_text": large, "plain_playfield_height": plain_height, "decorated_playfield_height": game.hud.world_slot.size.y})
			await RenderingServer.frame_post_draw
			var capture := root.get_texture().get_image()
			var pixel_scale := Vector2(capture.get_size()) / root.get_visible_rect().size
			for id: StringName in game.hud.session_icon_buttons:
				var button: Button = game.hud.session_icon_buttons[id]
				check(button.icon == HotelArt.session_icon(id) and button.icon.get_width() == 256 and button.icon.get_image().detect_alpha() != Image.ALPHA_NONE, "dedicated transparent budgeted session icon")
				check(not button.expand_icon and button.get_theme_constant("icon_max_width") == 28, "session icon participates in native minimum size")
				check(button.get_minimum_size().x >= plain_widths[id] + 28, "session icon reserves its real width")
				check(not button.text.is_empty() and root.get_visible_rect().encloses(button.get_global_rect()), "native session label and icon fit window")
				check(button.size.x >= button.get_combined_minimum_size().x, "native label and icon minimum fits")
				for sibling: Node in bar.get_children():
					if sibling is Button and sibling != button:
						check(not button.get_global_rect().intersects(sibling.get_global_rect()), "session toolbar buttons do not overlap")
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
				check(bright >= 10, "session icon area contains painted pixels beyond toolbar background")
				painted_areas += 1
			for keyboard: bool in [false, true]:
				await activate(game.hud.session_icon_buttons[&"save"], keyboard)
				activations += 1
				var saved_bytes := FileAccess.get_file_as_bytes(game.save_path)
				check(not saved_bytes.is_empty(), "painted save button writes file")
				var stored := SaveStore.load_session(game.save_path)
				check(stored.error.is_empty(), "saved file validates")
				if stored.error.is_empty():
					compare(before, SessionSnapshot.capture(stored.session), "painted save captures entire paused hotel")
				compare(before, SessionSnapshot.capture(game.session), "saving preserves active session")
				game._replace_session(HotelSession.new())
				for frame in 3:
					await process_frame
				await activate(game.hud.session_icon_buttons[&"load"], keyboard)
				activations += 1
				compare(before, SessionSnapshot.capture(game.session), "painted load restores entire hotel")
				check(saved_bytes == FileAccess.get_file_as_bytes(game.save_path), "loading preserves saved bytes")
				var opener: Button = game.hud.session_icon_buttons[&"new"]
				await activate(opener, keyboard)
				activations += 1
				check(game.new_dialog.visible, "painted new button still requires confirmation")
				compare(before, SessionSnapshot.capture(game.session), "opening confirmation retains hotel")
				if keyboard:
					game.new_dialog.get_ok_button().grab_focus()
					await dialog_key(game.new_dialog, KEY_ENTER)
					check(game.hotel.rooms.is_empty() and game.hotel.floors == 1 and game.session.actors.is_empty(), "confirmed new clears hotel")
					check(game.session.economy.cash == HotelSession.new().economy.cash and game.session.progression.completed.is_empty(), "new restores starting funds and objectives")
					check(game.selection == -1 and game.selected_actor == -1 and game.view.blueprint == null, "new resets selection and construction")
					confirmations += 1
				else:
					await dialog_key(game.new_dialog, KEY_ESCAPE)
					compare(before, SessionSnapshot.capture(game.session), "cancel preserves complete hotel")
					cancellations += 1
				check(not game.new_dialog.visible and opener.has_focus(), "new dialog closes and restores decorated opener focus")
				check(saved_bytes == FileAccess.get_file_as_bytes(game.save_path), "new or cancel preserves saved bytes")
				check(game.large_text == large, "device text preference survives new hotel")
				game._replace_session(stored.session)
				for frame in 3:
					await process_frame
			if resolution in [Vector2i(1024, 640), Vector2i(3840, 2160)] and large:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://.runtime/m7-session-toolbar-%d.png" % resolution.x)
	print(JSON.stringify({"suite": "ui_session_icons", "session_icons": 3, "activations": activations, "confirmations": confirmations, "cancellations": cancellations, "painted_areas": painted_areas, "layouts": layouts, "failures": failures}))
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)

func activate(button: Button, keyboard: bool) -> void:
	if keyboard:
		button.grab_focus()
		await key(root, KEY_ENTER)
	else:
		await click(root, button.get_global_rect().get_center())
