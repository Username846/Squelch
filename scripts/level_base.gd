class_name LevelBase
extends Node2D
## Shared plumbing for every crime: intro/outro dialogue, gas puffs, popups,
## the result screen, the secret-found banner and player movement.

var level_id := ""
var state := "intro"  # intro, play, won, lost
var t := 0.0
var play_t := 0.0
var puffs: Array = []
var popups: Array = []
var shake := 0.0

# player (for levels that use a walking Squelch)
var pp := Vector2(640, 500)
var pfacing := 1.0
var pwalk := 0.0
var pmoving := false
## Where on Squelch's body a held mouse / finger steers to (relative to pp).
var pointer_anchor := Vector2.ZERO

# pointer input: -1 = real mouse, >= 0 = touch index, -2 = nobody
var pointer := Vector2.ZERO
var _move_ptr := -2
var _action_ptr := -2

var _ui: CanvasLayer
var _result: Control


# ---- overridables
func music_name() -> String:
	return "board"


func setup() -> void:
	pass


func intro_lines() -> Array:
	return []


func win_lines() -> Array:
	return []


func start_play() -> void:
	pass


func play_process(_delta: float) -> void:
	pass


func draw_level() -> void:
	pass


func draw_hud() -> void:
	pass


## Show the on-screen action button (clickable and tappable).
func uses_action_button() -> bool:
	return true


## Hold the mouse button / a finger down to walk Squelch toward it.
func uses_pointer_move() -> bool:
	return false


func action_text() -> String:
	return "FART"


func action_pos() -> Vector2:
	return Vector2(1170, 600)


## Whether the action button is shown right now.
func action_active() -> bool:
	return uses_action_button()


# ---- lifecycle
func _ready() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 20
	add_child(_ui)
	var back := Button.new()
	back.text = "X"
	back.position = Vector2(1226, 8)
	back.size = Vector2(46, 40)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(func() -> void: Game.goto("res://scenes/board.gd"))
	_ui.add_child(back)
	Game.play_music(music_name())
	setup()
	_begin.call_deferred()


func _begin() -> void:
	if not await Game.talk(intro_lines()):
		return
	await get_tree().create_timer(0.12).timeout
	if not is_inside_tree():
		return
	state = "play"
	start_play()


func _process(delta: float) -> void:
	t += delta
	if state == "play":
		play_t += delta
		play_process(delta)
	elif _action_ptr != -2 or _move_ptr != -2:
		_release_pointers()
	_update_fx(delta)
	shake = maxf(0.0, shake - delta * 2.5)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 14.0
	queue_redraw()


func _exit_tree() -> void:
	_release_pointers()


func _release_pointers() -> void:
	if _action_ptr != -2:
		Input.action_release("fart")
	_action_ptr = -2
	_move_ptr = -2


func _show_action() -> bool:
	return state == "play" and action_active() and not Game.dialog_active


## Mouse and touch are handled the same way: a press on the action button holds
## the "fart" action; any other press (in walking levels) steers Squelch.
func _input(event: InputEvent) -> void:
	var idx := -2
	var pos := Vector2.ZERO
	var kind := ""  # down, up, move
	if event is InputEventScreenTouch:
		idx = event.index
		pos = event.position
		kind = "down" if event.pressed else "up"
	elif event is InputEventScreenDrag:
		idx = event.index
		pos = event.position
		kind = "move"
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			# mouse events synthesized from touch: just keep them off the action button
			if event.pressed and _show_action() and pos.distance_to(action_pos()) < 76.0:
				get_viewport().set_input_as_handled()
			return
		idx = -1
		kind = "down" if event.pressed else "up"
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		idx = -1
		pos = event.position
		kind = "move"
	else:
		return
	match kind:
		"down":
			if _show_action() and pos.distance_to(action_pos()) < 76.0:
				_action_ptr = idx
				Input.action_press("fart")
				get_viewport().set_input_as_handled()
			elif state == "play" and uses_pointer_move() and not Game.dialog_active and _move_ptr == -2:
				_move_ptr = idx
				pointer = pos
		"up":
			if idx == _action_ptr:
				_action_ptr = -2
				Input.action_release("fart")
			if idx == _move_ptr:
				_move_ptr = -2
		"move":
			if idx == _move_ptr:
				pointer = pos


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		Game.goto("res://scenes/board.gd")


