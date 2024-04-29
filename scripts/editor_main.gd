class_name EditorMain
extends Control

class BlitterOp:
	var name: String

	func _init(op_name: String):
		name = op_name

	func apply(image: Image, scratch_image: Image, aux_image: Image) -> void:
		pass
	func create_editor(image_frame: ImageFrame) -> Control:
		return null


class BlitterOpCopyToAux extends BlitterOp:
	func apply(image: Image, scratch_image: Image, aux_image: Image) -> void:
		aux_image.copy_from(image)


class BlitterOpPasteFromAux extends BlitterOp:
	func apply(image: Image, scratch_image: Image, aux_image: Image) -> void:
		image.copy_from(aux_image)


class BlitterOpClear extends BlitterOp:
	func apply(image: Image, scratch_image: Image, aux_image: Image) -> void:
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


		func apply(image: Image, scratch_image: Image, aux_image: Image) -> void:
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


		func create_editor(image_frame: ImageFrame) -> Control:
			var editor := POLYGON_EDITOR.instantiate() as PolygonEditor
			editor.init(self, image_frame)
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

@export var frame_thumbnail_scene: PackedScene

@onready var _add_clear_button: Button = %AddClearButton
@onready var _add_polygon_button: Button = %AddPolygonButton
@onready var _copy_to_aux_button: Button = %CopyToAuxButton
@onready var _paste_from_aux_button: Button = %PasteFromAuxButton
@onready var op_tree: Tree = %OpTree
@onready var current_frame: ImageFrame = %CurrentFrame
@onready var frame_thumbnail_container: HBoxContainer = %FrameThumbnailContainer
@onready var frame_add_button: Button = %FrameAddButton
@onready var frame_remove_button: Button = %FrameRemoveButton

var current_op_editor: Control
var current_frame_image: Image
var scratch_image: Image
var aux_image: Image
var current_frame_texture: ImageTexture
var selected_item: TreeItem:
	set(value):
		if selected_item == value:
			return
		if current_op_editor:
			current_op_editor.queue_free()
			current_op_editor = null

		selected_item = value
		if value:
			var op := value.get_meta("op") as BlitterOp
			current_op_editor = op.create_editor(current_frame)
			if current_op_editor:
				get_tree().root.add_child(current_op_editor)
				current_op_editor.data_changed.connect(_on_editor_data_changed)


func _ready() -> void:
	var root_node := op_tree.create_item()
	root_node.set_text(0, "Root")
	_add_clear_button.pressed.connect(_on_add_clear_button_pressed)
	_add_polygon_button.pressed.connect(_on_add_polygon_button_pressed)
	_copy_to_aux_button.pressed.connect(_on_copy_to_aux_button_pressed)
	_paste_from_aux_button.pressed.connect(_on_paste_from_aux_button_pressed)

	op_tree.reordered.connect(_on_tree_reordered)
	op_tree.item_selected.connect(_on_tree_item_selected)

	frame_add_button.pressed.connect(_on_frame_add_button_pressed)
	frame_remove_button.pressed.connect(_on_frame_remove_button_pressed)

	current_frame_image = Image.create(320, 256, false, Image.FORMAT_RGB8)
	scratch_image = Image.create(320, 256, false, Image.FORMAT_RGB8)
	aux_image = Image.create(320, 256, false, Image.FORMAT_RGB8)
	current_frame_texture = ImageTexture.create_from_image(current_frame_image)
	current_frame.texture = current_frame_texture
	current_frame.get_parent().resized.connect(_on_frame_container_resized)

	_on_frame_add_button_pressed()
	_draw_frame_from_commands()


func _process(delta: float) -> void:
	pass


func _on_editor_data_changed() -> void:
	_draw_frame_from_commands()


func _on_copy_to_aux_button_pressed() -> void:
	var op_name := _get_free_op_name(op_tree, "ToAux")
	var op := BlitterOpCopyToAux.new(op_name)
	_add_op(op, _copy_to_aux_button.icon)


func _on_paste_from_aux_button_pressed() -> void:
	var op_name := _get_free_op_name(op_tree, "FromAux")
	var op := BlitterOpPasteFromAux.new(op_name)
	_add_op(op, _paste_from_aux_button.icon)

func _on_add_clear_button_pressed() -> void:
	var op_name := _get_free_op_name(op_tree, "Clear")
	var op := BlitterOpClear.new(op_name)
	_add_op(op, _add_clear_button.icon)

func _on_add_polygon_button_pressed() -> void:
	var color := Color(randf(), randf(), randf())
	var offs := Vector2i(randi() % 200, randi() % 200)
	var op_name := _get_free_op_name(op_tree, "Polygon")
	var op := BlitterOpPoly.new(
		op_name,
		[Vector2i(5, 5) + offs, Vector2i(50, 50) + offs, Vector2i(100, 10) + offs],
		color, true, true
	)
	_add_op(op, _add_polygon_button.icon)


func _on_tree_reordered() -> void:
	_draw_frame_from_commands()


func _on_tree_item_selected() -> void:
	selected_item = op_tree.get_selected()


func _on_frame_container_resized() -> void:
	#var scale_vector := (current_frame.get_parent() as Control).size / Vector2(320, 256)
	#var scale = mini(scale_vector.x, scale_vector.y)
	#current_frame.custom_minimum_size = Vector2i(320, 256) * scale
	pass

func _on_frame_add_button_pressed() -> void:
	var frame_thumbnail := frame_thumbnail_scene.instantiate() as FrameThumbnail
	frame_thumbnail_container.add_child(frame_thumbnail)
	frame_thumbnail.is_selected = true
	frame_thumbnail.text = str(frame_thumbnail_container.get_children().size())


func _on_frame_remove_button_pressed() -> void:
	var children := frame_thumbnail_container.get_children()
	if children.size() <= 1:
		return

	for i: int in children.size():
		var frame_thumbnail: FrameThumbnail = children[i]
		if frame_thumbnail.is_selected:
			var sibling: FrameThumbnail
			if i == 0:
				if children.size() > 1:
					sibling = children[i + 1]
			else:
				sibling = children[i - 1]
			sibling.is_selected = true
			frame_thumbnail.queue_free()
			break



func _get_free_op_name(op_tree: Tree, base_name: String) ->  String:
	var check_name := base_name

	if !op_tree.get_root().get_children().any(
		func(item: TreeItem):
			return item.get_text(0) == check_name
	):
		return check_name

	var i := 2
	while true:
		check_name = base_name + str(i)
		if !op_tree.get_root().get_children().any(
			func(item: TreeItem):
				return item.get_text(0) == check_name
		):
			break
		i += 1
	return check_name


func _draw_frame_from_commands() -> void:
	current_frame_image.fill(Color.BLACK)
	var ops : Array[BlitterOp] = []
	for child in op_tree.get_root().get_children():
			var op = child.get_meta("op") as BlitterOp
			ops.push_back(op)

	for op: BlitterOp in ops:
		op.apply(current_frame_image, scratch_image, aux_image)
	current_frame_texture.update(current_frame_image)


func _add_op(op: BlitterOp, icon: Texture2D) -> void:
	var item := op_tree.create_item()
	item.set_icon(0, icon)
	item.set_text(0, op.name)
	item.set_meta("op", op)
	_draw_frame_from_commands()
