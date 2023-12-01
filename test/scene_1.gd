extends Control

signal mouse_button

@onready var option_in: OptionButton = %OptionIn
@onready var option_out: OptionButton = %OptionOut

func _ready():
	for wipe_type in range(WipeTool.WipeType.size()):		
		option_in.add_item(WipeTool.WipeType.keys()[wipe_type], wipe_type)
		option_out.add_item(WipeTool.WipeType.keys()[wipe_type], wipe_type)
	
	option_in.set_item_disabled(WipeTool.WipeType.CAPTURE_TRANSITIONS, true)
	option_out.set_item_disabled(WipeTool.WipeType.CAPTURE_TRANSITIONS, true)
	
	%SliderDuration.value = WipeTool.wipe_duration
	%OptionIn.selected = WipeTool.wipe_in_type
	%OptionOut.selected = WipeTool.wipe_out_type
	%ButtonColor.color = WipeTool.wipe_color

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		mouse_button.emit()

func _on_slider_duration_value_changed(value):
	WipeTool.wipe_duration = value

func _on_option_in_item_selected(index):
	WipeTool.wipe_in_type = index

func _on_option_out_item_selected(index):
	WipeTool.wipe_out_type = index
	
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
	WipeTool.wipe_with_scene_change("res://test/scene_1.tscn")

func _on_button_scene_other_pressed():
	WipeTool.wipe_with_scene_change("res://test/scene_2.tscn")
