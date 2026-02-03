class_name PropertyVectorBase
extends PropertyBase
## Property editor for any vector-based properties.
##
## Description.



## A list of every vector axis and their associated LineEdit.
@export var line_edit_list: Dictionary[String, LineEdit]
## The button used to link the ratios of each axis.
@export var button_ratio_link: TextureButton

## Expression used for executing mathematical expressions.
var expression = Expression.new()



func _setup() -> void:
	for axis: String in line_edit_list:
		line_edit_list[axis].text_changed.connect(_on_line_edit_text_changed.bind(axis))
		line_edit_list[axis].editing_toggled.connect(_on_line_edit_editing_toggled.bind(axis))

# TODO: Finish linkable ratio stuff.
# For some reason this just exists for things that don't have it in the EditorInspector.
#func _on_data_set(property: Dictionary) -> void:
#	if property.hint & PROPERTY_HINT_LINK:
#		button_ratio_link.visible = true
#		button_ratio_link.set_pressed_no_signal(true)

func _update_visual() -> void:
	for axis: String in line_edit_list:
		set_axis_text(axis)

## Dynamically sets the string of a LineEdit to show int or float values.
## Float values are rounded for readability.
func set_axis_text(axis: String) -> void:
	if typeof(target[property_name][axis]) == TYPE_INT: # Direct.
		line_edit_list[axis].text = str( target[property_name][axis] )
	else: # Dynamic rounding.
		line_edit_list[axis].text = str( snapped(target[property_name][axis], 0.0001) )



## Called when the text of a LineEdit is manually changed.
## Setting the text via code does not trigger this.
func _on_line_edit_text_changed(new_text: String, axis: String) -> void:
	# Set directly to avoid spamming the undo-system.
	target[property_name][axis] = float(new_text)

## Called when editing starts/ends on a LineEdit.
## Used to do evaluations of mathematical expressions when editing ends.
func _on_line_edit_editing_toggled(toggled_on: bool, axis: String) -> void:
	if toggled_on: return

	# Get current line edit.
	var line_edit: LineEdit = line_edit_list[axis]

	# Discard on parse error, reset LineEdit to property value.
	var error: Error = expression.parse(line_edit.text)
	if error != OK:
		set_axis_text(axis)
		return

	var result = expression.execute()

	# Discard on execution failure, reset LineEdit to property value.
	if expression.has_execute_failed():
		set_axis_text(axis)
		return

	set_value(float(result), ":" + axis)
	set_axis_text(axis)

	# This only helps with the visual at the current moment.
	# The focus detection mechanism doesn't actually recognize these, movement remains locked.
	# TODO: Remove these comments whenever this actually works.
	line_edit.release_focus()



func _get_editing_state() -> bool:
	var return_value: bool = false

	for axis: String in line_edit_list:
		if line_edit_list[axis].is_editing():
			return_value = true
			break

	return return_value
