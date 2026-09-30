extends "res://tests/ui_management.gd"

func run() -> void:
	var game: Node = load("res://core/game/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var session := SimulationRunner.make_hotel(55, "standard", 250000)
	session.speed = 0
	game._replace_session(session)
	game.view.zoom_factor = 0.75
	game.save_path = "user://content-ui.json"
	for frame in 5:
		await process_frame
	var cafe_button: Button = game.hud.build_buttons[&"cafe"]
	var lounge_button: Button = game.hud.build_buttons[&"lounge"]
	check(cafe_button.disabled and lounge_button.disabled, "new services visibly locked")
	check(cafe_button.tooltip_text.contains("Primeiras estadias"), "construction lock explained")
	session.guests.bookings = 3
	session.tick(0.1)
	game._refresh()
	check(not cafe_button.disabled and lounge_button.disabled, "first objective unlocks only cafe")
	await press_build(cafe_button)
	await click(root, game.view.room_rect(13, 1).get_center() + game.view.global_position)
	check(session.hotel.room_at(13, 1) != null and session.hotel.room_at(13, 1).definition_id == &"cafe", "cafe construction via viewport")
	session.guests.bookings = 10
	session.guests.meals_served = 5
	session.guests.service_uses = 5
	session.employees.cleaned = 5
	session.tick(0.1)
	game._refresh()
	await press_build(lounge_button)
	await click(root, game.view.room_rect(13, 0).get_center() + game.view.global_position)
	check(session.hotel.room_at(13, 0) != null and session.hotel.room_at(13, 0).definition_id == &"lounge", "lounge construction via viewport")
	for button: Node in game.hud.find_children("*", "Button", true, false):
		if button.text == "Selecionar / cancelar":
			await press_build(button)
	var actor := session.spawn_guest()
	actor.archetype_id = &"leisure"
	actor.money = actor.archetype().budget
	actor.x = 13.5
	actor.floor_index = 1
	session.tick_count = 3600
	session.time = 360.0
	session.day = 3
	game._refresh()
	for frame in 3:
		await process_frame
	check(game.hud.event_label.text.contains("Feira da cidade") and game.hud.event_label.text.contains("150%"), "active event visible")
	check(session.tick_count == 3600, "pause freezes event calendar")
	await click(root, game.view.actor_screen_position(actor) + game.view.global_position)
	check(game.selected_actor == actor.id and game.hud.inspector.text.contains("Perfil: Lazer"), "profile visible through actor picking")
	actor.target_room = session.hotel.room_at(13, 1).id
	actor.travel_to(13.5, 1, &"service_queue")
	var inspection_before := SessionSnapshot.capture(session)
	game._refresh()
	check(game.hud.inspector.text.contains("Objetivo: Usar serviço • Café Brisa #"), "walking guest names actual destination service")
	check(SessionSnapshot.capture(session) == inspection_before, "inspection does not mutate simulation")
	actor.state = &"lift_queue"
	actor.waiting = 12.5
	game._refresh()
	check(game.hud.inspector.text.contains("Espera nesta fila de elevador: 12.5s"), "queue duration identifies the current stage")
	actor.state = &"riding"
	game._refresh()
	check(not game.hud.inspector.text.contains("Espera nesta fila"), "boarding hides stale queue duration")
	actor.travel_to(-0.8, 0, &"exit")
	game._refresh()
	check(game.hud.inspector.text.contains("Sair do hotel") and not game.hud.inspector.text.contains("Café Brisa #"), "exit ignores stale service target")
	actor.state = &"deciding"
	game._refresh()
	check(game.hud.inspector.text.contains("Escolher a próxima atividade"), "decision has no stale destination")
	actor.travel_to(13.5, 1, &"service_queue")
	game._refresh()
	var scroll: ScrollContainer = game.hud.inspector.get_parent().get_parent()
	scroll.ensure_control_visible(game.hud.inspector)
	for frame in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.runtime/m5-content.png")
	for button: Node in game.hud.find_children("*", "Button", true, false):
		if button.text == "Salvar":
			await click(root, button.get_global_rect().get_center())
	var saved := SessionSnapshot.capture(session)
	game._replace_session(HotelSession.new())
	game.session.speed = 0
	for button: Node in game.hud.find_children("*", "Button", true, false):
		if button.text == "Carregar":
			await click(root, button.get_global_rect().get_center())
	check(preload("res://tests/snapshot_comparison.gd").difference(saved, SessionSnapshot.capture(game.session), "ui-content").is_empty(), "content and active event roundtrip through UI")
	check(game.hud.event_label.text.contains("150%") and not game.hud.build_buttons[&"cafe"].disabled, "restored event and unlock displayed")
	await portraits(game)
	print(JSON.stringify({"suite": "ui_content", "failures": failures}))
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)

