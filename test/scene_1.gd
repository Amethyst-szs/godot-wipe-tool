extends Node2D

var time: float = 0
signal time_passed

func _ready():
	WipeTool.wipe(WipeTool.WipeType.fade, WipeTool.WipeType.fade, 2.0, time_passed)

func _process(delta: float):
	time += delta
	if time >= 4.0:
		time_passed.emit()
