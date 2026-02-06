class_name PropertyString
extends PropertyBase
## Property editor for String properties.
##
## Displays a LineEdit to edit Strings with.



## The LineEdit used to display and edit the property.
@onready var line_edit: LineEdit = %LineEdit



func _setup() -> void:
	line_edit.text_changed.connect(_on_line_edit_text_changed)
	line_edit.editing_toggled.connect(_on_line_edit_editing_toggled)
	line_edit.text_submitted.connect(_on_line_edit_text_submitted)

func _on_data_set(property: Dictionary) -> void:
	# Set placeholder text if one is defined.
	if property.hint == PROPERTY_HINT_PLACEHOLDER_TEXT:
		line_edit.placeholder_text = property.hint_string



func _update_visual() -> void:
	line_edit.set_text(target.get(property_name))



## Called when the text of a LineEdit is manually changed.
## Setting the text via code does not trigger this.
func _on_line_edit_text_changed(new_text: String) -> void:
	# Set directly to avoid spamming the undo-system.
	target.set(property_name, new_text)

## Called when editing starts/ends on a LineEdit.
## Used to finalize the value when editing ends and turn it into an undoable step.
## NOTE: Undo system doesn't seem to fully support this, but it's better than spamming it.
func _on_line_edit_editing_toggled(toggled_on: bool) -> void:
	if toggled_on: return

	set_value(line_edit.text)

## Called when text is submitted using enter on a LineEdit.
## This ensures that focus is fully released.
func _on_line_edit_text_submitted(_new_text: String) -> void:
	line_edit.release_focus()



func _get_editing_state() -> bool:
	return line_edit.is_editing()
