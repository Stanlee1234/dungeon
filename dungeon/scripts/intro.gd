extends Node2D

@onready var tilemap = find_child("*TileMapLayer*", true, false)
@onready var fade_overlay = find_child("FadeOverlay", true, false)

func _trigger_sequence(player_node):
	print("DEBUG: Earthquake sequence started!")
	
	if not player_node or not tilemap:
		print("DEBUG ERROR: Missing player or tilemap in intro!")
		return
	
	# 1. Shake the Camera
	var camera = player_node.find_child("*Camera2D*", true, false)
	var shake_duration = 1.5
	var shake_intensity = 4.0
	
	if camera:
		var timer = get_tree().create_timer(shake_duration)
		while timer.time_left > 0:
			camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
			await get_tree().create_timer(0.01).timeout 
		camera.offset = Vector2.ZERO
	
	# 2. Delete the Ground (BULLETPROOF METHOD)
	var local_pos = tilemap.to_local(player_node.global_position)
	var player_tile = tilemap.local_to_map(local_pos)
	
	print("DEBUG: Erasing tiles to make the hole!")
	
	for x in range(-5, 6):
		for y in range(0, 15):
			var target_cell = Vector2i(player_tile.x + x, player_tile.y + y)
			# This simply deletes whatever tile is there, guaranteed to work
			tilemap.erase_cell(target_cell)
	
	# 3. Wait for the fall, then Fade Out
	await get_tree().create_timer(2.0).timeout
	
	if fade_overlay:
		print("DEBUG: Fading to black...")
		var tween = create_tween()
		tween.tween_property(fade_overlay, "modulate:a", 1.0, 1.0)
		await tween.finished
	
	print("DEBUG: Changing to Level 1")
	# Update this string if your scene is named something else!
	get_tree().change_scene_to_file("res://scenes/level1.tscn")
