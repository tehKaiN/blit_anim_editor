class_name PolygonGizmo
extends Control

signal data_changed()

var _frame_rect: TextureRect
var _point: EditorMain.PolyOp.Point

func init(frame_rect: TextureRect, point: EditorMain.PolyOp.Point) -> void:
	_frame_rect = frame_rect
	_point = point
	global_position = _frame_rect.global_position + Vector2(_point.pos)

func drag_by(delta_pos: Vector2) -> void:
	_point.pos += Vector2i(delta_pos)
	data_changed.emit()
	global_position = _frame_rect.global_position + Vector2(_point.pos) # TODO: listen for position change of point pos
