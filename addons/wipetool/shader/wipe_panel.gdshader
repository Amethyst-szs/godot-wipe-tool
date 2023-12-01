shader_type canvas_item;

uniform bool is_use_swipe = false;
uniform float swipe_pos = 0.f;
uniform vec2 swipe_dir = vec2(-1.f, 0.f);

const float swipe_angle = 0.13f;
const float swipe_thickness = 0.15f;

float handle_horizontal(vec2 uv) {
	// Offset swipe pos by factor of swipe_angle
	float swipe_pos_offset = swipe_pos * (1.f + swipe_angle);
	
	// Invert UV if the swipe direction is negative
	if(swipe_dir.x < 0.f) uv.x = 1.f - uv.x;
	
	// Add swipe angle into uv
	uv.x += uv.y * abs(swipe_dir.x * -swipe_angle);
	
	// Get the edge line based on the swipe_pos
	float right_edge = 1.f - step(uv.x, swipe_pos_offset - swipe_thickness);
	float left_edge = step(uv.x, swipe_pos_offset);
	
	return float((right_edge + left_edge) > 1.5f);
}

float handle_vertical(vec2 uv) {
	// Offset swipe pos by factor of swipe_angle
	float swipe_pos_offset = swipe_pos * (1.f + swipe_angle);
	
	// Invert UV if the swipe direction is negative
	if(swipe_dir.y > 0.f) uv.y = 1.f - uv.y;
	
	// Add swipe angle into uv
	uv.y += uv.x * abs(swipe_dir.y * -swipe_angle);
	
	// Get the edge line based on the swipe_pos
	float right_edge = 1.f - step(uv.y, swipe_pos_offset - swipe_thickness);
	float left_edge = step(uv.y, swipe_pos_offset);
	
	return float((right_edge + left_edge) > 1.5f);
}

void fragment() {
	if(is_use_swipe) {
		// Handle horizontal or vertical depending on swipe_dir vector
		if (abs(swipe_dir.y) <= 0.1f) {
			COLOR.a = handle_horizontal(UV);
		} else {
			COLOR.a = handle_vertical(UV);
		}
	}
}
