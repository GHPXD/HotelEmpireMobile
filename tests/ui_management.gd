extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Node = load("res://core/game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var session := SimulationRunner.make_hotel(321, "standard", 250000)
	session.speed = 0
	game._replace_session(session)
	game.selection = session.hotel.rooms[0].id
	game._refresh()
	for frame in 5:
		await process_frame
	check(not game.staff_panel.visible, "staff window closed on boot")
	var room := session.hotel.by_id(game.selection)
	var initial_cash: int = session.economy.cash
	var price: int = room.next_upgrade().cost
	var scroll: ScrollContainer = game.hud.upgrade_button.get_parent().get_parent()
	scroll.ensure_control_visible(game.hud.upgrade_button)
	for frame in 3:
		await process_frame
	await click(root, game.hud.upgrade_button.get_global_rect().get_center())
	check(room.level == 2 and session.economy.cash == initial_cash - price, "upgrade via real button")
	check(game.hud.inspector.text.contains("N2"), "inspector updates level")
	check(not game.hud.tariff_choice.visible, "reception tariff hidden")
	var restaurant: RoomState
	for candidate: RoomState in session.hotel.rooms:
		if candidate.definition_id == &"restaurant":
			restaurant = candidate
	game.selection = restaurant.id
	game._refresh()
	for frame in 3:
		await process_frame
	scroll.ensure_control_visible(game.hud.tariff_choice)
	game.hud.tariff_choice.grab_focus()
	await key(root, KEY_SPACE)
	await key(game.hud.tariff_choice.get_popup(), KEY_DOWN)
	await key(game.hud.tariff_choice.get_popup(), KEY_ENTER)
	check(restaurant.price_percent == 125, "keyboard applies premium tariff")
	check(session.speed == 0, "tariff keyboard activation preserves pause")
	check(game.hud.inspector.text.contains("Tarifa: $ 35"), "inspector displays effective tariff")
	check(not game.hud.tariff_effect.visible, "lodging consequence not advertised for services")
	for candidate: RoomState in session.hotel.rooms:
		if candidate.definition_id == &"bedroom":
			game.selection = candidate.id
			break
	game._refresh()
	check(game.hud.tariff_effect.visible and game.hud.tariff_effect.text.contains("125%: -7.5 a -5.0"), "lodging preview shows profile range before purchase")
	for button: Node in game.hud.find_children("*", "Button", true, false):
		if button.text == "Equipe":
			await click(root, button.get_global_rect().get_center())
	check(game.staff_panel.visible, "staff window opens through toolbar")
	var panel: StaffPanel = game.staff_panel
	# Select a cleaner via keyboard in the standard OptionButton control.
	panel.employee_choice.grab_focus()
	await key(panel, KEY_SPACE)
	await key(panel.employee_choice.get_popup(), KEY_DOWN)
	await key(panel.employee_choice.get_popup(), KEY_DOWN)
	await key(panel.employee_choice.get_popup(), KEY_ENTER)
	var actor: ActorState = session.actors.get(panel.employee_choice.get_selected_id())
	check(actor != null and actor.role == &"cleaner", "keyboard selects cleaner")
	panel.destination_choice.grab_focus()
	await key(panel, KEY_SPACE)
	await key(panel.destination_choice.get_popup(), KEY_DOWN)
	await key(panel.destination_choice.get_popup(), KEY_DOWN)
	await key(panel.destination_choice.get_popup(), KEY_ENTER)
	await key(panel, KEY_TAB)
	await key(panel, KEY_SPACE)
	check(actor.preferred_floor == 1, "apply floor assignment through UI")
	await RenderingServer.frame_post_draw
	panel.get_texture().get_image().save_png("res://.runtime/m3-staff.png")
	panel.hide()
	for button: Node in game.hud.find_children("*", "Button", true, false):
		if button.text == "Finanças":
			await click(root, button.get_global_rect().get_center())
	check(game.finances_dialog.visible and game.finances_dialog.dialog_text.contains("CUSTO FIXO"), "financial forecast reachable")
	game.finances_dialog.hide()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.runtime/m3-upgrade.png")
	await staff_icons(game)
	print(JSON.stringify({"suite": "ui_management", "failures": failures}))
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)

