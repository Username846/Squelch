extends Node
## Headless smoke test: visits every scene, mashes inputs, forces win/lose/egg paths.
## Run: godot --headless --path . --fixed-fps 60 res://tests/smoke.tscn

const SCENES := ["res://scenes/title.gd", "res://scenes/intro.gd", "res://scenes/board.gd",
	"res://scenes/finale.gd", "res://scenes/credits.gd"]


func _ready() -> void:
	_run.call_deferred()


func key(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)


func click(p: Vector2) -> void:
	for down in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = p
		ev.global_position = p
		ev.pressed = down
		Input.parse_input_event(ev)
		await get_tree().process_frame


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func tap(code: Key) -> void:
	key(code, true)
	await frames(2)
	key(code, false)
	await frames(2)


func _run() -> void:
	Game.reset_save()
	for s: String in SCENES:
		print("SMOKE scene ", s)
		Game.goto(s)
		await frames(30)
		for i in 40:
			await tap(KEY_SPACE)
		await frames(30)
	for i in Game.LEVELS.size():
		var lv: Dictionary = Game.LEVELS[i]
		print("SMOKE level ", lv["id"])
		for mode in ["play", "win", "lose"]:
			Game.goto(lv["path"])
			await frames(10)
			# get through the intro
			for k in 14:
				await tap(KEY_SPACE)
				await frames(10)
			await frames(20)
			var level: LevelBase = Game.current_scene
			print("  state after intro: ", level.state)
			if mode == "play":
				for k in 200:
					var codes := [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_SPACE, KEY_X, KEY_1, KEY_3]
					var c: Key = codes[k % codes.size()]
					key(c, true)
					await frames(3)
					key(c, false)
					if k % 10 == 0:
						await click(Vector2(randf() * 1280, randf() * 720))
				# hit every egg spot we know about by brute clicking a grid
				for gx in range(40, 1280, 60):
					for gy in range(80, 720, 60):
						await click(Vector2(gx, gy))
				for k in 30:
					await tap(KEY_SPACE)
				print("  state after play: ", level.state if is_instance_valid(level) else "freed")
			elif mode == "win":
				level.state = "play"
				level.found_egg()
				level.win()
				for k in 12:
					await frames(30)
					await tap(KEY_SPACE)
			else:
				level.state = "play"
				level.lose("test")
				await frames(120)
	print("SMOKE eggs=", Game.egg_count(), " done=", Game.done_count(), " all=", Game.all_eggs())
	Game.goto("res://scenes/board.gd")
	await frames(30)
	Game.goto("res://scenes/finale.gd")
	for k in 60:
		await frames(20)
		await tap(KEY_SPACE)
	print("SMOKE finished")
	Game.reset_save()
	get_tree().quit()
