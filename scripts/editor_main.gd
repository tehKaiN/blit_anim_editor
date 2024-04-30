class_name EditorMain
extends Control

class FrameData:
	var ops: Array[BlitterOp] = []

class BlitterOp:
	var name: String

	func _init(op_name: String):
		name = op_name

	func apply(image: Image, _scratch_image: Image, _aux_image: Image) -> void:
		pass
	func create_editor(image_frame: ImageFrame) -> Control:
		return null


class BlitterOpCopyToAux extends BlitterOp:
	func apply(image: Image, _scratch_image: Image, _aux_image: Image) -> void:
		_aux_image.copy_from(image)


class BlitterOpPasteFromAux extends BlitterOp:
	func apply(image: Image, _scratch_image: Image, _aux_image: Image) -> void:
		image.copy_from(_aux_image)


class BlitterOpClear extends BlitterOp:
	func apply(image: Image, _scratch_image: Image, _aux_image: Image) -> void:
		image.fill(Color.BLACK)


class BlitterOpPoly extends BlitterOp:
		class Point:
			var pos: Vector2i

			func _init(pos: Vector2i):
				self.pos = pos


		var points: Array[Point]
		var color: Color
		var is_fill: bool
		var is_keep_border: bool
		const POLYGON_EDITOR = preload("res://scenes/polygon_editor.tscn")

		func _init(op_name: String, positions: Array[Vector2i], color: Color, is_fill: bool, is_keep_border: bool) -> void:
			super(op_name)
			self.points = []
			for pos: Vector2i in positions:
				var point := Point.new(pos)
				points.push_back(point)

			self.color = color
			self.is_fill = is_fill
			self.is_keep_border = is_keep_border


		func apply(image: Image, _scratch_image: Image, _aux_image: Image) -> void:
			_scratch_image.fill(Color.BLACK)
			var bounds := _calculate_bounds()
			#print("bounds: {0} {1}".format([bounds.position, bounds.end]))

			var i := 1
			while i < points.size():
				var prev := points[i - 1]
				var next := points[i]
				_draw_fill_line(_scratch_image, prev.pos, next.pos)
				i += 1
			_draw_fill_line(_scratch_image, points.back().pos, points.front().pos)
			if is_fill:
				_fill_polygon(_scratch_image, image, bounds)


		func create_editor(image_frame: ImageFrame) -> Control:
			var editor := POLYGON_EDITOR.instantiate() as PolygonEditor
			editor.init(self, image_frame)
			return editor


		func _draw_fill_line(_scratch_image: Image, start: Vector2i, end: Vector2i) -> void:
			if end.y < start.y: # draw from top to bottom
				var temp := end
				end = start
				start = temp
			var delta := end - start
			var y := start.y + 1 # omit first pixel
			#print("draw line from {0} to {1}".format([start, end]))
			while y <= end.y:
				var x := start.x + (y - start.y) * delta.x / delta.y
				var out_color := Color.BLACK if _scratch_image.get_pixel(x, y) == Color.WHITE else Color.WHITE # xor
				_scratch_image.set_pixel(x, y, out_color)
				#print("{0},{1}".format([x, y]))
				y += 1


		func _fill_polygon(_scratch_image: Image, image: Image, bounds: Rect2i) -> void:
			var is_fill = false
			var y := bounds.end.y
			while y >= bounds.position.y:
				var x = bounds.end.x
				while x >= bounds.position.x:
					if _scratch_image.get_pixel(x, y) == Color.WHITE:
						is_fill = !is_fill
						if is_keep_border:
							image.set_pixel(x, y, color)
					elif is_fill:
						image.set_pixel(x, y, color)
					x -= 1
				y -= 1


		func _calculate_bounds() -> Rect2i:
			var min := points[0].pos
			var max := points[0].pos
			for point: Point in points:
				if point.pos.x < min.x:
					min.x = point.pos.x
				if point.pos.x > max.x:
					max.x = point.pos.x
				if point.pos.y < min.y:
					min.y = point.pos.y
				if point.pos.y > max.y:
					max.y = point.pos.y
			var bounds := Rect2i(min, max - min)
			return bounds

@onready var _current_frame_preview: ImageFrame = %CurrentFrame
@onready var _frame_manager: FrameManager = %FrameManager
@onready var _op_tree_editor: OpTreeEditor = %OpTreeEditor

var _current_op_editor: Control
var _current_frame_image: Image
var _scratch_image: Image
var _aux_image: Image
var _current_frame_texture: ImageTexture


func _ready() -> void:
	_op_tree_editor.op_added.connect(_on_op_tree_editor_op_added)
	_op_tree_editor.tree_reordered.connect(_on_op_tree_editor_tree_reordered)
	_op_tree_editor.op_selection_changed.connect(_on_op_tree_editor_op_selection_changed)
	_frame_manager.frame_selected.connect(_on_frame_manager_frame_selected)

	_current_frame_image = Image.create(320, 256, false, Image.FORMAT_RGB8)
	_scratch_image = Image.create(320, 256, false, Image.FORMAT_RGB8)
	_aux_image = Image.create(320, 256, false, Image.FORMAT_RGB8)
	_current_frame_texture = ImageTexture.create_from_image(_current_frame_image)
	_current_frame_preview.texture = _current_frame_texture
	_current_frame_preview.get_parent().resized.connect(_on_frame_container_resized)

	_frame_manager.add_next_frame()
	_op_tree_editor.frame_data = _frame_manager.current_frame
	_draw_current_frame()


func _on_op_tree_editor_op_added() -> void:
	_draw_current_frame()


func _on_op_tree_editor_tree_reordered() -> void:
	_draw_current_frame()

func _on_op_tree_editor_op_selection_changed() -> void:
		if _current_op_editor:
			_current_op_editor.queue_free()
			_current_op_editor = null

		if _op_tree_editor.selected_op:
			_current_op_editor = _op_tree_editor.selected_op.create_editor(_current_frame_preview)
			if _current_op_editor:
				get_tree().root.add_child(_current_op_editor)
				_current_op_editor.data_changed.connect(_on_op_editor_data_changed)

func _on_op_editor_data_changed() -> void:
	_draw_current_frame()


func _on_frame_manager_frame_selected() -> void:
	_op_tree_editor.frame_data = _frame_manager.current_frame
	_draw_current_frame()


func _on_frame_container_resized() -> void:
	#var scale_vector := (_current_frame_preview.get_parent() as Control).size / Vector2(320, 256)
	#var scale = mini(scale_vector.x, scale_vector.y)
	#_current_frame_preview.custom_minimum_size = Vector2i(320, 256) * scale
	pass


func _draw_current_frame() -> void:
	_current_frame_image.fill(Color.BLACK)
	# Needs to draw all previous frames so that scratch image is properly set
	for frame: FrameData in _frame_manager.frames:
		for op: BlitterOp in frame.ops:
			op.apply(_current_frame_image, _scratch_image, _aux_image)
		if frame == _frame_manager.current_frame:
			break
	_current_frame_texture.update(_current_frame_image)

