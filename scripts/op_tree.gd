extends Tree

signal reordered()


func _get_drag_data(at_position: Vector2) -> Variant:
	return get_item_at_position(at_position)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var drop_section := get_drop_section_at_position(at_position)
	if drop_section == -100 || drop_section == 0:
		drop_mode_flags &= ~DROP_MODE_INBETWEEN
		return false
	drop_mode_flags |= DROP_MODE_INBETWEEN
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var drop_section := get_drop_section_at_position(at_position)
	var hovered_item := get_item_at_position(at_position)

	if drop_section == -1:
		data.move_before(hovered_item)
	elif drop_section == 1:
		data.move_after(hovered_item)
	drop_mode_flags &= ~DROP_MODE_INBETWEEN
	print("drag stop")
	reordered.emit()
