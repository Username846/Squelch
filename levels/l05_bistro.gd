extends LevelBase
## Crime #5: A fancy restaurant. When a cloche lifts, click the dish to "season" it
## — but never while the waiter is watching that table.

const TABLES := [Vector2(170, 520), Vector2(400, 520), Vector2(640, 520), Vector2(880, 520), Vector2(1110, 520)]
const TANK := Rect2(1040, 120, 180, 120)
const GOAL := 10

var dishes: Array = []  # {open, t, seasoned}
var waiter_x := 640.0
var waiter_dir := 1.0
var waiter_pause := 0.0
var spawn_t := 1.0
var seasoned := 0
var strikes := 0
var me_at := -1
var me_t := 0.0
var lobster_free := false
var lobster_x := 0.0


func music_name() -> String:
	return "restaurant"


func setup() -> void:
	level_id = "bistro"
	for i in TABLES.size():
		dishes.append({"open": false, "t": 0.0, "seasoned": 0.0})


func intro_lines() -> Array:
	return [
		["Narrator", "Crime number five. Le Bistro Pew. Three Michelin stars. A four-month waiting list."],
		["Chef Pierre", "Ze soup tonight is a delicate lobster bisque. It must be served... parfait."],
		["Squelch", "Parfait? Oh, I'll add a little something extra."],
		["Narrator", "When a dish is uncovered, click it (or press its number 1 to 5) to season it. If the waiter is looking at that table, you're busted! Season ten dishes."],
	]


func win_lines() -> Array:
	return [
		["Diner", "Waiter! There is a... bouquet... in my soup!"],
		["Chef Pierre", "Sacre bleu! My bisque! Who has done zis?!"],
		["Squelch", "Compliments to the chef. And the chef's compliments... to me."],
	]


func uses_dpad() -> bool:
	return false


func uses_touch() -> bool:
	return false


func waiter_watching(i: int) -> bool:
	var dx: float = TABLES[i].x - waiter_x
	if absf(dx) < 80.0:
		return true
	return absf(dx) < 300.0 and signf(dx) == waiter_dir


func play_process(delta: float) -> void:
	me_t -= delta
	# waiter strolls, sometimes stops and turns
	if waiter_pause > 0.0:
		waiter_pause -= delta
		if waiter_pause <= 0.0 and randf() < 0.5:
			waiter_dir = -waiter_dir
	else:
		waiter_x += waiter_dir * delta * (130.0 + seasoned * 8.0)
		if waiter_x < 120 or waiter_x > 1160:
			waiter_dir = -waiter_dir
			waiter_x = clampf(waiter_x, 120, 1160)
		if randf() < delta * 0.5:
			waiter_pause = randf_range(0.5, 1.2)
	# dishes open and close
	spawn_t -= delta
	if spawn_t <= 0.0:
		spawn_t = randf_range(0.7, 1.4)
		var closed := []
		for i in dishes.size():
			if not dishes[i]["open"]:
				closed.append(i)
		if not closed.is_empty():
			var k: int = closed.pick_random()
			dishes[k]["open"] = true
			dishes[k]["t"] = 1.7
	for d: Dictionary in dishes:
		d["seasoned"] = maxf(0.0, d["seasoned"] - delta)
		if d["open"]:
			d["t"] -= delta
			if d["t"] <= 0.0:
				d["open"] = false


func _unhandled_input(event: InputEvent) -> void:
	super(event)
	if event is InputEventKey and event.pressed and not event.echo and state == "play":
		var k: int = event.physical_keycode
		if k >= KEY_1 and k <= KEY_5:
			_season(k - KEY_1)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = event.position
		if not lobster_free and TANK.has_point(p):
			lobster_free = true
			lobster_x = TANK.get_center().x
			Game.sfx("splash")
			Game.speak("Freedom! Au revoir, suckers!", "Lobster")
			pop_text("FREEDOM!", TANK.get_center() + Vector2(0, -80), Color(1, 0.4, 0.3), 40)
			found_egg()
			return
		if state == "play":
			for i in TABLES.size():
				if p.distance_to(TABLES[i] + Vector2(0, -40)) < 75.0:
					_season(i)


