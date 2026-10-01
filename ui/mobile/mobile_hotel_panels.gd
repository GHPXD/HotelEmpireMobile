class_name MobileHotelPanels
extends RefCounted
## Builds contextual views from domain state. All mutations are semantic commands.

signal command_requested(action: StringName, arguments: Dictionary)
signal navigation_requested(destination: StringName)
signal sheet_requested(kind: StringName, id: int)
signal presentation_changed

var shell: MobileShell
var session: HotelSession
var build_category: StringName = &""
var room_status: int = 0
var room_floor: int = -1
var updates: Array[Callable] = []
var sound_enabled: bool = true
var haptics_enabled: bool = true
var onboarding: OnboardingService
var structure_key: String = ""

func _init(presentation: MobileShell) -> void:
	shell = presentation

func show(value: HotelSession, router: ScreenRouter, blueprint: RoomDefinition) -> void:
	session = value
	structure_key = _structure()
	updates.clear()
	shell.clear_sheet()
	var title := "ui." + String(router.screen)
	match router.sheet:
		&"build_confirm":
			if blueprint == null:
				shell.hide_sheet()
				return
			title = "ui.build"
			_text(tr("ui.build_preview") % [tr("room." + String(blueprint.id) + ".name"), MobileLocale.number(blueprint.build_cost)])
			_action("ui.confirm", &"confirm_build", {}, HotelArt.build_icon(blueprint.id))
		&"demolish_confirm":
			title = "ui.demolish"
			_text(tr("ui.demolish_confirm"))
			_action("ui.confirm", &"demolish", {"id": router.context_id}, HotelArt.action_icon(&"demolish"))
		&"room":
			title = "ui.room"
			_room(router.context_id)
		&"actor":
			title = "ui.guest"
			_actor(router.context_id)
		&"employee":
			title = "ui.staff"
			_employee(router.context_id)
		&"hire_options":
			title = "staff.profiles"
			_hire_options(router.context_id)
		&"dismiss_confirm":
			title = "staff.dismiss"
			var actor: ActorState = session.actors.get(router.context_id)
			if actor != null and actor.is_employee() and not actor.ensure_employee().dismiss_requested:
				_text(tr("staff.dismiss_confirm") % MobileLabels.actor_name(actor))
				_action("ui.confirm", &"dismiss_employee", {"id": actor.id}, HotelArt.staff_icon(actor.role))
			else:
				_text(tr("actor.departed"))
		&"overview":
			title = "ui.hotel"
			_overview()
		_:
			match router.screen:
				&"hotel":
					shell.hide_sheet()
					return
				&"build": _build()
				&"staff": _staff()
				&"operations": _operations()
				&"finances": _finances()
				&"reviews": _reviews()
				&"missions": _missions()
				&"settings": _settings()
				&"store": _text(tr("store.unavailable"))
	shell.sheet_title.text = tr(title)
	shell.show_sheet(router.sheet in [&"build_confirm", &"demolish_confirm", &"dismiss_confirm"])
	structure_key = _structure()
	refresh()

func needs_rebuild() -> bool:
	return session != null and structure_key != _structure()

func _structure() -> String:
	var key := "%d:%d:%s:%d:%s" % [session.actors.size() - session.guest_count(), session.hotel.rooms.size(), str(session.player_work.job.is_empty()), onboarding.stage if onboarding != null else -1, str(onboarding.skipped if onboarding != null else true)]
	for order in session.player_work.orders:
		key += ":o%d" % int(order.id)
	for room in session.hotel.rooms:
		key += ":%d:%s" % [room.id, str(room.dirty)]
	for actor: ActorState in session.actors.values():
		if actor.employee != null:
			key += ":e%d:%s:%s:%s" % [actor.id, str(actor.employee.duty_enabled), str(actor.employee.priority), str(actor.employee.dismiss_requested)]
	return key

func refresh() -> void:
	for update in updates:
		update.call()

func _text(value: String) -> Label:
	var label := shell.label(shell.sheet_content, "")
	label.text = value
	return label

func _live(projection: Callable) -> Label:
	var label := _text("")
	updates.append(func() -> void: label.text = projection.call())
	return label

func _action(key: String, action: StringName, arguments: Dictionary = {}, icon: Texture2D = null, parent: Node = null) -> Button:
	var button := shell.button(parent if parent != null else shell.sheet_content, key, func() -> void: command_requested.emit(action, arguments), icon)
	button.set_meta("mobile_action", action)
	button.set_meta("arguments", arguments)
	return button

