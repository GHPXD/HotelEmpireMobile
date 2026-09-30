extends RefCounted
## Explicit --release-smoke diagnostic; uses only dedicated test save/report names.

var failures: int = 0

func run(game: Node) -> void:
	var tree: SceneTree = game.get_tree()
	var root: Window = tree.root
	check(not OS.has_feature("editor"), "running export template")
	check(not ResourceLoader.exists("res://tests/ui_art.gd"), "tests excluded from package")
	check(not FileAccess.file_exists("res://docs/PRODUCT_VISION.md"), "documentation excluded")
	var service_art_verified := 0
	var build_icons_verified := 0
	var staff_icons_verified := 0
	var actor_presentation_verified := 0
	var visual_session := HotelSession.new(418)
	var visual_view := HotelView.new()
	visual_view.session = visual_session
	visual_view.hotel = visual_session.hotel
	var neighbors: Array[ActorState] = []
	for index in 2:
		var actor := visual_session.spawn_guest()
		actor.archetype_id = &"balanced"
		actor.state = &"checkin"
		actor.x = 3.0 + index * 0.08 - (actor.id % 5) * 0.13
		neighbors.append(actor)
	for zoom: float in [0.35, 0.9, 1.8]:
		visual_view.zoom_factor = zoom
		for actor: ActorState in neighbors:
			var sprite := visual_view.actor_sprite_rect(actor)
			var badge := visual_view.actor_wait_badge_rect(actor)
			check(badge.end.y <= sprite.position.y - 3.9 * zoom, "exported wait status clears sprite")
			check(visual_view.actor_at_screen_position(visual_view.actor_screen_position(actor)) == actor.id, "exported near queue actor selectable")
		var face := visual_view.actor_sprite_rect(neighbors[0]).get_center()
		face.y -= visual_view.actor_sprite_rect(neighbors[0]).size.y * 0.3
		check(visual_view.actor_at_screen_position(face) == neighbors[0].id, "exported face picking")
		actor_presentation_verified += 1
	visual_session.actors.clear()
	visual_session.hotel.add_floor()
	var queue_room := visual_session.hotel.build(HotelCatalog.room(&"reception"), 3, 0)
	visual_session.hotel.build(HotelCatalog.room(&"elevator"), 15, 0)
	visual_session.transport.sync(visual_session.hotel)
	var queue_lift: ElevatorState = visual_session.transport.lifts[0]
	for index in 18:
		var actor := visual_session.spawn_guest()
		actor.waiting = 1.0
		if index < 12:
			actor.state = &"checkin"
			actor.target_room = queue_room.id
			actor.x = queue_room.center()
			queue_room.queue.members.push_front(actor.id)
		else:
			actor.state = &"lift_queue"
			actor.floor_index = 1
			actor.elevator_id = queue_lift.room_id
			actor.x = queue_lift.column
			queue_lift.queue.join(actor.id)
	var queue_before := SessionSnapshot.capture(visual_session)
	var projection := HotelQueueProjection.build(visual_session, HotelView.CELL, HotelView.FLOOR_HEIGHT)
	check(projection.groups.size() == 2 and projection.positions.size() == 18, "exported registered queue groups")
	var queue_projection_verified := 0
	for zoom: float in [0.35, 0.9, 1.8]:
		visual_view.zoom_factor = zoom
		for actor: ActorState in visual_session.actors.values():
			check(visual_view.actor_at_screen_position(visual_view.actor_screen_position(actor)) == actor.id, "exported registered queue member selectable")
			check(not visual_view.actor_wait_badge_rect(actor).has_area(), "exported shared queue status")
		queue_projection_verified += 1
	check(equivalent(queue_before, SessionSnapshot.capture(visual_session)), "exported queue presentation is read-only")
	var travel_art_verified := 0
	visual_session.actors.clear()
	for profile: StringName in [&"balanced", &"business", &"leisure"]:
		var actor := visual_session.spawn_guest()
		actor.archetype_id = profile
		actor.x = 6
		actor.destination_state = &"exit"
		var texture: Texture2D
		for state: StringName in [&"arriving", &"walking", &"lift_queue", &"riding", &"exit"]:
			actor.state = state
			texture = HotelArt.character(actor)
			check(HotelArt.animation_id(actor) == StringName("%s-travel" % profile), "exported entry/exit luggage context")
			check(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "exported travel alpha")
		actor.state = &"walking"
		for direction: int in [-1, 1]:
			actor.target_x = actor.x + direction
			for zoom: float in [0.35, 0.9, 1.8]:
				visual_view.zoom_factor = zoom
				for phase in 4:
					visual_session.tick_count = phase
					var region := HotelArt.character_region(actor, phase)
					var anchor := HotelArt.character_anchor(actor, phase)
					if direction < 0:
						anchor.x = region.size.x - anchor.x
					var sprite := visual_view.actor_sprite_rect(actor)
					check((sprite.position + anchor * HotelArt.character_scale(actor) * zoom).distance_to(visual_view.actor_screen_position(actor) + Vector2(0, 17 * zoom)) < 0.001, "exported travel shoe anchor")
					check(Rect2(Vector2.ZERO, texture.get_size()).encloses(region), "exported travel source bounds")
					check(visual_view.actor_at_screen_position(sprite.get_center()) == actor.id, "exported travel selection")
		travel_art_verified += 1
		visual_session.actors.clear()
	visual_view.free()
	var housekeeping_art_verified := 0
	for level in range(1, 4):
		var room := RoomState.new()
		room.definition_id = &"bedroom"
		room.level = level
		room.dirty = true
		var texture := HotelArt.room_state(room)
		check(texture == HotelArt.DIRTY_BEDROOMS[level - 1] and texture.get_width() > 0, "exported dirty bedroom painting")
		check(texture.get_size() == HotelArt.room(&"bedroom", level).get_size(), "exported dirty room dimensions")
		room.dirty = false
		check(HotelArt.room_state(room) == HotelArt.room(&"bedroom", level), "exported clean room painting restored")
		housekeeping_art_verified += 1
	var portrait_art_verified := 0
	var portrait_session := HotelSession.new(619)
	portrait_session.speed = 0
	for identity: StringName in HotelArt.PORTRAITS:
		var actor := portrait_session.spawn_guest()
		if identity in HotelArt.STAFF_IDLE_ROLES:
			actor.role = identity
			actor.state = &"idle"
		else:
			actor.archetype_id = identity
			actor.state = &"walking"
		actor.x = 1 + portrait_session.actors.size() * 2
	if OS.get_cmdline_user_args().has("--smoke-large-text") and not game.large_text:
		game._toggle_text_size()
	game._replace_session(portrait_session)
	for frame in 4:
		await tree.process_frame
	var portrait_before := SessionSnapshot.capture(portrait_session)
	for actor: ActorState in portrait_session.actors.values():
		await click(tree, game.view.actor_screen_position(actor) + game.view.global_position)
		for frame in 3:
			await tree.process_frame
		var texture := HotelArt.portrait(actor)
		check(game.selected_actor == actor.id and game.hud.actor_card.visible, "exported actor portrait selected by real click")
		check(game.hud.actor_portrait.texture == texture and texture.get_image().detect_alpha() != Image.ALPHA_NONE, "exported dedicated portrait with alpha")
		check(game.hud.sidebar_scroll.get_global_rect().encloses(game.hud.actor_card.get_global_rect()), "exported portrait auto-scroll and bounds")
		portrait_art_verified += 1
	check(equivalent(portrait_before, SessionSnapshot.capture(portrait_session)), "exported portrait selection preserves session")
	game._replace_session(HotelSession.new(620))
	check(not game.hud.actor_card.visible and game.hud.actor_portrait.texture == null, "exported new session clears portrait")
	var staff_session := HotelSession.new(830)
	staff_session.speed = 0
	game._replace_session(staff_session)
	for frame in 4:
		await tree.process_frame
	for definition: EmployeeDefinition in HotelSession.EMPLOYEES:
		var button: Button = game.hud.hire_buttons[definition.id]
		check(button.icon == HotelArt.staff_icon(definition.id) and button.icon.get_image().detect_alpha() != Image.ALPHA_NONE, "exported dedicated staff icon")
		game.hud.sidebar_scroll.ensure_control_visible(button)
		for frame in 3:
			await tree.process_frame
		check(root.get_visible_rect().encloses(button.get_global_rect()), "exported hiring button bounds")
		var cash := staff_session.economy.cash
		await click(tree, button.get_global_rect().get_center())
		var employee: ActorState = staff_session.actors.get(staff_session.next_actor_id - 1)
		check(employee != null and employee.role == definition.id and staff_session.economy.cash == cash - definition.hire_cost, "exported icon hires correct role and price")
		game.staff_panel.open_for(staff_session)
		var panel: StaffPanel = game.staff_panel
		if employee != null:
			for index in panel.employee_choice.item_count:
				if panel.employee_choice.get_item_id(index) == employee.id:
					panel.employee_choice.select(index)
					panel.employee_choice.item_selected.emit(index)
		for frame in 3:
			await tree.process_frame
		check(panel.role_icon.texture == button.icon and panel.role_icon.visible, "exported selected staff role icon")
		check(panel.role_icon.mouse_filter == Control.MOUSE_FILTER_IGNORE and panel.role_icon.focus_mode == Control.FOCUS_NONE, "exported staff decoration ignores input")
		panel.hide()
		staff_icons_verified += 1
	game.staff_panel.open_for(HotelSession.new(831))
	check(not game.staff_panel.role_icon.visible and game.staff_panel.role_icon.texture == null, "exported empty staff list clears icon")
	var action_icons_verified := await verify_action_icons(game)
	game.staff_panel.hide()
	var management_icons_verified := await verify_management_icons(game)
	var session_icons_verified := await verify_session_icons(game)
	var staff_idle_art_verified := 0
	for role: StringName in HotelArt.STAFF_IDLE_ROLES:
		var employee := ActorState.new()
		employee.role = role
		for state: StringName in HotelArt.STAFF_IDLE_STATES:
			employee.state = state
			var texture := HotelArt.character(employee)
			check(HotelArt.animation_id(employee) == StringName("%s-idle" % role), "exported staff idle selection")
			check(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "exported staff idle alpha")
			check(HotelArt.character_regions(employee).size() == 4, "exported staff idle poses")
			for tick: int in [0, 16, 32, 48]:
				check(Rect2(Vector2.ZERO, texture.get_size()).encloses(HotelArt.character_region(employee, tick)), "exported staff idle region contained")
			staff_idle_art_verified += 1
	for profile: StringName in [&"balanced", &"business", &"leisure"]:
		var visual_guest := ActorState.new()
		visual_guest.role = &"guest"
		visual_guest.archetype_id = profile
		visual_guest.state = &"using"
		for service: StringName in [&"cafe", &"lounge", &"restaurant", &"bedroom"]:
			var texture := HotelArt.character(visual_guest, service)
			check(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "exported service sprite has alpha")
			check(HotelArt.character_regions(visual_guest, service).size() == 4, "exported service frame count")
			for tick: int in [0, 8, 12, 16, 24, 36]:
				check(Rect2(Vector2.ZERO, texture.get_size()).encloses(HotelArt.character_region(visual_guest, tick, service)), "exported service region contained")
			service_art_verified += 1
	var session := HotelSession.new(123)
	session.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
	session.hotel.build(HotelCatalog.room(&"restaurant"), 3, 0)
	session.hotel.build(HotelCatalog.room(&"elevator"), 6, 0)
	for level: int in [1, 2]:
		session.hotel.add_floor()
		for column: int in [0, 2, 4, 8]:
			session.hotel.build(HotelCatalog.room(&"bedroom"), column, level)
	for definition: EmployeeDefinition in HotelSession.EMPLOYEES:
		check(session.hire(definition).is_empty(), "hire from exported data")
	check(session.hotel.rooms.size() == 11, "build from exported data")
	session.opened = true
	for tick in 6000:
		session.tick(session.rules.tick)
	check(session.guests.bookings >= 10 and session.guests.meals_served >= 5 and session.employees.cleaned >= 5, "productive packaged game")
	check(session.economy.cash > 0, "solvent packaged game")
	check(session.guests.reviews.size() == GuestSystem.REVIEW_LIMIT, "packaged gameplay fills bounded review history")
	var lift_wait_recorded := false
	for review: Dictionary in session.guests.reviews:
		check(review.reception_seconds != null and review.reception_seconds > 0, "fresh packaged guest records actual reception time")
		if review.lift_queue_seconds > 0:
			lift_wait_recorded = true
	check(lift_wait_recorded, "packaged visits contain real lift queue time")
	var upgraded_levels: Dictionary = {}
	for index: int in [0, 1, 3]:
		var room: RoomState = session.hotel.rooms[index]
		check(session.upgrade_room(room.id).is_empty(), "purchase packaged visual upgrade")
		check(HotelArt.room(room.definition_id, room.level) == HotelArt.ROOM_UPGRADES[room.definition_id], "level 2 uses dedicated painting")
		check(session.upgrade_room(room.id).is_empty(), "purchase final room upgrade")
		check(HotelArt.room(room.definition_id, room.level) == HotelArt.ROOM_FINAL_UPGRADES[room.definition_id], "level 3 uses final painting")
		upgraded_levels[room.id] = room.level
	var lift_room: RoomState = session.hotel.rooms[2]
	check(session.upgrade_room(lift_room.id).is_empty(), "purchase upgraded cabin")
	check(HotelArt.cabin(lift_room.level) == HotelArt.CABIN_UPGRADE, "upgraded cabin painting selected")
	check(HotelArt.CABIN_UPGRADE.get_width() > 0, "upgraded cabin packaged")
	check(session.upgrade_room(lift_room.id).is_empty(), "purchase final cabin")
	check(HotelArt.cabin(lift_room.level) == HotelArt.CABIN_FINAL_UPGRADE, "final cabin painting selected")
	check(HotelArt.CABIN_FINAL_UPGRADE.get_width() > 0, "final cabin packaged")
	var path := "user://release-smoke-save.json"
	var priced_room: RoomState = session.hotel.rooms[3]
	check(session.set_room_tariff(priced_room.id, 125).is_empty(), "packaged tariff accepted")
	check(SaveStore.save_session(session, path).is_empty(), "save from executable")
	var restored := SaveStore.load_session(path)
	check(restored.error.is_empty(), "load from executable")
	if restored.error.is_empty():
		for tick in 120:
			session.tick(session.rules.tick)
			restored.session.tick(restored.session.rules.tick)
		check(equivalent(SessionSnapshot.capture(session), SessionSnapshot.capture(restored.session)), "continued save equivalent")
	for texture: Texture2D in HotelArt.CHARACTERS.values():
		check(texture.get_width() > 0, "character texture packaged")
	for texture: Texture2D in HotelArt.ROOMS.values():
		check(texture.get_width() > 0, "room texture packaged")
	for texture: Texture2D in HotelArt.ROOM_UPGRADES.values():
		check(texture.get_width() > 0, "upgrade texture packaged")
	for texture: Texture2D in HotelArt.ROOM_FINAL_UPGRADES.values():
		check(texture.get_width() > 0, "final upgrade texture packaged")
	for cue: AudioStream in HotelAudio.SOUNDS.values():
		check(cue.get_length() > 0.1, "sound packaged")
	session.speed = 0
	game._replace_session(session)
	game.save_path = path
	for frame in 4:
		await tree.process_frame
	var catalog_before := SessionSnapshot.capture(session)
	for definition: RoomDefinition in HotelCatalog.ROOMS:
		var button: Button = game.hud.build_buttons[definition.id]
		var texture := HotelArt.build_icon(definition.id)
		check(button.icon == texture and texture != HotelArt.room(definition.id), "exported dedicated construction icon")
		check(texture.get_width() == texture.get_height() and texture.get_image().detect_alpha() != Image.ALPHA_NONE, "exported square transparent construction icon")
		game.hud.sidebar_scroll.ensure_control_visible(button)
		for frame in 3:
			await tree.process_frame
		check(root.get_visible_rect().encloses(button.get_global_rect()), "exported catalog button bounds")
		await click(tree, button.get_global_rect().get_center())
		check(game.view.blueprint == definition, "exported construction icon activation")
		game._cancel()
		build_icons_verified += 1
	check(equivalent(catalog_before, SessionSnapshot.capture(session)), "exported icon activation preserves simulation")
	await click(tree, game.hud.session_buttons["Salvar"].get_global_rect().get_center())
	var expected := SessionSnapshot.capture(game.session)
	game._replace_session(HotelSession.new(777))
	game.session.speed = 0
	if OS.get_cmdline_user_args().has("--smoke-large-text") and not game.large_text:
		game._toggle_text_size()
		for frame in 3:
			await tree.process_frame
	for button: Control in [game.hud.open_button, game.hud.session_buttons["Salvar"], game.hud.session_buttons["Carregar"], game.hud.operations_button, game.hud.session_buttons["Avaliações"]]:
		check(root.get_visible_rect().encloses(button.get_global_rect()), "essential toolbar control fits viewport")
	await click(tree, game.hud.session_buttons["Carregar"].get_global_rect().get_center())
	check(equivalent(expected, SessionSnapshot.capture(game.session)), "toolbar restores packaged session")
	game._inspect_room(priced_room.id)
	check(game.session.hotel.by_id(priced_room.id).price_percent == 125, "packaged tariff restored")
	check(game.hud.tariff_choice.visible and game.hud.tariff_choice.selected == 2, "packaged tariff control reflects save")
	check(game.hud.tariff_effect.visible and game.hud.tariff_effect.text.contains("125%: -7.5 a -5.0"), "packaged lodging value preview")
	for frame in 3:
		await tree.process_frame
	game.hud.sidebar_scroll.ensure_control_visible(game.hud.tariff_choice)
	for frame in 3:
		await tree.process_frame
	check(root.get_visible_rect().encloses(game.hud.tariff_choice.get_global_rect()), "tariff control fits viewport")
	var restored_lift_room: RoomState = game.session.hotel.by_id(lift_room.id)
	check(restored_lift_room.level == 3, "saved elevator upgrade restored")
	check(HotelArt.cabin(restored_lift_room.level) == HotelArt.CABIN_FINAL_UPGRADE, "restored elevator uses final cabin")
	for id: int in upgraded_levels:
		var room: RoomState = game.session.hotel.by_id(id)
		check(room.level == upgraded_levels[id], "saved visual upgrade level restored")
		var painting: Texture2D = HotelArt.ROOM_FINAL_UPGRADES[room.definition_id] if room.level == 3 else HotelArt.ROOM_UPGRADES[room.definition_id]
		check(HotelArt.room(room.definition_id, room.level) == painting, "restored room uses upgraded painting")
	game.session.speed = 0
	var reception: RoomState = game.session.hotel.rooms[0]
	game._inspect_room(reception.id)
	var diagnosis := CheckinDiagnostics.reason(game.session, reception)
	check(game.hud.inspector.text.contains(UILabels.checkin(diagnosis)), "packaged inspector shows live check-in diagnosis")
	check(HotelAnalytics.rooms(game.session, &"reception")[0].checkin_reason == diagnosis, "packaged operations shares diagnosis")
	check(equivalent(expected, SessionSnapshot.capture(game.session)), "packaged diagnosis is read-only")
	var operational_lift: ElevatorState = game.session.transport.lift_by_id(lift_room.id)
	var elevator_metrics := HotelAnalytics.elevator(game.session, operational_lift)
	check(elevator_metrics.boarded > 0 and elevator_metrics.delivered > 0, "real packaged transport history exists")
	game._inspect_room(lift_room.id)
	check(game.hud.inspector.text.contains(UILabels.elevator(elevator_metrics)), "inspector shares elevator metrics")
	check(not game.hud.inspector.text.contains("Utilização:"), "inspector avoids hotel-age utilization denominator")
	game._show_operations()
	for index in game.operations_panel.rows.size():
		if game.operations_panel.rows[index].id == lift_room.id:
			game.operations_panel.room_list.select(index)
	game.operations_panel.refresh(game.session)
	var groups := HotelAnalytics.satisfaction_groups(game.session)
	check(game.operations_panel.summary_label.text.contains("Presentes com check-in: %d" % groups.checked_in.count), "packaged admitted cohort")
	check(game.operations_panel.summary_label.text.contains("Presentes sem check-in: %d" % groups.not_checked_in.count), "packaged arrival cohort")
	check(game.operations_panel.selected_details.text.contains(UILabels.elevator(elevator_metrics)), "operations shows actual elevator history")
	for frame in 3:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	game.operations_panel.get_texture().get_image().save_png("user://release-elevator-metrics.png")
	await close_popup(tree, game.operations_panel)
	check(equivalent(expected, SessionSnapshot.capture(game.session)), "elevator metrics preserve session")
	await click(tree, game.hud.session_buttons["Avaliações"].get_global_rect().get_center())
	check(game.reviews_panel.visible, "packaged reviews open after save restore")
	check(game.reviews_panel.details.text.contains(GuestReviewsPanel.describe(game.session.guests.reviews.back(), game.session.rules.day_seconds)), "packaged review matches saved visitor facts")
	check(root.get_visible_rect().encloses(Rect2(Vector2(game.reviews_panel.position), Vector2(game.reviews_panel.size))), "packaged reviews fit viewport")
	game.session.speed = 1
	var reading := SessionSnapshot.capture(game.session)
	game._process(1.0)
	check(equivalent(reading, SessionSnapshot.capture(game.session)), "packaged reviews pause running simulation")
	game.session.speed = 0
	await close_popup(tree, game.reviews_panel)
	check(not game.reviews_panel.visible and game.hud.session_buttons["Avaliações"].has_focus(), "packaged reviews close and restore focus")
	await click(tree, game.hud.help_button.get_global_rect().get_center())
	check(game.help_panel.visible, "packaged help opens")
	game._process(1.0)
	check(equivalent(expected, SessionSnapshot.capture(game.session)), "packaged help preserves session")
	await close_popup(tree, game.help_panel)
	check(not game.help_panel.visible, "packaged help closes with Escape")
	game._show_finances()
	game.get_tree().root.close_requested.emit()
	check(game.exit_dialog.visible, "packaged close asks before exit")
	check(not game.finances_dialog.visible, "packaged exit replaces management popup")
	await close_popup(tree, game.exit_dialog)
	check(not game.exit_dialog.visible, "packaged exit cancellation resumes game")
	check(equivalent(expected, SessionSnapshot.capture(game.session)), "exit cancellation preserves packaged session")
	var recovery_path := "user://release-smoke-corrupt.json"
	check(SaveStore.save_session(game.session, recovery_path + ".bak").is_empty(), "packaged recovery backup fixture")
	var broken := FileAccess.open(recovery_path, FileAccess.WRITE)
	broken.store_string("{broken")
	broken.close()
	game.save_path = recovery_path
	await click(tree, game.hud.session_buttons["Carregar"].get_global_rect().get_center())
	check(game.recovery_dialog.visible, "packaged recovery offered")
	await close_popup(tree, game.recovery_dialog)
	check(equivalent(expected, SessionSnapshot.capture(game.session)), "packaged recovery cancel preserves hotel")
	await click(tree, game.hud.session_buttons["Carregar"].get_global_rect().get_center())
	game.recovery_dialog.get_ok_button().grab_focus()
	await popup_key(tree, game.recovery_dialog, KEY_ENTER)
	check(not game.recovery_dialog.visible, "packaged recovery confirmed")
	check(equivalent(expected, SessionSnapshot.capture(game.session)), "packaged backup restored")
	check(FileAccess.get_file_as_string(recovery_path) == "{broken", "packaged recovery preserves original file")
	game.save_path = path
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("user://release-smoke.png") == OK, "capture packaged game")
	var report: Dictionary = {"suite": "release_smoke", "failures": failures, "bookings": session.guests.bookings, "meals": session.guests.meals_served, "cleaned": session.employees.cleaned, "cash": session.economy.cash, "ticks": session.tick_count, "user_data": OS.get_user_data_dir(), "executable": OS.get_executable_path()}
	report["service_art_verified"] = service_art_verified
	report["staff_idle_art_verified"] = staff_idle_art_verified
	report["actor_presentation_verified"] = actor_presentation_verified
	report["queue_projection_verified"] = queue_projection_verified
	report["housekeeping_art_verified"] = housekeeping_art_verified
	report["portrait_art_verified"] = portrait_art_verified
	report["travel_art_verified"] = travel_art_verified
	report["build_icons_verified"] = build_icons_verified
	report["staff_icons_verified"] = staff_icons_verified
	report["action_icons_verified"] = action_icons_verified
	report["management_icons_verified"] = management_icons_verified
	report["session_icons_verified"] = session_icons_verified
	report["presentation"] = {"window": [root.size.x, root.size.y], "viewport": [root.get_visible_rect().size.x, root.get_visible_rect().size.y], "large_text": game.large_text, "display": DisplayServer.get_name(), "renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(), "os": OS.get_name(), "os_version": OS.get_version()}
	var file := FileAccess.open("user://release-smoke-report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print(JSON.stringify(report))
	tree.quit(1 if failures else 0)

func verify_action_icons(game: Node) -> int:
	var tree: SceneTree = game.get_tree()
	var verified := 0
	for action: StringName in [&"add_floor", &"upgrade", &"demolish"]:
		var session := HotelSession.new(844)
		session.speed = 0
		var room := session.hotel.build(HotelCatalog.room(&"reception"), 0, 0)
		game._replace_session(session)
		game._inspect_room(room.id)
		for frame in 3:
			await tree.process_frame
		var button: Button = game.hud.action_buttons[action]
		var texture := HotelArt.action_icon(action)
		check(button.icon == texture and texture.get_width() == 256 and texture.get_image().detect_alpha() != Image.ALPHA_NONE, "exported budgeted action icon")
		game.hud.sidebar_scroll.ensure_control_visible(button)
		for frame in 3:
			await tree.process_frame
		check(game.hud.sidebar_scroll.get_global_rect().encloses(button.get_global_rect()) and tree.root.get_visible_rect().encloses(button.get_global_rect()), "exported action button bounds")
		var cash := session.economy.cash
		var cost := room.next_upgrade().cost
		await click(tree, button.get_global_rect().get_center())
		match action:
			&"add_floor":
				check(session.hotel.floors == 2 and session.economy.cash == cash - 750, "exported floor icon builds at correct cost")
			&"upgrade":
				check(room.level == 2 and session.economy.cash == cash - cost, "exported upgrade icon improves selected room")
			&"demolish":
				check(session.hotel.by_id(room.id) == null and session.economy.cash == cash and game.selection == -1, "exported demolition icon removes without refund")
		check(session.speed == 0 and session.tick_count == 0, "exported action input preserves pause")
		verified += 1
	return verified

func verify_management_icons(game: Node) -> int:
	var tree: SceneTree = game.get_tree()
	var session := SimulationRunner.make_hotel(848, "standard", 250000)
	session.speed = 0
	game._replace_session(session)
	for frame in 4:
		await tree.process_frame
	var before := SessionSnapshot.capture(session)
	var panels: Dictionary = {&"finances": game.finances_dialog, &"operations": game.operations_panel, &"reviews": game.reviews_panel}
	var verified := 0
	for id: StringName in panels:
		var button: Button = game.hud.management_buttons[id]
		var panel: Window = panels[id]
		var texture := HotelArt.management_icon(id)
		check(button.icon == texture and texture.get_width() == 256 and texture.get_image().detect_alpha() != Image.ALPHA_NONE, "exported dedicated management icon")
		check(not button.expand_icon and button.get_theme_constant("icon_max_width") == 28, "exported management icon contributes to minimum width")
		check(tree.root.get_visible_rect().encloses(button.get_global_rect()) and button.size.x >= button.get_combined_minimum_size().x, "exported decorated management button bounds")
		await click(tree, button.get_global_rect().get_center())
		check(panel.visible, "exported icon opens correct management panel")
		check(equivalent(before, SessionSnapshot.capture(session)), "exported management icon navigation preserves session")
		await close_popup(tree, panel)
		check(not panel.visible and button.has_focus(), "exported Escape returns focus to management icon button")
		verified += 1
	return verified

func verify_session_icons(game: Node) -> int:
	var tree: SceneTree = game.get_tree()
	var session := SimulationRunner.make_hotel(849, "standard", 250000)
	session.speed = 0
	game._replace_session(session)
	var before := SessionSnapshot.capture(session)
	var original_save_path: String = game.save_path
	game.save_path = "user://release-session-icons.json"
	for frame in 4:
		await tree.process_frame
	for id: StringName in game.hud.session_icon_buttons:
		var button: Button = game.hud.session_icon_buttons[id]
		var texture := HotelArt.session_icon(id)
		check(button.icon == texture and texture.get_width() == 256 and texture.get_image().detect_alpha() != Image.ALPHA_NONE, "exported dedicated session icon")
		check(not button.expand_icon and button.get_theme_constant("icon_max_width") == 28, "exported session icon contributes to minimum width")
		check(tree.root.get_visible_rect().encloses(button.get_global_rect()) and button.size.x >= button.get_combined_minimum_size().x, "exported decorated session button bounds")
	await click(tree, game.hud.session_icon_buttons[&"save"].get_global_rect().get_center())
	var saved_bytes := FileAccess.get_file_as_bytes(game.save_path)
	check(not saved_bytes.is_empty(), "exported painted save writes file")
	check(equivalent(before, SessionSnapshot.capture(game.session)), "exported save preserves paused state")
	game._replace_session(HotelSession.new())
	for frame in 3:
		await tree.process_frame
	await click(tree, game.hud.session_icon_buttons[&"load"].get_global_rect().get_center())
	check(equivalent(before, SessionSnapshot.capture(game.session)), "exported painted load restores entire hotel")
	var opener: Button = game.hud.session_icon_buttons[&"new"]
	await click(tree, opener.get_global_rect().get_center())
	check(game.new_dialog.visible, "exported painted new opens confirmation")
	await close_popup(tree, game.new_dialog)
	check(not game.new_dialog.visible and opener.has_focus(), "exported cancel returns decorated new opener focus")
	check(equivalent(before, SessionSnapshot.capture(game.session)), "exported cancel preserves hotel")
	await click(tree, opener.get_global_rect().get_center())
	game.new_dialog.get_ok_button().grab_focus()
	await popup_key(tree, game.new_dialog, KEY_ENTER)
	check(game.hotel.rooms.is_empty() and game.hotel.floors == 1 and game.session.actors.is_empty(), "exported confirmed new resets hotel")
	check(saved_bytes == FileAccess.get_file_as_bytes(game.save_path), "exported confirmed new preserves saved bytes")
	await click(tree, game.hud.session_icon_buttons[&"load"].get_global_rect().get_center())
	check(equivalent(before, SessionSnapshot.capture(game.session)), "exported painted load recovers hotel after new confirmation")
	game.save_path = original_save_path
	return 3

func close_popup(tree: SceneTree, window: Window) -> void:
	await popup_key(tree, window, KEY_ESCAPE)

func popup_key(tree: SceneTree, window: Window, code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		event.window_id = window.get_window_id()
		Input.parse_input_event(event)
		await tree.process_frame

func click(tree: SceneTree, point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	tree.root.push_input(motion, true)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = pressed
		tree.root.push_input(event, true)
		await tree.process_frame

func equivalent(a: Variant, b: Variant) -> bool:
	if (a is float or a is int) and (b is float or b is int):
		return absf(float(a) - float(b)) < 0.00000001
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for key: Variant in a:
			if not b.has(key) or not equivalent(a[key], b[key]):
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for index in a.size():
			if not equivalent(a[index], b[index]):
				return false
		return true
	return a == b

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
