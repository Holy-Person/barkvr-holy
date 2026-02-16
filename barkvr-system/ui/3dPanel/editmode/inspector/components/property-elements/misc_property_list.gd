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

const FIELD_BOOL = preload("uid://bcgft7j8haksh")
const FIELD_INT = preload("uid://dyiaij1fj5sje")
const FIELD_FLOAT = preload("uid://po0psf0jy7wg")
const FIELD_STRING = preload("uid://bpcdhejgbrn6i")
const FIELD_MULTILINE_TEXT = preload("uid://ejwq7pjdhfty")
const FIELD_COLOR = preload("uid://1ynmsuc1l8yy")
const FIELD_VECTOR_2 = preload("uid://dsinfbuvvxpxu")
const FIELD_VECTOR_3 = preload("uid://d0negxx0bii55")
const FIELD_ENUM = preload("uid://bho6ojyyrbvsp")
#const FIELD_ARRAY = preload("uid://0v3uyc87pkoa")
#const FIELD_OBJECT = preload()



## The event manager used for undo-able events.
var event_manager: Bark_Journal # Type ignores naming conventions.
## The current object being edited.
var current_object: Object
## VBoxContainer to hold the properties.
var v_box_container: VBoxContainer



func _ready() -> void:
	event_manager = Engine.get_singleton(&"event_manager")

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

	await _generate_property_list(object, current_v_box)
	await get_tree().process_frame

	# Ensure selection hasn't changed.
	if current_v_box != v_box_container: return

	# Remove emtpy category headers.
	for child in current_v_box.get_children():
		if child is PropertyCategory:
			child.check_empty()



## Returns the object currently selected in this inspector.
func get_edited_object() -> Object:
	return current_object



func _generate_property_list(object: Object, v_box: VBoxContainer) -> void:
	# Last spawned category to parent fields under.
	var current_category: PropertyCategory
	# Button group to ensure only one field is active at a time.
	var list_button_group := ButtonGroup.new()

	var previous_iteration_tick: int
	for property: Dictionary in object.get_property_list():
		# Delay to prevent everything from loading at once, prevents stutters.
		if previous_iteration_tick + 1 > Time.get_ticks_msec(): await get_tree().process_frame
		previous_iteration_tick = Time.get_ticks_msec()

		# Discard if selection has changed.
		if v_box != v_box_container: return
		if not is_instance_valid(object): return

		var p_type: Variant.Type = property.type
		var p_name: String = property.name
		var p_hint: PropertyHint = property.hint
		var p_hint_text: String = property.hint_string
		var p_usage: int = property.usage

		# TODO: Remove debug.
		print(property)

		match p_usage:
			# Category header.
			PROPERTY_USAGE_CATEGORY:
				current_category = _new_category(property)
				v_box.add_child(current_category)
				v_box.move_child(current_category, 0)

			# NOTE: Too complicated to generate correctly, left out for the time being.
			# Foldable group.
			PROPERTY_USAGE_GROUP: continue
			# Foldable subgroup.
			PROPERTY_USAGE_SUBGROUP: continue

			# Property editor.
			var usage when p_usage & PROPERTY_USAGE_EDITOR || usage & PROPERTY_USAGE_INTERNAL:
				var property_editor: PropertyBase = instantiate_property_editor(object, p_type, p_name, p_hint, p_hint_text, p_usage)
				if not property_editor: continue

				property_editor.button_group = list_button_group
				property_editor.scroll_container = self
				property_editor.property_changed.connect(_on_property_field_property_changed)

				if current_category: current_category.add_child(property_editor)
				else: v_box.add_child(property_editor)



func _new_category(property: Dictionary) -> PropertyCategory:
	var category: PropertyCategory = PROPERTY_CATEGORY.instantiate()
	category.set_data(property)
	return category

## Set the value of the property via the event_manager. An optional suffix can be given to the property name.
func _on_property_field_property_changed(property: StringName, value: Variant, record_undo: bool) -> void:
	if not is_instance_valid(current_object) or not is_instance_valid(event_manager): return

	if not record_undo: # Set property directly.
		if property.contains(":"):
			var split: PackedStringArray = property.split(":")
			current_object[split[0]][split[1]] = value
		else:
			current_object[property] = value
	else: # Set property via event manager to register into the undo system.
		event_manager.set_property(
			event_manager.root.get_path_to(current_object),
			property,
			value
		)

## Creates a property editor that can be used to edit the specified property of an object.
static func instantiate_property_editor(object: Object, type: Variant.Type, path: String, hint: PropertyHint, hint_text: String, usage: int) -> PropertyBase:
	var field_scene: PackedScene

	match [type, hint]:
		[_, PROPERTY_HINT_ENUM]: field_scene = FIELD_ENUM
		[_, PROPERTY_HINT_MULTILINE_TEXT]: field_scene = FIELD_MULTILINE_TEXT
		#[_, PROPERTY_HINT_LAYERS_2D_RENDER]: TODO: Layer flag editor.
		[TYPE_BOOL, _]: field_scene = FIELD_BOOL
		[TYPE_INT, _]: field_scene = FIELD_INT
		[TYPE_FLOAT, _]: field_scene = FIELD_FLOAT
		[TYPE_STRING, _], [TYPE_STRING_NAME, _]: field_scene = FIELD_STRING
		[TYPE_COLOR, _]: field_scene = FIELD_COLOR
		[TYPE_VECTOR2, _], [TYPE_VECTOR2I, _]: field_scene = FIELD_VECTOR_2
		[TYPE_VECTOR3, _], [TYPE_VECTOR3I, _]: field_scene = FIELD_VECTOR_3
		#[TYPE_ARRAY, _]: field_scene = FIELD_ARRAY # TODO: Array editor.
		#[TYPE_OBJECT, _]: field_scene = FIELD_OBJECT # TODO: Object editor.
		[_, _]: print("Non handled property type/hint:\n\t%s/%s" % [type, hint])

	if not field_scene: return null
	var property_field: PropertyBase = field_scene.instantiate()

	property_field.set_object_and_property_data(object, path, hint, hint_text)

	if usage & PROPERTY_USAGE_CHECKED:
		property_field.checkable = true
		#property_field.checked = true
	elif usage & PROPERTY_USAGE_CHECKABLE:
		property_field.checkable = true

	property_field.label = path.capitalize()
	if object is Skeleton3D: # Singled out for autocomplete recognition.
		if path.contains("bones/"):
			property_field.label = "Bone: " + object.get_bone_name( int(path.split("/")[1]) ) + " " + path.split("/")[-1]

	return property_field
