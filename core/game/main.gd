extends Node

var session := HotelSession.new()
var economy: HotelEconomy = session.economy
var hotel: HotelModel = session.hotel
var view: HotelView
var hud: HotelHUD
var selection: int = -1
var selected_actor: int = -1
var accumulator: float = 0.0
var ui_timer: float = 0.0
var save_path: String = SaveStore.DEFAULT_PATH
var new_dialog: ConfirmationDialog
var finances_dialog: FinancePanel
var staff_panel: StaffPanel
var progression_panel: ProgressionPanel
var operations_panel: OperationsPanel
var large_text: bool = false
var audio: HotelAudio
var exit_dialog: ConfirmationDialog
var exit_focus: Control
var help_panel: HotelHelpPanel
var recovery_dialog: ConfirmationDialog
var recovery_session: HotelSession
var reviews_panel: GuestReviewsPanel

func _ready() -> void:
	if OS.get_cmdline_user_args().has("--simulate"):
		call_deferred("_run_headless")
		return
	_register_input()
	audio = HotelAudio.new()
	add_child(audio)
	hud = HotelHUD.new()
	add_child(hud)
	hud.audio_requested.connect(_toggle_audio)
	hud.audio_button.text = "Som: ligado" if audio.enabled else "Som: desligado"
	view = HotelView.new()
	view.hotel = hotel
	view.session = session
	hud.world_slot.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.cell_clicked.connect(_on_cell_clicked)
	view.cancelled.connect(_cancel)
	view.actor_clicked.connect(_select_actor)
	hud.build_requested.connect(_on_build_requested)
	hud.floor_requested.connect(_add_floor)
	hud.cancel_requested.connect(_cancel)
	hud.demolish_requested.connect(_demolish)
	hud.hire_requested.connect(_hire)
	hud.speed_requested.connect(func(value: int) -> void: session.speed = value)
	hud.open_requested.connect(func() -> void: session.opened = not session.opened)
	hud.save_requested.connect(_save)
	hud.load_requested.connect(_load)
	hud.new_requested.connect(_confirm_new)
	hud.debug_requested.connect(_toggle_debug)
	hud.finances_requested.connect(_show_finances)
	hud.staff_requested.connect(_show_staff)
	hud.upgrade_requested.connect(_upgrade_selected)
	hud.tariff_requested.connect(_set_selected_tariff)
	hud.objectives_requested.connect(_show_objectives)
	hud.operations_requested.connect(_show_operations)
	hud.text_size_requested.connect(_toggle_text_size)
	operations_panel = OperationsPanel.new()
	operations_panel.theme = hud.theme
	operations_panel.filters_changed.connect(_refresh)
	operations_panel.room_requested.connect(_inspect_room)
	add_child(operations_panel)
	progression_panel = ProgressionPanel.new()
	progression_panel.theme = hud.theme
	add_child(progression_panel)
	staff_panel = StaffPanel.new()
	staff_panel.theme = hud.theme
	staff_panel.assignment_changed.connect(_refresh)
	add_child(staff_panel)
	new_dialog = ConfirmationDialog.new()
	new_dialog.theme = hud.theme
	new_dialog.title = "Novo hotel"
	new_dialog.dialog_text = "Começar do zero? Progresso não salvo será perdido.\nSeu arquivo salvo será preservado."
	new_dialog.confirmed.connect(func() -> void: _replace_session(HotelSession.new()))
	add_child(new_dialog)
	finances_dialog = FinancePanel.new()
	finances_dialog.theme = hud.theme
	finances_dialog.title = "Finanças do hotel"
	add_child(finances_dialog)
	help_panel = HotelHelpPanel.new()
	help_panel.theme = hud.theme
	add_child(help_panel)
	hud.help_requested.connect(help_panel.open_guide)
	_bind_popup(help_panel, hud.help_button)
	reviews_panel = GuestReviewsPanel.new()
	reviews_panel.theme = hud.theme
	add_child(reviews_panel)
	hud.reviews_requested.connect(func() -> void: reviews_panel.open_for(session))
	_bind_popup(reviews_panel, hud.session_buttons["Avaliações"])
	recovery_dialog = ConfirmationDialog.new()
	recovery_dialog.theme = hud.theme
	recovery_dialog.title = "Recuperar backup"
	recovery_dialog.ok_button_text = "Recuperar backup"
	recovery_dialog.cancel_button_text = "Manter partida aberta"
	recovery_dialog.dialog_hide_on_ok = false
	recovery_dialog.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recovery_dialog.confirmed.connect(_recover_save)
	recovery_dialog.canceled.connect(func() -> void: recovery_session = null)
	add_child(recovery_dialog)
	_bind_popup(recovery_dialog, hud.session_buttons["Carregar"])
	_bind_popup(operations_panel, hud.operations_button)
	_bind_popup(progression_panel, hud.objectives_button)
	_bind_popup(staff_panel, hud.session_buttons["Equipe"])
	_bind_popup(finances_dialog, hud.session_buttons["Finanças"])
	_bind_popup(new_dialog, hud.session_buttons["Novo hotel"])
	large_text = UIPreferences.load_large_text()
	hud.set_large_text(large_text)
	hotel.changed.connect(_refresh)
	_refresh()
	hud.open_button.grab_focus()
	exit_dialog = ConfirmationDialog.new()
	exit_dialog.theme = hud.theme
	exit_dialog.title = "Sair do Hotel Empire"
	exit_dialog.ok_button_text = "Salvar e sair"
	exit_dialog.cancel_button_text = "Continuar jogando"
	exit_dialog.dialog_hide_on_ok = false
	exit_dialog.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exit_dialog.add_button("Sair sem salvar", true, "discard")
	exit_dialog.confirmed.connect(_save_and_exit)
	exit_dialog.custom_action.connect(func(action: StringName) -> void:
		if action == &"discard":
			_quit_game())
	exit_dialog.canceled.connect(func() -> void:
		if is_instance_valid(exit_focus):
			exit_focus.grab_focus())
	exit_dialog.transient = true
	exit_dialog.exclusive = true
	add_child(exit_dialog)
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(_request_exit)
	if OS.get_cmdline_user_args().has("--release-smoke"):
		call_deferred("_run_release_smoke")

