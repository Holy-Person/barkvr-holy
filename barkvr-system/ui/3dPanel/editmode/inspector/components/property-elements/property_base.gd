class_name PropertyBase
extends Container
## Base class for all inspector properties.
##
## Contains common variables and functions that all properties use.



@export var label: Label

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
## Called after the node is ready.
func _setup() -> void:
	pass



func _check_update() -> void:
	var parent: ScrollContainer = get_parent_control().get_parent_control()

	# Don't update if the value is currently being edited.
	if parent and not is_editing:
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



## Set the important data of the property, indended to be called before the node is ready.
func set_data(display_name: String, target_object: Object, new_property_name: String) -> void:
	if label: label.text = display_name
	target = target_object
	property_name = new_property_name

	_on_data_set()

## Override function.
## Called after all data has been set.
func _on_data_set() -> void:
	pass



## Override function.
## Called on get of is_editing.
func _get_editing_state() -> bool:
	return false
