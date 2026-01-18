class_name PropertyBase
extends Container
## Custom class for editing properties that can be added to the PropertyPanel.
##
## Contains all variables that every property uses, as well as override functions for easy management.



@onready var ui_button_background: Button = %ButtonBackground
@onready var ui_button_checkable: CheckBox = %ButtonCheckable
@onready var ui_texture_type: TextureRect = %TextureType
@onready var ui_label: Label = %Label
@onready var ui_button_reset: Button = %ButtonReset
@onready var ui_button_delete: Button = %ButtonDelete



## Checkable properties have a checkbox for nullable variant types.
var checkable: bool = false:
	set(value):
		checkable = value
		ui_button_checkable.visible = value
		# TODO: Disable editable content while null.

## Deletable properties can be deleted by the user.
var deletable: bool = false:
	set(value):
		deletable = value
		# TODO: Add option to delete property.

## Set this property to change the text of the label.
var label: String = "":
	set(value):
		label = value
		ui_label.text = value.capitalize()

## Whether or not the property can be edited.
var read_only: bool = false:
	set(value):
		read_only = value
		# TODO: Read only state.

## The button group used for the background button on all properties.
## Ensures only one property is highlighted at any one time.
var button_group: ButtonGroup:
	set(value):
		ui_button_background.button_group = value
	get:
		return ui_button_background.button_group

# Type ignores naming conventions.
## The event manager used for undo-able events.
var event_manager: Bark_Journal

## The target object the property belongs to.
var target: Object
## The property name of this property on the object.
var property_name: StringName
## Default value of this property, if one exists.
var property_revert_value: Variant

## Return whether the node is currently being edited.
var is_editing: bool:
	get:
		return _get_editing_state()



func _ready() -> void:
	event_manager = Engine.get_singleton(&"event_manager")

	ui_button_checkable.toggled.connect(_on_checkable_toggled)
	ui_button_reset.pressed.connect(_on_reset_pressed)
	ui_button_delete.pressed.connect(_on_delete_pressed)

	_setup()
	_check_update()

## Override function.
## Called after the PropertyBase is ready.
func _setup() -> void:
	pass



## Repeating function to update the visual in the inspector.
func _check_update() -> void:
	var parent: ScrollContainer = get_parent_control().get_parent_control().get_parent_control()

	# Don't update if the value is currently being edited or has no target.
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



## Set the target object and property data of this element.
func set_data(target_object: Object, property: Dictionary) -> void:
	target = target_object
	property_name = property.name

	# If the value is checkable, show the checkable button.
	if (property.usage & PROPERTY_USAGE_CHECKABLE) > 0:
		checkable = true

	# Set revert value if revert value exists.
	if target.property_can_revert(property_name):
		property_revert_value = property_get_revert(property_name)
		if property_revert_value != target.get(property_name):
			ui_button_reset.visible = true

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
## Called on get of is_editing, used to get the current editing status.
func _get_editing_state() -> bool:
	return false



func _on_read_only_toggled() -> void:
	pass

## Called when the checkable button is toggled.
func _on_checkable_toggled(_toggled_on: bool) -> void:
	# TODO: Does this set to null or some default value if unchecked? I think it's null.
	# Sets to default value if checked true, I think(?).
	pass

## Called when the reset button is pressed.
func _on_reset_pressed() -> void:
	set_value(property_revert_value)

## Called when the delete button is pressed.
func _on_delete_pressed() -> void:
	# TODO: There's no hint or usage to denote these, might just leave it as a UI thing with no function.
	pass

## Set the value of the property.
func set_value(value: Variant, property_suffix: String = "") -> void:
	if not is_instance_valid(target) or not is_instance_valid(event_manager): return
	if read_only: return

	# Show revert button if value is not the default.
	if target.property_can_revert(property_name):
		if property_revert_value != value:
			ui_button_reset.visible = true
		else:
			ui_button_reset.visible = false

	# Set property value via event manager to allow for undo.
	event_manager.set_property(
		event_manager.root.get_path_to(target),
		property_name + property_suffix,
		value
	)
