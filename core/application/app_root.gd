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
var panels: MobileHotelPanels
var haptics := HapticService.new()
var display_scale := MobileDisplayScale.new()
var return_sheet: StringName = &""
var return_context_id: int = -1

func _ready() -> void:
	_configure_display()
	get_window().size_changed.connect(_configure_display)
	MobileLocale.install(UIPreferences.load_locale())
	haptics.load_preference()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_area = MobileSafeArea.new()
	safe_area.name = "SafeArea"
	add_child(safe_area)
	shell = MobileShell.new()
	shell.name = "MobileShell"
	safe_area.add_child(shell)
	panels = MobileHotelPanels.new(shell)
	panels.onboarding = controller.onboarding
	panels.command_requested.connect(_command)
	panels.navigation_requested.connect(_navigate)
	panels.sheet_requested.connect(func(kind: StringName, id: int) -> void: router.open_sheet(kind, id))
	panels.presentation_changed.connect(_route)
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
	view.construction = controller.construction
	panels.construction = controller.construction
	panels.progress_clock = controller.progress_clock
	panels.inventory = controller.inventory
	view.mobile_input = gestures
	shell.world_slot.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.resized.connect(_fit_initial_camera, CONNECT_ONE_SHOT)
	view.resized.connect(_focus_context)
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
	controller.speedup_used.connect(func(item_id: StringName, applied_ms: int) -> void:
		analytics.record(&"speedup_used", {"kind": String(item_id), "duration_seconds": applied_ms / 1000.0}))
	controller.construction_changed.connect(func(events: Array[Dictionary]) -> void:
		view.queue_redraw()
		for event in events:
			if event.error.is_empty():
				audio.play(&"upgrade" if event.kind == "upgrade" else &"build")
				haptics.confirm()
				shell.set_message("construction.finished")
			else:
				shell.set_message(event.error)
		_refresh())
	controller.player_work_changed.connect(func(kind: String, phase: String, result: String) -> void:
		if result == "completed":
			audio.play(&"build")
			haptics.confirm()
		var key := "work.result." + result
		shell.set_message(key if TranslationServer.translate(key) != key else "work.error." + result)
		analytics.record(&"manual_work", {"kind": kind, "phase": phase, "result": result}))
	controller.guide_advanced.connect(func(stage: int) -> void: analytics.record(&"tutorial_progress", {"stage": stage}))
	controller.staff_changed.connect(func(event: Dictionary) -> void:
		if event.result == "promoted":
			shell.message.text = tr("staff.promoted") % [tr("staff." + event.role + ".name"), event.level])
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false
	if controller.boot_status == "recovered":
		shell.set_message("ui.saved_recovery")
	if controller.onboarding.active():
		router.open_sheet(&"overview")
	_show_construction_return()
	_refresh()
	remote_config.refresh()
	analytics.record(&"app_open", {"load_status": controller.boot_status})
	analytics.record(&"session_start")
	controller.lifecycle_changed.connect(func(in_background: bool) -> void:
		analytics.record(&"background" if in_background else &"resume")
		if not in_background:
			_show_construction_return())

func _show_construction_return() -> void:
	if controller.return_construction.is_empty():
		return
	if router.sheet != &"construction_return":
		return_sheet = router.sheet
		return_context_id = router.context_id
	panels.return_construction = controller.return_construction.duplicate(true)
	shell.set_message("construction.finished")
	router.open_sheet(&"construction_return")

func _configure_display() -> void:
	display_scale.apply(get_window())

func _fit_initial_camera() -> void:
	view.zoom_factor = clampf((view.size.x - 40) / (HotelModel.COLUMNS * HotelView.CELL), 0.8, 1.0)
	view.pan = Vector2.ZERO
	if view.size.x < 720:
		# Start with the reception end of the plot at a readable touch scale.
		view.pan.x = 5 * HotelView.CELL * view.zoom_factor
	if view.size.y < 200:
		view.pan.y = view.size.y / 2 - (view.origin().y - HotelView.FLOOR_HEIGHT * view.zoom_factor / 2)
	view.queue_redraw()

func _focus_context() -> void:
	if view == null:
		return
	var target := _context_rect()
	var top_margin := 36.0 if view.size.y >= 180 else (24.0 if shell.message.get_parent() == shell.world_slot else 4.0)
	var viewport := Rect2(Vector2(16, top_margin), view.size - Vector2(32, top_margin + 4))
	if not target.has_area() or not viewport.has_area() or viewport.encloses(target):
		return
	# Fit the entire selected room even after a pinch or a compact sheet resize.
	var fit := minf(viewport.size.x / target.size.x, viewport.size.y / target.size.y)
	if fit < 1.0:
		view.zoom_factor = clampf(view.zoom_factor * fit, 0.35, 1.8)
		target = _context_rect()
	view.pan += viewport.get_center() - target.get_center()
	view.queue_redraw()

