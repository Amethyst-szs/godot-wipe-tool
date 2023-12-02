extends CanvasLayer

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

## All parameters configuring how the wipe transition looks
@onready var param: WipeParams = WipeParams.new(panel)

## Dictionary for wipe param presets created by the end-user.
## Recommended for commonly used transitions so it's easier to update them later and switch on the fly.
## Modify using the preset functions, don't directly push to this dictionary yourself.
var param_presets: Dictionary = {}

#region Built-in Methods

func _ready() -> void:
	param.wipe_is_visible = false
	view_capture.visible = false

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
	var in_string: String = "in_" + Wipe.Type.keys()[param.wipe_in_type]
	
	anim_player.play("RESET")
	await anim_player.animation_finished
	param.wipe_is_visible = true
	
	_update_shader_params(param.wipe_circle_in_pos)
	
	# If the wipe type is a standard non-capture transition, play animation here
	if param.wipe_in_type < Wipe.Type.CAPTURE_TRANSITIONS and not param.wipe_in_type == Wipe.Type.NONE:
		anim_player.play(in_string, -1, 1.0 / param.wipe_duration)
	else: # If the wipe is a capture transition, capture viewport here
		_capture_viewport()

## Open wipe, will play animation even if wipe was not closed
func wipe_open() -> void:
	# Play the out/opening animation with no condition
	var out_string: String = "out_" + Wipe.Type.keys()[param.wipe_out_type]
	
	anim_player.play("RESET")
	await anim_player.animation_finished
	param.wipe_is_visible = true
	
	_update_shader_params(param.wipe_circle_out_pos)
	
	anim_player.play(out_string, -1, 1.0 / param.wipe_duration)
	await anim_player.animation_finished
	
	# Reset flag for wipe visibility and force uncapture viewport
	param.wipe_is_visible = false
	_uncapture_viewport()

## Close the wipe, and once the close completes, instantly open it again
func wipe_close_and_open() -> void:
	# Convert the in_type and out_type to strings
	var in_string: String = "in_" + Wipe.Type.keys()[param.wipe_in_type]
	var out_string: String = "out_" + Wipe.Type.keys()[param.wipe_out_type]
	
	# Set the flag for the wipe being visibile and reset wipe
	anim_player.play("RESET")
	await anim_player.animation_finished
	param.wipe_is_visible = true
	
	_update_shader_params(param.wipe_circle_in_pos)
	
	# Play the in animation, wait for the animation to finish, then play the out animation
	
	# If the wipe type is a standard non-capture transition, play in animation
	if param.wipe_in_type < Wipe.Type.CAPTURE_TRANSITIONS and not param.wipe_in_type == Wipe.Type.NONE:
		anim_player.play(in_string, -1, 1.0 / param.wipe_duration)
		await anim_player.animation_finished
	else: # If the wipe is a capture transition, capture viewport here
		_capture_viewport()
	
	_update_shader_params(param.wipe_circle_out_pos)
		
	anim_player.play(out_string, -1, 1.0 / param.wipe_duration)
	await anim_player.animation_finished
	
	# Reset flag for wipe visibility and force uncapture viewport
	param.wipe_is_visible = false
	_uncapture_viewport()

