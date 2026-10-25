extends Node2D
## The crime board: pick a crime, see which ones are committed and how many secrets are stashed.

const CARD := Vector2(210, 215)

var t := 0.0
var sel := 0
var hover := -1
var reset_armed := false
var _reset_btn: Button


func _ready() -> void:
	Game.play_music("board")
	sel = 0
	for i in Game.LEVELS.size():
		if Game.is_unlocked(i) and not Game.is_done(Game.LEVELS[i]["id"]):
			sel = i
			break
	var ui := CanvasLayer.new()
	add_child(ui)
	var intro := Button.new()
	intro.text = "Watch Intro"
	intro.position = Vector2(20, 668)
	intro.focus_mode = Control.FOCUS_NONE
	intro.pressed.connect(func() -> void: Game.goto("res://scenes/intro.gd"))
	ui.add_child(intro)
	var title := Button.new()
	title.text = "Title"
	title.position = Vector2(150, 668)
	title.focus_mode = Control.FOCUS_NONE
	title.pressed.connect(func() -> void: Game.goto("res://scenes/title.gd"))
	ui.add_child(title)
	_reset_btn = Button.new()
	_reset_btn.text = "Reset Progress"
	_reset_btn.position = Vector2(1120, 668)
	_reset_btn.focus_mode = Control.FOCUS_NONE
	_reset_btn.pressed.connect(_on_reset)
	ui.add_child(_reset_btn)


func _on_reset() -> void:
	if not reset_armed:
		reset_armed = true
		_reset_btn.text = "Really? Click again"
		return
	Game.reset_save()
	Game.goto("res://scenes/board.gd")


func card_rect(i: int) -> Rect2:
	var col := i % 5
	var row := i / 5
	return Rect2(Vector2(45 + col * 242, 92 + row * 248), CARD)


func final_rect() -> Rect2:
	return Rect2(390, 590, 500, 70)


func final_open() -> bool:
	return Game.all_eggs()


func _process(delta: float) -> void:
	t += delta
	var m := get_global_mouse_position()
	hover = -1
	for i in Game.LEVELS.size():
		if card_rect(i).has_point(m):
			hover = i
	if final_rect().has_point(m):
		hover = 10
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if hover >= 0:
			_open(hover)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_LEFT, KEY_A:
				sel = maxi(0, sel - 1)
			KEY_RIGHT, KEY_D:
				sel = mini(10, sel + 1)
			KEY_UP, KEY_W:
				sel = 4 if sel == 10 else maxi(0, sel - 5) if sel >= 5 else sel
			KEY_DOWN, KEY_S:
				sel = 10 if sel >= 5 else sel + 5
			KEY_SPACE, KEY_ENTER, KEY_KP_ENTER:
				_open(sel)
			KEY_ESCAPE:
				Game.goto("res://scenes/title.gd")
		Game.sfx("click")


func _open(i: int) -> void:
	if i == 10:
		if final_open():
			Game.sfx("siren")
			Game.goto("res://scenes/finale.gd")
		else:
			Game.sfx("buzzer")
		return
	if Game.is_unlocked(i):
		Game.sfx("select")
		Game.goto_level(i)
	else:
		Game.sfx("buzzer")


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.55, 0.38, 0.22))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 400:
		draw_circle(Vector2(rng.randf() * 1280, rng.randf() * 720), rng.randf_range(1, 3), Color(0.4, 0.26, 0.14, 0.5))
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.3, 0.18, 0.08), false, 18)
	Art.text(self, Vector2(640, 62), "THE CRIMES OF SQUELCH", 48, Color(0.98, 0.94, 0.85), true, 10, Color(0.25, 0.1, 0.05))
	Art.star(self, Vector2(1100, 50), 20, Color(0.25, 0.1, 0.05))
	Art.star(self, Vector2(1100, 50), 16, Color(1, 0.8, 0.15))
	Art.text(self, Vector2(1175, 62), "%d / 10" % Game.egg_count(), 32, Color(1, 0.85, 0.3), true, 8, Color(0.25, 0.1, 0.05))
	Art.text(self, Vector2(130, 62), "Committed %d/10" % Game.done_count(), 24, Color(0.98, 0.94, 0.85), true, 6, Color(0.25, 0.1, 0.05))
	# red string between cards
	for i in Game.LEVELS.size() - 1:
		var a := card_rect(i).get_center() + Vector2(0, -95)
		var b := card_rect(i + 1).get_center() + Vector2(0, -95)
		draw_line(a, b, Color(0.8, 0.1, 0.1, 0.8), 3)
	for i in Game.LEVELS.size():
		_draw_card(i)
	_draw_final()
	Art.text(self, Vector2(640, 705), "Arrows + Space, or click a case", 18, Color(1, 1, 1, 0.6), true, 4)


