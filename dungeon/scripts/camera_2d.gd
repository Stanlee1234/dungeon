extends Camera2D

var locked_y = 66

func _process(_delta):
	var target_x = get_parent().global_position.x
	global_position = Vector2(target_x, locked_y)
