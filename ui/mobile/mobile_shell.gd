class_name MobileShell
extends Control
## Responsive shell owns only view state. Domain mutations go through AppRoot.

signal navigation_requested(destination: StringName)
signal open_requested
signal pause_requested
signal close_requested

var world_slot: Control
var navigation: GridContainer
var top: GridContainer
var cash: Label
var reputation: Label
var guests: Label
var message: Label
var open_button: Button
var pause_button: Button
var sheet: PanelContainer
var sheet_content: VBoxContainer
var sheet_scroll: ScrollContainer
var modal_blocker: Control
var nav_buttons: Dictionary = {}
var body: VBoxContainer
var actions: GridContainer
var world_body: BoxContainer
var sheet_title: Label

func _ready() -> void:
	theme = MobileTheme.create(UIPreferences.load_large_text())
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body = VBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(body)
	top = GridContainer.new()
	top.columns = 3
	body.add_child(top)
	cash = label(top, "")
	reputation = label(top, "")
	guests = label(top, "")
	actions = GridContainer.new()
	actions.columns = 3
	body.add_child(actions)
	open_button = button(actions, "ui.open", func() -> void: open_requested.emit())
	pause_button = button(actions, "ui.pause", func() -> void: pause_requested.emit())
	button(actions, "ui.settings", func() -> void: navigation_requested.emit(&"settings"))
	world_body = BoxContainer.new()
	world_body.name = "HotelAndContext"
	world_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	world_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(world_body)
	world_body.resized.connect(_layout)
	world_slot = Control.new()
	world_slot.name = "HotelWorld"
	world_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	world_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_slot.custom_minimum_size = Vector2(0, 100)
	world_body.add_child(world_slot)
	message = label(body, "ui.ready")
	message.custom_minimum_size.y = 36
	message.add_theme_font_size_override("font_size", 14)
	navigation = GridContainer.new()
	navigation.name = "BottomNavigation"
	navigation.columns = 5
	body.add_child(navigation)
	for destination: StringName in [&"hotel", &"build", &"missions", &"staff", &"store"]:
		var nav := button(navigation, "ui." + String(destination), func() -> void: navigation_requested.emit(destination))
		nav.name = String(destination).capitalize()
		nav.add_theme_font_size_override("font_size", 14)
		nav_buttons[destination] = nav
	modal_blocker = Control.new()
	modal_blocker.name = "ModalBlocker"
	modal_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	world_slot.add_child(modal_blocker)
	modal_blocker.hide()
	sheet = PanelContainer.new()
	sheet.name = "ContextSheet"
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	world_body.add_child(sheet)
	var sheet_layout := VBoxContainer.new()
	sheet.add_child(sheet_layout)
	var heading := HBoxContainer.new()
	sheet_layout.add_child(heading)
	sheet_title = label(heading, "")
	sheet_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	sheet_title.clip_text = true
	sheet_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sheet_title.add_theme_font_size_override("font_size", 18)
	var close := button(heading, "ui.back", func() -> void: close_requested.emit())
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.custom_minimum_size.x = 90
	sheet_scroll = ScrollContainer.new()
	sheet_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sheet_scroll.custom_minimum_size.y = 48
	sheet_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sheet_layout.add_child(sheet_scroll)
	sheet_content = VBoxContainer.new()
	sheet_content.name = "SheetContent"
	sheet_content.mouse_filter = Control.MOUSE_FILTER_PASS
	sheet_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet_scroll.add_child(sheet_content)
	sheet.hide()
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if navigation == null:
		return
	navigation.columns = 3 if size.x < 540 and size.x <= size.y else 5
	top.columns = 1 if size.x < 340 and theme.default_font_size > 16 else (2 if size.x < 440 else 3)
	actions.columns = 3
	var compact := size.y < 400 and size.x > size.y
	if compact and message.get_parent() != world_slot:
		message.reparent(world_slot)
		message.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		message.offset_bottom = 24
		message.custom_minimum_size.y = 24
		message.autowrap_mode = TextServer.AUTOWRAP_OFF
		message.clip_text = true
		message.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		message.z_index = 1
	elif not compact and message.get_parent() != body:
		message.reparent(body)
		body.move_child(message, navigation.get_index())
		message.custom_minimum_size.y = 36
		message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		message.clip_text = false
		message.z_index = 0
	for button: Button in nav_buttons.values():
		button.add_theme_font_size_override("font_size", 18 if theme.default_font_size > 16 else 14)
	# Allocate context space alongside the world instead of covering the hotel.
	world_body.vertical = size.x < 720 and size.x <= size.y
	if not world_body.vertical:
		sheet.custom_minimum_size = Vector2(clampf(size.x * 0.38, 240, 360), 0)
		sheet.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sheet.size_flags_horizontal = Control.SIZE_FILL
	else:
		var height := minf(maxf(180, world_body.size.y * 0.48), maxf(120, world_body.size.y - 106))
		sheet.custom_minimum_size = Vector2(0, height)
		sheet.size_flags_vertical = Control.SIZE_FILL
		sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func refresh(session: HotelSession) -> void:
	cash.text = tr("ui.cash") % MobileLocale.number(session.economy.cash)
	reputation.text = tr("ui.reputation") % str(roundi(session.guests.reputation))
	guests.text = tr("ui.guests") % str(session.guest_count())
	open_button.text = tr("ui.close_hotel" if session.opened else "ui.open")
	pause_button.text = tr("ui.resume" if session.speed == 0 else "ui.pause")

func set_message(key: String) -> void:
	message.set_meta("translation_key", key)
	message.text = tr(key)

func refresh_locale() -> void:
	for item in find_children("*", "Control", true, false):
		if item.has_meta("translation_key"):
			item.text = tr(item.get_meta("translation_key"))

func clear_sheet() -> void:
	for child in sheet_content.get_children():
		sheet_content.remove_child(child)
		child.queue_free()
	sheet_scroll.scroll_vertical = 0

func show_sheet(modal: bool = false) -> void:
	_set_modal(modal)
	sheet.show()
	_layout()

func hide_sheet() -> void:
	sheet.hide()
	_set_modal(false)

func _set_modal(enabled: bool) -> void:
	modal_blocker.visible = enabled
	if enabled:
		world_slot.move_child(modal_blocker, -1)
	for bar in [actions, navigation]:
		for item: Button in bar.get_children():
			if enabled and not item.has_meta("before_modal_disabled"):
				item.set_meta("before_modal_disabled", item.disabled)
				item.disabled = true
			elif not enabled and item.has_meta("before_modal_disabled"):
				item.disabled = item.get_meta("before_modal_disabled")
				item.remove_meta("before_modal_disabled")

func label(parent: Node, key: String) -> Label:
	var item := Label.new()
	item.text = tr(key) if not key.is_empty() else ""
	if not key.is_empty():
		item.set_meta("translation_key", key)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func button(parent: Node, key: String, action: Callable, icon: Texture2D = null) -> Button:
	var item := Button.new()
	item.text = tr(key)
	item.set_meta("translation_key", key)
	item.custom_minimum_size = Vector2(0, 48)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.icon = icon
	item.expand_icon = true
	item.mouse_filter = Control.MOUSE_FILTER_PASS
	item.clip_text = true
	item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	item.add_theme_constant_override("icon_max_width", 32)
	item.pressed.connect(action)
	parent.add_child(item)
	return item
