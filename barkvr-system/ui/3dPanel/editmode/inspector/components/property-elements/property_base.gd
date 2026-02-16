class_name PropertyBase
extends Container
## Custom class for editing properties that can be added to the PropertyPanel.
##
## Contains all variables that every property uses, as well as override functions for easy management.



signal property_changed(property: StringName, value: Variant, record_undo: bool)
signal property_deleted(property: StringName)
signal request_refresh()



## Checkable properties have a checkbox for nullable variant types.
var checkable: bool = false:
	set(value):
		checkable = value
		if ui_button_checkable: ui_button_checkable.visible = value

## Deletable properties can be deleted by the user.
var deletable: bool = false:
	set(value):
		deletable = value
		if ui_button_delete: ui_button_delete.visible = value

## Set this property to change the text of the label.
var label: String:
	set(value):
		label = value
		if ui_label: ui_label.text = value

## The button group used for the background button on all properties.
## Ensures only one property is highlighted at any one time.
## Background button will not be visible without setting this value.
var button_group: ButtonGroup:
	set(value):
		button_group = value
		if not ui_button_background: return
		ui_button_background.show()
		ui_button_background.button_group = value

## Scroll container used for visibility detection.
var scroll_container: ScrollContainer

## The target object the property belongs to.
var target: Object
## The target property path.
var property: StringName
## The PropertyHint of the property.
var hint: PropertyHint
## The hint_string of the property.
var hint_text: String
## Default value of this property, if one exists.
var revert_value: Variant

## Return whether the node is currently being edited.
var is_editing: bool:
	get: return _get_editing_state()



@onready var ui_button_background: Button = %ButtonBackground
@onready var ui_button_checkable: CheckBox = %ButtonCheckable
@onready var ui_texture_type: TextureRect = %TextureType
@onready var ui_label: Label = %Label
@onready var ui_button_reset: Button = %ButtonReset
@onready var ui_button_delete: Button = %ButtonDelete



func _ready() -> void:
	ui_button_checkable.toggled.connect(_on_checkable_toggled)
	ui_button_reset.pressed.connect(_on_reset_pressed)
	ui_button_delete.pressed.connect(_on_delete_pressed)

	if not target: return

	#	if (property.usage & PROPERTY_USAGE_CHECKED) > 0:
	#		ui_button_checkable.set_pressed_no_signal(true)

	# Set revert value if one exists.
	if target.property_can_revert(property):
		revert_value = target.property_get_revert(property)

	# One-time visual sets.
	ui_label.text = label
	ui_button_checkable.visible = checkable
	ui_button_delete.visible = deletable

	if button_group:
		ui_button_background.show()
		ui_button_background.button_group = button_group

	_setup()
	_check_update()



## Repeating function to update the visual in the inspector.
func _check_update() -> void:
	# Loop function on inspector update interval + own spawn offset.
	# TODO: Zodie seems to want to change this someday, it's unoptimized.
	create_tween().tween_callback(_check_update).set_delay(Engine.get_singleton(&"settings_manager").inspector_update_interval)

	# Don't update if the value is currently being edited or has no valid target.
	if is_instance_valid(target) and not is_editing and is_visible_in_tree():
		if scroll_container:
			var scroll_rect: Rect2 = scroll_container.get_global_rect()
			var rect: Rect2 = get_global_rect()

			# Check if this property is currently visible in the ScrollContainer, if not, do nothing.
			if not (rect.end.y > scroll_rect.position.y and rect.position.y < scroll_rect.end.y):
				return

		_update_base_visual()

## Update the base visual of the current property.
func _update_base_visual() -> void:
	var current_value: Variant = target.get(property)

	# Update checkbox if value is checkable.
	if checkable:
		ui_button_checkable.set_pressed_no_signal(current_value != null)

	# Show revert button if value and revert value don't match.
	# TODO: Might be worth allowing for resets when there is no given default value.
	if target.property_can_revert(property):
		match typeof(revert_value):
			TYPE_FLOAT:
				ui_button_reset.visible = not is_equal_approx(revert_value, current_value)
			TYPE_VECTOR2, TYPE_VECTOR3:
				ui_button_reset.visible = not revert_value.is_equal_approx(current_value)
			_:
				ui_button_reset.visible = revert_value != current_value

	_update_visual()



## Assigns object and property path to edit.
func set_object_and_property_data(object: Object, path: String, p_hint: PropertyHint = PROPERTY_HINT_NONE, p_hint_text: String = "") -> void:
	target = object
	property = path
	hint = p_hint
	hint_text = p_hint_text



## Called when the checkable button is toggled.
func _on_checkable_toggled(toggled_on: bool) -> void:
	if not is_instance_valid(target): return

	if toggled_on: emit_changed(revert_value)
	else: emit_changed(null)

	# Force check visual for fast & responsive change.
	_check_update()

## Called when the reset button is pressed.
func _on_reset_pressed() -> void:
	emit_changed(revert_value)

## Called when the delete button is pressed.
func _on_delete_pressed() -> void:
	property_deleted.emit(property)
	queue_free()



## Call this method to apply a value change.
## Setting [code]record_undo[/code] to [code]false[/code] sets the value directly.
## A suffix to the current property's name can be defined with [code]property_suffix[/code].
func emit_changed(value: Variant, record_undo: bool = true, property_suffix: String = "") -> void:
	if not is_instance_valid(target): return

	if property_suffix.is_empty():
		property_changed.emit(property, value, record_undo)
	else:
		property_changed.emit(property + ":" + property_suffix, value, record_undo)


## Override function.
## Called after the PropertyBase is ready.
func _setup() -> void:
	pass

## Override function.
## Update the unique visuals of the current property.
func _update_visual() -> void:
	pass

## Override function.
## Called on get of is_editing, used to check the current editing status.
func _get_editing_state() -> bool:
	return false
