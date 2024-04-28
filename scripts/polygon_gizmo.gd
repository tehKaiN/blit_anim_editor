class_name PolygonGizmo
extends Control

signal data_changed()

var _image_frame: ImageFrame
var _point: EditorMain.BlitterOpPoly.Point
var _editor: PolygonEditor

var is_drag_enabled: bool:
	get:
		return _editor.active_tool == PolygonEditor.Tool.MOVE

func init(image_frame: ImageFrame, point: EditorMain.BlitterOpPoly.Point, editor: PolygonEditor) -> void:
	_image_frame = image_frame
	_point = point
	_editor = editor
	global_position = _image_frame.global_position + Vector2(_point.pos)

func drag_by(delta_pos: Vector2) -> void:
	_point.pos += Vector2i(delta_pos)
	data_changed.emit()
	global_position = _image_frame.global_position + Vector2(_point.pos) # TODO: listen for position change of point pos


func try_handle_remove() -> bool:
	if _editor.active_tool == PolygonEditor.Tool.REMOVE:
		_editor.try_remove_point(_point)
		return true
	return false
