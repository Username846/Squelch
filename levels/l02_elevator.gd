extends LevelBase
## Crime #2: A crowded elevator. Release gas silently when nobody is looking
## until every passenger flees for the stairs.

const FLOOR_TIME := 1.7
const BOX := Rect2(220, 70, 840, 600)
const HATCH := Rect2(580, 78, 120, 34)
const ME_X := 640.0

var floor_n := 30
var floor_t := FLOOR_TIME
var pressure := 40.0
var stink := 0.0
var suspicion := 0.0
var releasing := false
var hiss_t := 0.0
var doors := 0.0  # 0 closed .. 1 open
var door_t := 0.0
var passengers: Array = []
var hatch_open := false


func music_name() -> String:
	return "elevator"


func setup() -> void:
	level_id = "elevator"
	var xs := [340.0, 480.0, 800.0, 940.0]
	var tol := [30.0, 45.0, 60.0, 75.0]
	for i in 4:
		passengers.append({"x": xs[i], "tol": tol[i], "state": "idle", "st": randf_range(1.5, 4.0), "here": true,
			"leaving": 0.0, "col": Art.CLOTHES[i + 1], "skin": Art.SKIN[(i * 2) % 5], "hair": Art.HAIR[i % 5]})


func intro_lines() -> Array:
	return [
		["Narrator", "Crime number two. The Grand Tower elevator. Thirty floors. Four strangers."],
		["Squelch", "Ah, the elevator. Nature's slow cooker."],
		["Narrator", "Your pressure keeps rising. HOLD the button, or SPACE, to silently release. When the air gets bad enough, passengers bail at the next floor."],
		["Narrator", "But if anyone sees you releasing, they'll get suspicious. Watch for the question marks! Clear the elevator before the lobby."],
	]


func win_lines() -> Array:
	return [
		["Passenger", "I'll take the stairs. All thirty floors of them."],
		["Squelch", "Going down? No. Going... dirty."],
	]


func action_text() -> String:
	return "HOLD"


func play_process(delta: float) -> void:
	# floors tick by
	floor_t -= delta
	if floor_t <= 0.0:
		floor_t = FLOOR_TIME
		floor_n -= 1
		_floor_stop()
		if floor_n <= 1:
			if _count_here() > 0:
				lose("You reached the lobby with %d passenger(s) still on board." % _count_here())
			return
	# doors animate
	if door_t > 0.0:
		door_t -= delta
		doors = minf(1.0, doors + delta * 3.0)
	else:
		doors = maxf(0.0, doors - delta * 3.0)
	# gas pressure
	pressure += delta * (7.0 + (30 - floor_n) * 0.12)
	releasing = Input.is_action_pressed("fart") and pressure > 2.0
	if releasing:
		pressure = maxf(0.0, pressure - delta * 32.0)
		stink = minf(100.0, stink + delta * 22.0)
		hiss_t -= delta
		if hiss_t <= 0.0:
			hiss_t = 0.85
			Game.sfx("hiss", randf_range(0.9, 1.1), -8.0)
		if randf() < delta * 8.0:
			puff(Vector2(ME_X, 560), 1, Art.GAS, 10, 12, -15)
	stink = maxf(0.0, stink - delta * 2.5)
	if pressure >= 100.0:
		pressure = 35.0
		suspicion += 40.0
		stink = minf(100.0, stink + 25.0)
		Game.fart("fart_huge", 1.0)
		shake = 0.7
		pop_text("BRAAAAP!", Vector2(ME_X, 300), Color(1, 0.5, 0.3), 56)
		for p: Dictionary in passengers:
			if p["here"]:
				p["state"] = "look"
				p["st"] = 1.5
	# passengers look around
	for p: Dictionary in passengers:
		if not p["here"]:
			continue
		p["st"] -= delta
		match p["state"]:
			"idle":
				if p["st"] <= 0.0:
					p["state"] = "turn"
					p["st"] = 0.75
			"turn":
				if p["st"] <= 0.0:
					p["state"] = "look"
					p["st"] = randf_range(0.9, 1.5)
			"look":
				if releasing:
					suspicion += delta * 35.0
				if p["st"] <= 0.0:
					p["state"] = "idle"
					p["st"] = randf_range(2.5, 6.0)
	if suspicion >= 100.0:
		Game.speak("It was HIM!", "Passenger")
		lose("The passengers caught you in the act. Elevator justice is swift.")


func _count_here() -> int:
	var n := 0
	for p: Dictionary in passengers:
		if p["here"]:
			n += 1
	return n


func _floor_stop() -> void:
	Game.sfx("ding", 1.0, -10.0)
	var leaving := false
	for p: Dictionary in passengers:
		if p["here"] and stink >= p["tol"]:
			p["here"] = false
			leaving = true
			pop_text("I'm out!", Vector2(p["x"], 260), Art.GAS)
	if leaving:
		door_t = 1.0
		stink *= 0.8
		Game.speak(["I'll take the stairs!", "Oh my god.", "Nope. Nope. Nope.", "Who ATE something?"].pick_random(), "Passenger")
		if _count_here() == 0:
			win()


