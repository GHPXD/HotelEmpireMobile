class_name AppRoot
extends Control
## Scene lifetime coordinator; owns services, routes and presentation bindings.

var controller := GameController.new()
var router := ScreenRouter.new()
var gestures := MobileInputController.new()
var safe_area: MobileSafeArea
var shell: MobileShell
var view: HotelView
var audio: HotelAudio
var ui_elapsed: float = 0.0
var preview_cell := Vector2i(-1, -1)
var analytics := AnalyticsService.new()
var remote_config := RemoteConfigService.new()
var application_paused: bool = false
var application_focused: bool = true

func _ready() -> void:
	MobileLocale.install()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_area = MobileSafeArea.new()
	safe_area.name = "SafeArea"
	add_child(safe_area)
	shell = MobileShell.new()
	shell.name = "MobileShell"
	safe_area.add_child(shell)
	audio = HotelAudio.new()
	add_child(audio)
	var error := controller.boot()
	if not error.is_empty():
		shell.set_message(error)
		shell.body.mouse_filter = Control.MOUSE_FILTER_STOP
		for button in shell.find_children("*", "Button", true, false):
			button.disabled = true
		return
	view = HotelView.new()
	view.name = "HotelView"
	view.hotel = controller.session.hotel
	view.session = controller.session
	view.mobile_input = gestures
	shell.world_slot.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.resized.connect(_fit_initial_camera, CONNECT_ONE_SHOT)
	gestures.tapped.connect(_world_tap)
	gestures.panned.connect(func(delta: Vector2) -> void:
		view.pan += delta
		view.queue_redraw())
	gestures.pinched.connect(_pinch)
	gestures.pointer_changed.connect(func(point: Vector2) -> void:
		view.pointer = point
		view.queue_redraw())
	shell.navigation_requested.connect(_navigate)
	shell.open_requested.connect(func() -> void:
		controller.toggle_open()
		_refresh())
	shell.pause_requested.connect(func() -> void:
		controller.toggle_pause()
		_refresh())
	shell.close_requested.connect(_back)
	router.changed.connect(_route)
	controller.simulation_advanced.connect(func() -> void: view.queue_redraw())
	controller.saves.checkpoint_failed.connect(shell.set_message)
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false
	if controller.boot_status == "recovered":
		shell.set_message("ui.saved_recovery")
	_refresh()
	remote_config.refresh()
	analytics.record(&"app_open", {"load_status": controller.boot_status})
	analytics.record(&"session_start")
	controller.lifecycle_changed.connect(func(in_background: bool) -> void:
		analytics.record(&"background" if in_background else &"resume"))

func _fit_initial_camera() -> void:
	view.zoom_factor = clampf((view.size.x - 40) / (HotelModel.COLUMNS * HotelView.CELL), 0.35, 1.0)
	view.queue_redraw()

func _process(delta: float) -> void:
	if controller.session == null or controller.background:
		return
	controller.advance(delta)
	ui_elapsed += delta
	if ui_elapsed >= remote_config.values.ui_refresh_seconds:
		ui_elapsed = 0.0
		_refresh()
		analytics.flush()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		application_paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		application_paused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		application_focused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		application_focused = true
	if controller == null or controller.session == null:
		return
	if what == NOTIFICATION_TRANSLATION_CHANGED and shell != null:
		shell.refresh_locale()
		_refresh()
		_route()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		gestures.reset()
		controller.enter_background()
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if not application_paused and application_focused:
			controller.resume()
		if safe_area != null:
			safe_area.refresh()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		controller.enter_background()
		get_tree().quit()

func _navigate(destination: StringName) -> void:
	gestures.reset()
	view.blueprint = null
	view.queue_redraw()
	router.navigate(destination)

func _back() -> void:
	gestures.reset()
	if router.back():
		return
	if view != null and view.blueprint != null:
		view.blueprint = null
		view.queue_redraw()
		shell.set_message("ui.ready")
	# Root Android back keeps the hotel available; OS Home remains the exit path.

func _world_tap(point: Vector2) -> void:
	if shell.modal_blocker.visible:
		return
	if view.blueprint != null:
		preview_cell = view.cell_at(point)
		var error := controller.session.hotel.build_error(view.blueprint, preview_cell.x, preview_cell.y)
		if not error.is_empty():
			shell.set_message(MobileFeedback.key(error))
			return
		router.open_sheet(&"build_confirm")
		return
	var actor_id := view.actor_at_screen_position(point)
	if actor_id >= 0:
		router.open_sheet(&"actor", actor_id)
		return
	var cell := view.cell_at(point)
	var room := controller.session.hotel.room_at(cell.x, cell.y)
	view.selected = room.id if room != null else -1
	view.queue_redraw()
	if room != null:
		router.open_sheet(&"room", room.id)
	else:
		router.close_sheet()

func _pinch(factor: float, old_focus: Vector2, focus: Vector2) -> void:
	var point := (old_focus - view.origin()) / view.zoom_factor
	view.zoom_factor = clampf(view.zoom_factor * factor, 0.35, 1.8)
	view.pan += focus - view.world_to_screen(point)
	view.queue_redraw()