func portraits(game: Node) -> void:
	var session := SimulationRunner.make_hotel(951, "standard", 250000)
	session.speed = 0
	game._replace_session(session)
	var people: Array[ActorState] = []
	for profile: StringName in [&"balanced", &"business", &"leisure"]:
		var actor := session.spawn_guest()
		actor.archetype_id = profile
		actor.state = &"walking"
		people.append(actor)
	var roles: Array[StringName] = []
	for actor: ActorState in session.actors.values():
		if actor.role != &"guest" and not roles.has(actor.role):
			people.append(actor)
			roles.append(actor.role)
	check(people.size() == 5 and HotelArt.PORTRAITS.size() == 5, "five portrait identities")
	for index in people.size():
		people[index].x = 3 + index * 2
		people[index].floor_index = 0
	var before := SessionSnapshot.capture(session)
	var original_size := root.size
	var original_large: bool = game.large_text
	for resolution: Vector2i in [Vector2i(1024, 640), Vector2i(1280, 800), Vector2i(1600, 900)]:
		root.size = resolution
		for large: bool in [false, true]:
			game.view.pan = Vector2.ZERO
			game.view.zoom_factor = 0.75
			if game.large_text != large:
				game._toggle_text_size()
			for frame in 4:
				await process_frame
			for actor: ActorState in people:
				game.hud.sidebar_scroll.scroll_vertical = 0
				await click(root, game.view.actor_screen_position(actor) + game.view.global_position)
				for frame in 3:
					await process_frame
				check(game.selected_actor == actor.id, "real click selects portrait subject")
				check(game.hud.actor_card.visible and game.hud.actor_portrait.texture == HotelArt.portrait(actor), "portrait follows archetype or role")
				var scroll_rect: Rect2 = game.hud.sidebar_scroll.get_global_rect()
				check(scroll_rect.encloses(game.hud.actor_card.get_global_rect()), "auto scroll reveals entire portrait card")
				check(root.get_visible_rect().encloses(game.hud.actor_card.get_global_rect()), "portrait card fits window and text size")
				check(game.hud.actor_portrait.get_size().is_equal_approx(Vector2(96, 96)), "portrait has fixed UI bounds independent of PNG size")
				check(not game.hud.actor_portrait_caption.text.is_empty(), "portrait has a textual profile or role")
				check(game.hud.actor_portrait.mouse_filter == Control.MOUSE_FILTER_IGNORE and game.hud.actor_portrait.focus_mode == Control.FOCUS_NONE, "decorative portrait cannot steal input or focus")
				if resolution == Vector2i(1280, 800) and not large:
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://.runtime/m7-portrait-%s.png" % HotelArt.character_id(actor))
				check(SessionSnapshot.capture(session) == before, "portrait selection and layout preserve session")
			game._inspect_room(session.hotel.rooms[0].id)
			check(not game.hud.actor_card.visible and game.hud.actor_portrait.texture == null, "room selection removes stale portrait")
	root.size = original_size
	if game.large_text != original_large:
		game._toggle_text_size()
	var actor: ActorState = people[0]
	game._select_actor(actor.id)
	var portrait: Texture2D = game.hud.actor_portrait.texture
	var previous_state := actor.state
	actor.state = &"service_queue"
	actor.happiness = 1
	game._refresh()
	check(game.hud.actor_portrait.texture == portrait and game.hud.inspector.text.contains("Satisfação: 1"), "portrait identifies character independently of state and happiness")
	actor.state = previous_state
	actor.happiness = before.actors.filter(func(item: Dictionary) -> bool: return item.id == actor.id)[0].happiness
	var path := "user://portrait-ui.json"
	check(SaveStore.save_session(session, path).is_empty(), "portrait fixture save")
	game.save_path = path
	game._replace_session(HotelSession.new())
	check(not game.hud.actor_card.visible and game.hud.actor_portrait.texture == null, "new session clears portrait")
	await click(root, game.hud.session_buttons["Carregar"].get_global_rect().get_center())
	check(not game.hud.actor_card.visible, "loading starts without stale selection")
	var restored: ActorState = game.session.actors.get(actor.id)
	check(restored != null, "portrait fixture actor restored")
	if restored != null:
		game._select_actor(restored.id)
		check(game.hud.actor_portrait.texture == portrait, "restored archetype resolves same portrait")
		game.session.actors.erase(restored.id)
		game._refresh()
		check(not game.hud.actor_card.visible and game.hud.actor_portrait.texture == null, "departed actor leaves no stale portrait")

func press_build(button: Button) -> void:
	var scroll: ScrollContainer = button.get_parent().get_parent()
	scroll.ensure_control_visible(button)
	for frame in 3:
		await process_frame
	await click(root, button.get_global_rect().get_center())
