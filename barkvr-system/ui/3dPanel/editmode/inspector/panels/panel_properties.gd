extends InspectorPanel



@onready var target_name_line: LineEdit = %TargetName

@onready var button_documentation: Button = %ButtonDocumentation
@onready var button_previous: Button = %ButtonPrevious
@onready var button_next: Button = %ButtonNext
@onready var button_history: Button = %ButtonHistory

@onready var property_list: InspectorPropertyList = %PropertyList



func _ready() -> void:
	target_name_line.text_changed.connect(_on_target_name_line_text_changed)

func _on_target_set(new_target: Node) -> void:
	if not is_instance_valid(new_target): return

	# Set text in TargetName LineEdit.
	if new_target.has_meta(&"display_name"):
		target_name_line.text = new_target.get_meta(&"display_name")
	elif "name" in new_target and new_target.name:
		target_name_line.text = new_target.name

	property_list.edit.call_deferred(new_target)



## Change the name of the currently selected node by typing in the target name field.
func _on_target_name_line_text_changed(new_text: String) -> void:
	if not target: return

	target.set_meta(&"display_name", new_text)
	target.name = target.name
