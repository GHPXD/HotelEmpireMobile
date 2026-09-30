class_name StaffPanel
extends Window

signal assignment_changed
var session: HotelSession
var employee_choice: OptionButton
var destination_choice: OptionButton
var details: Label
var role_icon: TextureRect
var feedback: Label
var apply_button: Button

func _ready() -> void:
	hide()
	title = "Gestão da equipe"
	size = Vector2i(620, 420)
	min_size = Vector2i(500, 360)
	close_requested.connect(hide)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	var label := Label.new()
	label.text = "FUNCIONÁRIO"
	column.add_child(label)
	employee_choice = OptionButton.new()
	employee_choice.item_selected.connect(func(_index: int) -> void: _refresh_destinations())
	column.add_child(employee_choice)
	var detail_row := HBoxContainer.new()
	detail_row.add_theme_constant_override("separation", 12)
	column.add_child(detail_row)
	role_icon = TextureRect.new()
	role_icon.custom_minimum_size = Vector2(48, 48)
	role_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	role_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	role_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	role_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	role_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_row.add_child(role_icon)
	details = Label.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_row.add_child(details)
	destination_choice = OptionButton.new()
	column.add_child(destination_choice)
	apply_button = Button.new()
	apply_button.text = "Aplicar atribuição"
	apply_button.pressed.connect(_apply)
	column.add_child(apply_button)
	feedback = Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(feedback)

func open_for(value: HotelSession) -> void:
	session = value
	employee_choice.clear()
	for actor: ActorState in session.actors.values():
		if actor.role != &"guest":
			employee_choice.add_item(actor.display_name, actor.id)
	feedback.text = "Atribuições novas respeitam a viagem ou limpeza já iniciada."
	_refresh_destinations()
	popup_centered()
	employee_choice.grab_focus()

func _refresh_destinations() -> void:
	destination_choice.clear()
	role_icon.texture = null
	role_icon.visible = false
	apply_button.disabled = employee_choice.item_count == 0
	if employee_choice.item_count == 0:
		details.text = "Contrate funcionários na lateral do hotel."
		return
	var actor: ActorState = session.actors.get(employee_choice.get_selected_id())
	if actor == null:
		apply_button.disabled = true
		details.text = "Funcionário indisponível."
		return
	role_icon.texture = HotelArt.staff_icon(actor.role)
	role_icon.visible = role_icon.texture != null
	destination_choice.add_item("Automático • hotel inteiro")
	destination_choice.set_item_metadata(0, -1)
	var desired: int = actor.preferred_room if actor.role == &"receptionist" else actor.preferred_floor
	if actor.role == &"receptionist":
		for room in session.hotel.rooms:
			if room.definition().category == &"reception":
				destination_choice.add_item("Recepção #%d • térreo" % room.id)
				destination_choice.set_item_metadata(destination_choice.item_count - 1, room.id)
	else:
		for floor_index in session.hotel.floors:
			destination_choice.add_item("Somente andar %d" % floor_index)
			destination_choice.set_item_metadata(destination_choice.item_count - 1, floor_index)
	for index in destination_choice.item_count:
		if int(destination_choice.get_item_metadata(index)) == desired:
			destination_choice.select(index)
	var salary: int = 0
	for definition in HotelSession.EMPLOYEES:
		if definition.id == actor.role:
			salary = definition.salary
	details.text = "Estado: %s • %s\nSalário: $ %d/dia • Trabalho acumulado: %.0fs" % [UILabels.state(actor.state), "Sem tarefa" if actor.assignment < 0 else "Tarefa: sala #%d" % actor.assignment, salary, actor.workload]

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hide()
		set_input_as_handled()

func _apply() -> void:
	if employee_choice.selected < 0 or destination_choice.selected < 0:
		return
	var error := session.configure_employee(employee_choice.get_selected_id(), int(destination_choice.get_selected_metadata()))
	feedback.text = "Atribuição salva. Será aplicada na próxima tarefa disponível." if error.is_empty() else error
	assignment_changed.emit()
