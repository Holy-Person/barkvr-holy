class_name InspectorPropertyList
extends ScrollContainer
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

	# Last spawned category to parent fields under.
	var current_category: Control

	# Button group to ensure only one field is active at a time.
	var list_button_group := ButtonGroup.new()

	for property: Dictionary in object.get_property_list():
		# Delay to prevent everything from loading at once, prevents stutters.
		if start_time + 1 < Time.get_ticks_msec():
			await get_tree().process_frame
			start_time = Time.get_ticks_msec()

		# Discard if selection has changed.
		if object != current_object: return
		if not is_instance_valid(object): return

		print(property)

		if property.usage == PROPERTY_USAGE_NONE:
			continue

		# Discard script variables that are not set to export.
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			if not property.usage & PROPERTY_USAGE_EDITOR:
				continue
		elif property.usage == PROPERTY_USAGE_STORAGE:
			continue

		# Add a category header.
		if property.usage & PROPERTY_USAGE_CATEGORY:
			# TODO: Send signal to detect empty categories.
			current_category = _new_category(property)

		# Add a foldable group.
		elif property.usage & PROPERTY_USAGE_GROUP:
			# TODO: Add fields as children to group.
			# This is a pain, some groups do not have a hint string to indicate their related properties.
			# It seems they might just grab anything coming after it at that point, needs testing.
			var group: Control = _new_group(property)
			if current_category:
				current_category.add_child(group)
			else:
				v_box_container.add_child(group)

		# TODO: Subgroups.
		elif property.usage & PROPERTY_USAGE_SUBGROUP:
			pass

		# Add as an editable property.
		else:
			var property_field: PropertyBase = _new_property(property)
			if not property_field: continue

			if current_category:
				current_category.add_child(property_field)
			else:
				v_box_container.add_child(property_field)

			property_field.button_group = list_button_group
			property_field.scroll_container = self
			property_field.set_data(object, property)



## Returns the object currently selected in this inspector.
func get_edited_object() -> Object:
	return current_object



func _new_category(property: Dictionary) -> Control:
	var category = PROPERTY_CATEGORY.instantiate()
	v_box_container.add_child(category)
	v_box_container.move_child(category, 0)
	category.set_data(property)
	return category

func _new_group(property: Dictionary) -> Control:
	var group: FoldableContainer = PROPERTY_GROUP.instantiate()
	group.title = property.name
	return group

func _new_property(property: Dictionary) -> PropertyBase:
	var property_field: PropertyBase

	match property.type:
		TYPE_BOOL:
			property_field = FIELD_BOOL.instantiate()
		TYPE_INT:
			# TODO: Could do custom layer fields: PROPERTY_HINT_LAYERS_2D_RENDER
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

	return property_field
