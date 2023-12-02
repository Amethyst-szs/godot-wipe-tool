extends RefCounted

## All parameters configuring how a wipe transition using WipeTool looks
class_name WipeParams

#region Param Init and Node References

func _init(panel: ColorRect = null):
	panel_ref = panel

func copy(other: WipeParams):
	wipe_duration = other.wipe_duration
	wipe_in_type = other.wipe_in_type
	wipe_out_type = other.wipe_out_type
	wipe_color = other.wipe_color
	wipe_circle_in_pos = other.wipe_circle_in_pos
	wipe_circle_out_pos = other.wipe_circle_out_pos

## Reference to panel node used in transitions.
## Don't set this manually, this is automatically set by WipeTool when needed.
var panel_ref: ColorRect

#endregion

#region Variables

## Is the wipe ColorRect currently visible? Set by methods, not meant to be manually changed
var wipe_is_visible: bool = false:
	set(value):
		if panel_ref:
			panel_ref.visible = value
			
		wipe_is_visible = value
	get:
		return wipe_is_visible

## Color of ColorRect used in the wipe animations
var wipe_color: Color = Color.BLACK:
	set(value):
		if panel_ref:
			panel_ref.color = value
		
		wipe_color = value
	get:
		return wipe_color

## Amount of time in seconds that the wipe transition lasts
var wipe_duration: float = 1.0
## Animation to play when closing the wipe
var wipe_in_type: Wipe.Type = Wipe.Type.fade
## Animation to play when opening the wipe
var wipe_out_type: Wipe.Type = Wipe.Type.fade

## Position between 0-1 for the circle wipe transition coming in
var wipe_circle_in_pos: Vector2 = Vector2(0.5, 0.5)
## Position between 0-1 for the circle wipe transition leaving out
var wipe_circle_out_pos: Vector2 = Vector2(0.5, 0.5)

#endregion

#region Helper Functions

func reset() -> void:
	wipe_duration = 1.0
	wipe_in_type = Wipe.Type.fade
	wipe_out_type = Wipe.Type.fade
	wipe_color = Color.BLACK
	wipe_circle_in_pos = Vector2(0.5, 0.5)
	wipe_circle_out_pos = Vector2(0.5, 0.5)

func set_normal(in_type: Wipe.Type = Wipe.Type.NONE, out_type: Wipe.Type = Wipe.Type.NONE, duration: float = -1.0, color: Color = Color.TRANSPARENT) -> void:
	if not duration == -1.0: wipe_duration = duration
	if not in_type == Wipe.Type.NONE: wipe_in_type = in_type
	if not out_type == Wipe.Type.NONE: wipe_out_type = out_type
	if not color == Color.TRANSPARENT: color = wipe_color

func set_wipes(in_type: Wipe.Type, out_type: Wipe.Type) -> void:
	wipe_in_type = in_type
	wipe_out_type = out_type

func set_wipes_both(wipe_type: Wipe.Type) -> void:
	wipe_in_type = wipe_type
	wipe_out_type = wipe_type

func set_circle(in_pos: Vector2, out_pos: Vector2, enable_circle_type: bool = true) -> void:
	wipe_circle_in_pos = in_pos
	wipe_circle_out_pos = out_pos
	
	if enable_circle_type:
		wipe_in_type = Wipe.Type.circle
		wipe_out_type = Wipe.Type.circle

#endregion
