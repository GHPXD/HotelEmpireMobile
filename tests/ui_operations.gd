extends "res://tests/ui_management.gd"

func run() -> void:
	var game: Node = load("res://core/game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var old_text: bool = game.large_text
	var session := SimulationRunner.make_hotel(77, "standard", 250000)
	session.speed = 0
	game._replace_session(session)
	var dirty: RoomState = session.hotel.rooms[5]
	dirty.dirty = true
	for frame in 5:
		await process_frame
	var snapshot := SessionSnapshot.capture(session)
	check(game.hud.build_buttons[&"reception"].visible, "empty search shows catalog")
	game.hud.build_search.grab_focus()
	for letter in "cafe":
		var event := InputEventKey.new()
		event.unicode = letter.unicode_at(0)
		event.pressed = true
		root.push_input(event, true)
		await process_frame
	check(game.hud.build_search.text == "cafe", "search accepts keyboard text")
	check(game.hud.build_buttons[&"cafe"].visible and not game.hud.build_buttons[&"restaurant"].visible, "accent-insensitive catalog search")
	game.hud.build_search.select_all()
	for letter in "inexistente":
		var event := InputEventKey.new()
		event.unicode = letter.unicode_at(0)
		event.pressed = true
		root.push_input(event, true)
		await process_frame
	check(game.hud.catalog_count.text.contains("Nenhuma"), "empty search feedback")
	game.hud.reset_catalog()
	# Open using the global shortcut and operate filters using their real popup input.
	game.hud.open_button.grab_focus()
	await key(root, KEY_F2)
	var panel: OperationsPanel = game.operations_panel
	check(panel.visible and panel.category_choice.has_focus(), "F2 opens with useful initial focus")
	check(panel.summary_label.text.contains("0/12") and panel.rows.size() == 17, "live summary and initial room list")
	check(panel.summary_label.text.contains("Presentes com check-in: 0 • —") and panel.summary_label.text.contains("Presentes sem check-in: 0 • —"), "empty cohorts display no observation rather than zero satisfaction")
	panel.status_choice.grab_focus()
	await key(panel, KEY_SPACE)
	await key(panel.status_choice.get_popup(), KEY_DOWN)
	await key(panel.status_choice.get_popup(), KEY_DOWN)
	await key(panel.status_choice.get_popup(), KEY_ENTER)
	check(panel.rows.size() == 1 and panel.rows[0].id == dirty.id, "keyboard filter finds dirty room")
	panel.room_list.grab_focus()
	await key(panel, KEY_DOWN)
	game._refresh()
	check(not panel.inspect_button.disabled and panel.selected_details.text.contains("LIMPAR"), "selected room details visible")
	await RenderingServer.frame_post_draw
	panel.get_texture().get_image().save_png("res://.runtime/m6-operations.png")
	await key(panel, KEY_ENTER)
	check(not panel.visible and game.selection == dirty.id, "Enter inspects filtered room")
	var center: Vector2 = game.view.room_rect(dirty.column, dirty.floor_index, dirty.definition().width).get_center()
	check(center.distance_to(game.view.size / 2.0) < 1.0, "inspection centers camera")
	check(game.hud.operations_button.has_focus(), "focus returns to operations opener")
	await key(root, KEY_F2)
	dirty.dirty = false
	game._refresh()
	check(panel.rows.is_empty() and panel.inspect_button.disabled and panel.count_label.text.contains("Nenhuma"), "live filter handles room no longer dirty")
	await key(panel, KEY_ESCAPE)
	check(not panel.visible and game.hud.operations_button.has_focus(), "Escape closes and restores focus")
	# Text-size preference is independent of the paused simulation.
	if not game.large_text:
		await key(root, KEY_F4)
	check(game.large_text and game.hud.theme.default_font_size == 20 and UIPreferences.load_large_text(), "F4 enlarges text and persists preference")
	game.hud.session_buttons["Equipe"].grab_focus()
	await key(root, KEY_ENTER)
	check(game.staff_panel.visible and game.staff_panel.employee_choice.has_focus(), "staff modal keyboard entry")
	await RenderingServer.frame_post_draw
	check(game.staff_panel.size.y <= root.get_visible_rect().size.y, "staff panel fits visible viewport with large text")
	game.staff_panel.get_texture().get_image().save_png("res://.runtime/m6-large-staff.png")
	await key(game.staff_panel, KEY_ESCAPE)
	check(not game.staff_panel.visible and game.hud.session_buttons["Equipe"].has_focus(), "staff Escape restores opener")
	game.hud.session_buttons["Finanças"].grab_focus()
	await key(root, KEY_ENTER)
	check(game.finances_dialog.visible and game.finances_dialog.details.has_focus(), "finance modal keyboard entry")
	await RenderingServer.frame_post_draw
	check(game.finances_dialog.size.y <= root.get_visible_rect().size.y, "finance panel fits visible viewport with large text")
	game.finances_dialog.get_texture().get_image().save_png("res://.runtime/m6-large-finances.png")
	await key(game.finances_dialog, KEY_ESCAPE)
	check(not game.finances_dialog.visible and game.hud.session_buttons["Finanças"].has_focus(), "finance Escape restores opener")
	panel.reset_filters()
	await key(root, KEY_F2)
	for index in panel.rows.size():
		if panel.rows[index].transport:
			panel.room_list.select(index)
			break
	panel.refresh(session)
	check(panel.selected_details.text.contains("Sem embarques registrados"), "selected elevator distinguishes absent history")
	for frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	check(panel.size.y <= root.get_visible_rect().size.y, "operations panel fits visible viewport with large text")
	panel.get_texture().get_image().save_png("res://.runtime/m6-large-panel.png")
	await key(panel, KEY_ESCAPE)
	for frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.runtime/m6-large-hud.png")
	dirty.dirty = true
	check(SessionSnapshot.capture(session) == snapshot, "filters focus and text size do not mutate gameplay")
	var admitted := session.spawn_guest()
	admitted.checked_in = true
	admitted.happiness = 80
	var arriving := session.spawn_guest()
	arriving.happiness = 40
	game._show_operations()
	check(panel.summary_label.text.contains("Presentes com check-in: 1 • 80.0/100"), "nonempty admitted cohort displayed")
	check(panel.summary_label.text.contains("Presentes sem check-in: 1 • 40.0/100"), "nonempty arrival cohort displayed")
	var summary_scroll: ScrollContainer = panel.summary_label.get_parent()
	for frame in 3:
		await process_frame
	summary_scroll.grab_focus()
	await key(panel, KEY_DOWN)
	await key(panel, KEY_DOWN)
	for frame in 3:
		await process_frame
	check(summary_scroll.scroll_vertical > 0 or panel.summary_label.size.y <= summary_scroll.size.y, "summary can be read with keyboard at large text")
	var scroll_position := summary_scroll.scroll_vertical
	arriving.happiness = 45
	panel.refresh(session)
	for frame in 3:
		await process_frame
	check(panel.summary_label.text.contains("Presentes sem check-in: 1 • 45.0/100") and summary_scroll.scroll_vertical == scroll_position, "live value update preserves reading position")
	await RenderingServer.frame_post_draw
	panel.get_texture().get_image().save_png("res://.runtime/satisfaction-groups.png")
	await key(panel, KEY_ESCAPE)
	game._replace_session(HotelSession.new())
	game.session.speed = 0
	check(game.hud.build_search.text.is_empty() and panel.status_choice.selected == 0 and game.large_text, "new session resets filters but keeps device preference")
	if game.large_text != old_text:
		game._toggle_text_size()
	print(JSON.stringify({"suite": "ui_operations", "failures": failures}))
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
