extends CanvasLayer

## A simple system for managing transitions between scenes and during scenes
class_name WipeToolPlugin

## Every type of wipe in the animation player
enum WipeType {
	fade,
	slide_left,
	slide_right,
	slide_up,
	slide_down,
	
	CAPTURE_TRANSITIONS, # All wipes after this point capture the viewport
	crossfade,
}

# Signals

## Signal notifying that the async scene loading is completed
signal async_load_finished

# Node References

## ColorRect used for the wipe animations
@onready var panel: ColorRect = $Panel
## AnimationPlayer for every kind of wipe the WipeTool can play
@onready var anim_player: AnimationPlayer = $PanelAnim
## TextureRect that contains a screenshot of the viewport during scene transitions
@onready var view_capture: TextureRect = $ViewCapture

#region Wipe Parameters

## Is the wipe ColorRect currently visible? Set by methods, not meant to be manually changed
var wipe_is_visible: bool = false:
	set(value):
		panel.visible = value
		wipe_is_visible = value
	get:
		return wipe_is_visible

## Color of ColorRect used in the wipe animations
var wipe_color: Color = Color.BLACK:
	set(value):
		panel.color = value
		wipe_color = value
	get:
		return wipe_color

## Amount of time in seconds that the wipe transition lasts
var wipe_duration: float = 1.0
## Animation to play when closing the wipe
var wipe_in_type: WipeType = WipeType.fade
## Animation to play when opening the wipe
var wipe_out_type: WipeType = WipeType.fade

#endregion

#region Built-in Methods

func _ready() -> void:
	wipe_is_visible = false

func _process(_delta: float) -> void:
	# If a new target scene is set, check it every frame to see if the load is finished
	if not wipe_new_scene_path.is_empty():
		if ResourceLoader.load_threaded_get_status(wipe_new_scene_path) == ResourceLoader.THREAD_LOAD_LOADED:
			wipe_new_scene_path = ""
			async_load_finished.emit()

#endregion

#region Mid-Scene Wipe Methods

## Close wipe, will not automatically open until "wipe_open" is called
func wipe_close() -> void:
	# Play the in/closing animation with no condition, end-user is expected to open it again themselves
	var in_string: String = "in_" + WipeType.keys()[wipe_in_type]
	
	anim_player.play("RESET")
	await anim_player.animation_finished
	wipe_is_visible = true
	
	# If the wipe type is a standard non-capture transition, play animation here
	if wipe_in_type < WipeType.CAPTURE_TRANSITIONS:
		anim_player.play(in_string, -1, 1.0 / wipe_duration)
	else: # If the wipe is a capture transition, capture viewport here
		_capture_viewport()

## Open wipe, will play animation even if wipe was not closed
func wipe_open() -> void:
	# Play the out/opening animation with no condition
	var out_string: String = "out_" + WipeType.keys()[wipe_out_type]
	
	anim_player.play("RESET")
	await anim_player.animation_finished
	wipe_is_visible = true
	
	anim_player.play(out_string, -1, 1.0 / wipe_duration)
	await anim_player.animation_finished
	
	# Reset flag for wipe visibility and force uncapture viewport
	wipe_is_visible = false
	_uncapture_viewport()

## Close the wipe, and once the close completes, instantly open it again
func wipe_close_and_open() -> void:
	# Convert the in_type and out_type to strings
	var in_string: String = "in_" + WipeType.keys()[wipe_in_type]
	var out_string: String = "out_" + WipeType.keys()[wipe_out_type]
	
	# Set the flag for the wipe being visibile and reset wipe
	anim_player.play("RESET")
	await anim_player.animation_finished
	wipe_is_visible = true
	
	# Play the in animation, wait for the animation to finish, then play the out animation
	
	# If the wipe type is a standard non-capture transition, play in animation
	if wipe_in_type < WipeType.CAPTURE_TRANSITIONS:
		anim_player.play(in_string, -1, 1.0 / wipe_duration)
		await anim_player.animation_finished
	else: # If the wipe is a capture transition, capture viewport here
		_capture_viewport()
		
	anim_player.play(out_string, -1, 1.0 / wipe_duration)
	await anim_player.animation_finished
	
	# Reset flag for wipe visibility and force uncapture viewport
	wipe_is_visible = false
	_uncapture_viewport()

