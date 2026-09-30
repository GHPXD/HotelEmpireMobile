extends "res://tests/ui_new_game.gd"
## Native stateful presentation controls and device preferences, separate from saves.

var painted_areas: int = 0

func run() -> void:
	var game: Node = load("res://core/game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var original_large: bool = game.large_text
	var original_audio: bool = game.audio.enabled
	var session := SimulationRunner.make_hotel(850, "standard", 250000)
	session.speed = 0
	game._replace_session(session)
	game.audio.player.volume_db = -80.0
	var before := SessionSnapshot.capture(session)
	var activations := 0
	var shortcuts := 0
	var reloads := 0
	var layouts: Array[Dictionary] = []
	for resolution: Vector2i in [Vector2i(1024, 640), Vector2i(1280, 800), Vector2i(1600, 900), Vector2i(3840, 2160)]:
		root.size = resolution
		for large: bool in [false, true]:
			if game.large_text != large:
				game._toggle_text_size()
			if not game.audio.enabled:
				game._toggle_audio()
			game.hud.audio_button.icon = null
			game.hud.text_size_button.icon = null
			for frame in 4:
				await process_frame
			var plain_height: float = game.hud.world_slot.size.y
			var plain_audio_width: float = game.hud.audio_button.get_minimum_size().x
			var plain_text_width: float = game.hud.text_size_button.get_minimum_size().x
			game.hud.set_audio_enabled(true)
			game.hud.text_size_button.icon = HotelArt.preference_icon(&"text_size")
			for frame in 4:
				await process_frame
			var bar: HFlowContainer = game.hud.audio_button.get_parent()
			var row_height: float = game.hud.audio_button.size.y + bar.get_theme_constant("v_separation")
			check(game.hud.world_slot.size.y >= plain_height - row_height - 0.01, "preference icons cost at most one additional toolbar row")
			check(game.hud.audio_button.get_minimum_size().x >= plain_audio_width + 28 and game.hud.text_size_button.get_minimum_size().x >= plain_text_width + 28, "native preference controls reserve real icon width")
			layouts.append({"window": [resolution.x, resolution.y], "large_text": large, "plain_playfield_height": plain_height, "decorated_playfield_height": game.hud.world_slot.size.y})
			for keyboard: bool in [false, true]:
				for enabled: bool in [false, true]:
					if not enabled:
						game.audio.play(&"build")
						check(game.audio.player.playing, "mute fixture starts actual audio stream")
					await activate_preference(game.hud.audio_button, keyboard)
					activations += 1
					check(game.audio.enabled == enabled, "native audio button changes actual audio state")
					check(game.hud.audio_button.text == ("Som: ligado" if enabled else "Som: desligado"), "native audio label mirrors state")
					var config := ConfigFile.new()
					check(config.load("user://audio.cfg") == OK and config.get_value("audio", "enabled", null) == enabled, "audio preference persisted separately")
					if not enabled:
						check(not game.audio.player.playing, "muted player stopped")
					await verify_painted(game.hud.audio_button, &"sound_on" if enabled else &"sound_off")
					compare(before, SessionSnapshot.capture(session), "audio setting preserves entire hotel")
					if resolution in [Vector2i(1024, 640), Vector2i(3840, 2160)] and large and keyboard:
						root.get_texture().get_image().save_png("res://.runtime/m7-preferences-%d-%s.png" % [resolution.x, "on" if enabled else "off"])
				for target: bool in [not large, large]:
					await activate_preference(game.hud.text_size_button, keyboard)
					activations += 1
					check(game.large_text == target and game.hud.theme.default_font_size == (20 if target else 16), "native text button changes real theme size")
					check(game.hud.text_size_button.text == ("Texto − • F4" if target else "Texto + • F4"), "text label retains direction and F4 shortcut")
					check(UIPreferences.load_large_text() == target, "text preference persisted separately")
					await verify_painted(game.hud.text_size_button, &"text_size")
					compare(before, SessionSnapshot.capture(session), "text setting preserves entire hotel")
			for target: bool in [not large, large]:
				await key(root, KEY_F4)
				shortcuts += 1
				check(game.large_text == target and game.hud.text_size_button.icon == HotelArt.preference_icon(&"text_size"), "F4 changes text and retains painted icon")
				compare(before, SessionSnapshot.capture(session), "F4 preserves entire hotel")
	# A fresh main scene reads all four combinations from the actual device files.
	for enabled: bool in [false, true]:
		for large: bool in [false, true]:
			if game.audio.enabled != enabled:
				game._toggle_audio()
			if game.large_text != large:
				game._toggle_text_size()
			var fresh: Node = load("res://core/game/main.tscn").instantiate()
			root.add_child(fresh)
			fresh.session.speed = 0
			for frame in 4:
				await process_frame
			check(fresh.audio.enabled == enabled and fresh.hud.audio_button.icon == HotelArt.preference_icon(&"sound_on" if enabled else &"sound_off"), "startup restores audio state and matching icon")
			check(fresh.large_text == large and fresh.hud.theme.default_font_size == (20 if large else 16) and fresh.hud.text_size_button.icon == HotelArt.preference_icon(&"text_size"), "startup restores text preference and icon")
			fresh._replace_session(HotelSession.new())
			check(fresh.audio.enabled == enabled and fresh.large_text == large, "replacing hotel preserves device preferences")
			fresh.queue_free()
			await process_frame
			reloads += 1
	compare(before, SessionSnapshot.capture(session), "preference reload checks preserve original hotel")
	if game.audio.enabled != original_audio:
		game._toggle_audio()
	if game.large_text != original_large:
		game._toggle_text_size()
	print(JSON.stringify({"suite": "ui_preferences_icons", "preference_icons": 3, "activations": activations, "f4_activations": shortcuts, "preference_reloads": reloads, "painted_areas": painted_areas, "layouts": layouts, "failures": failures}))
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)