func _run_release_smoke() -> void:
	await preload("res://debug/release_smoke.gd").new().run(self)

func _process(delta: float) -> void:
	if hud == null or (reviews_panel != null and reviews_panel.visible) or (exit_dialog != null and exit_dialog.visible) or (help_panel != null and help_panel.visible) or (recovery_dialog != null and recovery_dialog.visible):
		return
	accumulator += minf(delta, 0.25) * session.speed
	var previous_objectives: int = session.progression.completed.size()
	while accumulator >= session.rules.tick:
		session.tick(session.rules.tick)
		accumulator -= session.rules.tick
	if session.progression.completed.size() > previous_objectives:
		audio.play(&"objective")
		var latest: ObjectiveDefinition = HotelProgression.OBJECTIVES[session.progression.completed.size() - 1]
		hud.message.text = "Objetivo concluído: %s. %s" % [latest.display_name, latest.reward_text]
		for definition in HotelCatalog.ROOMS:
			if definition.required_objective == latest.id:
				hud.message.text += " Libera %s." % definition.display_name
	ui_timer += delta
	view.queue_redraw()
	if ui_timer >= 0.2:
		ui_timer = 0
		_refresh()

func _request_exit() -> void:
	if hotel.rooms.is_empty() and hotel.floors == 1 and session.actors.is_empty() and economy.capital_spent == 0 and session.guests.completed == 0:
		_quit_game()
		return
	if exit_dialog.visible:
		return
	for panel: Window in [new_dialog, finances_dialog, staff_panel, progression_panel, operations_panel, help_panel, reviews_panel, recovery_dialog]:
		panel.hide()
	recovery_session = null
	exit_focus = get_viewport().gui_get_focus_owner()
	exit_dialog.dialog_text = "Salvar esta partida antes de sair?\nSair sem salvar preserva apenas o último save."
	exit_dialog.popup_centered(Vector2i(560, 190))
	exit_dialog.get_cancel_button().grab_focus()

func _save_and_exit() -> void:
	var error := SaveStore.save_session(session, save_path)
	if not error.is_empty():
		exit_dialog.dialog_text = error + "\nA partida continua aberta. Tente novamente ou continue jogando."
		hud.message.text = error
		return
	_quit_game()

func _quit_game() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if (exit_dialog != null and exit_dialog.visible) or (recovery_dialog != null and recovery_dialog.visible):
		return
	if event.is_action_pressed("ui_cancel"):
		_cancel()
	elif event.is_action_pressed("toggle_debug"):
		_toggle_debug()
	elif event.is_action_pressed("save_hotel"):
		_save()
	elif event.is_action_pressed("pause_hotel"):
		var focus := get_viewport().gui_get_focus_owner()
		if not (focus is BaseButton or focus is LineEdit or focus is TextEdit):
			session.speed = 1 if session.speed == 0 else 0
	elif event.is_action_pressed("show_operations"):
		_show_operations()
	elif event.is_action_pressed("large_text"):
		_toggle_text_size()
	elif event.is_action_pressed("search_build"):
		hud.build_search.grab_focus()
	elif event.is_action_pressed("show_help"):
		help_panel.open_guide()

func _on_build_requested(definition: RoomDefinition) -> void:
	view.blueprint = definition
	hud.message.text = "Construir %s • $ %d • clique numa posição livre." % [definition.display_name, definition.build_cost]
	view.queue_redraw()

