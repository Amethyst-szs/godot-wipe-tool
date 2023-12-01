@tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("WipeTool", "res://addons/wipetool/scene/wipe_tool.tscn")


func _exit_tree():
	remove_autoload_singleton("WipeTool")
