extends Camera2D

# The fixed Y height for the camera
var locked_y = 66

func _process(_delta):
	# Assuming the parent is the player
	var target_x = get_parent().global_position.x
	global_position = Vector2(target_x, locked_y)
