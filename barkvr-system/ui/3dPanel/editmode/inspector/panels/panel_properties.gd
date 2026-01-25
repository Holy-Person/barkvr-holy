extends InspectorPanel



@onready var target_name_line: LineEdit = %TargetName

@onready var button_documentation: Button = %ButtonDocumentation

@onready var property_list: InspectorPropertyList = %PropertyList



func _ready() -> void:
	target_name_line.text_changed.connect(_on_target_name_line_text_changed)
	button_documentation.pressed.connect(_on_button_documentation_pressed)

func _on_target_set(new_target: Node) -> void:
	var is_target_valid: bool = is_instance_valid(new_target)

	target_name_line.editable = is_target_valid
	button_documentation.disabled = not is_target_valid

	property_list.edit.call_deferred(new_target)

	if not is_target_valid:
		target_name_line.text = ""
		return

	# Set text in TargetName LineEdit.
	if new_target.has_meta(&"display_name"):
		target_name_line.text = new_target.get_meta(&"display_name")
	elif "name" in new_target and new_target.name:
		target_name_line.text = new_target.name



## Change the name of the currently selected node by typing in the target name field.
func _on_target_name_line_text_changed(new_text: String) -> void:
	if not target: return

	target.set_meta(&"display_name", new_text)
	target.name = target.name

func _on_button_documentation_pressed() -> void:
	if not is_instance_valid(target): return

	var version_info: Dictionary = Engine.get_version_info()
	var target_class: String = target.get_class().to_lower()
	OS.shell_open("https://docs.godotengine.org/en/%s.%s/classes/class_%s.html" % [version_info.major, version_info.minor, target_class])
