class_name HotelHUD
extends Control

signal build_requested(definition: RoomDefinition)
signal floor_requested
signal demolish_requested
signal cancel_requested
signal hire_requested(definition: EmployeeDefinition)
signal speed_requested(value: int)
signal open_requested
signal save_requested
signal load_requested
signal new_requested
signal debug_requested
signal finances_requested
signal staff_requested
signal upgrade_requested
signal tariff_requested(percent: int)
signal objectives_requested
signal operations_requested
signal text_size_requested
signal audio_requested
signal help_requested
signal reviews_requested

var stats: Label
var message: Label
var inspector: Label
var world_slot: Control
var operations: Label
var open_button: Button
var debug_label: Label
var upgrade_button: Button
var upgrade_preview: Label
var tariff_choice: OptionButton
var tariff_label: Label
var tariff_effect: Label
const TARIFFS: Array[int] = [75, 100, 125]
var objectives_button: Button
var build_buttons: Dictionary = {}
var event_label: Label
var operations_button: Button
var text_size_button: Button
var build_search: LineEdit
var build_category: OptionButton
var catalog_count: Label
var sidebar_scroll: ScrollContainer
var session_buttons: Dictionary = {}
var audio_button: Button
var help_button: Button
const BUILD_CATEGORIES: Array[StringName] = [&"", &"lodging", &"service", &"infrastructure"]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_theme()
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 0)
	add_child(layout)
	var header := PanelContainer.new()
	layout.add_child(header)
	var header_row := HBoxContainer.new()
	header.add_child(header_row)
	var title := Label.new()
	title.text = "  HOTEL EMPIRE  "
	title.add_theme_font_size_override("font_size", 24)
	header_row.add_child(title)
	stats = Label.new()
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_row.add_child(stats)
	var toolbar := HBoxContainer.new()
	layout.add_child(toolbar)
	open_button = Button.new()
	open_button.custom_minimum_size.x = 175
	open_button.text = "Abrir hotel"
	open_button.pressed.connect(func() -> void: open_requested.emit())
	toolbar.add_child(open_button)
	for speed_value in [0, 1, 2, 3]:
		_button(toolbar, "Pausa" if speed_value == 0 else "%dx" % speed_value, func() -> void: speed_requested.emit(speed_value))
	operations = Label.new()
	operations.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	operations.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toolbar.add_child(operations)
	var session_bar := HFlowContainer.new()
	layout.add_child(session_bar)
	_button(session_bar, "Novo hotel", func() -> void: new_requested.emit())
	_button(session_bar, "Salvar", func() -> void: save_requested.emit())
	_button(session_bar, "Carregar", func() -> void: load_requested.emit())
	_button(session_bar, "Finanças", func() -> void: finances_requested.emit())
	_button(session_bar, "Equipe", func() -> void: staff_requested.emit())
	operations_button = _button(session_bar, "Operação • F2", func() -> void: operations_requested.emit())
	text_size_button = _button(session_bar, "Texto + • F4", func() -> void: text_size_requested.emit())
	objectives_button = Button.new()
	objectives_button.text = "Objetivos 0/%d" % HotelProgression.OBJECTIVES.size()
	objectives_button.custom_minimum_size.y = 42
	objectives_button.pressed.connect(func() -> void: objectives_requested.emit())
	session_bar.add_child(objectives_button)
	_button(session_bar, "Debug • F3", func() -> void: debug_requested.emit())
	audio_button = _button(session_bar, "Som: ligado", func() -> void: audio_requested.emit())
	help_button = _button(session_bar, "Ajuda • F1", func() -> void: help_requested.emit())
	_button(session_bar, "Avaliações", func() -> void: reviews_requested.emit())
	debug_label = Label.new()
	debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	debug_label.visible = false
	session_bar.add_child(debug_label)
	event_label = Label.new()
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(event_label)
	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 0)
	layout.add_child(content)
	world_slot = Control.new()
	world_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(world_slot)
	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size.x = 265
	content.add_child(sidebar)
	var scroll := ScrollContainer.new()
	sidebar_scroll = scroll
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(scroll)
	var tools := VBoxContainer.new()
	tools.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tools.add_theme_constant_override("separation", 10)
	scroll.add_child(tools)
	var build_title := Label.new()
	build_title.text = "CONSTRUIR"
	tools.add_child(build_title)
	var search_label := Label.new()
	search_label.text = "Buscar construção • Ctrl+F"
	tools.add_child(search_label)
	build_search = LineEdit.new()
	build_search.placeholder_text = "Nome da sala"
	build_search.clear_button_enabled = true
	build_search.text_changed.connect(func(_text: String) -> void: _filter_catalog())
	tools.add_child(build_search)
	build_category = OptionButton.new()
	for label in ["Todas as categorias", "Quartos", "Serviços", "Infraestrutura"]:
		build_category.add_item(label)
	build_category.item_selected.connect(func(_index: int) -> void: _filter_catalog())
	tools.add_child(build_category)
	catalog_count = Label.new()
	catalog_count.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tools.add_child(catalog_count)
	for definition in HotelCatalog.ROOMS:
		var button := Button.new()
		button.text = "%s\n$ %d   •   %d células" % [definition.display_name, definition.build_cost, definition.width]
		button.tooltip_text = "Manutenção: $ %d/dia • Capacidade: %d\nDisponível desde o início" % [definition.maintenance, definition.capacity]
		button.custom_minimum_size.y = 58
		button.icon = HotelArt.room(definition.id)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 36)
		button.pressed.connect(func() -> void: build_requested.emit(definition))
		tools.add_child(button)
		build_buttons[definition.id] = button
	_button(tools, "+ Andar   •   $ 750", func() -> void: floor_requested.emit())
	_button(tools, "Selecionar / cancelar", func() -> void: cancel_requested.emit())
	_button(tools, "Demolir seleção", func() -> void: demolish_requested.emit())
	var staff_title := Label.new()
	staff_title.text = "EQUIPE"
	tools.add_child(staff_title)
	for definition in HotelSession.EMPLOYEES:
		_button(tools, "+ %s • $ %d" % [definition.display_name, definition.hire_cost], func() -> void: hire_requested.emit(definition))
	inspector = Label.new()
	inspector.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector.text = "Construa uma recepção no térreo para começar."
	inspector.custom_minimum_size.x = 235
	tools.add_child(inspector)
	tariff_label = Label.new()
	tariff_label.text = "TARIFA DA SALA"
	tools.add_child(tariff_label)
	tariff_choice = OptionButton.new()
	tariff_choice.custom_minimum_size.y = 44
	for label in ["Econômica • 75%", "Padrão • 100%", "Premium • 125%"]:
		tariff_choice.add_item(label)
	tariff_choice.tooltip_text = "Quartos: cobrança no check-in. Serviços: preço combinado ao iniciar. Atendimentos em curso mantêm o preço."
	tariff_choice.item_selected.connect(func(index: int) -> void: tariff_requested.emit(TARIFFS[index]))
	tools.add_child(tariff_choice)
	tariff_effect = Label.new()
	tariff_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tools.add_child(tariff_effect)
	upgrade_preview = Label.new()
	upgrade_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tools.add_child(upgrade_preview)
	upgrade_button = Button.new()
	upgrade_button.custom_minimum_size.y = 44
	upgrade_button.pressed.connect(func() -> void: upgrade_requested.emit())
	tools.add_child(upgrade_button)
	var footer := PanelContainer.new()
	layout.add_child(footer)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.text = "Comece pela recepção, quartos e equipe. Ajuda • F1 mostra como abrir seu hotel."
	footer.add_child(message)

