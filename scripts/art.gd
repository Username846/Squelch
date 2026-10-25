class_name Art
extends RefCounted
## Procedural drawing helpers. Everything in the game is drawn with these.

const GAS := Color(0.6, 0.8, 0.25)
const SQUELCH_COAT := Color(0.42, 0.2, 0.58)
const SKIN := [Color(1.0, 0.85, 0.7), Color(0.9, 0.7, 0.55), Color(0.72, 0.52, 0.38), Color(0.55, 0.38, 0.27), Color(0.98, 0.78, 0.66)]
const HAIR := [Color(0.25, 0.15, 0.08), Color(0.08, 0.06, 0.05), Color(0.85, 0.65, 0.3), Color(0.6, 0.25, 0.1), Color(0.7, 0.7, 0.72)]
const CLOTHES := [Color(0.9, 0.3, 0.3), Color(0.3, 0.55, 0.9), Color(0.95, 0.75, 0.2), Color(0.3, 0.75, 0.45), Color(0.9, 0.5, 0.75), Color(0.95, 0.55, 0.2), Color(0.5, 0.4, 0.85)]

static var _boxes := {}


static func font() -> Font:
	return ThemeDB.fallback_font


static func text(ci: CanvasItem, pos: Vector2, s: String, size := 24, col := Color.WHITE, center := true, outline := 0, ocol := Color(0, 0, 0, 0.85)) -> void:
	var f := font()
	var p := pos
	if center:
		p.x -= f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	if outline > 0:
		ci.draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, ocol)
	ci.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## Draws centered, word-wrapped text starting at `pos` (first baseline).
static func wrap(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, width: float) -> void:
	var line := ""
	var y := pos.y
	for w in s.split(" "):
		var test := (line + " " + w).strip_edges()
		if font().get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width and line != "":
			text(ci, Vector2(pos.x, y), line, size, col)
			y += size + 4
			line = w
		else:
			line = test
	text(ci, Vector2(pos.x, y), line, size, col)


static func rrect(ci: CanvasItem, r: Rect2, col: Color, rad := 8.0, border := 0.0, bcol := Color.BLACK) -> void:
	var key := "%s|%s|%s|%s" % [col.to_html(), rad, border, bcol.to_html()]
	var sb: StyleBoxFlat = _boxes.get(key)
	if sb == null:
		sb = StyleBoxFlat.new()
		sb.bg_color = col
		sb.set_corner_radius_all(int(rad))
		sb.anti_aliasing = true
		if border > 0.0:
			sb.border_color = bcol
			sb.set_border_width_all(int(border))
		_boxes[key] = sb
	sb.draw(ci.get_canvas_item(), r)


static func ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, filled := true, width := 2.0) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	if filled:
		ci.draw_colored_polygon(pts, col)
	else:
		ci.draw_polyline(pts, col, width, true)


static func cloud(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(-r * 0.6, r * 0.15), r * 0.6, col)
	ci.draw_circle(c + Vector2(r * 0.6, r * 0.2), r * 0.55, col)
	ci.draw_circle(c + Vector2(0, -r * 0.2), r * 0.75, col)
	ci.draw_circle(c + Vector2(0, r * 0.25), r * 0.6, col)


