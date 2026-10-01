extends Control
## Art fixture uses the production touch view without desktop management UI.

var view := HotelView.new()
var selected_actor: int = -1

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.actor_clicked.connect(func(id: int) -> void: selected_actor = id)

func _replace_session(session: HotelSession) -> void:
	view.hotel = session.hotel
	view.session = session
	view.queue_redraw()

func _process(_delta: float) -> void:
	# Art tests change ticks/camera directly, outside application commands.
	view.queue_redraw()