func _link(destination: StringName, icon: Texture2D = null) -> void:
	var button := shell.button(shell.sheet_content, "ui." + String(destination), func() -> void: navigation_requested.emit(destination), icon)
	button.set_meta("destination", destination)

func _inspect(kind: StringName, id: int, value: String, icon: Texture2D = null) -> void:
	var button := shell.button(shell.sheet_content, "", func() -> void: sheet_requested.emit(kind, id), icon)
	button.text = value
	button.set_meta("inspect_kind", kind)
	button.set_meta("inspect_id", id)

func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.sheet_content.add_child(grid)
	return grid

func _build() -> void:
	var categories := _grid()
	for category: StringName in [&"", &"reception", &"lodging", &"service", &"transport"]:
		var button := shell.button(categories, "category." + ("all" if category.is_empty() else String(category)), func() -> void:
			build_category = category
			presentation_changed.emit())
		button.disabled = build_category == category
	for definition: RoomDefinition in HotelCatalog.ROOMS:
		if not build_category.is_empty() and definition.category != build_category:
			continue
		var button := _action("room." + String(definition.id) + ".name", &"choose_build", {"definition": definition}, HotelArt.build_icon(definition.id))
		var locked := session.progression.build_error(definition)
		button.disabled = not locked.is_empty()
		_text(tr("build.cost") % [MobileLocale.number(definition.build_cost), definition.width])
		if button.disabled:
			_text(tr("error.locked"))
	_action("ui.floor", &"add_floor", {}, HotelArt.action_icon(&"add_floor")).text = tr("ui.floor") % MobileLocale.number(HotelModel.FLOOR_COST)

func _overview() -> void:
	if session.player_work.job.is_empty():
		_guide()
		_manual_overview()
	else:
		_manual_overview()
		_guide()
	_live(func() -> String:
		var stats := HotelAnalytics.summary(session)
		return tr("hotel.summary") % [roundi(stats.occupancy), stats.dirty, stats.room_queue + stats.lift_queue])
	_link(&"operations", HotelArt.management_icon(&"operations"))
	_link(&"finances", HotelArt.management_icon(&"finances"))
	_link(&"reviews", HotelArt.management_icon(&"reviews"))

func _room(id: int) -> void:
	var room := session.hotel.by_id(id)
	if room == null:
		_text(tr("error.command"))
		return
	_work_status()
	_live(func() -> String:
		return tr("ui.room_details") % [MobileLabels.room_name(room), room.level, room.capacity(), MobileLocale.number(room.income)])
	if room.definition().category == &"reception":
		_live(func() -> String: return MobileLabels.checkin(session, room))
		_work_button("checkin", id, HotelArt.staff_icon(&"receptionist"))
		_link(&"staff", HotelArt.staff_icon(&"receptionist"))
	elif room.definition().category == &"transport":
		_live(func() -> String: return MobileLabels.elevator(HotelAnalytics.elevator(session, session.transport.lift_by_id(room.id))))
	else:
		_live(func() -> String: return tr("room.operation") % [room.queue.members.size(), tr("room.dirty" if room.dirty else "room.clean"), tr("room.busy" if room.busy() else "room.free")])
	if room.definition().category == &"lodging":
		_work_button("cleaning", id, HotelArt.staff_icon(&"cleaner"))
		_orders(id)
	if room.definition().category != &"transport":
		_live(func() -> String: return tr("work.condition") % [room.condition, roundi((100 - room.condition) * session.player_work.rules.maximum_slowdown)])
		_work_button("repair", id, HotelArt.action_icon(&"repair"))
		_text(tr("work.repair_cost") % MobileLocale.number(session.player_work.rules.repair_cost))
	var next := room.next_upgrade()
	if next != null:
		var upgrade := _action("ui.upgrade", &"upgrade", {"id": id}, HotelArt.action_icon(&"upgrade"))
		upgrade.disabled = not session.progression.upgrade_error(room).is_empty()
		_text(tr("upgrade.cost") % MobileLocale.number(next.cost))
		if upgrade.disabled:
			_text(tr("error.locked"))
	else:
		_text(tr("room.max_level"))
	if room.definition().category in [&"lodging", &"service"]:
		_live(func() -> String: return tr("tariff.current") % [room.price_percent, MobileLocale.number(room.price())])
		var tariffs := _grid()
		for percent: int in [75, 100, 125]:
			var button := _action("", &"tariff", {"id": id, "percent": percent}, null, tariffs)
			button.text = "%d%%" % percent
			button.disabled = percent == room.price_percent
		if room.definition().category == &"lodging":
			_text(tr("tariff.effect"))
			for percent: int in [75, 100, 125]:
				var low: float = INF
				var high: float = -INF
				for profile: GuestArchetype in HotelCatalog.GUESTS:
					var delta := room.lodging_value_delta(profile, percent)
					low = minf(low, delta)
					high = maxf(high, delta)
				_text(tr("tariff.range") % [percent, low, high])
	_action("ui.demolish", &"request_demolish", {"id": id}, HotelArt.action_icon(&"demolish"))

