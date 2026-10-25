extends Node
## Boot node: hands control to the Game autoload, which owns scene switching.


func _ready() -> void:
	Game.goto("res://scenes/title.gd")