func staff_icons(game: Node) -> void:
	var original_size := root.size
	var original_large: bool = game.large_text
	var cases := 0
	for resolution: Vector2i in [Vector2i(1024, 640), Vector2i(1280, 800), Vector2i(1600, 900)]:
		root.size = resolution
		for large: bool in [false, true]:
			if game.large_text != large:
				game._toggle_text_size()
			var session := HotelSession.new(817)
			session.speed = 0
			session.hotel.add_floor()
			var reception := session.hotel.build(HotelCatalog.room(&"reception"), 3, 0)
			session.hotel.build(HotelCatalog.room(&"elevator"), 15, 0)
			game._replace_session(session)
			for frame in 4:
				await process_frame
			for definition: EmployeeDefinition in HotelSession.EMPLOYEES:
				var button: Button = game.hud.hire_buttons[definition.id]
				check(button.icon == HotelArt.staff_icon(definition.id) and button.icon.get_image().detect_alpha() != Image.ALPHA_NONE, "dedicated transparent staff hire icon")
				check(button.text.contains(definition.display_name) and button.text.contains(str(definition.hire_cost)) and button.tooltip_text.contains(str(definition.salary)), "hire role, price and salary remain native text")
				game.hud.sidebar_scroll.ensure_control_visible(button)
				for frame in 3:
					await process_frame
				check(game.hud.sidebar_scroll.get_global_rect().encloses(button.get_global_rect()) and root.get_visible_rect().encloses(button.get_global_rect()), "hire button fits smallest/largest viewport and both text sizes")
				var cash := session.economy.cash
				var count := session.actors.size()
				await click(root, button.get_global_rect().get_center())
				button.grab_focus()
				await key(root, KEY_ENTER)
				check(session.economy.cash == cash - definition.hire_cost * 2 and session.actors.size() == count + 2, "mouse and Enter hire exactly one employee each at correct price")
				var actor: ActorState = session.actors.get(session.next_actor_id - 1)
				check(actor != null and actor.role == definition.id, "hire icon selects correct employee role")
				if actor == null:
					continue
				game.staff_panel.open_for(session)
				var panel: StaffPanel = game.staff_panel
				for index in panel.employee_choice.item_count:
					if panel.employee_choice.get_item_id(index) == actor.id:
						panel.employee_choice.select(index)
						panel.employee_choice.item_selected.emit(index)
				for frame in 3:
					await process_frame
				check(panel.role_icon.texture == button.icon and panel.role_icon.visible, "assignment icon follows selected role")
				check(panel.role_icon.size.is_equal_approx(Vector2(48, 48)) and Rect2(Vector2.ZERO, panel.size).encloses(panel.role_icon.get_global_rect()), "role icon fits staff window")
				check(panel.role_icon.mouse_filter == Control.MOUSE_FILTER_IGNORE and panel.role_icon.focus_mode == Control.FOCUS_NONE, "decorative staff icon does not intercept input")
				panel.destination_choice.select(1 if actor.role == &"receptionist" else 2)
				panel.apply_button.grab_focus()
				await key(panel, KEY_SPACE)
				check(actor.preferred_room == reception.id if actor.role == &"receptionist" else actor.preferred_floor == 1, "assignment remains functional with role icon")
				if resolution == Vector2i(1024, 640) and large:
					await RenderingServer.frame_post_draw
					panel.get_texture().get_image().save_png("res://.runtime/m7-staff-icon-%s.png" % actor.role)
				panel.hide()
				cases += 1
			var restored := SessionSnapshot.restore(SessionSnapshot.capture(session))
			check(restored.error.is_empty(), "hired staff and assignments restore")
			if restored.error.is_empty():
				game.staff_panel.open_for(restored.session)
				check(game.staff_panel.role_icon.texture == HotelArt.staff_icon(&"receptionist"), "restored staff resolve same role icon")
				game.staff_panel.hide()
			session.economy.cash = 0
			var before := SessionSnapshot.capture(session)
			var denied: Button = game.hud.hire_buttons[&"cleaner"]
			game.hud.sidebar_scroll.ensure_control_visible(denied)
			for frame in 3:
				await process_frame
			await click(root, denied.get_global_rect().get_center())
			check(SessionSnapshot.capture(session) == before and game.hud.message.text.contains("insuficiente"), "unaffordable hiring preserves session and explains failure")
			if resolution == Vector2i(1024, 640) and large:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://.runtime/m7-staff-hiring.png")
			game.staff_panel.open_for(HotelSession.new())
			check(not game.staff_panel.role_icon.visible and game.staff_panel.role_icon.texture == null, "empty staff list clears previous icon")
			game.staff_panel.hide()
	root.size = original_size
	if game.large_text != original_large:
		game._toggle_text_size()
	print(JSON.stringify({"staff_icon_cases": cases, "hires_verified": 24, "failures": failures}))

func click(viewport: Viewport, point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	viewport.push_input(motion, true)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		viewport.push_input(event, true)
		await process_frame
	await process_frame

func key(viewport: Viewport, code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		if viewport is PopupMenu:
			event.window_id = viewport.get_window_id()
			Input.parse_input_event(event)
		else:
			viewport.push_input(event, true)
		await process_frame
	await process_frame

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

