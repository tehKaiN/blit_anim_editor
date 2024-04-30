class_name OpTreeEditor
extends VBoxContainer

signal op_added()
signal tree_reordered()
signal op_selection_changed()

@onready var _add_clear_button: Button = %AddClearButton
@onready var _add_polygon_button: Button = %AddPolygonButton
@onready var _copy_to_aux_button: Button = %CopyToAuxButton
@onready var _paste_from_aux_button: Button = %PasteFromAuxButton
@onready var op_tree: Tree = %OpTree

var _root_node: TreeItem

var frame_data: EditorMain.FrameData:
	set(value):
		if frame_data == value:
			return
		frame_data = value
		_fill_tree_with_frame_data()

var selected_op: EditorMain.BlitterOp:
	set(value):
		if selected_op == value:
			return
		selected_op = value
		op_selection_changed.emit()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_root_node = op_tree.create_item()
	_root_node.set_text(0, "Root")

	_add_clear_button.pressed.connect(_on_add_clear_button_pressed)
	_add_polygon_button.pressed.connect(_on_add_polygon_button_pressed)
	_copy_to_aux_button.pressed.connect(_on_copy_to_aux_button_pressed)
	_paste_from_aux_button.pressed.connect(_on_paste_from_aux_button_pressed)

	op_tree.reordered.connect(_on_tree_reordered)
	op_tree.item_selected.connect(_on_tree_item_selected)

func _fill_tree_with_frame_data() -> void:
	for child: TreeItem in _root_node.get_children():
		_root_node.remove_child(child)
	for op: EditorMain.BlitterOp in frame_data.ops:
		_append_op_to_tree(op)


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


func _append_op(op: EditorMain.BlitterOp) -> void:
	frame_data.ops.push_back(op)
	_append_op_to_tree(op)
	op_added.emit()


func _append_op_to_tree(op: EditorMain.BlitterOp) -> void:
	var icon: Texture2D
	if op is EditorMain.BlitterOpCopyToAux:
		icon = _copy_to_aux_button.icon
	elif op is EditorMain.BlitterOpPasteFromAux:
		icon = _paste_from_aux_button.icon
	elif op is EditorMain.BlitterOpClear:
		icon = _add_clear_button.icon
	elif op is EditorMain.BlitterOpPoly:
		icon = _add_polygon_button.icon

	var item := op_tree.create_item(_root_node)
	item.set_icon(0, icon)
	item.set_text(0, op.name)
	item.set_meta("op", op)


func _on_copy_to_aux_button_pressed() -> void:
	var op_name := _get_free_op_name(op_tree, "ToAux")
	var op := EditorMain.BlitterOpCopyToAux.new(op_name)
	_append_op(op)


func _on_paste_from_aux_button_pressed() -> void:
	var op_name := _get_free_op_name(op_tree, "FromAux")
	var op := EditorMain.BlitterOpPasteFromAux.new(op_name)
	_append_op(op)

func _on_add_clear_button_pressed() -> void:
	var op_name := _get_free_op_name(op_tree, "Clear")
	var op := EditorMain.BlitterOpClear.new(op_name)
	_append_op(op)

func _on_add_polygon_button_pressed() -> void:
	var color := Color(randf(), randf(), randf())
	var offs := Vector2i(randi() % 200, randi() % 200)
	var op_name := _get_free_op_name(op_tree, "Polygon")
	var op := EditorMain.BlitterOpPoly.new(
		op_name,
		[Vector2i(5, 5) + offs, Vector2i(50, 50) + offs, Vector2i(100, 10) + offs],
		color, true, true
	)
	_append_op(op)


func _on_tree_reordered() -> void:
	tree_reordered.emit()


func _on_tree_item_selected() -> void:
	selected_op = op_tree.get_selected().get_meta("op")
