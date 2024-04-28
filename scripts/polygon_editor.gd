class_name PolygonEditor
extends OpEditor

enum Tool {NONE, ADD, REMOVE, MOVE}

@export var _gizmo_scene: PackedScene

@onready var _gizmos: Control = %Gizmos
@onready var _add_button: Button = %AddButton
@onready var _remove_button: Button = %RemoveButton
@onready var _move_button: Button = %MoveButton

var _image_frame: ImageFrame
var _op: EditorMain.PolyOp
var _is_button_used := false

var active_tool: Tool:
	get:
		if _add_button.button_pressed:
			return Tool.ADD
		if _remove_button.button_pressed:
			return Tool.REMOVE
		if _move_button.button_pressed:
			return Tool.MOVE
		return Tool.NONE

func init(op: EditorMain.BlitterOp, image_frame: ImageFrame) -> void:
	_image_frame = image_frame
	_op = op
	_image_frame.mouse_button_on_position.connect(_on_image_frame_mouse_button_on_position)


func try_remove_point(point: EditorMain.PolyOp.Point) -> bool:
	if _op.points.size() <= 3:
		return false
	_op.points.erase(point)
	notify_data_changed()
	_update_op_gizmos()
	return true


func _ready() -> void:
	_update_op_gizmos()


func _update_op_gizmos() -> void:
	assert(_op != null)
	assert(_image_frame != null)

	for gizmo: Control in _gizmos.get_children():
		gizmo.queue_free()

	for point: EditorMain.PolyOp.Point in _op.points:
		var gizmo = _gizmo_scene.instantiate() as PolygonGizmo
		assert(gizmo != null)
		gizmo.data_changed.connect(_on_gizmo_data_changed)
		_gizmos.add_child(gizmo)
		gizmo.init(_image_frame, point, self)


static func _square(x: float) -> float:
	return x*x


func _find_point_before_in_nearest_line(position: Vector2i) -> EditorMain.PolyOp.Point:
	var point_count := _op.points.size()
	var closest_distance := INF
	var closest_point_before :=  _op.points[0]
	for i: int in point_count:
		var la := _op.points[i]
		var lb := _op.points[(i + 1) % point_count]
		var pa := Vector2(la.pos)
		var pb := Vector2(lb.pos)
		var pos := Vector2(position)
		## https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line#Line_defined_by_two_points
		#var distance := (
			#absf((pb.x-pa.x)*(position.y-pa.y) - (position.x-pa.x)*(pb.y-pa.y)) /
			#sqrt(_square(pb.x - pa.x) + _square(pb.y - pa.y))
		#)
		var distance := minf(
			minf((pos - pa).length_squared(), (pos - pb).length_squared()),
			(pos - (pa + pb) / 2).length_squared()
		)
		if distance < closest_distance:
			closest_distance = distance
			closest_point_before = la
	return closest_point_before


func _on_gizmo_data_changed() -> void:
	notify_data_changed()


func _on_image_frame_mouse_button_on_position(is_pressed: bool, mouse_position: Vector2i) -> void:
	if is_pressed && !_is_button_used:
		_is_button_used = true
		if _add_button.button_pressed:
			var point_before := _find_point_before_in_nearest_line(mouse_position)
			_op.points.insert(_op.points.find(point_before) + 1, EditorMain.PolyOp.Point.new(mouse_position))
			notify_data_changed()
			_update_op_gizmos()
	elif !is_pressed:
		_is_button_used = false
