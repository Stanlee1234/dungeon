extends Node2D

@onready var player = get_node_or_null("Player")
@onready var tilemap = find_child("*TileMap*", true, false)
@onready var camera = find_child("*Camera*", true, false)

func _ready() -> void:
	if not player or not tilemap:
		return
	_trigger_sequence()

func _trigger_sequence():
	var shake_duration = 1.5
	var shake_intensity = 4.0
	var timer = 0.0
	
	if camera:
		while timer < shake_duration:
			camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
			timer += get_process_delta_time()
			await get_tree().process_frame
		camera.offset = Vector2.ZERO
	
	var local_pos = tilemap.to_local(player.global_position)
	var player_tile = tilemap.local_to_map(local_pos)
	
	for x in range(-5, 6):
		for y in range(0, 15):
			var target_cell = Vector2i(player_tile.x + x, player_tile.y + y)
			# For TileMap: set_cell(layer, coords, source_id, atlas_coords)
			# Layer 0 is usually the main floor layer
			tilemap.set_cell(0, target_cell, -1)
	
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://game.tscn")