func activate_preference(button: Button, keyboard: bool) -> void:
	if keyboard:
		button.grab_focus()
		await key(root, KEY_ENTER)
	else:
		await click(root, button.get_global_rect().get_center())
	for frame in 4:
		await process_frame
	check(button.has_focus(), "preference activation retains native focus")

func verify_painted(button: Button, id: StringName) -> void:
	check(button.icon == HotelArt.preference_icon(id) and button.icon.get_width() == 256 and button.icon.get_image().detect_alpha() != Image.ALPHA_NONE, "dedicated transparent preference texture matches state")
	check(not button.expand_icon and button.get_theme_constant("icon_max_width") == 28, "preference icon participates in native minimum")
	check(root.get_visible_rect().encloses(button.get_global_rect()) and button.size.x >= button.get_combined_minimum_size().x, "preference control label and icon fit window")
	for sibling: Node in button.get_parent().get_children():
		if sibling is Button and sibling != button:
			check(not button.get_global_rect().intersects(sibling.get_global_rect()), "decorated toolbar buttons do not overlap")
	await RenderingServer.frame_post_draw
	var capture := root.get_texture().get_image()
	var pixel_scale := Vector2(capture.get_size()) / root.get_visible_rect().size
	var margin := button.get_theme_stylebox("normal").get_content_margin(SIDE_LEFT)
	var icon_bounds := Rect2(button.global_position + Vector2(margin, (button.size.y - 28) / 2), Vector2(28, 28))
	var pixels := Rect2(icon_bounds.position * pixel_scale, icon_bounds.size * pixel_scale)
	var crop := Rect2i(pixels.position.ceil(), pixels.end.floor() - pixels.position.ceil())
	var bright := 0
	for y in range(crop.position.y, crop.end.y):
		for x in range(crop.position.x, crop.end.x):
			var color := capture.get_pixel(x, y)
			if maxf(color.r, maxf(color.g, color.b)) > 0.65:
				bright += 1
	check(bright >= 10, "actual preference icon area contains painted pixels beyond toolbar background: %s at %s, font %d, painted %d" % [id, root.size, button.get_theme_font_size("font_size"), bright])
	painted_areas += 1
