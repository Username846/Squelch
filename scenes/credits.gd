extends Node2D
## Rolling credits after the true ending.

const LINES := [
	["SQUELCH", 72], ["A Life of Fart Crime", 34], ["", 30],
	["Starring", 26], ["Squelch  —  as himself", 32], ["Det. Sniffington  —  as the nose", 32], ["", 30],
	["The Victims", 26], ["Everyone at Timmy's... sorry, Tammy's birthday party", 24], ["Four very patient elevator passengers", 24],
	["The Quiet Reading Society", 24], ["Yogi Breeze & the 6 a.m. class", 24], ["Chef Pierre's soup", 24],
	["The happy couple", 24], ["The entire Metropolitan Symphony", 24], ["Her Majesty the Queen", 24], ["The Evidence Room", 24], ["", 30],
	["Special Thanks", 26], ["The Raccoon in the Elevator", 24], ["The Old Man in the Armchair", 24], ["The Lobster (now free)", 24],
	["Bigfoot", 24], ["The shiny-headed gentleman, row A", 24], ["Granny Gusts", 24], ["", 30],
	["Music, voices & sound", 26], ["100% synthesized. No beans were harmed.", 24], ["", 30],
	["Made with Godot 4.7", 26], ["", 60], ["Thanks for playing!", 44], ["(you may now open a window)", 24],
]

var y := 760.0
var done := false


func _ready() -> void:
	Game.play_music("credits")


func _process(delta: float) -> void:
	y -= delta * 60.0
	queue_redraw()
	if not done and y < -LINES.size() * 46.0 - 200.0:
		done = true
		Game.goto("res://scenes/title.gd")


func _unhandled_input(event: InputEvent) -> void:
	if done:
		return
	if (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE) or (event is InputEventMouseButton and event.pressed):
		done = true
		Game.goto("res://scenes/title.gd")


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.08, 0.05, 0.14))
	var yy := y
	for l: Array in LINES:
		if yy > -80 and yy < 800:
			Art.text(self, Vector2(640, yy), l[0], l[1], Color(0.65, 0.9, 0.3) if l[1] >= 40 else Color(0.95, 0.9, 1.0), true, 6)
		yy += 46.0 if l[1] < 40 else 70.0
	Art.squelch(self, Vector2(1120, 700), 1.4, {"look": Vector2(-1, -0.4)})
