extends CanvasLayer

## A simple system for managing transitions between scenes and during scenes
class_name WipeToolPlugin

#region Node References

@onready var panel: ColorRect = $Panel
@onready var anim_player: AnimationPlayer = $PanelAnim

#endregion

#region Wipe Type List

enum WipeType {
	fade
}

#endregion

#region End-user Setup Functions

#endregion

func wipe(in_type: WipeType, out_type: WipeType, length: float, condition: Signal):
	var in_string: String = "in_" + WipeType.keys()[in_type]
	var out_string: String = "out_" + WipeType.keys()[out_type]
	
	panel.visible = true
	
	anim_player.play(in_string, -1, length)
	await condition
	anim_player.play(out_string, -1, length)
	
	panel.visible = false