func _actor(id: int) -> void:
	var actor: ActorState = session.actors.get(id)
	if actor == null:
		_text(tr("actor.departed"))
		return
	_portrait(actor)
	_text(MobileLabels.actor_name(actor))
	_live(func() -> String:
		return MobileLabels.actor_details(actor, session.hotel) if session.actors.has(id) else tr("actor.departed"))
	if actor.role == &"player":
		_work_status()
		_action("work.return", &"player_return", {}, HotelArt.build_icon(&"reception"))
	elif actor.role != &"guest":
		_inspect(&"employee", id, tr("staff.assign"), HotelArt.staff_icon(actor.role))

func _staff() -> void:
	var count := 0
	for actor: ActorState in session.actors.values():
		if actor.is_employee():
			count += 1
	if count > 0:
		_text(tr("staff.supervision"))
		for role: StringName in [&"receptionist", &"cleaner"]:
			if StaffProjection.department(session, role).staff == 0:
				continue
			_live(func() -> String:
				var department := StaffProjection.department(session, role)
				return tr("staff.department") % [tr("staff." + String(role) + ".name"), department.enabled, department.active, department.backlog, department.paused, MobileLocale.number(department.salary)])
	for definition: EmployeeDefinition in HotelSession.EMPLOYEES:
		var hire := _action("ui.hire", &"hire", {"definition": definition}, HotelArt.staff_icon(definition.id))
		hire.text = tr("staff.hire_role") % tr("staff." + String(definition.id) + ".name")
		_text(tr("staff.costs") % [MobileLocale.number(definition.hire_cost), MobileLocale.number(definition.salary)])
		updates.append(func() -> void: hire.disabled = session.economy.cash < definition.hire_cost)
		_inspect(&"hire_options", HotelSession.EMPLOYEES.find(definition), tr("staff.profiles_role") % tr("staff." + String(definition.id) + ".name"), HotelArt.staff_icon(definition.id))
	for actor: ActorState in session.actors.values():
		if actor.role not in [&"receptionist", &"cleaner"]:
			continue
		_inspect(&"employee", actor.id, MobileLabels.actor_name(actor), HotelArt.staff_icon(actor.role))
	if count == 0:
		_text(tr("staff.empty"))
	_text(tr("staff.salary_hint"))

func _employee(id: int) -> void:
	var actor: ActorState = session.actors.get(id)
	if actor == null or actor.role not in [&"receptionist", &"cleaner"]:
		_text(tr("error.command"))
		return
	_text(MobileLabels.actor_name(actor))
	_live(func() -> String:
		var stats := StaffProjection.details(actor)
		return tr("staff.progress") % [stats.level, stats.xp, stats.next_xp if stats.next_xp >= 0 else stats.xp, stats.jobs] + "\n" + tr("staff.performance") % [stats.efficiency, stats.quality, MobileLocale.number(stats.salary)])
	_text(_trait_names(actor.ensure_employee().traits))
	if actor.employee.dismiss_requested:
		_text(tr("staff.departing"))
		return
	_action("staff.pause" if actor.employee.duty_enabled else "staff.resume", &"staff_duty", {"id": id, "enabled": not actor.employee.duty_enabled})
	_text(tr("staff.pause_hint"))
	if actor.role == &"cleaner":
		for priority: StringName in [&"oldest", &"nearest"]:
			var button := _action("staff.priority." + String(priority), &"staff_priority", {"id": id, "priority": priority})
			button.disabled = actor.employee.priority == priority
	_text(tr("staff.assignment_hint"))
	var selected := actor.preferred_room if actor.role == &"receptionist" else actor.preferred_floor
	var auto := _action("staff.auto", &"assign", {"id": id, "destination": -1})
	auto.disabled = selected == -1
	if actor.role == &"receptionist":
		for room: RoomState in session.hotel.rooms:
			if room.definition().category == &"reception":
				var button := _action("", &"assign", {"id": id, "destination": room.id}, HotelArt.build_icon(&"reception"))
				button.text = MobileLabels.room_name(room)
				button.disabled = selected == room.id
	else:
		for floor_index in session.hotel.floors:
			var button := _action("", &"assign", {"id": id, "destination": floor_index})
			button.text = tr("staff.floor") % floor_index
			button.disabled = selected == floor_index
	_action("staff.dismiss", &"request_dismiss", {"id": id}, HotelArt.staff_icon(actor.role))
	_portrait(actor)
	_live(func() -> String: return MobileLabels.actor_details(actor, session.hotel))

