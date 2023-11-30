extends CanvasLayer

## A simple system for managing transitions between scenes and during scenes
class_name WipeToolPlugin

# Node References
@onready var panel: ColorRect = $Panel
@onready var anim_player: AnimationPlayer = $PanelAnim

## Type of wipe used for the animation player
enum WipeType {
	fade
}

#region Signals

## Signal notifying that the async scene loading is completed
signal async_load_finished

#endregion

#region Wipe Parameters

var wipe_is_visible: bool = false:
	set(value):
		panel.visible = value
		wipe_is_visible = value
	get:
		return wipe_is_visible
		
var wipe_duration: float = 1.0
var wipe_in_type: WipeType = WipeType.fade
var wipe_out_type: WipeType = WipeType.fade

var wipe_new_scene_path: String

#endregion

#region Built-in Methods

func _process(_delta: float) -> void:
	# If a new target scene is set, check it every frame to see if the load is finished
	if not wipe_new_scene_path.is_empty():
		if ResourceLoader.load_threaded_get_status(wipe_new_scene_path) == ResourceLoader.THREAD_LOAD_LOADED:
			wipe_new_scene_path = ""
			async_load_finished.emit()

#endregion

#region Mid-Scene Wipe Methods

func wipe_close():
	# Play the in/closing animation with no condition, end-user is expected to open it again themselves
	var in_string: String = "in_" + WipeType.keys()[wipe_in_type]
	
	wipe_is_visible = true
	anim_player.play(in_string, -1, 1.0 / wipe_duration)
	
func wipe_open():
	# Play the out/opening animation with no condition
	var out_string: String = "out_" + WipeType.keys()[wipe_in_type]
	
	wipe_is_visible = true
	
	anim_player.play(out_string, -1, 1.0 / wipe_duration)
	await anim_player.animation_finished
	
	wipe_is_visible = false

func wipe_close_and_open():
	# Convert the in_type and out_type to strings
	var in_string: String = "in_" + WipeType.keys()[wipe_in_type]
	var out_string: String = "out_" + WipeType.keys()[wipe_out_type]
	
	# Set the flag for the wipe being visibile
	wipe_is_visible = true
	
	# Play the in animation, wait for the animation to finish, then play the out animation
	anim_player.play(in_string, -1, 1.0 / wipe_duration)
	await anim_player.animation_finished
	anim_player.play(out_string, -1, 1.0 / wipe_duration)
	await anim_player.animation_finished
	
	# Reset flag for wipe visibility
	wipe_is_visible = false

func wipe_with_signal(open_condition: Signal):
	# Convert the in_type and out_type to strings
	var in_string: String = "in_" + WipeType.keys()[wipe_in_type]
	var out_string: String = "out_" + WipeType.keys()[wipe_out_type]
	
	# Set the flag for the wipe being visibile
	wipe_is_visible = true
	
	# Play the in animation, wait for the open_condition signal and anim, then play the out animation
	anim_player.play(in_string, -1, 1.0 / wipe_duration)
	
	#FIXME: Can't use and in await, so this doesn't work correctly
	await open_condition and anim_player.animation_finished
	anim_player.play(out_string, -1, 1.0 / wipe_duration)
	await anim_player.animation_finished
	
	# Reset flag for wipe visibility
	wipe_is_visible = false

#endregion

#region Scene Transition Methods

func _threaded_load(scene_path: String):
	ResourceLoader.load_threaded_request(scene_path, "", true)
	wipe_new_scene_path = scene_path

func wipe_with_scene_change(scene_path: String):
	# Start loading the scene data on another thread
	_threaded_load(scene_path)
	
	# Convert the in_type and out_type to strings
	var in_string: String = "in_" + WipeType.keys()[wipe_in_type]
	var out_string: String = "out_" + WipeType.keys()[wipe_out_type]
	
	# Set the flag for the wipe being visibile
	wipe_is_visible = true
	
	# Play the in animation, wait for the open_condition signal and anim, then play the out animation
	anim_player.play(in_string, -1, 1.0 / wipe_duration)
	
	#FIXME: Can't use and in await, so this doesn't work correctly
	await async_load_finished and anim_player.animation_finished
	anim_player.play(out_string, -1, 1.0 / wipe_duration)
	await anim_player.animation_finished
	
	# Reset flag for wipe visibility
	wipe_is_visible = false

#endregion
