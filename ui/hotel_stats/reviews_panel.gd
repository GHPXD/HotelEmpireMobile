class_name GuestReviewsPanel
extends Window

var details: RichTextLabel

func _ready() -> void:
	title = "Avaliações dos visitantes"
	size = Vector2i(720, 550)
	min_size = Vector2i(460, 320)
	wrap_controls = true
	hide()
	close_requested.connect(hide)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	details = RichTextLabel.new()
	details.bbcode_enabled = false
	details.focus_mode = Control.FOCUS_ALL
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.custom_minimum_size = Vector2(400, 220)
	column.add_child(details)
	var close := Button.new()
	close.text = "Voltar ao hotel • Esc"
	close.custom_minimum_size.y = 42
	close.pressed.connect(hide)
	column.add_child(close)

func open_for(session: HotelSession) -> void:
	details.text = "ÚLTIMAS SAÍDAS • até %d registros\nRelatos baseados na experiência registrada. A nota abaixo é satisfação individual, não a reputação do hotel.\n\n" % GuestSystem.REVIEW_LIMIT
	if session.guests.reviews.is_empty():
		details.text += "Nenhuma avaliação registrada. Novas saídas aparecerão aqui. Saves antigos começam sem histórico reconstruído."
	else:
		for index in range(session.guests.reviews.size() - 1, -1, -1):
			details.text += describe(session.guests.reviews[index], session.rules.day_seconds) + "\n\n"
	popup_centered()
	details.scroll_to_line(0)
	details.grab_focus()

static func describe(review: Dictionary, day_seconds: float) -> String:
	var opinion := "Saí satisfeito com a experiência." if review.score >= 80 else ("Minha experiência foi razoável." if review.score >= 50 else "Saí insatisfeito com a experiência.")
	var stay := "Consegui me hospedar." if review.checked_in else "Saí sem me hospedar."
	var facts := "Refeições: %d • Outros serviços: %d • Descansos: %d" % [review.meals, review.services - review.meals, review.sleeps]
	return "Visitante %03d • %s • Dia %d\nSatisfação: %.1f/100\n%s %s\n%s" % [review.guest_id, HotelCatalog.guest(StringName(review.profile)).display_name, floori(review.time / day_seconds) + 1, review.score, opinion, stay, facts]

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hide()
		set_input_as_handled()
