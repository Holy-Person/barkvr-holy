class_name InspectorPropertyList
extends Container
## A control used to edit the properties of an object.
##
## This is the control that holds and generates the list to edit properties with.
## Based on Godot's EditorInspector.



# TODO: find a more optimized way to update field values
# This requires a PR to godot. they don't seem interested in the change
# but without it, it's impossible to do performant scene tracking - Zodie



const PROPERTY_CATEGORY = preload("uid://cw7vdx8shf5ca")
const PROPERTY_GROUP = preload("uid://bk3i20e6suery")

const FIELD_BOOL = preload("uid://bcgft7j8haksh")
const FIELD_INT = preload("uid://dyiaij1fj5sje")
const FIELD_FLOAT = preload("uid://po0psf0jy7wg")
const FIELD_STRING = preload("uid://bpcdhejgbrn6i")
const FIELD_COLOR = preload("uid://1ynmsuc1l8yy")
const FIELD_VECTOR_2 = preload("uid://dsinfbuvvxpxu")
const FIELD_VECTOR_3 = preload("uid://d0negxx0bii55")
const FIELD_ENUM = preload("uid://bho6ojyyrbvsp")


## Button group to ensure only one field is active at a time.
var list_button_group := ButtonGroup.new()

## The current object being edited.
var current_object: Object
## VBoxContainer to hold the properties.
var v_box_container: VBoxContainer



func edit(object: Object) -> void:
	if v_box_container: v_box_container.queue_free()
	current_object = object

	if not is_instance_valid(object): return

	print("Setting target in: ",self, " to look at: ", object)

	v_box_container = VBoxContainer.new()
	v_box_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_box_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(v_box_container)

	var start_time: float = Time.get_ticks_msec()

	for property: Dictionary in object.get_property_list():
		# Delay for performance.
		if start_time + 1 < Time.get_ticks_msec():
			await get_tree().process_frame
			start_time = Time.get_ticks_msec()

		# Discard if selection has changed.
		if object != current_object: return
		if not is_instance_valid(object): return

		print(property)

		# Unknown discard.
		if property.name == "owner":
			continue

		# Category headers.
		if (property.usage & PROPERTY_USAGE_CATEGORY) > 0:
			_add_category(property)
		# Groups. (Going to be really annoying to work with.)
		elif (property.usage & PROPERTY_USAGE_GROUP) > 0:
			_add_group(property)
		# Add as an editable property.
		else:
			_add_property(object, property)



## Returns the object currently selected in this inspector.
func get_edited_object() -> Object:
	return current_object



func _add_category(property: Dictionary) -> void:
	var category = PROPERTY_CATEGORY.instantiate()
	v_box_container.add_child(category)
	category.set_data(property)

func _add_group(property: Dictionary) -> void:
	var group: FoldableContainer = PROPERTY_GROUP.instantiate()
	group.title = property.name
	v_box_container.add_child(group)

func _add_property(object: Object, property: Dictionary) -> void:
	var property_field: PropertyBase

	match property.type:
		TYPE_BOOL:
			property_field = FIELD_BOOL.instantiate()
		TYPE_INT:
			if property.hint == PROPERTY_HINT_ENUM:
				property_field = FIELD_ENUM.instantiate()
				#tmp.set_data(fieldname, new_target, prop.name, prop)
			else:
				property_field = FIELD_INT.instantiate()
		TYPE_FLOAT:
			property_field = FIELD_FLOAT.instantiate()
		TYPE_STRING, TYPE_STRING_NAME:
			if property.hint == PROPERTY_HINT_ENUM:
				property_field = FIELD_ENUM.instantiate()
				#tmp.set_data(fieldname, new_target, prop.name, prop, true)
			else:
				property_field = FIELD_STRING.instantiate()
		TYPE_COLOR:
			property_field = FIELD_COLOR.instantiate()
		TYPE_VECTOR2, TYPE_VECTOR2I:
			property_field = FIELD_VECTOR_2.instantiate()
		TYPE_VECTOR3, TYPE_VECTOR3I:
			property_field = FIELD_VECTOR_3.instantiate()
		TYPE_ARRAY:
			pass
		TYPE_OBJECT:
			pass
		_:
			print("Non-handled type: ", property.type)

	if property_field:
		v_box_container.add_child(property_field)
		property_field.button_group = list_button_group
		property_field.set_data(object, property)
