extends LevelBase
## Crime #10: Break into police HQ, steal back the Golden Bean, and get out.
## Drop gas clouds to knock out guards.

const WALLS := [
	Rect2(0, 60, 1280, 20), Rect2(0, 700, 1280, 20), Rect2(0, 60, 20, 660), Rect2(1260, 60, 20, 660),
	Rect2(220, 80, 20, 420), Rect2(220, 600, 20, 100), Rect2(240, 300, 300, 20), Rect2(520, 160, 20, 160),
	Rect2(440, 450, 20, 250), Rect2(640, 80, 20, 300), Rect2(640, 480, 20, 220), Rect2(660, 300, 260, 20),
	Rect2(860, 450, 20, 250), Rect2(1000, 80, 20, 300), Rect2(1000, 480, 260, 20),
	Rect2(1080, 500, 20, 100), Rect2(1080, 660, 20, 40),
]
## Looks exactly like a wall. Isn't one.
const FAKE_WALL := Rect2(1080, 600, 20, 60)
const STASH := Rect2(1100, 500, 160, 200)
const START := Vector2(100, 640)
const EXIT := Rect2(20, 580, 120, 120)
const BEAN := Vector2(1160, 200)
const FOV := 62.0
const RANGE := 200.0

var guards: Array = []
var clouds: Array = []  # {pos, t}
var charges := 3
var recharge := 0.0
var has_bean := false
var lives := 3
var invuln := 0.0
var stash_found := false


func music_name() -> String:
	return "heist"


func uses_pointer_move() -> bool:
	return true


func action_pos() -> Vector2:
	return Vector2(960, 620)


func action_text() -> String:
	return "GAS"


func setup() -> void:
	level_id = "heist"
	pp = START
	var paths := [
		[Vector2(280, 390), Vector2(600, 390)],
		[Vector2(700, 140), Vector2(960, 140), Vector2(960, 260), Vector2(700, 260)],
		[Vector2(700, 405), Vector2(960, 405)],
		[Vector2(1060, 140), Vector2(1220, 140), Vector2(1220, 420), Vector2(1060, 420)],
		[Vector2(300, 120), Vector2(300, 250), Vector2(480, 250), Vector2(480, 120)],
	]
	for p: Array in paths:
		guards.append({"pos": p[0], "path": p, "i": 1, "dir": 0.0, "ko": 0.0, "wait": 0.0, "speed": randf_range(65, 85)})


func intro_lines() -> Array:
	return [
		["Narrator", "Crime number ten. Police Headquarters. The Evidence Room."],
		["Squelch", "They took my Golden Bean. A family heirloom. Four generations of Squelches have eaten from it."],
		["Squelch", "Tonight, I take it back."],
		["Narrator", "Sneak to the evidence room in the top right, grab the Golden Bean, and return to the exit. Hold the mouse or your finger to walk. The GAS button (or SPACE) drops a gas cloud. Guards who walk into it pass out. Don't get seen!"],
	]


func win_lines() -> Array:
	return [
		["Squelch", "Come to papa, my precious little legume."],
		["Narrator", "Squelch escaped into the night with the Golden Bean. But somewhere, a very large nose was twitching."],
	]


func play_process(delta: float) -> void:
	invuln -= delta
	var blockers := WALLS.duplicate()
	move_player(delta, 200.0, Rect2(30, 90, 1220, 600), blockers)
	if not stash_found and STASH.has_point(pp):
		stash_found = true
		Game.speak("My old mugshots! I was so handsome.", "Squelch")
		pop_text("A secret stash of mugshots!", STASH.get_center() + Vector2(-120, -40), Color(1, 0.85, 0.3), 28)
		found_egg()
	# gas clouds
	recharge += delta
	if charges < 3 and recharge >= 7.0:
		charges += 1
		recharge = 0.0
	if Input.is_action_just_pressed("fart") and charges > 0:
		charges -= 1
		recharge = 0.0
		clouds.append({"pos": pp, "t": 5.0})
		Game.fart("fart_wet" if randf() < 0.5 else "fart2", -1.0, -3.0)
	for c: Dictionary in clouds:
		c["t"] -= delta
		if randf() < delta * 6.0:
			puff(c["pos"], 1, Art.GAS, 50, 20, -5)
	clouds = clouds.filter(func(c: Dictionary) -> bool: return c["t"] > 0.0)
	# guards
	for g: Dictionary in guards:
		if g["ko"] > 0.0:
			g["ko"] -= delta
			continue
		for c: Dictionary in clouds:
			if g["pos"].distance_to(c["pos"]) < 75.0:
				g["ko"] = 6.0
				Game.sfx("thud", 1.2)
				pop_text("Zzz", g["pos"] + Vector2(0, -60), Art.GAS)
		if g["ko"] > 0.0:
			continue
		var target: Vector2 = g["path"][g["i"]]
		var d: Vector2 = target - g["pos"]
		if g["wait"] > 0.0:
			g["wait"] -= delta
			g["dir"] += sin(t * 2.5) * delta * 1.4
		elif d.length() < 3.0:
			g["i"] = (g["i"] + 1) % g["path"].size()
			g["wait"] = 0.8
		else:
			g["dir"] = lerp_angle(g["dir"], d.angle(), delta * 6.0)
			g["pos"] = g["pos"].move_toward(target, delta * g["speed"])
		if invuln <= 0.0 and can_see(g["pos"], g["dir"], FOV, RANGE, pp, WALLS):
			_caught(g)
			return
	# bean & exit
	if not has_bean and pp.distance_to(BEAN) < 40.0:
		has_bean = true
		Game.sfx("coin")
		Game.sfx("siren", 1.0, -12.0)
		pop_text("GOT THE GOLDEN BEAN!", BEAN + Vector2(-60, -50), Color(1, 0.85, 0.2), 32)
	if has_bean and EXIT.has_point(pp):
		win()


