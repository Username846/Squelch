extends LevelBase
## Crime #4: Hot yoga rhythm game. Every pose comes with a perfectly timed toot.

const BPM := 90.0
const LANES := [Vector2(800, 0), Vector2(910, 0), Vector2(1020, 0), Vector2(1130, 0)]
const LANE_KEYS := [["left", KEY_LEFT, KEY_A], ["down", KEY_DOWN, KEY_S], ["up", KEY_UP, KEY_W], ["right", KEY_RIGHT, KEY_D]]
const LANE_COL := [Color(0.95, 0.4, 0.5), Color(0.4, 0.7, 1.0), Color(0.5, 0.9, 0.4), Color(1.0, 0.8, 0.3)]
const HIT_Y := 600.0
const TRAVEL := 1.6
const GONG := Vector2(110, 250)
const POSES := ["Warrior", "Downward Dog", "Tree", "Cobra", "Happy Baby", "Lotus"]

var notes: Array = []  # {time, lane, state}
var clock := -1.0
var hits := 0
var misses := 0
var combo := 0
var pose := 0
var pose_flash := 0.0
var lane_flash := [0.0, 0.0, 0.0, 0.0]
var judge_text := ""
var judge_t := 0.0
var gonged := false
var class_glare := 0.0
var song_end := 0.0


func music_name() -> String:
	return "yoga"


func setup() -> void:
	level_id = "yoga"
	var beat := 60.0 / BPM
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var b := 4.0
	while b < 60.0:
		var lane := rng.randi() % 4
		notes.append({"time": b * beat, "lane": lane, "state": "live"})
		var r := rng.randf()
		if b > 20.0 and r < 0.25:
			notes.append({"time": (b + 0.5) * beat, "lane": (lane + 1 + rng.randi() % 3) % 4, "state": "live"})
		b += 2.0 if b < 12.0 and r < 0.5 else 1.0
	song_end = (b + 3.0) * beat


func intro_lines() -> Array:
	return [
		["Narrator", "Crime number four. Hot yoga with Yogi Breeze. Ninety-five degrees. No windows."],
		["Yogi Breeze", "Breathe in... and breathe out. Let everything... release."],
		["Squelch", "If you insist."],
		["Narrator", "When a note reaches the line, tap or click its circle, or press the matching ARROW key. Hit seventy percent to keep the class guessing!"],
	]


func win_lines() -> Array:
	return [
		["Yogi Breeze", "Namaste. And also... what on earth was that smell?"],
		["Squelch", "That, my friend, was my inner peace leaving my body."],
	]


func uses_action_button() -> bool:
	return false


func start_play() -> void:
	Game.play_music("yoga", true)
	clock = 0.0


func play_process(delta: float) -> void:
	clock += delta
	for i in 4:
		lane_flash[i] = maxf(0.0, lane_flash[i] - delta * 4.0)
	judge_t -= delta
	pose_flash -= delta
	class_glare -= delta
	for n: Dictionary in notes:
		if n["state"] == "live" and clock - n["time"] > 0.2:
			n["state"] = "miss"
			_miss()
	for i in 4:
		if Input.is_action_just_pressed(LANE_KEYS[i][0]):
			_press(i)
	if clock > song_end:
		var total := notes.size()
		if float(hits) / total >= 0.7:
			win()
		else:
			lose("Only %d%% of your toots landed on the beat. The class grew suspicious." % int(100.0 * hits / total))


func _unhandled_input(event: InputEvent) -> void:
	super(event)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = event.position
		if not gonged and p.distance_to(GONG) < 60.0:
			gonged = true
			Game.sfx("gong")
			Game.fart("fart_huge", 1.0)
			pop_text("OMMMMMMM", GONG + Vector2(160, -40), Art.GAS, 44)
			for i in 6:
				puff(Vector2(260 + i * 90, 560), 4)
			found_egg()
			return

	# lanes: a real mouse click or any finger (so two-note chords work on touch screens)
	var lane_press: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION)
	if lane_press and state == "play":
		var lp: Vector2 = event.position
		for i in 4:
			if absf(lp.x - LANES[i].x) < 55.0 and lp.y > 380.0:
				_press(i)


func _press(lane: int) -> void:
	lane_flash[lane] = 1.0
	var best: Dictionary = {}
	var best_d := 999.0
	for n: Dictionary in notes:
		if n["state"] == "live" and n["lane"] == lane:
			var d := absf(clock - n["time"])
			if d < best_d:
				best_d = d
				best = n
	if best.is_empty() or best_d > 0.2:
		Game.sfx("fart_tiny", 0.7, -8.0)
		return
	best["state"] = "hit"
	hits += 1
	combo += 1
	judge_text = "PERFECT!" if best_d < 0.08 else "GOOD"
	judge_t = 0.6
	Game.sfx("tuba%d" % [0, 2, 3, 4][lane], 1.0 if best_d < 0.08 else 0.95)
	puff(Vector2(470, 520), 3)
	if combo % 4 == 0:
		pose = (pose + 1) % POSES.size()
		pose_flash = 1.2


func _miss() -> void:
	misses += 1
	combo = 0
	judge_text = "MISS"
	judge_t = 0.5
	class_glare = 0.8


