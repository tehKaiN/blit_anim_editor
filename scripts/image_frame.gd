class_name ImageFrame
extends TextureRect


signal mouse_button_on_position(is_down: bool, position: Vector2i)

var picture_scale := 1

func _gui_input(event: InputEvent) -> void:
	if event.is_action("lmb"):
		var position := get_local_mouse_position() / picture_scale
		mouse_button_on_position.emit(event.is_pressed(), position)
		accept_event()
