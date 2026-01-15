class_name PropertyVectorBase
extends PropertyBase



@export var line_edit_list: Dictionary[String, LineEdit]

var expression = Expression.new()
# TODO: Add linkable bool
# TODO: Add rounding to stop floating point nightmares.



func _setup() -> void:
	for axis: String in line_edit_list:
		line_edit_list[axis].text_changed.connect(_on_line_edit_text_changed.bind(axis))
		line_edit_list[axis].editing_toggled.connect(_on_line_edit_editing_toggled.bind(axis))

func _update_visual() -> void:
	if not is_instance_valid(target):
		target = null
		for axis: String in line_edit_list:
			line_edit_list[axis].editable = false
			line_edit_list[axis].set_text("")
		return

	if property_name in target:
		for axis: String in line_edit_list:
			line_edit_list[axis].text = str(target[property_name][axis])



func _on_line_edit_text_changed(new_text: String, axis: String) -> void:
	if not is_editing: return

	event_manager.set_property(
		event_manager.root.get_path_to(target),
		property_name + ":" + axis,
		float(new_text)
	)

func _on_line_edit_editing_toggled(toggled_on: bool, axis: String) -> void:
	if toggled_on: return

	var line_edit: LineEdit = line_edit_list[axis]

	var error: Error = expression.parse(line_edit.text)
	if error != OK:
		line_edit.text = str(target[property_name][axis])
		return

	var result = expression.execute()

	if expression.has_execute_failed():
		line_edit.text = str(target[property_name][axis])
		return

	line_edit.text = str(result)
	event_manager.set_property(
		event_manager.root.get_path_to(target),
		property_name + ":" + axis,
		float(result)
	)



func _get_editing_state() -> bool:
	var return_value: bool = false

	for axis: String in line_edit_list:
		if line_edit_list[axis].has_focus():
			return_value = true
			break

	return return_value
