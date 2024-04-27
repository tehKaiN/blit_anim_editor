class_name PolygonEditor
extends OpEditor

@export var _gizmo_scene: PackedScene
@onready var _gizmos: Control = %Gizmos
var _frame_rect: TextureRect
var _op: EditorMain.PolyOp


func init(op: EditorMain.BlitterOp, frame_rect: TextureRect) -> void:
	_frame_rect = frame_rect
	_op = op


func _ready() -> void:
	_update_op_gizmos()


func _update_op_gizmos() -> void:
	assert(_op != null)
	assert(_frame_rect != null)

	for point: EditorMain.PolyOp.Point in _op.points:
		var gizmo = _gizmo_scene.instantiate() as PolygonGizmo
		assert(gizmo != null)
		gizmo.data_changed.connect(_on_gizmo_data_changed)
		_gizmos.add_child(gizmo)
		gizmo.init(_frame_rect, point)


func _on_gizmo_data_changed() -> void:
	notify_data_changed()

