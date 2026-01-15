extends InspectorPanel

# TODO: find a more optimized way to update field values
# This requires a PR to godot. they don't seem interested in the change
# but without it, it's impossible to do performant scene tracking

#const FIELD_ARRAY = preload("uid://dxshup2m2t62c")
#const FIELD_BOOL = preload("uid://bcgft7j8haksh")
#const FIELD_COLOR = preload("uid://1ynmsuc1l8yy")
#const FIELD_ENUM = preload("uid://dy1wide8xv5df")
#const FIELD_INT = preload("uid://d1t7rsyo8nq76")
#const FIELD_NUMBER = preload("uid://cbmgba1q1d8q5")
#const FIELD_OBJECT = preload("uid://dddtbbin6ty1l")
#const FIELD_STRING = preload("uid://3cx3afcwx3hw")

const FIELD_VECTOR_2 = preload("uid://dsinfbuvvxpxu")
const FIELD_VECTOR_3 = preload("uid://d0negxx0bii55")

# Type ignores naming conventions.
var event_manager : Bark_Journal

@onready var target_name_line: LineEdit = %TargetName

@onready var button_documentation: Button = %ButtonDocumentation
@onready var button_previous: Button = %ButtonPrevious
@onready var button_next: Button = %ButtonNext
@onready var button_history: Button = %ButtonHistory

@onready var scroll_list: VBoxContainer = %ScrollList

# Leftover here.
#@onready var activetoggle: CheckButton = $"VBoxContainer/titlebar/properties header/active/HBoxContainer/activetoggle"

#var target : Object = null

func _ready() -> void:
	event_manager = Engine.get_singleton(&"event_manager")

	_setup_signals()

func _setup_signals() -> void:
	#activetoggle.toggled.connect(func(on: bool):
	#	if target and is_instance_valid(target) and target is Node:
	#		event_manager.set_property(event_manager.root.get_path_to(target), "visible", on)
	#	)
	target_name_line.text_changed.connect(_on_target_name_line_text_changed)

func _on_target_set(new_target: Node) -> void:
	print("setting target in: ",self, "to look at: ",new_target)

	if new_target and new_target is Object:
		target = new_target
		if "name" in new_target and new_target.name:
			target_name_line.text = new_target.name
		if new_target.has_meta("display_name"):
			target_name_line.text = new_target.get_meta("display_name")

		#activetoggle.button_pressed = new_target.visible

		var start_time : float = Time.get_ticks_msec()
		for child in scroll_list.get_children():
			if start_time + 1 < Time.get_ticks_msec():
				await get_tree().process_frame
				start_time = Time.get_ticks_msec()
			child.queue_free()
		var prop_list :Array[Dictionary]= new_target.get_property_list()
		call_deferred("_add_fields", prop_list, new_target)

func _add_fields(property_list, new_target) -> void:
	while LocalGlobals.is_inspector_loading:
		await get_tree().process_frame
	LocalGlobals.is_inspector_loading = true

	var button_group := ButtonGroup.new()

	var start_time : float = Time.get_ticks_msec()

	for property in property_list:
		if start_time + 1 < Time.get_ticks_msec():
			await get_tree().process_frame
			start_time = Time.get_ticks_msec()

		if !is_instance_valid(new_target):
			return # Can cause inspector loading to get stuck at true

		if property.name == "owner":
			continue

		var property_field: PropertyBase
		match property.type:
			#TYPE_OBJECT:
			#	property_field = FIELD_OBJECT.instantiate()
			#TYPE_ARRAY:
			#	property_field = FIELD_ARRAY.instantiate()
			#TYPE_STRING_NAME:
			#	match property.hint:
			#		0:
			#			property_field = FIELD_STRING.instantiate()
			#		2:
			#			property_field = FIELD_ENUM.instantiate()
			#			tmp.set_data(fieldname, new_target, prop.name, prop, true)
			#TYPE_STRING:
			#	property_field = FIELD_STRING.instantiate()
			#TYPE_COLOR:
			#	property_field = FIELD_COLOR.instantiate()
			#TYPE_BOOL:
			#	property_field = FIELD_BOOL.instantiate()
			#TYPE_FLOAT:
			#	property_field = FIELD_NUMBER.instantiate()
			#	#tmp.type = 0
			#TYPE_INT:
			#	match property.hint:
			#		2:
			#			property_field = FIELD_ENUM.instantiate()
			#			#tmp.set_data(fieldname, new_target, prop.name, prop)
			#		_:
			#			property_field = FIELD_INT.instantiate()
			TYPE_VECTOR3, TYPE_VECTOR3I:
				property_field = FIELD_VECTOR_3.instantiate()
			TYPE_VECTOR2, TYPE_VECTOR2I:
				property_field = FIELD_VECTOR_2.instantiate()

		if property_field:
			scroll_list.add_child(property_field)
			property_field.button_group = button_group
			property_field.set_data(target, property)

	LocalGlobals.is_inspector_loading = false

func clear_fields():
	if target:
		if target.has_meta(&"display_name"):
			target_name_line.text = target.get_meta(&"display_name")
		else:
			target_name_line.text = target.name

## Change the name of the currently selected node by typing in the target name field.
func _on_target_name_line_text_changed(new_text: String) -> void:
	if not target: return

	target.set_meta(&"display_name", new_text)
	target.name = target.name