func refresh(hotel: HotelModel, selected: RoomState) -> void:
	tariff_choice.visible = selected != null and selected.definition().category in [&"lodging", &"service"]
	tariff_label.visible = tariff_choice.visible
	tariff_effect.visible = selected != null and selected.definition().category == &"lodging"
	if tariff_effect.visible:
		tariff_effect.text = "SATISFAÇÃO NO CHECK-IN\nConforme o perfil do hóspede:"
		for index in TARIFFS.size():
			var low: float = INF
			var high: float = -INF
			for profile: GuestArchetype in HotelCatalog.GUESTS:
				var delta := selected.lodging_value_delta(profile, TARIFFS[index])
				low = minf(low, delta)
				high = maxf(high, delta)
			tariff_effect.text += "\n%d%%: %+.1f a %+.1f pontos" % [TARIFFS[index], low, high]
		tariff_effect.text += "\nLimite: 0–100. Uma vez por estadia; sem efeito retroativo."
	if tariff_choice.visible:
		tariff_choice.select(TARIFFS.find(selected.price_percent))
	upgrade_button.visible = selected != null
	upgrade_preview.visible = selected != null
	stats.text = "$ %s    |    %d andar(es)    |    Investido: $ %d" % [hotel.economy.cash, hotel.floors, hotel.economy.capital_spent]
	if selected != null:
		var definition := selected.definition()
		inspector.text = "%s  #%d • N%d\n\nCapacidade: %d\nUsuários: %d\nFila: %d\nReceita: $ %d\nTarifa: $ %d\nAtendimento: %.1fs\nManutenção: $ %d/dia\n\nDemolição sem reembolso." % [definition.display_name, selected.id, selected.level, selected.capacity(), selected.users.size(), selected.queue.members.size(), selected.income, selected.price(), selected.duration(), selected.maintenance()]
		var next := selected.next_upgrade()
		upgrade_button.disabled = next == null or hotel.economy.cash < next.cost
		upgrade_button.text = "Nível máximo" if next == null else "Melhorar para N%d • $ %d" % [selected.level + 1, next.cost]
		upgrade_preview.text = "" if next == null else "PRÓXIMO NÍVEL\nCapacidade: %d → %d\nTarifa: $ %d → $ %d\nManutenção: $ %d → $ %d/dia" % [selected.capacity(), definition.capacity + next.capacity_bonus, selected.price(), selected.scaled_price(definition.price + next.price_bonus), selected.maintenance(), definition.maintenance + next.maintenance_bonus]
		if next != null and definition.category == &"transport":
			upgrade_preview.text += "\nVelocidade: %.2fx → %.2fx" % [selected.speed_multiplier(), next.speed_multiplier]
		elif next != null:
			upgrade_preview.text += "\nAtendimento: %.1fs → %.1fs\nBônus satisfação: +%.0f → +%.0f" % [selected.duration(), definition.service_duration * next.duration_multiplier, selected.satisfaction_bonus(), next.satisfaction_bonus]
	else:
		inspector.text = "SEU PRIMEIRO HOTEL\n\n1. Recepção no térreo\n2. Quartos para hospedar\n3. Bistrô para refeições\n4. Elevador para expandir\n\nPoços ocupam a mesma coluna em todos os andares."

