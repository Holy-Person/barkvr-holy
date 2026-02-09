class_name PropertyMultilineText
extends PropertyBase
## Property editor for multiline String properties.
##
## Displays a large TextEdit to edit Strings with.
## Used for Strings with the property hint of PROPERTY_HINT_MULTILINE_TEXT.



## The TextEdit used to display and edit the property.
@onready var text_edit: TextEdit = %TextEdit



func _setup() -> void:
	text_edit.text_changed.connect(_on_text_edit_text_changed)



func _update_visual() -> void:
	text_edit.set_text(target.get(property_name))



## Called when the text of the TextEdit changes.
func _on_text_edit_text_changed() -> void:
	# Set directly to avoid spamming the undo system.
	# There is currently no good way of handling these with the undo system.
	emit_changed(text_edit.text, false)



func _get_editing_state() -> bool:
	return text_edit.has_focus()
