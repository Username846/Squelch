extends Node2D
## Opening cutscene: Detective Sniffington introduces the city's gassiest menace.

var t := 0.0
var shot := "city"
var rain: Array = []


func _ready() -> void:
	Game.play_music("intro")
	for i in 120:
		rain.append(Vector2(randf() * 1280, randf() * 720))
	_run.call_deferred()


func _run() -> void:
	if not await Game.talk([
		["Narrator", "The city. Eleven million noses... and not one of them is safe."],
		["Det. Sniffington", "The name's Sniffington. Detective Sniffington. Best nose on the force."],
		["Det. Sniffington", "For twenty years, one perp has kept this nose running."],
	]):
		return
	shot = "wanted"
	Game.sfx("whoosh")
	if not await Game.talk([
		["Det. Sniffington", "They call him... Squelch. Birthday parties. Elevators. Libraries. Even weddings."],
		["Det. Sniffington", "Nothing is sacred to that man. Nothing."],
	]):
		return
	shot = "squelch"
	Game.sfx("thud")
	if not await Game.talk([
		["Squelch", "Heh heh heh. The detective is right about one thing. Nothing. Is. Sacred."],
		["Squelch", "Ten crimes, detective. Ten perfect crimes. And in every one, I'll hide a little secret, just for me."],
		["Squelch", "Catch me if you can. If you can stand the smell."],
	]):
		return
	Game.fart("fart_huge", 0.9)
	shot = "gas"
	await get_tree().create_timer(1.4).timeout
	if not is_inside_tree():
		return
	Game.data["seen_intro"] = true
	Game.save()
	Game.goto("res://scenes/board.gd")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		Game.data["seen_intro"] = true
		Game.save()
		Game.goto("res://scenes/board.gd")


func _process(delta: float) -> void:
	t += delta
	for i in rain.size():
		rain[i] += Vector2(-120, 700) * delta
		if rain[i].y > 720:
			rain[i] = Vector2(randf() * 1400, -10)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.07, 0.07, 0.12))
	match shot:
		"city":
			for i in 14:
				var h := 200.0 + float((i * 97) % 260)
				draw_rect(Rect2(i * 95, 520 - h, 88, h), Color(0.12, 0.12, 0.2))
				for wy in range(int(540 - h), 500, 30):
					if (i + wy) % 3 == 0:
						draw_rect(Rect2(i * 95 + 20, wy, 14, 16), Color(0.9, 0.8, 0.4, 0.5))
			draw_rect(Rect2(0, 500, 1280, 220), Color(0.05, 0.05, 0.08))
			draw_circle(Vector2(980, 330), 90, Color(1, 0.9, 0.5, 0.06))
			draw_line(Vector2(980, 330), Vector2(980, 520), Color(0.2, 0.2, 0.25), 8)
			Art.sniffington(self, Vector2(360, 700), 3.0, {"look": Vector2(1, 0)})
		"wanted":
			draw_rect(Rect2(0, 0, 1280, 720), Color(0.25, 0.18, 0.12))
			Art.rrect(self, Rect2(430, 60, 420, 440), Color(0.93, 0.86, 0.66), 4)
			Art.text(self, Vector2(640, 130), "WANTED", 72, Color(0.35, 0.1, 0.05))
			draw_rect(Rect2(490, 150, 300, 230), Color(0.8, 0.72, 0.55))
			Art.squelch(self, Vector2(640, 400), 2.0)
			draw_rect(Rect2(430, 380, 420, 120), Color(0.93, 0.86, 0.66))
			Art.text(self, Vector2(640, 430), "\"SQUELCH\"", 44, Color(0.35, 0.1, 0.05))
			Art.text(self, Vector2(640, 475), "for crimes against the nose", 24, Color(0.35, 0.1, 0.05))
		"squelch", "gas":
			draw_rect(Rect2(0, 500, 1280, 220), Color(0.06, 0.05, 0.08))
			draw_colored_polygon(PackedVector2Array([Vector2(560, 0), Vector2(720, 0), Vector2(900, 600), Vector2(380, 600)]), Color(1, 0.95, 0.7, 0.12))
			Art.squelch(self, Vector2(640, 600), 3.0, {"look": Vector2(0, 0.4)})
			if shot == "gas":
				var k := clampf(t * 0.3, 0, 1)
				for i in 10:
					Art.cloud(self, Vector2(640 + sin(i * 1.7 + t) * 300, 500 - i * 30), 80 + i * 10, Color(0.6, 0.8, 0.25, 0.25 + 0.4 * k))
	for r: Vector2 in rain:
		draw_line(r, r + Vector2(-4, 22), Color(0.6, 0.7, 0.9, 0.35), 1.5)
	Art.text(self, Vector2(1180, 30), "Esc = skip", 18, Color(1, 1, 1, 0.35))
