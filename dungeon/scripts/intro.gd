extends Node2D

@onready var player = $Player
@onready var tilemap = $TileMapLayer
@onready var camera = $Player/Camera2D 

const TILE_SIZE = 12
const BLOCKS_TO_WALK = 10

func _ready() -> void:
	if not player or not tilemap or not camera:
		return
	_start_intro()

func _start_intro():
	if player.has_method("set_physics_process"):
		player.set_physics_process(false)
	
	var sprite = player.find_child("AnimatedSprite2D")
	if sprite:
		sprite.play("walk")

	var target_x = player.global_position.x + (BLOCKS_TO_WALK * TILE_SIZE)
	var walk_tween = create_tween()
	
	walk_tween.tween_property(player, "global_position:x", target_x, 4.0)
	
	await walk_tween.finished
	
	if sprite:
		sprite.play("idle")
	
	var shake_duration = 1.5
	var shake_intensity = 4.0
	var timer = 0.0
	
	while timer < shake_duration:
		camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		timer += get_process_delta_time()
		await get_tree().process_frame
	
	camera.offset = Vector2.ZERO
	
	var player_tile = tilemap.local_to_map(player.global_position)
	for x in range(-2, 3):
		tilemap.set_cell(Vector2i(player_tile.x + x, player_tile.y), -1)
		tilemap.set_cell(Vector2i(player_tile.x + x, player_tile.y + 1), -1)

	player.set_physics_process(true)
	player.velocity.x = 0 
	
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://game.tscn")
