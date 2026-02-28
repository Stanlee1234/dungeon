extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -200.0
const CLIMB_SPEED = -80.0
const SLIDE_SPEED = 40.0

var DEAD = false
var on_chain = false
var is_climbing = false

@onready var sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:

	if DEAD: return

	_check_for_tile_data()

	if is_climbing:
		_handle_chain_logic()
	else:
		_handle_normal_movement(delta)

	move_and_slide()

func _check_for_tile_data():
	var tilemap = get_parent().find_child("TileMapLayer", true, false)
	if not tilemap:
		return

	var check_pos = global_position + Vector2(0, 0)
	var map_pos = tilemap.local_to_map(check_pos)
	var tile_data = tilemap.get_cell_tile_data(map_pos)

	if tile_data:
		if tile_data.get_custom_data("is_danger") == true:
			_die()
		
		if tile_data.get_custom_data("is_chain") == true:
			if not on_chain:
				is_climbing = true
			on_chain = true
		else:
			if on_chain:
				velocity.y = JUMP_VELOCITY
			on_chain = false
			is_climbing = false
	else:
		if on_chain:
			velocity.y = JUMP_VELOCITY
		on_chain = false
		is_climbing = false

func _handle_normal_movement(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	_update_animations(direction)

func _handle_chain_logic():
	var horizontal_dir := Input.get_axis("ui_left", "ui_right")
	
	if Input.is_action_pressed("ui_up"):
		velocity.y = CLIMB_SPEED
		sprite.play("walk")
	else:
		velocity.y = SLIDE_SPEED
		sprite.play("idle")

	if horizontal_dir:
		velocity.x = horizontal_dir * SPEED
		sprite.flip_h = horizontal_dir < 0
	else:
		velocity.x = 0

func _update_animations(direction):
	if is_climbing: return
	if not is_on_floor():
		sprite.play("jump")
	elif direction != 0:
		sprite.play("walk")
	else:
		sprite.play("idle")

func _die():
	if DEAD: return
	DEAD = true
	set_physics_process(false)
	call_deferred("_reload_game")

func _reload_game():
	get_tree().reload_current_scene()
