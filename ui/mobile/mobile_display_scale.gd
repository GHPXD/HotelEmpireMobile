class_name MobileDisplayScale
extends RefCounted
## Logical UI units follow the device scale, independent of pixel resolution.

var override_scale: float = 0.0

func apply(window: Window) -> void:
	if override_scale <= 0.0 and OS.get_name() not in ["Android", "iOS"]:
		return
	var scale := override_scale if override_scale > 0.0 else DisplayServer.screen_get_scale()
	if not is_finite(scale) or scale <= 0.0:
		scale = 1.0
	var logical := Vector2i((Vector2(window.size) / scale).round())
	logical = logical.max(Vector2i(1, 1))
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.content_scale_factor = 1.0
	if window.content_scale_size != logical:
		window.content_scale_size = logical