func _refresh() -> void:
	if shell != null and controller.session != null:
		shell.refresh(controller.session)

func _route() -> void:
	gestures.reset()
	shell.clear_sheet()
	if router.sheet == &"build_confirm":
		shell.label(shell.sheet_content, "").text = tr("ui.build_preview") % [tr("room." + String(view.blueprint.id) + ".name"), MobileLocale.number(view.blueprint.build_cost)]
		shell.button(shell.sheet_content, "ui.confirm", _confirm_build, HotelArt.build_icon(view.blueprint.id))
		shell.show_sheet(true)
		return
	if router.sheet == &"room":
		_show_room(router.context_id)
		return
	if router.sheet == &"actor":
		var actor: ActorState = controller.session.actors.get(router.context_id)
		if actor == null:
			router.close_sheet()
			return
		shell.label(shell.sheet_content, "").text = tr("ui.guest_details") % [actor.display_name, roundi(actor.happiness), roundi(actor.age)]
		shell.show_sheet()
		return
	match router.screen:
		&"hotel":
			shell.hide_sheet()
		&"build":
			for definition in HotelCatalog.ROOMS:
				var button := shell.button(shell.sheet_content, "room." + String(definition.id) + ".name", _choose_build.bind(definition), HotelArt.build_icon(definition.id))
				button.text += "  " + MobileLocale.number(definition.build_cost)
				button.disabled = not controller.session.progression.build_error(definition).is_empty()
			shell.button(shell.sheet_content, "ui.floor", _add_floor, HotelArt.action_icon(&"add_floor")).text = tr("ui.floor") % MobileLocale.number(HotelModel.FLOOR_COST)
			shell.show_sheet()
		&"staff":
			for definition in HotelSession.EMPLOYEES:
				shell.button(shell.sheet_content, "ui.hire", _hire.bind(definition), HotelArt.staff_icon(definition.id)).text = tr("ui.hire") % [tr("staff." + String(definition.id) + ".name"), MobileLocale.number(definition.hire_cost)]
				shell.label(shell.sheet_content, "").text = tr("ui.salary") % MobileLocale.number(definition.salary)
			shell.show_sheet()
		&"missions":
			for objective in HotelProgression.OBJECTIVES:
				if controller.session.progression.completed.has(objective.id):
					shell.label(shell.sheet_content, "ui.objective_completed")
				else:
					for metric: String in objective.requirements:
						shell.label(shell.sheet_content, "").text = tr("ui.objective_progress") % [tr("metric." + metric), int(controller.session.progression_metrics().get(metric, 0)), int(objective.requirements[metric])]
					break
				shell.show_sheet()
		&"store":
			shell.label(shell.sheet_content, "store.unavailable")
			shell.show_sheet()
		&"settings":
			shell.button(shell.sheet_content, "ui.large_text", _toggle_text, HotelArt.preference_icon(&"text_size"))
			shell.button(shell.sheet_content, "ui.sound", audio.toggle, HotelArt.preference_icon(&"sound_on" if audio.enabled else &"sound_off"))
			shell.show_sheet()

func _choose_build(definition: RoomDefinition) -> void:
	router.navigate(&"hotel")
	view.blueprint = definition
	shell.message.text = tr("ui.choose_position") % tr("room." + String(definition.id) + ".name")
	view.queue_redraw()

func _confirm_build() -> void:
	var result := controller.build(view.blueprint, preview_cell.x, preview_cell.y)
	if result.room != null:
		view.selected = result.room.id
		view.blueprint = null
		audio.play(&"build")
		router.close_sheet()
	_feedback(result.error, "ui.built")
	_refresh()

func _add_floor() -> void:
	_feedback(controller.add_floor(), "ui.built")
	view.queue_redraw()
	_refresh()

func _hire(definition: EmployeeDefinition) -> void:
	_feedback(controller.hire(definition), "ui.hired")
	_refresh()

func _show_room(id: int) -> void:
	var room := controller.session.hotel.by_id(id)
	if room == null:
		router.close_sheet()
		return
	shell.label(shell.sheet_content, "").text = tr("ui.room_details") % [tr("room." + String(room.definition_id) + ".name"), room.level, room.capacity(), MobileLocale.number(room.income)]
	var upgrade := shell.button(shell.sheet_content, "ui.upgrade", _upgrade.bind(id), HotelArt.action_icon(&"upgrade"))
	upgrade.disabled = room.next_upgrade() == null or not controller.session.progression.upgrade_error(room).is_empty()
	shell.show_sheet()

func _upgrade(id: int) -> void:
	var error := controller.upgrade(id)
	_feedback(error, "ui.upgraded")
	if error.is_empty():
		audio.play(&"upgrade")
		_route()
	_refresh()

func _toggle_text() -> void:
	var enabled := not UIPreferences.load_large_text()
	if UIPreferences.save_large_text(enabled) != OK:
		shell.set_message("save.error.write")
		return
	shell.theme = MobileTheme.create(enabled)
	shell._layout()

func _feedback(error: String, success: String) -> void:
	shell.set_message(success if error.is_empty() else MobileFeedback.key(error))