func _draw_card(i: int) -> void:
	var lv: Dictionary = Game.LEVELS[i]
	var r := card_rect(i)
	var tilt := sin(i * 2.3) * 0.04
	draw_set_transform(r.get_center(), tilt, Vector2.ONE)
	var rr := Rect2(-r.size / 2, r.size)
	var focus := i == hover or i == sel
	if focus:
		Art.rrect(self, rr.grow(8), Color(1, 0.9, 0.3, 0.6 + 0.3 * sin(t * 6)), 8)
	var unlocked := Game.is_unlocked(i)
	Art.rrect(self, rr, Color(0.97, 0.95, 0.9) if unlocked else Color(0.45, 0.42, 0.4), 4)
	draw_rect(Rect2(rr.position + Vector2(12, 12), Vector2(rr.size.x - 24, 110)), Color(0.2, 0.18, 0.25) if unlocked else Color(0.25, 0.23, 0.22))
	draw_circle(Vector2(0, rr.position.y + 4), 9, Color(0.85, 0.1, 0.1))
	if unlocked:
		_thumb(i, Vector2(0, rr.position.y + 112))
		Art.text(self, Vector2(0, rr.position.y + 148), "#%d %s" % [i + 1, lv["title"]], 18, Color(0.15, 0.1, 0.1))
		Art.wrap(self, Vector2(0, rr.position.y + 172), lv["crime"], 14, Color(0.35, 0.25, 0.25), rr.size.x - 20)
		if Game.is_done(lv["id"]):
			draw_set_transform(r.get_center() + Vector2(0, -50), tilt - 0.3, Vector2.ONE)
			Art.rrect(self, Rect2(-88, -22, 176, 40), Color(0, 0, 0, 0), 6, 4, Color(0.85, 0.1, 0.1, 0.85))
			Art.text(self, Vector2(0, 9), "COMMITTED", 26, Color(0.85, 0.1, 0.1, 0.85))
			draw_set_transform(r.get_center(), tilt, Vector2.ONE)
		if Game.has_egg(lv["id"]):
			Art.star(self, rr.end - Vector2(22, 22), 15, Color(1, 0.8, 0.15))
	else:
		Art.text(self, Vector2(0, rr.position.y + 85), "?", 72, Color(0.6, 0.6, 0.6))
		Art.text(self, Vector2(0, rr.position.y + 160), "#%d  LOCKED" % (i + 1), 20, Color(0.2, 0.2, 0.2))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## Tiny scene sketch on each case card.
func _thumb(i: int, foot: Vector2) -> void:
	var s := 0.75
	match i:
		0:
			Art.chair(self, foot + Vector2(-50, -6), 0.8, Color(0.9, 0.4, 0.4))
			Art.chair(self, foot + Vector2(50, -6), 0.8, Color(0.4, 0.6, 0.9))
			Art.person(self, foot + Vector2(-50, -4), 0.55, Art.CLOTHES[2], Art.SKIN[0], {"hat": "party"})
		1:
			draw_rect(Rect2(foot + Vector2(-70, -100), Vector2(140, 98)), Color(0.55, 0.5, 0.4))
			draw_line(foot + Vector2(0, -100), foot + Vector2(0, -2), Color(0.3, 0.28, 0.25), 3)
		2:
			for k in 5:
				draw_rect(Rect2(foot + Vector2(-80 + k * 32, -95), Vector2(26, 90)), Color.from_hsv(k * 0.17, 0.5, 0.7))
		3:
			Art.ellipse(self, foot + Vector2(0, -8), 70, 10, Color(0.4, 0.7, 0.6))
		4:
			draw_rect(Rect2(foot + Vector2(-60, -40), Vector2(120, 38)), Color(0.95, 0.95, 0.95))
			draw_arc(foot + Vector2(0, -42), 34, PI, TAU, 16, Color(0.8, 0.8, 0.85), 6)
		5:
			Art.person(self, foot + Vector2(30, -2), 0.55, Color.WHITE, Art.SKIN[0], {"hat": "veil", "dress": true})
			Art.person(self, foot + Vector2(-30, -2), 0.55, Color(0.1, 0.1, 0.12), Art.SKIN[2], {})
		6:
			draw_rect(Rect2(foot + Vector2(-90, -60), Vector2(180, 50)), Color(0.3, 0.3, 0.32))
			Art.rrect(self, Rect2(foot + Vector2(-30, -50), Vector2(60, 28)), Color(0.5, 0.25, 0.65), 6)
		7:
			draw_arc(foot + Vector2(0, -40), 30, 0, TAU, 20, Color(0.85, 0.7, 0.2), 8)
		8:
			Art.person(self, foot + Vector2(0, -2), 0.55, Color(0.4, 0.2, 0.6), Art.SKIN[0], {"hat": "crown", "dress": true, "hair": Art.HAIR[4]})
		9:
			Art.ellipse(self, foot + Vector2(0, -45), 22, 32, Color(1, 0.8, 0.2))
	if i in [1, 2, 3, 4, 7, 9]:
		Art.squelch(self, foot, s * 0.7)


func _draw_final() -> void:
	var r := final_rect()
	var open := final_open()
	var focus := hover == 10 or sel == 10
	if focus:
		Art.rrect(self, r.grow(6), Color(1, 0.9, 0.3, 0.6 + 0.3 * sin(t * 6)), 10)
	Art.rrect(self, r, Color(0.15, 0.05, 0.08) if open else Color(0.2, 0.18, 0.18), 8, 4, Color(0.85, 0.1, 0.1) if open else Color(0.4, 0.4, 0.4))
	if open:
		Art.text(self, r.get_center() + Vector2(0, -2), "THE FINAL CASE", 32, Color(1, 0.4 + 0.3 * sin(t * 5), 0.3))
		Art.text(self, r.get_center() + Vector2(0, 24), "click to open the file", 18, Color(1, 1, 1, 0.8))
	else:
		Art.text(self, r.get_center() + Vector2(0, 6), "FINAL CASE — SEALED", 30, Color(0.6, 0.6, 0.6))
		if Game.done_count() >= 10:
			Art.text(self, r.get_center() + Vector2(0, 30), "only a master of secrets may open it", 15, Color(0.75, 0.75, 0.75))
