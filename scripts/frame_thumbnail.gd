class_name FrameThumbnail
extends MarginContainer

@onready var _button: Button = %Button

var is_selected: bool:
	get:
		return _button.button_pressed
	set(value):
		_button.button_pressed = value

var text: String:
	get:
		return _button.text
	set(value):
		_button.text = value
