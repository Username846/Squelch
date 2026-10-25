extends LevelBase
## Crime #1: Musical chairs. Foul every chair before the music stops.

const C := Vector2(640, 430)
const CHAIR_R := Vector2(170, 105)
const KID_R := Vector2(290, 185)
const ROUNDS := [[4, 8.0], [5, 7.0], [6, 6.5]]
const CAKE := Vector2(1130, 250)

var round_i := 0
var phase := "wait"  # music, rush, judge, wait
var phase_t := 0.0
var chairs: Array = []
var kids: Array = []
var fart_cd := 0.0
var cake_lit := true


func music_name() -> String:
	return "party"


func uses_pointer_move() -> bool:
	return true


func setup() -> void:
	level_id = "party"
	pointer_anchor = Vector2(0, -40)
	pp = Vector2(640, 660)
	_make_round()


func intro_lines() -> Array:
	return [
		["Narrator", "Crime number one. Little Tammy's seventh birthday party."],
		["Squelch", "Musical chairs. The purest game of childhood. Ha. Not for long."],
		["Squelch", "While the music plays, I fart on every single chair. When it stops... they sit."],
		["Narrator", "Hold the mouse or your finger where you want to walk, or use the arrow keys. Next to a chair, hit the FART button or SPACE. Foul them all before the music stops!"],
	]


func win_lines() -> Array:
	return [
		["Birthday Girl", "Mommy! Every chair smells like old eggs!"],
		["Mom", "Who invited the man in the trench coat?!"],
		["Squelch", "Happy birthday, Tammy. That one was on the house."],
	]


func _make_round() -> void:
	var n: int = ROUNDS[round_i][0]
	chairs.clear()
	for i in n:
		var a := TAU * i / n - PI / 2
		chairs.append({"pos": C + Vector2(cos(a) * CHAIR_R.x, sin(a) * CHAIR_R.y), "foul": false, "kid": -1})
	kids.clear()
	for i in n + 1:
		kids.append({"a": TAU * i / (n + 1), "pos": Vector2.ZERO, "chair": -1, "col": Art.CLOTHES[i % Art.CLOTHES.size()],
			"skin": Art.SKIN[(i * 3) % Art.SKIN.size()], "hair": Art.HAIR[(i * 2) % 4], "mood": "smile", "walk": 0.0})
	for k: Dictionary in kids:
		k["pos"] = C + Vector2(cos(k["a"]) * KID_R.x, sin(k["a"]) * KID_R.y)


func start_play() -> void:
	_start_music_phase()


func _start_music_phase() -> void:
	phase = "music"
	phase_t = ROUNDS[round_i][1]
	Game.play_music("party")
	pop_text("Round %d!" % (round_i + 1), Vector2(640, 140), Color(1, 0.9, 0.3), 44)


func play_process(delta: float) -> void:
	fart_cd -= delta
	phase_t -= delta
	match phase:
		"music":
			move_player(delta, 300.0, Rect2(60, 160, 1160, 520))
			for k: Dictionary in kids:
				k["a"] += delta * 0.55
				k["pos"] = C + Vector2(cos(k["a"]) * KID_R.x, sin(k["a"]) * KID_R.y)
				k["walk"] += delta * 10.0
				# kids shove you if you get in their way
				var d: Vector2 = pp - k["pos"]
				if d.length() < 36.0:
					pp += d.normalized() * (36.0 - d.length())
					pp = pp.clamp(Vector2(60, 160), Vector2(1220, 680))
			if Input.is_action_just_pressed("fart") and fart_cd <= 0.0:
				_do_fart()
			if phase_t <= 0.0:
				_stop_music()
		"rush":
			var all_seated := true
			for k: Dictionary in kids:
				if k["chair"] >= 0:
					var target: Vector2 = chairs[k["chair"]]["pos"]
					k["pos"] = k["pos"].move_toward(target, delta * 420.0)
					k["walk"] += delta * 16.0
					if k["pos"].distance_to(target) > 2.0:
						all_seated = false
			if all_seated or phase_t <= 0.0:
				_judge()
		"judge":
			if phase_t <= 0.0:
				if _all_foul():
					round_i += 1
					if round_i >= ROUNDS.size():
						win()
						return
					_make_round()
					_start_music_phase()
				else:
					_make_round()
					_start_music_phase()


