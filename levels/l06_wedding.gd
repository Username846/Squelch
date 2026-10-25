extends LevelBase
## Crime #6: A wedding. Three sacred moments, three perfectly timed blasts.
## Stop the swinging marker inside the green zone.

const MOMENTS := [
	{"cue": ["Priest", "If anyone here objects to this union, speak now... or forever hold your peace."], "zone": 0.24, "speed": 1.1,
		"react": [["Bride", "Did... did someone just object?"], ["Groom", "With their BUTT?"]]},
	{"cue": ["Priest", "You may now... kiss the bride."], "zone": 0.16, "speed": 1.5,
		"react": [["Groom", "Honey, was that you?"], ["Bride", "Absolutely not!"]]},
	{"cue": ["Bride", "Okay, everyone! Bouquet toss! One, two, three..."], "zone": 0.11, "speed": 1.9,
		"react": [["Priest", "Lord have mercy. My eyebrows are gone."]]},
]
const ORGAN := Rect2(30, 120, 170, 330)

var moment := 0
var phase := "cue"  # cue, swing, react
var marker := 0.0
var mdir := 1.0
var zone_c := 0.5
var strikes := 0
var organ_played := false
var blast_t := 0.0


func music_name() -> String:
	return "wedding"


func setup() -> void:
	level_id = "wedding"


func intro_lines() -> Array:
	return [
		["Narrator", "Crime number six. St. Agnes Cathedral. A beautiful June wedding."],
		["Squelch", "Ah, weddings. The rings. The vows. The acoustics."],
		["Narrator", "At each sacred moment, a gauge appears. Press SPACE, or click, when the marker is in the green zone. Miss three times and the ushers throw you out."],
	]


func win_lines() -> Array:
	return [
		["Narrator", "The wedding video went viral. Forty million views. The couple has since moved to a remote island."],
		["Squelch", "I now pronounce you... gassed and wife."],
	]


func uses_dpad() -> bool:
	return false


func start_play() -> void:
	_cue()


func _cue() -> void:
	phase = "cue"
	var m: Dictionary = MOMENTS[moment]
	if not await Game.talk([m["cue"]]):
		return
	await get_tree().create_timer(0.1).timeout
	if not is_inside_tree() or state != "play":
		return
	phase = "swing"
	marker = 0.0
	mdir = 1.0
	zone_c = randf_range(0.25, 0.75)
	Game.set_touch_controls(true, false, "BLAST")


func play_process(delta: float) -> void:
	blast_t -= delta
	if phase != "swing":
		return
	var m: Dictionary = MOMENTS[moment]
	marker += mdir * delta * float(m["speed"])
	if marker > 1.0:
		marker = 1.0
		mdir = -1.0
	elif marker < 0.0:
		marker = 0.0
		mdir = 1.0
	if Input.is_action_just_pressed("fart"):
		_release()


func _unhandled_input(event: InputEvent) -> void:
	super(event)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = event.position
		if not organ_played and ORGAN.has_point(p):
			organ_played = true
			for i in [0, 2, 4]:
				Game.sfx("tuba%d" % i, 0.5, 4.0)
			Game.sfx("fart_huge", 0.5)
			pop_text("The organ has opinions.", ORGAN.get_center() + Vector2(120, -100), Art.GAS)
			found_egg()
			return
		if state == "play" and phase == "swing":
			_release()


func _release() -> void:
	var m: Dictionary = MOMENTS[moment]
	var half: float = m["zone"] * 0.5
	phase = "react"
	Game.set_touch_controls(false)
	if absf(marker - zone_c) <= half:
		Game.fart("fart_huge", 0.9 + moment * 0.1, 3.0)
		blast_t = 2.5
		shake = 0.8
		puff(Vector2(640, 560), 18, Art.GAS, 160, 30, -50)
		pop_text("PRRRRRRRRRRRRRRT!", Vector2(640, 300), Art.GAS, 64)
		Game.sfx("gasp", 0.9)
		await get_tree().create_timer(1.6).timeout
		if not is_inside_tree():
			return
		if not await Game.talk(m["react"]):
			return
		moment += 1
		if moment >= MOMENTS.size():
			win()
		else:
			_cue()
	else:
		strikes += 1
		Game.sfx("fart_squeak", 1.3)
		pop_text("...pfft.", Vector2(640, 380), Color(1, 0.6, 0.6), 44)
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree():
			return
		if strikes >= 3:
			lose("Your timing was off. The ushers escorted you out during the vows.")
			return
		if not await Game.talk([["Narrator", "Too weak! Nobody even noticed. Try again."]]):
			return
		_cue()


