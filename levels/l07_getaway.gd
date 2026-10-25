extends LevelBase
## Crime #7: Car chase! Dodge traffic, grab beans, fart-boost away from the cops.

const LANE_Y := [330.0, 450.0, 570.0]
const SHOULDER_Y := 680.0
const CAR_X := 300.0
const GOAL := 1600.0

var lane := 1
var car_y := 450.0
var dist := 0.0
var speed := 420.0
var gas := 60.0
var boost := 0.0
var police := 20.0
var hit_cd := 0.0
var spawn_t := 1.0
var obstacles: Array = []  # {x, lane, kind}
var road_off := 0.0
var shoulder_t := 0.0
var bigfoot := false
var bigfoot_x := 0.0


func music_name() -> String:
	return "getaway"


func action_pos() -> Vector2:
	return Vector2(1170, 160)


func action_text() -> String:
	return "BOOST"


func setup() -> void:
	level_id = "getaway"


func intro_lines() -> Array:
	return [
		["Narrator", "Crime number seven. The cops finally have Squelch's license plate. P-U-1."],
		["Officer", "Pull over! You're under arrest for... uh... the smell!"],
		["Squelch", "Arrest me? You'll have to catch me first. Bean-powered engine, engage!"],
		["Narrator", "Tap or click a lane to switch to it, or use UP and DOWN. BOOST (or SPACE) fires a fart boost: you smash through anything while boosting. Grab bean cans for more gas. Escape after 1600 meters!"],
	]


func win_lines() -> Array:
	return [
		["Officer", "We lost him, Chief. Every time we got close, we had to roll the windows down."],
		["Squelch", "Eat my dust. Well... it's not exactly dust."],
	]


func play_process(delta: float) -> void:
	hit_cd -= delta
	if Input.is_action_just_pressed("up"):
		lane = maxi(0, lane - 1)
	if Input.is_action_just_pressed("down"):
		lane = mini(3, lane + 1)
	var ty: float = SHOULDER_Y if lane == 3 else LANE_Y[lane]
	car_y = move_toward(car_y, ty, delta * 900.0)
	if Input.is_action_just_pressed("fart") and gas >= 25.0 and boost <= 0.0:
		gas -= 25.0
		boost = 1.6
		Game.fart("fart_huge", 1.3)
		shake = 0.3
	boost -= delta
	var on_shoulder := lane == 3
	var sp := speed * (1.8 if boost > 0.0 else 1.0) * (0.55 if on_shoulder else 1.0)
	dist += sp * delta / 10.0
	road_off = fmod(road_off + sp * delta, 80.0)
	if boost > 0.0:
		police -= delta * 14.0
		if randf() < delta * 30.0:
			puff(Vector2(CAR_X - 70, car_y + 10), 1, Art.GAS, 6, 14, 0)
	elif on_shoulder:
		police += delta * 9.0
	else:
		police -= delta * 1.5
	police = clampf(police, 0.0, 100.0)
	# shoulder secret
	if on_shoulder:
		shoulder_t += delta
		if shoulder_t > 3.0 and not bigfoot:
			bigfoot = true
			bigfoot_x = 1350.0
			Game.speak("Hrrrrmm. Nice car.", "Bigfoot")
			found_egg()
	if bigfoot:
		bigfoot_x -= sp * delta
	# obstacles
	spawn_t -= delta
	if spawn_t <= 0.0:
		spawn_t = randf_range(0.45, 0.9) * (1.0 - minf(dist / GOAL, 1.0) * 0.35)
		var r := randf()
		var kind := "can" if r < 0.2 else ("cone" if r < 0.5 else ("oil" if r < 0.65 else "car"))
		obstacles.append({"x": 1380.0, "lane": randi() % 3, "kind": kind, "hit": false, "col": Art.CLOTHES[randi() % 7]})
	for o: Dictionary in obstacles:
		var vx := sp + (-160.0 if o["kind"] == "car" else 0.0)
		o["x"] -= vx * delta
		if o["hit"] or on_shoulder:
			continue
		if o["lane"] == lane and absf(o["x"] - CAR_X) < 70.0 and absf(car_y - LANE_Y[lane]) < 40.0:
			o["hit"] = true
			if o["kind"] == "can":
				gas = minf(100.0, gas + 30.0)
				Game.sfx("coin")
				pop_text("+GAS", Vector2(CAR_X, car_y - 60), Art.GAS)
			elif boost > 0.0:
				Game.sfx("crash", 1.4, -4.0)
				pop_text("SMASH!", Vector2(CAR_X + 60, car_y - 60), Color(1, 0.8, 0.3))
			elif hit_cd <= 0.0:
				hit_cd = 1.0
				police += 22.0
				shake = 0.5
				Game.sfx("crash")
				pop_text("CRASH!", Vector2(CAR_X, car_y - 60), Color(1, 0.4, 0.3), 40)
	obstacles = obstacles.filter(func(o: Dictionary) -> bool: return o["x"] > -150.0)
	if police >= 100.0:
		Game.sfx("siren")
		lose("The cops boxed you in. Should've eaten more beans.")
	elif dist >= GOAL:
		win()


func _unhandled_input(event: InputEvent) -> void:
	super(event)
	if state == "play" and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var y: float = event.position.y
		if y > 640.0:
			lane = 3
		elif y > 250.0:
			lane = clampi(roundi((y - LANE_Y[0]) / 120.0), 0, 2)


