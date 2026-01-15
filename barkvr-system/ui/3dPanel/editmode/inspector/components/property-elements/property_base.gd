class_name PropertyBase
extends Container
## Custom class for editing properties that can be added to the PropertyPanel.
##
## Contains all variables that every property uses, as well as override functions for easy management.



@onready var ui_button_background: Button = %ButtonBackground
@onready var ui_name_container: MarginContainer = %NameField
@onready var ui_button_checkable: CheckBox = %ButtonCheckable
@onready var ui_label: Label = %Label
@onready var ui_button_reset: TextureButton = %ButtonReset
@onready var ui_editing_field: PanelContainer = %EditingField



## A checkbox for nullable variant types.
## TODO: Disable editable content while null.
var checkable: bool = false:
	set(value):
		checkable = value
		ui_button_checkable.visible = value

## Set this to false to[br]do thing.
var draw_label: bool = true:
	set(value):
		draw_label = value
		ui_name_container.visible = value

var label: String = "":
	set(value):
		label = value
		ui_label.text = value.capitalize()

var read_only: bool = false:
	set(value):
		read_only = value
		# TODO: Read only state.

var button_group: ButtonGroup:
	set(value):
		button_group = value
		ui_button_background.button_group = button_group

# Type ignores naming conventions.
var event_manager: Bark_Journal

var target: Object
var property_name: String

var is_editing: bool:
	get:
		return _get_editing_state()



func _ready() -> void:
	event_manager = Engine.get_singleton(&"event_manager")

	_setup()

	_check_update()

## Override function.
## Called after the PropertyBase is ready.
func _setup() -> void:
	pass



func _check_update() -> void:
	var parent: ScrollContainer = get_parent_control().get_parent_control()

	# Don't update if the value is currently being edited.
	if target and parent and not is_editing:
		var parent_rect: Rect2 = parent.get_global_rect()
		var rect: Rect2 = get_global_rect()

		# Check if this property is currently visible in the ScrollContainer.
		if (rect.end.y > parent_rect.position.y and rect.position.y < parent_rect.end.y):
			_update_visual()

	# Loop function on inspector update interval + own spawn offset.
	# TODO: Zodie seems to want to change this someday, it's unoptimized.
	create_tween().tween_callback(_check_update).set_delay(Engine.get_singleton(&"settings_manager").inspector_update_interval)

## Override function.
## Update the visual of the current property.
func _update_visual() -> void:
	pass



## Set the target object and property data of this element, indended to be called before the node is ready.
func set_data(target_object: Object, property: Dictionary) -> void:
	target = target_object
	print(property)
	property_name = property.name

	if (property.usage & PROPERTY_USAGE_CHECKABLE) > 0:
		checkable = true

	label = property_name

	if target is Skeleton3D: # Singled out for autocomplete recognition.
		if property_name.contains("bones/"):
			label = "bone: " + target.get_bone_name( int(property_name.split("/")[1]) ) + " " + property_name.split("/")[-1]

	_on_data_set(property)

## Override function.
## Called after all data has been set.
func _on_data_set(_property: Dictionary) -> void:
	pass



## Override function.
## Called on get of is_editing.
func _get_editing_state() -> bool:
	return false



func _on_read_only_toggled() -> void:
	pass
