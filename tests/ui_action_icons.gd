extends "res://tests/ui_management.gd"
## Exercise decorated commands through native mouse and keyboard input.

func run() -> void:
	var game: Node = load("res://core/game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.audio.enabled = false
	var cases := 0
	for resolution: Vector2i in [Vector2i(1024, 640), Vector2i(1280, 800), Vector2i(1600, 900)]:
		root.size = resolution
		for large: bool in [false, true]:
			if game.large_text != large:
				game._toggle_text_size()
			for action: StringName in [&"add_floor", &"upgrade", &"demolish"]:
				for keyboard: bool in [false, true]:
					var session := HotelSession.new(844)
					session.speed = 0
					var room := session.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
					game._replace_session(session)
					game._inspect_room(room.id)
					var button: Button = game.hud.action_buttons[action]
					for frame in 3:
						await process_frame
					game.hud.sidebar_scroll.ensure_control_visible(button)
					for frame in 4:
						await process_frame
					check(button.icon == HotelArt.action_icon(action) and button.icon.get_width() == 256, "dedicated command icon uses budgeted import")
					check(button.icon.get_image().detect_alpha() != Image.ALPHA_NONE, "command icon preserves transparency")
					check(button.expand_icon and button.get_theme_constant("icon_max_width") == 32, "command image constrained to 32px")
					check(game.hud.sidebar_scroll.get_global_rect().encloses(button.get_global_rect()) and root.get_visible_rect().encloses(button.get_global_rect()), "command fits scrolled viewport: %s %s large=%s keyboard=%s button=%s scroll=%s" % [action, resolution, large, keyboard, button.get_global_rect(), game.hud.sidebar_scroll.get_global_rect()])
					check(button.size.x >= button.get_combined_minimum_size().x and button.size.y >= button.get_combined_minimum_size().y, "icon and native label fit minimum size")
					var cash := session.economy.cash
					var floors := session.hotel.floors
					var upgrade_cost := room.next_upgrade().cost
					if resolution == Vector2i(1024, 640) and large and not keyboard and action == &"upgrade":
						await RenderingServer.frame_post_draw
						root.get_texture().get_image().save_png("res://.runtime/m7-action-upgrade.png")
					if keyboard:
						button.grab_focus()
						await key(root, KEY_ENTER)
					else:
						await click(root, button.get_global_rect().get_center())
					match action:
						&"add_floor":
							check(session.hotel.floors == floors + 1 and session.economy.cash == cash - 750 and button.text.contains("750"), "floor icon buys exactly one floor at displayed cost")
						&"upgrade":
							check(room.level == 2 and session.economy.cash == cash - upgrade_cost and game.hud.inspector.text.contains("N2"), "upgrade icon applies selected room level and cost")
						&"demolish":
							check(session.hotel.by_id(room.id) == null and session.economy.cash == cash and game.selection == -1, "demolition icon removes selection without refund")
					check(session.tick_count == 0 and session.speed == 0, "command input preserves pause")
					if resolution == Vector2i(1024, 640) and large and not keyboard and action == &"add_floor":
						for frame in 3:
							await process_frame
						game.hud.sidebar_scroll.ensure_control_visible(button)
						for frame in 3:
							await process_frame
						await RenderingServer.frame_post_draw
						root.get_texture().get_image().save_png("res://.runtime/m7-action-%s.png" % action)
					cases += 1
	# Failed commands cannot mutate the authoritative session.
	var denied := HotelSession.new(845)
	denied.speed = 0
	var selected := denied.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
	denied.economy.cash = 0
	game._replace_session(denied)
	game._inspect_room(selected.id)
	check(game.hud.upgrade_button.disabled and game.hud.upgrade_button.icon == HotelArt.action_icon(&"upgrade"), "unaffordable upgrade retains icon and stays disabled")
	var before := SessionSnapshot.capture(denied)
	await press_action(game, &"upgrade")
	await press_action(game, &"add_floor")
	check(SessionSnapshot.capture(denied) == before, "unaffordable commands preserve snapshot")
	game.selection = -1
	game._refresh()
	await press_action(game, &"demolish")
	check(SessionSnapshot.capture(denied) == before and game.hud.message.text.contains("Selecione"), "empty demolition preserves session and explains selection")
	check(not game.hud.upgrade_button.visible, "no selection hides upgrade command")
	print(JSON.stringify({"suite": "ui_action_icons", "command_cases": cases, "action_icons": 3, "failures": failures}))
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)

func press_action(game: Node, action: StringName) -> void:
	var button: Button = game.hud.action_buttons[action]
	game.hud.sidebar_scroll.ensure_control_visible(button)
	for frame in 3:
		await process_frame
	await click(root, button.get_global_rect().get_center())
