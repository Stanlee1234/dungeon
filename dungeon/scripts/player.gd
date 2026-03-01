extends CharacterBody2D

@onready var sprite = find_child("*AnimatedSprite2D*", true, false)
@onready var camera = find_child("*Camera2D*", true, false)
@onready var tilemap = get_parent().find_child("*TileMapLayer*", true, false)

const SPEED = 100.0
const JUMP_VELOCITY = -200.0
const CLIMB_SPEED = -80.0
const SLIDE_SPEED = 40.0
const COYOTE_TIME_MAX = 0.15
const TILE_SIZE = 12
const BLOCKS_TO_WALK = 30

var DEAD = false
var has_control = true
var on_chain = false
var is_climbing = false
var keys_collected = 0
var coyote_timer = 0.0
var last_tile_pos = Vector2i(-1, -1) 

var start_x = 0.0
var sequence_triggered = false
var is_falling = false
var fall_start_y = 0.0
var max_fall_distance = 0.0
var last_door_pos = Vector2.ZERO

func _ready() -> void:
	start_x = global_position.x
	last_door_pos = global_position

func _physics_process(delta: float) -> void:
	if DEAD: return
	if not sprite:
		move_and_slide()
		return

	_check_for_tile_data()
	_check_tutorial_distance()

	if is_climbing:
		_handle_chain_logic()
	else:
		_handle_normal_movement(delta)

	_handle_landing_rumble()
	move_and_slide()

func _check_tutorial_distance():
	if get_tree().current_scene.name == "intro" and not sequence_triggered:
		var distance = abs(global_position.x - start_x)
		
		if distance >= BLOCKS_TO_WALK * TILE_SIZE:
			print("DEBUG: 30 Blocks reached! Telling intro to break ground.")
			sequence_triggered = true
			
			var intro_scene = get_tree().current_scene
			if intro_scene.has_method("_trigger_sequence"):
				intro_scene._trigger_sequence(self) 
			else:
				print("DEBUG ERROR: _trigger_sequence missing on intro root!")

func _handle_landing_rumble():
	if not is_on_floor():
		if not is_falling:
			is_falling = true
			fall_start_y = global_position.y
		var current_fall = global_position.y - fall_start_y
		if current_fall > max_fall_distance:
			max_fall_distance = current_fall
	else:
		if is_falling:
			if max_fall_distance >= 100.0:
				_apply_rumble(0.4, 4.0)
			is_falling = false
			max_fall_distance = 0.0

func _apply_rumble(duration: float, intensity: float):
	if not camera: return
	var timer = get_tree().create_timer(duration)
	while timer.time_left > 0:
		camera.offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		await get_tree().create_timer(0.01).timeout
	camera.offset = Vector2.ZERO

func _check_for_tile_data():
	if not tilemap: return
	var check_pos = global_position + Vector2(0, -4)
	var map_pos = tilemap.local_to_map(tilemap.to_local(check_pos))
	var tile_data = tilemap.get_cell_tile_data(map_pos)

	if tile_data:
		if tile_data.get_custom_data("is_danger"):
			_respawn_player()
		
		if map_pos != last_tile_pos:
			if tile_data.get_custom_data("is_key"):
				keys_collected += 1
				tilemap.set_cell(map_pos, -1)
			
			if tile_data.get_custom_data("is_door"):
				last_door_pos = tilemap.map_to_local(map_pos + Vector2i(1, 0))
				if keys_collected > 0:
					keys_collected -= 1
					tilemap.set_cell(map_pos, 0, Vector2i(6, 1))
			last_tile_pos = map_pos

		if tile_data.get_custom_data("is_chain"):
			if not on_chain: is_climbing = true
			on_chain = true
		else:
			_exit_chain()
	else:
		_exit_chain()
		last_tile_pos = map_pos

func _exit_chain():
	if on_chain:
		if Input.is_action_pressed("ui_up"):
			velocity.y = JUMP_VELOCITY
		else:
			velocity.y = 0 
	on_chain = false
	is_climbing = false

func _handle_normal_movement(delta):
	if is_on_floor():
		coyote_timer = COYOTE_TIME_MAX
	else:
		coyote_timer -= delta
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_up") and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0

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

func _respawn_player():
	velocity = Vector2.ZERO
	global_position = last_door_pos
	is_falling = false
	max_fall_distance = 0.0

func _on_win_body_entered(body: Node2D) -> void:
	if body == self:
		var current_scene = get_tree().current_scene.name
		if current_scene == "level1":
			get_tree().change_scene_to_file("res://scenes/level2.tscn")
		elif current_scene == "level2":
			get_tree().change_scene_to_file("res://scenes/win.tscn")