static func star(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + TAU * i / 10.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	ci.draw_colored_polygon(pts, col)


## A cartoon person standing with feet at `p`. Options:
## look (Vector2), mood (smile/frown/o/sleep/grin/green), walk (phase), sit (bool),
## hat (party/fedora/chef/crown/police/veil/top/cap/none), hair (Color), arms_up (bool),
## dress (bool), bald (bool), facing (-1/1), mask, mustache, glasses
static func person(ci: CanvasItem, p: Vector2, s: float, body: Color, skin: Color, o: Dictionary = {}) -> void:
	var look: Vector2 = o.get("look", Vector2.ZERO)
	var mood: String = o.get("mood", "smile")
	var walk: float = o.get("walk", 0.0)
	var sit: bool = o.get("sit", false)
	var hair: Color = o.get("hair", HAIR[0])
	var facing: float = o.get("facing", 1.0)
	var dark := body.darkened(0.35)
	var hip := p + Vector2(0, -40 * s)
	if sit:
		hip = p + Vector2(0, -30 * s)
		ci.draw_line(hip + Vector2(-8 * s, 0), hip + Vector2(-8 * s + 22 * s * facing, 2 * s), dark, 9 * s)
		ci.draw_line(hip + Vector2(8 * s, 0), hip + Vector2(8 * s + 22 * s * facing, 2 * s), dark, 9 * s)
		ci.draw_line(hip + Vector2(-8 * s + 22 * s * facing, 2 * s), p + Vector2(-8 * s + 22 * s * facing, 0), dark, 8 * s)
		ci.draw_line(hip + Vector2(8 * s + 22 * s * facing, 2 * s), p + Vector2(8 * s + 22 * s * facing, 0), dark, 8 * s)
	else:
		var sw := sin(walk) * 10 * s
		ci.draw_line(hip + Vector2(-7 * s, 0), p + Vector2(-8 * s + sw, 0), dark, 9 * s)
		ci.draw_line(hip + Vector2(7 * s, 0), p + Vector2(8 * s - sw, 0), dark, 9 * s)
		ci.draw_circle(p + Vector2(-8 * s + sw, 0), 6 * s, Color(0.15, 0.1, 0.1))
		ci.draw_circle(p + Vector2(8 * s - sw, 0), 6 * s, Color(0.15, 0.1, 0.1))
	# torso
	var top := hip + Vector2(0, -42 * s)
	if o.get("dress", false):
		ci.draw_colored_polygon(PackedVector2Array([top + Vector2(-14 * s, 0), top + Vector2(14 * s, 0), hip + Vector2(26 * s, 10 * s), hip + Vector2(-26 * s, 10 * s)]), body)
	else:
		rrect(ci, Rect2(top + Vector2(-17 * s, 0), Vector2(34 * s, 46 * s)), body, 10 * s)
	# arms
	var arm_y := top + Vector2(0, 8 * s)
	if o.get("arms_up", false):
		ci.draw_line(arm_y + Vector2(-15 * s, 0), arm_y + Vector2(-30 * s, -34 * s), body, 8 * s)
		ci.draw_line(arm_y + Vector2(15 * s, 0), arm_y + Vector2(30 * s, -34 * s), body, 8 * s)
		ci.draw_circle(arm_y + Vector2(-30 * s, -34 * s), 5 * s, skin)
		ci.draw_circle(arm_y + Vector2(30 * s, -34 * s), 5 * s, skin)
	else:
		var asw := -sin(walk) * 8 * s
		ci.draw_line(arm_y + Vector2(-16 * s, 0), arm_y + Vector2(-22 * s + asw, 30 * s), body, 8 * s)
		ci.draw_line(arm_y + Vector2(16 * s, 0), arm_y + Vector2(22 * s - asw, 30 * s), body, 8 * s)
		ci.draw_circle(arm_y + Vector2(-22 * s + asw, 30 * s), 5 * s, skin)
		ci.draw_circle(arm_y + Vector2(22 * s - asw, 30 * s), 5 * s, skin)
	# head
	var head := top + Vector2(0, -20 * s)
	var face_skin := skin
	if mood == "green":
		face_skin = skin.lerp(Color(0.55, 0.8, 0.3), 0.6)
	if not o.get("bald", false) and o.get("hat", "none") != "veil":
		ci.draw_circle(head + Vector2(0, -3 * s), 23 * s, hair)
	ci.draw_circle(head, 20 * s, face_skin)
	if o.get("bald", false):
		ci.draw_circle(head + Vector2(-7 * s, -10 * s), 5 * s, Color(1, 1, 1, 0.5))
	elif o.get("hat", "none") != "veil":
		ci.draw_rect(Rect2(head + Vector2(-20 * s, -21 * s), Vector2(40 * s, 9 * s)), hair)
	# eyes
	var e := look.limit_length(1.0) * 3 * s
	if o.get("mask", false):
		rrect(ci, Rect2(head + Vector2(-17 * s, -9 * s), Vector2(34 * s, 11 * s)), Color(0.05, 0.05, 0.08), 5 * s)
	if mood == "sleep":
		ci.draw_line(head + Vector2(-11 * s, -3 * s), head + Vector2(-4 * s, -3 * s), Color.BLACK, 2 * s)
		ci.draw_line(head + Vector2(4 * s, -3 * s), head + Vector2(11 * s, -3 * s), Color.BLACK, 2 * s)
	else:
		ci.draw_circle(head + Vector2(-7 * s, -4 * s), 4.5 * s, Color.WHITE)
		ci.draw_circle(head + Vector2(7 * s, -4 * s), 4.5 * s, Color.WHITE)
		ci.draw_circle(head + Vector2(-7 * s, -4 * s) + e, 2.2 * s, Color.BLACK)
		ci.draw_circle(head + Vector2(7 * s, -4 * s) + e, 2.2 * s, Color.BLACK)
	if o.get("glasses", false):
		ci.draw_arc(head + Vector2(-7 * s, -4 * s), 7 * s, 0, TAU, 16, Color.BLACK, 1.5 * s)
		ci.draw_arc(head + Vector2(7 * s, -4 * s), 7 * s, 0, TAU, 16, Color.BLACK, 1.5 * s)
	# mouth
	var m := head + Vector2(0, 8 * s)
	match mood:
		"frown", "green":
			ci.draw_arc(m + Vector2(0, 5 * s), 6 * s, PI * 1.15, PI * 1.85, 8, Color(0.3, 0.05, 0.05), 2.5 * s)
		"o":
			ci.draw_circle(m + Vector2(0, 1 * s), 4 * s, Color(0.3, 0.05, 0.05))
		"grin":
			ci.draw_arc(m + Vector2(0, -2 * s), 8 * s, PI * 0.1, PI * 0.9, 10, Color(0.3, 0.05, 0.05), 3 * s)
		"sleep":
			ci.draw_line(m + Vector2(-3 * s, 0), m + Vector2(3 * s, 0), Color(0.3, 0.05, 0.05), 2 * s)
		_:
			ci.draw_arc(m + Vector2(0, -2 * s), 6 * s, PI * 0.15, PI * 0.85, 8, Color(0.3, 0.05, 0.05), 2.5 * s)
	if o.get("mustache", false):
		ci.draw_colored_polygon(PackedVector2Array([m + Vector2(-13 * s, -1 * s), m + Vector2(0, -5 * s), m + Vector2(13 * s, -1 * s), m + Vector2(0, -1 * s)]), Color(0.12, 0.07, 0.05))
	_hat(ci, head, s, o.get("hat", "none"))


static func _hat(ci: CanvasItem, head: Vector2, s: float, hat: String) -> void:
	match hat:
		"party":
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-13 * s, -16 * s), head + Vector2(13 * s, -16 * s), head + Vector2(2 * s, -52 * s)]), Color(1.0, 0.3, 0.6))
			ci.draw_line(head + Vector2(-9 * s, -27 * s), head + Vector2(9 * s, -27 * s), Color(1, 0.9, 0.2), 3 * s)
			ci.draw_circle(head + Vector2(2 * s, -52 * s), 5 * s, Color(1, 0.9, 0.2))
		"fedora":
			ci.draw_rect(Rect2(head + Vector2(-30 * s, -20 * s), Vector2(60 * s, 7 * s)), Color(0.12, 0.08, 0.14))
			rrect(ci, Rect2(head + Vector2(-18 * s, -42 * s), Vector2(36 * s, 24 * s)), Color(0.12, 0.08, 0.14), 6 * s)
			ci.draw_rect(Rect2(head + Vector2(-18 * s, -25 * s), Vector2(36 * s, 5 * s)), Color(0.55, 0.25, 0.7))
		"chef":
			ci.draw_rect(Rect2(head + Vector2(-16 * s, -30 * s), Vector2(32 * s, 14 * s)), Color.WHITE)
			cloud(ci, head + Vector2(0, -40 * s), 18 * s, Color.WHITE)
		"crown":
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-17 * s, -16 * s), head + Vector2(17 * s, -16 * s), head + Vector2(19 * s, -42 * s), head + Vector2(9 * s, -28 * s), head + Vector2(0, -46 * s), head + Vector2(-9 * s, -28 * s), head + Vector2(-19 * s, -42 * s)]), Color(1.0, 0.8, 0.15))
			ci.draw_circle(head + Vector2(0, -24 * s), 3.5 * s, Color(0.9, 0.1, 0.2))
		"police":
			rrect(ci, Rect2(head + Vector2(-21 * s, -36 * s), Vector2(42 * s, 18 * s)), Color(0.12, 0.18, 0.4), 5 * s)
			ci.draw_rect(Rect2(head + Vector2(-24 * s, -20 * s), Vector2(48 * s, 5 * s)), Color(0.08, 0.1, 0.25))
			star(ci, head + Vector2(0, -27 * s), 6 * s, Color(1, 0.85, 0.2))
		"deerstalker":
			var cap := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				cap.append(head + Vector2(0, -10 * s) + Vector2(cos(a) * 23 * s, sin(a) * 20 * s))
			ci.draw_colored_polygon(cap, Color(0.55, 0.45, 0.3))
			ci.draw_rect(Rect2(head + Vector2(-28 * s, -12 * s), Vector2(56 * s, 5 * s)), Color(0.45, 0.35, 0.22))
			ci.draw_line(head + Vector2(0, -30 * s), head + Vector2(0, -12 * s), Color(0.4, 0.3, 0.2), 2 * s)
		"veil":
			ci.draw_circle(head + Vector2(0, -3 * s), 25 * s, Color(1, 1, 1, 0.55))
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-24 * s, 0), head + Vector2(24 * s, 0), head + Vector2(34 * s, 70 * s), head + Vector2(-34 * s, 70 * s)]), Color(1, 1, 1, 0.4))
			ci.draw_circle(head + Vector2(0, -20 * s), 6 * s, Color(1, 0.85, 0.9))
		"top":
			ci.draw_rect(Rect2(head + Vector2(-26 * s, -20 * s), Vector2(52 * s, 6 * s)), Color(0.08, 0.08, 0.1))
			ci.draw_rect(Rect2(head + Vector2(-16 * s, -54 * s), Vector2(32 * s, 36 * s)), Color(0.08, 0.08, 0.1))
		"cap":
			ci.draw_circle(head + Vector2(0, -12 * s), 20 * s, Color(0.85, 0.2, 0.2))
			ci.draw_rect(Rect2(head + Vector2(0, -14 * s), Vector2(28 * s, 5 * s)), Color(0.7, 0.15, 0.15))
		"wig":
			for i in 5:
				ci.draw_circle(head + Vector2(-20 * s + i * 10 * s, -18 * s), 9 * s, Color(0.95, 0.95, 0.95))
			ci.draw_circle(head + Vector2(-22 * s, 2 * s), 9 * s, Color(0.95, 0.95, 0.95))
			ci.draw_circle(head + Vector2(22 * s, 2 * s), 9 * s, Color(0.95, 0.95, 0.95))