func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 42
	button.pressed.connect(action)
	parent.add_child(button)
	session_buttons[text] = button
	return button

func _filter_catalog() -> void:
	var count: int = 0
	var category: StringName = BUILD_CATEGORIES[build_category.selected]
	var query := UILabels.search_key(build_search.text)
	for definition in HotelCatalog.ROOMS:
		var matches: bool = category.is_empty() or definition.category == category or (category == &"infrastructure" and definition.category in [&"reception", &"transport"])
		var button: Button = build_buttons[definition.id]
		button.visible = matches and (query.is_empty() or UILabels.search_key(definition.display_name).contains(query))
		if button.visible:
			count += 1
	catalog_count.text = "%d construção(ões)" % count if count > 0 else "Nenhuma construção encontrada. Limpe a busca ou troque a categoria."

func reset_catalog() -> void:
	build_search.text = ""
	build_category.select(0)
	_filter_catalog()

func set_large_text(enabled: bool) -> void:
	theme.default_font_size = 20 if enabled else 16
	text_size_button.text = "Texto − • F4" if enabled else "Texto + • F4"
	sidebar_scroll.get_parent().custom_minimum_size.x = 320 if enabled else 265

func refresh_simulation(session: HotelSession, actor_id: int) -> void:
	_filter_catalog()
	for definition in HotelCatalog.ROOMS:
		var button: Button = build_buttons[definition.id]
		var locked := session.progression.build_error(definition)
		button.disabled = not locked.is_empty()
		button.text = "%s\n%s" % [definition.display_name, "Bloqueado • veja Objetivos" if button.disabled else "$ %d   •   %d células" % [definition.build_cost, definition.width]]
		button.tooltip_text = locked if button.disabled else "Manutenção: $ %d/dia • Capacidade: %d\nTarifa: $ %d • Atendimento: %.1fs" % [definition.maintenance, definition.capacity, definition.price, definition.service_duration]
	var event := HotelEvents.state(session.tick_count, session.rules)
	event_label.text = "  %s • %.0fs %s" % [event.name, event.remaining, "restantes • procura %.0f%%" % (event.multiplier * 100) if event.active else "para começar"]
	event_label.tooltip_text = event.description
	objectives_button.text = "Objetivos %d/%d" % [session.progression.completed.size(), HotelProgression.OBJECTIVES.size()]
	objectives_button.tooltip_text = session.progression.summary()
	stats.text = "$ %d   |   Reputação %.0f   |   Hóspedes %d   |   Lucro $ %d   |   Dia %d • %dx" % [session.economy.cash, session.guests.reputation, session.guest_count(), session.economy.profit(), session.day + 1, session.speed]
	open_button.text = "Fechar chegadas" if session.opened else "Abrir hotel"
	operations.text = session.alerts()
	if debug_label.visible:
		var waiting: int = 0
		var riding: int = 0
		for lift in session.transport.lifts:
			waiting += lift.queue.members.size()
			riding += lift.passengers.size()
		debug_label.text = "FPS %d | Agentes %d | Elevador: fila %d, bordo %d | Rotas %d | Tick %d" % [Engine.get_frames_per_second(), session.actors.size(), waiting, riding, session.transport.path_requests, session.tick_count]
	var actor: ActorState = session.actors.get(actor_id)
	if actor != null:
		inspector.text = "%s\n%s • %s\n\nSatisfação: %.0f\nFome: %.0f\nCansaço: %.0f\nDinheiro: $ %d\nQuarto: %s\nTempo: %.0fs\nEspera: %.1fs\nDestino: andar %d" % [actor.display_name, UILabels.role(actor.role), UILabels.state(actor.state), actor.happiness, actor.needs.hunger, actor.needs.energy, actor.money, "Sem reserva" if actor.bedroom < 0 else str(actor.bedroom), actor.age, actor.waiting, actor.target_floor]
		if actor.role == &"guest":
			inspector.text += "\n\nPerfil: %s\n%s\nLazer: %.0f\nServiços usados: %d" % [actor.archetype().display_name, actor.archetype().description, actor.needs.entertainment, actor.service_uses]
		if debug_label.visible:
			inspector.text += "\n\nUtilidades (debug):\n%s" % str(actor.utility_scores)

