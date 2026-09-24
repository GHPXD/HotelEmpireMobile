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
	print(JSON.stringify({"suite": "ui_management", "failures": failures}))
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)

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

