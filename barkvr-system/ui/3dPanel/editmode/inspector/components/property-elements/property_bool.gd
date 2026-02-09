class_name PropertyBool
extends PropertyBase
## Property editor for boolean properties.
##
## Displays a checkbox to edit boolean properties with.
## Boolean properties seem to not have a reset value during runtime,
## this results in the reset button never appearing.



## The checkbox used to display and edit the property.
@onready var check_box: CheckBox = %CheckBox



func _setup() -> void:
	check_box.toggled.connect(_on_check_box_toggled)

func _on_data_set(_property: Dictionary) -> void:
	# Unsure as to why this is here, carried over from Zodie's old version.
	if property_name.contains("/"):
		queue_free()
		return
	check_box.set_pressed_no_signal(target.get(property_name))

func _update_visual() -> void:
	check_box.set_pressed_no_signal(target.get(property_name))



func _on_check_box_toggled(toggled_on: bool) -> void:
	emit_changed(toggled_on)
