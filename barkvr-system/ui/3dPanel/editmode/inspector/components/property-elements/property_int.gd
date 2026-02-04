class_name PropertyInt
extends PropertyBase
## Property editor for integer properties.
##
## Displays a spinbox to edit integers with.



## The spinbox used to display and edit the property.
@onready var spin_box: SpinBox = %SpinBox



func _setup() -> void:
	spin_box.value_changed.connect(_on_spin_box_value_changed)
	spin_box.get_line_edit().text_submitted.connect(_on_spin_box_text_submitted)

	# Prevent null revert values.
	if property_revert_value == null:
		property_revert_value = 0

func _update_visual() -> void:
	# Do not set SpinBox value to null.
	if checkable and target.get(property_name) == null:
		spin_box.set_value_no_signal(property_revert_value)
		return
	spin_box.set_value_no_signal(target.get(property_name))



func _on_spin_box_value_changed(value: float) -> void:
	set_value( int(value) )

func _on_spin_box_text_submitted(_new_text: String) -> void:
	spin_box.get_line_edit().release_focus()



func _get_editing_state() -> bool:
	return spin_box.get_line_edit().is_editing()
