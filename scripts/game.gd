extends Node
## Global game state: save data, scene switching, music, sound effects,
## synthesized-voice dialogue and on-screen touch controls.

signal advanced

const SAVE_PATH := "user://squelch_save.json"
const W := 1280.0
const H := 720.0

const LEVELS := [
	{"id": "party", "title": "Birthday Bash", "crime": "Musical Chair Contamination", "path": "res://levels/l01_party.gd"},
	{"id": "elevator", "title": "Going Down", "crime": "Elevator Atmosphere Tampering", "path": "res://levels/l02_elevator.gd"},
	{"id": "library", "title": "Silent But Deadly", "crime": "Crop-Dusting a Quiet Zone", "path": "res://levels/l03_library.gd"},
	{"id": "yoga", "title": "Downward Dog", "crime": "Rhythmic Gas Release", "path": "res://levels/l04_yoga.gd"},
	{"id": "bistro", "title": "Le Bistro Pew", "crime": "Aggravated Soup Seasoning", "path": "res://levels/l05_bistro.gd"},
	{"id": "wedding", "title": "Speak Now", "crime": "Ceremonial Disruption", "path": "res://levels/l06_wedding.gd"},
	{"id": "getaway", "title": "Gas Getaway", "crime": "Jet-Propelled Evasion", "path": "res://levels/l07_getaway.gd"},
	{"id": "symphony", "title": "Symphony No. 2", "crime": "Brass Section Impersonation", "path": "res://levels/l08_symphony.gd"},
	{"id": "royal", "title": "Royal Tea", "crime": "High Treason Against the Nose", "path": "res://levels/l09_royal.gd"},
	{"id": "heist", "title": "The Evidence Room", "crime": "Grand Theft Bean-o", "path": "res://levels/l10_heist.gd"},
]

## [pitch, rate] for the speech synthesizer, per speaker.
const VOICES := {
	"Squelch": [0.55, 0.95],
	"Narrator": [0.8, 0.88],
	"Det. Sniffington": [0.35, 0.85],
	"Kid": [1.9, 1.15],
	"Birthday Girl": [2.0, 1.1],
	"Mom": [1.4, 1.05],
	"Passenger": [1.0, 1.0],
	"Librarian": [1.5, 0.8],
	"Old Man": [0.45, 0.7],
	"Yogi Breeze": [1.2, 0.75],
	"Chef Pierre": [0.7, 1.05],
	"Diner": [1.3, 1.1],
	"Priest": [0.6, 0.8],
	"Bride": [1.6, 1.05],
	"Groom": [0.9, 1.0],
	"Officer": [0.7, 1.15],
	"Maestro": [1.1, 0.9],
	"The Queen": [1.5, 0.8],
	"Guard": [0.6, 1.1],
	"Judge": [0.5, 0.8],
	"Jury": [1.3, 1.2],
	"Raccoon": [2.0, 1.3],
	"Lobster": [1.8, 1.4],
	"Bigfoot": [0.1, 0.7],
	"Granny Gusts": [1.7, 0.85],
}

const SPEAKER_COLORS := {
	"Squelch": Color(0.75, 0.5, 1.0),
	"Narrator": Color(0.85, 0.85, 0.85),
	"Det. Sniffington": Color(0.5, 0.75, 1.0),
}

## Per-effect volume trims (dB), since the raw synths vary in loudness.
const SFX_TRIM := {
	"click": -14.0, "select": -10.0, "siren": -10.0, "honk": -6.0, "buzzer": -6.0,
	"coin": -6.0, "babble1": -8.0, "babble2": -8.0, "babble3": -8.0, "step": -10.0,
	"lose": -3.0, "pop": -6.0, "gasp": -6.0, "chair": -8.0,
}

const FARTS := ["fart1", "fart2", "fart3", "fart_wet", "fart_squeak"]

var data := {"done": {}, "eggs": {}, "seen_intro": false, "seen_finale": false}
var current_scene: Node
var music: AudioStreamPlayer
var music_name := ""
var muted := false

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_idx := 0
var _cache := {}
var _voices := PackedStringArray()

