extends LevelBase
## Crime #8: Sneak into the orchestra's tuba section and "play" along.
## Repeat the Maestro's phrase with your four fart valves.

const ROUNDS := [3, 4, 5, 6]
const VALVES := [Vector2(470, 640), Vector2(590, 640), Vector2(710, 640), Vector2(830, 640)]
const VALVE_KEYS := ["left", "down", "up", "right"]
const VALVE_SFX := ["tuba0", "tuba2", "tuba3", "tuba4"]
const VALVE_COL := [Color(0.95, 0.4, 0.5), Color(0.4, 0.7, 1.0), Color(0.5, 0.9, 0.4), Color(1.0, 0.8, 0.3)]
const BALD := Vector2(1035, 640)

var round_i := 0
var phase := "idle"  # show, input, idle
var seq: Array = []
var show_i := 0
var show_t := 0.0
var input_i := 0
var lit := [0.0, 0.0, 0.0, 0.0]
var strikes := 0
var baton := 0.0
var bald_shine := false
var audience_mood := "smile"


func music_name() -> String:
	return "orchestra"


func setup() -> void:
	level_id = "symphony"


func intro_lines() -> Array:
	return [
		["Narrator", "Crime number eight. The Metropolitan Symphony. Tonight: a world-premiere tuba concerto."],
		["Squelch", "The tuba player has, shall we say, mysteriously eaten some bad clams. Luckily I brought my own instrument."],
		["Maestro", "Tuba! Repeat after me. And please... play with feeling."],
		["Narrator", "Watch the Maestro's phrase, then repeat it by clicking or tapping the valves, or with the ARROW keys. Four phrases to finish the concerto. Three wrong notes and you're out."],
	]


func win_lines() -> Array:
	return [
		["Maestro", "Bravo! Bravissimo! Such... texture! Such... aroma!"],
		["Squelch", "Thank you, thank you. I'll be here all week. The smell, however, will be here all month."],
	]


func uses_action_button() -> bool:
	return false


func start_play() -> void:
	Game.music.volume_db = -20.0
	_new_round()


func _exit_tree() -> void:
	Game.music.volume_db = -9.0


func _new_round() -> void:
	seq.clear()
	for i in ROUNDS[round_i]:
		seq.append(randi() % 4)
	phase = "show"
	show_i = -2
	show_t = 0.0
	audience_mood = "smile"


func play_process(delta: float) -> void:
	baton += delta
	for i in 4:
		lit[i] = maxf(0.0, lit[i] - delta * 3.0)
	if phase == "show":
		show_t -= delta
		if show_t <= 0.0:
			show_i += 1
			show_t = 0.6
			if show_i >= seq.size():
				phase = "input"
				input_i = 0
				pop_text("Your turn!", Vector2(640, 420), Color(1, 1, 0.5), 36)
			elif show_i >= 0:
				var v: int = seq[show_i]
				lit[v] = 1.0
				Game.sfx(VALVE_SFX[v], 1.0, -2.0)
	elif phase == "input":
		for i in 4:
			if Input.is_action_just_pressed(VALVE_KEYS[i]):
				_press(i)


func _unhandled_input(event: InputEvent) -> void:
	super(event)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = event.position
		if not bald_shine and p.distance_to(BALD) < 36.0:
			bald_shine = true
			Game.sfx("ding", 1.5)
			pop_text("*shine*", BALD + Vector2(0, -60), Color(1, 1, 0.7))
			found_egg()
			return
		if state == "play" and phase == "input":
			for i in 4:
				if p.distance_to(VALVES[i]) < 50.0:
					_press(i)


func _press(i: int) -> void:
	lit[i] = 1.0
	Game.sfx(VALVE_SFX[i], 1.0, 0.0)
	puff(Vector2(250, 360), 2, Art.GAS, 20, 14, -40)
	if seq[input_i] != i:
		strikes += 1
		phase = "idle"
		audience_mood = "frown"
		Game.sfx("buzzer", 1.0, -4.0)
		Game.sfx("boo", 1.0, -6.0)
		pop_text("WRONG NOTE!", Vector2(640, 420), Color(1, 0.4, 0.4), 40)
		if strikes >= 3:
			lose("Three sour notes. Security has removed you, and your 'instrument', from the stage.")
			return
		await get_tree().create_timer(1.5).timeout
		if is_inside_tree() and state == "play":
			_new_round()
		return
	input_i += 1
	if input_i >= seq.size():
		phase = "idle"
		audience_mood = "green"
		Game.sfx("cheer", 1.0, -8.0)
		pop_text("BRAVO!", Vector2(640, 420), Color(0.6, 1, 0.4), 44)
		round_i += 1
		await get_tree().create_timer(1.6).timeout
		if not is_inside_tree() or state != "play":
			return
		if round_i >= ROUNDS.size():
			win()
		else:
			_new_round()


