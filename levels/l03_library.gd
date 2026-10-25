extends LevelBase
## Crime #3: Crop-dust every reader in the library without the librarian seeing you.

const SHELVES := [
	Rect2(200, 140, 40, 220), Rect2(420, 90, 260, 36), Rect2(420, 160, 40, 170),
	Rect2(700, 420, 260, 36), Rect2(860, 130, 40, 200), Rect2(1040, 300, 140, 36), Rect2(180, 520, 180, 36),
]
const READERS := [Vector2(330, 240), Vector2(570, 230), Vector2(570, 590), Vector2(1010, 210), Vector2(1150, 440)]
const PATH := [Vector2(300, 440), Vector2(640, 380), Vector2(980, 380), Vector2(980, 600), Vector2(500, 640)]
const OLD_MAN := Vector2(90, 650)
const START := Vector2(1200, 670)
const FOV := 70.0
const RANGE := 240.0

var lib_pos := PATH[0]
var lib_dir := 0.0
var lib_target := 1
var lib_wait := 0.0
var lib_investigate := 0.0
var lib_look_at := Vector2.ZERO
var dusted: Array = [false, false, false, false, false]
var lives := 3
var invuln := 0.0
var fart_cd := 0.0
var old_awake := false


func music_name() -> String:
	return "library"


func uses_pointer_move() -> bool:
	return true


func action_pos() -> Vector2:
	return Vector2(1180, 150)


func setup() -> void:
	level_id = "library"
	pp = START
	pfacing = -1.0


func intro_lines() -> Array:
	return [
		["Narrator", "Crime number three. The City Library. Silence is golden."],
		["Librarian", "Shhhh."],
		["Squelch", "Silence is golden. But my farts? My farts are silent... and green."],
		["Narrator", "Sneak up to all five readers and hit FART (or SPACE) to crop-dust them. Hold the mouse or your finger to walk, or use the arrow keys. Stay out of the librarian's sight, and remember: she can hear a fart nearby."],
	]


func win_lines() -> Array:
	return [
		["Librarian", "Why does the entire non-fiction section smell like a swamp?"],
		["Squelch", "Shhhh."],
	]


func play_process(delta: float) -> void:
	fart_cd -= delta
	invuln -= delta
	move_player(delta, 210.0, Rect2(30, 80, 1220, 615), SHELVES)
	_librarian(delta)
	if Input.is_action_just_pressed("fart") and fart_cd <= 0.0:
		_fart()
	if invuln <= 0.0 and can_see(lib_pos, lib_dir, FOV, RANGE, pp + Vector2(0, -20), SHELVES):
		_caught()


func _librarian(delta: float) -> void:
	if lib_investigate > 0.0:
		lib_investigate -= delta
		lib_dir = lerp_angle(lib_dir, (lib_look_at - lib_pos).angle(), delta * 6.0)
		return
	if lib_wait > 0.0:
		lib_wait -= delta
		lib_dir += sin(t * 2.0) * delta * 1.2
		return
	var target: Vector2 = PATH[lib_target]
	var d := target - lib_pos
	if d.length() < 3.0:
		lib_target = (lib_target + 1) % PATH.size()
		lib_wait = 1.3
		return
	lib_dir = lerp_angle(lib_dir, d.angle(), delta * 5.0)
	lib_pos = lib_pos.move_toward(target, delta * 85.0)


func _fart() -> void:
	fart_cd = 0.6
	Game.fart("", -1.0, -6.0)
	puff(pp + Vector2(0, -20), 5, Art.GAS, 22, 14, -10)
	if lib_pos.distance_to(pp) < 330.0:
		lib_investigate = 2.2
		lib_look_at = pp
		pop_text("?", lib_pos + Vector2(0, -110), Color(1, 0.9, 0.2), 50)
	for i in READERS.size():
		if not dusted[i] and pp.distance_to(READERS[i]) < 80.0:
			dusted[i] = true
			pop_text("*cough*", READERS[i] + Vector2(0, -90), Art.GAS)
			Game.sfx("gasp", randf_range(0.8, 1.2))
	if not old_awake and pp.distance_to(OLD_MAN) < 90.0:
		old_awake = true
		Game.speak("Mmm. Ah. A vintage. Nineteen sixty three.", "Old Man")
		pop_text("...a vintage.", OLD_MAN + Vector2(40, -110), Color(1, 0.9, 0.6))
		found_egg()
	if not dusted.has(false):
		win()


func _caught() -> void:
	lives -= 1
	Game.speak("Shhhhh! Out!", "Librarian")
	Game.sfx("buzzer")
	pop_text("SHHHHH!", lib_pos + Vector2(0, -110), Color(1, 0.4, 0.4), 50)
	shake = 0.4
	if lives <= 0:
		lose("The librarian spotted you and banned you for life. And the afterlife.")
		return
	pp = START
	invuln = 1.5


