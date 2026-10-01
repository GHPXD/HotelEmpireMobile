class_name MobileInputController
extends RefCounted
## Device events become world gestures. Call only after GUI routing accepts them.

signal tapped(position: Vector2)
signal panned(delta: Vector2)
signal pinched(scale_factor: float, previous_focus: Vector2, focus: Vector2)
signal pointer_changed(position: Vector2)

const PAN_THRESHOLD: float = 12.0
var pointers: Dictionary = {}
var start_position: Vector2
var previous_position: Vector2
var suppress_tap: bool = false
var mouse_held: bool = false

func reset() -> void:
	pointers.clear()
	suppress_tap = false
	mouse_held = false

func handle(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		if event.canceled:
			reset()
			return true
		if event.pressed:
			if pointers.is_empty():
				start_position = event.position
				previous_position = event.position
				suppress_tap = false
			pointers[event.index] = event.position
			if pointers.size() > 1:
				suppress_tap = true
			pointer_changed.emit(event.position)
		else:
			if not pointers.has(event.index):
				return false
			var may_tap: bool = pointers.size() == 1 and not suppress_tap and event.position.distance_to(start_position) < PAN_THRESHOLD
			pointers.erase(event.index)
			if may_tap:
				tapped.emit(event.position)
			if pointers.size() == 1:
				previous_position = pointers.values()[0]
				start_position = previous_position
		return true
	if event is InputEventScreenDrag:
		if not pointers.has(event.index):
			return false
		var old_positions := pointers.values()
		pointers[event.index] = event.position
		pointer_changed.emit(event.position)
		if pointers.size() == 1:
			if not suppress_tap and event.position.distance_to(start_position) >= PAN_THRESHOLD:
				suppress_tap = true
			if suppress_tap:
				panned.emit(event.position - previous_position)
			previous_position = event.position
		elif pointers.size() == 2:
			var positions := pointers.values()
			var old_distance: float = old_positions[0].distance_to(old_positions[1])
			if old_distance > 0.001:
				var factor: float = positions[0].distance_to(positions[1]) / old_distance
				pinched.emit(factor, (old_positions[0] + old_positions[1]) / 2.0, (positions[0] + positions[1]) / 2.0)
		return true
	# One-button pointer emulation supports editor QA without desktop-only gestures.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return true
		var touch := InputEventScreenTouch.new()
		touch.index = -1
		touch.position = event.position
		touch.pressed = event.pressed
		mouse_held = event.pressed
		return handle(touch)
	if event is InputEventMouseMotion and mouse_held and event.device != InputEvent.DEVICE_ID_EMULATION:
		var drag_event := InputEventScreenDrag.new()
		drag_event.index = -1
		drag_event.position = event.position
		return handle(drag_event)
	return false