func _context_rect() -> Rect2:
	var target := Rect2()
	if router.sheet == &"build_confirm" and view.blueprint != null:
		target = view.room_rect(preview_cell.x, preview_cell.y, view.blueprint.width)
	elif router.sheet == &"room":
		var room := controller.session.hotel.by_id(router.context_id)
		if room != null:
			target = view.room_rect(room.column, room.floor_index, room.definition().width)
	elif router.sheet in [&"construction", &"construction_cancel_confirm", &"speedup_confirm"]:
		var job: Variant = controller.construction.by_id(router.context_id)
		if job != null and job.kind != "floor":
			target = view.room_rect(int(job.column), int(job.floor_index), HotelCatalog.room(StringName(job.definition_id)).width)
	elif router.sheet in [&"actor", &"employee"]:
		var actor: ActorState = controller.session.actors.get(router.context_id)
		if actor != null:
			target = view.actor_sprite_rect(actor)
	return target

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
		if view != null:
			view.queue_redraw()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		gestures.reset()
		audio.suspend()
		controller.enter_background()
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if not application_paused and application_focused:
			controller.resume()
		if safe_area != null:
			safe_area.refresh()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		audio.suspend()
		controller.enter_background()
		get_tree().quit()

func _navigate(destination: StringName) -> void:
	gestures.reset()
	view.blueprint = null
	view.queue_redraw()
	router.navigate(destination)
	if destination == &"hotel":
		router.open_sheet(&"overview")

func _back() -> void:
	gestures.reset()
	if router.back():
		return
	if view != null and view.blueprint != null:
		view.blueprint = null
		view.queue_redraw()
		shell.set_message("ui.build_cancelled")
		return
	if OS.get_name() == "Android":
		controller.enter_background()
		get_tree().quit()

func _world_tap(point: Vector2) -> void:
	if shell.modal_blocker.visible:
		return
	if view.blueprint != null:
		preview_cell = view.cell_at(point)
		var error := controller.construction.build_error(view.blueprint, preview_cell.x, preview_cell.y)
		if not error.is_empty():
			shell.set_message(MobileFeedback.key(error))
			return
		router.open_sheet(&"build_confirm")
		return
	var cell := view.cell_at(point)
	for job in controller.construction.jobs:
		if job.kind != "build":
			continue
		var definition := HotelCatalog.room(StringName(job.definition_id))
		if cell.x >= int(job.column) and cell.x < int(job.column) + definition.width and (cell.y == int(job.floor_index) or definition.category == &"transport"):
			router.open_sheet(&"construction", int(job.id))
			return
	var actor_id := view.actor_at_screen_position(point)
	if actor_id >= 0:
		router.open_sheet(&"actor", actor_id)
		return
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
		if panels != null:
			if panels.needs_rebuild():
				_route()
			else:
				panels.refresh()

func _route() -> void:
	if panels == null or view == null:
		return
	gestures.reset()
	view.fixed_preview = router.sheet == &"build_confirm" and view.blueprint != null
	view.preview_cell = preview_cell
	panels.sound_enabled = audio.enabled
	panels.haptics_enabled = haptics.enabled
	panels.show(controller.session, router, view.blueprint)
	_focus_context.call_deferred()
	view.queue_redraw()