func _season(i: int) -> void:
	me_at = i
	me_t = 0.6
	var d: Dictionary = dishes[i]
	if not d["open"]:
		Game.sfx("click")
		return
	if waiter_watching(i):
		strikes += 1
		d["open"] = false
		Game.speak("Monsieur! What are you doing to ze soup?!", "Chef Pierre")
		Game.sfx("buzzer")
		pop_text("CAUGHT!", TABLES[i] + Vector2(0, -150), Color(1, 0.3, 0.3), 44)
		shake = 0.4
		if strikes >= 3:
			lose("The waiter caught you seasoning the soup three times. You've been eighty-sixed.")
		return
	d["open"] = false
	d["seasoned"] = 2.0
	seasoned += 1
	Game.fart("fart_wet" if randf() < 0.5 else "")
	puff(TABLES[i] + Vector2(0, -60), 6)
	pop_text(["Mon dieu!", "Ugh!", "Ze bouquet!", "Gross!", "Waiter!"].pick_random(), TABLES[i] + Vector2(0, -170), Art.GAS)
	if seasoned >= GOAL:
		win()


func draw_level() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.45, 0.12, 0.15))
	for i in 20:
		draw_rect(Rect2(i * 64, 0, 4, 420), Color(0.55, 0.2, 0.2))
	draw_rect(Rect2(0, 420, 1280, 300), Color(0.25, 0.15, 0.1))
	for i in 20:
		draw_line(Vector2(i * 70 - 100, 720), Vector2(i * 70, 420), Color(0.3, 0.18, 0.12), 2)
	# chandeliers
	for x in [320, 960]:
		draw_line(Vector2(x, 0), Vector2(x, 60), Color(0.8, 0.7, 0.3), 3)
		Art.ellipse(self, Vector2(x, 70), 50, 14, Color(0.9, 0.8, 0.4))
		for k in 5:
			draw_circle(Vector2(x - 40 + k * 20, 58), 5, Color(1, 0.95, 0.6))
	Art.text(self, Vector2(400, 140), "Le Bistro Pew", 56, Color(1, 0.85, 0.5), true, 8, Color(0.3, 0.05, 0.05))
	for k in 3:
		Art.star(self, Vector2(360 + k * 40, 172), 15, Color(1, 0.85, 0.3))
	# lobster tank
	Art.rrect(self, TANK, Color(0.4, 0.7, 0.9, 0.7), 6, 4, Color(0.7, 0.75, 0.8))
	for k in 4:
		draw_circle(TANK.position + Vector2(30 + k * 40, TANK.size.y - 20 - fmod(t * 30 + k * 25, 80)), 4, Color(1, 1, 1, 0.5))
	if not lobster_free:
		_lobster(TANK.get_center() + Vector2(sin(t) * 20, 20), 1.0)
	else:
		lobster_x -= get_process_delta_time() * 140.0
		if lobster_x < -60.0:
			lobster_x = 1340.0
		_lobster(Vector2(lobster_x, 700), 0.9)
	# tables
	for i in TABLES.size():
		var tp: Vector2 = TABLES[i]
		var d: Dictionary = dishes[i]
		var green: bool = d["seasoned"] > 0.0
		Art.person(self, tp + Vector2(-70, 40), 0.85, Art.CLOTHES[i], Art.SKIN[(i + 1) % 5], {"sit": true, "mood": "green" if green else "smile", "hair": Art.HAIR[i % 5], "facing": 1.0, "look": Vector2(1, 0)})
		Art.person(self, tp + Vector2(70, 40), 0.85, Art.CLOTHES[(i + 3) % 7], Art.SKIN[(i + 3) % 5], {"sit": true, "mood": "green" if green else "smile", "hair": Art.HAIR[(i + 2) % 5], "facing": -1.0, "look": Vector2(-1, 0), "dress": i % 2 == 0})
		draw_rect(Rect2(tp + Vector2(-60, -16), Vector2(120, 16)), Color(0.97, 0.97, 0.95))
		draw_rect(Rect2(tp + Vector2(-56, 0), Vector2(112, 60)), Color(0.93, 0.93, 0.9))
		Art.ellipse(self, tp + Vector2(0, -18), 34, 8, Color(1, 1, 1))
		if d["open"]:
			Art.ellipse(self, tp + Vector2(0, -24), 24, 8, Color(0.95, 0.55, 0.35))
			for k in 3:
				var wv := sin(t * 5 + k) * 5
				draw_line(tp + Vector2(-10 + k * 10 + wv, -34), tp + Vector2(-10 + k * 10 - wv, -60), Color(1, 1, 1, 0.6), 3)
			draw_arc(tp + Vector2(30, -90), 30, PI, TAU, 16, Color(0.85, 0.85, 0.9), 6)
			Art.meter(self, Rect2(tp + Vector2(-40, -120), Vector2(80, 12)), d["t"] / 1.7, Color(1, 0.9, 0.4))
		else:
			draw_arc(tp + Vector2(0, -20), 32, PI, TAU, 18, Color(0.82, 0.82, 0.88), 30)
			draw_circle(tp + Vector2(0, -54), 5, Color(0.7, 0.7, 0.75))
		if green:
			for k in 3:
				var wv2 := sin(t * 3 + k * 2) * 8
				draw_line(tp + Vector2(-14 + k * 14, -40) + Vector2(wv2, 0), tp + Vector2(-14 + k * 14, -70) + Vector2(-wv2, 0), Color(0.55, 0.8, 0.2, 0.8), 4)
		Art.text(self, tp + Vector2(0, 100), str(i + 1), 22, Color(1, 1, 1, 0.5), true, 4)
	# waiter
	var wp := Vector2(waiter_x, 690)
	draw_colored_polygon(PackedVector2Array([wp + Vector2(0, -100), wp + Vector2(waiter_dir * 300, -40), wp + Vector2(waiter_dir * 300, 30)]), Color(1, 1, 0.5, 0.1))
	Art.ellipse(self, wp + Vector2(0, -6), 85, 14, Color(1, 1, 0.5, 0.12))
	Art.person(self, wp, 1.1, Color(0.1, 0.1, 0.12), Art.SKIN[0], {"look": Vector2(waiter_dir, 0), "walk": t * 8 if waiter_pause <= 0 else 0.0, "mustache": true, "facing": waiter_dir, "hair": Art.HAIR[1]})
	draw_line(wp + Vector2(waiter_dir * 22, -78), wp + Vector2(waiter_dir * 40, -90), Color.WHITE, 6)
	# squelch the "sommelier"
	if me_t > 0.0 and me_at >= 0:
		Art.squelch(self, TABLES[me_at] + Vector2(0, 150), 0.9, {"hat": "none", "mood": "grin"})


func _lobster(c: Vector2, s: float) -> void:
	Art.ellipse(self, c, 26 * s, 12 * s, Color(0.9, 0.2, 0.15))
	draw_circle(c + Vector2(-30 * s, -6 * s), 9 * s, Color(0.9, 0.2, 0.15))
	draw_circle(c + Vector2(30 * s, -6 * s), 9 * s, Color(0.9, 0.2, 0.15))
	draw_circle(c + Vector2(-6 * s, -10 * s), 3 * s, Color.BLACK)
	draw_circle(c + Vector2(6 * s, -10 * s), 3 * s, Color.BLACK)


func draw_hud() -> void:
	if state != "play":
		return
	Art.text(self, Vector2(830, 140), "Dishes seasoned: %d / %d" % [seasoned, GOAL], 30, Color.WHITE, true, 6)
	Art.text(self, Vector2(830, 180), "Strikes: %d / 3" % strikes, 26, Color(1, 0.5, 0.5), true, 6)
	Art.text(self, Vector2(640, 330), "Click open dishes while the waiter's gaze (yellow) isn't on them", 20, Color(1, 1, 1, 0.75), true, 5)