## Squelch himself: purple trench coat, fedora, eye mask, magnificent mustache.
static func squelch(ci: CanvasItem, p: Vector2, s := 1.0, o: Dictionary = {}) -> void:
	var opts := {"hat": "fedora", "mask": true, "mustache": true, "hair": Color(0.1, 0.06, 0.04), "mood": "grin"}
	opts.merge(o, true)
	person(ci, p, s, SQUELCH_COAT, Color(0.93, 0.82, 0.66), opts)
	# coat flaps
	var hip := p + Vector2(0, -40 * s)
	ci.draw_colored_polygon(PackedVector2Array([hip + Vector2(-17 * s, -6 * s), hip + Vector2(17 * s, -6 * s), hip + Vector2(21 * s, 14 * s), hip + Vector2(-21 * s, 14 * s)]), SQUELCH_COAT.darkened(0.15))
	ci.draw_line(hip + Vector2(0, -46 * s), hip + Vector2(0, 14 * s), SQUELCH_COAT.darkened(0.4), 2 * s)


## Detective Sniffington: tan coat, deerstalker, a truly enormous nose.
static func sniffington(ci: CanvasItem, p: Vector2, s := 1.0, o: Dictionary = {}) -> void:
	var opts := {"hat": "deerstalker", "hair": Color(0.5, 0.4, 0.3), "mood": "frown"}
	opts.merge(o, true)
	person(ci, p, s, Color(0.72, 0.6, 0.4), Color(1.0, 0.85, 0.72), opts)
	var head := p + Vector2(0, -102 * s)
	ci.draw_circle(head + Vector2(6 * s * float(opts.get("facing", 1.0)), 4 * s), 9 * s, Color(1.0, 0.7, 0.6))


static func chair(ci: CanvasItem, p: Vector2, s: float, col: Color) -> void:
	ci.draw_rect(Rect2(p + Vector2(-20 * s, -60 * s), Vector2(40 * s, 34 * s)), col.darkened(0.15))
	ci.draw_rect(Rect2(p + Vector2(-22 * s, -30 * s), Vector2(44 * s, 9 * s)), col)
	ci.draw_line(p + Vector2(-18 * s, -22 * s), p + Vector2(-18 * s, 0), col.darkened(0.3), 4 * s)
	ci.draw_line(p + Vector2(18 * s, -22 * s), p + Vector2(18 * s, 0), col.darkened(0.3), 4 * s)


static func meter(ci: CanvasItem, r: Rect2, frac: float, col: Color, label := "") -> void:
	rrect(ci, r, Color(0, 0, 0, 0.55), 6)
	var f := clampf(frac, 0.0, 1.0)
	if f > 0.0:
		rrect(ci, Rect2(r.position + Vector2(3, 3), Vector2((r.size.x - 6) * f, r.size.y - 6)), col, 4)
	if label != "":
		text(ci, r.position + Vector2(r.size.x / 2, r.size.y - 6), label, int(r.size.y * 0.62), Color.WHITE, true, 4)