func draw_level() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.95, 0.8, 0.6))
	draw_rect(Rect2(0, 470, 700, 250), Color(0.8, 0.6, 0.4))
	# gong
	draw_line(GONG + Vector2(-60, -70), GONG + Vector2(-60, 120), Color(0.4, 0.25, 0.1), 8)
	draw_line(GONG + Vector2(60, -70), GONG + Vector2(60, 120), Color(0.4, 0.25, 0.1), 8)
	draw_line(GONG + Vector2(-66, -70), GONG + Vector2(66, -70), Color(0.4, 0.25, 0.1), 10)
	draw_circle(GONG, 48, Color(0.85, 0.65, 0.2))
	draw_arc(GONG, 36, 0, TAU, 24, Color(0.7, 0.5, 0.15), 3)
	# plant + window light
	draw_colored_polygon(PackedVector2Array([Vector2(300, 60), Vector2(500, 60), Vector2(620, 470), Vector2(180, 470)]), Color(1, 1, 0.9, 0.15))
	# students
	for i in 4:
		var x := 240.0 + i * 120
		var y := 520.0 if i % 2 == 0 else 470.0
		Art.ellipse(self, Vector2(x, y + 4), 48, 9, Color.from_hsv(0.08 * i + 0.4, 0.5, 0.8))
		var look := Vector2(1, 0) if class_glare > 0 else Vector2(0, -0.4)
		Art.person(self, Vector2(x, y), 0.75, Art.CLOTHES[i + 2], Art.SKIN[i], {"arms_up": pose % 2 == 0, "mood": "green" if gonged or class_glare > 0 else "smile", "hair": Art.HAIR[i], "look": look})
	# instructor
	Art.person(self, Vector2(160, 640), 0.95, Color(0.9, 0.4, 0.8), Art.SKIN[2], {"arms_up": true, "mood": "smile", "hair": Art.HAIR[3]})
	# squelch on his mat
	Art.ellipse(self, Vector2(470, 640), 60, 10, Color(0.5, 0.3, 0.6))
	var opts := {"arms_up": pose % 2 == 1, "mood": "grin", "hat": "none"}
	Art.squelch(self, Vector2(470, 636), 1.1, opts)
	if pose_flash > 0.0:
		Art.text(self, Vector2(470, 440), POSES[pose] + "!", 32, Color(0.5, 0.2, 0.6), true, 6, Color.WHITE)
	# note highway
	Art.rrect(self, Rect2(730, 0, 470, 720), Color(0.15, 0.1, 0.2, 0.85), 0)
	var beat := 60.0 / BPM
	var off := fmod(maxf(clock, 0.0), beat) / beat
	for k in 12:
		var y := HIT_Y - (k - off) * (HIT_Y / TRAVEL) * beat
		if y > 0 and y < 720:
			draw_line(Vector2(740, y), Vector2(1190, y), Color(1, 1, 1, 0.06), 2)
	for i in 4:
		var lx: float = LANES[i].x
		draw_line(Vector2(lx, 0), Vector2(lx, 720), Color(1, 1, 1, 0.08), 2)
		draw_circle(Vector2(lx, HIT_Y), 40, Color(LANE_COL[i], 0.25 + lane_flash[i] * 0.6))
		draw_arc(Vector2(lx, HIT_Y), 40, 0, TAU, 24, LANE_COL[i], 4)
		_arrow(Vector2(lx, HIT_Y), i, Color(1, 1, 1, 0.5), 18)
	for n: Dictionary in notes:
		if n["state"] != "live":
			continue
		var y: float = HIT_Y - (n["time"] - clock) / TRAVEL * HIT_Y
		if y < -40 or y > 760:
			continue
		var lx2: float = LANES[n["lane"]].x
		Art.cloud(self, Vector2(lx2, y), 32, LANE_COL[n["lane"]])
		_arrow(Vector2(lx2, y), n["lane"], Color(0.15, 0.1, 0.2), 16)


func _arrow(c: Vector2, lane: int, col: Color, s: float) -> void:
	var ang: float = [PI, PI / 2, -PI / 2, 0.0][lane]
	var pts := PackedVector2Array([Vector2(s, 0), Vector2(-s * 0.4, -s * 0.8), Vector2(-s * 0.4, s * 0.8)])
	var out := PackedVector2Array()
	for p in pts:
		out.append(c + p.rotated(ang))
	draw_colored_polygon(out, col)


func draw_hud() -> void:
	if state != "play":
		return
	var total := notes.size()
	var done := hits + misses
	Art.text(self, Vector2(965, 50), "Toots on beat: %d / %d" % [hits, total], 26, Color.WHITE, true, 6)
	Art.meter(self, Rect2(780, 70, 370, 22), float(hits) / total, Art.GAS, "")
	draw_line(Vector2(780 + 370 * 0.7, 66), Vector2(780 + 370 * 0.7, 96), Color(1, 1, 1), 3)
	if judge_t > 0.0:
		Art.text(self, Vector2(965, 520), judge_text, 40, Color(1, 0.4, 0.4) if judge_text == "MISS" else Color(1, 1, 0.4), true, 8)
	if combo >= 4:
		Art.text(self, Vector2(965, 690), "Combo x%d" % combo, 26, Color(0.7, 1, 0.5), true, 6)
	if done == 0 and clock < 2.5:
		Art.text(self, Vector2(965, 300), "Get ready...", 34, Color.WHITE, true, 6)
