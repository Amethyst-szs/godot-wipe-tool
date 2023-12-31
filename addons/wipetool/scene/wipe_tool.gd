extends CanvasLayer

#region Node References

## ColorRect used for the wipe animations
@onready var panel: ColorRect = $Panel
## AnimationPlayer for every kind of wipe the WipeTool can play
@onready var anim_player: AnimationPlayer = $PanelAnim
## TextureRect that contains a screenshot of the viewport during scene transitions
@onready var view_capture: TextureRect = $ViewCapture

#endregion

#region Param & Preset Variables

## All parameters configuring how the wipe transition looks
@onready var param: WipeParams = WipeParams.new(panel):
	set(value):
		param = value
		param.panel_ref = panel
	get:
		return param

## Dictionary for wipe param presets created by the end-user.
## Recommended for commonly used transitions so it's easier to update them later and switch on the fly.
## Modify using the preset functions, don't directly push to this dictionary yourself.
var param_presets: Dictionary = {}

#endregion

#region Signals

## Signal emitted when a wipe in animation is started
signal wipe_in_started

## Signal emitted when a wipe in animation is fully finished
signal wipe_in_finished

## Signal emitted when a wipe out animation is start
signal wipe_out_started

## Signal emitted when a wipe out animatiom is fully finished
signal wipe_out_finished

## Signal emitted when a wipe captures the viewport and displays that screenshot over your scene
signal wipe_viewport_captured

## Signal emitted when a wipe uncaptures the viewport and goes back to showing your regular scene
signal wipe_viewport_uncaptured

## Signal notifying that the async scene loading is completed
signal async_load_finished

#endregion

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
	wipe_in_started.emit()
	
	# Play the in/closing animation with no condition, end-user is expected to open it again themselves
	var in_string: String = "in_" + Wipe.Type.keys()[param.wipe_in_type]
	
	anim_player.play("RESET")
	param.wipe_is_visible = true
	
	panel.color = param.wipe_color
	_update_shader_params(param.wipe_circle_in_pos)
	
	# If the wipe type is a standard non-capture transition, play animation here
	if param.wipe_in_type < Wipe.Type.CAPTURE_TRANSITIONS and not param.wipe_in_type == Wipe.Type.NONE:
		anim_player.play(in_string, -1, 1.0 / param.wipe_duration)
		await anim_player.animation_finished
	else: # If the wipe is a capture transition, capture viewport here
		_capture_viewport()
	
	call_deferred("emit_signal", "wipe_in_finished")

## Open wipe, will play animation even if wipe was not closed
func wipe_open() -> void:
	wipe_out_started.emit()
	
	# Play the out/opening animation with no condition
	var out_string: String = "out_" + Wipe.Type.keys()[param.wipe_out_type]
	
	anim_player.play("RESET")
	param.wipe_is_visible = true
	
	panel.color = param.wipe_color
	_update_shader_params(param.wipe_circle_out_pos)
	
	# Play out animation if type is not NONE
	if not param.wipe_out_type == Wipe.Type.NONE:
		anim_player.play(out_string, -1, 1.0 / param.wipe_duration)
		await anim_player.animation_finished
	else:
		anim_player.play("RESET")
	
	# Reset flag for wipe visibility and force uncapture viewport
	param.wipe_is_visible = false
	_uncapture_viewport()
	
	call_deferred("emit_signal", "wipe_out_finished")

## Close the wipe, and once the close completes, instantly open it again
func wipe_close_and_open() -> void:
	wipe_in_started.emit()
	
	# Convert the in_type and out_type to strings
	var in_string: String = "in_" + Wipe.Type.keys()[param.wipe_in_type]
	var out_string: String = "out_" + Wipe.Type.keys()[param.wipe_out_type]
	
	# Set the flag for the wipe being visibile and reset wipe
	anim_player.play("RESET")
	await anim_player.animation_finished
	param.wipe_is_visible = true
	
	panel.color = param.wipe_color
	_update_shader_params(param.wipe_circle_in_pos)
	
	# Play the in animation, wait for the animation to finish, then play the out animation
	
	# If the wipe type is a standard non-capture transition, play in animation
	if param.wipe_in_type < Wipe.Type.CAPTURE_TRANSITIONS and not param.wipe_in_type == Wipe.Type.NONE:
		anim_player.play(in_string, -1, 1.0 / param.wipe_duration)
		await anim_player.animation_finished
	else: # If the wipe is a capture transition, capture viewport here
		if not param.wipe_in_type == Wipe.Type.NONE:
			_capture_viewport()
	
	wipe_in_finished.emit()
	
	panel.color = param.wipe_color
	_update_shader_params(param.wipe_circle_out_pos)
	
	wipe_out_started.emit()
	
	# Play out animation if type is not NONE
	if not param.wipe_out_type == Wipe.Type.NONE:
		anim_player.play(out_string, -1, 1.0 / param.wipe_duration)
		await anim_player.animation_finished
	else:
		anim_player.play("RESET")
	
	# Reset flag for wipe visibility and force uncapture viewport
	param.wipe_is_visible = false
	_uncapture_viewport()
	
	wipe_out_finished.emit()

