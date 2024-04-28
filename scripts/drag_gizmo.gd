class_name DragGizmo
extends TextureRect

@export var unselected_texture: Texture
@export var selected_texture: Texture
@export var dragged_control: Control

var _is_dragging: bool:
	set(value):
		if _is_dragging == value:
			return
		_is_dragging = value
		_update_transparency()

var _is_mouse_inside: bool:
	set(value):
		if _is_mouse_inside == value:
			return
		_is_mouse_inside = value
		_update_transparency()

var _prev_mouse_position: Vector2

func _input(event: InputEvent) -> void:
	if event.is_action("lmb"):
		if event.is_pressed() && !_is_dragging && _is_mouse_inside:
			_is_dragging = true
			_prev_mouse_position = get_global_mouse_position()
			texture = selected_texture
			#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			get_viewport().set_input_as_handled()
		elif event.is_released() && _is_dragging:
			_is_dragging = false
			texture = unselected_texture
			#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_viewport().set_input_as_handled()


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_update_transparency()

func _process(delta: float) -> void:
	if _is_dragging:
		var mouse_position := get_global_mouse_position()
		var delta_pos := mouse_position - _prev_mouse_position
		dragged_control.drag_by(delta_pos)
		_prev_mouse_position = mouse_position


func _update_transparency() -> void:
	var alpha := 1.0 if _is_dragging || _is_mouse_inside else .5
	modulate = Color(1.0, 1.0, 1.0, alpha)


func _on_mouse_entered() -> void:
	_is_mouse_inside = true


func _on_mouse_exited() -> void:
	_is_mouse_inside = false