## Close the wipe, wait for the signal to be emitted, and then open it
func wipe_with_signal(open_condition: Signal) -> void:
	# Convert the in_type and out_type to strings
	var in_string: String = "in_" + Wipe.Type.keys()[param.wipe_in_type]
	var out_string: String = "out_" + Wipe.Type.keys()[param.wipe_out_type]
	
	# Set the flag for the wipe being visibile and reset wipe
	anim_player.play("RESET")
	await anim_player.animation_finished
	param.wipe_is_visible = true
	
	_update_shader_params(param.wipe_circle_in_pos)
	
	# If the wipe type is a standard non-capture transition, play in animation here
	if param.wipe_in_type < Wipe.Type.CAPTURE_TRANSITIONS and not param.wipe_in_type == Wipe.Type.NONE:
		# Create composited signal
		var comp_signal := CompositeSignal.new()
		comp_signal.add_signals([open_condition, anim_player.animation_finished])
	
		# Play the in animation, wait for the open_condition signal and anim, then play the out animation
		anim_player.play(in_string, -1, 1.0 / param.wipe_duration)
		await comp_signal.composite_complete
	else: # If the wipe is a capture transition, capture viewport here and wait for condition
		if not param.wipe_in_type == Wipe.Type.NONE:
			_capture_viewport()
		
		await open_condition
	
	_update_shader_params(param.wipe_circle_out_pos)
		
	anim_player.play(out_string, -1, 1.0 / param.wipe_duration)
	await anim_player.animation_finished
	
	# Reset flag for wipe visibility and force uncapture viewport
	param.wipe_is_visible = false
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
	var in_string: String = "in_" + Wipe.Type.keys()[param.wipe_in_type]
	var out_string: String = "out_" + Wipe.Type.keys()[param.wipe_out_type]
	
	# Set the flag for the wipe being visibile and reset wipe
	anim_player.play("RESET")
	await anim_player.animation_finished
	param.wipe_is_visible = true
	
	# Start loading the scene data on another thread
	_threaded_load(scene_path)
	
	_update_shader_params(param.wipe_circle_in_pos)
	
	# If the wipe type is a standard non-capture transition, play animation here
	if param.wipe_in_type < Wipe.Type.CAPTURE_TRANSITIONS and not param.wipe_in_type == Wipe.Type.NONE:
		# Create composited signal
		var comp_signal := CompositeSignal.new()
		comp_signal.add_signals([async_load_finished, anim_player.animation_finished])
	
		# Play the in animation, wait for the anim and scene load to finish
		anim_player.play(in_string, -1, 1.0 / param.wipe_duration)
		await comp_signal.composite_complete
	else:
		await async_load_finished
	
	# Swap scenes, skipping uncapturing the viewport if using a scene transition
	if param.wipe_out_type < Wipe.Type.CAPTURE_TRANSITIONS:
		_uncapture_viewport()
	get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(scene_path))
	get_tree().paused = false
	
	_update_shader_params(param.wipe_circle_out_pos)
	
	# Open wipe now that scene has been loaded
	anim_player.play(out_string, -1, 1.0 / param.wipe_duration)
	await anim_player.animation_finished
	
	# Reset flag for wipe visibility and force uncapture viewport
	param.wipe_is_visible = false
	_uncapture_viewport()

#endregion

#region Helper Methods for Param Editing

## Reset all wipe transition properties to default
func param_reset() -> void:
	param.reset()

## Update parameters for wipe transition. Pass in the default value to skip updating that parameter
func param_set(in_type: Wipe.Type = Wipe.Type.NONE, out_type: Wipe.Type = Wipe.Type.NONE, duration: float = -1.0, color: Color = Color.TRANSPARENT) -> void:
	param.set_normal(in_type, out_type, duration, color)

## Set the in and out wipe
func param_type(in_type: Wipe.Type, out_type: Wipe.Type) -> void:
	param.set_wipes(in_type, out_type)

## Set both the in and out wipe to the same type
func param_type_both(wipe_type: Wipe.Type) -> void:
	param.set_wipes_both(wipe_type)

## Update the circle transition's position, and optionally enable the circle type for in and out
func param_circle(in_pos: Vector2, out_pos: Vector2, enable_circle_type: bool = true) -> void:
	param.set_circle(in_pos, out_pos, enable_circle_type)

#endregion

#region Helper Methods for Presets

## Add a new WipeParams to the preset list with a given name
func preset_add(preset_name: String, new_params: WipeParams):
	var new_param_copy: WipeParams = WipeParams.new()
	new_param_copy.copy(new_params)
	param_presets[preset_name] = new_param_copy

## Add the current param settings in WipeTool to the preset list with a given name
func preset_add_current(preset_name: String):
	var new_param_copy: WipeParams = WipeParams.new()
	new_param_copy.copy(param)
	param_presets[preset_name] = new_param_copy

## Apply a preset in WipeTool with the preset's name
func preset_apply(preset_name: String):
	var new_param: WipeParams = WipeParams.new(panel)
	new_param.copy(param_presets[preset_name])
	new_param._init(panel)
	param = new_param

## Remove a preset by name
func preset_remove(preset_name: String):
	param_presets.erase(preset_name)

#endregion

#region Shader Methods

func _update_shader_params(circle_pos: Vector2):
	if not panel.material is ShaderMaterial:
		return
	
	var mat: ShaderMaterial = panel.material
	mat.set_shader_parameter("circle_pos", circle_pos)

#endregion