# dialogue UI
var dialog_active := false
var _dlg_layer: CanvasLayer
var _dlg_root: Control
var _dlg_name: Label
var _dlg_text: Label
var _dlg_hint: Label
var _typing := false
var _type_pos := 0.0
var _dlg_cooldown := 0.0
var _dlg_cancel := false

# transition + banners
var _fade_layer: CanvasLayer
var _fade: ColorRect
var _banner: Label
var _banner_t := 0.0

# touch controls
var _touch_layer: CanvasLayer
var _touch_dpad: Node2D
var _touch_fart: TouchScreenButton
var _touch_fart_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	_setup_input()
	load_save()
	music = AudioStreamPlayer.new()
	music.volume_db = -9.0
	add_child(music)
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)
	_build_dialog()
	_build_fade()
	_build_touch()


# ------------------------------------------------------------------ input
func _setup_input() -> void:
	var map := {
		"left": [KEY_LEFT, KEY_A],
		"right": [KEY_RIGHT, KEY_D],
		"up": [KEY_UP, KEY_W],
		"down": [KEY_DOWN, KEY_S],
		"fart": [KEY_SPACE],
		"alt": [KEY_X, KEY_ENTER, KEY_KP_ENTER],
	}
	for action: String in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.3)
		for key: int in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key as Key
			InputMap.action_add_event(action, ev)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		muted = not muted
		AudioServer.set_bus_mute(0, muted)
		banner("Sound off" if muted else "Sound on")
	if not dialog_active:
		return
	var go := false
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.physical_keycode
		go = k == KEY_SPACE or k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_Z or k == KEY_X
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		go = true
	if go:
		get_viewport().set_input_as_handled()
		if _dlg_cooldown > 0.0:
			return
		_dlg_cooldown = 0.18
		if _typing:
			_typing = false
			_dlg_text.visible_ratio = 1.0
		else:
			advanced.emit()


func _process(delta: float) -> void:
	_dlg_cooldown = maxf(0.0, _dlg_cooldown - delta)
	if _typing:
		_type_pos += delta * 45.0
		_dlg_text.visible_characters = int(_type_pos)
		if _type_pos >= _dlg_text.text.length():
			_typing = false
			_dlg_text.visible_ratio = 1.0
	if _dlg_hint:
		_dlg_hint.modulate.a = 0.0 if _typing else 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
	if _banner_t > 0.0:
		_banner_t -= delta
		_banner.modulate.a = clampf(_banner_t, 0.0, 1.0)
		_banner.visible = _banner_t > 0.0


# ------------------------------------------------------------------ save data
func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		for k: String in data:
			if parsed.has(k):
				data[k] = parsed[k]


func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func reset_save() -> void:
	data = {"done": {}, "eggs": {}, "seen_intro": false, "seen_finale": false}
	save()


func is_done(id: String) -> bool:
	return data["done"].has(id)


func has_egg(id: String) -> bool:
	return data["eggs"].has(id)


func egg_count() -> int:
	return data["eggs"].size()


func done_count() -> int:
	return data["done"].size()


func all_eggs() -> bool:
	for l in LEVELS:
		if not has_egg(l["id"]):
			return false
	return true


func is_unlocked(index: int) -> bool:
	return index == 0 or is_done(LEVELS[index - 1]["id"])


func complete(id: String) -> void:
	data["done"][id] = true
	save()


## Returns true when the secret was not found before.
func find_egg(id: String) -> bool:
	if has_egg(id):
		return false
	data["eggs"][id] = true
	save()
	return true


func level_index(id: String) -> int:
	for i in LEVELS.size():
		if LEVELS[i]["id"] == id:
			return i
	return -1


# ------------------------------------------------------------------ scenes
func goto(path: String) -> void:
	if dialog_active:
		_dlg_cancel = true
		advanced.emit()
	tts_stop()
	set_touch_controls(false)
	_fade.color.a = 1.0
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
	var scene: Node = load(path).new()
	current_scene = scene
	get_tree().root.add_child.call_deferred(scene)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.35)


