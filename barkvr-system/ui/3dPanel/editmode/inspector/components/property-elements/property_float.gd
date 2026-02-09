class_name PropertyFloat
extends PropertyBase
## Property editor for any float properties.
##
## Currently only displays a basic LineEdit.
## A system similar to the EditorSpinSlider is in consideration.



## The LineEdit used to edit the property.
@onready var line_edit: LineEdit = %LineEdit

## Expression used for executing mathematical expressions.
var expression = Expression.new()



func _setup() -> void:
	line_edit.text_changed.connect(_on_line_edit_text_changed)
	line_edit.editing_toggled.connect(_on_line_edit_editing_toggled)

func _update_visual() -> void:
	# Value is rounded for readability.
	line_edit.text = str( snapped(target[property_name], 0.0001) )



## Called when the text of the LineEdit is manually changed.
## Setting the text via code does not trigger this.
func _on_line_edit_text_changed(new_text: String) -> void:
	# Set directly to avoid spamming the undo-system.
	emit_changed(new_text.to_float(), false)

## Called when editing starts/ends on the LineEdit.
## Used to do evaluations of mathematical expressions when editing ends.
func _on_line_edit_editing_toggled(toggled_on: bool) -> void:
	if toggled_on: return

	# Discard on parse error, reset LineEdit to property value.
	var error: Error = expression.parse(line_edit.text)
	if error != OK:
		_update_visual()
		return

	var result = expression.execute()

	# Discard on execution failure, reset LineEdit to property value.
	if expression.has_execute_failed():
		_update_visual()
		return

	emit_changed(float(result))
	_update_visual()

	line_edit.release_focus()



func _get_editing_state() -> bool:
	return line_edit.is_editing()
