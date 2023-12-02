extends Control

signal mouse_button

@onready var option_in: OptionButton = %OptionIn
@onready var option_out: OptionButton = %OptionOut

var preset_name: String = ""

#region Ready, Input, and Reset Functions

func _ready():
	%PresetManagerPanel.visible = false
	prepare()

func prepare():
	for wipe_type in range(Wipe.Type.size()):
		option_in.add_item(Wipe.Type.keys()[wipe_type], wipe_type)
		option_out.add_item(Wipe.Type.keys()[wipe_type], wipe_type)
	
	option_in.set_item_disabled(Wipe.Type.CAPTURE_TRANSITIONS, true)
	option_out.set_item_disabled(Wipe.Type.CAPTURE_TRANSITIONS, true)
	
	%SliderDuration.value = WipeTool.param.wipe_duration
	%OptionIn.selected = WipeTool.param.wipe_in_type
	%OptionOut.selected = WipeTool.param.wipe_out_type
	%ButtonColor.color = WipeTool.param.wipe_color
	
	%CircleInX.value = WipeTool.param.wipe_circle_in_pos.x
	%CircleInY.value = WipeTool.param.wipe_circle_in_pos.y
	%CircleOutX.value = WipeTool.param.wipe_circle_out_pos.x
	%CircleOutY.value = WipeTool.param.wipe_circle_out_pos.y
	
	_on_option_in_item_selected(WipeTool.param.wipe_in_type)
	_on_option_out_item_selected(WipeTool.param.wipe_out_type)
	
	_update_preset_list()

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		mouse_button.emit()

func reset_interface():
	option_in.clear()
	option_out.clear()
	prepare()

#endregion

#region Wipe settings functions

func _on_slider_duration_value_changed(value):
	WipeTool.param.wipe_duration = value

func _on_option_in_item_selected(index):
	WipeTool.param.wipe_in_type = index
	
	var is_circle_mode: bool = (index == Wipe.Type.circle or index == Wipe.Type.circle_invert)
	%CircleInX.visible = is_circle_mode
	%CircleInY.visible = is_circle_mode

func _on_option_out_item_selected(index):
	WipeTool.param.wipe_out_type = index
	
	var is_circle_mode: bool = (index == Wipe.Type.circle or index == Wipe.Type.circle_invert)
	%CircleOutX.visible = is_circle_mode
	%CircleOutY.visible = is_circle_mode
	
func _on_circle_in_x_value_changed(value):
	WipeTool.param.wipe_circle_in_pos.x = value

func _on_circle_in_y_value_changed(value):
	WipeTool.param.wipe_circle_in_pos.y = value

func _on_circle_out_x_value_changed(value):
	WipeTool.param.wipe_circle_out_pos.x = value

func _on_circle_out_y_value_changed(value):
	WipeTool.param.wipe_circle_out_pos.y = value

func _on_button_color_color_changed(color: Color):
	WipeTool.param.wipe_color = color

#endregion

#region Grid Button Functions

func _on_button_close_pressed():
	WipeTool.wipe_close()

func _on_button_open_pressed():
	WipeTool.wipe_open()

func _on_button_close_open_pressed():
	WipeTool.wipe_close_and_open()

func _on_button_condition_pressed():
	WipeTool.wipe_with_signal(mouse_button)

func _on_button_scene_pressed():
	WipeTool.wipe_with_scene_change("res://example/scene_1.tscn")

func _on_button_scene_other_pressed():
	WipeTool.wipe_with_scene_change("res://example/scene_2.tscn")

func _on_button_scene_other_no_wipe_pressed():
	WipeTool.scene_change("res://example/scene_2.tscn")

func _on_button_reset_pressed():
	WipeTool.param_reset()
	reset_interface()

func _on_button_pre_circle_pressed():
	WipeTool.param_reset()
	WipeTool.param_circle(Vector2.ZERO, Vector2.ONE, true)
	reset_interface()

func _on_button_pre_crossfade_pressed():
	WipeTool.param_reset()
	WipeTool.param_set(Wipe.Type.crossfade, Wipe.Type.crossfade, 0.5)
	reset_interface()

#endregion

#region Preset Manager

func _on_preset_manager_toggle_toggled(toggled_on):
	%PresetManagerPanel.visible = toggled_on

func _on_preset_name_text_changed(new_text):
	preset_name = new_text

func _update_preset_list():
	var all_presets: String = ""
	
	for item in range(WipeTool.param_presets.size()):
		all_presets += "%s\n" % [WipeTool.param_presets.keys()[item]]
	
	%PresetList.text = all_presets

func _on_preset_create_pressed():
	if not preset_name.is_empty():
		WipeTool.preset_add_current(preset_name)
		_update_preset_list()

func _on_preset_apply_pressed():
	if not preset_name.is_empty():
		WipeTool.preset_apply(preset_name)
		reset_interface()

func _on_preset_delete_pressed():
	if not preset_name.is_empty():
		WipeTool.preset_remove(preset_name)
		_update_preset_list()
		
func _on_preset_delete_all_pressed():
	WipeTool.preset_remove_all()
	_update_preset_list()

#endregion