func _do_fart() -> void:
	fart_cd = 0.3
	Game.fart()
	puff(pp + Vector2(0, -30), 5)
	if cake_lit and pp.distance_to(CAKE + Vector2(0, 40)) < 70.0:
		cake_lit = false
		puff(CAKE + Vector2(0, -40), 8, Art.GAS, 30)
		pop_text("whoosh!", CAKE + Vector2(0, -80))
		found_egg()
	for c: Dictionary in chairs:
		if not c["foul"] and pp.distance_to(c["pos"] + Vector2(0, -10)) < 62.0:
			c["foul"] = true
			Game.sfx("chair", randf_range(0.9, 1.2))
			pop_text("FOULED!", c["pos"] + Vector2(0, -70), Art.GAS)
			return


func _all_foul() -> bool:
	for c: Dictionary in chairs:
		if not c["foul"]:
			return false
	return true


func _stop_music() -> void:
	phase = "rush"
	phase_t = 2.5
	Game.pause_music(true)
	Game.sfx("gasp", 1.4)
	# each kid races to the nearest free chair
	var free := range(chairs.size())
	var order := range(kids.size())
	order.shuffle()
	for ki: int in order:
		if free.is_empty():
			break
		var k: Dictionary = kids[ki]
		var best: int = free[0]
		for ci: int in free:
			if k["pos"].distance_to(chairs[ci]["pos"]) < k["pos"].distance_to(chairs[best]["pos"]):
				best = ci
		free.erase(best)
		k["chair"] = best
		chairs[best]["kid"] = ki


func _judge() -> void:
	phase = "judge"
	phase_t = 2.6
	var fouled := 0
	for c: Dictionary in chairs:
		if c["kid"] < 0:
			continue
		var k: Dictionary = kids[c["kid"]]
		if c["foul"]:
			k["mood"] = "green"
			fouled += 1
			puff(c["pos"] + Vector2(0, -40), 4)
		else:
			k["mood"] = "grin"
	if _all_foul():
		Game.sfx("boo", 1.6, -2.0)
		Game.speak("Ewwwww!", "Kid")
		pop_text("EWWWWW!", Vector2(640, 250), Art.GAS, 60)
		shake = 0.4
	else:
		Game.sfx("buzzer")
		pop_text("%d chair(s) still clean! Again!" % (chairs.size() - fouled), Vector2(640, 250), Color(1, 0.5, 0.4), 40)


