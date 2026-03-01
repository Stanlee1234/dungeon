extends Node2D

@onready var player = get_node_or_null("Player")
@onready var tilemap = find_child("*TileMapLayer*", true, false)
@onready var camera = find_child("*Camera*", true, false)
@onready var fade_overlay = find_child("FadeOverlay", true, false)
@onready var status_label = find_child("StatusLabel", true, false)

const TILE_SIZE = 12 
const BLOCKS_TO_WALK = 30

var sequence_triggered = false
var start_x = 0.0

func _ready() -> void:
	if not player or not tilemap:
		return
	start_x = player.global_position.x
	if status_label:
		status_label.modulate.a = 0.0

func _process(_delta: float) -> void:
	if sequence_triggered or not player:
		return
		
	var distance_walked = abs(player.global_position.x - start_x)
	var target_distance = BLOCKS_TO_WALK * TILE_SIZE
	
	if distance_walked >= target_distance:
		sequence_triggered = true
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
			if y == 0:
				if x == -5:
					tilemap.set_cell(target_cell, 3, Vector2i(2, 0))
				elif x == 5:
					tilemap.set_cell(target_cell, 3, Vector2i(0, 0))
				else:
					tilemap.set_cell(target_cell, -1)
			else:
				tilemap.set_cell(target_cell, -1)
	
	await get_tree().create_timer(1.5).timeout
	
	var tween = create_tween().set_parallel(true)
	if fade_overlay:
		tween.tween_property(fade_overlay, "modulate:a", 1.0, 1.5)
	if status_label:
		status_label.text = "The tutorial is over..."
		tween.tween_property(status_label, "modulate:a", 1.0, 1.0)
	
	await tween.finished
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/game.tscn")
