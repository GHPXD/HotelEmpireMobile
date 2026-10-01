class_name MobileProfileSupport
extends RefCounted
## Benchmark fixtures, never shipped. Run with isolated user-data-root.

static func create(window: Window) -> AppRoot:
	var game: AppRoot = preload("res://core/application/app_root.tscn").instantiate()
	game.controller.saves.path = "user://profile-session.json"
	game.controller.saves.legacy_path = "user://profile-no-legacy.json"
	window.add_child(game)
	game.audio.enabled = false
	return game

static func activate(game: AppRoot, session: HotelSession) -> void:
	game.controller.session = session
	game.controller.accumulator = 0.0
	game.view.session = session
	game.view.hotel = session.hotel
	game.gestures.reset()
	game.router.navigate(&"hotel")
	game._route()
	game._refresh()
	game.view.queue_redraw()