func _on_cell_clicked(column: int, floor_index: int) -> void:
	selected_actor = -1
	if view.blueprint != null:
		var error := hotel.build_error(view.blueprint, column, floor_index)
		if not error.is_empty():
			hud.message.text = error
			return
		var room := hotel.build(view.blueprint, column, floor_index)
		selection = room.id
		audio.play(&"build")
		hud.message.text = "%s construído. Continue construindo ou pressione Esc." % room.definition().display_name
	else:
		var room := hotel.room_at(column, floor_index)
		selection = -1 if room == null else room.id
	_refresh()

func _add_floor() -> void:
	var error := hotel.add_floor()
	hud.message.text = "Novo andar construído; elevadores existentes atendem automaticamente." if error.is_empty() else error

func _demolish() -> void:
	var error := session.demolish(selection)
	hud.message.text = "Sala demolida. Não há reembolso." if error.is_empty() else error
	if error.is_empty():
		selection = -1
	_refresh()

func _cancel() -> void:
	view.blueprint = null
	hud.message.text = "Modo de seleção. Clique numa sala para inspecionar."
	view.queue_redraw()

func _refresh() -> void:
	view.selected = selection
	view.queue_redraw()
	hud.refresh(hotel, hotel.by_id(selection))
	hud.refresh_simulation(session, selected_actor)
	hud.refresh_unlock(session, hotel.by_id(selection))
	var selected_room := hotel.by_id(selection)
	if selected_room != null and selected_room.definition().category == &"reception":
		hud.inspector.text += "\n\nCHECK-IN • AGORA\n" + UILabels.checkin(CheckinDiagnostics.reason(session, selected_room))
	if progression_panel.visible:
		progression_panel.refresh(session)
	if operations_panel.visible:
		operations_panel.refresh(session)
	var lift := session.transport.lift_by_id(selection)
	if lift != null:
		hud.inspector.text = "ELEVADOR #%d • N%d\n\n%s\nTempo ocupado acumulado: %.1fs\nDestino: andar %d" % [lift.room_id, selected_room.level, UILabels.elevator(HotelAnalytics.elevator(session, lift)), lift.busy_seconds, lift.target_floor]

func _hire(definition: EmployeeDefinition) -> void:
	var error := session.hire(definition)
	hud.message.text = "%s contratado(a). Atribuição automática; salário $ %d/dia." % [definition.display_name, definition.salary] if error.is_empty() else error
	_refresh()

func _select_actor(id: int) -> void:
	selected_actor = id
	selection = -1
	_refresh()
	hud.reveal_actor_inspection.call_deferred()

func _replace_session(value: HotelSession) -> void:
	reviews_panel.hide()
	recovery_dialog.hide()
	recovery_session = null
	help_panel.hide()
	operations_panel.hide()
	operations_panel.reset_filters()
	hud.reset_catalog()
	progression_panel.hide()
	staff_panel.hide()
	staff_panel.session = null
	if hotel.changed.is_connected(_refresh):
		hotel.changed.disconnect(_refresh)
	session = value
	economy = value.economy
	hotel = value.hotel
	view.hotel = hotel
	view.session = session
	view.blueprint = null
	view.pan = Vector2.ZERO
	view.zoom_factor = 1
	selection = -1
	selected_actor = -1
	accumulator = 0
	hotel.changed.connect(_refresh)
	_refresh()

func _save() -> void:
	var error := SaveStore.save_session(session, save_path)
	hud.message.text = "Hotel salvo. Você pode fechar e continuar depois." if error.is_empty() else error

func _load() -> void:
	recovery_session = null
	var result := SaveStore.load_session(save_path)
	if not result.error.is_empty():
		hud.message.text = result.error
		if FileAccess.file_exists(save_path + ".bak"):
			var backup := SaveStore.load_session(save_path + ".bak")
			if backup.error.is_empty():
				recovery_session = backup.session
				recovery_dialog.dialog_text = "%s\n\nHá um backup válido do dia %d, com %d salas e caixa $ %d.\nRecuperar substitui a partida aberta pelo backup anterior; progresso não salvo será perdido. Os arquivos não serão alterados." % [result.error, recovery_session.day + 1, recovery_session.hotel.rooms.size(), recovery_session.economy.cash]
				recovery_dialog.popup_centered(Vector2i(590, 270))
				recovery_dialog.get_cancel_button().grab_focus()
			else:
				hud.message.text += " O backup também não pôde ser carregado."
		return
	_replace_session(result.session)
	hud.message.text = "Hotel carregado: quartos, hóspedes, filas e finanças restaurados."

func _recover_save() -> void:
	if recovery_session == null:
		return
	var restored: HotelSession = recovery_session
	_replace_session(restored)
	hud.message.text = "Backup recuperado. Confira a partida e use Salvar quando quiser gravá-la."

