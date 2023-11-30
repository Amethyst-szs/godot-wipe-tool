extends Control

var time: float = 0
signal time_passed

func _ready():
	WipeTool.wipe_duration = 2.0
	WipeTool.wipe_with_scene_change("res://test/scene_2.tscn")

func _process(delta: float):
	time += delta
	if time >= 4.0:
		time_passed.emit()
