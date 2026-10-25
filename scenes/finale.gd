extends Node2D
## The final cutscene, unlocked by finding all ten secret stashes.
## Squelch finally gets caught... or does he?

var t := 0.0
var shot_t := 0.0
var shot := "street"
var cuffed := false
var jury_gasp := false
var sniff_guilty := false
var fly := 0.0
var clouds: Array = []


func _ready() -> void:
	Game.play_music("finale")
	Game.set_skip(func() -> void: Game.goto("res://scenes/credits.gd"))
	_run.call_deferred()


func _set_shot(s: String) -> void:
	shot = s
	shot_t = 0.0


func _run() -> void:
	Game.sfx("siren")
	if not await Game.talk([
		["Det. Sniffington", "FREEZE, Squelch! Drop the bean!"],
		["Squelch", "Detective! What a... pungent surprise."],
		["Det. Sniffington", "Ten crimes. Ten secret stashes. I sniffed out every single one. You led me right to you."],
		["Squelch", "You found... all of my secrets?"],
		["Det. Sniffington", "Every. Last. One. You're going away for a long, long time."],
	]):
		return
	cuffed = true
	Game.sfx("click", 0.6, 10.0)
	if not await Game.talk([["Narrator", "And so, after twenty years on the run, the great Squelch was finally caught."]]):
		return
	_set_shot("court")
	Game.sfx("thud")
	if not await Game.talk([
		["Judge", "Order! Order! The People versus Squelch."],
		["Det. Sniffington", "Your honor, the defendant gassed a birthday party, a wedding, a symphony... and the Queen herself."],
	]):
		return
	jury_gasp = true
	Game.sfx("gasp")
	if not await Game.talk([
		["Jury", "Gasp!"],
		["Judge", "How does the defendant plead?"],
		["Squelch", "Your honor, I have just one question for the detective."],
		["Squelch", "Detective. At the scene of every crime... who was the FIRST to smell it?"],
		["Det. Sniffington", "Me, obviously! I have the finest nose on the force!"],
		["Squelch", "Then the law is clear, your honor. He who smelt it..."],
		["Jury", "...DEALT IT!"],
		["Judge", "Good heavens. It's the oldest law in the book."],
		["Judge", "Detective Sniffington! I find YOU guilty of all ten fart crimes!"],
	]):
		return
	sniff_guilty = true
	Game.sfx("thud")
	if not await Game.talk([
		["Det. Sniffington", "WHAT?! No! It wasn't me! NOOOOO!"],
		["Squelch", "And now, your honor... my closing statement."],
	]):
		return
	_set_shot("blast")
	Game.fart("fart_huge", 0.8, 4.0)
	await get_tree().create_timer(0.6).timeout
	Game.fart("fart_huge", 0.6, 4.0)
	Game.sfx("crash")
	await get_tree().create_timer(1.6).timeout
	if not is_inside_tree():
		return
	_set_shot("sky")
	Game.sfx("whoosh")
	if not await Game.talk([
		["Narrator", "Squelch was never caught again."],
		["Narrator", "Or was he?"],
	]):
		return
	_set_shot("end")
	if not await Game.talk([["Det. Sniffington", "Sniff... sniff... I'll get you, Squelch. If it's the last thing I smell."]]):
		return
	Game.fart("fart3", 1.3)
	await get_tree().create_timer(2.5).timeout
	if not is_inside_tree():
		return
	Game.data["seen_finale"] = true
	Game.save()
	Game.goto("res://scenes/credits.gd")


func _process(delta: float) -> void:
	t += delta
	shot_t += delta
	if shot == "blast" or shot == "sky":
		fly += delta
		if randf() < delta * 30:
			clouds.append([Vector2(640 + randf_range(-40, 40), 620 - fly * 200 if shot == "blast" else 600), randf_range(30, 90), 2.0])
	for c: Array in clouds:
		c[2] -= delta
		c[1] += delta * 40
	clouds = clouds.filter(func(c: Array) -> bool: return c[2] > 0.0)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		Game.goto("res://scenes/board.gd")


