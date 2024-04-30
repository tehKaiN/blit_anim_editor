class_name FrameThumbnail
extends MarginContainer

signal selected(frame_data: EditorMain.FrameData)

@onready var _button: Button = %Button
var frame_data: EditorMain.FrameData

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

func _ready() -> void:
	_button.toggled.connect(_on_button_toggled)

func _on_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		selected.emit(frame_data)