func draw_level() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.45, 0.2, 0.2))
	for y in range(0, 720, 48):
		for x in range(0, 1280, 48):
			if (x / 48 + y / 48) % 2 == 0:
				draw_rect(Rect2(x, y, 48, 48), Color(0.42, 0.18, 0.18))
	draw_rect(Rect2(0, 0, 1280, 70), Color(0.3, 0.18, 0.12))
	# old man's corner
	Art.rrect(self, Rect2(OLD_MAN + Vector2(-50, -90), Vector2(100, 100)), Color(0.35, 0.45, 0.3), 14)
	Art.person(self, OLD_MAN + Vector2(0, 0), 0.9, Color(0.5, 0.4, 0.3), Art.SKIN[0], {"sit": true, "mood": "o" if old_awake else "sleep", "bald": true})
	Art.rrect(self, Rect2(OLD_MAN + Vector2(-58, -50), Vector2(18, 60)), Color(0.3, 0.4, 0.25), 6)
	Art.rrect(self, Rect2(OLD_MAN + Vector2(40, -50), Vector2(18, 60)), Color(0.3, 0.4, 0.25), 6)
	if not old_awake:
		Art.text(self, OLD_MAN + Vector2(40 + sin(t) * 5, -100 - fmod(t * 10, 20)), "z", 26, Color(1, 1, 1, 0.7))
	# shelves
	for r: Rect2 in SHELVES:
		draw_rect(r, Color(0.35, 0.2, 0.1))
		var horiz := r.size.x > r.size.y
		var n := int((r.size.x if horiz else r.size.y) / 9)
		for i in n:
			var c := Color.from_hsv(fmod(i * 0.37 + r.position.x * 0.01, 1.0), 0.55, 0.65)
			if horiz:
				draw_rect(Rect2(r.position.x + 2 + i * 9, r.position.y + 4, 7, r.size.y - 8), c)
			else:
				draw_rect(Rect2(r.position.x + 4, r.position.y + 2 + i * 9, r.size.x - 8, 7), c)
	# readers
	for i in READERS.size():
		var rp: Vector2 = READERS[i]
		Art.rrect(self, Rect2(rp + Vector2(-50, -8), Vector2(100, 34)), Color(0.55, 0.35, 0.2), 6)
		Art.person(self, rp, 0.75, Art.CLOTHES[i], Art.SKIN[(i * 2) % 5], {"sit": true, "mood": "green" if dusted[i] else "smile", "glasses": i % 2 == 0, "hair": Art.HAIR[i % 5], "look": Vector2(0, 1)})
		draw_rect(Rect2(rp + Vector2(-20, -12), Vector2(40, 10)), Color(0.95, 0.95, 0.9))
		if dusted[i]:
			draw_arc(rp + Vector2(0, -60), 28 + sin(t * 4) * 3, PI, TAU, 12, Color(0.6, 0.85, 0.2, 0.6), 4)
	# librarian vision
	draw_cone(lib_pos + Vector2(0, -20), lib_dir, FOV, RANGE, SHELVES, Color(1, 1, 0.5, 0.18) if lib_investigate <= 0.0 else Color(1, 0.4, 0.3, 0.25))
	Art.person(self, lib_pos + Vector2(0, 30), 0.85, Color(0.35, 0.3, 0.5), Art.SKIN[1], {"glasses": true, "mood": "frown", "hair": Art.HAIR[4], "look": Vector2.from_angle(lib_dir), "walk": t * 6 if lib_wait <= 0 else 0.0, "dress": true})
	draw_circle(lib_pos + Vector2(0, -100), 12, Art.HAIR[4])
	var me_alpha := 0.4 if invuln > 0.0 and int(t * 10) % 2 == 0 else 1.0
	modulate = Color(1, 1, 1)
	if me_alpha > 0.5:
		Art.squelch(self, pp + Vector2(0, 30), 0.8, {"walk": pwalk if pmoving else 0.0, "facing": pfacing})


func draw_hud() -> void:
	if state != "play":
		return
	var n := dusted.count(true)
	Art.text(self, Vector2(200, 46), "Readers dusted: %d/5" % n, 28, Color.WHITE, true, 6)
	Art.text(self, Vector2(640, 46), "Lives: %d" % lives, 28, Color(1, 0.5, 0.5), true, 6)
	Art.text(self, Vector2(1000, 46), "Hold to walk, FART to dust", 20, Color(1, 1, 1, 0.7), true, 4)
