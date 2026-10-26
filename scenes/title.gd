extends Node2D
## Title screen. The first click also unlocks browser audio.

var t := 0.0
var puffs: Array = []
var leaving := false
var buildings: Array = []
var fs_btn: Button


func _ready() -> void:
	Game.play_music("title")
	var ui := CanvasLayer.new()
	add_child(ui)
	var mute := Button.new()
	mute.text = "Sound: off" if Game.muted else "Sound: on"
	mute.position = Vector2(20, 668)
	mute.focus_mode = Control.FOCUS_NONE
	mute.pressed.connect(func() -> void:
		Game.toggle_mute()
		mute.text = "Sound: off" if Game.muted else "Sound: on")
	ui.add_child(mute)
	if _fullscreen_supported():
		fs_btn = Button.new()
		fs_btn.position = Vector2(20, 20)
		fs_btn.custom_minimum_size = Vector2(170, 52)
		fs_btn.focus_mode = Control.FOCUS_NONE
		fs_btn.add_theme_font_size_override("font_size", 22)
		fs_btn.pressed.connect(_toggle_fullscreen)
		ui.add_child(fs_btn)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var x := 0.0
	while x < 1280:
		var w := rng.randf_range(60, 140)
		buildings.append([x, w, rng.randf_range(160, 380), rng.randi()])
		x += w + rng.randf_range(0, 10)


func _is_fullscreen() -> bool:
	var m := DisplayServer.window_get_mode()
	return m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


## iPhones' Safari has no fullscreen API for games, so the button is hidden there.
func _fullscreen_supported() -> bool:
	if not OS.has_feature("web"):
		return true
	return bool(JavaScriptBridge.eval("!!(document.fullscreenEnabled || document.webkitFullscreenEnabled)", true))


func _toggle_fullscreen() -> void:
	Game.sfx("click")
	if _is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if OS.has_feature("web"):
		# phones: also try to lock to landscape once fullscreen kicks in
		await get_tree().create_timer(0.5).timeout
		JavaScriptBridge.eval("try{screen.orientation.lock('landscape').catch(function(){})}catch(e){}", true)


func _process(delta: float) -> void:
	t += delta
	if fs_btn:
		fs_btn.text = "Exit Fullscreen" if _is_fullscreen() else "Fullscreen"
	if randf() < delta * 5.0:
		puffs.append({"p": Vector2(640 + randf_range(-30, 30), 560), "v": Vector2(randf_range(-60, 60), randf_range(-60, -20)), "r": randf_range(14, 26), "life": 2.5})
	for p: Dictionary in puffs:
		p["p"] += p["v"] * delta
		p["r"] += delta * 10.0
		p["life"] -= delta
	puffs = puffs.filter(func(p: Dictionary) -> bool: return p["life"] > 0.0)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if leaving:
		return
	var go := false
	if event is InputEventKey and event.pressed and not event.echo:
		go = event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	elif event is InputEventMouseButton and event.pressed:
		go = true
	if go:
		leaving = true
		Game.fart("fart_huge", 1.0)
		await get_tree().create_timer(0.9).timeout
		if not is_inside_tree():
			return
		Game.goto("res://scenes/board.gd" if Game.data["seen_intro"] else "res://scenes/intro.gd")


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.1, 0.06, 0.2))
	for i in 12:
		draw_rect(Rect2(0, i * 40, 1280, 40), Color(0.25, 0.12, 0.35, 0.08 * i))
	draw_circle(Vector2(1160, 110), 60, Color(0.95, 0.95, 0.75))
	draw_circle(Vector2(1182, 96), 53, Color(0.2, 0.1, 0.3))
	for b: Array in buildings:
		var r := Rect2(b[0], 600 - b[2], b[1], b[2])
		draw_rect(r, Color(0.06, 0.04, 0.1))
		var rng := RandomNumberGenerator.new()
		rng.seed = b[3]
		var y := r.position.y + 14
		while y < 590:
			var x: float = r.position.x + 10
			while x < r.end.x - 14:
				if rng.randf() < 0.35:
					draw_rect(Rect2(x, y, 10, 14), Color(1, 0.85, 0.4, 0.7))
				x += 20
			y += 26
	draw_rect(Rect2(0, 600, 1280, 120), Color(0.08, 0.06, 0.1))
	for p: Dictionary in puffs:
		Art.cloud(self, p["p"], p["r"], Color(0.6, 0.8, 0.25, 0.45 * clampf(p["life"], 0, 1)))
	Art.squelch(self, Vector2(640, 610), 2.2, {"look": Vector2(sin(t), 0.3)})
	var wob := sin(t * 3.0) * 4.0
	Art.text(self, Vector2(640, 170 + wob), "SQUELCH", 140, Color(0.65, 0.9, 0.3), true, 22, Color(0.2, 0.05, 0.3))
	Art.text(self, Vector2(640, 230), "A LIFE OF FART CRIME", 38, Color(0.95, 0.85, 1.0), true, 10, Color(0.2, 0.05, 0.3))
	var a := 0.5 + 0.5 * sin(t * 4.0)
	Art.text(self, Vector2(640, 690), "Click, tap or press SPACE to begin", 30, Color(1, 1, 1, a), true, 6)
	if Game.egg_count() > 0:
		Art.star(self, Vector2(1150, 690), 14, Color(1, 0.8, 0.15))
		Art.text(self, Vector2(1205, 700), "%d/10" % Game.egg_count(), 26, Color(1, 0.85, 0.3), true, 6)