func goto_level(index: int) -> void:
	goto(LEVELS[index]["path"])


func _build_fade() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.size = Vector2(W, H)
	_fade_layer.add_child(_fade)
	_banner = Label.new()
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.position = Vector2(0, 110)
	_banner.size = Vector2(W, 80)
	_banner.add_theme_font_size_override("font_size", 44)
	_banner.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	_banner.add_theme_color_override("font_outline_color", Color(0.15, 0.05, 0.2))
	_banner.add_theme_constant_override("outline_size", 14)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	_fade_layer.add_child(_banner)


func banner(text: String, secs := 2.5) -> void:
	_banner.text = text
	_banner_t = secs
	_banner.visible = true


# ------------------------------------------------------------------ audio
func play_music(name: String, restart := false) -> void:
	if name == music_name and music.playing and not restart:
		music.stream_paused = false
		return
	music_name = name
	var st: AudioStream = _load("res://audio/music/%s.ogg" % name)
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = true
	music.stream = st
	music.stream_paused = false
	music.play()


func stop_music() -> void:
	music.stop()
	music_name = ""


func pause_music(paused: bool) -> void:
	music.stream_paused = paused


func sfx(name: String, pitch := 1.0, vol := 0.0) -> void:
	var st: AudioStream = _load("res://audio/sfx/%s.wav" % name)
	if st == null:
		return
	var p := _sfx_pool[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % _sfx_pool.size()
	p.stream = st
	p.pitch_scale = pitch
	p.volume_db = vol + float(SFX_TRIM.get(name, 0.0))
	p.play()


func fart(kind := "", pitch := -1.0, vol := 0.0) -> void:
	if kind == "":
		kind = FARTS[randi() % FARTS.size()]
	if pitch < 0.0:
		pitch = randf_range(0.85, 1.25)
	sfx(kind, pitch, vol)


func _load(path: String) -> Resource:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


# ------------------------------------------------------------------ speech
func tts_supported() -> bool:
	return DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH)


func tts_stop() -> void:
	if tts_supported() and not _voices.is_empty():
		DisplayServer.tts_stop()


## Speaks a line with the synthesized voice for `who`. Falls back to babble blips.
func speak(text: String, who: String) -> void:
	var vp: Array = VOICES.get(who, [0.8 + float(absi(who.hash()) % 60) / 100.0, 1.0])
	var clean := text.replace("*", "").replace("...", ", ").replace("—", ", ")
	if muted:
		return
	if tts_supported():
		if _voices.is_empty():
			_voices = DisplayServer.tts_get_voices_for_language("en")
		if not _voices.is_empty():
			var voice := _voices[0]
			# give the big characters their own voice when the browser has several
			if _voices.size() > 1 and who != "Narrator":
				voice = _voices[absi(who.hash()) % mini(_voices.size(), 6)]
			DisplayServer.tts_speak(clean, voice, 90, vp[0], vp[1], 0, true)
			return
	sfx("babble%d" % (1 + absi(who.hash()) % 3), clampf(vp[0] * 1.2, 0.5, 2.0))


func _build_dialog() -> void:
	_dlg_layer = CanvasLayer.new()
	_dlg_layer.layer = 40
	add_child(_dlg_layer)
	_dlg_root = Control.new()
	_dlg_root.size = Vector2(W, H)
	_dlg_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_dlg_root.visible = false
	_dlg_layer.add_child(_dlg_root)
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.06, 0.16, 0.93)
	sb.border_color = Color(0.6, 0.85, 0.3)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(16)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(110, 520)
	panel.size = Vector2(1060, 180)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dlg_root.add_child(panel)
	_dlg_name = Label.new()
	_dlg_name.position = Vector2(28, 12)
	_dlg_name.add_theme_font_size_override("font_size", 28)
	panel.add_child(_dlg_name)
	_dlg_text = Label.new()
	_dlg_text.position = Vector2(28, 54)
	_dlg_text.size = Vector2(1004, 110)
	_dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg_text.add_theme_font_size_override("font_size", 26)
	panel.add_child(_dlg_text)
	_dlg_hint = Label.new()
	_dlg_hint.text = "click / space  >>"
	_dlg_hint.position = Vector2(880, 140)
	_dlg_hint.add_theme_font_size_override("font_size", 18)
	_dlg_hint.add_theme_color_override("font_color", Color(0.6, 0.85, 0.3))
	panel.add_child(_dlg_hint)