func _trait_names(traits: Array[StringName]) -> String:
	if traits.is_empty():
		return tr("staff.traits.none")
	var names: Array[String] = []
	for trait_id in traits:
		names.append(tr("staff.trait." + String(trait_id)))
	return ", ".join(names)

func _hire_options(index: int) -> void:
	if index < 0 or index >= HotelSession.EMPLOYEES.size():
		_text(tr("error.command"))
		return
	var definition := HotelSession.EMPLOYEES[index]
	_text(tr("staff." + String(definition.id) + ".name"))
	for profile: Array in EmployeeProgress.RULES.profiles(definition.id):
		var traits: Array[StringName] = []
		traits.assign(profile)
		var progress := EmployeeProgress.new()
		progress.traits = traits
		var cost := EmployeeProgress.RULES.hire_cost(definition.hire_cost, traits)
		var button := _action("", &"hire", {"definition": definition, "traits": traits}, HotelArt.staff_icon(definition.id))
		button.text = tr("staff.hire_profile") % [_trait_names(traits), MobileLocale.number(cost)]
		updates.append(func() -> void: button.disabled = session.economy.cash < cost)
		_text(tr("staff.performance") % [roundi(progress.efficiency(definition.skill) * 100), progress.quality(), MobileLocale.number(progress.salary(definition.salary))])
		for trait_id in traits:
			_text(tr("staff.effect." + String(trait_id)))
	_text(tr("staff.profile_hint"))

func _operations() -> void:
	var filters := _grid()
	for status in 4:
		var button := shell.button(filters, "filter.status_%d" % status, func() -> void:
			room_status = status
			presentation_changed.emit())
		button.disabled = status == room_status
		button.set_meta("room_status", status)
	var floors := _grid()
	for floor_index in range(-1, session.hotel.floors):
		var button := shell.button(floors, "", func() -> void:
			room_floor = floor_index
			presentation_changed.emit())
		button.text = tr("filter.all_floors") if floor_index < 0 else tr("staff.floor") % floor_index
		button.disabled = floor_index == room_floor
	var rows := HotelAnalytics.rooms(session, &"", room_floor, room_status)
	if rows.is_empty():
		_text(tr("filter.empty"))
	for row: Dictionary in rows:
		var room := session.hotel.by_id(row.id)
		_inspect(&"room", room.id, MobileLabels.room_name(room), HotelArt.build_icon(room.definition_id))
		_live(func() -> String:
			if room.definition().category == &"reception":
				return MobileLabels.checkin(session, room)
			if room.definition().category == &"transport":
				return MobileLabels.elevator(HotelAnalytics.elevator(session, session.transport.lift_by_id(room.id)))
			return tr("room.operation") % [room.queue.members.size(), tr("room.dirty" if room.dirty else "room.clean"), tr("room.busy" if room.busy() else "room.free")])

func _finances() -> void:
	_live(func() -> String:
		var costs := session.recurring_costs()
		return tr("finance.daily") % [MobileLocale.number(costs.maintenance), MobileLocale.number(costs.salaries), MobileLocale.number(costs.total)])
	_live(func() -> String:
		var economy := session.economy
		return tr("finance.total") % [MobileLocale.number(economy.revenue), MobileLocale.number(economy.expenses), MobileLocale.number(economy.profit()), MobileLocale.number(economy.capital_spent)])
	_text(tr("finance.hint"))
	_text(tr("finance.transactions"))
	for index in range(maxi(0, session.economy.ledger.size() - 10), session.economy.ledger.size()):
		var item: Dictionary = session.economy.ledger[index]
		_text(tr("finance.transaction") % [MobileLocale.number(item.amount), MobileLabels.transaction_reason(item.reason)])

func _reviews() -> void:
	_text(tr("review.hint"))
	if session.guests.reviews.is_empty():
		_text(tr("review.empty"))
	for index in range(session.guests.reviews.size() - 1, -1, -1):
		_text(MobileLabels.review(session.guests.reviews[index], session.rules.day_seconds))