func _draw() -> void:
	draw_level()
	for p: Dictionary in puffs:
		var a: float = p["life"] / p["max"]
		Art.cloud(self, p["pos"], p["r"], Color(p["col"].r, p["col"].g, p["col"].b, 0.55 * a))
	for q: Dictionary in popups:
		var a2: float = clampf(q["life"], 0.0, 1.0)
		var c: Color = q["col"]
		Art.text(self, q["pos"], q["text"], q["size"], Color(c.r, c.g, c.b, a2), true, 6, Color(0, 0, 0, 0.8 * a2))
	draw_hud()
	if _show_action():
		var held := _action_ptr != -2 or Input.is_action_pressed("fart")
		var ap := action_pos()
		draw_circle(ap, 66, Color(0.1, 0.05, 0.15, 0.45))
		draw_circle(ap, 58, Color(0.55, 0.8, 0.25, 0.85 if held else 0.55))
		draw_arc(ap, 62, 0, TAU, 32, Color(1, 1, 1, 0.7), 4)
		Art.text(self, ap + Vector2(0, 9), action_text(), 26, Color.WHITE, true, 6, Color(0.15, 0.05, 0.2))
	if _move_ptr != -2:
		draw_arc(pointer, 18, 0, TAU, 16, Color(1, 1, 1, 0.5), 3)


# ---- effects
func puff(pos: Vector2, n := 6, col := Art.GAS, spread := 30.0, size := 16.0, up := -30.0) -> void:
	for i in n:
		puffs.append({
			"pos": pos + Vector2(randf_range(-spread, spread), randf_range(-spread * 0.5, spread * 0.5)),
			"vel": Vector2(randf_range(-30, 30), randf_range(-20, 10) + up),
			"r": size * randf_range(0.6, 1.2), "life": 1.6, "max": 1.6, "col": col,
		})


func pop_text(s: String, pos: Vector2, col := Color(1, 1, 0.4), size := 30) -> void:
	popups.append({"text": s, "pos": pos, "col": col, "life": 1.4, "size": size})


func _update_fx(delta: float) -> void:
	for p: Dictionary in puffs:
		p["pos"] += p["vel"] * delta
		p["r"] += delta * 14.0
		p["life"] -= delta
	puffs = puffs.filter(func(p: Dictionary) -> bool: return p["life"] > 0.0)
	for q: Dictionary in popups:
		q["pos"] += Vector2(0, -40) * delta
		q["life"] -= delta
	popups = popups.filter(func(q: Dictionary) -> bool: return q["life"] > 0.0)


# ---- player movement
func move_player(delta: float, speed: float, bounds: Rect2, blockers: Array = []) -> void:
	var v := Input.get_vector("left", "right", "up", "down")
	if v.length() < 0.1 and _move_ptr != -2:
		var to := pointer - (pp + pointer_anchor)
		if to.length() > 8.0:
			v = to.normalized() * minf(1.0, to.length() / 40.0)
	pmoving = v.length() > 0.1
	if not pmoving:
		return
	if absf(v.x) > 0.1:
		pfacing = signf(v.x)
	pwalk += delta * 12.0
	var step := v * speed * delta
	var nx := Vector2(clampf(pp.x + step.x, bounds.position.x, bounds.end.x), pp.y)
	if not _blocked(nx, blockers):
		pp = nx
	var ny := Vector2(pp.x, clampf(pp.y + step.y, bounds.position.y, bounds.end.y))
	if not _blocked(ny, blockers):
		pp = ny


func _blocked(p: Vector2, blockers: Array) -> bool:
	for r: Rect2 in blockers:
		if r.grow(14).has_point(p):
			return true
	return false


