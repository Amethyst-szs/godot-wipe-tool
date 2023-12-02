extends Control

signal mouse_button

@onready var option_in: OptionButton = %OptionIn
@onready var option_out: OptionButton = %OptionOut

func _ready():
	for wipe_type in range(Wipe.Type.size()):		
		option_in.add_item(Wipe.Type.keys()[wipe_type], wipe_type)
		option_out.add_item(Wipe.Type.keys()[wipe_type], wipe_type)
	
	option_in.set_item_disabled(Wipe.Type.CAPTURE_TRANSITIONS, true)
	option_out.set_item_disabled(Wipe.Type.CAPTURE_TRANSITIONS, true)
	
	%SliderDuration.value = WipeTool.wipe_duration
	%OptionIn.selected = WipeTool.wipe_in_type
	%OptionOut.selected = WipeTool.wipe_out_type
	%ButtonColor.color = WipeTool.wipe_color
	
	%CircleInX.value = WipeTool.wipe_circle_in_pos.x
	%CircleInY.value = WipeTool.wipe_circle_in_pos.y
	%CircleOutX.value = WipeTool.wipe_circle_out_pos.x
	%CircleOutY.value = WipeTool.wipe_circle_out_pos.y
	
	_on_option_in_item_selected(WipeTool.wipe_in_type)
	_on_option_out_item_selected(WipeTool.wipe_out_type)

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		mouse_button.emit()

func reset_interface():
	option_in.clear()
	option_out.clear()
	_ready()

func _on_slider_duration_value_changed(value):
	WipeTool.wipe_duration = value

func _on_option_in_item_selected(index):
	WipeTool.wipe_in_type = index
	
	var is_circle_mode: bool = index == Wipe.Type.circle
	%CircleInX.visible = is_circle_mode
	%CircleInY.visible = is_circle_mode

func _on_option_out_item_selected(index):
	WipeTool.wipe_out_type = index
	
	var is_circle_mode: bool = index == Wipe.Type.circle
	%CircleOutX.visible = is_circle_mode
	%CircleOutY.visible = is_circle_mode
	
func _on_circle_in_x_value_changed(value):
	WipeTool.wipe_circle_in_pos.x = value

func _on_circle_in_y_value_changed(value):
	WipeTool.wipe_circle_in_pos.y = value

func _on_circle_out_x_value_changed(value):
	WipeTool.wipe_circle_out_pos.x = value

func _on_circle_out_y_value_changed(value):
	WipeTool.wipe_circle_out_pos.y = value

func _on_button_color_color_changed(color: Color):
	WipeTool.wipe_color = color

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

func _on_button_reset_pressed():
	WipeTool.wipe_reset_params()
	reset_interface()

func _on_button_pre_circle_pressed():
	WipeTool.wipe_reset_params()
	WipeTool.wipe_set_params_circle(Vector2.ZERO, Vector2.ONE, true)
	reset_interface()

func _on_button_pre_crossfade_pressed():
	WipeTool.wipe_reset_params()
	WipeTool.wipe_set_params(Wipe.Type.crossfade, Wipe.Type.crossfade, 0.5)
	reset_interface()
