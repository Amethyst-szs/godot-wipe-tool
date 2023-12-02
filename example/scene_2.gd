extends Control

func _on_button_pressed():
	WipeTool.wipe_with_scene_change("res://example/scene_1.tscn")

func _on_button_instant_pressed():
	WipeTool.scene_change("res://example/scene_1.tscn")