func draw_level() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.3, 0.55, 0.25))
	# skyline strip
	draw_rect(Rect2(0, 0, 1280, 250), Color(0.55, 0.75, 0.95))
	for i in 12:
		var bx := fposmod(i * 140.0 - dist * 2.0, 1680.0) - 140.0
		draw_rect(Rect2(bx, 120 - (i % 3) * 30, 110, 130 + (i % 3) * 30), Color(0.45, 0.5, 0.6))
	# road
	draw_rect(Rect2(0, 270, 1280, 360), Color(0.25, 0.25, 0.28))
	draw_rect(Rect2(0, 266, 1280, 6), Color.WHITE)
	draw_rect(Rect2(0, 628, 1280, 6), Color.WHITE)
	for k in 2:
		var y := 390.0 + k * 120.0
		var x := -road_off
		while x < 1280:
			draw_rect(Rect2(x, y - 3, 44, 6), Color(1, 0.9, 0.3))
			x += 80
	# shoulder gravel
	draw_rect(Rect2(0, 634, 1280, 86), Color(0.5, 0.45, 0.35))
	for i in 30:
		draw_circle(Vector2(fposmod(i * 97.0 - dist * 10.0, 1280.0), 650 + (i * 37) % 60), 3, Color(0.4, 0.35, 0.28))
	if bigfoot and bigfoot_x > -100:
		Art.person(self, Vector2(bigfoot_x, 720), 1.6, Color(0.4, 0.25, 0.12), Color(0.5, 0.32, 0.18), {"arms_up": true, "hair": Color(0.4, 0.25, 0.12), "mood": "grin"})
	# obstacles
	for o: Dictionary in obstacles:
		if o["hit"] and o["kind"] != "car":
			continue
		var p := Vector2(o["x"], LANE_Y[o["lane"]])
		match o["kind"]:
			"cone":
				draw_colored_polygon(PackedVector2Array([p + Vector2(0, -38), p + Vector2(22, 22), p + Vector2(-22, 22)]), Color(1, 0.5, 0.1))
				draw_rect(Rect2(p + Vector2(-12, -6), Vector2(24, 8)), Color.WHITE)
			"oil":
				Art.ellipse(self, p + Vector2(0, 10), 48, 18, Color(0.08, 0.06, 0.1))
			"can":
				Art.rrect(self, Rect2(p + Vector2(-18, -28), Vector2(36, 52)), Color(0.85, 0.3, 0.2), 6)
				Art.text(self, p + Vector2(0, 6), "BEANS", 11, Color.WHITE)
			"car":
				_car(p, o["col"], o["hit"])
	# player car
	var shakey := sin(t * 40) * 2 if lane == 3 else 0.0
	_car(Vector2(CAR_X, car_y + shakey), Art.SQUELCH_COAT, false, true)
	if boost > 0.0:
		draw_colored_polygon(PackedVector2Array([Vector2(CAR_X - 70, car_y - 14), Vector2(CAR_X - 170 - randf() * 40, car_y), Vector2(CAR_X - 70, car_y + 14)]), Color(0.65, 0.9, 0.3, 0.8))
	# police
	var px := 40.0 + (police / 100.0) * (CAR_X - 170.0)
	_car(Vector2(px, car_y), Color(0.1, 0.1, 0.15), false, false, true)


func _car(p: Vector2, col: Color, wrecked: bool, me := false, cop := false) -> void:
	var body := Rect2(p + Vector2(-65, -26), Vector2(130, 52))
	Art.rrect(self, body, col.darkened(0.3) if wrecked else col, 14)
	Art.rrect(self, Rect2(p + Vector2(-25, -22), Vector2(60, 44)), Color(0.6, 0.8, 0.95, 0.9), 10)
	for wx in [-40, 40]:
		draw_rect(Rect2(p + Vector2(wx - 14, -34), Vector2(28, 10)), Color(0.05, 0.05, 0.05))
		draw_rect(Rect2(p + Vector2(wx - 14, 24), Vector2(28, 10)), Color(0.05, 0.05, 0.05))
	if me:
		draw_circle(p + Vector2(5, 0), 13, Color(0.93, 0.82, 0.66))
		draw_rect(Rect2(p + Vector2(-12, -10), Vector2(34, 7)), Color(0.12, 0.08, 0.14))
	if cop:
		Art.text(self, p + Vector2(-35, 8), "POLICE", 16, Color.WHITE, true)
		draw_rect(Rect2(p + Vector2(-8, -30), Vector2(16, 8)), Color(1, 0, 0) if int(t * 6) % 2 == 0 else Color(0, 0.4, 1))
	if wrecked:
		Art.cloud(self, p + Vector2(0, -30), 20, Color(0.3, 0.3, 0.3, 0.7))


func draw_hud() -> void:
	if state != "play":
		return
	Art.meter(self, Rect2(20, 16, 380, 32), dist / GOAL, Color(0.4, 0.7, 1.0), "ESCAPE  %d / %d m" % [int(dist), int(GOAL)])
	Art.meter(self, Rect2(420, 16, 260, 32), gas / 100.0, Art.GAS, "GAS")
	Art.meter(self, Rect2(700, 16, 300, 32), police / 100.0, Color(1, 0.3, 0.3), "COPS")