func draw_level() -> void:
	# room
	draw_rect(Rect2(0, 0, 1280, 720), Color(1.0, 0.86, 0.75))
	for i in 16:
		draw_rect(Rect2(i * 80, 0, 40, 190), Color(1.0, 0.78, 0.7))
	draw_rect(Rect2(0, 190, 1280, 530), Color(0.72, 0.5, 0.35))
	for i in 9:
		draw_line(Vector2(0, 220 + i * 60), Vector2(1280, 220 + i * 60), Color(0.65, 0.44, 0.3), 2)
	# banner
	for i in 12:
		var x := 180 + i * 75
		draw_colored_polygon(PackedVector2Array([Vector2(x, 40), Vector2(x + 60, 40), Vector2(x + 30, 85)]), Art.CLOTHES[i % 7])
	draw_line(Vector2(170, 40), Vector2(1110, 40), Color(0.5, 0.3, 0.2), 3)
	Art.text(self, Vector2(640, 130), "HAPPY 7th BIRTHDAY TAMMY!", 40, Color(0.9, 0.2, 0.5), true, 8, Color.WHITE)
	# balloons
	for b in [Vector2(80, 120), Vector2(140, 90), Vector2(1200, 110)]:
		draw_line(b, b + Vector2(0, 120), Color(0.4, 0.4, 0.4), 1)
		Art.ellipse(self, b, 26, 32, Color(0.9, 0.3, 0.4) if b.x < 120 else Color(0.3, 0.6, 0.95))
	# cake table
	draw_rect(Rect2(CAKE + Vector2(-80, 20), Vector2(160, 14)), Color(0.95, 0.95, 0.95))
	draw_rect(Rect2(CAKE + Vector2(-70, 34), Vector2(10, 60)), Color(0.5, 0.35, 0.25))
	draw_rect(Rect2(CAKE + Vector2(60, 34), Vector2(10, 60)), Color(0.5, 0.35, 0.25))
	Art.rrect(self, Rect2(CAKE + Vector2(-50, -30), Vector2(100, 50)), Color(1, 0.75, 0.85), 8)
	Art.rrect(self, Rect2(CAKE + Vector2(-50, -30), Vector2(100, 14)), Color(1, 1, 1), 6)
	for i in 7:
		var cx := CAKE.x - 36 + i * 12
		draw_line(Vector2(cx, CAKE.y - 30), Vector2(cx, CAKE.y - 48), Color(0.4, 0.7, 1.0), 4)
		if cake_lit:
			draw_circle(Vector2(cx, CAKE.y - 53 + sin(t * 12 + i) * 1.5), 4, Color(1, 0.75, 0.2))
	# chairs & kids, sorted by depth
	var items: Array = []
	for c: Dictionary in chairs:
		items.append([c["pos"].y, "chair", c])
	for k: Dictionary in kids:
		items.append([k["pos"].y + 1.0, "kid", k])
	items.append([pp.y + 0.5, "me", null])
	items.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for it: Array in items:
		match it[1]:
			"chair":
				var c: Dictionary = it[2]
				Art.chair(self, c["pos"], 1.0, Color(0.55, 0.75, 0.3) if c["foul"] else Color(0.85, 0.3, 0.35))
				if c["foul"]:
					for j in 3:
						var wv := Vector2(sin(t * 3 + j * 2) * 8, -j * 14)
						draw_line(c["pos"] + Vector2(-10 + j * 10, -40) + wv, c["pos"] + Vector2(-6 + j * 10, -52) + wv, Color(0.5, 0.75, 0.2, 0.8), 3)
			"kid":
				var k: Dictionary = it[2]
				var sitting: bool = phase in ["judge"] and k["chair"] >= 0 and k["mood"] != "green"
				var jump: float = -absf(sin(t * 14)) * 30 if k["mood"] == "green" else 0.0
				Art.person(self, k["pos"] + Vector2(0, jump - (8 if sitting else 0)), 0.7, k["col"], k["skin"],
					{"hat": "party", "hair": k["hair"], "walk": k["walk"], "sit": sitting, "mood": k["mood"], "arms_up": k["mood"] == "green"})
			"me":
				Art.squelch(self, pp, 0.85, {"hat": "party", "walk": pwalk if pmoving else 0.0, "facing": pfacing})


func draw_hud() -> void:
	if state != "play":
		return
	var n_foul := 0
	for c: Dictionary in chairs:
		if c["foul"]:
			n_foul += 1
	Art.rrect(self, Rect2(20, 650, 360, 52), Color(0, 0, 0, 0.5), 10)
	Art.text(self, Vector2(200, 686), "Round %d/3   Chairs fouled: %d/%d" % [round_i + 1, n_foul, chairs.size()], 22, Color.WHITE)
	if phase == "music":
		Art.text(self, Vector2(640, 195), "MUSIC PLAYING...  %.1f" % maxf(phase_t, 0.0), 30, Color(1, 1, 1), true, 6)
	elif phase == "rush":
		Art.text(self, Vector2(640, 195), "THE MUSIC STOPPED!", 34, Color(1, 0.4, 0.4), true, 6)
