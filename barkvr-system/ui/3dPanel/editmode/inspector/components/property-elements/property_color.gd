class_name PropertyColor
extends PropertyBase
## Property editor for Color properties.
##
## Description.



## A list of every type of color value and their associated LineEdit.
@export var line_edit_list: Dictionary[String, LineEdit]

## A ColorRect to display the current color directly.
@onready var color_rect: ColorRect = %ColorRect
## The OptionButton used to select the color profile type.
@onready var option_button: OptionButton = %OptionButton
## The TabContainer displaying the various LineEdits.
@onready var tab_container: TabContainer = %TabContainer



func _setup() -> void:
	option_button.item_selected.connect(_on_option_button_item_selected)
	for field: String in line_edit_list:
		line_edit_list[field].text_changed.connect(_on_line_edit_text_changed.bind(field))

func _update_visual() -> void:
	# Should be fine to just leave this as-is, probably.
	if target.get(property) == null: return

	var property_value: Color = target.get(property)
	color_rect.color = property_value

	for field: String in line_edit_list:
		var field_id: String = field.split(":")[1] if field.contains(":") else field
		match field_id:
			"a": line_edit_list[field].text = str(property_value.a)
			"r": line_edit_list[field].text = str(property_value.r)
			"g": line_edit_list[field].text = str(property_value.g)
			"b": line_edit_list[field].text = str(property_value.b)
			"h": line_edit_list[field].text = str(property_value.h)
			"s": line_edit_list[field].text = str(property_value.s)
			"v": line_edit_list[field].text = str(property_value.v)
			"hex": line_edit_list[field].text = property_value.to_html().capitalize()



## Used to switch the TabContainer to the correct color type.
func _on_option_button_item_selected(index: int) -> void:
	tab_container.current_tab = index

## Called when the text of a LineEdit is manually changed.
## Setting the text via code does not trigger this.
func _on_line_edit_text_changed(new_text: String, field: String) -> void:
	var field_id: String = field.split(":")[1] if field.contains(":") else field

	match field_id:
		"a": emit_changed(float(new_text), false, "a")
		"r": emit_changed(float(new_text), false, "r")
		"g": emit_changed(float(new_text), false, "g")
		"b": emit_changed(float(new_text), false, "b")
		"h": emit_changed(float(new_text), false, "h")
		"s": emit_changed(float(new_text), false, "s")
		"v": emit_changed(float(new_text), false, "v")
		"hex":
			# Prevent errors caused by Color.html with invalids.
			if not new_text.is_valid_html_color(): return
			emit_changed(Color.html(new_text), false)

	color_rect.color = target.get(property)



func _get_editing_state() -> bool:
	var return_value: bool = false

	for field: String in line_edit_list:
		if line_edit_list[field].is_editing():
			return_value = true
			break

	return return_value