func _draw() -> void:
	match shot:
		"street":
			draw_rect(Rect2(0, 0, 1280, 720), Color(0.06, 0.06, 0.14))
			draw_rect(Rect2(200, 120, 880, 420), Color(0.3, 0.3, 0.36))
			Art.text(self, Vector2(640, 190), "POLICE", 64, Color(0.8, 0.85, 1.0))
			draw_rect(Rect2(570, 360, 140, 180), Color(0.15, 0.15, 0.2))
			draw_rect(Rect2(0, 540, 1280, 180), Color(0.12, 0.12, 0.15))
			var flash := int(t * 4) % 2 == 0
			draw_rect(Rect2(0, 0, 1280, 720), Color(1, 0, 0, 0.12) if flash else Color(0, 0.2, 1, 0.12))
			Art.squelch(self, Vector2(760, 520), 1.8, {"mood": "o" if cuffed else "grin", "arms_up": not cuffed})
			Art.ellipse(self, Vector2(814, 352 if not cuffed else 460), 14, 20, Color(1, 0.8, 0.2))
			Art.sniffington(self, Vector2(420, 530), 2.0, {"look": Vector2(1, 0)})
			if cuffed:
				draw_arc(Vector2(750, 470), 12, 0, TAU, 16, Color(0.75, 0.75, 0.8), 5)
				draw_arc(Vector2(772, 470), 12, 0, TAU, 16, Color(0.75, 0.75, 0.8), 5)
		"court":
			draw_rect(Rect2(0, 0, 1280, 720), Color(0.45, 0.3, 0.18))
			for i in 8:
				draw_rect(Rect2(i * 170 + 20, 0, 30, 720), Color(0.4, 0.26, 0.15))
			draw_rect(Rect2(460, 150, 360, 200), Color(0.3, 0.18, 0.1))
			Art.person(self, Vector2(640, 260), 1.4, Color(0.08, 0.08, 0.1), Art.SKIN[1], {"hat": "wig", "mood": "o" if sniff_guilty else "frown"})
			draw_rect(Rect2(460, 250, 360, 100), Color(0.35, 0.22, 0.12))
			draw_rect(Rect2(0, 500, 1280, 220), Color(0.3, 0.2, 0.12))
			for j in 6:
				Art.person(self, Vector2(1000 + (j % 3) * 80, 420 + (j / 3) * 90), 0.8, Art.CLOTHES[j], Art.SKIN[j % 5], {"mood": "o" if jury_gasp else "smile", "hair": Art.HAIR[j % 5]})
			draw_rect(Rect2(960, 380, 280, 40), Color(0.3, 0.18, 0.1))
			Art.squelch(self, Vector2(260, 510), 1.6, {"mood": "grin"})
			if sniff_guilty:
				Art.sniffington(self, Vector2(760 + sin(t * 30) * 6, 510), 1.6, {"mood": "o", "arms_up": true})
			else:
				Art.sniffington(self, Vector2(760, 510), 1.6, {"look": Vector2(-1, 0), "facing": -1.0})
		"blast":
			draw_rect(Rect2(0, 0, 1280, 720), Color(0.45, 0.3, 0.18))
			draw_rect(Rect2(0, 0, 1280, 720), Color(0.6, 0.8, 0.25, clampf(shot_t * 0.4, 0, 0.7)))
			for c: Array in clouds:
				Art.cloud(self, c[0], c[1], Color(0.55, 0.78, 0.2, 0.5 * clampf(c[2], 0, 1)))
			Art.squelch(self, Vector2(640, 500 - shot_t * shot_t * 160), 1.8, {"arms_up": true})
			Art.text(self, Vector2(640, 120), "PFFFFFRRRRRRRRT!", 80, Color(0.9, 1, 0.5), true, 14, Color(0.2, 0.3, 0.05))
		"sky", "end":
			draw_rect(Rect2(0, 0, 1280, 720), Color(0.07, 0.05, 0.2))
			for i in 60:
				draw_circle(Vector2(fmod(i * 211.0, 1280), fmod(i * 137.0, 500)), 1.5, Color(1, 1, 0.9, 0.7))
			draw_circle(Vector2(900, 260), 150, Color(0.97, 0.95, 0.8))
			if shot == "sky":
				var p := Vector2(-100 + shot_t * 260, 520 - shot_t * 70)
				for k in 8:
					Art.cloud(self, p + Vector2(-40 - k * 26, 50 + k * 8), 18 + k * 3, Color(0.6, 0.8, 0.25, 0.6 - k * 0.07))
				Art.squelch(self, p + Vector2(0, 60), 1.1, {"arms_up": true})
			else:
				draw_rect(Rect2(0, 600, 1280, 120), Color(0.04, 0.03, 0.08))
				Art.text(self, Vector2(640, 200), "THE END?", 110, Color(0.65, 0.9, 0.3), true, 18, Color(0.15, 0.05, 0.2))
				var bars := Rect2(840, 420, 260, 200)
				Art.sniffington(self, Vector2(970, 600), 1.6, {"mood": "frown", "look": Vector2(0, -1)})
				for b in 6:
					draw_rect(Rect2(bars.position.x + b * 50, bars.position.y, 8, bars.size.y), Color(0.5, 0.5, 0.55))
				draw_rect(Rect2(bars.position.x, bars.position.y, bars.size.x - 2, 8), Color(0.5, 0.5, 0.55))