func speaker_color(who: String) -> Color:
	if SPEAKER_COLORS.has(who):
		return SPEAKER_COLORS[who]
	var h := float(absi(who.hash()) % 1000) / 1000.0
	return Color.from_hsv(h, 0.45, 1.0)


## Shows lines of [speaker, text] one after another. Await it.
## Returns false if the scene changed while talking.
func talk(lines: Array) -> bool:
	dialog_active = true
	_dlg_cancel = false
	_dlg_root.visible = true
	_dlg_cooldown = 0.25
	for line: Array in lines:
		if _dlg_cancel:
			break
		var who: String = line[0]
		_dlg_name.text = who
		_dlg_name.add_theme_color_override("font_color", speaker_color(who))
		_dlg_text.text = line[1]
		_dlg_text.visible_characters = 0
		_type_pos = 0.0
		_typing = true
		speak(line[1], who)
		await advanced
	tts_stop()
	_dlg_root.visible = false
	dialog_active = false
	var ok := not _dlg_cancel
	_dlg_cancel = false
	return ok


# ------------------------------------------------------------------ touch controls
func _circle_tex(radius: int, col: Color) -> ImageTexture:
	var img := Image.create(radius * 2, radius * 2, false, Image.FORMAT_RGBA8)
	for y in radius * 2:
		for x in radius * 2:
			var d := Vector2(x - radius + 0.5, y - radius + 0.5).length()
			var a := clampf(radius - d, 0.0, 1.0)
			var rim := 1.0 if d > radius - 5 else 0.0
			img.set_pixel(x, y, Color(col.r + rim * 0.3, col.g + rim * 0.3, col.b + rim * 0.3, col.a * a))
	return ImageTexture.create_from_image(img)


func _touch_button(parent: Node, action: String, pos: Vector2, radius: int, text: String) -> TouchScreenButton:
	var b := TouchScreenButton.new()
	b.texture_normal = _circle_tex(radius, Color(0.2, 0.15, 0.3, 0.45))
	b.texture_pressed = _circle_tex(radius, Color(0.5, 0.8, 0.3, 0.6))
	var shape := CircleShape2D.new()
	shape.radius = radius
	b.shape = shape
	b.action = action
	b.position = pos - Vector2(radius, radius)
	b.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
	parent.add_child(b)
	var l := Label.new()
	l.text = text
	l.size = Vector2(radius * 2, radius * 2)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 40 if text.length() < 3 else 22)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
	return b


func _build_touch() -> void:
	_touch_layer = CanvasLayer.new()
	_touch_layer.layer = 30
	add_child(_touch_layer)
	_touch_dpad = Node2D.new()
	_touch_layer.add_child(_touch_dpad)
	var c := Vector2(150, 560)
	_touch_button(_touch_dpad, "up", c + Vector2(0, -78), 44, "^")
	_touch_button(_touch_dpad, "down", c + Vector2(0, 78), 44, "v")
	_touch_button(_touch_dpad, "left", c + Vector2(-78, 0), 44, "<")
	_touch_button(_touch_dpad, "right", c + Vector2(78, 0), 44, ">")
	_touch_fart = _touch_button(_touch_layer, "fart", Vector2(1140, 570), 70, "FART")
	_touch_fart_label = _touch_fart.get_child(0)
	set_touch_controls(false)


## Shows the on-screen d-pad / action button (only ever visible on touch screens).
func set_touch_controls(on: bool, dpad := true, action_text := "FART") -> void:
	if _touch_layer == null:
		return
	on = on and DisplayServer.is_touchscreen_available()
	_touch_layer.visible = on
	_touch_dpad.visible = on and dpad
	_touch_fart_label.text = action_text
