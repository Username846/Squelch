extends Node
## Renders a screenshot of every scene (needs a display; use xvfb-run).
## Run: godot --path . res://tests/shots.tscn -- <out_dir>

var out := "user://shots"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func tap(code: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.pressed = true
	Input.parse_input_event(ev)
	await frames(2)
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)
	await frames(12)


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _run() -> void:
	for l in Game.LEVELS:
		Game.data["done"][l["id"]] = true
	for path: String in ["res://scenes/board.gd", "res://scenes/intro.gd"]:
		Game.goto(path)
		await frames(40)
		await shot(path.get_file().get_basename())
	for i in Game.LEVELS.size():
		Game.goto_level(i)
		await frames(30)
		await shot("%02d_intro" % (i + 1))
		for k in 14:
			await tap(KEY_SPACE)
		for k in 90:
			await frames(1)
		await shot("%02d_play" % (i + 1))
	Game.goto("res://scenes/finale.gd")
	for k in 40:
		await tap(KEY_SPACE)
		if k % 6 == 0:
			await shot("finale_%02d" % k)
	Game.reset_save()
	get_tree().quit()
