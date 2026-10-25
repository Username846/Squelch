extends LevelBase
## Crime #9: The Queen's garden tea. Clench through her speech, and only let go
## when the ceremonial cannon fires to cover the noise.

const QUEEN := Vector2(820, 470)
const QS := 1.3
const CANNON := Vector2(1130, 520)
const GOAL := 4

var pressure := 20.0
var covered := 0
var strikes := 0
var cannon := "idle"  # idle, fuse, boom
var cannon_t := 4.0
var speech_t := 2.0
var bubble := ""
var bubble_t := 0.0
var crown_off := false
var crown_pos := Vector2.ZERO
var crown_vel := Vector2.ZERO
var flash := 0.0
var clench_anim := 0.0
var _btns: Array = []

const SPEECH := [
	"One is delighted to welcome you all to the royal garden.",
	"The roses this year are particularly fragrant.",
	"One has always believed in decorum above all else.",
	"Do try the cucumber sandwiches. One made them oneself. Not really.",
	"In my seventy years on the throne, one has never once smelled anything untoward.",
	"Is it one, or is it rather warm out here?",
	"The corgis send their regards.",
]


func music_name() -> String:
	return "royal"


func setup() -> void:
	level_id = "royal"


func intro_lines() -> Array:
	return [
		["Narrator", "Crime number nine. Buckingham Garden. Tea with Her Majesty the Queen."],
		["Squelch", "I've eaten nothing but baked beans and boiled eggs for three days. For queen and country."],
		["Narrator", "Your gut pressure keeps rising. MASH SPACE (or the CLENCH button) to hold it in. When the cannon fires, press X (or RELEASE) to let it out under the BOOM."],
		["Narrator", "Release at the wrong moment or burst, and it's a royal scandal. Hide four blasts under cannon fire!"],
	]


func win_lines() -> Array:
	return [
		["The Queen", "What a splendid salute. Though one could swear the cannon smelled of... eggs."],
		["Squelch", "God save the Queen. Because nobody can save her nose."],
	]


func uses_touch() -> bool:
	return false


func start_play() -> void:
	var labels := [["CLENCH  (Space)", _clench], ["RELEASE  (X)", _release]]
	for i in 2:
		var b := Button.new()
		b.text = labels[i][0]
		b.position = Vector2(380 + i * 280, 640)
		b.size = Vector2(240, 64)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(labels[i][1])
		_ui.add_child(b)
		_btns.append(b)


func play_process(delta: float) -> void:
	flash -= delta
	clench_anim -= delta
	pressure += delta * (8.0 + play_t * 0.22)
	if Input.is_action_just_pressed("fart") or (Input.is_action_just_pressed("up")):
		_clench()
	if Input.is_action_just_pressed("alt"):
		_release()
	if pressure >= 100.0:
		pressure = 45.0
		_scandal("You burst! In front of the QUEEN!")
	# the Queen rambles on
	speech_t -= delta
	bubble_t -= delta
	if speech_t <= 0.0:
		speech_t = 6.5
		bubble = SPEECH.pick_random()
		bubble_t = 5.0
		Game.speak(bubble, "Granny Gusts" if crown_off else "The Queen")
	# cannon cycle
	cannon_t -= delta
	match cannon:
		"idle":
			if cannon_t <= 0.0:
				cannon = "fuse"
				cannon_t = 1.6
		"fuse":
			if cannon_t <= 0.0:
				cannon = "boom"
				cannon_t = 0.75
				flash = 0.4
				shake = 0.6
				Game.sfx("boom")
		"boom":
			if cannon_t <= 0.0:
				cannon = "idle"
				cannon_t = randf_range(3.0, 6.5)
	if crown_off:
		crown_vel.y += 900.0 * delta
		crown_pos += crown_vel * delta
		if crown_pos.y > 600.0:
			crown_pos.y = 600.0
			crown_vel = Vector2.ZERO