func draw_level() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.15, 0.08, 0.1))
	# curtains
	for i in 2:
		var x := 0.0 if i == 0 else 1140.0
		for k in 5:
			draw_rect(Rect2(x + k * 28, 0, 22, 560), Color(0.6, 0.08, 0.12))
	draw_rect(Rect2(0, 0, 1280, 50), Color(0.55, 0.06, 0.1))
	# stage
	draw_rect(Rect2(0, 470, 1280, 120), Color(0.5, 0.32, 0.18))
	draw_colored_polygon(PackedVector2Array([Vector2(640, 0), Vector2(840, 470), Vector2(440, 470)]), Color(1, 1, 0.85, 0.06))
	# musicians in rows
	for row in 2:
		for k in 6:
			var mp := Vector2(330 + k * 120 + row * 60, 300 + row * 120)
			if row == 1 and k == 0:
				continue
			Art.chair(self, mp, 0.8, Color(0.2, 0.2, 0.2))
			Art.person(self, mp, 0.8, Color(0.08, 0.08, 0.1), Art.SKIN[(k + row) % 5], {"sit": true, "hair": Art.HAIR[(k + row * 2) % 5], "mood": "green" if audience_mood == "green" else "smile", "look": Vector2(-0.5, 0)})
			if k % 2 == 0:
				draw_line(mp + Vector2(-20, -60), mp + Vector2(30, -40), Color(0.6, 0.35, 0.15), 6)
			else:
				draw_line(mp + Vector2(10, -70), mp + Vector2(10, -30), Color(0.85, 0.75, 0.3), 5)
	# squelch with tuba
	var sp := Vector2(240, 440)
	Art.squelch(self, sp, 1.1, {"sit": false, "mood": "grin"})
	var brass := Color(0.9, 0.72, 0.2)
	draw_arc(sp + Vector2(6, -55), 26, 0, TAU, 24, brass, 11)
	draw_line(sp + Vector2(26, -70), sp + Vector2(40, -125), brass, 14)
	draw_colored_polygon(PackedVector2Array([sp + Vector2(30, -122), sp + Vector2(50, -122), sp + Vector2(78, -175), sp + Vector2(4, -175)]), brass)
	Art.ellipse(self, sp + Vector2(41, -175), 38, 10, Color(0.3, 0.2, 0.05))
	draw_circle(sp + Vector2(-14, -84), 5, brass)
	# maestro
	var mp2 := Vector2(1000, 470)
	draw_rect(Rect2(mp2 + Vector2(-50, -20), Vector2(100, 20)), Color(0.3, 0.2, 0.1))
	Art.person(self, mp2 + Vector2(0, -20), 1.15, Color(0.05, 0.05, 0.08), Art.SKIN[0], {"hair": Art.HAIR[4], "mood": "o" if phase == "show" else ("frown" if audience_mood == "frown" else "smile"), "arms_up": phase == "show" and int(baton * 3) % 2 == 0, "look": Vector2(-1, 0)})
	var bt := mp2 + Vector2(-30, -110 + sin(baton * 8) * 20)
	draw_line(mp2 + Vector2(-22, -80), bt, Color.WHITE, 3)
	# audience heads in the foreground
	for k in 11:
		var hp := Vector2(60 + k * 118, 700)
		var bald := k == 8
		if bald:
			hp = BALD + Vector2(0, 60)
		draw_circle(hp + Vector2(0, -60), 38, Color(0.05, 0.03, 0.04) if not bald else Color(0.35, 0.25, 0.2))
		draw_rect(Rect2(hp + Vector2(-50, -30), Vector2(100, 60)), Color(0.04, 0.02, 0.03))
		if bald:
			draw_circle(hp + Vector2(-12, -76), 8 if not bald_shine else 14, Color(1, 1, 1, 0.25 if not bald_shine else 0.6 + 0.3 * sin(t * 8)))
	# valves
	for i in 4:
		draw_circle(VALVES[i], 46, Color(VALVE_COL[i], 0.3 + lit[i] * 0.7))
		draw_arc(VALVES[i], 46, 0, TAU, 24, VALVE_COL[i], 5)
		_arrow(VALVES[i], i, Color(1, 1, 1, 0.8), 20)


func _arrow(c: Vector2, lane: int, col: Color, s: float) -> void:
	var ang: float = [PI, PI / 2, -PI / 2, 0.0][lane]
	var out := PackedVector2Array()
	for p in [Vector2(s, 0), Vector2(-s * 0.4, -s * 0.8), Vector2(-s * 0.4, s * 0.8)]:
		out.append(c + (p as Vector2).rotated(ang))
	draw_colored_polygon(out, col)


func draw_hud() -> void:
	if state != "play":
		return
	Art.text(self, Vector2(640, 100), "Phrase %d / %d     Wrong notes %d / 3" % [mini(round_i + 1, 4), ROUNDS.size(), strikes], 28, Color.WHITE, true, 6)
	if phase == "show":
		Art.text(self, Vector2(640, 150), "Watch the Maestro...", 26, Color(1, 1, 0.6), true, 6)
	elif phase == "input":
		Art.text(self, Vector2(640, 150), "Your turn!  %d / %d" % [input_i, seq.size()], 26, Color(0.6, 1, 0.5), true, 6)