func _caught(g: Dictionary) -> void:
	lives -= 1
	Game.speak(["Hey! Freeze!", "Intruder!", "Stop right there!"].pick_random(), "Guard")
	Game.sfx("buzzer")
	pop_text("SPOTTED!", g["pos"] + Vector2(0, -70), Color(1, 0.35, 0.35), 40)
	shake = 0.4
	if lives <= 0:
		lose("Spotted one too many times. The guards cuffed you right next to the evidence locker.")
		return
	pp = START
	invuln = 2.0
	has_bean = false


func draw_level() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.22, 0.24, 0.28))
	for y in range(80, 700, 40):
		draw_line(Vector2(20, y), Vector2(1260, y), Color(0.25, 0.27, 0.31), 1)
	for x in range(20, 1260, 40):
		draw_line(Vector2(x, 80), Vector2(x, 700), Color(0.25, 0.27, 0.31), 1)
	# rooms
	draw_rect(Rect2(1020, 80, 240, 400), Color(0.3, 0.25, 0.2))
	Art.text(self, Vector2(1140, 110), "EVIDENCE", 22, Color(1, 0.85, 0.5, 0.6))
	draw_rect(EXIT, Color(0.3, 0.8, 0.4, 0.25))
	Art.text(self, EXIT.get_center() + Vector2(0, -40), "EXIT", 22, Color(0.5, 1, 0.6, 0.8))
	# evidence shelves
	for k in 3:
		draw_rect(Rect2(1040 + k * 70, 300, 50, 30), Color(0.5, 0.4, 0.25))
	# the stash (only visible once you're inside)
	if stash_found or STASH.has_point(pp):
		draw_rect(STASH, Color(0.35, 0.3, 0.4))
		for k in 6:
			Art.rrect(self, Rect2(STASH.position + Vector2(14 + (k % 3) * 48, 20 + (k / 3) * 80), Vector2(40, 54)), Color(0.9, 0.9, 0.85), 3)
			Art.squelch(self, STASH.position + Vector2(34 + (k % 3) * 48, 70 + (k / 3) * 80), 0.32)
	# walls (the fake one too, drawn identically)
	for r: Rect2 in WALLS:
		draw_rect(r, Color(0.55, 0.57, 0.62))
	draw_rect(FAKE_WALL, Color(0.55, 0.57, 0.62))
	# bean
	if not has_bean:
		Art.ellipse(self, BEAN, 16 + sin(t * 4) * 2, 24, Color(1, 0.8, 0.2))
		draw_circle(BEAN + Vector2(-5, -8), 4, Color(1, 1, 0.8))
		Art.star(self, BEAN + Vector2(22, -24), 7 + sin(t * 6) * 3, Color(1, 1, 0.7))
	# clouds
	for c: Dictionary in clouds:
		draw_circle(c["pos"], 75, Color(0.55, 0.8, 0.2, 0.25 * clampf(c["t"], 0, 1)))
	# guards
	for g: Dictionary in guards:
		if g["ko"] <= 0.0:
			draw_cone(g["pos"], g["dir"], FOV, RANGE, WALLS, Color(1, 1, 0.5, 0.17))
			Art.person(self, g["pos"] + Vector2(0, 26), 0.6, Color(0.15, 0.2, 0.45), Art.SKIN[3], {"hat": "police", "look": Vector2.from_angle(g["dir"]), "walk": t * 8 if g["wait"] <= 0.0 else 0.0})
		else:
			draw_set_transform(g["pos"] + Vector2(0, 20), PI / 2, Vector2.ONE)
			Art.person(self, Vector2.ZERO, 0.6, Color(0.15, 0.2, 0.45), Art.SKIN[3], {"hat": "police", "mood": "sleep"})
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			Art.text(self, g["pos"] + Vector2(20, -30 - fmod(t * 15, 20)), "z", 22, Color.WHITE)
	# squelch
	if not (invuln > 0.0 and int(t * 10) % 2 == 0):
		Art.squelch(self, pp + Vector2(0, 26), 0.6, {"walk": pwalk if pmoving else 0.0, "facing": pfacing})
		if has_bean:
			Art.ellipse(self, pp + Vector2(18, -10), 8, 12, Color(1, 0.8, 0.2))


func draw_hud() -> void:
	if state != "play":
		return
	Art.text(self, Vector2(170, 44), "Gas clouds: %d/3" % charges, 26, Art.GAS, true, 6)
	Art.text(self, Vector2(470, 44), "Lives: %d" % lives, 26, Color(1, 0.5, 0.5), true, 6)
	Art.text(self, Vector2(870, 44), "Return to EXIT!" if has_bean else "Steal the Golden Bean (top right)", 24, Color(1, 0.9, 0.4), true, 6)
