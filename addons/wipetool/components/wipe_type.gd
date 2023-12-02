## Class containing list of wipe transition types in the "Type" enum
class_name Wipe

## Every type of wipe in the animation player
enum Type {
	NONE,
	fade,
	slide_left,
	slide_right,
	slide_up,
	slide_down,
	circle,
	circle_invert,
	
	CAPTURE_TRANSITIONS, # All wipes after this point will always capture the viewport
	crossfade,
	swipe_left,
	swipe_right,
	swipe_up,
	swipe_down
}
