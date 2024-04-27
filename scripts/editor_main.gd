class_name EditorMain
extends Control

class BlitterOp:
	func apply(image: Image, scratch_image: Image) -> void:
		pass
	func create_editor(frame_rect: TextureRect) -> Control:
		return null


class PolyOp extends BlitterOp:
		class Point:
			var pos: Vector2i

			func _init(pos: Vector2i):
				self.pos = pos


		var points: Array[Point]
		var color: Color
		var is_fill: bool
		var is_keep_border: bool
		const POLYGON_EDITOR = preload("res://scenes/polygon_editor.tscn")

		func _init(positions: Array[Vector2i], color: Color, is_fill: bool, is_keep_border: bool) -> void:
			self.points = []
			for pos: Vector2i in positions:
				var point := Point.new(pos)
				points.push_back(point)

			self.color = color
			self.is_fill = is_fill
			self.is_keep_border = is_keep_border


		func apply(image: Image, scratch_image: Image) -> void:
			scratch_image.fill(Color.BLACK)
			var bounds := _calculate_bounds()
			#print("bounds: {0} {1}".format([bounds.position, bounds.end]))

			var i := 1
			while i < points.size():
				var prev := points[i - 1]
				var next := points[i]
				_draw_fill_line(scratch_image, prev.pos, next.pos)
				i += 1
			_draw_fill_line(scratch_image, points.back().pos, points.front().pos)
			if is_fill:
				_fill_polygon(scratch_image, image, bounds)


		func create_editor(frame_rect: TextureRect) -> Control:
			var editor := POLYGON_EDITOR.instantiate() as PolygonEditor
			editor.init(self, frame_rect)
			return editor


		func _draw_fill_line(scratch_image: Image, start: Vector2i, end: Vector2i) -> void:
			if end.y < start.y: # draw from top to bottom
				var temp := end
				end = start
				start = temp
			var delta := end - start
			var y := start.y + 1 # omit first pixel
			#print("draw line from {0} to {1}".format([start, end]))
			while y <= end.y:
				var x := start.x + (y - start.y) * delta.x / delta.y
				var out_color := Color.BLACK if scratch_image.get_pixel(x, y) == Color.WHITE else Color.WHITE # xor
				scratch_image.set_pixel(x, y, out_color)
				#print("{0},{1}".format([x, y]))
				y += 1


		func _fill_polygon(scratch_image: Image, image: Image, bounds: Rect2i) -> void:
			var is_fill = false
			var y := bounds.end.y
			while y >= bounds.position.y:
				var x = bounds.end.x
				while x >= bounds.position.x:
					if scratch_image.get_pixel(x, y) == Color.WHITE:
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


@onready var add_op_button: Button = %AddOpButton
@onready var op_tree: Tree = %OpTree
@onready var current_frame: TextureRect = %CurrentFrame

var current_op_editor: Control
var current_frame_image: Image
var scratch_image: Image
var current_frame_texture: ImageTexture
var selected_item: TreeItem:
	set(value):
		if selected_item == value:
			return
		if current_op_editor:
			current_op_editor.get_parent().remove_child(current_op_editor)
			current_op_editor = null

		selected_item = value
		if value:
			var op := value.get_meta("op") as BlitterOp
			current_op_editor = op.create_editor(current_frame)
			if current_op_editor:
				get_tree().root.add_child(current_op_editor)
				current_op_editor.data_changed.connect(_on_editor_data_changed)


func _ready() -> void:
	var tree_node := op_tree.create_item()
	tree_node.set_text(0, "Root")
	add_op_button.pressed.connect(_on_add_button_pressed)
	op_tree.reordered.connect(_on_tree_reordered)
	op_tree.item_selected.connect(_on_tree_item_selected)

	current_frame_image = Image.create(320, 256, false, Image.FORMAT_RGB8)
	scratch_image = Image.create(320, 256, false, Image.FORMAT_RGB8)
	current_frame_texture = ImageTexture.create_from_image(current_frame_image)
	current_frame.texture = current_frame_texture
	current_frame.get_parent().resized.connect(_on_frame_container_resized)

	_draw_frame_from_commands()


func _process(delta: float) -> void:
	pass


static var item_index := 0

func _on_editor_data_changed() -> void:
	_draw_frame_from_commands()

func _on_add_button_pressed() -> void:
	var item := op_tree.create_item()
	item.set_text(0, "Op_{0}".format([item_index]))
	var offs := Vector2i(randi() % 200, randi() % 200)
	var color := Color(randf(), randf(), randf())
	item.set_meta("op", PolyOp.new(
		[Vector2i(5, 5) + offs, Vector2i(50, 50) + offs, Vector2i(100, 10) + offs],
		color, true, true)
	)
	item_index += 1
	_draw_frame_from_commands()

func _on_tree_reordered() -> void:
	_draw_frame_from_commands()


func _on_tree_item_selected() -> void:
	selected_item = op_tree.get_selected()


func _on_frame_container_resized() -> void:
	#var scale_vector := (current_frame.get_parent() as Control).size / Vector2(320, 256)
	#var scale = mini(scale_vector.x, scale_vector.y)
	#current_frame.custom_minimum_size = Vector2i(320, 256) * scale
	pass


func _draw_frame_from_commands() -> void:
	current_frame_image.fill(Color.BLACK)
	var ops : Array[BlitterOp] = []
	for child in op_tree.get_root().get_children():
			var op = child.get_meta("op") as BlitterOp
			ops.push_back(op)

	for op: BlitterOp in ops:
		op.apply(current_frame_image, scratch_image)
	current_frame_texture.update(current_frame_image)