## Close the wipe, wait for the signal to be emitted, and then open it
func wipe_with_signal(open_condition: Signal) -> void:
	wipe_in_started.emit()
	
	# Convert the in_type and out_type to strings
	var in_string: String = "in_" + Wipe.Type.keys()[param.wipe_in_type]
	var out_string: String = "out_" + Wipe.Type.keys()[param.wipe_out_type]
	
	# Set the flag for the wipe being visibile and reset wipe
	anim_player.play("RESET")
	await anim_player.animation_finished
	param.wipe_is_visible = true
	
	panel.color = param.wipe_color
	_update_shader_params(param.wipe_circle_in_pos)
	
	# If the wipe type is a standard non-capture transition, play in animation here
	if param.wipe_in_type < Wipe.Type.CAPTURE_TRANSITIONS and not param.wipe_in_type == Wipe.Type.NONE:
		# Create composited signal
		var comp_signal := CompositeSignal.new()
		comp_signal.add_signals([open_condition, anim_player.animation_finished])
	
		# Play the in animation, wait for the open_condition signal and anim, then play the out animation
		anim_player.play(in_string, -1, 1.0 / param.wipe_duration)
		anim_player.animation_finished.connect(_anim_player_wipe_close_finished.bind(anim_player))
		await comp_signal.composite_complete
		
	else: # If the wipe is a capture transition, capture viewport here and wait for condition
		if not param.wipe_in_type == Wipe.Type.NONE:
			_capture_viewport()
		
		await open_condition
	
	# Check if this node's metadata is storing a reference to a script
	if has_meta("signal_script_ref"):
		remove_meta("signal_script_ref")
	
	panel.color = param.wipe_color
	_update_shader_params(param.wipe_circle_out_pos)
	
	wipe_out_started.emit()
	
	# Play out animation if type is not NONE
	if not param.wipe_out_type == Wipe.Type.NONE:
		anim_player.play(out_string, -1, 1.0 / param.wipe_duration)
		await anim_player.animation_finished
	else:
		anim_player.play("RESET")
	
	# Reset flag for wipe visibility and force uncapture viewport
	param.wipe_is_visible = false
	_uncapture_viewport()
	
	wipe_out_finished.emit()

func _anim_player_wipe_close_finished(name: StringName, anim_player: AnimationPlayer):
	wipe_in_finished.emit()
	
	if anim_player.animation_finished.is_connected(_anim_player_wipe_close_finished):
		anim_player.animation_finished.disconnect(_anim_player_wipe_close_finished)

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
	wipe_viewport_captured.emit()

# Destroy sceenshot of viewport and hide view_capture
func _uncapture_viewport() -> void:
	if view_capture.visible:
		wipe_viewport_uncaptured.emit()
	
	view_capture.visible = false
	view_capture.texture = null

## Close wipe, wait for animation and new scene load, then open wipe
func wipe_with_scene_change(scene_path: String) -> void:
	# Pause scene to prevent user changing anything during wipe in
	get_tree().paused = true
	
	# Screenshot viewport and display that static image during in anim
	_capture_viewport()
	
	wipe_in_started.emit()
	
	# Convert the in_type and out_type to strings
	var in_string: String = "in_" + Wipe.Type.keys()[param.wipe_in_type]
	var out_string: String = "out_" + Wipe.Type.keys()[param.wipe_out_type]
	
	# Set the flag for the wipe being visibile and reset wipe
	anim_player.play("RESET")
	await anim_player.animation_finished
	param.wipe_is_visible = true
	
	# Start loading the scene data on another thread
	_threaded_load(scene_path)
	
	panel.color = param.wipe_color
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
	
	wipe_in_finished.emit()
	
	# Swap scenes, skipping uncapturing the viewport if using a scene transition
	if param.wipe_out_type < Wipe.Type.CAPTURE_TRANSITIONS:
		_uncapture_viewport()
	get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(scene_path))
	get_tree().paused = false
	
	panel.color = param.wipe_color
	_update_shader_params(param.wipe_circle_out_pos)
	
	wipe_out_started.emit()
	
	# Play out animation if type is not NONE
	if not param.wipe_out_type == Wipe.Type.NONE:
		anim_player.play(out_string, -1, 1.0 / param.wipe_duration)
		await anim_player.animation_finished
	else:
		anim_player.play("RESET")
	
	# Reset flag for wipe visibility and force uncapture viewport
	param.wipe_is_visible = false
	_uncapture_viewport()
	
	wipe_out_finished.emit()

## Change scenes with async without playing any wipe animation
func scene_change(scene_path: String) -> void:
	# Start loading the scene data on another thread
	_threaded_load(scene_path)
	await async_load_finished
	
	get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(scene_path))
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
	preset_remove(preset_name)
	
	var new_param_copy: WipeParams = WipeParams.new()
	new_param_copy.copy(new_params)
	param_presets[preset_name] = new_param_copy

## Add the current param settings in WipeTool to the preset list with a given name
func preset_add_current(preset_name: String):
	preset_remove(preset_name)
	
	var new_param_copy: WipeParams = WipeParams.new()
	new_param_copy.copy(param)
	param_presets[preset_name] = new_param_copy

## Apply a preset in WipeTool with the preset's name
func preset_apply(preset_name: String):
	if not param_presets.has(preset_name):
		push_warning("WipeTool: Attempted to apply WipeParams preset that doesn't exist!")
		return
	
	var new_param: WipeParams = WipeParams.new(panel)
	new_param._init(panel)
	new_param.copy(param_presets[preset_name])
	param = new_param

## Remove a preset by name
func preset_remove(preset_name: String):
	param_presets.erase(preset_name)

# Delete every single wipe preset
func preset_remove_all():
	param_presets.clear()

#endregion

#region Shader Methods

func _update_shader_params(circle_pos: Vector2):
	if not panel.material is ShaderMaterial:
		return
	
	var mat: ShaderMaterial = panel.material
	mat.set_shader_parameter("circle_pos", circle_pos)

#endregion