func _clench() -> void:
	if state != "play":
		return
	pressure = maxf(0.0, pressure - 6.5)
	clench_anim = 0.12


func _release() -> void:
	if state != "play":
		return
	if cannon == "boom" or (cannon == "fuse" and cannon_t < 0.1):
		covered += 1
		Game.fart("fart_huge", 0.8, -2.0)
		puff(Vector2(330, 560), 10, Art.GAS, 40, 22, -20)
		pop_text("Covered! %d/%d" % [covered, GOAL], Vector2(330, 360), Art.GAS, 36)
		pressure = 0.0
		cannon = "idle"
		cannon_t = randf_range(3.0, 6.0)
		if covered >= GOAL:
			_clear_buttons()
			win()
	elif pressure < 15.0:
		pop_text("Nothing to release!", Vector2(330, 360), Color(1, 1, 1), 26)
	else:
		pressure = 0.0
		Game.fart("fart_wet", 1.0, 2.0)
		puff(Vector2(330, 560), 8)
		_scandal("You released in total silence. Everybody heard.")


func _scandal(msg: String) -> void:
	strikes += 1
	shake = 0.5
	Game.sfx("gasp")
	Game.speak(["Good heavens!", "Guards!", "One is not amused."].pick_random(), "The Queen")
	pop_text("SCANDAL!", Vector2(640, 260), Color(1, 0.35, 0.35), 54)
	if strikes >= 3:
		_clear_buttons()
		lose(msg + " The Royal Guard has escorted you to the Tower.")


func _clear_buttons() -> void:
	for b: Button in _btns:
		b.queue_free()
	_btns.clear()


func _unhandled_input(event: InputEvent) -> void:
	super(event)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var head := QUEEN + Vector2(0, -102 * QS)
		if not crown_off and event.position.distance_to(head + Vector2(0, -30 * QS)) < 34.0:
			crown_off = true
			crown_pos = head + Vector2(0, -30 * QS)
			crown_vel = Vector2(180, -420)
			Game.sfx("pop")
			Game.speak("Oh, bother. Hello, dearie. Granny's been doing this for years.", "Granny Gusts")
			pop_text("Granny Gusts?!", head + Vector2(0, -90), Color(1, 0.8, 0.3), 36)
			found_egg()


