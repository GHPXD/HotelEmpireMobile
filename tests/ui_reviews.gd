extends "res://tests/ui_new_game.gd"

func run() -> void:
	var game: Node = load("res://core/game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 4:
		await process_frame
	await click(root, game.hud.session_buttons["Avaliações"].get_global_rect().get_center())
	check(game.reviews_panel.visible and game.reviews_panel.details.text.contains("Nenhuma avaliação"), "empty history opens through toolbar")
	await key(game.reviews_panel, KEY_ESCAPE)
	var session := SimulationRunner.make_hotel(71, "standard", 250000)
	session.opened = true
	for tick in 3000:
		session.tick(0.1)
	check(not session.guests.reviews.is_empty(), "real gameplay produces reviews")
	game._replace_session(session)
	await click(root, game.hud.session_buttons["Avaliações"].get_global_rect().get_center())
	check(game.reviews_panel.details.has_focus() and game.reviews_panel.details.text.contains("Visitante"), "populated reviews focus reading area")
	var paused := SessionSnapshot.capture(session)
	game._process(1.0)
	check(SessionSnapshot.capture(session) == paused, "reading reviews pauses simulation")
	await key(game.reviews_panel, KEY_END)
	check(game.reviews_panel.details.get_v_scroll_bar().value > 0, "End scrolls review history")
	await RenderingServer.frame_post_draw
	game.reviews_panel.get_texture().get_image().save_png("res://.runtime/reviews.png")
	await key(game.reviews_panel, KEY_ESCAPE)
	check(not game.reviews_panel.visible and game.hud.session_buttons["Avaliações"].has_focus(), "Escape restores toolbar focus")
	var previous_large: bool = game.large_text
	if not game.large_text:
		game._toggle_text_size()
	game.reviews_panel.open_for(session)
	for frame in 4:
		await process_frame
	check(root.get_visible_rect().encloses(Rect2(Vector2(game.reviews_panel.position), Vector2(game.reviews_panel.size))), "large text reviews fit viewport")
	await key(game.reviews_panel, KEY_END)
	check(game.reviews_panel.details.get_v_scroll_bar().value > 0, "large text history scrolls")
	await key(game.reviews_panel, KEY_ESCAPE)
	if game.large_text != previous_large:
		game._toggle_text_size()
	game.reviews_panel.open_for(session)
	game._request_exit()
	check(game.exit_dialog.visible and not game.reviews_panel.visible, "exit closes reviews before opening confirmation")
	await dialog_key(game.exit_dialog, KEY_ESCAPE)
	check(not game.exit_dialog.visible and game.session == session, "cancel exit preserves reviewed hotel")
	game.reviews_panel.open_for(session)
	game._replace_session(HotelSession.new())
	check(not game.reviews_panel.visible and game.session.guests.reviews.is_empty(), "new hotel closes old history")
	print(JSON.stringify({"suite": "ui_reviews", "failures": failures}))
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
