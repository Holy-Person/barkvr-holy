extends InspectorPanel

# TODO: find a more optimized way to update field values
# This requires a PR to godot. they don't seem interested in the change
# but without it, it's impossible to do performant scene tracking

const FIELD_ARRAY = preload("uid://dxshup2m2t62c")
const FIELD_BOOL = preload("uid://ctvd4j8wp7mh5")
const FIELD_COLOR = preload("uid://5r83rbiuayop")
const FIELD_ENUM = preload("uid://dy1wide8xv5df")
const FIELD_NUMBER = preload("uid://cbmgba1q1d8q5")
const FIELD_OBJECT = preload("uid://dddtbbin6ty1l")
const FIELD_STRING = preload("uid://3cx3afcwx3hw")
const FIELD_VECTOR_2 = preload("uid://dkaactpqyjgjn")
const FIELD_VECTOR_3 = preload("uid://dd2kp02usski5")

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

	_setup_icons()
	_setup_signals()

func _setup_icons() -> void:
	button_documentation.set_button_icon(get_editor_icon(&"HelpSearch"))
	button_previous.set_button_icon(get_editor_icon(&"Back"))
	button_next.set_button_icon(get_editor_icon(&"Forward"))
	button_history.set_button_icon(get_editor_icon(&"History"))

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

func _add_fields(prop_list, new_target) -> void:
	while LocalGlobals.is_inspector_loading:
		await get_tree().process_frame
	LocalGlobals.is_inspector_loading = true
	var start_time : float = Time.get_ticks_msec()
	for i in range(prop_list.size()):
		if start_time + 1 < Time.get_ticks_msec():
			await get_tree().process_frame
			start_time = Time.get_ticks_msec()
		#await get_tree().process_frame
		var prop = prop_list[i]
		var fieldname :String= prop.name
		if prop.name.contains("bones/") and new_target is Skeleton3D:
			fieldname = "bone: "+new_target.get_bone_name(int(prop.name.split("/")[1]))+" "+prop.name.split("/")[-1]
		if !is_instance_valid(new_target):
			return
		if prop.name == "owner":
			continue
		match prop.type:
			TYPE_OBJECT:
				var tmp :Object_Attribute = FIELD_OBJECT.instantiate()
				scroll_list.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, target, prop.name)
			TYPE_ARRAY:
				var tmp :Array_Attribute = FIELD_ARRAY.instantiate()
				scroll_list.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_STRING_NAME:
				match prop.hint:
					0:
						var tmp :String_Attribute = FIELD_STRING.instantiate()
						scroll_list.add_child(tmp)
						tmp.name = fieldname
						tmp.set_data(fieldname, new_target, prop.name)
					2:
						var tmp :Enum_Attribute = FIELD_ENUM.instantiate()
						scroll_list.add_child(tmp)
						tmp.name = fieldname
						tmp.set_data(fieldname, new_target, prop.name, prop, true)
			TYPE_STRING:
				var tmp :String_Attribute = FIELD_STRING.instantiate()
				scroll_list.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_COLOR:
				var tmp :Color_Attribute = FIELD_COLOR.instantiate()
				scroll_list.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_BOOL:
				var tmp :Bool_Attribute = FIELD_BOOL.instantiate()
				scroll_list.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_FLOAT:
				var tmp :Number_Attribute = FIELD_NUMBER.instantiate()
				tmp.type = 0
				scroll_list.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_INT:
				match prop.hint:
					2:
						var tmp :Enum_Attribute = FIELD_ENUM.instantiate()
						scroll_list.add_child(tmp)
						tmp.name = fieldname
						tmp.set_data(fieldname, new_target, prop.name, prop)
					_:
						var tmp :Number_Attribute = FIELD_NUMBER.instantiate()
						tmp.type = 1
						scroll_list.add_child(tmp)
						tmp.name = fieldname
						tmp.set_data(fieldname, new_target, prop.name)
			TYPE_VECTOR3:
				var tmp :Vector3_Attribute = FIELD_VECTOR_3.instantiate()
				scroll_list.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_VECTOR3I:
				var tmp :Vector3_Attribute = FIELD_VECTOR_3.instantiate()
				scroll_list.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_VECTOR2:
				var tmp :Vector2_Attribute = FIELD_VECTOR_2.instantiate()
				scroll_list.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
			TYPE_VECTOR2I:
				var tmp :Vector2_Attribute = FIELD_VECTOR_2.instantiate()
				scroll_list.add_child(tmp)
				tmp.name = fieldname
				tmp.set_data(fieldname, new_target, prop.name)
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