func draw_level() -> void:
	var sky := Color(0.6, 0.8, 1.0)
	draw_rect(Rect2(0, 0, 1280, 720), sky)
	draw_circle(Vector2(140, 90), 50, Color(1, 0.95, 0.6))
	# palace
	draw_rect(Rect2(180, 120, 920, 260), Color(0.85, 0.82, 0.72))
	for i in 14:
		draw_rect(Rect2(210 + i * 63, 160, 30, 60), Color(0.4, 0.45, 0.55))
		draw_rect(Rect2(210 + i * 63, 260, 30, 60), Color(0.4, 0.45, 0.55))
	draw_rect(Rect2(560, 80, 160, 60), Color(0.85, 0.82, 0.72))
	draw_line(Vector2(700, 80), Vector2(700, 60), Color(0.3, 0.3, 0.3), 3)
	draw_rect(Rect2(700, 60, 40, 22), Color(0.8, 0.1, 0.2))
	# lawn
	draw_rect(Rect2(0, 380, 1280, 340), Color(0.35, 0.65, 0.3))
	for i in 40:
		draw_line(Vector2(i * 33, 720), Vector2(i * 33 + 6, 700), Color(0.3, 0.55, 0.25), 2)
	# podium + queen
	Art.person(self, QUEEN, QS, Color(0.55, 0.25, 0.65), Art.SKIN[0], {"dress": true, "hat": "none" if crown_off else "crown", "hair": Art.HAIR[4], "mood": "o" if bubble_t > 0.0 else "smile", "glasses": crown_off})
	if crown_off:
		_crown(crown_pos)
	draw_rect(Rect2(QUEEN + Vector2(-60, -50), Vector2(120, 60)), Color(0.4, 0.25, 0.15))
	if bubble_t > 0.0:
		var bp := QUEEN + Vector2(-20, -260)
		Art.rrect(self, Rect2(bp + Vector2(-280, -40), Vector2(400, 76)), Color.WHITE, 14)
		Art.wrap(self, bp + Vector2(-80, -10), bubble, 18, Color(0.2, 0.1, 0.2), 370)
	# guests
	for i in 4:
		var gp := Vector2(520 + i * 85 - (i / 2) * 420, 560 + (i % 2) * 30)
		if i >= 2:
			gp = Vector2(470 + (i - 2) * 80, 610)
		Art.person(self, gp, 0.85, Art.CLOTHES[i + 2], Art.SKIN[i], {"hat": "top" if i % 2 == 0 else "none", "dress": i % 2 == 1, "hair": Art.HAIR[i]})
	# squelch, sweating
	var strain := pressure / 100.0
	var sq := Vector2(330, 620) + Vector2(sin(t * 50) * strain * 4, 0)
	Art.squelch(self, sq, 1.2 - (0.04 if clench_anim > 0 else 0.0), {"hat": "top", "mood": "o" if strain > 0.7 else ("frown" if strain > 0.4 else "smile")})
	if strain > 0.5:
		for k in 3:
			draw_circle(sq + Vector2(-25 + k * 25, -150 + fmod(t * 60 + k * 20, 40)), 4, Color(0.5, 0.8, 1))
	# cannon + guard
	Art.person(self, CANNON + Vector2(-90, 40), 1.0, Color(0.8, 0.1, 0.15), Art.SKIN[3], {"hat": "top", "look": Vector2(1, 0)})
	draw_set_transform(CANNON, -0.35, Vector2.ONE)
	Art.rrect(self, Rect2(-20, -26, 140, 52), Color(0.2, 0.2, 0.22), 18)
	draw_circle(Vector2(120, 0), 24, Color(0.12, 0.12, 0.14))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_circle(CANNON + Vector2(-20, 40), 30, Color(0.45, 0.3, 0.15))
	if cannon == "fuse":
		var k2 := 1.0 - cannon_t / 1.6
		var sp := CANNON + Vector2(-60 + k2 * 40, 0)
		draw_line(CANNON + Vector2(-60, 0), CANNON + Vector2(-20, -10), Color(0.3, 0.2, 0.1), 3)
		Art.star(self, sp, 10 + randf() * 6, Color(1, 0.8, 0.2))
	elif cannon == "boom":
		Art.cloud(self, CANNON + Vector2(140, -70), 70, Color(0.95, 0.95, 0.9, 0.9))
		Art.text(self, CANNON + Vector2(60, -150), "BOOM!", 60, Color(1, 0.6, 0.2), true, 10)
	if flash > 0.0:
		draw_rect(Rect2(0, 0, 1280, 720), Color(1, 1, 0.9, flash))


func _crown(p: Vector2) -> void:
	var s := QS
	draw_colored_polygon(PackedVector2Array([p + Vector2(-17 * s, 14 * s), p + Vector2(17 * s, 14 * s), p + Vector2(19 * s, -12 * s), p + Vector2(9 * s, 2 * s), p + Vector2(0, -16 * s), p + Vector2(-9 * s, 2 * s), p + Vector2(-19 * s, -12 * s)]), Color(1.0, 0.8, 0.15))


func draw_hud() -> void:
	if state != "play":
		return
	Art.meter(self, Rect2(20, 16, 420, 36), pressure / 100.0, Color(0.95, 0.5, 0.2).lerp(Color(1, 0.1, 0.1), pressure / 100.0), "GUT PRESSURE")
	Art.text(self, Vector2(760, 46), "Covered blasts: %d / %d    Scandals: %d / 3" % [covered, GOAL, strikes], 26, Color(0.1, 0.1, 0.2), true, 0)
