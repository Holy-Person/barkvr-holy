class_name PropertyInt
extends PropertyBase



@onready var spin_box: SpinBox = %SpinBox



func _setup() -> void:
	spin_box.value_changed.connect(_on_spin_box_value_changed)

func _update_visual() -> void:
	if not is_instance_valid(target):
		target = null
		spin_box.editable = false
		spin_box.set_value_no_signal(0)
		return

	if property_name in target:
		if target[property_name] == null: target[property_name] = null
		#spin_box.set_value_no_signal(target[property_name])



func _on_spin_box_value_changed(value: float) -> void:
	if not is_instance_valid(target) or not is_instance_valid(event_manager): return

	event_manager.set_property(
		event_manager.root.get_path_to(target),
		property_name,
		int(value)
	)



func _get_editing_state() -> bool:
	return spin_box.get_line_edit().has_focus()
