extends Node2D

@onready var player = get_node_or_null("Player")
@onready var tilemap = find_child("*TileMapLayer*", true, false)
@onready var camera = find_child("*Camera*", true, false)

func _ready() -> void:
	if not player or not tilemap:
		return
	_trigger_sequence()

func _trigger_sequence():
	var shake_duration = 1.5
	var shake_intensity = 4.0
	
	if camera:
		var timer = get_tree().create_timer(shake_duration)
		while timer.time_left > 0:
			camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
			await get_tree().create_timer(0.01).timeout 
		camera.offset = Vector2.ZERO
	
	var local_pos = tilemap.to_local(player.global_position)
	var player_tile = tilemap.local_to_map(local_pos)
	
	for x in range(-5, 6):
		for y in range(0, 15):
			var target_cell = Vector2i(player_tile.x + x, player_tile.y + y)
			# For TileMapLayer, coordinates are the first argument
			tilemap.set_cell(target_cell, -1)
	
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://game.tscn")
