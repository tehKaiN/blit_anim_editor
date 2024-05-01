class_name FrameManager
extends PanelContainer

signal frame_selected()

@export var frame_thumbnail_scene: PackedScene

@onready var frame_add_button: Button = %FrameAddButton
@onready var frame_remove_button: Button = %FrameRemoveButton
@onready var frame_thumbnail_container: HBoxContainer = %FrameThumbnailContainer
@onready var playback_timer: Timer = %PlaybackTimer

var frames: Array[EditorMain.FrameData]
var current_frame: EditorMain.FrameData

func _ready() -> void:
	frame_add_button.pressed.connect(_on_frame_add_button_pressed)
	frame_remove_button.pressed.connect(_on_frame_remove_button_pressed)
	frame_thumbnail_container.child_order_changed.connect(_on_thumbnail_container_child_order_changed)


func add_next_frame() -> void:
	var frame_data := EditorMain.FrameData.new()
	frames.push_back(frame_data)

	var frame_thumbnail := frame_thumbnail_scene.instantiate() as FrameThumbnail
	assert(frame_thumbnail != null)
	frame_thumbnail_container.add_child(frame_thumbnail)
	frame_thumbnail.selected.connect(_on_frame_thumbnail_selected)
	frame_thumbnail.frame_data = frame_data
	frame_thumbnail.is_selected = true


func _on_frame_thumbnail_selected(frame_data: EditorMain.FrameData) -> void:
	current_frame = frame_data
	frame_selected.emit()


func _on_frame_add_button_pressed() -> void:
	add_next_frame()


func _on_frame_remove_button_pressed() -> void:
	# TODO: remove frame from data

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
			frames.erase(frame_thumbnail.frame_data)
			frame_thumbnail.queue_free()
			sibling.is_selected = true
			break


func _on_thumbnail_container_child_order_changed() -> void:
	var children := frame_thumbnail_container.get_children()
	for i: int in children.size():
		(children[i] as FrameThumbnail).text = str(i + 1)
