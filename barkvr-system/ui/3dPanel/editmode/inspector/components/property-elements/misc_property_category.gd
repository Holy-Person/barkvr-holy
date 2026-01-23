extends VBoxContainer



func set_data(property: Dictionary) -> void:
	var property_name: String = property.name
	%Label.text = property_name
	if property_name.ends_with(".gd"):
		%TextureRect.texture = get_editor_icon(&"GDScript")
	else:
		%TextureRect.texture = get_editor_icon(property_name)



## Returns the basic editor icon under the given icon_name.
## Returns NodeWarning icon instead if no icon exists under that name.
func get_editor_icon(icon_name: StringName) -> Texture2D:
	var icon_path: String = "res://barkvr-system/assets/icons/editor-icons/"+icon_name+".svg"
	if ResourceLoader.exists(icon_path, "Texture2D"):
		return ResourceLoader.load(icon_path, "Texture2D")

	# Default to NodeWarning if the requested icon wasn't found.
	return ResourceLoader.load("res://barkvr-system/assets/icons/editor-icons/Info.svg", "Texture2D")