func refresh_unlock(session: HotelSession, room: RoomState) -> void:
	upgrade_button.tooltip_text = ""
	if room == null or room.next_upgrade() == null:
		return
	var locked := session.progression.upgrade_error(room)
	if not locked.is_empty():
		upgrade_button.disabled = true
		upgrade_button.text = "N3 bloqueado • veja Objetivos"
		upgrade_button.tooltip_text = locked
		upgrade_preview.text += "\n\n" + locked

func _build_theme() -> void:
	theme = Theme.new()
	theme.default_font_size = 16
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("203a43")
	panel.content_margin_left = 14
	panel.content_margin_right = 14
	panel.content_margin_top = 14
	panel.content_margin_bottom = 14
	theme.set_stylebox("panel", "PanelContainer", panel)
	for state in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("35535c") if state == "normal" else Color("496f72")
		box.set_corner_radius_all(7)
		box.content_margin_left = 10
		box.content_margin_right = 10
		if state == "focus":
			box.bg_color = Color.TRANSPARENT
			box.border_color = Color("f7cf79")
			box.set_border_width_all(2)
		theme.set_stylebox(state, "Button", box)
	theme.set_color("font_color", "Label", Color("eef1e5"))
	theme.set_color("font_disabled_color", "Button", Color("acbdbc"))
	for control_type in ["LineEdit", "OptionButton", "ItemList"]:
		theme.set_stylebox("focus", control_type, theme.get_stylebox("focus", "Button"))