## Close the wipe, wait for the signal to be emitted, and then open it
func wipe_with_signal(open_condition: Signal) -> void:
	# Convert the in_type and out_type to strings
	var in_string: String = "in_" + WipeType.keys()[wipe_in_type]
	var out_string: String = "out_" + WipeType.keys()[wipe_out_type]
	
	# Set the flag for the wipe being visibile and reset wipe
	anim_player.play("RESET")
	await anim_player.animation_finished
	wipe_is_visible = true
	
	# If the wipe type is a standard non-capture transition, play in animation here
	if wipe_in_type < WipeType.CAPTURE_TRANSITIONS:
		# Create composited signal
		var comp_signal := CompositeSignal.new()
		comp_signal.add_signals([open_condition, anim_player.animation_finished])
	
		# Play the in animation, wait for the open_condition signal and anim, then play the out animation
		anim_player.play(in_string, -1, 1.0 / wipe_duration)
		await comp_signal.composite_complete
	else: # If the wipe is a capture transition, capture viewport here and wait for condition
		_capture_viewport()
		await open_condition
		
	anim_player.play(out_string, -1, 1.0 / wipe_duration)
	await anim_player.animation_finished
	
	# Reset flag for wipe visibility and force uncapture viewport
	wipe_is_visible = false
	_uncapture_viewport()

#endregion

#region Scene Transition Methods

## String containing path of new scene being async loaded, not meant for end-user
var wipe_new_scene_path: String

# Start loading new scene on thread
func _threaded_load(scene_path: String) -> void:
	ResourceLoader.load_threaded_request(scene_path)
	wipe_new_scene_path = scene_path

# Create screenshot of viewport and set view_capture to that image
func _capture_viewport() -> void:
	var image: Image = get_viewport().get_texture().get_image()
	view_capture.visible = true
	view_capture.texture = ImageTexture.create_from_image(image)

# Destroy sceenshot of viewport and hide view_capture
func _uncapture_viewport() -> void:
	view_capture.visible = false
	view_capture.texture = null

## Close wipe, wait for animation and new scene load, then open wipe
func wipe_with_scene_change(scene_path: String) -> void:
	# Pause scene to prevent user changing anything during wipe in
	get_tree().paused = true
	
	# Screenshot viewport and display that static image during in anim
	_capture_viewport()
	
	# Convert the in_type and out_type to strings
	var in_string: String = "in_" + WipeType.keys()[wipe_in_type]
	var out_string: String = "out_" + WipeType.keys()[wipe_out_type]
	
	# Set the flag for the wipe being visibile and reset wipe
	anim_player.play("RESET")
	await anim_player.animation_finished
	wipe_is_visible = true
	
	# Start loading the scene data on another thread
	_threaded_load(scene_path)
	
	# If the wipe type is a standard non-capture transition, play animation here
	if wipe_in_type < WipeType.CAPTURE_TRANSITIONS:
		# Create composited signal
		var comp_signal := CompositeSignal.new()
		comp_signal.add_signals([async_load_finished, anim_player.animation_finished])
	
		# Play the in animation, wait for the anim and scene load to finish
		anim_player.play(in_string, -1, 1.0 / wipe_duration)
		await comp_signal.composite_complete
	else:
		await async_load_finished
	
	# Swap scenes, skipping uncapturing the viewport if using a scene transition
	if wipe_out_type < WipeType.CAPTURE_TRANSITIONS:
		_uncapture_viewport()
	get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(scene_path))
	get_tree().paused = false
	
	# Open wipe now that scene has been loaded
	anim_player.play(out_string, -1, 1.0 / wipe_duration)
	await anim_player.animation_finished
	
	# Reset flag for wipe visibility and force uncapture viewport
	wipe_is_visible = false
	_uncapture_viewport()

#endregion
