class_name PropertyBool
extends PropertyBase



@onready var check_box: CheckBox = %CheckBox



func _setup() -> void:
	check_box.toggled.connect(_on_check_box_toggled)

func _on_data_set(_property: Dictionary) -> void:
	if property_name in target:
		if property_name.contains("/"):
			queue_free()
			return
		check_box.button_pressed = target[property_name]

func _update_visual() -> void:
	if not is_instance_valid(target):
		target = null
		check_box.disabled = true
		check_box.set_text("")
		return

	if property_name in target:
		check_box.button_pressed = target[property_name]



func _on_check_box_toggled(toggled_on: bool) -> void:
	if not is_instance_valid(target) or not is_instance_valid(event_manager): return

	event_manager.set_property(
		event_manager.root.get_path_to(target),
		property_name,
		toggled_on
	)
