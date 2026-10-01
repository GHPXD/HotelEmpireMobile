class_name MobileTheme
extends RefCounted
## Hotel palette: deep teal joinery, warm cream labels, brass focus borders.

static func create(large_text: bool = false) -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 20 if large_text else 16
	theme.set_color("font_color", "Label", Color("fff1cc"))
	theme.set_color("font_color", "Button", Color("fff1cc"))
	theme.set_color("font_disabled_color", "Button", Color("b3c4ba"))
	theme.set_constant("h_separation", "GridContainer", 4)
	theme.set_constant("v_separation", "GridContainer", 4)
	theme.set_constant("separation", "HBoxContainer", 4)
	theme.set_constant("separation", "VBoxContainer", 6)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("203a43")
	panel.border_color = Color("ba9b61")
	panel.set_border_width_all(1)
	panel.content_margin_left = 12
	panel.content_margin_right = 12
	panel.content_margin_top = 10
	panel.content_margin_bottom = 10
	theme.set_stylebox("panel", "PanelContainer", panel)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("35535c")
		if state == "pressed":
			box.bg_color = Color("57746e")
		if state == "disabled":
			box.bg_color = Color("263d42")
		box.border_color = Color("f7cf79") if state == "focus" else Color("64776b")
		box.set_border_width_all(2 if state == "focus" else 1)
		box.content_margin_left = 8
		box.content_margin_right = 8
		box.content_margin_top = 8
		box.content_margin_bottom = 8
		if state == "focus":
			box.bg_color = Color.TRANSPARENT
		theme.set_stylebox(state, "Button", box)
	return theme