func _confirm_new() -> void:
	new_dialog.popup_centered(Vector2i(450, 170))

func _toggle_debug() -> void:
	hud.debug_label.visible = not hud.debug_label.visible
	_refresh()

func _show_finances() -> void:
	var lines: String = "Caixa: $ %d\nReceita: $ %d\nDespesas operacionais: $ %d\nLucro operacional: $ %d\nInvestimento: $ %d\n\nÚLTIMAS TRANSAÇÕES\n" % [economy.cash, economy.revenue, economy.expenses, economy.profit(), economy.capital_spent]
	var costs := session.recurring_costs()
	lines = "CUSTO FIXO ATUAL / DIA\nManutenção: $ %d • Salários: $ %d • Total: $ %d\n\n" % [costs.maintenance, costs.salaries, costs.total] + lines
	for index in range(maxi(0, economy.ledger.size() - 10), economy.ledger.size()):
		var item: Dictionary = economy.ledger[index]
		lines += "%+d  %s\n" % [item.amount, item.reason]
	finances_dialog.dialog_text = lines
	finances_dialog.popup_centered(Vector2i(600, 520))
	finances_dialog.details.grab_focus()

func _show_staff() -> void:
	staff_panel.open_for(session)

func _show_objectives() -> void:
	progression_panel.open_for(session)

func _show_operations() -> void:
	operations_panel.open_for(session)

func _inspect_room(id: int) -> void:
	var room := hotel.by_id(id)
	if room == null:
		hud.message.text = "Esta sala não existe mais."
		return
	view.blueprint = null
	selection = id
	selected_actor = -1
	view.pan += view.size / 2.0 - view.room_rect(room.column, room.floor_index, room.definition().width).get_center()
	_refresh()
	hud.sidebar_scroll.ensure_control_visible(hud.inspector)

func _toggle_text_size() -> void:
	large_text = not large_text
	hud.set_large_text(large_text)
	var error := UIPreferences.save_large_text(large_text)
	hud.message.text = "Texto ampliado." if large_text else "Texto padrão."
	if error != OK:
		hud.message.text += " Não foi possível salvar a preferência."

func _bind_popup(window: Window, opener: Control) -> void:
	window.transient = true
	window.exclusive = true
	window.visibility_changed.connect(_popup_visibility.bind(window, opener))

func _popup_visibility(window: Window, opener: Control) -> void:
	if not window.visible:
		opener.grab_focus()

func _upgrade_selected() -> void:
	var error := session.upgrade_room(selection)
	if error.is_empty():
		audio.play(&"upgrade")
	hud.message.text = "Melhoria aplicada. Serviços em curso mantêm o preço combinado." if error.is_empty() else error
	_refresh()

func _set_selected_tariff(percent: int) -> void:
	var error := session.set_room_tariff(selection, percent)
	hud.message.text = "Tarifa atualizada. Atendimentos em curso mantêm o preço combinado." if error.is_empty() else error
	_refresh()

func _toggle_audio() -> void:
	audio.toggle()
	hud.audio_button.text = "Som: ligado" if audio.enabled else "Som: desligado"

func _register_input() -> void:
	if not InputMap.has_action("show_help"):
		InputMap.add_action("show_help")
		var help_key := InputEventKey.new()
		help_key.physical_keycode = KEY_F1
		InputMap.action_add_event("show_help", help_key)
	for binding in [{"name": "toggle_debug", "key": KEY_F3}, {"name": "save_hotel", "key": KEY_S, "ctrl": true}, {"name": "pause_hotel", "key": KEY_SPACE}, {"name": "show_operations", "key": KEY_F2}, {"name": "large_text", "key": KEY_F4}, {"name": "search_build", "key": KEY_F, "ctrl": true}]:
		if InputMap.has_action(binding.name):
			continue
		InputMap.add_action(binding.name)
		var event := InputEventKey.new()
		event.physical_keycode = binding.key
		event.ctrl_pressed = binding.get("ctrl", false)
		InputMap.action_add_event(binding.name, event)

func _run_headless() -> void:
	var options := SimulationRunner.parse(OS.get_cmdline_user_args())
	if options.has("error"):
		print(JSON.stringify(options))
		get_tree().quit(2)
		return
	var result := SimulationRunner.run(options)
	var encoded := JSON.stringify(result, "\t")
	print(encoded)
	if not options.output.is_empty():
		var file := FileAccess.open(options.output, FileAccess.WRITE)
		if file == null:
			push_error("Could not write simulation report: " + options.output)
			get_tree().quit(2)
			return
		file.store_string(encoded)
		file.close()
	get_tree().quit(1 if result.has("error") or not result.get("failures", []).is_empty() else 0)
