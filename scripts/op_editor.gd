class_name OpEditor
extends Control

signal data_changed()

func notify_data_changed() -> void:
	data_changed.emit()