func _missions() -> void:
	_guide()
	for objective in HotelProgression.OBJECTIVES:
		_text(tr("objective." + String(objective.id)))
		if session.progression.completed.has(objective.id):
			_text(tr("ui.objective_completed"))
		else:
			for metric: String in objective.requirements:
				_live(func() -> String: return tr("ui.objective_progress") % [tr("metric." + metric), int(session.progression_metrics().get(metric, 0)), int(objective.requirements[metric])])

func _settings() -> void:
	_action("ui.large_text_on" if UIPreferences.load_large_text() else "ui.large_text_off", &"large_text", {}, HotelArt.preference_icon(&"text_size"))
	_action("ui.sound_on" if sound_enabled else "ui.sound_off", &"sound", {}, HotelArt.preference_icon(&"sound_on" if sound_enabled else &"sound_off"))
	_action("ui.haptics_on" if haptics_enabled else "ui.haptics_off", &"haptics")
	_text(tr("ui.language"))
	for locale: String in ["pt_BR", "en", "es"]:
		var button := _action("language." + locale, &"locale", {"locale": locale})
		button.disabled = TranslationServer.get_locale() == locale

func _portrait(actor: ActorState) -> void:
	var picture := TextureRect.new()
	picture.name = "ActorPortrait"
	picture.custom_minimum_size = Vector2(72, 72)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.texture = HotelArt.portrait(actor)
	shell.sheet_content.add_child(picture)

func _guide() -> void:
	if onboarding == null:
		return
	if not onboarding.enabled or onboarding.skipped:
		_action("guide.start", &"guide_resume", {}, HotelArt.management_icon(&"help"))
		return
	_text(tr("guide.title"))
	_live(func() -> String: return tr("guide.progress") % [onboarding.stage, OnboardingService.STEPS.size()])
	_text(tr("guide." + onboarding.step_id()))
	if onboarding.active():
		_action("guide.action", &"guide_next", {}, HotelArt.management_icon(&"objectives"))
		_action("guide.skip", &"guide_skip", {}, HotelArt.management_icon(&"help"))

func _manual_overview() -> void:
	_text(tr("work.title"))
	_work_status(true)
	if session.player_work.job.is_empty():
		for room in session.hotel.rooms:
			if room.definition().category == &"reception":
				_work_button("checkin", room.id, HotelArt.staff_icon(&"receptionist"))
			elif room.dirty:
				_work_button("cleaning", room.id, HotelArt.staff_icon(&"cleaner"))
	_orders()
	if session.player_work.orders.is_empty():
		_text(tr("work.orders_empty"))

func _work_status(always: bool = false) -> void:
	if not always and session.player_work.job.is_empty():
		return
	if not session.player_work.job.is_empty():
		_action("work.cancel", &"player_cancel")
	_live(func() -> String: return MobileLabels.player_work(session))
	if not session.player_work.job.is_empty():
		var progress := ProgressBar.new()
		progress.custom_minimum_size.y = 16
		progress.show_percentage = false
		shell.sheet_content.add_child(progress)
		updates.append(func() -> void:
			var job := session.player_work.job
			progress.value = 100 * (1.0 - float(job.get("remaining", 0.0)) / maxf(0.1, float(job.get("duration", 1.0)))) if job.get("phase") in ["action", "prepare", "deliver"] else 0)

func _work_button(kind: String, id: int, icon: Texture2D) -> void:
	var room := session.hotel.by_id(id)
	var button := _action("work." + kind, &"player_work", {"kind": kind, "id": id}, icon)
	button.text = tr("work." + kind) + " · " + MobileLabels.room_name(room)
	var reason := _text("")
	updates.append(func() -> void:
		var error := session.player_work.task_error(session, kind, id)
		button.disabled = not error.is_empty()
		reason.text = tr("work.error." + error) if not error.is_empty() else tr("work.ready"))

func _orders(bedroom_id: int = -1) -> void:
	for order in session.player_work.orders:
		var guest: ActorState = session.actors.get(int(order.guest_id))
		if guest == null or (bedroom_id >= 0 and guest.bedroom != bedroom_id):
			continue
		var button := _action("work.room_service", &"room_service", {"order_id": int(order.id)}, HotelArt.action_icon(&"room_service"))
		button.text = tr("work.order") % [MobileLabels.actor_name(guest), MobileLabels.room_name(session.hotel.by_id(guest.bedroom))]
		updates.append(func() -> void: button.disabled = not session.player_work.order_error(session, int(order.id)).is_empty())
		var source := session.player_work.food_source(session, guest, guest.floor_index)
		if source != null:
			_text(tr("work.delivery_price") % MobileLocale.number(source.price()))