func _command(action: StringName, arguments: Dictionary) -> void:
	if controller.transaction_active():
		return
	match action:
		&"player_work":
			_feedback(controller.start_player_work(arguments.kind, arguments.id), "work.result.started")
			_route()
		&"room_service":
			_feedback(controller.start_room_service(arguments.order_id), "work.result.started")
			_route()
		&"player_cancel":
			_feedback(controller.cancel_player_work(), "work.result.cancelled")
			_route()
		&"player_return":
			_feedback(controller.return_player(), "work.returning")
		&"guide_next": _guide_next()
		&"guide_skip":
			_feedback(controller.set_guide_skipped(true), "guide.skipped")
			_route()
		&"guide_resume":
			controller.set_guide_skipped(false)
			_route()
		&"choose_build": _choose_build(arguments.definition)
		&"confirm_build": _confirm_build()
		&"request_speedup":
			panels.speedup_item = arguments.item
			panels.speedup_operation_id = controller.inventory.next_operation_id()
			router.open_sheet(&"speedup_confirm", arguments.id)
		&"use_speedup":
			var error := controller.use_speedup(arguments.id, arguments.item, arguments.operation_id)
			_feedback(error, "speedup.applied")
			if error.is_empty():
				if controller.construction.by_id(arguments.id) != null:
					haptics.confirm()
					router.open_sheet(&"construction", arguments.id)
				elif controller.onboarding.active():
					router.open_sheet(&"overview")
				else:
					router.close_sheet()
			else:
				_route()
		&"construction_return_continue":
			var unavailable := return_sheet in [&"construction", &"construction_cancel_confirm", &"speedup_confirm"] and controller.construction.by_id(return_context_id) == null
			if not return_sheet.is_empty() and not unavailable:
				router.open_sheet(return_sheet, return_context_id)
			else:
				router.close_sheet()
		&"request_construction_cancel": router.open_sheet(&"construction_cancel_confirm", arguments.id)
		&"cancel_construction":
			var error := controller.cancel_construction(arguments.id)
			_feedback(error, "construction.cancelled")
			if error.is_empty():
				router.close_sheet()
		&"add_floor": _add_floor()
		&"hire":
			var traits: Array[StringName] = []
			traits.assign(arguments.get("traits", []))
			_hire(arguments.definition, traits)
		&"staff_duty":
			_feedback(controller.set_employee_duty(arguments.id, arguments.enabled), "staff.assigned")
			_route()
		&"staff_priority":
			_feedback(controller.set_employee_priority(arguments.id, arguments.priority), "staff.assigned")
			_route()
		&"request_dismiss": router.open_sheet(&"dismiss_confirm", arguments.id)
		&"dismiss_employee":
			_feedback(controller.dismiss_employee(arguments.id), "staff.departing")
			router.open_sheet(&"employee", arguments.id)
		&"upgrade": _upgrade(arguments.id)
		&"tariff":
			_feedback(controller.set_tariff(arguments.id, arguments.percent), "tariff.saved")
			_route()
		&"assign":
			_feedback(controller.configure_employee(arguments.id, arguments.destination), "staff.assigned")
			_route()
		&"request_demolish": router.open_sheet(&"demolish_confirm", arguments.id)
		&"demolish":
			var error := controller.demolish(arguments.id)
			_feedback(error, "ui.demolished")
			if error.is_empty():
				view.selected = -1
				router.close_sheet()
			view.queue_redraw()
		&"large_text": _toggle_text()
		&"sound":
			audio.toggle()
			_route()
		&"haptics":
			if haptics.toggle() != OK:
				shell.set_message("save.error.write")
			_route()
		&"locale":
			if UIPreferences.save_value("locale", arguments.locale) != OK:
				shell.set_message("save.error.write")
				return
			MobileLocale.install(arguments.locale)
			_route()
	_refresh()

func _exit_tree() -> void:
	if panels != null:
		panels.updates.clear()

func _choose_build(definition: RoomDefinition) -> void:
	router.navigate(&"hotel")
	view.blueprint = definition
	shell.message.text = tr("ui.choose_position") % tr("room." + String(definition.id) + ".name")
	view.queue_redraw()

func _confirm_build() -> void:
	var result := controller.build(view.blueprint, preview_cell.x, preview_cell.y)
	if result.job != null:
		view.selected = -1
		view.blueprint = null
		haptics.confirm()
		router.open_sheet(&"construction", int(result.job.id))
	_feedback(result.error, "construction.started")
	_refresh()

func _add_floor() -> void:
	_feedback(controller.add_floor(), "construction.started")
	view.queue_redraw()
	_refresh()

func _hire(definition: EmployeeDefinition, traits: Array[StringName] = []) -> void:
	var error := controller.hire(definition, traits)
	_feedback(error, "ui.hired")
	if error.is_empty() and router.sheet == &"hire_options":
		router.navigate(&"staff")
	_route()
	_refresh()

func _upgrade(id: int) -> void:
	var error := controller.upgrade(id)
	_feedback(error, "construction.started")
	if error.is_empty():
		haptics.confirm()
		_route()
	_refresh()

func _toggle_text() -> void:
	var enabled := not UIPreferences.load_large_text()
	if UIPreferences.save_large_text(enabled) != OK:
		shell.set_message("save.error.write")
		return
	shell.theme = MobileTheme.create(enabled)
	shell._layout()
	_route()

func _feedback(error: String, success: String) -> void:
	shell.set_message(success if error.is_empty() else MobileFeedback.key(error))

func _guide_next() -> void:
	var step := controller.onboarding.step_id()
	var session := controller.session
	match step:
		"reception": _choose_build(HotelCatalog.room(&"reception"))
		"bedroom": _choose_build(HotelCatalog.room(&"bedroom"))
		"food": _choose_build(HotelCatalog.room(&"restaurant"))
		"open":
			if not session.opened:
				controller.toggle_open()
			_refresh()
		"checkin":
			var room := OnboardingService.first_room(session, &"reception")
			if room != null:
				router.open_sheet(&"room", room.id)
		"room_service": router.open_sheet(&"overview")
		"cleaning", "repair":
			var target := OnboardingService.first_room(session, &"lodging")
			for room in session.hotel.rooms:
				if (step == "cleaning" and room.dirty) or (step == "repair" and room.condition < 100 and room.definition().category != &"transport"):
					target = room
					break
			if target != null:
				router.open_sheet(&"room", target.id)
		"hire": _navigate(&"staff")
