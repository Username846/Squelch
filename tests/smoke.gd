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


## Injected events are in window coordinates; convert from the 1280x720 game space.
func to_window(p: Vector2) -> Vector2:
	return get_viewport().get_screen_transform() * p


func mouse(p: Vector2, down: bool) -> void:
	p = to_window(p)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = p
	ev.global_position = p
	ev.pressed = down
	Input.parse_input_event(ev)
	await frames(2)


func touch(p: Vector2, down: bool, index := 0) -> void:
	p = to_window(p)
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.position = p
	ev.pressed = down
	Input.parse_input_event(ev)
	await frames(2)


func drag(p: Vector2, index := 0) -> void:
	p = to_window(p)
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = p
	Input.parse_input_event(ev)
	await frames(2)


func expect(cond: bool, what: String, level: LevelBase) -> void:
	if not cond:
		push_error("SMOKE FAIL: %s in %s" % [what, level.level_id])


## A finger that lands elsewhere and slides onto a control must press it.
func _slide_checks(level: LevelBase) -> void:
	Game.touch_ui = true
	if level.uses_action_button() and level.action_active():
		await touch(Vector2(640, 300), true, 3)
		await drag(level.action_pos() + Vector2(-200, 0), 3)
		expect(not Input.is_action_pressed("fart"), "fart pressed before reaching the button", level)
		await drag(level.action_pos(), 3)
		expect(Input.is_action_pressed("fart"), "sliding onto the action button did not press it", level)
		await drag(Vector2(640, 300), 3)
		expect(not Input.is_action_pressed("fart"), "sliding off the action button did not release it", level)
		await touch(Vector2(640, 300), false, 3)
	if level.uses_dpad():
		var c := level.dpad_pos()
		await touch(Vector2(640, 300), true, 4)
		await drag(c + Vector2(90, 0), 4)
		expect(Input.is_action_pressed("right"), "sliding onto d-pad right did not press it", level)
		await drag(c + Vector2(0, -90), 4)
		expect(Input.is_action_pressed("up") and not Input.is_action_pressed("right"), "sliding right -> up on the d-pad", level)
		# second finger on the action button while the first holds the d-pad
		if level.uses_action_button() and level.action_active():
			await touch(level.action_pos(), true, 5)
			expect(Input.is_action_pressed("fart") and Input.is_action_pressed("up"), "d-pad + action at once", level)
			await touch(level.action_pos(), false, 5)
		await touch(c + Vector2(0, -90), false, 4)
		expect(not Input.is_action_pressed("up"), "lifting the finger did not release the d-pad", level)


## Mouse-only and touch-only play: the action button and hold-to-walk must work.
func _pointer_checks(level: LevelBase) -> void:
	if level.uses_action_button() and level.action_active():
		await mouse(level.action_pos(), true)
		if not Input.is_action_pressed("fart"):
			push_error("SMOKE FAIL: mouse on action button did not press fart in " + level.level_id)
		await mouse(level.action_pos(), false)
		await touch(level.action_pos(), true, 1)
		if not Input.is_action_pressed("fart"):
			push_error("SMOKE FAIL: touch on action button did not press fart in " + level.level_id)
		await touch(level.action_pos(), false, 1)
		if Input.is_action_pressed("fart"):
			push_error("SMOKE FAIL: fart stuck after release in " + level.level_id)
	if level.uses_pointer_move():
		var start := level.pp
		var target := Vector2(640, 400) if start.distance_to(Vector2(640, 400)) > 150 else Vector2(300, 600)
		await mouse(target, true)
		await frames(40)
		await mouse(target, false)
		var mid := level.pp
		await touch(start, true, 0)
		await frames(40)
		await touch(start, false, 0)
		print("  pointer walk: ", start, " -> ", mid, " -> ", level.pp)
		if mid.distance_to(start) < 20.0 or level.pp.distance_to(mid) < 20.0:
			push_error("SMOKE FAIL: hold-to-walk did not move Squelch in " + level.level_id)


func _run() -> void:
	print("SMOKE window ", DisplayServer.window_get_size(), " screen xf ", get_viewport().get_screen_transform())
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
			if not Game.current_scene is LevelBase:
				push_error("SMOKE FAIL: %s did not load" % lv["path"])
				get_tree().quit(1)
				return
			var level: LevelBase = Game.current_scene
			print("  state after intro: ", level.state)
			if mode == "play":
				await _pointer_checks(level)
				await _slide_checks(level)
				Game.touch_ui = false
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
