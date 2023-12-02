shader_type canvas_item;

// Swipe transition vars
uniform bool is_use_swipe = false;
uniform float swipe_pos = 0.f;
uniform vec2 swipe_dir = vec2(-1.f, 0.f);
const float swipe_angle = 0.13f;
const float swipe_thickness = 0.15f;

// Circle transition vars
uniform bool is_use_circle = false;
uniform bool is_circle_in = true;
uniform vec2 circle_pos = vec2(0.f);
uniform float circle_size = 0.f;

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
	if (is_use_swipe) {
		// Handle horizontal or vertical depending on swipe_dir vector
		if (abs(swipe_dir.y) <= 0.1f) {
			COLOR.a = handle_horizontal(UV);
		} else {
			COLOR.a = handle_vertical(UV);
		}
	} else if (is_use_circle) {
		// Calculate screen size ratio
		vec2 ps = SCREEN_PIXEL_SIZE;
		vec2 ratio = (ps.x > ps.y) ? vec2(ps.y / ps.x, 1) : vec2(1, ps.x / ps.y);
		
		// Offset UV and circle pos by screen ratio for perfect circle in center of screen
		vec2 uv_ratio = vec2(UV.x / ratio.y, UV.y / ratio.x);
		vec2 circle_pos_ratio = vec2(circle_pos.x / ratio.y, circle_pos.y / ratio.x);
		
		// Create modified circle size based on ratio
		float circle_size_ratio = circle_size * max(ratio.x, ratio.y) * 1.3f;
		circle_size_ratio *= distance(circle_pos, vec2(0.5f)) + 1.f;
		
		// Calculate the edge and alpha
		float edge = distance(uv_ratio, circle_pos_ratio);
		float edgestep = step(edge, circle_size_ratio);
		COLOR.a = is_circle_in ? 1.f - edgestep : edgestep;
	}
}