func draw_level() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.85, 0.8, 0.75))
	# stained glass
	for i in 3:
		var c := Vector2(420 + i * 220, 150)
		draw_rect(Rect2(c + Vector2(-50, -60), Vector2(100, 160)), Color(0.3, 0.25, 0.3))
		for k in 6:
			draw_rect(Rect2(c + Vector2(-44 + (k % 2) * 46, -54 + (k / 2) * 52), Vector2(40, 46)), Color.from_hsv(fmod(i * 0.3 + k * 0.17, 1.0), 0.6, 0.9, 0.85))
		draw_circle(c + Vector2(0, -60), 50, Color(0.3, 0.25, 0.3))
		draw_circle(c + Vector2(0, -60), 42, Color.from_hsv(i * 0.3, 0.5, 0.95, 0.85))
	# organ
	draw_rect(ORGAN, Color(0.45, 0.3, 0.2))
	for i in 7:
		var h := 180.0 + sin(i * 1.3) * 60.0
		draw_rect(Rect2(ORGAN.position.x + 12 + i * 22, ORGAN.position.y + 200 - h, 16, h), Color(0.85, 0.75, 0.45))
	draw_rect(Rect2(ORGAN.position.x, ORGAN.position.y + 220, ORGAN.size.x, 110), Color(0.35, 0.22, 0.14))
	# altar + aisle
	draw_rect(Rect2(0, 420, 1280, 300), Color(0.6, 0.55, 0.5))
	draw_colored_polygon(PackedVector2Array([Vector2(600, 420), Vector2(680, 420), Vector2(820, 720), Vector2(460, 720)]), Color(0.75, 0.15, 0.2))
	draw_rect(Rect2(540, 330, 200, 90), Color(0.95, 0.95, 0.9))
	var blasting := blast_t > 0.0
	var mood := "o" if blasting else "smile"
	Art.person(self, Vector2(640, 410), 1.2, Color(0.1, 0.1, 0.1), Art.SKIN[0], {"mood": mood, "bald": true})
	draw_rect(Rect2(626, 318, 28, 10), Color.WHITE)
	var hair_up := blast_t > 1.5
	Art.person(self, Vector2(540, 500), 1.3, Color(0.12, 0.12, 0.15), Art.SKIN[2], {"mood": mood, "hair": Art.HAIR[1], "arms_up": hair_up, "facing": 1.0, "look": Vector2(1, 0)})
	Art.person(self, Vector2(740, 500), 1.3, Color.WHITE, Art.SKIN[0], {"mood": mood, "hat": "veil", "dress": true, "hair": Art.HAIR[2], "arms_up": hair_up or (moment == 2 and phase == "swing"), "look": Vector2(-1, 0)})
	# pews with guests
	for row in 2:
		for side in 2:
			var x0 := 120.0 if side == 0 else 830.0
			var y0 := 590.0 + row * 80
			for g in 4:
				if row == 1 and side == 0 and g == 3:
					continue
				var gp := Vector2(x0 + g * 85, y0)
				Art.person(self, gp, 0.8, Art.CLOTHES[(g + row * 3 + side) % 7], Art.SKIN[(g + side) % 5], {"mood": "green" if blasting else "smile", "hair": Art.HAIR[(g + row) % 5], "look": Vector2(0, -1), "hat": "top" if g == 1 and side == 1 else "none"})
			draw_rect(Rect2(x0 - 40, y0 - 20, 340, 26), Color(0.4, 0.25, 0.15))
	Art.squelch(self, Vector2(375, 670), 0.8, {"hat": "top", "mood": "grin" if blasting else "smile", "look": Vector2(1, -1)})
	if blasting:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.55, 0.75, 0.2, 0.25 * minf(blast_t, 1.0)))


func draw_hud() -> void:
	if state != "play":
		return
	Art.text(self, Vector2(1020, 50), "Moment %d/3   Misses %d/3" % [mini(moment + 1, 3), strikes], 24, Color(0.2, 0.1, 0.1), true, 0)
	if phase == "swing":
		var r := Rect2(340, 230, 600, 50)
		Art.rrect(self, r.grow(8), Color(0, 0, 0, 0.6), 12)
		draw_rect(r, Color(0.8, 0.3, 0.3))
		var half: float = MOMENTS[moment]["zone"] * 0.5
		draw_rect(Rect2(r.position.x + (zone_c - half) * r.size.x, r.position.y, half * 2 * r.size.x, r.size.y), Color(0.45, 0.85, 0.3))
		var mx := r.position.x + marker * r.size.x
		draw_rect(Rect2(mx - 5, r.position.y - 12, 10, r.size.y + 24), Color.WHITE)
		Art.text(self, Vector2(640, 320), "SPACE / click in the green!", 28, Color.WHITE, true, 6)
