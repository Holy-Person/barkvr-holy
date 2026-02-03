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



# TODO: Free self if object ever becomes invalid, maybe in _process?
func edit(object: Object) -> void:
	if v_box_container: v_box_container.queue_free()
	current_object = object

	if not is_instance_valid(object): return

	print("Setting target in: ",self, " to look at: ", object)

	v_box_container = VBoxContainer.new()
	v_box_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_box_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(v_box_container)

	# The currently active VBoxContainer, used to track selection changes.
	var current_v_box: VBoxContainer = v_box_container

	await _generate_property_list(object)

	# Ensure selection hasn't changed.
	if current_v_box != v_box_container: return

	# Remove emtpy category headers.
	for child in v_box_container.get_children():
		if child is PropertyCategory:
			child.check_empty()



## Returns the object currently selected in this inspector.
func get_edited_object() -> Object:
	return current_object



func _generate_property_list(object: Object) -> void:
	var previous_iteration_tick: int = Time.get_ticks_msec()

	# The currently active VBoxContainer, used to track selection changes.
	var current_v_box: VBoxContainer = v_box_container

	# Last spawned category to parent fields under.
	var current_category: PropertyCategory
	var current_group: FoldableContainer
	var current_group_hint: String = ""

	# Button group to ensure only one field is active at a time.
	var list_button_group := ButtonGroup.new()

	for property: Dictionary in object.get_property_list():
		# Delay to prevent everything from loading at once, prevents stutters.
		if previous_iteration_tick + 1 < Time.get_ticks_msec():
			await get_tree().process_frame
			previous_iteration_tick = Time.get_ticks_msec()

		# Discard if selection has changed.
		if current_v_box != v_box_container: return
		if not is_instance_valid(object): return

		# TODO: Remove debug.
		print(property)

		match property.usage:
			PROPERTY_USAGE_CATEGORY: # Add a category header.
				current_category = _new_category(property)
				v_box_container.add_child(current_category)
				v_box_container.move_child(current_category, 0)

			PROPERTY_USAGE_GROUP: # Add a foldable group.
				# TODO: Indenting, more group parenting paths.
				current_group = _new_group(property)
				current_group_hint = property.hint_string
				if current_category:
					current_category.add_child(current_group)
				else:
					v_box_container.add_child(current_group)
			PROPERTY_USAGE_SUBGROUP: # Add a foldable subgroup.
				# TODO: Actually make them "sub" groups.
				# Also basically all of their logic.
				var group: FoldableContainer = _new_group(property)
				if current_category:
					current_category.add_child(group)
				else:
					v_box_container.add_child(group)

			var usage when usage & PROPERTY_USAGE_EDITOR || usage & PROPERTY_USAGE_INTERNAL:
				var property_field: PropertyBase = _new_property(property)
				if not property_field: continue

				# Parenting.
				if not current_group_hint.is_empty() && property.name.begins_with(current_group_hint):
					current_group.get_child(0).add_child(property_field)
				elif current_category:
					current_category.add_child(property_field)
				else:
					v_box_container.add_child(property_field)

				property_field.button_group = list_button_group
				property_field.scroll_container = self
				property_field.set_data(object, property)
			_:
				continue



func _new_category(property: Dictionary) -> PropertyCategory:
	var category: PropertyCategory = PROPERTY_CATEGORY.instantiate()
	category.set_data(property)
	return category

func _new_group(property: Dictionary) -> FoldableContainer:
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
