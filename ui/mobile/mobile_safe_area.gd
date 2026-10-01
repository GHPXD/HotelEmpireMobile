class_name MobileSafeArea
extends MarginContainer
## Convert OS safe-area pixels into the actual root Control coordinate space.

var override_safe_area := Rect2(-1, -1, -1, -1)
var override_window_size := Vector2.ZERO
const PADDING: int = 8

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(refresh)
	refresh()

static func insets(view_size: Vector2, window_size: Vector2, safe_rect: Rect2) -> Vector4:
	if window_size.x <= 0 or window_size.y <= 0 or safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		return Vector4.ZERO
	var ratio := view_size / window_size
	var clipped := safe_rect.intersection(Rect2(Vector2.ZERO, window_size))
	if not clipped.has_area():
		return Vector4.ZERO
	return Vector4(maxf(0, clipped.position.x * ratio.x), maxf(0, clipped.position.y * ratio.y),
		maxf(0, (window_size.x - clipped.end.x) * ratio.x), maxf(0, (window_size.y - clipped.end.y) * ratio.y))

func refresh() -> void:
	var window_size := Vector2(DisplayServer.window_get_size())
	var safe_rect := Rect2(Vector2.ZERO, window_size)
	if OS.get_name() in ["Android", "iOS"]:
		safe_rect = Rect2(DisplayServer.get_display_safe_area())
	if override_safe_area.size.x >= 0:
		safe_rect = override_safe_area
		window_size = override_window_size
	var margins := insets(size, window_size, safe_rect)
	add_theme_constant_override("margin_left", ceili(margins.x) + PADDING)
	add_theme_constant_override("margin_top", ceili(margins.y) + PADDING)
	add_theme_constant_override("margin_right", ceili(margins.z) + PADDING)
	add_theme_constant_override("margin_bottom", ceili(margins.w) + PADDING)
