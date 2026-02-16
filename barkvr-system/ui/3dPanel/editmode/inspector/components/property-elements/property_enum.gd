class_name PropertyEnum
extends PropertyBase
## Property editor for enum properties.
##
## Displays an OptionButton to edit enums with.
## Enums can be of type int, String or StringName.



## Used to decide how to interact with the raw value.
var is_string_enum: bool = false

## The option button used to display and edit the enum.
@onready var option_button: OptionButton = %OptionButton



func _setup() -> void:
	option_button.item_selected.connect(_on_option_button_item_selected)

	# Discard if no hint text is provided.
	if hint_text.is_empty(): queue_free()

	is_string_enum = typeof(target.get(property)) != TYPE_INT

	# Leftover from previous version, unsure on function.
	if is_string_enum: option_button.add_item("None")

	# Add each option from hint_string.
	for option: String in hint_text.split(","):
		if option.contains(":"):
			# IDs can be directly specified as such: "option:integer"
			var split_option: PackedStringArray = option.split(":")
			option_button.add_item(split_option[0], split_option[1].to_int())
		else:
			option_button.add_item(option)

func _update_visual() -> void:
	if is_string_enum:
		option_button.selected = get_item_index_from_text(target.get(property))
	else:
		option_button.selected = target.get(property)



## Get the index of an item based on the displayed text.
func get_item_index_from_text(item_text: String) -> int:
	for i: int in option_button.item_count:
		if option_button.get_item_text(i) == item_text:
			return i
	return 0



func _on_option_button_item_selected(index: int) -> void:
	if is_string_enum:emit_changed(option_button.get_item_text(index))
	else: emit_changed(option_button.get_item_id(index))



func _get_editing_state() -> bool:
	return option_button.get_popup().visible
