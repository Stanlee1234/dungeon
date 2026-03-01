extends Node2D

@onready var player = find_child("*Player*", true, false)
@onready var tilemap = find_child("*TileMapLayer*", true, false)
@onready var tutorial_label = player.find_child("TutorialLabel", true, false)
@onready var tutorial_label2 = player.find_child("TutorialLabel2", true, false)

const START_POS = Vector2(6, 137)
const TILE_SIZE = 12

func _ready() -> void:
	if player:
		player.has_control = false
		player.set_physics_process(false)
		player.global_position = START_POS
		
		if tutorial_label:
			tutorial_label.modulate.a = 0.0
			tutorial_label.visible = true
		if tutorial_label2:
			tutorial_label2.modulate.a = 0.0
			tutorial_label2.visible = true
		
		_run_cutscene()

func _run_cutscene() -> void:
	await get_tree().create_timer(1.0).timeout

	# 1. Move up 3 blocks
	player.sprite.play("walk")
	var climb = create_tween()
	climb.tween_property(player, "global_position:y", player.global_position.y - (TILE_SIZE * 3), 1.0)
	await climb.finished
	player.sprite.play("idle")
	await get_tree().create_timer(0.5).timeout

	# 2. Jump out to the right
	player.sprite.play("jump")
	var jump = create_tween().set_parallel(true)
	jump.tween_property(player, "global_position:x", player.global_position.x + 36, 0.6)
	jump.tween_property(player, "global_position:y", player.global_position.y - 12, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await jump.finished
	
	# 3. Land on the surface
	var fall = create_tween()
	fall.tween_property(player, "global_position:y", player.global_position.y + 12, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await fall.finished
	player.sprite.play("idle")

	# 4. Change the block at (0, 9)
	if tilemap:
		tilemap.set_cell(Vector2i(0, 9), 2, Vector2i(1, 0))

	# 5. Look left and right
	await get_tree().create_timer(1.0).timeout
	player.sprite.flip_h = true
	await get_tree().create_timer(1.2).timeout
	player.sprite.flip_h = false
	await get_tree().create_timer(1.0).timeout

	# 6. Walk off screen and show text after 10 blocks
	player.sprite.play("walk")
	var walk = create_tween()
	# First move 10 blocks (120 pixels) then show text
	walk.tween_property(player, "global_position:x", player.global_position.x + 100, 3.0)
	await walk.finished
	
	if tutorial_label:
		var text_fade = create_tween()
		text_fade.tween_property(tutorial_label, "modulate:a", 1.0, 1.0)
	
	# Continue walking off screen
	var text_fade2 = create_tween()
	text_fade2.tween_property(player, "global_position:x", player.global_position.x + 100, 3.0)
	await text_fade2.finished

	if tutorial_label2:
		var text_fade = create_tween()
		text_fade.tween_property(tutorial_label2, "modulate:a", 1.0, 1.0)
	
	var finish_walk = create_tween()
	finish_walk.tween_property(player, "global_position:x", player.global_position.x + 10000, 300.0)
