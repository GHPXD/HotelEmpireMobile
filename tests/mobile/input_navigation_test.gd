extends SceneTree

var failures: int = 0
var checks: int = 0
var taps: int = 0
var movement := Vector2.ZERO
var scale_factor: float = 1.0
var previous_focus := Vector2.ZERO
var focus := Vector2.ZERO

func _initialize() -> void:
	var input := MobileInputController.new()
	input.tapped.connect(func(_point: Vector2) -> void: taps += 1)
	input.panned.connect(func(delta: Vector2) -> void: movement += delta)
	input.pinched.connect(func(factor: float, old_center: Vector2, center: Vector2) -> void:
		scale_factor = factor
		previous_focus = old_center
		focus = center)
	input.handle(touch(0, Vector2(100, 100), true))
	input.handle(touch(0, Vector2(101, 101), false))
	check(taps == 1, "tap emits once on release")
	input.handle(touch(0, Vector2(100, 100), true))
	input.handle(drag(0, Vector2(103, 104)))
	input.handle(touch(0, Vector2(103, 104), false))
	check(taps == 2 and movement == Vector2.ZERO, "small movement stays tap")
	input.handle(touch(0, Vector2(100, 100), true))
	input.handle(drag(0, Vector2(130, 110)))
	input.handle(touch(0, Vector2(130, 110), false))
	check(taps == 2 and movement == Vector2(30, 10), "pan cannot trigger selection/build")
	input.handle(touch(0, Vector2(100, 100), true))
	input.handle(touch(1, Vector2(200, 100), true))
	input.handle(drag(1, Vector2(250, 100)))
	check(is_equal_approx(scale_factor, 1.5) and previous_focus == Vector2(150, 100) and focus == Vector2(175, 100), "pinch tracks scale and centroid")
	input.handle(touch(1, Vector2(250, 100), false))
	input.handle(touch(0, Vector2(100, 100), false))
	check(taps == 2, "pinch finger release never becomes tap")
	input.handle(touch(0, Vector2(100, 100), true))
	var cancelled := touch(0, Vector2(100, 100), false)
	cancelled.canceled = true
	input.handle(cancelled)
	check(input.pointers.is_empty() and taps == 2, "OS gesture cancel clears capture")
	check(not input.handle(drag(4, Vector2.ZERO)), "uncaptured UI drag cannot pan hotel")
	input.handle(touch(0, Vector2.ZERO, true))
	input.reset()
	check(not input.handle(touch(0, Vector2.ZERO, false)), "overlay interrupts gesture")
	var mouse := InputEventMouseButton.new()
	mouse.device = InputEvent.DEVICE_ID_EMULATION
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	input.handle(mouse)
	mouse.pressed = false
	input.handle(mouse)
	check(taps == 2, "touch mouse emulation cannot double tap")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	check(not input.handle(wheel), "no dependency on wheel")
	var router := ScreenRouter.new()
	router.navigate(&"build")
	router.open_sheet(&"room", 1)
	router.open_sheet(&"guest", 2)
	check(router.sheet == &"guest" and router.context_id == 2, "single contextual sheet replaces old")
	check(router.back() and router.screen == &"build" and router.sheet.is_empty(), "back closes sheet first")
	check(router.back() and router.screen == &"hotel", "back returns to hotel")
	check(not router.back(), "root back is platform decision")
	router.navigate(&"invalid")
	check(router.screen == &"hotel", "unknown navigation ignored")
	check(MobileSafeArea.insets(Vector2(800, 400), Vector2(1600, 800), Rect2(80, 20, 1440, 720)) == Vector4(40, 10, 40, 30), "safe area scales to root units")
	check(MobileSafeArea.insets(Vector2(400, 800), Vector2(800, 1600), Rect2(0, 80, 800, 1480)) == Vector4(0, 40, 0, 20), "portrait notch and gesture bar")
	check(MobileSafeArea.insets(Vector2(800, 400), Vector2.ZERO, Rect2()) == Vector4.ZERO, "headless safe fallback")
	check(MobileSafeArea.insets(Vector2(800, 400), Vector2(800, 400), Rect2(-10, -10, 900, 450)) == Vector4.ZERO, "safe bounds clamp")
	print(JSON.stringify({"suite": "mobile_input_navigation", "checks": checks, "failures": failures}))
	print("MOBILE_TEST_COMPLETE")
	quit(1 if failures else 0)

func touch(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event

func drag(index: int, position: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	return event

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