func _unhandled_input(event: InputEvent) -> void:
	super(event)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not hatch_open and state == "play" and HATCH.has_point(event.position):
			hatch_open = true
			Game.sfx("thud")
			Game.speak("Hey. Close the hatch. I live here.", "Raccoon")
			pop_text("...a raccoon?", HATCH.get_center() + Vector2(0, 80))
			found_egg()


func draw_level() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.18, 0.16, 0.14))
	# elevator walls
	draw_rect(BOX, Color(0.72, 0.62, 0.45))
	for i in 6:
		draw_rect(Rect2(BOX.position.x + 20 + i * 136, BOX.position.y + 60, 120, 420), Color(0.78, 0.68, 0.5))
	draw_rect(Rect2(BOX.position.x, BOX.end.y - 60, BOX.size.x, 60), Color(0.4, 0.3, 0.25))
	draw_rect(Rect2(BOX.position.x, BOX.position.y, BOX.size.x, 46), Color(0.6, 0.55, 0.45))
	# ceiling hatch
	if hatch_open:
		draw_rect(HATCH, Color(0.05, 0.05, 0.05))
		Art.ellipse(self, HATCH.get_center() + Vector2(0, 14), 26, 20, Color(0.45, 0.45, 0.48))
		Art.rrect(self, Rect2(HATCH.get_center() + Vector2(-22, 6), Vector2(44, 12)), Color(0.1, 0.1, 0.1), 5)
		draw_circle(HATCH.get_center() + Vector2(-9, 11), 3, Color.WHITE)
		draw_circle(HATCH.get_center() + Vector2(9, 11), 3, Color.WHITE)
	else:
		draw_rect(HATCH, Color(0.55, 0.5, 0.42))
		draw_rect(HATCH, Color(0.45, 0.4, 0.33), false, 2)
	# floor display
	Art.rrect(self, Rect2(1090, 120, 150, 90), Color(0.05, 0.05, 0.05), 8)
	draw_colored_polygon(PackedVector2Array([Vector2(1105, 150), Vector2(1135, 150), Vector2(1120, 175)]), Color(1, 0.4, 0.2))
	Art.text(self, Vector2(1185, 185), "%d" % floor_n, 48, Color(1, 0.4, 0.2))
	# button panel
	Art.rrect(self, Rect2(1100, 260, 120, 280), Color(0.6, 0.6, 0.62), 6)
	for i in 12:
		draw_circle(Vector2(1130 + (i % 2) * 60, 290 + (i / 2) * 42), 13, Color(1, 0.9, 0.5) if (i + 1) == floor_n else Color(0.85, 0.85, 0.85))
	# passengers
	for p: Dictionary in passengers:
		if not p["here"]:
			continue
		var look := Vector2.ZERO
		if p["state"] == "turn":
			look = Vector2(signf(ME_X - p["x"]) * 0.5, 0)
		elif p["state"] == "look":
			look = Vector2(signf(ME_X - p["x"]), 0.2)
		var mood := "green" if stink >= p["tol"] * 0.75 else "smile"
		if p["state"] == "look":
			mood = "frown" if releasing else "o"
		Art.person(self, Vector2(p["x"], 600), 1.6, p["col"], p["skin"], {"look": look, "mood": mood, "hair": p["hair"]})
		if p["state"] == "turn":
			Art.text(self, Vector2(p["x"], 210), "?", 54, Color(1, 0.9, 0.2), true, 8)
		elif p["state"] == "look":
			Art.text(self, Vector2(p["x"], 210), "!!" if releasing else "!", 54, Color(1, 0.3, 0.2) if releasing else Color(1, 0.6, 0.2), true, 8)
	Art.squelch(self, Vector2(ME_X, 610), 1.65, {"mood": "o" if releasing else "smile", "look": Vector2(0, -0.6) if releasing else Vector2.ZERO})
	# stink haze
	draw_rect(BOX, Color(0.55, 0.75, 0.2, stink / 100.0 * 0.4))
	# doors
	var dw := BOX.size.x * 0.5 * (1.0 - doors)
	if doors > 0.0:
		draw_rect(Rect2(BOX.position.x, BOX.position.y, dw, BOX.size.y), Color(0.55, 0.57, 0.6))
		draw_rect(Rect2(BOX.end.x - dw, BOX.position.y, dw, BOX.size.y), Color(0.55, 0.57, 0.6))


func draw_hud() -> void:
	if state != "play":
		return
	Art.meter(self, Rect2(20, 20, 300, 34), pressure / 100.0, Color(0.9, 0.5, 0.2), "PRESSURE")
	Art.meter(self, Rect2(340, 20, 260, 34), stink / 100.0, Art.GAS, "STINK")
	Art.meter(self, Rect2(620, 20, 300, 34), suspicion / 100.0, Color(0.95, 0.25, 0.25), "SUSPICION")
	Art.text(self, Vector2(1100, 48), "Passengers: %d" % _count_here(), 24, Color.WHITE, true, 6)
	Art.text(self, Vector2(640, 705), "HOLD to release silently — not while anyone's looking!", 20, Color(1, 1, 1, 0.75), true, 5)