## Line of sight check for vision cones; walls are Rect2s.
func can_see(from: Vector2, dir: float, fov_deg: float, dist: float, target: Vector2, walls: Array) -> bool:
	var d := target - from
	if d.length() > dist:
		return false
	if absf(angle_difference(dir, d.angle())) > deg_to_rad(fov_deg) * 0.5:
		return false
	var steps := int(d.length() / 8.0)
	for i in range(1, steps):
		var q := from + d * (float(i) / steps)
		for r: Rect2 in walls:
			if r.has_point(q):
				return false
	return true


## Draws a vision cone clipped by walls (ray-marched).
func draw_cone(from: Vector2, dir: float, fov_deg: float, dist: float, walls: Array, col: Color) -> void:
	var pts := PackedVector2Array([from])
	var half := deg_to_rad(fov_deg) * 0.5
	for i in 17:
		var a := dir - half + half * 2.0 * i / 16.0
		var v := Vector2.from_angle(a)
		var reach := dist
		var k := 8.0
		while k < dist:
			var q := from + v * k
			var hit := false
			for r: Rect2 in walls:
				if r.has_point(q):
					hit = true
					break
			if hit:
				reach = k
				break
			k += 8.0
		pts.append(from + v * reach)
	draw_colored_polygon(pts, col)


# ---- outcomes
func found_egg() -> void:
	if Game.find_egg(level_id):
		Game.sfx("egg")
		Game.banner("* SECRET STASH FOUND! *  (%d/10)" % Game.egg_count(), 3.0)
	else:
		Game.sfx("sparkle")


func win() -> void:
	if state != "play":
		return
	state = "won"
	Game.complete(level_id)
	Game.sfx("win")
	Game.sfx("cheer", 1.0, -6.0)
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	if not await Game.talk(win_lines()):
		return
	var idx := Game.level_index(level_id)
	var buttons := []
	if idx + 1 < Game.LEVELS.size():
		buttons.append(["Next Crime >>", func() -> void: Game.goto_level(idx + 1)])
	buttons.append(["Crime Board", func() -> void: Game.goto("res://scenes/board.gd")])
	buttons.append(["Replay", func() -> void: Game.goto(Game.LEVELS[idx]["path"])])
	_show_result("CRIME COMMITTED!", Game.LEVELS[idx]["crime"], Color(0.6, 1.0, 0.35), buttons)


func lose(reason: String) -> void:
	if state != "play":
		return
	state = "lost"
	Game.sfx("lose")
	shake = 0.6
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return
	var idx := Game.level_index(level_id)
	_show_result("BUSTED!", reason, Color(1.0, 0.4, 0.35), [
		["Try Again", func() -> void: Game.goto(Game.LEVELS[idx]["path"])],
		["Crime Board", func() -> void: Game.goto("res://scenes/board.gd")],
	])


func _show_result(title: String, sub: String, col: Color, buttons: Array) -> void:
	_result = Control.new()
	_result.size = Vector2(1280, 720)
	_ui.add_child(_result)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = _result.size
	_result.add_child(dim)
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.07, 0.18, 0.97)
	sb.border_color = col
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(20)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(340, 190)
	panel.size = Vector2(600, 330)
	_result.add_child(panel)
	var l := Label.new()
	l.text = title
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, 30)
	l.size = Vector2(600, 70)
	l.add_theme_font_size_override("font_size", 56)
	l.add_theme_color_override("font_color", col)
	panel.add_child(l)
	var s := Label.new()
	s.text = sub
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.position = Vector2(30, 110)
	s.size = Vector2(540, 80)
	s.add_theme_font_size_override("font_size", 26)
	panel.add_child(s)
	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	box.position = Vector2(20, 230)
	box.size = Vector2(560, 64)
	panel.add_child(box)
	var first: Button = null
	for b: Array in buttons:
		var btn := Button.new()
		btn.text = b[0]
		btn.custom_minimum_size = Vector2(170, 60)
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(b[1])
		box.add_child(btn)
		if first == null:
			first = btn
	if first:
		first.grab_focus()
