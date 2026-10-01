extends SceneTree
## Controlled UI texture budget; no gameplay throughput or minimum hardware claim.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var label := "full"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--label="):
			label = argument.trim_prefix("--label=").validate_filename()
	var game := MobileProfileSupport.create(root)
	current_scene = game
	game.audio.enabled = false
	var session := SimulationRunner.make_hotel(841, "standard", 100000)
	session.speed = 0
	var people: Array[ActorState] = []
	for profile: StringName in [&"balanced", &"business", &"leisure"]:
		var actor := session.spawn_guest()
		actor.archetype_id = profile
		actor.state = &"deciding"
		actor.x = 3 + people.size() * 3
		people.append(actor)
	for role: StringName in HotelArt.STAFF_IDLE_ROLES:
		for actor: ActorState in session.actors.values():
			if actor.role == role:
				people.append(actor)
				break
	MobileProfileSupport.activate(game, session)
	var before := SessionSnapshot.capture(session)
	var rows: Array[Dictionary] = []
	var errors: Array[String] = []
	for resolution: Vector2i in [Vector2i(360, 780), Vector2i(844, 390), Vector2i(1280, 800)]:
		root.size = resolution
		for large: bool in [false, true]:
			if UIPreferences.load_large_text() != large:
				game._toggle_text()
			for actor: ActorState in people:
				game.router.open_sheet(&"actor", actor.id)
				for frame in 6:
					await process_frame
				var portrait: TextureRect = game.shell.sheet_content.find_child("ActorPortrait", true, false)
				if portrait == null or not game.shell.sheet_scroll.get_global_rect().encloses(portrait.get_global_rect()):
					errors.append("Portrait bounds: %s/%s/%s" % [resolution, large, actor.role])
			for frame in 30:
				await process_frame
			rows.append({"requested_window": [resolution.x, resolution.y], "actual_window": [root.size.x, root.size.y], "viewport": [root.get_visible_rect().size.x, root.get_visible_rect().size.y], "large_text": large, "video_memory_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED), "engine_static_memory_bytes": OS.get_static_memory_usage()})
	if SessionSnapshot.capture(session) != before:
		errors.append("UI presentation mutated session")
	var groups: Dictionary = {}
	var rgba_mip_bytes := 0
	for group: String in ["portraits", "build_icons", "staff_icons"]:
		var textures: Dictionary = HotelArt.PORTRAITS if group == "portraits" else (HotelArt.BUILD_ICONS if group == "build_icons" else HotelArt.STAFF_ICONS)
		var entries: Array[Dictionary] = []
		for id: StringName in textures:
			var texture: Texture2D = textures[id]
			var width := texture.get_width()
			var height := texture.get_height()
			var mip_bytes := 0
			while width > 0 and height > 0:
				mip_bytes += width * height * 4
				if width == 1 and height == 1:
					break
				width = maxi(1, width / 2)
				height = maxi(1, height / 2)
			rgba_mip_bytes += mip_bytes
			entries.append({"id": id, "path": texture.resource_path, "width": texture.get_width(), "height": texture.get_height(), "rgba8_mip_chain_estimate_bytes": mip_bytes})
		groups[group] = entries
	var report := {"label": label, "engine": Engine.get_version_info().string, "cpu": OS.get_processor_name(), "gpu": RenderingServer.get_video_adapter_name(), "scope": "13 UI textures, paused main scene, 5 portrait identities, 6 mobile window/text cases; not simulation throughput or certified hardware", "rows": rows, "texture_groups": groups, "rgba8_ui_mip_chain_estimate_bytes": rgba_mip_bytes, "errors": errors}
	var file := FileAccess.open("user://mobile-m8-ui-textures-%s.json" % label, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print(JSON.stringify(report))
	game.queue_free()
	await process_frame
	quit(0 if errors.is_empty() else 1)
