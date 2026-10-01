extends RefCounted
## Injected storage fault; no asynchronous I/O or platform dependency in domain.

var game: GameController
var mode: String = "fail"
var calls: int = 0
var nested_error: String = ""
var build_error: String = ""
var pause_result: String = ""

func write(data: Dictionary, path: String, validator: Callable) -> String:
	calls += 1
	if calls == 1 and game != null:
		nested_error = game.use_speedup(1, &"5m", 1)
		build_error = game.build(HotelCatalog.room(&"bedroom"), 10, 0).error
		game.advance(0.1)
		if mode in ["pause", "pause_resume"]:
			pause_result = game.enter_background()
			if mode == "pause_resume":
				game.resume()
	if mode == "fail":
		return "save.error.write"
	return AtomicJSONStore.write(data, path, validator)
