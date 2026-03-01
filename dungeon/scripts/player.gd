extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -200.0
const CLIMB_SPEED = -80.0
const SLIDE_SPEED = 40.0

# State variables
var DEAD = false
var on_chain = false
var is_climbing = false
var keys_collected = 0

# Track the last tile processed to prevent double-collecting keys or doors
var last_tile_pos = Vector2i(-1, -1) 

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
	if not tilemap: return

	# We check 4 pixels above the origin (feet) to center the "sensor" 
	# and prevent bouncing at the bottom of chains.
	var check_pos = global_position + Vector2(0, -4)
	var map_pos = tilemap.local_to_map(check_pos)
	var tile_data = tilemap.get_cell_tile_data(map_pos)

	if tile_data:
		# 1. DANGER CHECK
		if tile_data.get_custom_data("is_danger") == true:
			_die()
		
		# 2. KEY & DOOR LOGIC (Only runs once per tile coordinate)
		if map_pos != last_tile_pos:
			# Collect Key
			if tile_data.get_custom_data("is_key") == true:
				keys_collected += 1
				tilemap.set_cell(map_pos, -1) # Delete the key tile
				last_tile_pos = map_pos
				print("Keys: ", keys_collected)

			# Switch Door
			if tile_data.get_custom_data("is_door") == true:
				if keys_collected > 0:
					keys_collected -= 1
					# Switches the closed door to the "Open" tile at (6, 1)
					tilemap.set_cell(map_pos, 0, Vector2i(6, 1))
					last_tile_pos = map_pos
					print("Door opened! Keys remaining: ", keys_collected)
		
		# 3. CHAIN LOGIC (Runs every frame while overlapping)
		if tile_data.get_custom_data("is_chain") == true:
			if not on_chain:
				is_climbing = true
			on_chain = true
		else:
			_exit_chain()
	else:
		# If there's no tile at all, ensure we fall off the chain
		_exit_chain()
		last_tile_pos = map_pos

func _exit_chain():
	if on_chain:
		velocity.y = 0 
	on_chain = false
	is_climbing = false

func _handle_normal_movement(delta):
	# Apply Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Horizontal Movement
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	_update_animations(direction)

func _handle_chain_logic():
	var horizontal_dir := Input.get_axis("ui_left", "ui_right")
	
	# Vertical Climb/Slide
	if Input.is_action_pressed("ui_up"):
		velocity.y = CLIMB_SPEED
		sprite.play("walk") # Playing walk animation for climbing
	else:
		velocity.y = SLIDE_SPEED
		sprite.play("idle")

	# Allow horizontal movement while on the chain
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
	# Restarts the game after a tiny delay
	call_deferred("_reload_game")

func _reload_game():
	get_tree().reload_current_scene()
